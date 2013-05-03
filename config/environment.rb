# Load the rails application
require File.expand_path('../application', __FILE__)

# Initialize the rails application
Racetipper::Application.initialize!

#Set debug levels to info
Rails.logger.level = 0
