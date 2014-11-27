require_relative 'protocol_handler'
require_relative 'dtp'
require_relative 'ftp_command'
require_relative 'ftp_response'
require_relative 'volcano_stats'


class VolcanoSession
  attr_reader :sid, :settings, :cwd, :mode, :authentication, :ph, :dtp

  def initialize(server, id, client)
    @sid = id
    @settings = server.settings

    @client = client
    @ph = ProtocolHandler.new(@client, @sid)
    @dtp = nil

    @cwd = Pathname.new('/')
    @mode = 'A'
    @authentication = -1   # -1: no auth negotiated, 0: USER given, 1: auth OK | TODO: better

    @stat_conn = {:user => client, :duration => 0, :transfer_nb=> 0, :start_time=> Time.now}
    @stat_transfered = {:speed => 0, :size=> 0}
  end

  def launch
    $log.puts('New process spawn', @sid)
    @ph.send_response(FTPResponseGreet.new)

    begin
      while 1
        command = @ph.read_command(@client.readline)

        unless command.nil?
          if command.is_a?(FTPCommandRetr) || command.is_a?(FTPCommandStor)
            @stat_conn[:transfer_nb] += 1
          end
          @ph.send_response(command.do(self))
          raise EOFError if command.is_a?(FTPCommandQuit)
        end
      end

    rescue SystemExit, Interrupt
      @stat_conn[:duration] = Time.now
      VolcanoStats.new(@stat_conn)

      msg = 'Terminating session'
      $log.puts(msg, @sid)
      @ph.send_response(FTPResponseGoodbye.new)
      reset_dtp
      @client.close

    rescue EOFError, Errno::EPIPE, Errno::ECONNRESET
      @stat_conn[:duration] = Time.now
      stat = VolcanoStats.new
      stat.connexion(@stat_conn)
      stat.transfered(@stat_transfered)

      msg = 'Client disconnected'
      $log.puts(msg, @sid)
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