require 'pathname'

class DTP
  attr_reader :busy

  def initialize
    @bind_ip = nil
    @port = nil
    @socket = nil
    @busy = false
  end



  def closed?; @socket.nil?; end

  def open; raise 'DTP::open not implemented'; end
  def send; raise 'DTP::send not implemented'; end
  def recv; raise 'DTP::recv not implemented'; end

  def close
    begin
      @socket.close unless @socket.nil? || @socket.closed?
      @socket = nil
      @port = nil
      @bind_ip = nil
      true
    rescue => e; puts "<#{self.class}::close> #{e.class}: '#{e}'"; false
    end
  end
end

class DTPPassive < DTP
  def initialize(external_ip)
    super()
    begin
      @socket = TCPServer.new(0)
      @bind_ip = external_ip
      @port = @socket.addr[1]
      @client = nil
    rescue => e; raise e;
    end
  end

  def open
    begin
      @client = @socket.accept
      true
    rescue => e; puts "<#{self.class}::open> #{e.class}: '#{e}'"; false
    end
  end

  def send(mode, data)
    begin
      raise 'Client socket closed' if @client.nil?
      raise 'Timeout' if select(nil, [@client], nil, 20).nil?
      @busy = true
      case mode
        when 'I'; nb = @client.write(data)
        else; nb = @client.write(data.encode(:crlf_newline => :replace))
      end
      @busy = false
      nb
    rescue => e; puts "<#{self.class}::send> #{e.class}: '#{e}'"; false
    end
  end

  def recv #TODO: handle modes
    begin
      raise 'Client socket closed' if @client.nil?
      raise 'Timeout' if select([@client], nil, nil, 20).nil?
      @busy = true
      data = @client.read
      @busy = false
      data
    rescue => e; puts "<#{self.class}::recv> #{e.class}: '#{e}'"; nil
    end
  end

  def close
    begin
      @client.close unless @client.nil? || @client.closed?
      @socket.close unless @socket.nil? || @socket.closed?
      @client = nil
      @socket = nil
      @port = nil
      @bind_ip = nil
      true
    rescue => e; puts "<#{self.class}::close> #{e.class}: '#{e}'"; false
    end
  end

  def conn_info
    (@bind_ip.split('.') << @port / 256 << @port % 256).join(',')
  end
end

class DTPActive < DTP
  def initialize(bind, port)
    super()
    @bind_ip = bind
    @port = port
  end

  def open
    begin
      @socket = TCPSocket.new(@bind_ip, @port)
      true
    rescue => e; puts "<#{self.class}::open> #{e.class}: '#{e}'"; false
    end
  end

  def send(mode, data)
    begin
      raise 'Client socket closed' if @socket.nil?
      raise 'Timeout' if select(nil, [@socket], nil, 20).nil?
      @busy = true
      case mode
        when 'I'; nb = @socket.write(data)
        else; nb = @socket.write(data.encode(:crlf_newline => :replace))
      end
      @busy = false
      nb
    rescue => e; puts "<#{self.class}::send> #{e.class}: '#{e}'"; false
    end
  end

  def recv
    begin
      raise 'Client socket closed' if @socket.nil?
      raise 'Timeout' if select(nil, [@socket], nil, 20).nil?
      @busy = true
      data = @socket.read
      @busy = false
      data
    rescue => e; puts "<#{self.class}::recv> #{e.class}: '#{e}'"; nil
    end
  end
end
