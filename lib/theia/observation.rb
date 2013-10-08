module Theia
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

    def siblings
      frame.observations.delete_if { |o| o == self }
    end
  end

end
