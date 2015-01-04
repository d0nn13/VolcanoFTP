# ==== PASV ====
# Activates the DTP passive mode
class FTPCommandPasv < FTPCommand
  def initialize(arg)
    super()
    @code = 'PASV'
  end

  def do(client)
    begin
      session = client.session
      raise FTP530 unless session.logged?
      session.set_dtp(DTPPassive.new(session.preferences[:external_ip]))
      FTPResponse.new(227, "Entering passive mode (#{session.dtp.conn_info})")

    rescue FTP530; FTPResponse.new(530, "Ya ain't logged.")
    rescue => e
      puts self.class, e.class, e, e.backtrace
      FTPResponse500.new
    ensure
      session.set_previous_cmd(self)
    end
  end
end