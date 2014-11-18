require_relative 'ftp_response'
require_relative 'dtp'

# Base class for all commands
class FTPCommand
  def initialize
    @code = 'NaC'  # "Not a Command"
    @args = []
  end

  def do(session); FTPResponse502.new; end
  def to_s; "#{@code} #{@args}"; end
end

# ==== PWD ====
# Transfers the current working directory name
class FTPCommandPwd < FTPCommand
  def initialize(arg)
    super()
    @code = 'PWD'
  end

  def do(session)
    FTPResponse.new(257, "\"#{session.cwd}\"")
  end
end

# ==== CWD ====
# Change the server's working directory (CWD) for the current session
class FTPCommandCwd < FTPCommand
  def initialize(path)
    super()
    @code = 'CWD'
    @args << path unless path.nil?
  end

  def do(session)
    begin
      path = session.make_path(@args)
      raise FTP550 unless Dir.exists?(session.sys_path(path))
      session.set_cwd(path)
      FTPResponse250.new("Directory changed to #{path}")

    rescue FTP550; FTPResponse.new(550, 'CWD command failed')
    rescue => e
      puts self.class, e.class, e, e.backtrace
      FTPResponse500.new
    end
  end
end

# ==== PASV ====
# Activates the DTP's passive mode
class FTPCommandPasv < FTPCommand
  def initialize(arg)
    super()
    @code = 'PASV'
  end

  def do(session)
    begin
      session.set_dtp(DTPPassive.new(session.external_ip))
      FTPResponse.new(227, "Entering passive mode (#{session.dtp.conn_info})")
    rescue => e
      puts self.class, e.class, e, e.backtrace
      FTPResponse500.new
    end
  end
end

# ==== PORT ====
# Activates the DTP's active mode
class FTPCommandPort < FTPCommand
  def initialize(port)
    super()
    @code = 'PORT'
    @args << port.gsub(/\s/, '')  # remove spaces
  end

  def do(session)
    begin
      bind = @args[0].split(',')[0..3].join('.')
      port = @args[0].split(',')[4].to_i * 256 + @args[0].split(',')[5].to_i
      session.set_dtp(DTPActive.new(bind, port))
      FTPResponse200.new('Entered active mode')
    rescue => e
      puts self.class, e.class, e, e.backtrace
      FTPResponse500.new
    end
  end
end

# ==== LIST ====
# Transfers the contents of the current working directory
class FTPCommandList < FTPCommand
  def initialize(path)
    super()
    @code = 'LIST'
    @args << path unless path.nil?
  end

  def do(session)
    begin
      if @args.length.zero? == false && @args[0].match(/^-/)
        ls_args = @args[0]
        path = session.cwd
      else
        ls_args = ''
        path = session.make_path(@args)
      end
      syscall = "ls -l #{ls_args} '#{session.sys_path(path)}'"
      raise FTP425 if session.dtp.nil? || session.dtp.open.nil? || session.dtp.closed?

      ret = `#{syscall}`

      session.ph.send_response(FTPResponse.new(150, 'File status OK.')) if $?.exitstatus.zero?
      raise FTP426 unless session.dtp.send(ret)
      FTPResponse.new(226, 'Closing data connection.') if session.dtp.close

    rescue FTP425; session.dtp.close; FTPResponse425.new
    rescue FTP426; session.dtp.close; FTPResponse.new(426, 'Connection closed; transfer aborted.')
    rescue => e
      puts self.class, e.class, e, e.backtrace
      FTPResponse500.new
    end
  end
end

