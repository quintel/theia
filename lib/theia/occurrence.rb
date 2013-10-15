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

    def center
      x = @rect.x + (@rect.width / 2)
      y = @rect.y + (@rect.height / 2)

      Point.new(x, y)
    end

    def contains?(x, y)
      x >= @rect.x && x <= (@rect.x + @rect.width) &&
      y >= @rect.y && y <= (@rect.y + @rect.height)
    end

    def fresh?(cycle)
      @last_seen == cycle
    end

    def mark_for_deletion!(cycle)
      @deletion   = true
      @last_seen  = cycle
    end

    def distance(occurrence)
      p1 = self.center
      p2 = occurrence.center

      Math.sqrt( (p2.x - p1.x)**2 + (p2.y - p1.y)**2 ).abs
    end

    def reliability(siblings)
      # If a piece is marked for deletion, return 0. This ensures that
      # it is removed when the cleanup comes through.
      if @deletion
        Theia.logger.info "#{ @piece.key } is marked for deletion."
        return 0
      end

      # The initial score is based on the number of frames the piece
      # has been present for. 4 or more frames gives it full marks.
      reliability = [@last_seen - @first_seen, 4].min / 4.0

      # Remove the distance to the closest piece's color.
      # reliability -= @piece.compare(color)

      Theia.logger.info "Color spotted #{ @color.to_a }"
      Theia.logger.info "Color difference for best match #{ @piece.key }= #{ @piece.compare(color) }"

      # A piece loses 15% of reliability for every sibling
      reliability = 0 if siblings.size > 4

      if reliability < Tracker::THRESHOLD_RELIABILITY
        Theia.logger.info "#{ @piece.key } is not reliable (#{ reliability }, #{ siblings.length } siblings, seen at #{ @first_seen } and then at #{ @last_seen })"
      end

      reliability
    end
  end
end
