module Theia

  class Tracker
    # Maximum distance at which a pice will be considered to be overlapping
    # another one
    DISTANCE_THRESHOLD = 20

    # Minimum value (between 0 and 1) where a detection is considered to be
    # reliable. Check `Occurrence#reliability` for the specifics.
    RELIABILITY_THRESHOLD = 0.8

    # By dividing the areas of a new blob and an existing occurrence, we get
    # a ratio that should be within the values below.
    MATCH_RATIO_RANGE = (0.65..1.35)

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
        min, max = [piece.rect.area, occurrence.rect.area].sort

        if MATCH_RATIO_RANGE.include? max / min
          piece.mark_for_deletion!(@cycle)
        end
      else
        piece.last_seen += 1
      end
    end

    def cleanup!
      @occurrences.each do |occurrence|
        others = siblings(occurrence)

        # Check if the occurrence is not present in the delta anymore
        if occurrence.last_seen < @cycle
          # If it's marked for deletion, just get rid of it.
          if occurrence.marked_for_deletion?
            @occurrences.delete(occurrence)
          end

          # If it's not a reliable result, get rid of it.
          if occurrence.reliability(others) < RELIABILITY_THRESHOLD
            @occurrences.delete(occurrence)
          end
        end
      end
    end

    def pieces
      cleanup!

      pieces = []
      @occurrences.each do |occurrence|
        others = siblings(occurrence)
        if occurrence.reliability(others) >= RELIABILITY_THRESHOLD
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

    # Public: Represents the tracker as a hash
    def to_h
      {
        cycle:        @cycle,
        occurrences:  @occurrences.map(&:to_h)
      }
    end

    # Public: Builds the tracker from a hash
    def self.from_h(hash)
      tracker = Tracker.new
      tracker.cycle = hash[:cycle]

      tracker.occurrences = hash[:occurrences].map do |o|
        Occurrence.from_h(o)
      end

      tracker
    end
  end # Tracker

end # Theia
