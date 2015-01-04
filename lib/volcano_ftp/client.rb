require_relative 'session'

class Client
  attr_reader :server, :socket, :session, :id, :name

  def initialize(server, socket, id)
    @server = server
    @socket = socket
    @session = Session.new(self)
    @id = id
    @name = nil
    @stats_handler = nil
    @socket_info = "#{socket.peeraddr(:hostname)[2]} (#{socket.peeraddr(:hostname)[3]}:#{socket.peeraddr(:hostname)[1]})"
  end

  def set_name(name)
    raise TypeError.new('Not a String') unless name.is_a?(String)
    @name = name
  end

  def set_stats_handler(handler)
    @stats_handler = handler
  end

  def requesting?
    !select([@socket], nil, nil, 0).nil?
  end

  def to_s
    name = "#{@socket_info}"
    name += " (#{@name})" unless @name.nil?
    name
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