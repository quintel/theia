module Theia
  # Keeps track of the state of the board in the Game mode, and logs each change
  # as pieces are added and removed.
  class Logger
    # Public: Creates a new change logger which outputs messages about each
    # alteration to the given +io+ object.
    #
    # io     - The thing to which you want to write the log. This can be an
    #          (already opened file, $stdout, etc).
    # pieces - The initial board state.
    #
    # Returns the logger.
    def initialize(io, pieces = [])
      @io = io
      @previous_state = count_pieces(pieces)
    end

    # Public: Adds a new log entry, comparing the current game state to the
    # previous one. Nothing is logged if the state is unchanged.
    #
    # current_pieces - The pieces currently detected on the board.
    #
    # Returns nothing.
    def log(current_pieces)
      current_state = count_pieces(current_pieces)

      if current_state != @previous_state
        write(describe(current_state) + " (#{ difference(current_state) })")
        @previous_state = current_state
      end
    end

    # Public: Writes a message to the IO.
    def write(message)
      @io.puts(message) if @io
    end

    #######
    private
    #######

    # Given an array of piece names, creates a hash counting the number of
    # times each piece appears.
    #
    #   pieces_summary(%w( a b a c ))
    #   # => { "a" => 2, "b" => 1, "c" => 1 }
    #
    # Returns a hash.
    def count_pieces(pieces)
      grouped = pieces.group_by { |name| name }

      grouped.each_with_object({}) do |(key, pieces), summary|
        summary[key] = pieces.length
      end
    end

    # Creates a summary of what items are currently on the board.
    def describe(current_state)
      if current_state.empty?
        'Empty board'
      else
        current_state.map { |key, count| "#{ count }x #{ key }" }.join(', ')
      end
    end

    # Creates a string describing the difference between the given state, and
    # the previous state stored in the logger.
    def difference(current_state)
      (current_state.keys | @previous_state.keys).map do |key|
        current_count  = current_state.fetch(key, 0)
        previous_count = @previous_state.fetch(key, 0)

        if current_count > previous_count
          "+#{ current_count - previous_count } #{ key }"
        elsif current_count < previous_count
          "-#{ previous_count - current_count } #{ key }"
        end
      end.compact.join(', ')
    end
  end # Logger
end # Theia
