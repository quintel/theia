class VideoExpectation
  attr_accessor :frames, :last_frame, :video_path

  def initialize(frames, video_path)
    @frames     = frames
    @video_path = video_path

    @last_frame = @frames.keys.max
  end

  def self.load(video_dir)
    expectations = YAML.load_file("#{ video_dir }/expectations.yml")
    video_path   = Dir["#{ video_dir }/video.*"][0]

    new(expectations, video_path)
  end
end
