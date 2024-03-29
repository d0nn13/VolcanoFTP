require 'socket'
require 'set'
require_relative 'volcano_ftp/logger'
require_relative 'volcano_ftp/preferences'
require_relative 'volcano_ftp/client'
require_relative 'volcano_ftp/worker'
require_relative 'volcano_ftp/exception'
require_relative 'volcano_ftp/auth'

#$DEBUG = true
PID_FILENAME = 'data/.volcano.pid'

IDLE_DELAY = 0.2
HANDLE_REQUEST_THREAD_DELAY = 0.001
NO_REQUEST_TIMEOUT = 2


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

    accept_thd = Thread.new { accept(cf) }
    handle_requests_thd = Thread.new { handle_requests }

    workers.each { |w| w.join }
    accept_thd.join
    handle_requests_thd.join
  end

  private
  def accept(cf)
    while 1

      begin
        select([@srv_sock])
        client = cf.build_client(@srv_sock.accept)
        n = push_client(client)
        $log.puts("! Client connected: #{client} (Total: #{n})", client.id)
        @ph.send_response(client, FTPResponseGreet.new)
        @clients[:pool]

      rescue Exception => e
        $log.puts('Exception caught in accept thread')
        raise e
      end

    end
  end

  def handle_requests
    no_req_ts = Time.now
    while 1
      loop_ts = Time.now

      begin
        if nb_client.zero?
          sleep(IDLE_DELAY); next
        end

        requesters = @clients[:mutex].synchronize {
          out = Set.new
          @clients[:pool].each { |c|
            out << c if c.requesting?
          }
          out
        }

        if requesters.length.zero?
          if (Time.now - no_req_ts) >= NO_REQUEST_TIMEOUT
            sleep(IDLE_DELAY); next
          end
        else
          no_req_ts = Time.now
        end

        requesters.each { |r|
          cmd = @ph.read_command(r)
          push_job(Job.new(r, cmd)) unless cmd.nil?
        }

      rescue ClientConnectionLost => e
        handle_clientconnectionlost(e.client)
      rescue Exception => e
        $log.puts('Exception caught in handle_request thread')
        raise e
      ensure
        dly = Time.now - loop_ts
        sleep(HANDLE_REQUEST_THREAD_DELAY - dly) if dly < HANDLE_REQUEST_THREAD_DELAY
      end

    end
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
    $log.puts("! Client disconnected: #{client} (Total: #{n})", client.id)
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
