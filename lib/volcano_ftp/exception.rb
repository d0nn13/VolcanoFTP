class FTP400 < Exception; end
class FTP425 < FTP400; end
class FTP426 < FTP400; end

class FTP500 < Exception; end
class FTP503 < FTP500; end
class FTP530 < FTP500; end
class FTP550 < FTP500; end

class ClientConnectionLost < RuntimeError
  attr_reader :client

  def initialize(client)
    @client = client
  end
end

class DTPException < Exception; end
