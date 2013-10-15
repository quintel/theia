module Theia
  class Tracker
    DISTANCE_THRESHOLD    = 40
    THRESHOLD_RELIABILITY = 0.8
    THRESHOLD_DELETION    = 10

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

      if !piece.fresh?(@cycle) && (piece.last_seen + 1) < occurrence.first_seen
        piece_area = piece.rect.area
        occurrence_area = occurrence.rect.area
        min = [piece_area, occurrence_area].min.to_f
        max = [piece_area, occurrence_area].max.to_f

        if (max / min) <= 1.2 && (max / min) >= 0.8
          piece.mark_for_deletion!(@cycle)
        end
      else
        piece.last_seen += 1
      end
    end

    def cleanup!
      @occurrences.each do |occurrence|
        others = siblings(occurrence)
        if @cycle - occurrence.last_seen >= THRESHOLD_DELETION &&
          occurrence.reliability(others) < THRESHOLD_RELIABILITY
          @occurrences.delete(occurrence)
        end
      end
    end

    def pieces
      cleanup!

      pieces = []
      @occurrences.each do |occurrence|
        others = siblings(occurrence)
        if occurrence.reliability(others) >= THRESHOLD_RELIABILITY
          pieces << occurrence
        end
      end

      pieces
    end

    def siblings(occurrence)
      siblings = []
      @occurrences.each do |o|
        next if o == occurrence
        next if o.first_seen != occurrence.first_seen

        siblings << o
      end

      siblings
    end
  end
end
