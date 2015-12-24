require 'spec_helper'
module Lib
  describe VisualReviewWatir do
    let(:visual_review){ VisualReviewWatir.new }
    let(:post_runs_response_body){"{\"id\":3,\"suiteId\":1,\"branchName\":\"master\",\"baselineTreeId\":1,\"startTime\":\"2015-12-24T15:41:48-0200\",\"endTime\":null,\"status\":\"running\",\"projectId\":1}"}
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
          allow_any_instance_of(Net::HTTP).to receive(:get_response).and_return(seccessful_request)
          status = visual_review.server_active?
          expect(status).to be true
        end
      end

      context 'when server is not active' do
        it 'returns false' do
          allow_any_instance_of(Net::HTTP).to receive(:get_response).and_return(nil)
          status = visual_review.server_active?

          expect(status).to be false
        end
      end
    end

    describe '#start_run' do
      context 'when api version is compatible' do
        let(:valid_response){double(Net::HTTPCreated, code: "201", body: post_runs_response_body)}
        let(:valid_api){double(Net::HTTPOK, code: "200", body: "1")}
        before(:all) do
          allow(Net::HTTP).to receive(:request).and_return(valid_response)
          allow(VisualReviewWatir).to receive(:checkApiVersion).and_return(valid_api)
        end

        it 'returns run id info' do
          response = visual_review.start_run("Project0", "Suite1")
          expect(response.has_key?("run_id"))
        end

        it 'returns run date info' do
          response = visual_review.start_run("Project0", "Suite1")
          expect(response.has_key?("run_date"))
        end

        it 'returns hash' do
          response = visual_review.start_run("Project0", "Suite1")
          expect(response).to be_a(Hash)
        end
      end
      context 'when api version is not compatible' do
        let(:invalid_api){double(Net::HTTPOK, code: "200", body: "50")}
        it 'returns runtimeError exeception' do
          allow(VisualReviewWatir).to receive(:checkApiVersion).and_return(invalid_api)
          expect{visual_review.start_run("Project0", "Suite1")}.to raise_error
        end
      end
    end
  end
end
