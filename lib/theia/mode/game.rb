module Theia

  module Mode
    class Game < VideoBase
      attr_reader :pieces

      def initialize(options)
        super(options)

        @pieces               = []
        @occurrences          = []
        @previous_occurrences = []
        @cycle                = 0
        @selected_piece       = nil

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

          window.on_click do |x, y|
            occurrence = @tracker.pieces.detect { |p| p.contains?(x, y) }

            if occurrence
              piece            = occurrence.piece
              idx              = Piece.all.index(piece)
              next_idx         = (idx + 1) % Piece.all.length
              occurrence.piece = Piece.all[next_idx]
              occurrence.color = occurrence.piece.color
            elsif @selected_piece
              rect       = Rect.new(x - 18, y - 18, 36, 36)
              piece      = @selected_piece
              occurrence = Occurrence.new(rect, piece.color, piece, @cycle)
              occurrence.mark_as_forced!
              @tracker.track(occurrence)
              @selected_piece = nil
            end
          end

          window
        end
      end

      def start
        super

        Theia.logger.info "Game started. Ready to go!\n" +
                          "Keep the following keys supressed on the Exec Window:\n" +
                          "* X = clear all\n" +
                          "* S = Save and quit\n" +
                          "* Left-click on a piece shifts it to the next one\n" +
                          "* Left-click on an empty spot adds a piece\n" +
                          "* Right-click on a piece = removes it"

        loop do
          with_cycle(@cycle) do |frame, delta|
            show_piece_selection!
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

            # Here, we have to call `dup` on the pieces variable so that we don't
            # do a reference equals.
            @pieces               = []
            @previous_occurrences = @occurrences.dup
            @occurrences          = @tracker.pieces

            @occurrences.each do |occurrence|
              frame.draw_rectangle(occurrence.rect, Color.new(255, 255, 255))
              frame.draw_label(occurrence.piece.key, occurrence.rect.point)
              @pieces << occurrence.piece.key
            end

            # Draw the FPS indicator on the upper right corner.
            frame.draw_label("FPS: %.2f" % @fps, Point.new(frame.cols - 80, 20), )

            board_window.show(frame)

            output_diff
            write_state!

            case GUI::wait_key(100)
            when 88 # X - Clear all
              clear_state!
            when 83 # S - Save and quit
              save_game_and_quit!
            when 100 # d - debugger
              debugger
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
          pieces: @pieces.sort
        }

        File.write Theia.data_path_for('state.yml'), state.to_yaml
      end

      # Private: Creates or shows a window for the piece selection
      def piece_selection_window
        @piece_sel_window ||= begin
          window = GUI::Window.new('Piece selection')

          window.on_click do |x, y|
            piece_idx = y / 20
            @selected_piece = Piece.all[piece_idx]
          end

          window
        end
      end

      # Private: Shows the piece selection window.
      def show_piece_selection!
        pieces = Piece.all.count
        piece_sel = Image.new(Size.new(200, (20 * pieces)), Image::TYPE_8UC3)
        piece_sel.fill!(Color.new(0))
        Piece.all.each_with_index do |piece, idx|
          offset_y = idx * 20
          text = piece.key

          if @selected_piece == piece
            text = ">>> #{ text } <<<"
          end

          piece_sel.draw_label(text, Point.new(0, offset_y + 10))
        end
        piece_selection_window.show(piece_sel)
      end

      # Private: Logs the difference between the previous frame and the current one.
      def output_diff
        added   = @occurrences - @previous_occurrences
        removed = @previous_occurrences - @occurrences

        added.each do |occurrence|
          Theia.logger.info("Added: #{ occurrence.piece.key } (color diff: #{ occurrence.color_distance * 100 }%)")
        end

        removed.each do |occurrence|
          Theia.logger.info("Removed: #{ occurrence.piece.key }")
        end
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
