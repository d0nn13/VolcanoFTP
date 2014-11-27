#!/usr/bin/env ruby

require 'socket'
require_relative 'volcano_log'
require_relative 'volcano_settings'
require_relative 'volcano_session'
require_relative 'volcano_stats'

PID_FILENAME = '.volcano.pid'

class TCPSocket
  def to_s
    "#{peeraddr(:hostname)[2]} (#{peeraddr(:hostname)[3]}:#{peeraddr(:hostname)[1]})"
  end
end

class VolcanoFTP
  attr_reader :settings

  def initialize(settings)
    Signal.trap('TERM') { exit }
    ENV['HOME'] = '/'
    @settings = settings.settings
    @socket = TCPServer.new(@settings[:bind_ip], @settings[:port])
    @sessions = {}
    @inactive_time = Time.new(0)
  end

  def refresh_sessions
    @sessions.each_key { |pid|
      @sessions.delete(pid) unless Process.wait(pid, Process::WNOHANG).nil?
    }
  end

  def run
    $log.puts("Starting VolcanoFTP. [Root dir: '#{settings[:root_dir]}']")
    $log.puts("Bound to address #{@settings[:bind_ip]}, listening on port #{@settings[:port]}")
    File.open(PID_FILENAME, 'w') { |file| file.puts Process.pid.to_s }  # save pid to file
    sid = 0

    begin
      while 1
        refresh_sessions
        if select([@socket], nil, nil, 0.2)
          client = @socket.accept
          $log.puts("Client connected : #{client}")

          sid += 1
          new_session = VolcanoSession.new(self, sid, client)

          pid = fork {new_session.launch}
          @sessions[pid] = new_session
        end
      end
    rescue SystemExit, Interrupt
      VolcanoStats.new
      sess_nb = @sessions.length
      unless sess_nb.zero?
        msg = "Waiting for #{sess_nb} remaining process#{sess_nb > 1 && 'es' || ''} to finish..."
        $log.puts(msg)
        @sessions.each_key { |pid|
          Process.kill('TERM', pid)
          Process.waitpid(pid)
          @sessions.delete(pid)
        }
      end
      $log.puts('Leaving.')
    ensure
      File.delete(PID_FILENAME) if File.exists?(PID_FILENAME) # delete saved pid file
    end
  end

end

begin
  s = VolcanoSettings.new
  $log = VolcanoLog.new(s)
  VolcanoFTP.new(s).run

rescue SystemExit
  ;
rescue LogException, SocketError, Errno::EADDRINUSE, Errno::EADDRNOTAVAIL => e
  puts e
rescue Exception => e
  VolcanoLog.log("Uncaught exception: #{e.class} '#{e}'")
  puts e.backtrace
ensure
  $log.close_log unless $log.nil?
end
