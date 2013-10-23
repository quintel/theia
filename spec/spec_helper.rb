require 'theia'
require 'timeout'

require_relative 'support/video_expectation'
require_relative 'support/game_spec'
require_relative 'support/lib/theia/mode/game_test'

include Theia

# copy all the fixtures to a temp path
require 'support/capture'
require 'support/integration'

# Overwrite to use temp fixtures path
module Theia
  def self.data_path
    File.expand_path("../tmp", __FILE__)
  end

  def self.refresh_fixtures!
    FileUtils.cp_r('spec/fixtures/.', Theia.data_path)
  end

end

Theia.refresh_fixtures!

# Shut up Wesley!
Theia.logger.level = Log4r::OFF

RSpec.configure do |config|
  # Use only the new "expect" syntax.
  config.expect_with(:rspec) { |c| c.syntax = :expect }

  # Tries to find examples / groups with the focus tag, and runs them. If no
  # examples are focues, run everything. Prevents the need to specify
  # `--tag focus` when you only want to run certain examples.
  config.filter_run(focus: true)
  config.run_all_when_everything_filtered = true

  # Allow adding examples to a filter group with only a symbol.
  config.treat_symbols_as_metadata_keys_with_true_values = true

  config.include(Theia::Spec::IntegrationHelper, integration: true)
end
