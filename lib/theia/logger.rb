module Theia

  # Public: Instantiates a Log4r and memoizes it
  def self.logger
    @logger ||= begin
      logger = Log4r::Logger.new('Theia')

      outputter           = Log4r::UniqueOutputter.new('stdout')
      outputter.formatter = Log4r::PatternFormatter.new(pattern: '%l - %x - %m')

      logger.add(outputter)

      logger
    end
  end

end # Theia
