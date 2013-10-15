module Theia
  # A Frame is ONE moment in time in which the camera can observe multiple
  # things.
  class Frame

    @@counter = 0

    attr_reader :observations, :recording, :number

    # Public: creates a new Frame for the recording.
    def initialize(recording = nil)
      @observations = []
      @recording = recording
      @number = @@counter; @@counter += 1

      recording.add_frame(self) if recording

      self
    end

    # Public: add an observation to the frame.
    def add_observation(observation)
      @observations << observation
    end

    def to_s
      "<#{ self.class } ##{ number } #{ observations.size } observations>"
    end

  end
end
