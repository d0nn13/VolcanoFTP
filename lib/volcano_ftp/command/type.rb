# ==== TYPE ====
# Sets the transfer mode
class FTPCommandType < FTPCommand
  def initialize(arg)
    super()
    @code = 'TYPE'
    @args << arg unless arg.nil?
  end

  def do(client)
    begin
      session = client.session
      raise FTP530 unless session.logged?
      session.set_mode(@args[0]) unless @args.length.zero?
      FTPResponse200.new

    rescue FTP530; FTPResponse.new(530, "Ya ain't logged.")
    ensure
      session.set_previous_cmd(self)
    end
  end
end