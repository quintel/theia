module Theia
  module Mode
    class Game < VideoBase

      def initialize(options)
        super(options)

        @pieces = []
        @state  = :stopped
        @grace  = 0
        @cycle  = 0

        if options[:resume]
          resume_game!
        elsif !options[:blank]
          setup_game!
        end
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
      rescue Errno::ENOENT
        Theia.logger.info "Could not find save file. Quitting..."
        exit 1
      end

      def clear_state!
        Theia.logger.info "Clearing state..."

        @tracker = Tracker.new
        @tracker.cycle = @cycle
      end

      def setup_game!
        path = File.expand_path('../../../../data/', __FILE__)
        state = YAML.load_file("#{ path }/template.yml")

        # Step 1: Build up the tracker and bring the cycle to 0. This allows
        # the pieces to be registered and in an already detected state.
        start_cycle     = state.length * -10
        @cycle          = start_cycle
        @tracker.cycle  = start_cycle

        state.each do |initial_piece|
          piece = Piece.all.detect { |p| p.key == initial_piece[:key] }
          rect  = Rect.new(*initial_piece[:rect])

          5.times do
            next_cycle!
            occurrence = Occurrence.new(rect, piece.color, piece, @cycle)
            @tracker.track(occurrence)
          end

          5.times { next_cycle! }
        end

        # Step 2: Show a video of the map, and draw the boundaries where we
        # expect the pieces to be in their initial position.
        loop do
          frame = nil

          # Loop until we get a (perspective corrected) frame from the map.
          while !frame do
            frame = @map.frame
          end

          frame.resize!(Map::A0_SIZE)

          state.each do |initial_piece|
            rect = Rect.new(*initial_piece[:rect])
            frame.draw_rectangle(rect, Color.new(255, 255, 255))
            frame.draw_label(initial_piece[:key], rect.point)
          end

          board_window.show(frame)
          break if GUI::wait_key(100) > 0
        end
      rescue Errno::ENOENT
        Theia.logger.warn "Could not find template. Starting with a blank slate"
      end
    end
  end
end
