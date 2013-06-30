web: bundle exec unicorn -p $PORT -c ./config/unicorn.rb
worker: env QUEUES=racetipper VERBOSE=1 bundle exec rake resque:work