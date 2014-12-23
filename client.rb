require_relative 'volcano_session'

class Client
  attr_reader :server, :socket, :session, :id

  def initialize(server, id, socket)
    @server = server
    @socket = socket
    @id = id
    @stats_handler = nil
    @session = VolcanoSessionThreaded.new(self)
  end

  def set_stats_handler(handler)
    @stats_handler = handler
  end

  def to_s
    "#{socket}(##{@id})"
  end
end


class ClientFactory
  def self.get_instance(server)
    @instance = ClientFactory.new(server) if @instance.nil?
    @instance
  end

  def build_client(socket)
    c = Client.new(@server, @id, socket)
    @id += 1
    c
  end

  private
  def initialize(server)
    @server = server
    @id = 0
  end
end