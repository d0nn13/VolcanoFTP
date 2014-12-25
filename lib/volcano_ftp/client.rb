require_relative 'session'

class Client
  attr_reader :server, :socket, :session, :id

  def initialize(server, socket, id)
    @server = server
    @socket = socket
    @socket_info = "#{socket.peeraddr(:hostname)[2]} (#{socket.peeraddr(:hostname)[3]}:#{socket.peeraddr(:hostname)[1]})"
    @session = Session.new(self)
    @id = id
    @stats_handler = nil
  end

  def set_stats_handler(handler)
    @stats_handler = handler
  end

  def to_s
    "#{@socket_info}"
  end
end


class ClientFactory
  def self.get_instance(server)
    @instance = ClientFactory.new(server) if @instance.nil?
    @instance
  end

  def build_client(socket)
    c = Client.new(@server, socket, @id)
    @id += 1
    c
  end

  private
  def initialize(server)
    @server = server
    @id = 0
  end
end