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

    def fresh?
      @last_seen == @first_seen
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

    def reliability
      # If a piece is marked for deletion, return 0. This ensures that
      # it is removed when the swipe comes through.
      return 0 if @deletion

      reliability = [@last_seen - @first_seen, 2].min / 2
      reliability -= @piece.compare(color)
      if reliability < 0.8
        puts "#{ @piece.key } -- #{ reliability } -- #{ @last_seen }"
      end
      reliability
    end
  end
end
