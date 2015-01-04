# ==== SIZE ====
# Size of server file
class FTPCommandSize < FTPCommand
  def initialize(path)
    super()
    @code = 'SIZE'
    @args << path unless path.nil?
  end

  def do(client)
    begin
      session = client.session
      raise FTP530 unless session.logged?
      path = session.make_path(@args)
      raise FTP550 unless File.exists?(session.sys_path(path))
      size = File.size(session.sys_path(path))

      FTPResponse.new(213, size)

    rescue FTP530; FTPResponse.new(530, "Ya ain't logged.")
    rescue FTP550; FTPResponse.new(550, "File #{path} does not exist")
    rescue => e
      puts self.class, e.class, e, e.backtrace
      FTPResponse500.new
    ensure
      session.set_previous_cmd(self)
    end
  end
end