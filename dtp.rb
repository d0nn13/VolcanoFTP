require 'pathname'

class DTP
  def initialize(session)
    @session = session
    @mode = 'A'
    @bind = '0.0.0.0'
    @port = 0
    @socket = nil
  end

  def set_mode(mode)
    @mode = mode if mode == 'A' || mode == 'I'
  end

  def open; raise Exception.new('DTP::open not implemented'); end
  def send; raise Exception.new('DTP::send not implemented'); end

  def close
    begin
      @socket.close unless @socket.nil? || @socket.closed?
      true
    rescue Exception => e
      puts e, e.backtrace
      false
    end
  end
end


class DTPActive < DTP
  def initialize(session, bind, port)
    super(session)
    @bind = bind
    @port = port
  end

  def open
    begin
      @socket = TCPSocket.new(@bind, @port)
      true
    rescue Errno::ECONNREFUSED
      false
    end
  end

  def send(data)
    begin
      @socket.write(data)
      true
    rescue Exception => e
      puts e, e.backtrace
      false
    end
  end
end


class DTPPassive < DTP
  def initialize(session)
    super(session)
    @socket = TCPServer.new(session.server_ip, 0)
    @port = @socket.addr[1]
    @client = nil
  end

  def open
    begin
      @client = @socket.accept
      true
    rescue Exception => e
      puts e, e.backtrace
      false
    end
  end

  def send(data)
    begin
      nb = @client.write(data)
      @client.close
      nb
    rescue Exception => e
      puts e, e.backtrace
      false
    end
  end

  def conn_info
    (@session.server_ip.split('.') << @port / 256 << @port % 256).join(',')
  end

end