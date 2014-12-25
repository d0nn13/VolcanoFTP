require_relative 'logger'
require_relative 'command'
require_relative 'ftp_response'
require_relative 'job'

class ProtocolHandler
  private
  def initialize
    @commands = {
        PWD:  {obj: FTPCommandPwd,  pattern: /^PWD\s*$/i},
        CWD:  {obj: FTPCommandCwd,  pattern: /^CWD(\s+(?<args>.+))?\s*$/i},
        CDUP: {obj: FTPCommandCdup, pattern: /^CDUP\s*$/i},
        LIST: {obj: FTPCommandList, pattern: /^LIST(\s+(?<args>.+))?\s*$/i},
        NLST: {obj: FTPCommandNlst, pattern: /^NLST(\s+(?<args>.+))?\s*$/i},
        DELE: {obj: FTPCommandDele, pattern: /^DELE\s+(?<args>.+)\s*$/i},
        MKD:  {obj: FTPCommandMkd,  pattern: /^MKD\s+(?<args>.+)\s*$/i},
        RMD:  {obj: FTPCommandRmd,  pattern: /^RMD\s+(?<args>.+)\s*$/i},
        STOR: {obj: FTPCommandStor, pattern: /^STOR\s+(?<args>.+)\s*$/i},
        RETR: {obj: FTPCommandRetr, pattern: /^RETR\s+(?<args>.+)\s*$/i},
        PASV: {obj: FTPCommandPasv, pattern: /^PASV\s*$/i},
        PORT: {obj: FTPCommandPort, pattern: /^PORT\s+(?<args>(\d{1,3},\s?){5}\d{1,3})\s*$/i},
        SYST: {obj: FTPCommandSyst, pattern: /^SYST\s*$/i},
        FEAT: {obj: FTPCommandFeat, pattern: /^FEAT\s*$/i},
        TYPE: {obj: FTPCommandType, pattern: /^TYPE\s+(?<args>(A|B|I)|(L\s+\d{0,2}))\s*$/i},
        NOOP: {obj: FTPCommandNoop, pattern: /^NOOP\s*$/i},
        USER: {obj: FTPCommandUser, pattern: /^USER\s+(?<args>.+)\s*$/i},
        PASS: {obj: FTPCommandPass, pattern: /^PASS(\s+(?<args>.+))?\s*$/i},
        QUIT: {obj: FTPCommandQuit, pattern: /^QUIT\s*$/i}
    }
  end

  public
  def self.get_instance
    @instance = ProtocolHandler.new if @instance.nil?
    @instance
  end

  # Reads raw data and returns a Command
  def read_command(client)
    begin
      cmd_str = nil
      command = nil
      cmd_str = client.socket.readline

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
      $log.puts(">>>>  <#{command}> OK (:", client.id, LOG_SUCCESS)
      command

    rescue RuntimeError
      $log.puts(">>>>  <#{cmd_str.strip}> NOK ):", client.id, LOG_ERROR)
      send_response(client, FTPResponse500.new("'#{cmd_str.strip}': command not understood"))
      nil

    rescue EOFError, Errno::EPIPE, Errno::ECONNRESET
      raise ClientConnectionLost.new(client)
    end

  end

  # Send a response to a client
  def send_response(client, response)
    begin
      if response.is_a?(FTPResponse)
        client.socket.puts(response)
        $log.puts("<<<<  <#{response}>", client.id, LOG_INFO)
      end

    rescue EOFError, Errno::EPIPE, Errno::ECONNRESET
      raise ClientConnectionLost.new(client)
    end
  end

end
