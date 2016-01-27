require 'net/http'
require 'logger'
require 'json'
require 'watir-webdriver'
require 'securerandom'
require 'multipart_body'
require 'byebug'

class VisualReviewWatir
  attr_reader :hostname, :port, :actual_run

  APIVERSION = 1
  @@logger = Logger.new(STDOUT)
  def initialize(options = {})
    @hostname = options[:hostname] ||= 'localhost'
    @port = options[:port] ||= 7000
  end

  def server_active?
    uri = URI.parse("http://#{@hostname}:#{@port}")
    begin
      response = Net::HTTP.get_response(uri)
    rescue
      return false
    end
    return true if response.code == '200'
    false
  end

  def start_run(project_name, suite_name)
    check_api_version
    create_new_run(project_name, suite_name)
  end

  def take_screenshot(name, browser)
    screenshot_bin = browser.screenshot.png
    parts = []
    parts << Part.new(name: 'screenshotName', body: name, content_type: 'text/plain')
    parts << Part.new(name: 'properties', body: { browser: browser.name.to_s }.to_json, content_type: 'application/json')
    parts << Part.new(name: 'meta', body: '{}', content_type: 'application/json')
    parts << Part.new(name: 'file', body: screenshot_bin, filename: 'file.png', content_type: 'image/png')

    unless actual_run[:id]
      @@logger.error 'Something whent wrong. Could not send screenshot to Visual Review due we could not find run id'
      fail RuntimeError
    end

    response = call_server('post', "runs/#{actual_run[:id]}/screenshots", nil, parts)
    response_body = JSON.parse(response.body)
    if response.code.to_i != 201
      @@logger.error "Was expected response code 201, received #{response.code}. Body: #{response_body}"
      fail RuntimeError
    end
    @@logger.info 'New screenshot saved!'
    response_body
  end

  private
    def create_new_run(project_name, suite_name)
      body = { projectName: project_name, suiteName: suite_name }
      response = call_server('post', 'runs', body)
      if response.code.to_i != 201
        @@logger.error "Something went wrong, run not created. Expected response code 201, received #{response.code}"
        fail RuntimeError
      end

      res_json = JSON.parse(response.body)
      @actual_run = { id: res_json['id'], run_date: res_json['startTime'] }
      if actual_run[:id]
        @@logger.info "New run created with id #{@actual_run[:id]}"
        return actual_run
      else
        @@logger.error 'Something went wrong. Invalid run id returned by Visual Review when creating a new run.'
        fail RuntimeError
      end
    end

    def call_server(method, path, body = nil, multipart_data = nil)
      method_call = Object.const_get("Net::HTTP::#{method.capitalize}")
      url = "http://#{@hostname}:#{@port}/api/#{path}"
      uri = URI.parse(url)
      http = Net::HTTP.new(uri.host, uri.port)
      request = method_call.new(uri.request_uri)
      if body
        request['Content-Type'] = 'application/json'
        request.body = JSON.dump(body)
      end

      if multipart_data
        boundary = SecureRandom.hex
        multipart = MultipartBody.new multipart_data, boundary
        request.body = multipart.to_s
        request['Cookie'] = 'Name=Value; OtherName=OtherValue'
        request['Connection'] = 'keep-alive'
        request['Content-Type'] = "multipart/form-data; boundary=#{boundary}"
      end

      response = http.request(request)

      if response.code.to_i >= 400 && response.code.to_i < 600
        @@logger.error "Visual Review server returned #{response.code} status and body: #{response.body}"
        fail RuntimeError
      end
      response
    end

    def check_api_version
      response = call_server('get', 'version')
      if response.body.to_i != APIVERSION
        @@logger.error 'The visual review api version in no longer compatible with VisualReview-Watir gem, please check our site for more information'
        fail RuntimeError
      end
      nil
    end
end