# ==== STOR ====
# Transfers file from client to server
class FTPCommandStor < FTPCommand
  def initialize(path)
    super()
    @code = 'STOR'
    @args << path unless path.nil?
  end

  def do(session)
    begin
      dest = session.cwd + Pathname.new(@args[0]).basename
      raise FTP425 unless session.dtp.open
      session.ph.send_response(FTPResponse.new(150, 'File status OK.')) # TODO: if can write!!

      data = session.dtp.recv
      raise FTP426 if data.nil? || data.length.zero?

      File.write(session.sys_path(dest), data)
      FTPResponse.new(226, 'Closing data connection.') if session.dtp.close

    rescue FTP425; session.dtp.close; FTPResponse425.new
    rescue FTP426; session.dtp.close; FTPResponse.new(426, 'Connection closed; transfer aborted.')
    rescue => e
      puts self.class, e.class, e, e.backtrace
      FTPResponse500.new
    end
  end
end

# ==== RETR ====
# Transfers file from server to client
class FTPCommandRetr < FTPCommand
  def initialize(path)
    super()
    @code = 'RETR'
    @args << path unless path.nil?
  end

  def do(session)
    begin
      path = session.make_path(@args)
      raise 'File does not exist' unless File.exists?(session.sys_path(path)) # TODO: real ftp error
      raise FTP425 unless session.dtp.open
      session.ph.send_response(FTPResponse.new(150, 'File status OK.')) # TODO: if can read!!

      raise FTP426 unless session.dtp.send(File.binread(session.sys_path(path)))

      FTPResponse.new(226, 'Closing data connection.') if session.dtp.close

    rescue FTP425; session.dtp.close; FTPResponse425.new
    rescue FTP426; session.dtp.close; FTPResponse.new(426, 'Connection closed; transfer aborted.')
    rescue => e
      puts self.class, e.class, e, e.backtrace
      FTPResponse500.new
    end
  end
end

# ==== DELE ====
# Deletes server file
class FTPCommandDele < FTPCommand
  def initialize(path)
    super()
    @code = 'DELE'
    @args << path unless path.nil?
  end

  def do(session)
    begin
      path = session.make_path(@args)
      raise FTP550 unless File.exists?(session.sys_path(path))
      File.delete(session.sys_path(path))
      FTPResponse250.new("File \"#{path}\" deleted")

    rescue FTP550; FTPResponse.new(550, 'DELE command failed')
    rescue => e
      puts self.class, e.class, e, e.backtrace
      FTPResponse500.new
    end
  end
end

# ==== SYST ====
# Transfers the system type to the client
class FTPCommandSyst < FTPCommand
  def initialize(arg)
    super()
    @code = 'SYST'
  end

  def do(session)
    FTPResponseSystem.new
  end
end

# ==== FEAT ====
# Transmit feature list
class FTPCommandFeat < FTPCommand
  def initialize(arg)
    super()
    @code = 'FEAT'
  end

  def do(session)
    FTPResponseFeatures.new
  end
end

# ==== TYPE ====
# Sets the transfert mode
class FTPCommandType < FTPCommand
  def initialize(arg)
    super()
    @code = 'TYPE'
    @args << arg unless arg.nil?
  end

  def do(session)
    FTPResponse200.new
  end
end

# ==== USER ====
# Login command
class FTPCommandUser < FTPCommand
  def initialize(user='anonymous')
    super()
    @code = 'USER'
    @args << user
  end

  def do(session)
    begin
      # TODO user login stuff
      # session.server_user_login(@args[0].to_s, nil)
      FTPResponse.new(230, "User '#{@args[0]}' accepted")
    rescue => e
      puts self.class, e.class, e, e.backtrace
      FTPResponse500.new
    end
  end
end

# ==== PASS ====
# Login command
class FTPCommandPass < FTPCommand
  def initialize(pass='anonymous')
    super()
    @code = 'PASS'
    @args << pass
  end

  # def do(session)
    # session.server_user_login(nil, @args[0].to_s)
    # FTPResponse.new(230, "User '#{@args[0]}' accepted")
  # end
end

# ==== QUIT ====
# Terminates the client's session
class FTPCommandQuit < FTPCommand
  def initialize(arg)
    super()
    @code = 'QUIT'
  end

  def do(session)
    FTPResponseGoodbye.new
  end
end
