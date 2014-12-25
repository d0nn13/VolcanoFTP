class FTP400 < StandardError; end
class FTP425 < FTP400; end
class FTP426 < FTP400; end

class FTP500 < StandardError; end
class FTP550 < FTP500; end

class ClientConnectionLost < RuntimeError
  attr_reader :client

  def initialize(client)
    @client = client
  end
end

