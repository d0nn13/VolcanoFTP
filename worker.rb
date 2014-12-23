require_relative 'protocol_handler'

class Worker
  attr_reader :id

  def initialize(server, id)
    @server = server
    @id = id
    @ph = ProtocolHandlerThreaded.get_instance
  end

  def handle_job
    while 1
      begin
        req = @server.pop_job
        unless req.nil?
          $log.puts("* Worker ##{@id}: #{req}")
          @ph.send_response(req.client, req.do)
        end

      rescue ClientConnectionLost => e
        @server.handle_clientconnectionlost(e)
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