module Theia
  module Spec
    # A stub for the SpyGlass Capture class, and provides support for using JPEG
    # images in place of a video. The user can then "step" through each JPEG as
    # something changes on the playing board.
    class ImageCapture
      # Public: The path to the image representing the current frame in the
      # video.
      #
      # Returns a string, or nil if no frames have been played yet.
      attr_reader :current_image

      # Public: Creates a new ImageCapture.
      #
      # directory - The directory which contains images simulating frames in a
      #             video in which something notable happens.
      #
      # Returns an ImageCapture.
      def initialize(directory)
        @directory = Pathname.new(directory).expand_path
        @files     = Pathname.glob(@directory.join('*.{png,jpg}'))

        @current_image = @files.first
      end

      # Public: Advances to the next frame, in alphanumeric order. If there are
      # no more frames to display, the final frame will be used.
      #
      # Returns the path to the next image.
      def next
        @current_image = @files[@files.index(@current_image) + 1] || @files.last
      end

      # Public: Returns if we have reached the last frame; the video has
      # finished.
      #
      # Returns true or false.
      def finished?
        @files[@files.index(@current_image) + 1].nil?
      end

      # Public: Skips immediately to the frame whose filename (minus the
      # extension) matches +name+.
      #
      # Returns the path to the image.
      def show(name)
        @current_image = @files.detect do |path|
          path.basename.to_s.
            sub(/^\d+-/, '').
            sub(/\.(?:png|jpg)$/, '') == name.to_s
        end
      end

      # Public: A stub for VideoCapture's +capture+ method; reads the current
      # image so that it can be used as a frame in a simulated video.
      #
      # dest - The Spyglass::Image into which the image contents will be copied.
      #
      # Returns the +dest+ argument.
      def capture(dest)
        VideoCapture.new(current_image.to_s) >> dest
        dest
      end

      alias_method :>>, :capture

      def inspect
        "#<#{ self.class.name } #{ @directory } (#{ @files.length } frames)>"
      end
    end # ImageCapture
  end # Spec
end # Theia
