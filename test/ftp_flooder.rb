#!/usr/bin/env ruby

require 'socket'

class FTPFlooder
  def initialize(ip, port)
    @ip = ip.nil? && '127.0.0.1' || ip
    @port = port.nil? && 4000 || port.to_i

    @socket = TCPSocket.new(@ip, @port)
    @dtpsock = nil
  end

  def run
    resp = @socket.readline.chomp
    puts "\t#{resp}"
    return unless /^2/.match(resp)

    (1..1000).each { |it|
      @socket.puts('PASV')
      puts("\tPASV")
      resp = @socket.readline.chomp
      puts "\t#{resp}"
      return unless /^2/.match(resp)

      port = get_port(resp)
      @dtpsock = TCPSocket.new(@ip, port)
      @socket.puts('LIST')
      puts("\tLIST")
      dtpresp = @dtpsock.read
      resp = @socket.readline.chomp
      puts "\t#{resp}"
      return unless /^1/.match(resp)

      resp = @socket.readline.chomp
      puts "\t#{resp}"
      return unless /^2/.match(resp)

      puts "#{it}\n\n"
      @dtpsock.close
    }
    sleep 3
    @socket.close
  end

  def get_port(resp)
    m = /\((\d{0,3},){4}(?<p1>\d{0,3}),(?<p2>\d{0,3})\)/.match(resp)
    return nil if m.nil?
    return m[:p1].to_i * 256 + m[:p2].to_i
  end
end

begin
  f = FTPFlooder.new(ARGV[0], ARGV[1])
  f.run
  rescue Interrupt
  ;
end
