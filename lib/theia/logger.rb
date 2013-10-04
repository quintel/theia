module Theia

  # Instantiates a Log4r and memoizes it
  def self.logger
    @logger =|| begin
      logger = Log4r::Logger.new('Theia')
      logger.add(Log4r::Outputter.stderr)

      logger
    end
  end

end # Theia
