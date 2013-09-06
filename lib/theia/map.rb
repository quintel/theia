class Float
  def approx(other, relative_epsilon=Float::EPSILON, epsilon=Float::EPSILON)
    difference = other - self
    return true if difference.abs <= epsilon
    relative_error = (difference / (self > other ? self : other)).abs
    return relative_error <= relative_epsilon
  end
end

module Theia
  # Game map handler. Detects map boundaries.
  class Map
    # Internal: Initialize a new map.
    #
    # cap - An instance of Theia::Capture
    def initialize(cap)
      @cap = cap
    end

    def bounds
      @bounds ||= begin
        frame = Image.new

        @cap >> frame

        # Convert the image to black & white, run a threshold
        # so that we:
        #
        # - eliminate any colors brighter than black,
        # - run the Canny edge detector to bring out the edges,
        # - dilate the image to connect unconnected lines
        frame.convert! ColorSpace[:BGR => :Gray]
        frame.threshold_inv! 80.0, 255.0
        frame.canny! 50, 150
        frame.dilate! 2
        contours = frame.contours

        # Filter out false positives and sort by area.
        contours.select!  { |c| (c.rect.size.width.to_f / c.rect.size.height).approx(1.41, 0.1) }
        contours.sort!    { |c| c.rect.area }

        contours[0].rect
      end
    end
  end
end
