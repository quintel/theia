module Theia
  # A Frame is ONE moment in time in which the camera can observe something.
  class Frame

    attr_reader :observations, :recording

    def initialize(recording = nil)
      @observations = []
      @recording = recording

      recording.add_frame(self) if recording

      self
    end

    def add_observation(observation)
      @observations << observation
    end

  end
end
