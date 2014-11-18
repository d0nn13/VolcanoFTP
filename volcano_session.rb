require_relative 'protocol_handler'
require_relative 'dtp'
require_relative 'ftp_command'
require_relative 'ftp_response'


class VolcanoSession
  attr_reader :id, :settings, :cwd, :mode, :authentication, :ph, :dtp

  def initialize(server, id, client)
    @id = id
    @settings = server.settings

    @client = client
    @ph = ProtocolHandler.new(@client)
    @dtp = nil

    @cwd = Pathname.new('/')
    @mode = 'A'
    @authentication = -1   # -1: no auth negotiated, 0: USER given, 1: auth OK | TODO: better
  end

  def launch
    VolcanoLog.log("Process spawn for session n° #{@id}", Process.pid)
    @ph.send_response(FTPResponseGreet.new)

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
      VolcanoLog.log(msg, Process.pid)
      @ph.send_response(FTPResponseGoodbye.new)
      reset_dtp
      @client.close

    rescue EOFError, Errno::EPIPE, Errno::ECONNRESET
      msg = "Client disconnected, terminating session n° #{@id}"
      VolcanoLog.log(msg, Process.pid)
      reset_dtp
      @client.close
    end
  end

  def set_cwd(path)
    unless path.is_a?(Pathname); raise TypeError.new('Not a Pathname'); end
    @cwd = path
  end

  def set_mode(mode)
    raise ArgumentError.new('Wrong mode') unless mode.match(/^A|B|I|L$/)
    @mode = mode
  end

  def set_dtp(dtp)
    unless dtp.is_a?(DTP); raise TypeError.new('Not a DTP'); end
    @dtp = dtp
    true
  end

  def reset_dtp
    unless @dtp.nil?
      @dtp.close
      @dtp = nil
    end
  end

  def make_path(args)
    if args.length.zero?
      path = @cwd
    else
      path = Pathname.new(args[0]).expand_path(@cwd)   # TODO: handle ArgumentError: user xxx~ doesn't exist
    end
    path
  end

  def sys_path(path)
    path.sub('/', settings[:root_dir].to_s + '/')
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