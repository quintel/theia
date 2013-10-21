require 'theia'
require_relative 'support/video_expectation'
require_relative 'support/game_spec'
require_relative 'support/lib/theia/mode/game_test'

include Theia

# copy all the fixtures to a temp path

# Overwrite to use temp fixtures path
module Theia
  def self.data_path
    File.expand_path("../tmp", __FILE__)
  end

  def self.refresh_fixtures!
    FileUtils.cp_r('spec/fixtures/.', Theia.data_path)
  end

end

Theia.refresh_fixtures!
