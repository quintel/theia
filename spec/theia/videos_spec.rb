require 'spec_helper'

unless RSpec::world.exclusion_filter[:video]
  Dir[File.expand_path('../../fixtures/videos/*', __FILE__)].each do |video_dir|
    video = File.basename(video_dir)
    describe "Video: #{ video }", video: true do
      GameSpec.start VideoExpectation.load(video_dir)
    end
  end
end
