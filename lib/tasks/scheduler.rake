desc 'CRON: Generate leaderboard'
task :cron_leaderboard => :environment do
	puts 'CRON: Starting cron_leaderboard'
	ResqueTasks::cron_leaderboard
end
