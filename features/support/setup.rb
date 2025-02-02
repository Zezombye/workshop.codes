require 'factory_bot'
require 'cucumber'
require 'webdrivers'

# Enable use of factory methods without needing to prefix FactoryBot in step definitions
World(FactoryBot::Syntax::Methods)

# Enable mocking the OmniAuth flow
OmniAuth.config.test_mode = true

# HACK: EXTREMELY ugly
# Because Snap-packaged Firefox is sandboxed and cannot see into
# the /tmp directory, we need to make a clean tmp directory under the
# user's home to store the profiles

# Unfortunately, this means that the test runner must set the
# environment variable `TMPDIR` to `$HOME/tmp` manually, either by
# a bash command somewhat like the following:
# ```
# #!bin/bash
# TMPDIR=$HOME/tmp bundle exec rake cucumber`
# ```
# or otherwise

BeforeAll do
  Dir.mkdir(File.join(Dir.home, "tmp")) unless File.exist?(File.join(Dir.home, "tmp"))
end

AfterAll do
  FileUtils.remove_dir(File.join(Dir.home, "tmp"), true)
end

Capybara.javascript_driver = :selenium_headless

# Set the global random seed for reproducible test runs
InstallPlugin do |config, registry|
  $seed = ENV['SEED'].present? ? ENV['SEED'].to_i : config.seed
  Kernel.srand $seed
  puts "Setting global random seed to #{ $seed }"
end

# Set the random seed at the beginning of each scenario
# to avoid any potential interference from systems not under test
Before do
  Kernel.srand $seed
end

# Report the seed after run, and decouple RNG to maintain test independence
at_exit do
  Kernel.srand
  puts "Global random seed was #{ $seed }"
end
