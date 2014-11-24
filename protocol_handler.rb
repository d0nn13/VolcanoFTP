require_relative 'volcano_log'
require_relative 'ftp_command'
require_relative 'ftp_response'

class ProtocolHandler
  def initialize(client, sid)
    @client = client
    @sid = sid
    @commands = {
        PWD: {obj: FTPCommandPwd, pattern: /^PWD\s*$/i},
        CWD: {obj: FTPCommandCwd, pattern: /^CWD(\s+(?<args>.+))?\s*$/i},
        CDUP: {obj: FTPCommandCdup, pattern: /^CDUP\s*$/i},
        MKD: {obj: FTPCommandMkd, pattern: /^MKD\s+(?<args>.+)\s*$/i},
        RMD: {obj: FTPCommandRmd, pattern: /^RMD\s+(?<args>.+)\s*$/i},
        PASV: {obj: FTPCommandPasv, pattern: /^PASV\s*$/i},
        PORT: {obj: FTPCommandPort, pattern: /^PORT\s+(?<args>(\d{1,3},\s?){5}\d{1,3})\s*$/i},
        LIST: {obj: FTPCommandList, pattern: /^LIST(\s+(?<args>.+))?\s*$/i},
        NLST: {obj: FTPCommandNlst, pattern: /^NLST(\s+(?<args>.+))?\s*$/i},
        STOR: {obj: FTPCommandStor, pattern: /^STOR\s+(?<args>.+)\s*$/i},
        RETR: {obj: FTPCommandRetr, pattern: /^RETR\s+(?<args>.+)\s*$/i},
        DELE: {obj: FTPCommandDele, pattern: /^DELE\s+(?<args>.+)\s*$/i},
        SYST: {obj: FTPCommandSyst, pattern: /^SYST\s*$/i},
        FEAT: {obj: FTPCommandFeat, pattern: /^FEAT\s*$/i},
        TYPE: {obj: FTPCommandType, pattern: /^TYPE\s+(?<args>(A|B|I)|(L\s+\d{0,2}))\s*$/i},
        NOOP: {obj: FTPCommandNoop, pattern: /^NOOP\s*$/i},
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
      $log.puts(">>>>  <#{command}> OK (:", @sid, LOG_SUCCESS)
      command

    rescue RuntimeError
      $log.puts(">>>>  <#{cmd_str.strip}> NOK ):", @sid, LOG_ERROR)
      send_response(FTPResponse500.new("'#{cmd_str.strip}': command not understood"))
      nil
    end
  end

  # Send a response to the client
  def send_response(response)
    if response.is_a?(FTPResponse)
      @client.puts(response)
      $log.puts("<<<<  <#{response}>", @sid, LOG_INFO)
    end
  end
end