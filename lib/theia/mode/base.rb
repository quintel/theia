module Theia
  module Mode
    class Base
      def initialize(options)
        @options = options

        ensure_data_path!
      end

      # Public: Returns the data path.
      def data_path
        @path ||= @options['data-dir'] ||
          File.expand_path('../../../data', File.dirname(__FILE__))
      end

      # Public: Parses and returns the piece definitions.
      def piece_definitions
        Piece.pieces data_path
      end

      # Private: Ensures the data path exists.
      #
      # If it doesn't exist, create the directory.
      private
      def ensure_data_path!
        Dir.mkdir(data_path) unless File.exists? data_path
      end
    end
  end
end
