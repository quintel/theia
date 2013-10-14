module Theia
  class Tracker
    DISTANCE_THRESHOLD    = 40
    THRESHOLD_RELIABILITY = 0.8
    THRESHOLD_DELETION    = 4

    attr_accessor :occurrences, :cycle

    def initialize
      @occurrences = []
      @cycle = 0
    end

    def next_cycle!
      @cycle += 1
    end

    def track(occurrence)
      piece = @occurrences.detect do |o|
        o.distance(occurrence) < DISTANCE_THRESHOLD
      end

      if !piece
        @occurrences << occurrence
        return
      end

      if !piece.fresh? && (piece.last_seen + 3) < occurrence.first_seen
        piece.mark_for_deletion!(@cycle)
      else
        piece.last_seen += 1
      end
    end

    def cleanup!
      @occurrences.each do |occurrence|
        if @cycle - occurrence.last_seen >= THRESHOLD_DELETION && 
          occurrence.reliability < THRESHOLD_RELIABILITY
          @occurrences.delete(occurrence)
        end
      end
    end

    def pieces
      cleanup!

      pieces = []
      @occurrences.each do |occurrence|
        if occurrence.reliability >= THRESHOLD_RELIABILITY
          pieces << occurrence.piece.key
        end
      end

      pieces
    end
  end
end
