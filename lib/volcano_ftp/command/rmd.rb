# ==== RMD ====
# Deletes a directory in the server
class FTPCommandRmd < FTPCommand
  def initialize(path)
    super()
    @code = 'RMD'
    @args << path unless path.nil?
  end

  def do(client)
    begin
      session = client.session
      path = session.make_path(@args)
      raise FTP550 unless Dir.exists?(session.sys_path(path))
      Dir.rmdir(session.sys_path(path))
      FTPResponse.new(250, "Directory \"#{path}\" deleted")

    rescue Errno::ENOTEMPTY; FTPResponse.new(550, "#{@code} command failed (directory not empty)")
    rescue FTP550; FTPResponse.new(550, "#{@code} command failed (no such file or directory)")
    rescue => e
      puts self.class, e.class, e, e.backtrace
      FTPResponse500.new
    ensure
      session.set_previous_cmd(self)
    end
  end
end
