module Theia
  # A Frame is ONE moment in time in which the camera can observe something.
  class Frame

    @@counter = 0

    attr_reader :observations, :recording, :number

    def initialize(recording = nil)
      @observations = []
      @recording = recording
      @number = @@counter; @@counter += 1

      recording.add_frame(self) if recording

      self
    end

    def add_observation(observation)
      @observations << observation
    end

    def to_s
      "<#{ self.class } ##{ number } #{ observations.size } observations>"
    end

  end
end
