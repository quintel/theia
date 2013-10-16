module Theia

  class Tracker
    # Maximum distance at which a pice will be considered to be overlapping
    # another one
    DISTANCE_THRESHOLD = 10

    # Minimum value (between 0 and 1) where a detection is considered to be
    # reliable. Check `Occurrence#reliability` for the specifics.
    THRESHOLD_RELIABILITY = 0.8

    # Number of frames for which we keep an object marked for deletion
    # around. This ensures that we give enough time to the background
    # subtractor to "learn" that the object is not part of it anymore
    # so that it doesn't get reported the next frame.
    THRESHOLD_DELETION = 10

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
