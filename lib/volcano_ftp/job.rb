require_relative 'client'
require_relative 'command'

class Job
  attr_reader :requester, :request

  def initialize(client, request)
    return if client.nil? or request.nil?
    @requester = client
    @request = request
  end

  def do
    @request.do(@requester)
  end

  def to_s
    "#{@requester} -> <#{@request}>"
  end
end