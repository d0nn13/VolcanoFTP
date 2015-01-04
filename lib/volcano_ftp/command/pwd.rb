# ==== PWD ====
# Transfers the current working directory name
class FTPCommandPwd < FTPCommand
  def initialize(arg)
    super()
    @code = 'PWD'
  end

  def do(client)
    begin
      session = client.session
      raise FTP530 unless session.logged?
      raise FTP530 unless session.logged?
      FTPResponse.new(257, "\"#{session.cwd}\"")

    rescue FTP530; FTPResponse.new(530, "Ya ain't logged.")
    ensure
      session.set_previous_cmd(self)
    end
  end
end