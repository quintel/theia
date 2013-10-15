module Theia
  module Mode
    class Calibration < VideoBase
      # Different stages at which the calibration process works
      # per piece.
      #
      # waiting   - Waiting for a piece to be placed on the hot spot
      # found     - A piece was found. Waits for the user to remove
      #             his/her hand.
      # training  - Grabbing the mean color from the hotspot.
      # remove    - Calibration finished for the piece. Waits for the
      #             user to remove it from the hotspot.
      STAGES = %w(waiting found training remove)

      RECT_SIZE = 200

      def initialize(options)
        super(options)

        # Use a different background subtraction algorithm
        @bg_subtractor = BackgroundSubtractor::MOG2.new history: 50, threshold: 8
        100.times do
          @frame = nil
          while !@frame do
            @frame = @map.frame
          end
          @bg_subtractor.subtract(@frame, 1.0/100)
        end

        # This is the hotspot in the center of the map.
        @rect = Rect.new(
          (Map::A1_HEIGHT) - (RECT_SIZE / 2),
          (Map::A1_WIDTH) - (RECT_SIZE / 2),
          RECT_SIZE, RECT_SIZE
        )

        if Theia.logger.level > Log4r::INFO
          Theia.logger.level = Log4r::INFO
        end
      end

      def board_window
        @board_window ||= GUI::Window.new("Board")
      end

      def delta_window
        @delta_window ||= GUI::Window.new("Delta")
      end

      def pieces
        Piece.all
      end

      def start
        @stage_idx = 0
        @piece_idx = 0

        display = Image.new(Map::A1_SIZE, Image::TYPE_8UC3)
        loop do
          with_cycle do |frame, delta|
            display.copy!(frame)
            display.draw_rectangle(@rect, Color.new(255, 0, 0))
            board_window.show(display)
            delta_window.show(delta)

            # Here we crop the frame and delta because we're just interested
            # in what's going on inside the ROI defined by @rect. Essentially,
            # this makes the calibration program blind to everything else
            # that's going on in the map.
            frame.crop! @rect
            delta.crop! @rect

            stage_method = "#{ STAGES[@stage_idx] }_stage".to_sym
            self.send(stage_method, frame, delta)
          end

          if @piece_idx == pieces.length && @stage_idx == 0
            Theia.logger.info "Writing pieces!"
            Piece.write
            break
          end
        end
      end

      def waiting_stage(frame, delta)
        Theia.logger.info "Waiting for piece #{ pieces[@piece_idx].key }"
        with_each_contour do |contour, mean|
          if mean[0] + mean[1] + mean[2] > 100
            next_stage!
          end
        end
      end

      def found_stage(frame, delta)
        Theia.logger.info "Remove hand."
        GUI::wait_key(3000)
        next_stage!
      end

      def training_stage(frame, delta)
        Theia.logger.info "Training..."
        with_each_contour do |contour, mean|
          pieces[@piece_idx].color = mean
          next_stage!
        end
      end

      def remove_stage(frame, delta)
        Theia.logger.info "Remove the model."
        return unless delta.mean.zeros?
        next_stage!
        next_piece!
      end

      #######
      private
      #######

      def next_stage!
        @stage_idx = (@stage_idx + 1) % STAGES.length
      end

      def next_piece!
        @piece_idx += 1
      end
    end
  end
end
