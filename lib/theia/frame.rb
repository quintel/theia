module Theia
  class Frame

    attr_reader :observations

    def initialize
      @observations = []
    end

    def add_observation(observation)
      @observations << observation
    end

  end
end
