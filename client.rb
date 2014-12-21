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

end