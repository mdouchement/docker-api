require 'spec_helper'

module Docker
  describe Connection do
    subject { Connection.new('http://localhost:4243', {}) }

    context 'when testing mode is disable' do
      describe '#request' do
        it 'calls the original request method' do
          expect_any_instance_of(Connection).to receive(:request_real).with('1', '2')
          subject.request('1', '2')
        end
      end
    end

    context 'when testing mode is fake' do
      before do
        Docker::Testing.fake!
      end

      after do
        Docker::Testing.disable!
      end

      describe '#request' do
        let(:raw_response) { { value_1: '1', value_2: '2' } }
        before do
          allow_any_instance_of(Connection).to receive(:dispatcher)
            .and_return(raw_response)
        end

        it 'calls the dispatcher' do
          expect_any_instance_of(Connection).to receive(:dispatcher).with('1', '2')
          subject.request('1', '2')
        end

        it 'returns a json response' do
          expect_any_instance_of(Connection).to receive(:format_response)
            .with(raw_response)
          subject.request('1', '2')
        end
      end

      describe '#dispatcher' do
        let(:method) { 'http_method' }
        let(:path) { 'some/path/containing/containers/pattern' }
        let(:query) { { query: true } }
        let(:opts) { { opts: true } }
        let(:raw_body) { '{"a":1,"b":2}' }
        let(:body) { { 'a' => 1, 'b' => 2 } }

        it 'adds body field to options if does not exist' do
          expect_any_instance_of(Testing::ContainerManager).to receive(:perform) do |*args|
            expect(args[4]).to eq(opts: true, body: {})
          end
          subject.send(:dispatcher, method, path, query, opts)
        end

        it 'formats body to JSON' do
          expect_any_instance_of(Testing::ContainerManager).to receive(:perform) do |*args|
            expect(args[4]).to eq(opts: true, body: body)
          end
          subject.send(:dispatcher, method, path, query, opts.merge(body: raw_body))
        end

        context 'when it is a Container request' do
          it 'calls container manager performer' do
            expect_any_instance_of(Testing::ContainerManager).to receive(:perform)
              .with(method, path, query, opts)
            subject.send(:dispatcher, method, path, query, opts)
          end
        end

        context 'when it is an Image request' do
          it 'does nothing' do
            expect(subject.send(:dispatcher, '', 'some/path/containing/images/pattern')).to be(nil)
          end
        end
      end

      describe '#container_manager' do
        it 'returns a manager' do
          expect(subject.send(:container_manager)).to be_an_instance_of(Testing::ContainerManager)
        end

        it 'returns a singleton manager' do
          expect { subject.send(:container_manager) }
            .to_not change { subject.send(:container_manager) }
        end
      end

      describe '#format_response' do
        it 'returns json' do
          expect(subject.send(:format_response, a: 1, b: 2)).to eq(JSON.generate(a: 1, b: 2))
        end
      end
    end
  end
end
