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

# ==== PWD ====
# Transfers the current working directory name
class FTPCommandPwd < FTPCommand
  def initialize(arg)
    super()
    @code = 'PWD'
  end

  def do(client)
    session = client.session
    FTPResponse.new(257, "\"#{session.cwd}\"")
  ensure
    session.set_previous_cmd(self)
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

  def do(client)
    begin
      session = client.session
      path = session.make_path(@args)
      raise FTP550 unless Dir.exists?(session.sys_path(path))
      session.set_cwd(path)
      FTPResponse.new(250, "Directory changed to #{path}")

    rescue FTP550; FTPResponse.new(550, 'CWD command failed')
    rescue => e
      puts self.class, e.class, e, e.backtrace
      FTPResponse500.new
    ensure
      session.set_previous_cmd(self)
    end
  end
end

# ==== CDUP ====
# CWD ..
class FTPCommandCdup < FTPCommandCwd
  def initialize(arg)
    super('..')
    @code = 'CDUP'
  end
end

# ==== LIST ====
# Transfers the contents of the current working directory
class FTPCommandList < FTPCommand
  def initialize(path)
    super()
    @code = 'LIST'
    @args << path unless path.nil?
    @ls_cmd = 'ls -l'
  end

  def do(client)
    begin
      session = client.session
      if @args.length.zero? == false && @args[0].match(/^-/)
        ls_args = @args[0]
        path = session.cwd
      else
        ls_args = ''
        path = session.make_path(@args)
      end

      raise FTP550 unless File.exists?(session.sys_path(path))
      syscall = "#{@ls_cmd} #{ls_args} '#{session.sys_path(path)}' 2> /dev/null"
      raise FTP425 if session.dtp.nil? || session.dtp.open == false

      ret = `#{syscall}`

      @ph.send_response(client, FTPResponse.new(150, 'File status OK.')) if $?.exitstatus.zero?
      raise FTP426 unless session.dtp.send(session.mode, ret)
      FTPResponse.new(226, 'Closing data connection.')

    rescue ClientConnectionLost; nil
    rescue FTP550
      FTPResponse.new(550, "File #{path} does not exist")
    rescue FTP425; FTPResponse.new(425, 'Can\'t open data connection.')
    rescue FTP426; FTPResponse.new(426, 'Connection closed; transfer aborted.')
    rescue => e
      puts self.class, e.class, e, e.backtrace
      FTPResponse500.new
    ensure
      session.dtp.close unless session.dtp.nil?
      session.set_previous_cmd(self)
    end
  end
end

# ==== NLST ====
# Transfers the name list of the current working directory
class FTPCommandNlst < FTPCommandList
  def initialize(path)
    super(path)
    @code = 'NLST'
    @args << path unless path.nil?
    @ls_cmd = 'ls'
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

  def do(client)
    begin
      session = client.session
      path = session.make_path(@args)
      raise FTP550 unless File.exists?(session.sys_path(path)) && File.file?(session.sys_path(path))
      File.delete(session.sys_path(path))
      FTPResponse.new(250, "File \"#{path}\" deleted")

    rescue FTP550; FTPResponse.new(550, "#{@code} command failed")
    rescue => e
      puts self.class, e.class, e, e.backtrace
      FTPResponse500.new
    ensure
      session.set_previous_cmd(self)
    end
  end
end

# ==== MKD ====
# Creates a directory in the server
class FTPCommandMkd < FTPCommand
  def initialize(path)
    super()
    @code = 'MKD'
    @args << path unless path.nil?
  end

  def do(client)
    begin
      session = client.session
      path = session.make_path(@args)
      raise FTP550 if Dir.exists?(session.sys_path(path))
      Dir.mkdir(session.sys_path(path))
      FTPResponse.new(250, "Directory \"#{path}\" created")

    rescue FTP550; FTPResponse.new(550, "#{@code} command failed (directory exists)")
    rescue => e
      puts self.class, e.class, e, e.backtrace
      FTPResponse500.new
    ensure
      session.set_previous_cmd(self)
    end
  end
end

# ==== RMD ====
# Deletes a directory in the server
class FTPCommandRmd < FTPCommand
  def initialize(path)
    super()
    @code = 'RMD'
    @args << path unless path.nil?
  end

  def do(client)
    begin
      session = client.session
      path = session.make_path(@args)
      raise FTP550 unless Dir.exists?(session.sys_path(path))
      Dir.rmdir(session.sys_path(path))
      FTPResponse.new(250, "Directory \"#{path}\" deleted")

    rescue Errno::ENOTEMPTY; FTPResponse.new(550, "#{@code} command failed (directory not empty)")
    rescue FTP550; FTPResponse.new(550, "#{@code} command failed (no such file or directory)")
    rescue => e
      puts self.class, e.class, e, e.backtrace
      FTPResponse500.new
    ensure
      session.set_previous_cmd(self)
    end
  end
