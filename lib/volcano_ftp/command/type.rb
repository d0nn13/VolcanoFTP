# ==== TYPE ====
# Sets the transfer mode
class FTPCommandType < FTPCommand
  def initialize(arg)
    super()
    @code = 'TYPE'
    @args << arg unless arg.nil?
  end

  def do(client)
    session = client.session
    session.set_mode(@args[0]) unless @args.length.zero?
    FTPResponse200.new
  ensure
    session.set_previous_cmd(self)
  end
end