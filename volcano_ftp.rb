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
    Thread.abort_on_exception = true
    @settings = settings.settings
    @srv_sock = TCPServer.new(@settings[:bind_ip], @settings[:port])
    @ph = ProtocolHandlerThreaded.get_instance
    @workers = []
    @jobs = Queue.new
    @clients = {
        mutex: Mutex.new,
        pool: Set.new
    }
  end

  def run
    $log.puts("Starting VolcanoFTP. [Root dir: '#{settings[:root_dir]}']")
    $log.puts("Bound to address #{@settings[:bind_ip]}, listening on port #{@settings[:port]}")
    File.open(PID_FILENAME, 'w') { |file| file.puts Process.pid.to_s }  # save pid to file

    wf = WorkerFactory.get_instance(self)
    cf = ClientFactory.get_instance(self)

    n = nil
    (1..@settings[:worker_nb]).each { |it|
      w = wf.build_worker
      @workers << Thread.new { w.handle_job }
      n = it
    }
    $log.puts("* #{n} worker threads created")

    while 1
      begin
        accept(cf)
        if nb_client.zero?
          sleep(0.1); next
        end

        client_select_read.each { |c|
          cmd = @ph.read_command(c)
          push_job(Job.new(c, cmd)) unless cmd.nil?
        }
      rescue ClientConnectionLost => e
        handle_clientconnectionlost(e)
      ensure
        sleep(0.05)
      end
    end

  end

  private
  def accept(cf)
    return unless select([@srv_sock], nil, nil, 0)
    client = cf.build_client(@srv_sock.accept)
    n = push_client(client)
    $log.puts("! Client connected: #{client.socket} (Total: #{n})")
    @ph.send_response(client, FTPResponseGreet.new)
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

  def nb_client
    n = nil
    @clients[:mutex].synchronize { n = @clients[:pool].size }
    n
  end

  def push_client(c)
    n = nil
    @clients[:mutex].synchronize {
      @clients[:pool].add(c) unless c.nil?
      n = @clients[:pool].size
    }
    n
  end

  def delete_client(c)
    n = nil
    @clients[:mutex].synchronize {
      @clients[:pool].delete(c) unless c.nil?
      n = @clients[:pool].size
    }
    n
  end

  public
  def push_job(j)
    @jobs.push(j) unless j.nil?
    @jobs.length
  end

  def pop_job
    @jobs.pop
  end

  def handle_clientconnectionlost(e)
    n = delete_client(e.client)
    $log.puts("! Client disconnected: #{e.client} (Total: #{n})")
  end
end



begin
  s = VolcanoSettings.new
  $log = VolcanoLog.new(s)
  VolcanoFTP.new(s).run

rescue SystemExit, Interrupt
  ;
rescue LogException, SocketError, Errno::EADDRINUSE, Errno::EADDRNOTAVAIL => e
  puts e
rescue Exception => e
  VolcanoLog.log("Uncaught exception: #{e.inspect} '#{e}'")
  puts e.backtrace
ensure
  File.delete(PID_FILENAME) if File.exists?(PID_FILENAME)
  $log.close_log unless $log.nil?
end
