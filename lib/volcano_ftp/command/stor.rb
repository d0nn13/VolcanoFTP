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
      raise FTP530 unless session.logged?
      dest = session.cwd + Pathname.new(@args[0]).basename
      raise FTP425 unless session.dtp.open
      raise FTP550 unless FileTest.writable?(session.sys_path(dest).dirname)
      @ph.send_response(client, FTPResponse.new(150, 'File status OK.'))

      $log.puts(" -- Reception of '#{dest}' started --", client.id)
      start_ts = Time.now
      data = session.dtp.recv

      raise FTP426 if data.nil?
      File.makedirs(session.sys_path(dest.dirname)) unless Dir.exists?(session.sys_path(dest).dirname)
      File.write(session.sys_path(dest), data)
      t_xfer = Time.at(Time.now - start_ts).localtime('+00:00').strftime('%H:%M:%S.%6N')
      $log.puts(" -- Reception of '#{dest}' ended (#{t_xfer}) --", client.id)

      # session.stats_data[:conn][:transfer_nb] += 1  # Update stats
      # session.stats_data[:transfer][:name] = dest
      # session.stats_data[:transfer][:size] = data.length # Update transferred file size for stat
      # session.stats_data[:transfer][:method] = @code # Update transferred method for stat
      # session.stats.transfered(session.stats_data)

      FTPResponse.new(226, 'Closing data connection.')

    rescue FTP530; FTPResponse.new(530, "Ya ain't logged.")
    rescue DTPException => e; $log.puts(e.message); FTPResponse425.new
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