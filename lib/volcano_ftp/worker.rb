require_relative 'logger'
require_relative 'protocol_handler'

class Worker
  attr_reader :id

  def initialize(server, id)
    @server = server
    @id = id
    @ph = ProtocolHandler.get_instance
  end

  def run
    while 1
      begin
        job = @server.pop_job
        unless job.nil?
          $log.puts("* Worker ##{@id}: #{job}")
          @ph.send_response(job.requester, job.do)
        end

      rescue ClientConnectionLost => e
        @server.handle_clientconnectionlost(e.client)
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