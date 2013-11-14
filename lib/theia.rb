require 'eventmachine'
require 'log4r'
require 'spyglass'
require 'yajl/json_gem'
require 'yaml'
require 'fileutils'

require_relative 'core_ext/log4r/outputter/uniqueoutputter'
require_relative 'core_ext/array'

require_relative 'theia/camera'
require_relative 'theia/helpers'
require_relative 'theia/occurrence'
require_relative 'theia/tracker'
require_relative 'theia/capture'
require_relative 'theia/logger'
require_relative 'theia/map'
require_relative 'theia/mode'
require_relative 'theia/piece'

include Spyglass

module Theia
end
