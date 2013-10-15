module Theia
  module Mode
    class Game < VideoBase

      def initialize(options)
        super(options)

        @pieces = []
        @state  = :stopped
        @grace  = 0
      end

      def delta_window
        @delta_window ||= GUI::Window.new("Delta")
      end

      def board_window
        @board_window ||= begin
          window = GUI::Window.new("Board")
          window.on_click do |x, y|
            piece = @tracker.pieces.detect { |p| p.contains?(x, y) }
            next unless piece

            Theia.logger.info("Removing #{ piece.piece.key } as per user request.")
            piece.mark_for_deletion!(@cycle)
          end

          window
        end
      end

      def start
        puts "Game started. Ready to go!"
        loop do
          with_cycle do |frame, delta|
            delta_window.show(delta)

            with_each_contour do |contour, mean|
              # Skip if we happened to catch some noise.
              next if mean.zeros?

              # Calculate the mean color proximity with the piece definitions.
              # Because we go by probability, we grab the most likely one by
              # the lowest distance between colours.
              results = piece_definitions.map { |p| p.compare(mean) }
              min     = results.min
              piece   = Piece.all[results.index min]
              occurrence = Occurrence.new(contour.rect, mean, piece, @cycle)

              @tracker.track(occurrence)
            end

            # Only overwrite the piece list if the game isn't paused. This
            # weeds out erroneous results that we might get when a hand is
            # over the board placing a piece.
            @pieces = []

            @tracker.pieces.each do |piece|
              frame.draw_rectangle(piece.rect, Color.new(255, 255, 255))
              frame.draw_label(piece.piece.key, piece.rect.point)
              @pieces << piece.piece.key
            end

            board_window.show(frame)

            Theia.logger.info(@pieces)

            write_state!
          end
        end
      end

      #######
      private
      #######

      # Write to file to be picked up by the websocket.
      def write_state!
        state = {
          state:  @state,
          pieces: @pieces.sort
        }

        path = File.expand_path('../../../../data/', __FILE__)

        File.write "#{ path }/state.yml", state.to_yaml
      end

    end
  end
end
