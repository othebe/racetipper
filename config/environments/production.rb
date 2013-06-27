Racetipper::Application.configure do
  # Settings specified here will take precedence over those in config/application.rb

  # Code is not reloaded between requests
  config.cache_classes = true

  # Full error reports are disabled and caching is turned on
  config.consider_all_requests_local       = false
  config.action_controller.perform_caching = true

  # Disable Rails's static asset server (Apache or nginx will already do this)
  config.serve_static_assets = false

  # Compress JavaScripts and CSS
  config.assets.compress = true

  # Don't fallback to assets pipeline if a precompiled asset is missed
  config.assets.compile = true

  # Generate digests for assets URLs
  config.assets.digest = true

  # Defaults to nil and saved in location specified by config.assets.prefix
  # config.assets.manifest = YOUR_PATH

  # Specifies the header that your server uses for sending files
  # config.action_dispatch.x_sendfile_header = "X-Sendfile" # for apache
  # config.action_dispatch.x_sendfile_header = 'X-Accel-Redirect' # for nginx

  # Force all access to the app over SSL, use Strict-Transport-Security, and use secure cookies.
  # config.force_ssl = true

  # See everything in the log (default is :info)
  # config.log_level = :debug

  # Prepend all log lines with the following tags
  # config.log_tags = [ :subdomain, :uuid ]

  # Use a different logger for distributed setups
  # config.logger = ActiveSupport::TaggedLogging.new(SyslogLogger.new)

  # Use a different cache store in production
  # config.cache_store = :mem_cache_store

  # Enable serving of images, stylesheets, and JavaScripts from an asset server
  # config.action_controller.asset_host = "http://assets.example.com"

  # Precompile additional assets (application.js, application.css, and all non-JS/CSS are already added)
  # config.assets.precompile += %w( search.js )

  # Disable delivery errors, bad email addresses will be ignored
  # config.action_mailer.raise_delivery_errors = false
  
    #Action mailer stuff
	config.action_mailer.delivery_method = :smtp
	config.action_mailer.smtp_settings = {
	  :address              => "smtp.gmail.com",
	  :port                 => 587,
	  :domain               => 'https://mail.google.com/a/cyclingtips.com.au',
	  :user_name            => 'editor@cyclingtips.com.au',
	  :password             => 'Australia2012',
	  :authentication       => 'plain',
	  :enable_starttls_auto => true  
	}

  # Enable threaded mode
  # config.threadsafe!

  # Enable locale fallbacks for I18n (makes lookups for any locale fall back to
  # the I18n.default_locale when a translation can not be found)
  config.i18n.fallbacks = true

  # Send deprecation notices to registered listeners
  config.active_support.deprecation = :notify

  # Log the query plan for queries taking more than this (works
  # with SQLite, MySQL, and PostgreSQL)
  # config.active_record.auto_explain_threshold_in_seconds = 0.5
end

#Constants
FACEBOOK_APP_ID = 536692469697929
FACEBOOK_APP_SECRET = '11bb95a12ff1ef93ad0ed3e6a44226a1'

#Bug notification email.
BUG_NOTIFY_LIST = 'othebe@gmail.com, tim.calkins@gmail.com'

#Cloudinary
Cloudinary.config do |config|
	config.cloud_name = 'racetipper'
	config.api_key = '354521382215813'
	config.api_secret = 'rWbmYgLsHoOGXJvgJT9WiHNpvf4'
	config.cdn_subdomain = true
end
CLOUDINARY_URL = 'cloudinary://354521382215813:rWbmYgLsHoOGXJvgJT9WiHNpvf4@racetipper'

#Ironworker
IRONWORKER_PROJECT_ID = '516968bc2267d85351001a8d'
IRONWORKER_TOKEN = 'sDMGz4n9RX85PZoi27Y4CuCHcNk'

#Redis
#ENV["REDISTOGO_URL"] = 'redis://redistogo:72db279f5fc11a9d974c7b19b1f6c5ce@dory.redistogo.com:10500'
ENV["REDISTOGO_URL"] = 'redis://app10583974:MQGZoLrEMhPFpRx3@pub-redis-19268.us-east-1-2.3.ec2.garantiadata.com:19268'
