require 'spec_helper'

describe Observation do

  let(:recording)   { Recording.new }
  let(:frame)       { Frame.new(recording) }
  let(:observation) { Observation.new(frame, :green, 100, 200, 10, 8) }

  describe '#initialize' do

    it 'remembers frame' do
      expect(observation.frame).to eq frame
    end

    it 'remembers color' do
      expect(observation.color).to eq :green
    end

    it 'remembers x' do
      expect(observation.x).to eq 100
    end

    it 'remembers y' do
      expect(observation.y).to eq 200
    end

    it 'remembers width' do
      expect(observation.width).to eq 10
    end

    it 'remembers height' do
      expect(observation.height).to eq 8
    end

  end # initialize

  describe '#siblings' do

    let(:observation_2) { Observation.new(frame, :red, 200, 100, 10, 8) }
    let(:observation_3) { Observation.new(Frame.new, :red, 200, 100, 10, 8) }

    it 'returns observation_2' do
      expect(observation.siblings).to include observation_2
    end

    it 'returns not itself' do
      expect(observation.siblings).to_not include observation
    end

    it 'returns not other observation on another frame' do
      expect(observation.siblings).to_not include observation_3
    end
  end

  describe '#history' do

    let(:frame_2)       { Frame.new(recording) }

    context 'with a similar observation' do

      let(:observation_2) { Observation.new(frame_2, :green, 100, 200, 10, 8) }

      xit 'sees it' do
        expect(observation_2.history).to include observation
      end

    end

  end
end # class Observation
