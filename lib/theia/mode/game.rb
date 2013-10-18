module Theia

  module Mode
    class Game < VideoBase

      def initialize(options)
        super(options)

        @pieces = []
        @state  = :stopped
        @cycle  = 0

        resume_game! if     options[:resume]
        setup_game!  unless options[:blank]
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
        super

        Theia.logger.info "Game started. Ready to go!"

        loop do
          with_cycle(@cycle) do |frame, delta|
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
            when 83 # S - Save and quit
              save_game_and_quit!
            end
          end

          break if @stop
        end
      end

      #######
      private
      #######

      # Private: Write to file to be picked up by the websocket.
      def write_state!
        state = {
          state:  @state,
          pieces: @pieces.sort
        }

        File.write Theia.data_path_for('state.yml'), state.to_yaml
      end

      # Private: Saves the current state to `data/saved.yml` and quits
      #          the game.
      def save_game_and_quit!
        Theia.logger.info "Saving game and exiting..."

        game = @tracker.to_h
        File.write Theia.data_path_for('saved.yml'), game.to_yaml
        @stop = true
      end

      # Private: Resumes a previous session by loading it from
      #          `data/saved.yml`
      def resume_game!
        Theia.logger.info "Resuming game"
        tracker = YAML.load_file(Theia.data_path_for('saved.yml'))

        @tracker = Tracker.from_h(tracker)
        @cycle   = tracker[:cycle]
      rescue Errno::ENOENT
        Theia.logger.info "Could not find save file. Quitting..."
        exit 1
      end

      # Private: Resets the tracker.
      def clear_state!
        Theia.logger.info "Clearing state..."

        @tracker = Tracker.new
        @tracker.cycle = @cycle
      end

      # Private: Builds up the tracker to an initial state of the game.
      #          This is defined in `data/template.yml`
      def setup_game!
        state = YAML.load_file(Theia.data_path_for('template.yml'))

        # Build up the tracker and bring the cycle to 0. This allows
        # the pieces to be registered and in an already detected state.
        start_cycle     = state.length * -10
        @cycle          = start_cycle
        @tracker.cycle  = start_cycle

        state.each do |initial_piece|
          piece = Piece.find(initial_piece[:key])
          rect  = Rect.new(*initial_piece[:rect])

          5.times do
            next_cycle!
            occurrence = Occurrence.new(rect, piece.color, piece, @cycle)
            @tracker.track(occurrence)
          end

          5.times { next_cycle! }
        end
      rescue Errno::ENOENT
        Theia.logger.warn "Could not find template. Starting with a blank slate"
      end
    end # Game
  end # Mode

end # Theia
