require_relative 'client'
require_relative 'ftp_command'

class Job
  attr_reader :client, :request

  def initialize(client, request)
    if client.nil? or request.nil?
      return nil
    end

    @client = client
    @request = request
  end

  def do
      @request.do(@client)
  end
end