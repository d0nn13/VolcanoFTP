# ==== PWD ====
# Transfers the current working directory name
class FTPCommandPwd < FTPCommand
  def initialize(arg)
    super()
    @code = 'PWD'
  end

  def do(client)
    session = client.session
    FTPResponse.new(257, "\"#{session.cwd}\"")
  ensure
    session.set_previous_cmd(self)
  end
end