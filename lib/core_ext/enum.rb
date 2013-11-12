class Enum
  def self.new(values = nil)
    enum = Class.new do
      unless values
        def self.const_missing(name)
          const_set(name, new(name))
        end
      end

      def initialize(name)
        @enum_name = name
      end

      def to_s
        "#{self.class}::#@enum_name"
      end
    end

    if values
      enum.instance_eval do
        values.each { |e| const_set(e, enum.new(e)) }
      end
    end

    enum
  end
end
