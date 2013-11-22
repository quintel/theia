module Theia

  class Piece

    attr_accessor :key, :color, :method

    def initialize(attributes)
      @key    = attributes[:key]
      @color  = Spyglass::Color.new(*attributes[:color])
      @method = :normal
    end

    # Public: Returns the Euclidean distance of the piece's color
    #         between 0 and 1, where 0 is a perfect match.
    def compare(color)
      light_diff = case @method
                   when :normal
                     0
                   when :b
                     @color[0] - color[0]
                   end

      Math.sqrt(
        light_diff ** 2 +
        (@color[1] - color[1]).abs ** 2 + # Color dimension 1
        (@color[2] - color[2]).abs ** 2   # Color dimension 2
      ) / 386 # Max value for the above operation.
    end

    # Public: Represents a piece as a hash
    def to_h
      { key: @key, color: @color.to_a }
    end

    # Writes the current piece back to disk.
    def save!
      pieces = YAML.load_file(self.class.data_path)

      pieces.delete_at(pieces.index { |piece| piece[:key] == key })
      pieces.push(to_h)

      File.write(self.class.data_path, pieces.to_yaml)
    end

    #------- CLASS METHODS ---------------------------------------------------

    # Public: Returns all the pieces.
    def self.all(options = {})
      @@pieces = nil if options[:force]
      @@pieces ||= begin
        pieces = YAML.load_file(Theia.data_path_for('pieces.yml'))
        pieces.map! { |p| Piece.new(p) }.sort_by { |p| p.key }

        pieces.each do |left|
          pieces.each do |right|
            if left.compare(right.color) < 3.0
              left.method  = :b
              right.method = :b
            end
          end
        end

        pieces
      end
    end

    # Public: Returns the Piece that best matches **color**
    def self.find_by_color(color)
      self.all.sort_by { |p| p.compare(color) }.first
    end

    # Public: Returns the Piece whose key is **key**
    def self.find(key)
      self.all.detect { |p| p.key == key }
    end

    # Public: Writes all the pieces back to disk
    def self.write
      result = self.all.map { |p| p.to_h }
      File.write self.data_path, result.to_yaml
    end

    def self.data_path
      Theia.data_path_for('pieces.yml')
    end
  end # Piece

end # Theia
