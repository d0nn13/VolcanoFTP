class FTP400 < StandardError; end
class FTP425 < FTP400; end
class FTP426 < FTP400; end

class FTP500 < StandardError; end
class FTP550 < FTP500; end

class FTPResponse
  def initialize(code, message)
    @code = code
    @message = message
  end

  def do(client)
    client.socket.puts(self)
    $log.puts("<<<<  <#{self}>", client.id, LOG_INFO)
  end

  def to_s
    "#{@code.to_s} #{@message}"
  end

end

class FTPResponse200 < FTPResponse
  def initialize(message='OK')
    super(200, message)
  end
end

class FTPResponse250 < FTPResponse
  def initialize(message='Requested file action completed')
    super(250, message)
  end
end

class FTPResponse425 < FTPResponse
  def initialize(message='Can\'t open data connection.')
    super(425, message)
  end
end

class FTPResponse500 < FTPResponse
  def initialize(message='Error')
    super(500, message)
  end
end

class FTPResponse502 < FTPResponse
  def initialize(message='Command not implemented')
    super(502, message)
  end
end

class FTPResponseSystem < FTPResponse
  def initialize(message='UNIX Type: L8')
    super(215, message)
  end
end

class FTPResponseFeatures < FTPResponse
  def initialize(features=['UTF8'])
    super(211, features.join('\r\n'))
  end

  def to_s
    "#{@code}-Features\r\n#{@message}\r\n#{@code} End"
  end
end

class FTPResponseGreet < FTPResponse
  def initialize(message='Welcome to VolcanoFTP server')
    super(220, message)
  end
end

class FTPResponseGoodbye < FTPResponse
  def initialize(message='Good bye!')
    super(221, message)
  end
end