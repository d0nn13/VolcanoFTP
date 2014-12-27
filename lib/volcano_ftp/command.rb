require_relative 'logger'
require_relative 'exception'
require_relative 'protocol_handler'
require_relative 'ftp_response'
require_relative 'dtp'


# Base class for all commands
class FTPCommand
  def initialize
    @ph = ProtocolHandler.get_instance
    @code = 'NaC'  # "Not a Command"
    @args = []
  end

  def do(client); FTPResponse.new(502, 'Command not implemented'); end
  def to_s; "#{@code} #{@args}"; end
end

require_relative('command/pwd')
require_relative('command/cwd')
require_relative('command/list')
require_relative('command/dele')
require_relative('command/mkd')
require_relative('command/rmd')
require_relative('command/rnfr')
require_relative('command/rnto')
require_relative('command/size')
require_relative('command/mdtm')
require_relative('command/stor')
require_relative('command/retr')
require_relative('command/pasv')
require_relative('command/port')
require_relative('command/syst')
require_relative('command/feat')
require_relative('command/type')
require_relative('command/noop')
require_relative('command/user')
require_relative('command/pass')
require_relative('command/quit')

