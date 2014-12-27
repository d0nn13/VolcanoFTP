# ==== USER ====
# Login command
class FTPCommandUser < FTPCommand
  def initialize(user='anonymous')
    super()
    @code = 'USER'
    @args << user
  end

  def do(client)
    begin
      session = client.session
      FTPResponse.new(230, "User '#{@args[0]}' accepted")
    ensure
      session.set_previous_cmd(self)
    end
  end
end
