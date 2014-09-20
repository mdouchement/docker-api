require 'spec_helper'

module Docker
  describe Testing do
    %i(fake disable).each do |method|
      describe ".#{ method }!" do
        it 'changes the test mode' do
          expect { Testing.send("#{ method }!") }.to change { Testing.__test_mode }.to(method)
        end
      end

      describe ".#{ method }?" do
        it '' do
          expect(Testing.send("#{ method }?")).to be(true)
        end
      end
    end

    describe '.time_now' do
      it 'returns the curent time well formatted' do
        expect(Testing.time_now).to match(/\d+\-\d+\-\w+:\d+:\d+\.\d+Z/)
      end
    end
  end
end