end

# ==== RNFR ====
# Rename from
class FTPCommandRnfr < FTPCommand
  attr_reader :source

  def initialize(path)
    super()
    @code = 'RNFR'
    @args << path unless path.nil?
    @source = nil
  end

  def do(client)
    begin
      session = client.session
      path = session.make_path(@args)
      raise FTP550 unless File.exists?(session.sys_path(path))
      @source = path
      FTPResponse.new(350, 'File exists, ready for destination name')

    rescue FTP550; FTPResponse.new(550, "#{@code} command failed (no such file or directory)")
    rescue => e
      puts self.class, e.class, e, e.backtrace
      FTPResponse500.new
    ensure
      session.set_previous_cmd(self)
    end
  end
end

# ==== RNTO ====
# Rename to
class FTPCommandRnto < FTPCommand
  def initialize(path)
    super()
    @code = 'RNTO'
    @args << path unless path.nil?
  end

  def do(client)
    begin
      session = client.session
      source = session.previous_cmd.source
      raise FTP503 if source.nil?
      dest = session.make_path(@args)
      raise FTP550 if File.exists?(session.sys_path(dest))
      File.rename(session.sys_path(source), session.sys_path(dest))
      FTPResponse.new(250, "Successfully renamed \"#{source}\" to \"#{dest}\"")

    rescue FTP503; FTPResponse.new(503, 'Bad sequence of commands')
    rescue FTP550; FTPResponse.new(550, "#{@code} command failed (destination filename exists)")
    rescue => e
      puts self.class, e.class, e, e.backtrace
      FTPResponse500.new
    ensure
      session.set_previous_cmd(self)
    end
  end
end


# ==== SIZE ====
# Size of server file
class FTPCommandSize < FTPCommand
  def initialize(path)
    super()
    @code = 'SIZE'
    @args << path unless path.nil?
  end

  def do(client)
    begin
      session = client.session
      path = session.make_path(@args)
      raise FTP550 unless File.exists?(session.sys_path(path))
      size = File.size(session.sys_path(path))

      FTPResponse.new(213, size)

    rescue FTP550; FTPResponse.new(550, "File #{path} does not exist")
    rescue => e
      puts self.class, e.class, e, e.backtrace
      FTPResponse500.new
    ensure
      session.set_previous_cmd(self)
    end
  end
end

