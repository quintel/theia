module Theia
  module Mode
    class Base
      def initialize(options)
        @options = options
      end

      # Public: Parses and returns the piece definitions.
      def piece_definitions
        Piece.all
      end

    end # Base
  end # Mode
end # Theia
