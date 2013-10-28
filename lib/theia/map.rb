module Theia

  # Game map handler. Detects map boundaries.
  class Map

    A0_WIDTH  = 840
    A0_HEIGHT = 1_188
    A0_SIZE   = Spyglass::Size.new(A0_HEIGHT, A0_WIDTH)

    A1_WIDTH  = 420
    A1_HEIGHT = 594
    A1_SIZE   = Spyglass::Size.new(A1_HEIGHT, A1_WIDTH)

    # Internal: Initialize a new map.
    #
    # cap - An instance of Theia::Capture
    def initialize(cap)
      @cap  = cap
      @raw  = Image.new
    end

    # Public: Given a raw feed, this method does a few things:
    #
    #         - Finds the boundaries of the map
    #         - Crops the raw frame into a region of interest
    #         - Corrects perspective
    #
    #         Returns `nil` when it can't detect a valid map area
    def frame
      @cap >> @raw

      # We'll only use B&W for map detection
      bw = @raw.convert(ColorSpace[:RGB => :Gray])

      # We only wanna get hold of the black (dark) map boundary, so we trow
      # away all pixels that are whiter than 100.0
      bw.threshold! 80.0, 255.0

      # Canny is used to detect color changing boundaries.
      bw.canny! 100, 100

      # Get the contours (Array of Contour)
      contours = bw.contours

      # Only get closed contours
      contours.select! { |c| c.convex? }

      # Ignore small contours
      contours.select! { |c| c.rect.area > (@raw.cols * @raw.rows) / 3 }

      # Sort by size, we wanna have the last one!
      contours.sort_by! { |c| -1 * c.rect.area }

      # Return nil if nothing is detected (SNAFU)
      if contours.empty?
        Theia.logger.warn("Cannot find the map"); return nil
      end

      # We wanna have the last (i.e. biggest) one!
      contour = contours.last

      # Return nil if we cannot find the corners
      if corners = contour.corners
        # Straighten up that image!
        Theia.logger.info("Map found")
        @raw.warp_perspective(corners, Size.new(A1_HEIGHT, A1_WIDTH))
      else
        Theia.logger.warn("Cannot find the corners of the map"); return nil
      end
    end
  end # Map

end # Theia
