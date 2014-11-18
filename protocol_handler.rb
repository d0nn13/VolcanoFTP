require_relative 'volcano_log'
require_relative 'ftp_command'
require_relative 'ftp_response'

class ProtocolHandler
  def initialize(client)
    @client = client
    @commands = {
        PWD: {obj: FTPCommandPwd, pattern: /^PWD\s*$/i},
        CWD: {obj: FTPCommandCwd, pattern: /^CWD(\s+(?<args>.+))?\s*$/i},
        PASV: {obj: FTPCommandPasv, pattern: /^PASV\s*$/i},
        PORT: {obj: FTPCommandPort, pattern: /^PORT\s+(?<args>(\d{1,3},\s?){5}\d{1,3})\s*$/i},
        LIST: {obj: FTPCommandList, pattern: /^LIST(\s+(?<args>.+))?\s*$/i},
        STOR: {obj: FTPCommandStor, pattern: /^STOR\s+(?<args>.+)\s*$/i},
        RETR: {obj: FTPCommandRetr, pattern: /^RETR\s+(?<args>.+)\s*$/i},
        DELE: {obj: FTPCommandDele, pattern: /^DELE\s+(?<args>.+)\s*$/i},
        SYST: {obj: FTPCommandSyst, pattern: /^SYST\s*$/i},
        FEAT: {obj: FTPCommandFeat, pattern: /^FEAT\s*$/i},
        TYPE: {obj: FTPCommandType, pattern: /^TYPE\s+(?<args>(A|B|I)|(L\s+\d{0,2}))\s*$/i},
        USER: {obj: FTPCommandUser, pattern: /^USER\s+(?<args>.+)\s*$/i},
        PASS: {obj: FTPCommandPass, pattern: /^PASS(\s+(?<args>.+))?\s*$/i},
        QUIT: {obj: FTPCommandQuit, pattern: /^QUIT\s*$/i}
    }
  end

  # Reads raw data and returns a FTPCommand
  def read_command(cmd_str)
    begin
      command = nil
      @commands.each_value { |cmd|
        if cmd[:obj].nil?; next; end
        match = cmd[:pattern].match(cmd_str.chomp)
        unless match.nil?
          args = match.names.include?('args') && match[:args] || nil
          command = cmd[:obj].new(args)
          break
        end
      }
      raise if command.nil?
      VolcanoLog.log("PI: Command\t<#{command}> OK (:", Process.pid, LOG_SUCCESS)
      command

    rescue RuntimeError
      VolcanoLog.log("PI: Command\t<#{cmd_str.strip}> NOK ):", Process.pid, LOG_ERROR)
      send_response(FTPResponse500.new("'#{cmd_str.strip}': command not understood"))
      nil
    end
  end

  # Send a response to the client
  def send_response(response)
    if response.is_a?(FTPResponse)
      @client.puts(response)
      VolcanoLog.log("PI: Response\t<#{response}>", Process.pid, LOG_INFO)
    end
  end
end