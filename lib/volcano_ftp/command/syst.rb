# ==== SYST ====
# Transfers the system type to the client
class FTPCommandSyst < FTPCommand
  def initialize(arg)
    super()
    @code = 'SYST'
  end

  def do(client)
    session = client.session
    FTPResponseSystem.new
  ensure
    session.set_previous_cmd(self)
  end
end