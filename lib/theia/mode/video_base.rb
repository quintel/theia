module Theia

  module Mode
    class VideoBase < Base
      BACKGROUND_FRAMES     = 50
      LEARNING_RATE         = 0.01
      BG_THRESHOLD          = 50
      EROSION_AMOUNT        = 5
      IGNORE_AREA_THRESHOLD = 300
      ERODE_PIECE_AMOUNT    = 2
      CAMERA_OPTIONS        = {
        auto_exposure:       false,
        auto_white_balance:  false,
        anti_flicker:        false,
        auto_focus:          false,
        exposure:            100,
        gain:                0,
        brightness:          128,
        contrast:            128,
        saturation:          128,
        sharpness:           128,
        focus:               0,
        zoom:                100
      }

      def initialize(options)
        super(options)
        @capture          = Capture.new(options)
        @live             = !!options["source"]
        @debug            = !!options["debug"]
        @map              = Map.new(@capture)
        @bg_subtractor    = BackgroundSubtractor::PratiMediod.new threshold: 15, history: 5, sampling_rate: 2
        @cycle            = 0
        @tracker          = Tracker.new
        @processing_times = []
        @fps              = 0.0
        @camera           = Camera.all.first
      end

      def next_cycle!
        @tracker.next_cycle!
        @cycle += 1
      end

      def start
        if @debug
          Dir.mkdir(Theia.tmp_path) unless Dir.exist?(Theia.tmp_path)

          # Clean up the temporary directory if we are running a debug
          # session again.
          Dir.foreach(Theia.tmp_path) do |file|
            File.delete("#{ Theia.tmp_path }/#{ file }") if file.end_with?('.png')
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
      def with_cycle(cycle_number = nil)
        @frame = nil

        # Loop until we get a (perspective corrected) frame from the map.
        while !@frame do
          @camera.set(CAMERA_OPTIONS)
          @frame = @map.frame
        end

        # We only count processing times as soon as we get the map. Seen as
        # this is a really fast operation (and most of the time is spent on
        # background subtration).
        cycle_start = Time.now

        next_cycle!

        Log4r::NDC.push("##{ @cycle }") if cycle_number

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
          @frame.write "#{ Theia.tmp_path }/#{ "%04i" % @cycle }-frame.png"
          @delta.write "#{ Theia.tmp_path }/#{ "%04i" % @cycle }-delta.png"
        end

        yield @frame, @delta

        cycle_finish = Time.now
        msecs = (cycle_finish - cycle_start)

        # After measuring how long it took to process the frame, add it to
        # processing times, make sure we only account for the last 10
        # measurements, average them out and divide them by 1 (sec). This
        # gives us the FPS.
        @processing_times << msecs
        @processing_times.shift if @processing_times.length > 10
        @fps = 1.0 / @processing_times.mean
      ensure
        Log4r::NDC.pop if cycle_number
      end

      def contours
        # Ignore contours that either:
        # * have an area smaller than so many pixels
        # * don't start at the edges
        @delta.contours.select do |c|
          c.rect.area               > IGNORE_AREA_THRESHOLD &&
          c.rect.x                  > 0 &&
          c.rect.y                  > 0 &&
          c.rect.x + c.rect.width   < Map::A0_HEIGHT &&
          c.rect.y + c.rect.height  < Map::A0_WIDTH &&
          c.rect.area               < 20_000
        end
      end

      def grab_color_from_contour(contour)
        mask = Image.new(@frame.size, Image::TYPE_8UC1)
        mask.fill!(Color.new(0))
        mask.draw_contours(contour, Color.new(255))

        # Create an image with the ROI (region-of-interest), and copy
        # the area drawn on the mask from the captured frame into this
        # variable. We then convert it to YCrCb, which is much much better
        # than RGB in terms of computer vision and get the mean colour.
        roi = Image.new
        roi.copy!(@frame, mask)
        roi.convert!(ColorSpace[:BGR => :YCrCb])
        color = roi.mean(mask)

        color
      end

      # Public: Iterates through contours and yields them.
      def with_each_contour
        contours.each do |contour|
          # Generate a MASK based on the current contour, and erode it so
          # that we can get rid of some of the shadow around the piece.
          # The whole map is black and the piece is white.
          yield contour, grab_color_from_contour(contour)
        end
      end
    end # VideoBase
  end # Mode

end # Theia

