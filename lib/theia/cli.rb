require 'theia'

module Theia
  class CLI < Thor
    default_task :game
    class_option "verbose",   type: :boolean, banner: "Enable verbose output mode", aliases: '-v'
    class_option "data-dir",  type: :string,  banner: "Directory where the data files reside"
    class_option "debug",     type: :boolean, banner: "Saves frames to a temporary directory"

    desc "game", "Starts up the game"
    method_option "source", type: :string, banner: "Specify which video source to use"
    long_desc <<-D
      Game starts up the game server. It's responsible for controlling the video capture,
      keeping track of what's going on in the map, and for witing the state down to files.
    D
    def game
      game = Mode::Game.new(options)
      game.start
    end

    desc "calibrate", "Calibrates Theia for lighting conditions"
    method_option "pieces", type: :array, banner: "Comma-separated list of pieces to calibrate (all by default)"
    method_option "source", type: :string, banner: "Specify which video source to use"
    long_desc <<-D
      Whenever the environment where the game board has changed, it's always a good idea to
      recalibrate the game, in order to get the most precise detections.
    D
    def calibrate
      calibration = Mode::Calibration.new(options)
      calibration.start
    end

    desc "websocket", "Starts the websocket server to publish game state"
    method_option "port", type: :numeric, banner: "Port on which the websocket runs", default: 8080
    long_desc <<-D
      This mode starts a websocket server that allows external applications to connect to theia and get the
      current state of the game.
    D
    def websocket
      websocket = Mode::Websocket.new(options)
      websocket.start
    end
  end
end
