require 'net/http'
require 'byebug'

class VisualReviewWatir

  def initialize(options = {})
    @hostname = options[:hostname] ||= "localhost"
    @port = options[:port] ||= 7000
  end

  def hostname
    @hostname
  end

  def port
    @port
  end

  def server_active?
    uri = URI.parse("#{@hostname}:#{@port}")
    http = Net::HTTP.new(uri.host,uri.port)
    begin
      response = http.get_response(uri)
    rescue
      response = nil
    end
    return true if response && response.code == "200"
    false
  end
end
