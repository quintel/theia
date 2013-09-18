module Theia
  module Mode
    class VideoBase < Base
      BACKGROUND_FRAMES = 50

      def initialize(options)
        super(options)

        @capture        = Capture.new(options)
        @map            = Map.new(@capture)
        @bg_subtractor  = BackgroundSubtractor.new history: BACKGROUND_FRAMES, shadow_detection: false

        calibrate!
      end

      # Public: Starts the calibration process.
      #
      # First, it tries to capture the map boundaries, and then trains the
      # background subtractor.
      def calibrate!
        # Set the camera bounds to the map. This greatly reduces the size
        # of images we have to work with.
        @capture.bounds = @map.bounds

        frame = Image.new

        # Train background.
        BACKGROUND_FRAMES.times do
          @capture >> frame
          @bg_subtractor.subtract(frame, 1.0/BACKGROUND_FRAMES)
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
        @frame ||= Image.new(@map.bounds.size, Image::TYPE_8UC3)
        @capture >> @frame

        @delta = @bg_subtractor.subtract(@frame, 0)
        @delta.threshold! 128.0, 255.0
        @delta.erode!.dilate!

        yield @frame, @delta

        GUI.wait_key(100)
        GC.start
      end

      # Public: Iterates through contours and yields them.
      def with_each_contour
        contours = @delta.contours
        contours.select! { |c| c.rect.area > 600 }
        contours.each do |contour|
          # Generate a mask based on the current contour, and erode it so
          # that we can get rid of some of the shadow around the piece.
          mask = Image.new(@frame.size, Image::TYPE_8UC1)
          mask.fill!(Color.new(0))
          mask.draw_contours(contour, Color.new(255))
          mask.erode! 5

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

