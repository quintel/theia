module Theia
  module Mode
    class GameTest < Game
      def initialize(fixture)
        Theia.silence_logger!
        @fixture = fixture
        opts = {"source" => @fixture.video_path, "blank" => true }

        super(opts)
      end

      def with_cycle(cycle_number)
        super cycle_number

        return unless @fixture.frames[cycle_number]
        GameSpec.run_checks(@fixture, @pieces, cycle_number)
        @stop = true if cycle_number >= @fixture.last_frame
      end
    end
  end
end
