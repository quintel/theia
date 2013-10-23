module Theia

  module Mode
    class ColorMeasure < VideoBase

      # How many frames do we want the background to 'adapt' and stabilize.
      LEARN_FRAMES = 75

      # How many times to sample a colour during calibration before we have
      # enough data.
      COLOR_SAMPLES = 5

      def initialize(options)
        super(options)

        @key = options["key"] || raise("Please specify key!")

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

        if Theia.logger.level > Log4r::INFO
          Theia.logger.level = Log4r::INFO
        end
      end

      def start
        puts <<-MESSAGE.gsub(/^ +/, '')

          Please put some pieces of #{ @key } on the map anywhere you like.

          Press the key of the piece to continue, or 'q' to exit...
        MESSAGE

        input = $stdin.gets.strip

        if input == 'q'
          puts 'Aborted. Goodbye.'
          exit 0
        end

        unless piece = Piece.find(@key)
          puts "Cannot find #{@key}"
        end

        display = Image.new(Map::A1_SIZE, Image::TYPE_8UC3)
        colors  = {}

        catch(:done) do
          loop do
            with_cycle do |frame, delta|
              display.copy!(frame)
              board_window.show(display)
              delta_window.show(delta)

              Theia.logger.info "I found #{ contours.size } # of contours."

              colors_from_contours!(contours, colors)

              # We have enough colors
              if colors.all? { |_, samples| samples.size >= COLOR_SAMPLES }
                colors.each do |key, samples|
                  samples.each do |sample|
                    Theia.logger.info(piece.compare(sample))
                  end
                end

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

          (hash[piece.key] ||= []).push(color)
        end
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

