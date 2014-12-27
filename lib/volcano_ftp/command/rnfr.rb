# ==== RNFR ====
# Rename from
class FTPCommandRnfr < FTPCommand
  attr_reader :source

  def initialize(path)
    super()
    @code = 'RNFR'
    @args << path unless path.nil?
    @source = nil
  end

  def do(client)
    begin
      session = client.session
      path = session.make_path(@args)
      raise FTP550 unless File.exists?(session.sys_path(path))
      @source = path
      FTPResponse.new(350, 'File exists, ready for destination name')

    rescue FTP550; FTPResponse.new(550, "#{@code} command failed (no such file or directory)")
    rescue => e
      puts self.class, e.class, e, e.backtrace
      FTPResponse500.new
    ensure
      session.set_previous_cmd(self)
    end
  end
end