module Theia
  module Mode
    class VideoBase < Base
      BACKGROUND_FRAMES     = 50
      LEARNING_RATE         = 0.01
      BG_THRESHOLD          = 50
      EROSION_AMOUNT        = 5
      IGNORE_AREA_THRESHOLD = 300
      ERODE_PIECE_AMOUNT    = 2

      def initialize(options)
        super(options)

        @capture        = Capture.new(options)
        @debug          = !!options["debug"]
        @map            = Map.new(@capture)
        @bg_subtractor  = BackgroundSubtractor::PratiMediod.new threshold: 15, history: 5, sampling_rate: 2
        @cycle          = 0
        @tracker        = Tracker.new
      end

      def next_cycle!
        @tracker.next_cycle!
        @cycle += 1
      end

      def start
        if @debug
          path = File.expand_path('../../../../data/tmp', __FILE__)

          Dir.mkdir(path) unless Dir.exist?(path)

          Dir.foreach(path) do |file|
            File.delete("#{ path }/#{ file }") if file.end_with?('.png')
          end
        end
      end

      # Public: Grabs the next frame and prepares it for detection.
      #
      # The process is as follows:
      # - Grab a frame from the capture source
      # - Calculate the delta mask by subtracting the background
      # - Run a threshold on the background to eliminate shadows
      # - Erode and dilate the delta image as a second step to remove
      #   shadows.
      def with_cycle
        @frame = nil

        # Loop until we get a (perspective corrected) frame from the map.
        while !@frame do
          @frame = @map.frame
        end

        next_cycle!

        @delta = @bg_subtractor.subtract(@frame, LEARNING_RATE)

        # Resize the frames
        [@frame, @delta].map do |img|
          img.resize!(Size.new(Map::A0_HEIGHT, Map::A0_WIDTH))
        end

        # Turn all pixels until 128.0 to 0.0.
        @delta.threshold! 128.0, 255.0

        # Contract shapes.
        @delta.erode!(EROSION_AMOUNT)

        # Save stuff
        if @debug
          path = File.expand_path('../../../../data/tmp', __FILE__)

          @frame.write "#{ path }/#{ "%04i" % @cycle }-frame.png"
          @delta.write "#{ path }/#{ "%04i" % @cycle }-delta.png"
        end

        yield @frame, @delta

        # Wait for key (but not use it) and loop after 100 ms.
        debugger if GUI.wait_key(100) == 100
      end

      # Public: Iterates through contours and yields them.
      def with_each_contour
        contours = @delta.contours

        # Ignore contours that either:
        # * have an area smaller than 600 pixels
        # * don't start at the edges
        contours.select! do |c|
          c.rect.area               > IGNORE_AREA_THRESHOLD &&
          c.rect.x                  > 0 &&
          c.rect.y                  > 0 &&
          c.rect.x + c.rect.width   < Map::A0_HEIGHT &&
          c.rect.y + c.rect.height  < Map::A0_WIDTH &&
          c.rect.area               < 20_000
        end

        contours.each do |contour|
          # Generate a MASK based on the current contour, and erode it so
          # that we can get rid of some of the shadow around the piece.
          # The whole map is black and the piece is white.
          mask = Image.new(@frame.size, Image::TYPE_8UC1)
          mask.fill!(Color.new(0))
          mask.draw_contours(contour, Color.new(255))
          # mask.erode! ERODE_PIECE_AMOUNT

          # Create an image with the ROI (region-of-interest), and copy
          # the area drawn on the mask from the captured frame into this
          # variable. We then convert it to YCrCb, which is much much better
          # than RGB in terms of computer vision and get the mean colour.
          roi = Image.new
          roi.copy!(@frame, mask)
          roi.convert!(ColorSpace[:BGR => :YCrCb])
          color = roi.mean(mask)

          yield contour, color
        end
      end
    end
  end
end

