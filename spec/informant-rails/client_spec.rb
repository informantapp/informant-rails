require 'spec_helper'

describe InformantRails::Client do
  describe '.record' do
    let(:request) { described_class.request }
    let(:env) { Hash['HTTP_REFERER' => 'http://example.com/some/url'] }
    before { described_class.record(env) }
    it 'stores the referring url' do
      expect(request.request_url).to eq 'http://example.com/some/url'
    end
  end

  describe '.inform' do
    context 'within a request transaction' do
      let(:model) { double }
      it 'processes the model' do
        described_class.request.should_receive(:process_model).with(model)
        described_class.inform(model)
      end
    end

    context 'without a request transaction' do
      it 'does not process anything' do
        described_class.should_receive(:request)
        InformantRails::Request.any_instance.should_not_receive(:process_model)
        described_class.inform(double)
      end
    end

    context 'with a nil model' do
      it 'does not process anything' do
        described_class.request.should_not_receive(:process_model)
        described_class.inform(nil)
      end
    end
  end

  describe '.process' do
    let(:request) { described_class.request }
    let(:model) { User.new.tap(&:save) }
    before { described_class.record({}) }

    context 'with an api token' do
      before { InformantRails::Config.api_token = 'abc123' }

      context 'and errors present' do
        before { described_class.inform(model) }

        it 'sends the data to the informant' do
          Net::HTTP.should_receive(:post_form).with(
            described_class.send(:api_url),
            request.as_json
          )
          described_class.process
        end

        it 'removes the request transaction from the cache' do
          Net::HTTP.stub(:post_form)
          described_class.process
          expect(described_class.request).to be_nil
        end
      end

      context 'without an api token present' do
        it 'sends the data to the informant' do
          Net::HTTP.should_not_receive(:post_form)
          described_class.process
        end

        it 'removes the request transaction from the cache' do
          described_class.process
          expect(described_class.request).to be_nil
        end
      end
    end

    context 'without an api token present' do
      before { InformantRails::Config.api_token = '' }

      it 'sends the data to the informant' do
        Net::HTTP.should_not_receive(:post_form)
        described_class.process
      end

      it 'removes the request transaction from the cache' do
        described_class.process
        expect(described_class.request).to be_nil
      end
    end
  end
end