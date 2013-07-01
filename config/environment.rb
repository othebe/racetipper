# Load the rails application
require File.expand_path('../application', __FILE__)

# Initialize the rails application
Racetipper::Application.initialize!

#Set debug levels to warn
Rails.logger.level = 2
