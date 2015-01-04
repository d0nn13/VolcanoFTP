# ==== USER ====
# Login command
class FTPCommandUser < FTPCommand
  attr_reader :user

  def initialize(user)
    super()
    @code = 'USER'
    @args << user
    @user = nil
  end

  def do(client)
    begin
      session = client.session
      @user = @args[0]
      FTPResponse.new(331, "Allright, provide #{@user}'s password please")
    ensure
      session.set_previous_cmd(self)
    end
  end
end
