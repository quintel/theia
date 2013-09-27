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
      @cap  = cap
      @raw  = Image.new
    end

    def frame
      @cap >> @raw
      bw = @raw.convert(ColorSpace[:RGB => :Gray])
      bw.threshold! 100.0, 255.0
      bw.canny! 100, 100
      bw.dilate!

      contours = bw.contours
      contours.select!  { |c| c.convex?             }
      contours.select!  { |c| c.rect.area > 500_000 }
      contours.sort_by! { |c| -1 * c.rect.area      }

      return if contours.empty?

      contour = contours.last
      if corners = contour.corners
        @raw.warp_perspective(corners, Size.new(1189, 841))
      end
    end
  end
end
