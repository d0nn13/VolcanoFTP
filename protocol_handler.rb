require_relative 'volcano_log'
require_relative 'ftp_command'
require_relative 'ftp_response'

class ProtocolHandler
  def initialize(session)
    @client = session.client

    @commands = {
        PWD: {obj: FTPCommandPwd, pattern: /^PWD\s*$/i},
        CWD: {obj: FTPCommandCwd, pattern: /^CWD(\s+(?<args>.+))?\s*$/i},
        PASV: {obj: FTPCommandPasv, pattern: /^PASV\s*$/i},
        PORT: {obj: FTPCommandPort, pattern: /^PORT\s+(?<args>(\d{1,3},\s?){5}\d{1,3})\s*$/i},
        LIST: {obj: FTPCommandList, pattern: /^LIST(\s+(?<args>.+))?\s*$/i},
        STOR: {obj: FTPCommandStor, pattern: /^STOR\s+(?<args>.+)\s*$/i},
        RETR: {obj: FTPCommandRetr, pattern: /^RETR\s+(?<args>.+)\s*$/i},
        SYST: {obj: FTPCommandSyst, pattern: /^SYST\s*$/i},
        FEAT: {obj: FTPCommandFeat, pattern: /^FEAT\s*$/i},
        TYPE: {obj: FTPCommandType, pattern: /^TYPE\s+(?<args>A|B|I|L\s+\d{0,2})\s*$/i},
        USER: {obj: FTPCommandUser, pattern: /^USER\s+(?<args>.+)\s*$/i},
        PASS: {obj: FTPCommandPass, pattern: /^PASS(\s+(?<args>.+))?\s*$/i},
        QUIT: {obj: FTPCommandQuit, pattern: /^QUIT\s*$/i}
    }
  end

  # Reads raw data and returns a FTPCommand
  def read_command(cmd_str)
    command = nil
    @commands.each_value { |cmd|
      if cmd[:obj].nil?; next; end
      match = cmd[:pattern].match(cmd_str.chomp)
      p match
      unless match.nil?
        args = match.names.include?('args') && match[:args] || nil
        command = cmd[:obj].new(args)
        break
      end
    }

    if command.nil?
      VolcanoLogError.log_pid(Process.pid, "PI: Command\t<#{cmd_str.strip}> NOK ):")
      send_response(FTPResponse500.new("'#{cmd_str.strip}': command not understood"))
    else
      VolcanoLogSuccess.log_pid(Process.pid, "PI: Command\t<#{command}> OK (:")
    end

    command
  end

  # Send a response to the client
  def send_response(response)
    if response.is_a?(FTPResponse)
      @client.puts(response)
      VolcanoLogInfo.log_pid(Process.pid, "PI: Response\t<#{response}>")
    end
  end
end