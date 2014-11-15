require_relative 'protocol_handler'
require_relative 'dtp'
require_relative 'ftp_command'
require_relative 'ftp_response'


class VolcanoSession
  attr_reader :server_ip, :client, :ph, :dtp, :authentication, :cwd

  def initialize(server, client)
    VolcanoLog.log_pid(Process.pid, "Process spawn for session n° #{server.session_id}")
    @id = server.session_id
    @server_ip = server.settings[:bind]
    @client = client
    @authentication = -1   # -1: no auth negotiated, 0: USER given, 1: auth OK | TODO: better
    @cwd = Pathname.new(Dir.home)

    @ph = ProtocolHandler.new(self)
    @ph.send_response(FTPResponseGreet.new)
    @dtp = nil
  end

  def launch
    begin
      while 1
        command = @ph.read_command(@client.readline)
        unless command.nil?
          @ph.send_response(command.do(self))

          raise EOFError if command.is_a?(FTPCommandQuit)
        end
      end
    rescue SystemExit, Interrupt
      msg = "Terminating session n° #{@id}"
      VolcanoLog.log_pid(Process.pid, msg)
      @ph.send_response(FTPResponseGoodbye.new)
      reset_dtp
      @client.close

    rescue EOFError, Errno::EPIPE, Errno::ECONNRESET
      msg = "Client disconnected, terminating session n° #{@id}"
      VolcanoLog.log_pid(Process.pid, msg)
      reset_dtp
      @client.close
    end
  end

  def set_cwd(path)
    unless path.is_a?(Pathname); raise Exception.new('Not a Pathname'); end
    @cwd = path
  end

  def set_dtp(dtp)
    unless dtp.is_a?(DTP); raise Exception.new('Not a DTP'); end
    @dtp = dtp
    true
  end

  def reset_dtp
    unless @dtp.nil?
      @dtp.close
      @dtp = nil
    end
  end


  # Handle user authentication (USER|PASS)
  def user_authentication(user, pass=nil)
    unless user.nil?

      # handle user name (exists?)
    end

    unless pass.nil?
      # handle password
    end
    true
  end

end