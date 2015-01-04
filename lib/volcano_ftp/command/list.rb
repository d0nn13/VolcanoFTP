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
      raise FTP530 unless session.logged?
      if @args.length.zero? == false && @args[0].match(/^-/)
        ls_args = @args[0]
        path = session.cwd
      else
        ls_args = ''
        path = session.make_path(@args)
      end

      raise FTP550 unless File.exists?(session.sys_path(path))
      raise FTP425 if session.dtp.nil?
      syscall = "#{@ls_cmd} #{ls_args} '#{session.sys_path(path)}' 2> /dev/null"
      ret = `#{syscall}`
      @ph.send_response(client, FTPResponse.new(150, 'File status OK.')) if $?.exitstatus.zero?

      raise FTP425 unless session.dtp.open
      raise FTP426 unless session.dtp.send(session.mode, ret)
      session.dtp.close
      FTPResponse.new(226, 'Closing data connection.')

    rescue ClientConnectionLost; nil
    rescue FTP530; FTPResponse.new(530, "Ya ain't logged.")
    rescue FTP550; FTPResponse.new(550, "File #{path} does not exist")
    rescue FTP425; FTPResponse.new(425, 'Can\'t open data connection.')
    rescue FTP426; FTPResponse.new(426, 'Connection closed; transfer aborted.')
    rescue => e
      puts self.class, e.class, e, e.backtrace
      FTPResponse500.new
    ensure
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