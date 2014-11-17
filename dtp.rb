require 'pathname'

class DTP
  def initialize(session)
    @session = session
    @mode = nil
    @bind_ip = nil
    @port = nil
    @socket = nil
  end

  def set_mode(mode)
    @mode = mode if mode == 'A' || mode == 'I'
  end

  def closed?; @socket.nil?; end

  def open; raise Exception.new('DTP::open not implemented'); end
  def send; raise Exception.new('DTP::send not implemented'); end
  def recv; raise Exception.new('DTP::recv not implemented'); end

  def close
    begin
      @socket.close unless @socket.nil? || @socket.closed?
      @socket = nil
      @port = nil
      @bind_ip = nil
      true
    rescue Exception
      false
    end
  end
end

class DTPActive < DTP
  def initialize(session, bind, port)
    super(session)
    @bind_ip = bind
    @port = port
  end

  def open
    begin
      @socket = TCPSocket.new(@bind_ip, @port)
      true
    rescue Errno::ECONNREFUSED; false
    end
  end

  def send(data)
    begin
      @socket.write(data)
      true
    rescue ; false
    end
  end
end


class DTPPassive < DTP
  def initialize(session)
    super(session)
    begin
      @socket = TCPServer.new(session.server_ip, 0)
      @bind_ip = session.external_ip
      @port = @socket.addr[1]
      @client = nil
    rescue => e; raise e
    end
  end

  def open
    begin
      return false if closed?
      @client = @socket.accept
      true
    rescue; false
    end
  end

  def send(data)
    begin
      nb = @client.write(data)
      @client.close
      nb
    rescue; false
    end
  end

  def recv
    begin
      data = @client.read
      @client.close
      data
    rescue; nil
    end
  end

  def conn_info
    (@bind_ip.split('.') << @port / 256 << @port % 256).join(',')
  end
end