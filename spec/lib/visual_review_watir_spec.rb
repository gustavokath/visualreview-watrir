require 'spec_helper'
module Lib
  describe VisualReviewWatir do
    let(:visual_review){ VisualReviewWatir.new }

    context 'create visual review watir component' do
      it 'successfully created with default values' do
        visual_review = VisualReviewWatir.new

        expect(visual_review.hostname).to eql("localhost")
        expect(visual_review.port).to eql(7000)
      end

      it 'successfully created' do
        options = { hostname: "visualreviewwatir.com", port: 80 }
        visual_review = VisualReviewWatir.new(options)

        expect(visual_review.hostname).to eql("visualreviewwatir.com")
        expect(visual_review.port).to eql(80)
      end
    end

    context 'validate visual review server status' do
      it 'server is active' do
        seccessful_request = double(Net::HTTPOK, code: "200")
        allow_any_instance_of(Net::HTTP).to receive(:get_response).and_return(seccessful_request)
        status = visual_review.server_active?

        expect(status).to be true
      end

      it 'server is down' do
        allow_any_instance_of(Net::HTTP).to receive(:get_response).and_return(nil)
        status = visual_review.server_active?

        expect(status).to be false
      end
    end
  end
end
