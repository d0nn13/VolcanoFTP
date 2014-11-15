#!/usr/bin/env ruby

require 'socket'
require_relative 'volcano_log'
require_relative 'volcano_configurator'
require_relative 'volcano_session'

class TCPSocket
  def to_s
    "#{peeraddr(:hostname)[2]} (#{peeraddr(:hostname)[3]}:#{peeraddr(:hostname)[1]})"
  end
end

class VolcanoFTP
  attr_reader :settings, :session_id

  def initialize(settings)
    @settings = settings
    @socket = TCPServer.new(@settings[:bind], @settings[:port])
    @sessions = []
    @session_id = 0
    @inactive_time = Time.new(0)
    VolcanoLog.log("Starting VolcanoFTP. [PID=#{Process.pid}]")
  end

  def refresh_sessions
    @sessions.each { |p|
      @sessions.delete(p) unless Process.wait(p, Process::WNOHANG).nil?
    }
  end

  def run
    VolcanoLog.log("Bound to address #{@settings[:bind]}, listening on port #{@settings[:port]}")

    begin
      while 1
        refresh_sessions
        if select([@socket], nil, nil, 0.2)
          client = @socket.accept
          VolcanoLog.log("\nClient connected : #{client}")
          @session_id += 1
          @sessions << fork { VolcanoSession.new(self, client).launch }
        end
      end
    rescue SystemExit, Interrupt
      sess_nb = @sessions.length
      unless sess_nb.zero?
        msg = "\nWaiting for #{sess_nb} remaining process#{sess_nb > 1 && 'es' || ''} to finish..."
        VolcanoLog.log(msg)
      end
      Process.waitall.each { |pid| @sessions.delete(pid[0]) }
      VolcanoLog.log("\nLeaving.")
    end

  end
end

begin
  VolcanoFTP.new(VolcanoConfigurator.new.settings).run
rescue SocketError, Errno::EADDRINUSE, Errno::EADDRNOTAVAIL => e
  puts e, e.backtrace
rescue Exception => e
  VolcanoLog.log("Uncaught exception : #{e}")
end
