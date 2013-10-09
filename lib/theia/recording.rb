module Theia

  # A recording contains up to 24 frames in consequetive order.
  class Recording

    MAX_FRAMES = 24

    attr_reader :frames

    def initialize
      @frames = []
    end

    def observations
      frames.map(&:observations).flatten
    end

    # Adds a frame to this recording. Pops off the last one, if it has hit
    # the max amount of frames allowed.
    def add_frame(frame)
      @frames.unshift(frame)

      @frames.delete_at(24) if frames.size > MAX_FRAMES

      @frames
    end

  end
end
