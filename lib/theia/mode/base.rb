module Theia
  module Mode
    class Base
      def initialize(options)
        @options = options

        Theia.logger.level = options[:verbose] ? Log4r::DEBUG : Log4r::INFO
      end

      # Public: Parses and returns the piece definitions.
      def piece_definitions
        Piece.all
      end

    end # Base
  end # Mode
end # Theia
