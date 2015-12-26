require 'net/http'
require 'byebug'
require 'logger'

class VisualReviewWatir
  APIVERSION = 1
  @@logger = Logger.new(STDOUT)
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
    begin
      response = Net::HTTP.get_response(uri)
    rescue
      return false
    end
    return true if response.code == "200"
    false
  end

  def start_run(project_name, suite_name)
    check_api_version
    return create_new_run(project_name, suite_name)
  end

  def create_new_run(project_name, suite_name)
    body = { :projectName => project_name, :suiteName => suite_name }
    response = call_server("post", "runs", body)
    if(response.code.to_i != 201)
      raise RuntimeError, "Something whent wrong, run not created. Expected response code 201, received #{response.code}"
    end

    res_json = JSON.parse(response.body)
    @actual_run = { :id => res_json['id'], :run_date => res_json['startTime'] }
    if(@actual_run[:id])
      @@logger.info "New run created with #{@actual_run[:id]} id"
      return @actual_run
    else
      raise RuntimeError, 'Something whent wrong. Invalid run id returned by Visual Review when creating a new run.'
    end
  end

  def call_server(method, path, body = nil)
    method_call = Object.const_get("Net::HTTP::#{method.capitalize}")
    url = "http://#{@hostname}:#{@port}/api/#{path}"
    uri = URI.parse(url)
    http = Net::HTTP.new(uri.host, uri.port)
    request = method_call.new(uri.request_uri)
    if(body)
      request["Content-Type"] = "application/json"
      request.body = JSON.dump(body)
    end
    response = http.request(request)

    if(response.code.to_i >= 400 && response.code.to_i < 600)
      raise RuntimeError, "Visual Review server returned #{response.code} status and body: #{response.body}"
    end
    response
  end

  def check_api_version
    response = call_server('get','version')
    if(response.body.to_i != APIVERSION)
      raise RuntimeError, "The visual review api version in no longer compatible with VisualReview-Watir gem, please check our site for more information"
    end
  end

  private :create_new_run, :call_server, :check_api_version
end
