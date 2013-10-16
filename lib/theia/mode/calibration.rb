module Theia
  module Mode
    class Calibration < VideoBase

      RECT_SIZE = 100
      MARGIN = 50
      LEARN_FRAMES = 75

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

        colors = Hash.new

        Piece.all.each { |p| colors[p.key] = [] }

        Theia.logger.info "Starting..."

        Theia.logger.info "Please put the pieces on the map from bottom to" +
                          "Top in the following order:\n\n" +
                          Piece.all.map { |p| "* #{ p.key} \n" }.join

        Theia.logger.info "Press any key to continue..."

        unless $stdin.gets.chomp =~ /^$/
          puts 'Aborted. Goodbye.'
          exit 0
        end

        display = Image.new(Map::A1_SIZE, Image::TYPE_8UC3)

        with_cycle do |frame, delta|

          display.copy!(frame)
          board_window.show(display)
          delta_window.show(delta)

          Theia.logger.info "I found #{ contours.size } # of contours."

          unless contours.size == Piece.all.size
            raise("I found #{ contours.size } on the board, " +
                  "but #{ Piece.all.size } on disk. " +
                  "Please add/remove pieces to align numbers.")
          end

          contours.sort_by! { |c| c.rect.y }

          contours.each_with_index do |contour, index|
            piece = Piece.all[index]

            color = grab_color_from_contour(contour)
            Theia.logger.info "FOUND! contour for #{ Piece.all[index].key } with y: #{ contour.rect.y } with color: #{ color.to_a }\n"

            colors[piece.key] << color
          end

          # We have enough colors
          if colors.all? { |k, v| v.size > 5 }

            # TODO: Calculate average color
            colors.each do |key, array|
              piece = Piece.find(key)
              piece.color = array.first.to_a
              piece.save!
            end

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

    end
  end
end
