#!/usr/bin/env ruby

require 'socket'
require 'set'
require_relative 'volcano_log'
require_relative 'volcano_settings'
require_relative 'volcano_session'
require_relative 'client'
require_relative 'worker'

PID_FILENAME = '.volcano.pid'
#$DEBUG = true

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
    @srv_sock = TCPServer.new(@settings[:bind_ip], @settings[:port])
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
        if select([@srv_sock], nil, nil, 0.2)
          client = @srv_sock.accept
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
    @srv_sock = TCPServer.new(@settings[:bind_ip], @settings[:port])
    @ph = ProtocolHandlerThreaded.get_instance
    @workers = []
    @clients = {
        mutex: Mutex.new,
        pool: Set.new
    }
    @jobs = {
        mutex: Mutex.new,
        queue: Queue.new
    }
  end

  def accept
    cf = ClientFactory.get_instance(self)
    return unless select([@srv_sock], nil, nil, 0)
    client = cf.build_client(@srv_sock.accept)
    push_client(client)
    $log.puts("! Client connected: #{client.socket}")
    @ph.send_response(client, FTPResponseGreet.new)
    @clients[:pool]
  end

  def run
    $log.puts("Starting VolcanoFTP. [Root dir: '#{settings[:root_dir]}']")
    $log.puts("Bound to address #{@settings[:bind_ip]}, listening on port #{@settings[:port]}")
    File.open(PID_FILENAME, 'w') { |file| file.puts Process.pid.to_s }  # save pid to file

    wf = WorkerFactory.get_instance(self)

    (1..@settings[:worker_nb]).each {
      w = wf.build_worker
      @workers << Thread.new { w.handle_job }
      $log.puts("* Worker thread ##{w.id} created")
    }

    while 1
      accept
      c = nil
      @clients[:mutex].synchronize { c = @clients[:pool].size }
      if c.zero?
        sleep(0.01); next
      end

      client_select_read.each { |c|
        begin
          cmd = @ph.read_command(c)
          unless cmd.nil?
            push_job(Job.new(c, cmd))
          end

        rescue EOFError, Errno::EPIPE, Errno::ECONNRESET
          delete_client(c)
          $log.puts("! Client disconnected: #{c}")
        end
      }
      sleep(0.01)
    end

    @workers.each { |w| w.join }

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

  def push_client(c)
    unless c.nil?
      @clients[:mutex].synchronize { @clients[:pool].add(c) }
    end
  end

  def delete_client(c)
    unless c.nil?
      @clients[:mutex].synchronize { @clients[:pool].delete(c) }
    end
  end

  def push_job(j)
    unless j.nil?
      @jobs[:mutex].synchronize { @jobs[:queue].push(j) }
    end
  end

  def pop_job
    j = nil
    @jobs[:mutex].synchronize { j = @jobs[:queue].pop }
    j
  end

  def no_job
    r = nil
    @jobs[:mutex].synchronize { r = @jobs[:queue].size }
    r.zero?
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
