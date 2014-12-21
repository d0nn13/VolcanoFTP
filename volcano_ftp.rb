#!/usr/bin/env ruby

require 'socket'
require 'set'
require_relative 'volcano_log'
require_relative 'volcano_settings'
require_relative 'volcano_session'
require_relative 'client'

PID_FILENAME = '.volcano.pid'
$DEBUG = true

class TCPSocket
  def to_s
    "#{peeraddr(:hostname)[2]} (#{peeraddr(:hostname)[3]}:#{peeraddr(:hostname)[1]})"
  end
end

class VolcanoFTP
  attr_reader :settings

  def initialize(settings)
    Signal.trap('QUIT') { exit }
    Signal.trap('TERM') { exit }
    ENV['HOME'] = '/'
    @settings = settings.settings
    @socket = TCPServer.new(@settings[:bind_ip], @settings[:port])
    @clients = {}
    @inactive_time = Time.new(0)
  end

  def refresh_sessions
    @clients.each_key { |pid|
      @clients.delete(pid) unless Process.wait(pid, Process::WNOHANG).nil?
    }
  end

  def run
    $log.puts("Starting VolcanoFTP. [Root dir: '#{settings[:root_dir]}']")
    $log.puts("Bound to address #{@settings[:bind_ip]}, listening on port #{@settings[:port]}")
    File.open(PID_FILENAME, 'w') { |file| file.puts Process.pid.to_s }  # save pid to file
    sid = 0

    begin
      while 1
        refresh_sessions
        if select([@socket], nil, nil, 0.2)
          client = @socket.accept
          $log.puts("Client connected : #{client}")

          sid += 1
          new_session = VolcanoSession.new(self, sid, client)

          pid = fork {new_session.launch}
          @clients[pid] = new_session
        end
      end
    rescue SystemExit, Interrupt
      sess_nb = @clients.length
      unless sess_nb.zero?
        msg = "Waiting for #{sess_nb} remaining process#{sess_nb > 1 && 'es' || ''} to finish..."
        $log.puts(msg)
        @clients.each_key { |pid|
          Process.kill('TERM', pid)
          Process.waitpid(pid)
          @clients.delete(pid)
        }
      end
      $log.puts('Leaving.')
    ensure
      File.delete(PID_FILENAME) if File.exists?(PID_FILENAME) # delete saved pid file
    end
  end

end

class VolcanoFTPThreaded
  attr_reader :settings

  def initialize(settings)
    Signal.trap('QUIT') { exit }
    Signal.trap('TERM') { exit }
    ENV['HOME'] = '/'
    @settings = settings.settings
    @socket = TCPServer.new(@settings[:bind_ip], @settings[:port])
    @workers = []
    @clients = {
        mutex: Mutex.new,
        pool: Set.new
    }
    @requests = {
        mutex: Mutex.new,
        queue: Queue.new
    }
    @responses = {
        mutex: Mutex.new,
        queue: Queue.new
    }
    @sid = 0
    @ph = ProtocolHandlerThreaded.new(self)
  end

  def push_client(c)
    unless c.nil?
      @clients[:mutex].synchronize { @clients[:pool].add(c) }
    end
  end

  def push_request(r)
    unless r.nil?
      @requests[:mutex].synchronize { @requests[:queue].push(r) }
    end
  end

  def push_response(r)
    unless r.nil?
      @responses[:mutex].synchronize { @responses[:queue].push(r) }
    end
  end

  def accept
    return unless select([@socket], nil, nil, 0)
    client_sock = @socket.accept

    client = Client.new(self, @sid += 1, client_sock)
    push_client(client)
    push_response(Job.new(client, FTPResponseGreet.new))

    $log.puts("Client connected: #{client_sock}")
    @clients[:pool]
  end

  def client_select_read
    read_ready = []
    @clients[:mutex].synchronize {
      @clients[:pool].each { |c|
        next unless select([c.socket], nil, nil, 0)
        read_ready << c
      }
    }
    read_ready
  end

  def client_select_write
    write_ready = []
    @clients[:mutex].synchronize {
      @clients[:pool].each { |c|
        next unless select(nil, [c.socket], nil, 0)
        write_ready << c
      }
    }
    write_ready
  end

  def handle_requests(tid)
    while 1
      if @requests[:queue].size.zero?
        sleep(0.1); next
      end

      req = nil
      @requests[:mutex].synchronize { req = @requests[:queue].pop }
      unless req.nil?
        resp = req.do
        push_response(Job.new(req.client, resp))
      end

    end
  end

  def handle_responses(tid)
    while 1
      if @responses[:queue].size.zero?
        sleep(0.1); next
      end

      resp = nil
      @responses[:mutex].synchronize { resp = @responses[:queue].pop }
      resp.do

    end
  end


  def run
    $log.puts("Starting VolcanoFTP. [Root dir: '#{settings[:root_dir]}']")
    $log.puts("Bound to address #{@settings[:bind_ip]}, listening on port #{@settings[:port]}")
    File.open(PID_FILENAME, 'w') { |file| file.puts Process.pid.to_s }  # save pid to file

    tid = 0

    (0..4).each
      @workers << Thread.new { handle_requests(tid += 1) }

    Thread.new { handle_responses(tid += 1) }

    while 1
      accept
      next if @clients[:pool].size.zero?

      client_select_read.each { |c|
        begin
          cmd = @ph.read_command(c)
          unless cmd.nil?
            @requests[:queue].push(Job.new(c, cmd))
          end

        rescue EOFError, Errno::EPIPE, Errno::ECONNRESET
          @clients[:mutex].synchronize { @clients[:pool].delete(c) }
          $log.puts('Client disconnected', c.id)
        end
      }
    end

    @workers.each { |w| w.join }

  end

end





begin
  s = VolcanoSettings.new
  $log = VolcanoLog.new(s)
  VolcanoFTPThreaded.new(s).run

rescue SystemExit, Interrupt
  ;
rescue LogException, SocketError, Errno::EADDRINUSE, Errno::EADDRNOTAVAIL => e
  puts e
rescue Exception => e
  #raise e
  VolcanoLog.log("Uncaught exception: #{e.class} '#{e}'")
  puts e.backtrace
ensure
  $log.close_log unless $log.nil?
end
