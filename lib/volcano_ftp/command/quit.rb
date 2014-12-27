# ==== QUIT ====
# Terminates the client's session
class FTPCommandQuit < FTPCommand
  def initialize(arg)
    super()
    @code = 'QUIT'
  end

  def do(client)
    session = client.session
    FTPResponseGoodbye.new
  ensure
    session.set_previous_cmd(self)
  end
end
