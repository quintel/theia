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
        @board_window ||= GUI::Window.new("Board")
      end

      def start
        puts "Game started. Ready to go!"
        loop do
          with_cycle do |frame, delta|
            board_window.show(frame)
            delta_window.show(delta)

            @state = :running

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
            @pieces = @tracker.pieces

            # Theia.logger.warn("Shit!")
            Theia.logger.info(@pieces)
            # Theia.logger.debug("Shit!")

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
