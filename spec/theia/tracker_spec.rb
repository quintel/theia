require 'spec_helper'

describe Tracker do
  describe '#track' do
    let(:rect)       { Rect.new(50, 50, 150, 150) }
    let(:piece)      { Piece.find('coal_plant') }
    let(:color)      { piece.color }
    let(:occurrence) { Occurrence.new(rect, color, piece, 1) }

    before(:each) do
      @tracker = Tracker.new
      @tracker.track(occurrence)
    end

    context 'first frame' do
      it 'should not report occurrences' do
        expect( @tracker.pieces ).to eq([])
      end
    end

    context 'when it hits MINIMUM_APEARENCES' do
      it 'should report occurrences' do
        Occurrence::MINIMUM_APPEARENCES.times do |cycle|
          occurrence = Occurrence.new(rect, color, piece, cycle)
          @tracker.cycle = cycle
          @tracker.track(occurrence)
        end

        expect( @tracker.pieces ).to eq([occurrence])
      end
    end

    context 'in the future' do
      it 'should remove occurrences that pop up again' do
        second = Occurrence.new(rect, color, piece, 2)
        @tracker.cycle = 2
        @tracker.track(second)

        third = Occurrence.new(rect, color, piece, 20)
        @tracker.cycle = 20
        @tracker.track(third)

        expect( @tracker.pieces ).to eq([])
      end
    end
  end
end
