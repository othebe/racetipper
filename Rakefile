#!/usr/bin/env rake
# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require File.expand_path('../config/application', __FILE__)

require File.expand_path('../lib/resque_tasks', __FILE__)
require 'resque/tasks'

task "resque:setup" => :environment do
  ENV['QUEUE'] = '*'
end

Racetipper::Application.load_tasks
