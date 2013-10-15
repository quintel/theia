require 'spec_helper'

describe Tracker do
  describe '#track' do
    let(:rect)       { Rect.new(50, 50, 150, 150) }
    let(:occurrence) { Occurrence.new(rect, 'coal_plant', 1) }

    before(:each) do
      @tracker = Tracker.new
      @tracker.track(occurrence)
    end

    context 'first frame' do
      it 'should not report occurrences' do
        expect( @tracker.pieces ).to eq([])
      end
    end

    context 'second frame' do
      xit 'should report occurrences' do
        second = Occurrence.new(rect, 'coal_plant', 2)
        @tracker.track(second)

        expect( @tracker.pieces ).to eq(['coal_plant'])
      end
    end

    context 'in the future' do
      it 'should remove occurrences that pop up again' do
        second = Occurrence.new(rect, 'coal_plant', 2)
        @tracker.track(second)

        third = Occurrence.new(rect, 'electric_car', 20)
        @tracker.track(third)

        expect( @tracker.pieces ).to eq([])
      end
    end
  end
end
