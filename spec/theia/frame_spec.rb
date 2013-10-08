require 'spec_helper'

describe Frame do

  let(:frame) { Frame.new }
  let(:observation_1) { Observation.new(frame, :green, 100, 200, 10, 8) }
  let(:observation_2) { Observation.new(frame, :red,   200, 100, 10, 8) }

  describe '#observations' do

    it 'remembers them' do
      expect(frame.observations).to include observation_1
      expect(frame.observations).to include observation_2
    end

  end

end
