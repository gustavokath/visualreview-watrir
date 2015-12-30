require 'spec_helper'
module Lib
  describe VisualReviewWatir do
    let(:visual_review){ VisualReviewWatir.new }
    let(:post_runs_response_body){"{\"id\":3,\"suiteId\":1,\"branchName\":\"master\",\"baselineTreeId\":1,\"startTime\":\"2015-12-24T15:41:48-0200\",\"endTime\":null,\"status\":\"running\",\"projectId\":1}"}
    let(:post_screenshot_response_body){"{\"id\":21,\"size\":57842,\"properties\":{\"browser\":\"firefox\"},\"meta\":{},\"screenshotName\":\"1\",\"runId\":90,\"imageId\":34}"}
    describe '.initialize' do
      context 'instalize component' do
        it 'with default values' do
          visual_review = VisualReviewWatir.new
          expect(visual_review.hostname).to eql("localhost")
          expect(visual_review.port).to eql(7000)
        end

        it 'with dinamicly values' do
          options = { hostname: "visualreviewwatir.com", port: 80 }
          visual_review = VisualReviewWatir.new(options)
          expect(visual_review.hostname).to eql("visualreviewwatir.com")
          expect(visual_review.port).to eql(80)
        end
      end
    end

    describe '#server_active?' do
      context 'when server is active' do
        it 'rerturns true' do
          seccessful_request = double(Net::HTTPOK, code: "200")
          allow(Net::HTTP).to receive(:get_response).and_return(seccessful_request)
          status = visual_review.server_active?
          expect(status).to be true
        end
        context 'and response is invalid' do
          it 'returns false' do
            request = double(Net::HTTPInternalServerError, code: "500")
            allow(Net::HTTP).to receive(:get_response).and_return(request)
            status = visual_review.server_active?
            expect(status).to be false
          end
        end
      end

      context 'when server is not active' do
        it 'returns false' do
          allow(Net::HTTP).to receive(:get_response).and_raise(Errno::ECONNREFUSED)
          status = visual_review.server_active?

          expect(status).to be false
        end
      end
    end

    describe '#start_run' do
      context 'when api version is compatible' do
        let(:valid_response){double(Net::HTTPCreated, code: "201", body: post_runs_response_body)}
        let(:valid_api){double(Net::HTTPOK, code: "200", body: "1")}

        it 'returns run id info' do
          allow_any_instance_of(Net::HTTP).to receive(:request).and_return(valid_response)
          allow_any_instance_of(VisualReviewWatir).to receive(:check_api_version).and_return(valid_api)
          response = visual_review.start_run("Project0", "Suite1")
          expect(response.has_key?("id"))
        end

        it 'returns run date info' do
          allow_any_instance_of(Net::HTTP).to receive(:request).and_return(valid_response)
          allow_any_instance_of(VisualReviewWatir).to receive(:check_api_version).and_return(valid_api)
          response = visual_review.start_run("Project0", "Suite1")
          expect(response.has_key?("run_date"))
        end

        it 'returns hash' do
          allow_any_instance_of(Net::HTTP).to receive(:request).and_return(valid_response)
          allow_any_instance_of(VisualReviewWatir).to receive(:check_api_version).and_return(valid_api)
          response = visual_review.start_run("Project0", "Suite1")
          expect(response).to be_a(Hash)
        end
      end
      context 'when api version is not compatible' do
        let(:invalid_api){double(Net::HTTPOK, code: "200", body: "50")}
        it 'returns runtimeError exeception' do
          allow_any_instance_of(Net::HTTP).to receive(:request).and_return(invalid_api)
          expect{visual_review.start_run("Project0", "Suite1")}.to raise_error(RuntimeError)
        end
      end
    end

    describe '#create_new_run' do
      context 'when response code is valid' do
        let(:valid_response){double(Net::HTTPCreated, code: "201", body: post_runs_response_body)}
        it 'returns a hash' do
          allow_any_instance_of(Net::HTTP).to receive(:request).and_return(valid_response)
          response = visual_review.send(:create_new_run,"Project0", "Suite1")
          expect(response).to be_a(Hash)
        end

        it 'returns run id info' do
          allow_any_instance_of(Net::HTTP).to receive(:request).and_return(valid_response)
          response = visual_review.send(:create_new_run,"Project0", "Suite1")
          expect(response.has_key?("id"))
        end

        it 'returns run date info' do
          allow_any_instance_of(Net::HTTP).to receive(:request).and_return(valid_response)
          response = visual_review.send(:create_new_run,"Project0", "Suite1")
          expect(response.has_key?("run_date"))
        end

        context 'and run id is not returned' do
          let(:invalid_body){"{\"id\":null,\"suiteId\":1,\"branchName\":\"master\",\"baselineTreeId\":1,\"startTime\":\"2015-12-24T15:41:48-0200\",\"endTime\":null,\"status\":\"running\",\"projectId\":1}"}
          let(:invalid_response){ double(Net::HTTPCreated, code: "201", body: invalid_body)}
          it 'raises an error' do
            allow_any_instance_of(Net::HTTP).to receive(:request).and_return(invalid_response)
            expect{visual_review.send(:create_new_run,"Project0", "Suite1")}.to raise_error(RuntimeError)
          end
        end
      end
      context 'when response code is invalid' do
        let(:invalid_response){ double(Net::HTTPOK, code: "200", body: post_runs_response_body)}
        it 'raises an error' do
          allow_any_instance_of(Net::HTTP).to receive(:request).and_return(invalid_response)
          expect{visual_review.send(:create_new_run,"Project0", "Suite1")}.to raise_error(RuntimeError)
        end
      end
    end

    describe '#call_server' do
      context 'when response is successfull' do
        context 'and request has body' do
          let(:valid_response){double(Net::HTTPCreated, code: "201", body: post_runs_response_body)}
          let(:body) {{ :projectName => "Project0", :suiteName => "Suite1" }}
          it 'returns valid response' do
            allow_any_instance_of(Net::HTTP).to receive(:request).and_return(valid_response)
            response = visual_review.send(:call_server, 'post', 'runs', body)
            expect(response.code).to eql(valid_response.code)
          end
        end

        context 'when request does not have body' do
          let(:valid_response){double(Net::HTTPOK, code: "200", body: post_runs_response_body)}
          it 'returns valid response' do
            allow_any_instance_of(Net::HTTP).to receive(:request).and_return(valid_response)
            response = visual_review.send(:call_server, 'get', 'runs/1')
            expect(response.code).to eql(valid_response.code)
          end
        end

        context 'when request has multipart data' do
          let(:valid_response){double(Net::HTTPCreated, code: "201", body: post_screenshot_response_body)}
          let(:valid_mock_multipart){[Part.new(:name => "screenshotName", :body => "name", :content_type => "text/plain"),
             Part.new(:name => "properties", :body => JSON.dump({"browser": "firefox"}), :content_type => "application/json"),
             Part.new(:name => "meta", :body => '{}', :content_type => "application/json"),
             Part.new(:name => 'file', :body => "\x89PNG\r\n\x1A\n\x00", :filename => 'f.png', :content_type => 'image/png')]}
          it 'returns valid response' do
            allow_any_instance_of(Net::HTTP).to receive(:request).and_return(valid_response)
            response = visual_review.send(:call_server, 'post','runs/3/screenshots', nil, valid_mock_multipart)
            expect(response.code).to eql(valid_response.code)
          end
        end
      end
      context 'when response fails' do
        it 'raises an error' do
           failed_response = double(Net::HTTPInternalServerError, code: "500", body: "Internal Server Error")
           allow_any_instance_of(Net::HTTP).to receive(:request).and_return(failed_response)
           expect{ visual_review.send(:call_server, 'get', 'runs/1') }.to raise_error(RuntimeError)
        end
      end
    end

    describe '#take_screenshot' do
      let(:fake_png){"\x89PNG\r\n\x1A\n\x00"}
      let(:screenshot_obj){double(Watir::Screenshot, png: fake_png)}
      let(:browser){double(Watir::Browser, name: "firefox", screenshot: screenshot_obj)}
      context 'when response is valid' do
        let(:valid_response){double(Net::HTTPCreated, code: "201", body: post_screenshot_response_body)}
        it 'returns json' do
          allow(visual_review).to receive(:actual_run).and_return({:id => 3})
          allow_any_instance_of(Net::HTTP).to receive(:request).and_return(valid_response)
          response = visual_review.take_screenshot("screenshot0", browser)
          expect(response).to be_a(Hash)
        end
      end

      context 'when response code is invalid' do
        let(:valid_response){double(Net::HTTPOK, code: "200", body: '{"error":"Screenshot with identical name and properties was already uploaded in this run"}')}
        it 'raises error' do
          allow(visual_review).to receive(:actual_run).and_return({:id => 3})
          allow_any_instance_of(Net::HTTP).to receive(:request).and_return(valid_response)
          expect{visual_review.take_screenshot("screenshot0", browser)}.to raise_error(RuntimeError)
        end
      end

      context 'when run id could not be found' do
        it 'raises error' do
          allow(visual_review).to receive(:actual_run).and_return({:id => nil})
          expect{visual_review.take_screenshot("screenshot0", browser)}.to raise_error(RuntimeError)
        end
      end
    end

    describe '#check_api_version' do
      context 'when api is compatible' do
        it 'does not rise error' do
          response = double(Net::HTTPOK, code: "200", body: "1")
          allow_any_instance_of(Net::HTTP).to receive(:request).and_return(response)
          expect{ visual_review.send(:check_api_version)}.to_not raise_error
        end
      end
      context 'when api  not is compatible' do
        it 'rises error' do
          response = double(Net::HTTPOK, code: "200", body: "50")
          allow_any_instance_of(Net::HTTP).to receive(:request).and_return(response)
          expect{ visual_review.send(:check_api_version)}.to raise_error(RuntimeError)
        end
      end
    end
  end
end
