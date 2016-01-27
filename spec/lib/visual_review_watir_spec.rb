require 'spec_helper'
describe VisualReviewWatir do
  let(:visual_review) { VisualReviewWatir.new }
  let(:post_runs_response_body) do
    "{
      \"id\":3,
      \"suiteId\":1,
      \"branchName\":\"master\",
      \"baselineTreeId\":1,
      \"startTime\":\"2015-12-24T15:41:48-0200\",
      \"endTime\":null,
      \"status\":\"running\",
      \"projectId\":1
      }"
  end
  let(:post_screenshot_response_body) do
    "{
      \"id\":21,
      \"size\":57842,
      \"properties\":{
        \"browser\":\"firefox\"
      },
      \"meta\":{},
      \"screenshotName\":\"1\",
      \"runId\":90,
      \"imageId\":34
    }"
  end

  describe '.initialize' do
    context 'instalize component' do
      it 'with default values' do
        visual_review = VisualReviewWatir.new
        expect(visual_review.hostname).to eql('localhost')
        expect(visual_review.port).to eql(7000)
      end

      it 'with dinamicly values' do
        options = { hostname: 'visualreviewwatir.com', port: 80 }
        visual_review = VisualReviewWatir.new(options)
        expect(visual_review.hostname).to eql('visualreviewwatir.com')
        expect(visual_review.port).to eql(80)
      end
    end
  end

  describe '#server_active?' do
    context 'when server is active' do
      it 'rerturns true' do
        request = double(Net::HTTPOK, code: '200')
        allow(Net::HTTP).to receive(:get_response).and_return(request)
        status = visual_review.server_active?
        expect(status).to be true
      end

      context 'and response is invalid' do
        it 'returns false' do
          request = double(Net::HTTPInternalServerError, code: '500')
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
      before do
        new_run = { id: 3, run_date: '2015-12-24T15:41:48-0200' }
        allow_any_instance_of(VisualReviewWatir).to receive(:create_new_run).and_return(new_run)
        allow_any_instance_of(VisualReviewWatir).to receive(:check_api_version).and_return(nil)
        @response = visual_review.start_run('Project0', 'Suite1')
      end

      it 'returns run id info' do
        expect(@response.key?('id'))
      end

      it 'returns run date info' do
        expect(@response.key?('run_date'))
      end

      it 'returns hash' do
        expect(@response).to be_a Hash
      end
    end

    context 'when api version is not compatible' do
      before do
        allow_any_instance_of(VisualReviewWatir).to receive(:check_api_version).and_raise(RuntimeError)
      end

      it 'returns runtimeError exeception' do
        expect { visual_review.start_run('Project0', 'Suite1') }.to raise_error(RuntimeError)
      end
    end
  end

  describe '#create_new_run' do
    context 'when response code is valid' do
      before do
        valid_response = double(Net::HTTPCreated, code: '201', body: post_runs_response_body)
        allow_any_instance_of(VisualReviewWatir).to receive(:call_server).and_return(valid_response)
        @response = visual_review.send(:create_new_run, 'Project0', 'Suite1')
      end

      it 'returns a hash' do
        expect(@response).to be_a Hash
      end

      it 'returns run id info' do
        expect(@response.key?('id'))
      end

      it 'returns run date info' do
        expect(@response.key?('run_date'))
      end

      context 'and run id is not returned' do
        it 'raises an error' do
          invalid_body = "{
            \"id\":null,
            \"startTime\":\"2015-12-24T15:41:48-0200\",
            \"projectId\":1
           }"
          invalid_response = double(Net::HTTPCreated, code: '201', body: invalid_body)
          allow_any_instance_of(VisualReviewWatir).to receive(:call_server).and_return(invalid_response)
          expect { visual_review.send(:create_new_run, 'Project0', 'Suite1') }.to raise_error(RuntimeError)
        end
      end
    end

    context 'when response code is invalid' do
      it 'raises an error' do
        invalid_response = double(Net::HTTPOK, code: '200', body: post_runs_response_body)
        allow_any_instance_of(VisualReviewWatir).to receive(:call_server).and_return(invalid_response)
        expect { visual_review.send(:create_new_run, 'Project0', 'Suite1') }.to raise_error(RuntimeError)
      end
    end
  end

  describe '#call_server' do
    context 'when response is successfull' do
      context 'and request has body' do
        let(:valid_response) do
          double(Net::HTTPCreated, code: '201', body: post_runs_response_body)
        end
        let(:body) { { projectName: 'Project0', suiteName: 'Suite1' } }
        it 'returns valid response' do
          allow_any_instance_of(Net::HTTP).to receive(:request).and_return(valid_response)
          response = visual_review.send(:call_server, 'post', 'runs', body)
          expect(response.code).to eql(valid_response.code)
        end
      end

      context 'when request does not have body' do
        let(:valid_response) { double(Net::HTTPOK, code: '200', body: post_runs_response_body) }
        it 'returns valid response' do
          allow_any_instance_of(Net::HTTP).to receive(:request).and_return(valid_response)
          response = visual_review.send(:call_server, 'get', 'runs/1')
          expect(response.code).to eql(valid_response.code)
        end
      end

      context 'when request has multipart data' do
        let(:valid_response) { double(Net::HTTPCreated, code: '201', body: post_screenshot_response_body) }
        let(:valid_mock_multipart) do
          [
            Part.new(name: 'screenshotName', body: 'name', content_type: 'text/plain'),
            Part.new(name: 'properties', body: { browser: 'firefox' }.to_json, content_type: 'application/json'),
            Part.new(name: 'meta', body: '{}', content_type: 'application/json'),
            Part.new(name: 'file', body: '\x89PNG\r\n\x1A\n\x00', filename: 'f.png', content_type: 'image/png')
          ]
        end
        it 'returns valid response' do
          allow_any_instance_of(Net::HTTP).to receive(:request).and_return(valid_response)
          response = visual_review.send(:call_server, 'post', 'runs/3/screenshots', nil, valid_mock_multipart)
          expect(response.code).to eql(valid_response.code)
        end
      end
    end
    context 'when response fails' do
      it 'raises an error' do
        failed_response = double(Net::HTTPInternalServerError, code: '500', body: 'Internal Server Error')
        allow_any_instance_of(Net::HTTP).to receive(:request).and_return(failed_response)
        expect { visual_review.send(:call_server, 'get', 'runs/1') }.to raise_error(RuntimeError)
      end
    end
  end

  describe '#take_screenshot' do
    let(:fake_png) { '\x89PNG\r\n\x1A\n\x00' }
    let(:screenshot_obj) { double(Watir::Screenshot, png: fake_png) }
    let(:browser) { double(Watir::Browser, name: 'firefox', screenshot: screenshot_obj) }

    context 'when response is valid' do
      let(:valid_response) { double(Net::HTTPCreated, code: '201', body: post_screenshot_response_body) }
      it 'returns json' do
        allow(visual_review).to receive(:actual_run).and_return(id: 3)
        allow_any_instance_of(VisualReviewWatir).to receive(:call_server).and_return(valid_response)
        response = visual_review.take_screenshot('screenshot0', browser)
        expect(response).to be_a Hash
      end
    end

    context 'when response code is invalid' do
      let(:valid_response) { double(Net::HTTPOK, code: '200', body: '{"error":"Screenshot with identical name and properties was already uploaded in this run"}') }
      it 'raises error' do
        allow(visual_review).to receive(:actual_run).and_return(id: 3)
        allow_any_instance_of(VisualReviewWatir).to receive(:call_server).and_return(valid_response)
        expect { visual_review.take_screenshot('screenshot0', browser) }.to raise_error(RuntimeError)
      end
    end

    context 'when run id could not be found' do
      it 'raises error' do
        allow(visual_review).to receive(:actual_run).and_return(id: nil)
        expect { visual_review.take_screenshot('screenshot0', browser) }.to raise_error(RuntimeError)
      end
    end
  end

  describe '#check_api_version' do
    context 'when api is compatible' do
      it 'does not rise error' do
        response = double(Net::HTTPOK, code: '200', body: '1')
        allow_any_instance_of(Net::HTTP).to receive(:request).and_return(response)
        expect { visual_review.send(:check_api_version) }.to_not raise_error
      end
    end
    context 'when api  not is compatible' do
      it 'rises error' do
        response = double(Net::HTTPOK, code: '200', body: '50')
        allow_any_instance_of(Net::HTTP).to receive(:request).and_return(response)
        expect { visual_review.send(:check_api_version) }.to raise_error(RuntimeError)
      end
    end
  end
end
