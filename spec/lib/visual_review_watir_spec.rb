require 'spec_helper'
module Lib
  describe VisualReviewWatir do
    let(:visual_review){ VisualReviewWatir.new }
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
      context 'when run is started' do
        it 'returns code 201' do
          response = double(Net::HTTPCreated, code: "201")
          allow(VisualReviewWatir).to receive(:server_active?).and_return(true)


        end

        it 'returns json' do
          allow(VisualReviewWatir).to receive(:server_active?).and_return(true)
          debugger
          result = visual_review.start_run("Project 0", "Suite 1")
          expect(result).to
        end

        it 'returns run id' do
          allow(VisualReviewWatir).to receive(:server_active?).and_return(true)
          result = visual_review.start_run("Project 0", "Suite 1")
        end
      end

      context 'when server is not active' do
        it 'ruturns error message' do
          allow(VisualReviewWatir).to receive(:server_active?).and_return(false)
        end
      end
    end
  end
end
