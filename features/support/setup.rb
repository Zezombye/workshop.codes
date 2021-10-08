require 'factory_bot'
require 'cucumber'

# Enable use of factory methods without needing to prefix FactoryBot in step definitions
World(FactoryBot::Syntax::Methods)


Capybara.javascript_driver = :selenium_headless

# Set the global random seed for reproducible test runs
AfterConfiguration do |config|
  $seed = ENV['SEED'].present? ? ENV['SEED'].to_i : config.seed
  Kernel.srand $seed
  puts "Setting global random seed to #{ $seed }"
end

# Report the seed after run, and decouple RNG to maintain test independence
at_exit do
  Kernel.srand
  puts "Global random seed was #{ $seed }"
end
