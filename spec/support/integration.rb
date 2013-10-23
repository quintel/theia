# Given a block, expects whatever happens in that block to result in the
# addition of the given pieces. The game will be tested repeatedly until either
# the exected change occurs, or a given timeout (defaults to 3 seconds) is
# reached.
RSpec::Matchers.define :add_pieces do |*pieces|
  match do |action|
    raise('You forgot to pass the game to "add_pieces"') unless @game

    timeout  = @timeout || 3
    expected = (@game.pieces + Array(pieces).flatten.map(&:to_s)).sort

    action.call

    Theia::Spec.match_pieces(@game, expected, timeout)
  end

  chain :to do |game|
    @game = game
  end

  chain :within do |timeout|
    @timeout = timeout
  end
end

# Given a block, expects whatever happens in that block to result in the
# removal of the given pieces. The game will be tested repeatedly until either
# the exected change occurs, or a given timeout (defaults to 3 seconds) is
# reached.
RSpec::Matchers.define :remoev_pieces do |*pieces|
  match do |action|
    raise('You forgot to pass the game to "add_pieces"') unless @game

    timeout  = @timeout || 3
    expected = (@game.pieces - Array(pieces).flatten.map(&:to_s)).sort

    action.call

    Theia::Spec.match_pieces(@game, expected, timeout)
  end

  chain :to do |game|
    @game = game
  end

  chain :within do |timeout|
    @timeout = timeout
  end
end

# Runs an ImageCapture, stepping through each frame and running the given
# matchers against each frame.
#
# For example
#
#   expect(ImageCapture.new('...')).to run_game(game).matching(
#     add_pieces('electric_car', 'gas_plant'),
#     add_pieces('wind_turbine', 'wind_turbine')
#   )
RSpec::Matchers.define :run_game do |game|
  match do |capture|
    step_matchers = @steps.dup

    until capture.finished? || step_matchers.none?
      expect { capture.next }.to step_matchers.shift.to(game)
    end

    true
  end

  chain :matching do |*steps|
    @steps = Array(steps).flatten
  end
end

module Theia
  module Spec
    # Public: Given a game instance, repeatedly tests the pieces which are
    # recognised until either the game pieces match +expected+, or +timeout+
    # seconds have passed.
    #
    # Returns true or false.
    def self.match_pieces(game, expected, timeout)
      Timeout.timeout(timeout) do
        loop { game.pieces.sort == expected ? (return true) : sleep(0.25) }
      end
    rescue Timeout::Error
      false
    end

    # Mixed into integration tests. Runs the example and the game in separate
    # threads, with the game repeatedly testing the ImageCapture output, while
    # the second thread runs the example.
    module IntegrationHelper
      def self.included(base)
        base.send(:let, :game) do
          Theia::Mode::Game.new(capture: capture, blank: true)
        end

        base.send(:around) do |example|
          game_thread = Thread.new do
            # No GUI windows kplzthx. RSpec stubs aren't available in around
            # blocks so... please forgive me...
            def game.delta_window ; Class.new { def show(*) ; end }.new ; end
            def game.board_window ; delta_window ; end

            game.start
          end

          spec_thread = Thread.new do
            # The game needs a few frames to "warm up"; otherwise the first
            # frame chosen by the user is gobbled up as the board, with no
            # changes recognised.
            sleep 1.5

            example.run
            game_thread.terminate
          end

          game_thread.join
          spec_thread.join
        end
      end
    end # IntegrationHelper
  end # Spec
end # Theia