# ==== MDTM ====
# Modification time of server file
class FTPCommandMdtm < FTPCommand
  def initialize(path)
    super()
    @code = 'MDTM'
    @args << path unless path.nil?
  end

  def do(client)
    begin
      session = client.session
      path = session.make_path(@args)
      raise FTP550 unless File.exists?(session.sys_path(path))
      mtime = File.mtime(session.sys_path(path)).strftime('%Y%m%d%H%M%S')

      FTPResponse.new(213, mtime)

    rescue FTP550; FTPResponse.new(550, "File #{path} does not exist")
    rescue => e
      puts self.class, e.class, e, e.backtrace
      FTPResponse500.new
    ensure
      session.set_previous_cmd(self)
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

  def do(client)
    begin
      session = client.session
      dest = session.cwd + Pathname.new(@args[0]).basename
      raise FTP425 unless session.dtp.open
      raise FTP550 unless FileTest.writable?(session.sys_path(dest).dirname)
      @ph.send_response(client, FTPResponse.new(150, 'File status OK.'))

      $log.puts(" -- Starting reception to '#{dest}' --", client.id)
      data = session.dtp.recv

      raise FTP426 if data.nil?
      File.makedirs(session.sys_path(dest.dirname)) unless Dir.exists?(session.sys_path(dest).dirname)
      File.write(session.sys_path(dest), data)
      $log.puts(" -- Reception of '#{dest}' ended --", client.id)

      # session.stats_data[:conn][:transfer_nb] += 1  # Update stats
      # session.stats_data[:transfer][:name] = dest
      # session.stats_data[:transfer][:size] = data.length # Update transferred file size for stat
      # session.stats_data[:transfer][:method] = @code # Update transferred method for stat
      # session.stats.transfered(session.stats_data)

      FTPResponse.new(226, 'Closing data connection.')

    rescue DTPException => e; $log.puts(e.message); raise FTP425
    rescue ClientConnectionLost; nil
    rescue FTP550; FTPResponse(550, 'Destination dir not writable')
    rescue FTP425; FTPResponse425.new
    rescue FTP426; FTPResponse.new(426, 'Connection closed; transfer aborted.')
    rescue => e
      puts self.class, e.class, e, e.backtrace
      FTPResponse500.new
    ensure
      session.dtp.close unless session.dtp.nil?
      session.set_previous_cmd(self)
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

  def do(client)
    begin
      session = client.session
      path = session.make_path(@args)
      raise FTP550 unless File.exists?(session.sys_path(path)) && File.file?(session.sys_path(path))
      raise FTP425 unless session.dtp.open
      @ph.send_response(client, FTPResponse.new(150, 'File status OK.'))

      $log.puts(" -- Starting sending of '#{path}' --", client.id)
      size = session.dtp.send(session.mode, File.binread(session.sys_path(path)))
      raise FTP426 unless size
      $log.puts(" -- Sending of '#{path}' ended --", client.id)

      # session.stats_data[:conn][:transfer_nb] += 1  # Update stats
      # session.stats_data[:transfer][:name] = path
      # session.stats_data[:transfer][:size] = size # Update transfered file size for stat
      # session.stats_data[:transfer][:method] = @code # Update transferred method for stat
      # session.stats.transfered(session.stats_data)

      FTPResponse.new(226, 'Closing data connection.')

    rescue DTPException => e; $log.puts(e.message); raise FTP425
    rescue ClientConnectionLost; nil
    rescue FTP550; FTPResponse.new(550, "File #{path} does not exist")
    rescue FTP425; FTPResponse425.new
    rescue FTP426; FTPResponse.new(426, 'Connection closed; transfer aborted.')
    rescue => e
      puts self.class, e.class, e, e.backtrace
      FTPResponse500.new
    ensure
      session.dtp.close unless session.dtp.nil?
      session.set_previous_cmd(self)
    end
  end
end

# ==== PASV ====
# Activates the DTP passive mode
class FTPCommandPasv < FTPCommand
  def initialize(arg)
    super()
    @code = 'PASV'
  end

  def do(client)
    begin
      session = client.session
      session.set_dtp(DTPPassive.new(session.preferences[:external_ip]))
      FTPResponse.new(227, "Entering passive mode (#{session.dtp.conn_info})")
    rescue => e
      puts self.class, e.class, e, e.backtrace
      FTPResponse500.new
    ensure
      session.set_previous_cmd(self)
    end
  end
end

# ==== PORT ====
# Activates the DTP active mode
class FTPCommandPort < FTPCommand
  def initialize(port)
    super()
    @code = 'PORT'
    @args << port.gsub(/\s/, '')  # remove spaces
  end

  def do(client)
    begin
      session = client.session
      bind = @args[0].split(',')[0..3].join('.')
      port = @args[0].split(',')[4].to_i * 256 + @args[0].split(',')[5].to_i
      session.set_dtp(DTPActive.new(bind, port))
      FTPResponse.new(200, 'Entered active mode')
    rescue => e
      puts self.class, e.class, e, e.backtrace
      FTPResponse500.new
    ensure
      session.set_previous_cmd(self)
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

  def do(client)
    session = client.session
    FTPResponseSystem.new
  ensure
    session.set_previous_cmd(self)
  end
end

# ==== FEAT ====
# Transmit feature list (RFC 2839)
class FTPCommandFeat < FTPCommand
  def initialize(arg)
    super()
    @code = 'FEAT'
  end

  def do(client)
    session = client.session
    FTPResponseFeatures.new
  ensure
    session.set_previous_cmd(self)
  end
end

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

# ==== NOOP ====
# Does nothing. :)
class FTPCommandNoop < FTPCommand
  def initialize(arg)
    super()
    @code = 'NOOP'
  end

  def do(client)
    session = client.session
    FTPResponse.new(200, 'Still here (:')
  ensure
    session.set_previous_cmd(self)
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

  def do(client)
    begin
      session = client.session
      FTPResponse.new(230, "User '#{@args[0]}' accepted")
    ensure
      session.set_previous_cmd(self)
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
end

# ==== QUIT ====
# Terminates the client's session
class FTPCommandQuit < FTPCommand
  def initialize(arg)
    super()
    @code = 'QUIT'
  end

  def do(client)
    session = client.session
    FTPResponseGoodbye.new
  ensure
    session.set_previous_cmd(self)
  end
end
