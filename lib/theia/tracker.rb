module Theia
  class Tracker
    DISTANCE_THRESHOLD = 40
    THRESHOLD_RELIABILITY = 0.8

    attr_accessor :occurrences

    def initialize
      @occurrences = []
    end

    def track(occurrence)
      piece = @occurrences.detect do |o|
        o.distance(occurrence) < DISTANCE_THRESHOLD
      end

      if !piece
        @occurrences << occurrence
        return
      end

      if !piece.fresh? && (piece.last_cycle + 1) < occurrence.cycle_added
        @occurrences.delete(piece)
      else
        piece.last_cycle += 1
      end
    end

    def pieces
      pieces = []
      @occurrences.each do |occurrence|
        if !occurrence.fresh?
          pieces << occurrence.piece.key
        end
      end

      pieces
    end
  end
end
