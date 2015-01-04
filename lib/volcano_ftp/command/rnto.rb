# ==== RNTO ====
# Rename to
class FTPCommandRnto < FTPCommand
  def initialize(path)
    super()
    @code = 'RNTO'
    @args << path unless path.nil?
  end

  def do(client)
    begin
      session = client.session
      raise FTP530 unless session.logged?
      source = session.previous_cmd.source
      raise FTP503 if source.nil?
      dest = session.make_path(@args)
      raise FTP550 if File.exists?(session.sys_path(dest))
      File.rename(session.sys_path(source), session.sys_path(dest))
      FTPResponse.new(250, "Successfully renamed \"#{source}\" to \"#{dest}\"")

    rescue FTP530; FTPResponse.new(530, "Ya ain't logged.")
    rescue FTP503; FTPResponse.new(503, 'Bad sequence of commands')
    rescue FTP550; FTPResponse.new(550, "#{@code} command failed (destination filename exists)")
    rescue => e
      puts self.class, e.class, e, e.backtrace
      FTPResponse500.new
    ensure
      session.set_previous_cmd(self)
    end
  end
end
