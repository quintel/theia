require "rspec/core/rake_task"


namespace :spec do
  RSpec::Core::RakeTask.new('video') do |t|
    t.verbose     = true
    t.rspec_opts  = "--tag @video"
  end
end

RSpec::Core::RakeTask.new('spec') do |t|
  t.verbose = true
end

