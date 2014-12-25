require 'socket'
require 'set'
require_relative 'volcano_ftp/logger'
require_relative 'volcano_ftp/preferences'
require_relative 'volcano_ftp/client'
require_relative 'volcano_ftp/worker'
require_relative 'volcano_ftp/exception'

PID_FILENAME = 'data/.volcano.pid'
#$DEBUG = true

class VolcanoFTP
  attr_reader :preferences

  def initialize(prefs)
    Signal.trap('QUIT') { exit }
    Signal.trap('TERM') { exit }
    ENV['HOME'] = '/'
    Thread.abort_on_exception = true
    @preferences = prefs
    @srv_sock = TCPServer.new(@preferences[:bind_ip], @preferences[:port])
    @ph = ProtocolHandler.get_instance
    @jobs = Queue.new
    @clients = {
        mutex: Mutex.new,
        pool: Set.new
    }
  end

  def run
    $log.puts("Starting VolcanoFTP. [Root dir: '#{@preferences[:root_dir]}']")
    $log.puts("Bound to address #{@preferences[:bind_ip]}, listening on port #{@preferences[:port]}")
    File.open(PID_FILENAME, 'w') { |file| file.puts Process.pid.to_s }  # save pid to file

    wf = WorkerFactory.get_instance(self)
    cf = ClientFactory.get_instance(self)
    workers = []

    (1..@preferences[:worker_nb]).each {
      workers << Thread.new { wf.build_worker.run }
    }
    $log.puts("* #{workers.length} worker threads created")

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
        handle_clientconnectionlost(e.client)
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
    $log.puts("! Client connected: #{client} (Total: #{n})")
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

  def handle_clientconnectionlost(client)
    n = delete_client(client)
    $log.puts("! Client disconnected: #{client} (Total: #{n})")
  end
end


begin
  s = Preferences.new.get
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
