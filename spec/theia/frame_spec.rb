require 'spec_helper'

describe Frame do

  let(:recording)     { Recording.new        }
  let(:frame)         { Frame.new(recording) }
  let(:observation_1) { Observation.new(frame, :green, 100, 200, 10, 8) }
  let(:observation_2) { Observation.new(frame, :red,   200, 100, 10, 8) }

  describe '#observations' do

    context 'with no observations' do
      it 'is empty' do
        expect(Frame.new.observations).to be_empty
      end
    end

    context 'with observations' do
      it 'remembers them' do
        expect(frame.observations).to include observation_1
        expect(frame.observations).to include observation_2
      end
    end

  end

  describe '#number' do

    it 'should increase one for every newly instantiaded object' do
      expect(Frame.new.number - Frame.new.number).to eq -1
    end

  end

  describe '#recording' do

    context 'with no recording present' do
      it 'is nil' do
        expect(Frame.new.recording).to be_nil
      end
    end

    context 'with a recording present' do
      it 'remembers' do
        expect(frame.recording).to eq recording
      end
    end

  end

end
