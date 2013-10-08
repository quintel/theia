module Theia

  # An Observation is something that is 'seen' by the camera in a particular
  # Frame. It has a certain color, position and size.
  class Observation

    attr_reader :frame, :color, :x, :y, :width, :height

    def initialize(frame, color, x, y, width, height)
      @frame  = frame
      @color  = color
      @x      = x
      @y      = y
      @width  = width
      @height = height

      frame.add_observation(self)

      self
    end

    def dimensions
      [x, y, width, height]
    end

    def recording
      frame.recording
    end

    # How reliable is this observation. Returns Float between 0 and 1.
    def reliability
      reliability = 1.0

      # Probably out of focus or disaster happened. Nobody puts 3 new pieces
      # on the board instantly.
      return 0 if siblings.select(&:new?).size > 5

      reliability *= 0.5 if new?
    end

    # Has this observation been seen before?
    # Returns true or false
    def new?
    end

    # Returns all the concurrent observations.
    def siblings
      frame.observations.delete_if { |o| o == self }
    end

    # Returns the observations that have happened in previous frames on 
    # (probably!) the same observed object.
    #
    # Returns an Array of Observations in reserve order.
    def history
      observations = recording.frames.map(&:observations).flatten
      observations.select do |observation|
        observation.x == self.x
        observation.y == self.y
        observation.color == self.color
      end
    end

    def to_s
      "<#{ self.class } Frame##{ frame.number } #{ color }, #{ dimensions.join(', ') }>"
    end

  end

end
