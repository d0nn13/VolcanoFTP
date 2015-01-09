require_relative '../auth'

# ==== PASS ====
# Login command
class FTPCommandPass < FTPCommand
  def initialize(pass)
    super()
    @code = 'PASS'
    @args << pass
  end

  def do(client)
    begin
      session = client.session
      user = session.previous_cmd.user
      raise FTP503 if user.nil?
      pass = @args[0]
      session.set_logged(Auth.grant?(user, pass))
      raise FTP530 unless session.logged?
      client.set_name(user)
      FTPResponse.new(230, "Welcome, '#{user}'.")

    rescue FTP503; FTPResponse.new(503, 'Login with USER first')
    rescue FTP530; FTPResponse.new(530, 'Bad login')
    ensure
      session.set_previous_cmd(self)
    end
  end

  def to_s; "#{@code} [********]"; end
end