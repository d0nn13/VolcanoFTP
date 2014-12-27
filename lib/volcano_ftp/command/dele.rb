# ==== DELE ====
# Deletes server file
class FTPCommandDele < FTPCommand
  def initialize(path)
    super()
    @code = 'DELE'
    @args << path unless path.nil?
  end

  def do(client)
    begin
      session = client.session
      path = session.make_path(@args)
      raise FTP550 unless File.exists?(session.sys_path(path)) && File.file?(session.sys_path(path))
      File.delete(session.sys_path(path))
      FTPResponse.new(250, "File \"#{path}\" deleted")

    rescue FTP550; FTPResponse.new(550, "#{@code} command failed")
    rescue => e
      puts self.class, e.class, e, e.backtrace
      FTPResponse500.new
    ensure
      session.set_previous_cmd(self)
    end
  end
end