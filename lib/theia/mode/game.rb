module Theia
  module Mode
    class Game < VideoBase

      def initialize(options)
        super(options)

        @pieces = []
        @state  = :stopped
        @grace  = 0
        @cycle  = 0

        resume_game! if options[:resume]
      end

      def delta_window
        @delta_window ||= GUI::Window.new("Delta")
      end

      def board_window
        @board_window ||= begin
          window = GUI::Window.new("Board")
          window.on_right_click do |x, y|
            piece = @tracker.pieces.detect { |p| p.contains?(x, y) }
            next unless piece

            Theia.logger.info("Removing #{ piece.piece.key } as per user request.")
            piece.mark_for_deletion!(@cycle)
          end

          window
        end
      end

      def start
        Theia.logger.info "Game started. Ready to go!"

        loop do
          with_cycle do |frame, delta|
            Log4r::NDC.push("##{ @cycle }")

            delta_window.show(delta)

            with_each_contour do |contour, mean|
              # Skip if we happened to catch some noise.
              next if mean.zeros?

              if @debug
                frame.draw_rectangle(contour.rect, Color.new(255, 0, 0))
              end

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

            case GUI::wait_key(100)
            when 88 # X - Clear all
              clear_state!
              break

            when 83 # S - Save and quit
              save_game_and_quit!
              break
            end

            Log4r::NDC.pop
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

      def save_game_and_quit!
        Theia.logger.info "Saving game and exiting..."
        game = @tracker.to_h

        path = File.expand_path('../../../../data/', __FILE__)

        File.write "#{ path }/saved.yml", game.to_yaml
        exit 0
      end

      def resume_game!
        begin
        Theia.logger.info "Resuming game"
        path = File.expand_path('../../../../data/', __FILE__)

        tracker = YAML.load_file("#{ path }/saved.yml")

        @tracker = Tracker.new

        @tracker.cycle  = tracker[:cycle]
        @cycle          = tracker[:cycle]

        tracker[:occurrences].each do |o|
          rect  = Rect.new(*o[:rect])
          color = Color.new(*o[:color])

          piece = Piece.all.detect { |p| p.key == o[:piece][:key] }

          occurrence = Occurrence.new(rect, color, piece, o[:cycle])
          occurrence.last_seen   = o[:last_seen]
          occurrence.first_seen  = o[:first_seen]

          @tracker.occurrences << occurrence
        end
        rescue Errno::ENOENT => ex
          Theia.logger.info "Could not find save file. Quitting..."
          exit 1
        end
      end

      def clear_state!
        Theia.logger.info "Clearing state..."

        @tracker = Tracker.new
        @tracker.cycle = @cycle
      end

    end
  end
end
