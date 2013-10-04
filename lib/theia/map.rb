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

    A0_WIDTH  = 840
    A0_HEIGHT = 1_188

    A1_WIDTH  = 420
    A1_HEIGHT = 594

    # Internal: Initialize a new map.
    #
    # cap - An instance of Theia::Capture
    def initialize(cap)
      @cap  = cap
      @raw  = Image.new
    end

    def frame
      @cap >> @raw

      # We'll only use B&W for map detection
      bw = @raw.convert(ColorSpace[:RGB => :Gray])

      # We only wanna get hold of the black (dark) map boundary, so we trow
      # away all pixels that are whiter than 100.0
      bw.threshold! 100.0, 255.0

      # Canny is used to detect color changing boundaries.
      bw.canny! 100, 100

      # Now we expand the lines to make sure unconnected contours get
      # connected.
      bw.dilate!

      # Get the contours (Array of Contour)
      contours = bw.contours

      # Only get closed contours
      contours.select!  { |c| c.convex? }

      # Ignore small contours
      contours.select!  { |c| c.rect.area > (@raw.cols * @raw.rows) / 3 }

      # Sort by size, we wanna have the last one!
      contours.sort_by! { |c| -1 * c.rect.area }

      # Return nil if nothing is detected (SNAFU)
      if contours.empty?
        puts("WARNING: Cannot find the map"); return nil
      end

      # We wanna have the last (i.e. biggest) one!
      contour = contours.last

      # Return nil if we cannot find the corners
      if corners = contour.corners
        # Straighten up that image!
        puts("Frame yielded")
        @raw.warp_perspective(corners, Size.new(A1_HEIGHT, A1_WIDTH))
      else
        puts("Cannot find the corners of the map")
      end
    end
  end
end
