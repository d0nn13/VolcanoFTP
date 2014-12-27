# ==== MKD ====
# Creates a directory in the server
class FTPCommandMkd < FTPCommand
  def initialize(path)
    super()
    @code = 'MKD'
    @args << path unless path.nil?
  end

  def do(client)
    begin
      session = client.session
      path = session.make_path(@args)
      raise FTP550 if Dir.exists?(session.sys_path(path))
      Dir.mkdir(session.sys_path(path))
      FTPResponse.new(250, "Directory \"#{path}\" created")

    rescue FTP550; FTPResponse.new(550, "#{@code} command failed (directory exists)")
    rescue => e
      puts self.class, e.class, e, e.backtrace
      FTPResponse500.new
    ensure
      session.set_previous_cmd(self)
    end
  end
end