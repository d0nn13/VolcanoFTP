# ==== MDTM ====
# Modification time of server file
class FTPCommandMdtm < FTPCommand
  def initialize(path)
    super()
    @code = 'MDTM'
    @args << path unless path.nil?
  end

  def do(client)
    begin
      session = client.session
      raise FTP530 unless session.logged?
      path = session.make_path(@args)
      raise FTP550 unless File.exists?(session.sys_path(path))
      mtime = File.mtime(session.sys_path(path)).strftime('%Y%m%d%H%M%S')

      FTPResponse.new(213, mtime)

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
