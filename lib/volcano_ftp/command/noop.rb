# ==== NOOP ====
# Does nothing. :)
class FTPCommandNoop < FTPCommand
  def initialize(arg)
    super()
    @code = 'NOOP'
  end

  def do(client)
    session = client.session
    FTPResponse.new(200, 'Still here (:')
  ensure
    session.set_previous_cmd(self)
  end
end
