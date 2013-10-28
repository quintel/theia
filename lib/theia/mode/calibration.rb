module Theia

  module Mode
    class Calibration < VideoBase

      # How many frames do we want the background to 'adapt' and stabilize.
      LEARN_FRAMES = 75

      # How many times to sample a colour during calibration before we have
      # enough data.
      COLOR_SAMPLES = 5

      # How many vertical slices we take to measure reference points
      VERTICAL_SLICES = 6

      # How many horizontal slices we take to measure reference points
      HORIZONTAL_SLICES = 6

      def initialize(options)
        super(options)

        # Use a different background subtraction algorithm
        @bg_subtractor = BackgroundSubtractor::MOG2.new history: 50, threshold: 8

        # Train the background first for 100 frames.

        Theia.logger.info "Starting Background learning. Please hold on..."

        LEARN_FRAMES.times do |i|
          print "At step #{ i + 1 } of #{ LEARN_FRAMES } now...\r"

          @frame = nil
          while !@frame do
            @frame = @map.frame
          end
          @bg_subtractor.subtract(@frame, 1.0/LEARN_FRAMES)
        end


      end

      def start
        puts <<-MESSAGE.gsub(/^ +/, '')

          Grabbing reference points...

        MESSAGE
        catch(:done) do
          with_cycle do |frame, delta|
            # Grab reference point colours to compare later.
            references = []
            ref_width  = frame.cols / VERTICAL_SLICES
            ref_height = frame.rows / HORIZONTAL_SLICES

            VERTICAL_SLICES.times do |x|
              HORIZONTAL_SLICES.times do |y|
                # Here we grab a chunk of the map, and get the colour of the
                # pixel in the middle. This will help us determine later on
                # what the variation between the calibration and the current
                # state is so that we adjust the colors accordingly.
                rect = Rect.new(x * ref_width, y * ref_height, ref_width, ref_height)
                color = frame.color_at(rect.center)

                references << { rect: rect.to_a, color: color.to_a }
              end
            end

            update_reference_points(references)

            throw :done
          end
        end

        puts <<-MESSAGE.gsub(/^ +/, '')

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
        colors  = {}

        catch(:done) do
          loop do
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

              colors_from_contours!(contours, colors)

              # We have enough colors
              if colors.all? { |_, samples| samples.size >= COLOR_SAMPLES }
                colors.each { |key, samples| update_piece(key, samples) }

                Theia.logger.info "Done! New colors have been saved to disk!"
                throw :done
              end
            end
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
      def colors_from_contours!(contours, previous)
        contours = contours.sort_by { |c| c.rect.y }

        contours.to_enum.with_index.each_with_object(previous) do |(contour, index), hash|
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

      def update_reference_points(references)
        path = Theia.data_path_for('references.yml')
        File.write(path, references.to_yaml)
      end

      # Given an array of color samples, returns the mean average color found.
      def mean_samples(samples)
        samples[0].to_a.zip(*samples[1..-1].map(&:to_a)).map do |colors|
          colors.reduce(:+).to_f / colors.length
        end
      end

    end # Calibration
  end # Mode

end # Theia
