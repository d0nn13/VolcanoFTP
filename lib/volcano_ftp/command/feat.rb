# ==== FEAT ====
# Transmit feature list (RFC 2839)
class FTPCommandFeat < FTPCommand
  def initialize(arg)
    super()
    @code = 'FEAT'
  end

  def do(client)
    session = client.session
    FTPResponseFeatures.new
  ensure
    session.set_previous_cmd(self)
  end
end