module Theia

  # Video capture class. Encapsulates boundaries so that we deal with
  # smaller images.
  class Capture
    # Public: Gets/Sets the bounds for which frames are returned.
    attr_accessor :bounds

    # Internal: Initialize a capture instance.
    #
    # options - An options hash.
    def initialize(options)
      @cap = options[:capture] || VideoCapture.new(options['source'] || 0)

      # Preemptively instantiate the image object we'll use.
      # This speeds up the process considerably, as memory
      # re-allocation doesn't happen very often if we do.
      @frame = Image.new
    end

    # Public: Grab a frame from the video source.
    #
    # dest - The destination image.
    #
    # Examples
    #
    #   cap.capture(new_frame)
    #   cap >> new_frame
    #
    # Copies a new frame from the video source into the destination
    # image and crops it if the bounds are defined.
    def capture(dest)
      @cap >> @frame

      @frame.crop!(@bounds) if @bounds
      dest.copy!(@frame)
    end

    alias_method :>>, :capture
  end # Capture

end # Theia
