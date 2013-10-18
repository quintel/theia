Dir[File.expand_path('../../fixtures/videos/*', __FILE__)].each do |video_dir|
  video = File.basename(video_dir)
  describe "Video: #{ video }" do
    fixture = VideoExpectation.load(video_dir)
    GameSpec.start(fixture, self)
  end
end

