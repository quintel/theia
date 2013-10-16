module Theia

  class Occurrence
    attr_accessor :rect, :color, :piece, :last_seen, :first_seen, :deletion

    def initialize(rect, color, piece, cycle)
      @rect       = rect
      @color      = color
      @piece      = piece
      @last_seen  = cycle
      @first_seen = cycle
      @deletion   = false
    end

    # Public: Returns the center point for the rect containing the occurrence.
    def center
      x = @rect.x + (@rect.width / 2)
      y = @rect.y + (@rect.height / 2)

      Point.new(x, y)
    end

    # Public: Returns true if a point is contained within the bounding rect.
    def contains?(x, y)
      x >= @rect.x && x <= (@rect.x + @rect.width) &&
      y >= @rect.y && y <= (@rect.y + @rect.height)
    end

    # Public: Returns true if an occurrence has not been "swallowed" into the
    #         map yet.
    def fresh?(cycle)
      @last_seen == cycle
    end

    # Public: Marks an occurrence for deletion.
    def mark_for_deletion!(cycle)
      @deletion   = true
      @last_seen  = cycle
    end

    # Public: Returns whether an occurrence is marked for deletion.
    def marked_for_deletion?
      @deletion
    end

    # Public: Euclidian distance between this and another occurrence. This is
    #         calculated using the center points of the occurrences' bounding
    #         rects.
    def distance(occurrence)
      p1 = self.center
      p2 = occurrence.center

      Math.sqrt( (p2.x - p1.x)**2 + (p2.y - p1.y)**2 ).abs
    end

    # Public: Returns a reliability score for an occurrence. The range of
    #         possible values goes from 0 (not reliable) to 1 (absolutely
    #         sure this is the right thing)
    def reliability(siblings)
      # If a piece is marked for deletion, return 0. This ensures that
      # it is removed when the cleanup comes through.
      if @deletion
        Theia.logger.debug "#{ @piece.key } is marked for deletion."
        return 0
      end

      # The initial score is based on the number of frames the piece
      # has been present for. 4 or more frames gives it full marks.
      reliability = [@last_seen - @first_seen, 4].min / 4.0

      Theia.logger.debug "Color spotted #{ @color.to_a }"
      Theia.logger.debug "Color difference for best match #{ @piece.key }= #{ @piece.compare(color) }"

      # A piece loses 15% of reliability for every sibling
      reliability = 0 if siblings.size > 4

      if reliability < Tracker::RELIABILITY_THRESHOLD
        Theia.logger.debug "#{ @piece.key } is not reliable (#{ reliability }, #{ siblings.length } siblings, seen at #{ @first_seen } and then at #{ @last_seen })"
      end

      reliability
    end

    # Public: Represents an occurrence as a hash
    def to_h
      {
        rect:       [@rect.x, @rect.y, @rect.width, @rect.height],
        color:      @color.to_a,
        piece:      @piece.to_h,
        last_seen:  @last_seen,
        first_seen: @first_seen,
        deletion:   @deletion
      }
    end

    # Public: Builds an occurrence from a hash
    def self.from_h(hash)
      rect  = Rect.new(*hash[:rect])
      color = Color.new(*hash[:color])
      piece = Piece.find(hash[:piece][:key])

      occurrence = Occurrence.new(rect, color, piece, hash[:cycle])
      occurrence.last_seen   = hash[:last_seen]
      occurrence.first_seen  = hash[:first_seen]

      occurrence
    end
  end # Occurrence

end # Theia
