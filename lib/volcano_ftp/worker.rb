require_relative 'logger'
require_relative 'protocol_handler'

WORKER_THREAD_DELAY = 5e-5

class Worker
  attr_reader :id

  def initialize(server, id)
    @server = server
    @id = id
    @ph = ProtocolHandler.get_instance
  end

  def run
    while 1
      loop_ts = Time.now

      begin
        job = @server.pop_job
        unless job.nil?
          $log.puts("* Worker ##{@id}: #{job}", job.requester.id, LOG_SUCCESS)
          @ph.send_response(job.requester, job.do)
        end

      rescue ClientConnectionLost => e
        @server.handle_clientconnectionlost(e.client)
      ensure
        dly = Time.now - loop_ts
        sleep(WORKER_THREAD_DELAY - dly) if dly < WORKER_THREAD_DELAY
      end

    end
  end
end


class WorkerFactory
  def self.get_instance(server)
    @instance = WorkerFactory.new(server) if @instance.nil?
    @instance
  end

  def build_worker
    w = Worker.new(@server, @id)
    @id += 1
    w
  end

  private
  def initialize(server)
    @server = server
    @id = 0
  end
end