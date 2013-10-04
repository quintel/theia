module Theia
  class Occurrence
    attr_accessor :rect, :piece, :last_cycle, :cycle_added

    def initialize(rect, piece, cycle)
      @rect         = rect
      @piece        = piece
      @last_cycle   = cycle
      @cycle_added  = cycle
    end

    def center
      x = @rect.x + (@rect.width / 2)
      y = @rect.y + (@rect.height / 2)

      Point.new(x, y)
    end

    def fresh?
      @last_cycle == @cycle_added
    end

    def distance(occurrence)
      p1 = self.center
      p2 = occurrence.center

      Math.sqrt( (p2.x - p1.x)**2 + (p2.y - p1.y)**2 ).abs
    end
  end
end
