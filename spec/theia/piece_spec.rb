require 'spec_helper'

describe Piece do

  let(:coal_piece) { Piece.new(key: 'coal', color: [0,0,0,0]) }
  let(:gas_piece)  { Piece.new(key: 'gas',  color: [255,255,255,0]) }

  describe 'all' do

    it 'returns at least a couple of pieces' do
      expect(Piece.all).to have_at_least(2).items
    end

  end

  describe 'find_by_color' do

    it 'finds the best suited color' do
      Piece.stub(:all) { [coal_piece, gas_piece] }

      expect(Piece.find_by_color([0,0,0])).to eq coal_piece
      expect(Piece.find_by_color([255,255,255])).to eq gas_piece
    end

  end

  describe '#compare' do

    context 'when perfect match' do

      it 'returns 0' do
        expect(coal_piece.compare([0,0,0])).to eq 0
      end

    end

    context 'when no match' do

      it 'returns > 0' do
        expect(gas_piece.compare([0,0,0])).to be > 0
      end

    end

  end

end
