#!/usr/bin/env ruby

require 'socket'
require_relative 'volcano_log'
require_relative 'volcano_settings'
require_relative 'volcano_session'

class TCPSocket
  def to_s
    "#{peeraddr(:hostname)[2]} (#{peeraddr(:hostname)[3]}:#{peeraddr(:hostname)[1]})"
  end
end

class VolcanoFTP
  attr_reader :settings

  def initialize(settings)
    ENV['HOME'] = '/'
    @settings = settings
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
    VolcanoLog.log("Starting VolcanoFTP. [Root dir: '#{settings[:root_dir]}'] [PID: #{Process.pid}]")
    VolcanoLog.log("Bound to address #{@settings[:bind_ip]}, listening on port #{@settings[:port]}")
    sid = 0

    begin
      while 1
        refresh_sessions
        if select([@socket], nil, nil, 0.2)
          client = @socket.accept
          VolcanoLog.log("\nClient connected : #{client}")
          sid += 1
          new_session = VolcanoSession.new(self, sid, client)
          pid = fork {new_session.launch}
          @sessions[pid] = new_session
        end
      end
    rescue SystemExit, Interrupt
      sess_nb = @sessions.length
      unless sess_nb.zero?
        msg = "\nWaiting for #{sess_nb} remaining process#{sess_nb > 1 && 'es' || ''} to finish..."
        VolcanoLog.log(msg)
      end
      Process.waitall.each { |pid| @sessions.delete(pid) }
      VolcanoLog.log("\nLeaving.")
    end

  end
end

begin
  VolcanoFTP.new(VolcanoSettings.new.to_h).run
rescue SystemExit
  ;
rescue SocketError, Errno::EADDRINUSE, Errno::EADDRNOTAVAIL => e
  puts e
rescue Exception => e
  VolcanoLog.log("Uncaught exception: #{e.class} '#{e}'")
  puts e.backtrace
end
