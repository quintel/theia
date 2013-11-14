module Theia

  class Camera

    VENDORS = {
      1133 => "Logitech"
    }

    INPUT_TERMINAL  = 0x0100
    PROCESSING_UNIT = 0x0300

    CONTROLS = {
      auto_exposure: {
        unit:      INPUT_TERMINAL,
        selector:  0x0200,
        size:      1,
        type:      :bool,
        values:    [0x08, 0x01] # True / False
      },

      exposure: {
        unit:      INPUT_TERMINAL,
        selector:  0x0400,
        size:      4
      },

      brightness: {
        unit:      PROCESSING_UNIT,
        selector:  0x0200,
        size:      2
      },

      contrast: {
        unit:      PROCESSING_UNIT,
        selector:  0x0300,
        size:      2
      },

      saturation: {
        unit:      PROCESSING_UNIT,
        selector:  0x0700,
        size:      2
      },

      sharpness: {
        unit:      PROCESSING_UNIT,
        selector:  0x0800,
        size:      2
      },

      white_balance: {
        unit:      PROCESSING_UNIT,
        selector:  0x0A00,
        size:      2
      },

      auto_white_balance: {
        unit:      PROCESSING_UNIT,
        selector:  0x0B00,
        size:      1,
        type:      :bool
      },

      focus: {
        unit:      INPUT_TERMINAL,
        selector:  0x0600,
        size:      2
      },

      auto_focus: {
        unit:      INPUT_TERMINAL,
        selector:  0x0800,
        size:      1,
        type:      :bool
      },

      gain: {
        unit:      PROCESSING_UNIT,
        selector:  0x0400,
        size:      2
      },

      anti_flicker: {
        unit:      PROCESSING_UNIT,
        selector:  0x0500,
        size:      1,
        type:      :bool,
      },

      back_light_compensation: {
        unit:      PROCESSING_UNIT,
        selector:  0x0100,
        size:      2,
        type:      :bool
      },

      zoom: {
        unit:      INPUT_TERMINAL,
        selector:  0x0B00,
        size:      2
      }
    }

    attr_reader :vendor, :model, :dev
    # Public: Initializes a camera from a USB device.
    def initialize(device)
      @dev   = device
      @model = device.product

      case device.manufacturer
      when '?'
        @vendor = VENDORS[device.idVendor] || 'Unknown'
      else
        @vendor = device.manufacturer
      end
    end

    # Public: Sets properties from a hash
    def set(props)
      props.each do |prop, val|
        self.send(:"#{ prop }=", val)
      end
    end

    # Public: Represents the camera object as a string.
    def to_s
      "<Camera: #{ @model } (#{ @vendor })>"
    end

    # Public: Returns all the USB devices that belong to the camera device
    #         class.
    def self.all
      context.devices(bClass: 239).map { |d| Camera.new(d) }
    end

    def method_missing(method, *args)
      if method.to_s.end_with?('=')
        method = method.to_s.gsub(/=/,'').to_sym
        if CONTROLS[method][:type] == :bool
          set_bool_value(CONTROLS[method], *args)
        else
          set_value(CONTROLS[method], *args)
        end
      elsif method.to_s.end_with?('?')
        method = method.to_s.gsub(/\?/,'').to_sym
        super unless CONTROLS[method][:type] == :bool
        get_bool_value(CONTROLS[method])
      else
        super unless CONTROLS[method]
        if CONTROLS[method][:type] == :bool
          get_bool_value(CONTROLS[method])
        else
          get_value(CONTROLS[method])
        end
      end
    end

    #######
    private
    #######

    def get_bool_value(control)
      val    = get_value(control)[0]
      values = control[:values] || [0x01, 0x00]
      return val == values[0]
    end

    def get_value(control)
      @dev.open_interface(0) do |h|
        ret = h.control_transfer(bmRequestType: 0xA1,
                                 bRequest: 0x81,
                                 wValue: control[:selector],
                                 wIndex: control[:unit],
                                 dataIn: control[:size])
        ret.unpack("C")
      end
    end

    def set_bool_value(control, val)
      idx    = (val && 0) || 1
      values = control[:values] || [0x01, 0x00]
      set_value(control, values[idx])
    end

    def set_value(control, val)
      @dev.open_interface(0) do |h|
        h.control_transfer(bmRequestType: 0x21,
                           bRequest: 0x01,
                           wValue: control[:selector],
                           wIndex: control[:unit],
                           dataOut: [val].pack("C"))
      end
    end

    # Private: Instantiates a USB context over which we work with.
    def self.context
      @@context ||= LIBUSB::Context.new
    end
  end # Camera

end # Theia
