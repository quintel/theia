module Theia
  module Mode
    class Calibration < VideoBase

      # How many frames do we want the background to 'adapt' and stabilize.
      LEARN_FRAMES = 75

      # How many times to sample a colour during calibration before we have
      # enough data.
      COLOR_SAMPLES = 5

      def initialize(options)
        super(options)

        # Use a different background subtraction algorithm
        @bg_subtractor = BackgroundSubtractor::MOG2.new history: 50, threshold: 8

        # Train the background first for 100 frames.

        Theia.logger.info "Starting Background learning. Please hold on..."

        LEARN_FRAMES.times do |i|
          Theia.logger.info "At step #{ i } of #{ LEARN_FRAMES } now..."
          @frame = nil
          while !@frame do
            @frame = @map.frame
          end
          @bg_subtractor.subtract(@frame, 1.0/LEARN_FRAMES)
        end

        if Theia.logger.level > Log4r::INFO
          Theia.logger.level = Log4r::INFO
        end
      end

      def start
        puts <<-MESSAGE.gsub(/^ +/, '')
          Starting...

          Please put the pieces on the map in a row, from left-to-right, in the
          following order:

          #{ Piece.all.map { |piece| "* #{ piece.key }" }.join("\n") }

          Press any key to continue, or 'q' to exit...
        MESSAGE

        if $stdin.gets.strip == 'q'
          puts 'Aborted. Goodbye.'
          exit 0
        end

        display = Image.new(Map::A1_SIZE, Image::TYPE_8UC3)

        with_cycle do |frame, delta|
          display.copy!(frame)
          board_window.show(display)
          delta_window.show(delta)

          unless contours.size == Piece.all.size
            raise("I found #{ contours.size } on the board, " +
                  "but #{ Piece.all.size } on disk. " +
                  "Please add/remove pieces to align numbers.")
          end

          Theia.logger.info "I found #{ contours.size } # of contours."

          colors = colors_from_contours(contours)

          # We have enough colors
          if colors.all? { |_, samples| samples.size >= COLOR_SAMPLES }
            colors.each(&method(:update_piece))

            Theia.logger.info "Done! New colors have been saved to disk!"
            break
          end
        end
      end

      def board_window
        @board_window ||= GUI::Window.new("Board")
      end

      def delta_window
        @delta_window ||= GUI::Window.new("Delta")
      end

      #######
      private
      #######

      # Given a collection of contours, returns a hash where each key is the key
      # of a piece, and the value is an array containing the color of the piece
      # in the format [Y, Cr, Cb, 0.0].
      def colors_from_contours(contours)
        contours = contours.sort_by { |c| c.rect.y }

        contours.each_with_object({}).with_index do |(contour, hash), index|
          piece = Piece.all[index]
          color = grab_color_from_contour(contour)

          Theia.logger.info "FOUND! contour for #{ Piece.all[index].key } " +
                            "with y: #{ contour.rect.y } with color: " +
                            "#{ color.to_a }"

          (hash[piece.key] ||= []).push(color)
        end
      end

      # Given the key of a piece, and the recorded color samples, updates the
      # piece with the new color data.
      def update_piece(key, samples)
        piece = Piece.find(key)
        piece.color = mean_samples(samples)
        piece.save!
      end

      # Given an array of color samples, returns the mean average color found.
      def mean_samples(samples)
        samples[0].zip(*samples[1..-1]).map do |colors|
          colors.reduce(:+).to_f / colors.length
        end
      end

    end # Calibration
  end # Mode
end # Theia
