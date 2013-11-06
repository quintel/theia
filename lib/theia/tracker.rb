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

    # Public: Increments the cycle
    def next_cycle!
      @cycle += 1
    end

    # Public: Given a new occurrence, this method tries to figure out:
    #
    #         - If it already exists on the map, marking the current
    #           cycle as the last one where the occurrence was seen.
    #
    #         - If it hasn't been last seen recently, the tracker marks
    #           an occurrence up for deletion. For this to work, the
    #           tracker also takes under consideration the area ratio
    #           between the first time a piece was recorded and the
    #           time where it reappears on the delta.
    def track(occurrence)
      # Try to find an existing occurrence that is within a very close
      # distance to the one that is being tracked. If none is found,
      # add it to the occurrences and return.
      piece = @occurrences.detect { |o| o.distance(occurrence) < DISTANCE_THRESHOLD }
      @occurrences << occurrence and return if !piece

      if !piece.fresh?(@cycle) && (piece.last_seen + 1) < occurrence.first_seen
        # If this occurrence has previously been reported, and has since
        # been "swallowed" in the background subtractor, try to figure out
        # whether the area ratio between the original rect and the new one
        # is within an acceptable margin. This prevents shadows from
        # accidentaly removing pieces.
        min, max = [piece.rect.area, occurrence.rect.area].sort

        if MATCH_RATIO_RANGE.include? (max.to_f / min.to_f) || piece.forced
          piece.mark_for_deletion!(@cycle)
        end
      else
        # The piece has been recently tracked, so just increment the cycle
        # at which it was last seen.
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

    # Public: Return valid (detected and reliable) results to be reported
    #         to the frontend.
    def pieces
      cleanup!

      @occurrences.select do |occurrence|
        others = siblings(occurrence)
        occurrence.reliability(others) >= RELIABILITY_THRESHOLD
      end
    end

    # Public: Return all occurrences that showed up in the same cycle as
    #         the passed object.
    def siblings(occurrence)
      @occurrences.select do |o|
        o != occurrence && o.first_seen == occurrence.first_seen
      end
    end

    # Public: Represents the tracker as a hash
    def to_h
      {
        cycle:       @cycle,
        occurrences: @occurrences.map(&:to_h)
      }
    end

    # Public: Builds the tracker from a hash
    def self.from_h(hash)
      tracker       = Tracker.new
      tracker.cycle = hash[:cycle]

      tracker.occurrences = hash[:occurrences].map do |o|
        Occurrence.from_h(o)
      end

      tracker
    end
  end # Tracker

end # Theia
