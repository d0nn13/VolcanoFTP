# ==== PORT ====
# Activates the DTP active mode
class FTPCommandPort < FTPCommand
  def initialize(port)
    super()
    @code = 'PORT'
    @args << port.gsub(/\s/, '')  # remove spaces
  end

  def do(client)
    begin
      session = client.session
      bind = @args[0].split(',')[0..3].join('.')
      port = @args[0].split(',')[4].to_i * 256 + @args[0].split(',')[5].to_i
      session.set_dtp(DTPActive.new(bind, port))
      FTPResponse.new(200, 'Entered active mode')
    rescue => e
      puts self.class, e.class, e, e.backtrace
      FTPResponse500.new
    ensure
      session.set_previous_cmd(self)
    end
  end
end
