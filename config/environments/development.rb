Racetipper::Application.configure do
  # Settings specified here will take precedence over those in config/application.rb

  # In the development environment your application's code is reloaded on
  # every request. This slows down response time but is perfect for development
  # since you don't have to restart the web server when you make code changes.
  config.cache_classes = false

  # Log error messages when you accidentally call methods on nil.
  config.whiny_nils = true

  # Show full error reports and disable caching
  config.consider_all_requests_local       = true
  config.action_controller.perform_caching = true

  # Don't care if the mailer can't send
  config.action_mailer.raise_delivery_errors = false
  #Action mailer stuff
	config.action_mailer.delivery_method = :smtp
	config.action_mailer.smtp_settings = {
	  :address              => "smtp.gmail.com",
	  :port                 => 587,
	  :domain               => 'racetipper.herokuapp.com',
	  :user_name            => 'ozzy@gushcloud.com',
	  :password             => 'stupify12',
	  :authentication       => 'plain',
	  :enable_starttls_auto => true  
	}

  # Print deprecation notices to the Rails logger
  config.active_support.deprecation = :log

  # Only use best-standards-support built into browsers
  config.action_dispatch.best_standards_support = :builtin

  # Raise exception on mass assignment protection for Active Record models
  config.active_record.mass_assignment_sanitizer = :strict

  # Log the query plan for queries taking more than this (works
  # with SQLite, MySQL, and PostgreSQL)
  config.active_record.auto_explain_threshold_in_seconds = 0.5

  # Do not compress assets
  config.assets.compress = false

  # Expands the lines which load the assets
  config.assets.debug = true
end

#Constants
FACEBOOK_APP_ID = 346523722129876
FACEBOOK_APP_SECRET = '133c9fcc00af63bf177b2f92febe65ff'

#Bug notification email.
BUG_NOTIFY_LIST = 'othebe@gmail.com'

#Cloudinary
Cloudinary.config do |config|
	config.cloud_name = 'dmlhr4mky'
	config.api_key = '189312664843342'
	config.api_secret = 'G8jADd0bciw0VSqzh5Y2FE7OPh4'
	config.cdn_subdomain = true
end
CLOUDINARY_URL = 'cloudinary://189312664843342:G8jADd0bciw0VSqzh5Y2FE7OPh4@dmlhr4mky'

#Ironworker
IRONWORKER_PROJECT_ID = '516968bc2267d85351001a8d'
IRONWORKER_TOKEN = 'sDMGz4n9RX85PZoi27Y4CuCHcNk'
