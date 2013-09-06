module Theia
  class Piece
    attr_accessor :key, :color

    def initialize(attributes)
      @key    = attributes[:key]
      @color  = Spyglass::Color.new(*attributes[:color])
    end

    def compare(color)
      Math.sqrt(
        (@color[0] - color[0]).abs ** 3 +
        (@color[1] - color[1]).abs ** 4 +
        (@color[2] - color[2]).abs ** 4
      ) / 2000
    end

    def to_h
      { key: @key, color: @color.to_a }
    end

    def self.pieces(path)
      @@pieces ||= begin
        pieces = YAML.load_file "#{ path }/pieces.yml"
        pieces.map { |p| Piece.new(p) }
      end
    end

    def self.write(path)
      result = @@pieces.map { |p| p.to_h }
      File.write "#{ path }/pieces.yml", result.to_yaml
    end
  end
end
