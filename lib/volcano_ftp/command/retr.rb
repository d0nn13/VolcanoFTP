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

      $log.puts(" -- Sending of '#{path}' started --", client.id)
      start_ts = Time.now
      size = session.dtp.send(session.mode, File.binread(session.sys_path(path)))
      
      raise FTP426 unless size
      t_xfer = Time.at(Time.now - start_ts).localtime('+00:00').strftime('%H:%M:%S.%6N')
      $log.puts(" -- Sending of '#{path}' ended (#{t_xfer}) --", client.id)

      # session.stats_data[:conn][:transfer_nb] += 1  # Update stats
      # session.stats_data[:transfer][:name] = path
      # session.stats_data[:transfer][:size] = size # Update transfered file size for stat
      # session.stats_data[:transfer][:method] = @code # Update transferred method for stat
      # session.stats.transfered(session.stats_data)

      FTPResponse.new(226, 'Closing data connection.')

    rescue DTPException => e; $log.puts(e.message); FTPResponse425.new
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
