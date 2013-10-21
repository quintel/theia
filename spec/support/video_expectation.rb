class VideoExpectation
  attr_accessor :name, :frames, :last_frame, :video_path

  def initialize(name, frames, video_path)
    @name       = name
    @frames     = frames
    @video_path = video_path

    @last_frame = @frames.keys.max
  end

  def self.load(video_dir)
    name          = File.basename(video_dir)
    expectations  = YAML.load_file("#{ video_dir }/expectations.yml")
    video_path    = Dir["#{ video_dir }/video.*"][0]

    new(name, expectations, video_path)
  end
end
