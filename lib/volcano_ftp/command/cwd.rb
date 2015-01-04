# ==== CWD ====
# Change the server's working directory (CWD) for the current session
class FTPCommandCwd < FTPCommand
  def initialize(path)
    super()
    @code = 'CWD'
    @args << path unless path.nil?
  end

  def do(client)
    begin
      session = client.session
      raise FTP530 unless session.logged?
      path = session.make_path(@args)
      raise FTP550 unless Dir.exists?(session.sys_path(path))
      session.set_cwd(path)
      FTPResponse.new(250, "Directory changed to #{path}")

    rescue FTP530; FTPResponse.new(530, 'Ya ain\'t logged.')
    rescue FTP550; FTPResponse.new(550, 'CWD command failed (directory does not exist)')
    rescue => e
      puts self.class, e.class, e, e.backtrace
      FTPResponse500.new
    ensure
      session.set_previous_cmd(self)
    end
  end
end

# ==== CDUP ====
# CWD ..
class FTPCommandCdup < FTPCommandCwd
  def initialize(arg)
    super('..')
    @code = 'CDUP'
  end
end