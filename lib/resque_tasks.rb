class ResqueTasks
	@queue = :racetipper
	
	#Resque tasks
	RESQUE_TASK = {
		:CRON_LEADERBOARD => 'CRON_LEADERBOARD',
		:CHECK_DEFAULT_RIDERS_FOR_STAGE => 'CHECK_DEFAULT_RIDERS_FOR_STAGE',
		:GENERATE_RESULTS_FOR_STAGE => 'GENERATE_RESULTS_FOR_STAGE',
		:GENERATE_GLOBAL_LEADERBOARD => 'GENERATE_GLOBAL_LEADERBOARD',
		:GENERATE_COMPETITION_LEADERBOARD => 'GENERATE_COMPETITION_LEADERBOARD',
	}
	
	#Title:			perform
	#Description:	Perform a resque task off the queue
	#Params:		task_data
	#					:type - 
	#					:data - Data hash
	def self.perform(task_data)
		task_type = task_data['type']
		data = task_data['data']
		
		puts "Starting: [#{task_type}]: " + data.to_s + Time.now.to_s
		
		case task_type
			when RESQUE_TASK[:CRON_LEADERBOARD]
				self.cron_leaderboard()
			when RESQUE_TASK[:CHECK_DEFAULT_RIDERS_FOR_STAGE]
				self.check_default_riders_for_stage(data)
			when RESQUE_TASK[:GENERATE_RESULTS_FOR_STAGE]
				self.generate_results_for_stage(data)
			when RESQUE_TASK[:GENERATE_GLOBAL_LEADERBOARD]
				self.generate_global_leaderboard(data)
			when RESQUE_TASK[:GENERATE_COMPETITION_LEADERBOARD]
				self.generate_competition_leaderboard(data)
		end
		
		puts "Ending: [#{task_type}]: " + data.to_s + Time.now.to_s
		return
	end
	
	#Title:			clear_pending
	#Description:	Clear pending tasks
	def self.clear_pending
		Resque.redis.del("queue:#{@queue}")
	end
	
	#############################
	# Cron                      #
	#############################
	
	#Title:			cron_leaderboard
	#Description:	Generate leaderboards for on-going races
	def self.cron_leaderboard
		return if (Resque.info[:pending] > 0)
		
		races = Race.where({:status=>STATUS[:ACTIVE], :is_complete=>false})
		races.each do |race|
			stages = Stage.where({:race_id=>race.id, :status=>STATUS[:ACTIVE]}).order('starts_on ASC')
			competitions = Competition.where({:race_id=>race.id})
			
			stages.each do |stage|
				next if (Result.where({:season_stage_id=>stage.id, :status=>STATUS[:ACTIVE]}).first.nil?)
				
				#Generate stage results
				self.q_generate_results_for_stage(stage.id)
				
				#Global leaderboard
				COMPETITION_SCOPE.each {|k, scope| self.q_generate_global_leaderboard(stage.id, scope)}
				
				#Competition leaderboards
				competitions.each {|competition| self.q_generate_competition_leaderboard(competition.id, stage.id)}
			end
		end
		
		#Loop back to self
		#self.q_cron_leaderboard
	end
	
	#Title:			q_cron_leaderboard
	#Description:	Adds cron-loop
	def self.q_cron_leaderboard
		Resque.enqueue(self, {
			:type => RESQUE_TASK[:CRON_LEADERBOARD],
			:data => {}
		})
	end
	
	#############################
	# Enqueue functions         #
	#############################
	
	##############################
	##### Default riders for stage
	##############################
	
	#Title:			q_check_default_riders_for_stage
	#Description:	Check if any tips for this stage need to be defaulted
	#Params:		stage_id
	def self.q_check_default_riders_for_stage(stage_id)
		Resque.enqueue(self, {
			:type => RESQUE_TASK[:CHECK_DEFAULT_RIDERS_FOR_STAGE],
			:data => {
				:stage_id => stage_id
			}
		})
	end
	
	#Title:			check_default_riders_for_stage
	#Description:	Check if any tips for this stage need to be defaulted
	#Params:		data:
	#					stage_id - Stage ID
	def self.check_default_riders_for_stage(data)
		stage_id = data['stage_id']
		
		#Check riders are valid in tips
		tips = CompetitionTip.where('stage_id = ? AND rider_id IS NOT NULL', stage_id)
		tips.each {|tip| tip.check_valid_rider}
		
		results = Result.where({:season_stage_id=>stage_id, :status=>STATUS[:ACTIVE]})
		
		#Check if any tips for this result need to be defaulted.
		results.each do |result|		
			result.check_valid_tips
		end
		
		#Mark stage as done
		stage = Stage.find_by_id(stage_id)
		stage.is_complete = true
		stage.save
		
		#Check if any races need to be marked as completed
		race_id = stage.race_id
		Race.check_completion_status(race_id)
		
		#Check if any competitions need to be marked as completed
		competitions = Competition.where('race_id = ? AND status <> ?', race_id, STATUS[:DELETED])
		competitions.each do |competition|
			competition.check_completion_status
		end
		
		#Clear results cache
		CacheModule::delete_results('stage', stage_id)
		CacheModule::delete_results('race', race_id)
		
		#Regenerate results cache
		self.q_generate_results_for_stage(stage_id)
		
		#Global leaderboard generation
		COMPETITION_SCOPE.each {|k, scope| self.q_generate_global_leaderboard(stage_id, scope)}
		
		competitions.each {|competition| self.q_generate_competition_leaderboard(competition.id, stage_id)}
	end
	
	#########################
	##### Race results
	#########################
	
	#Title:			q_generate_results_for_stage
	#Description:	Generate results for a stage
	#Params:		stage_id - Stage ID
	def self.q_generate_results_for_stage(stage_id)
		Resque.enqueue(self, {
			:type => RESQUE_TASK[:GENERATE_RESULTS_FOR_STAGE],
			:data => {
				:stage_id => stage_id
			}
		})
	end
	
	#Title:			generate_results_for_stage
	#Description:	Generate results for a stage and its race
	#Params:		data:
	#					stage_id - Stage ID
	def self.generate_results_for_stage(data)
		stage_id = data['stage_id']

		#Stage results
		stage = Stage.find_by_id(stage_id)
		return if (stage.nil?)
		Result.get_results('stage', stage_id, {}, true)
		
		#Race results
		race = Race.find_by_id(stage.race_id)
		return if (race.nil?)
		Result.get_results('race', race.id, {}, true)
		
		#Generate cumulative stage results
		stage_list = []
		stages = Stage
			.select(:id)
			.where('stages.race_id  = ? AND stages.starts_on <=? AND stages.status = ?', 
				stage.race_id, stage.starts_on, STATUS[:ACTIVE])
		stages.each do |stage|
			stage_list.push(stage.id) 
			Result.get_cumulative_stage_results(stage_list)
		end
	end
	
	#########################
	##### Global leaderboards
	
	#Title:			q_generate_global_leaderboard
	#Description:	Adds request to generate global leaderboard
	#Params:		group_type - race / stage
	#				group_id - Race or stage ID
	#				scope - COMPETITION_SCOPE constants
	def self.q_generate_global_leaderboard(stage_id, scope)
		Resque.enqueue(self, {
			:type => RESQUE_TASK[:GENERATE_GLOBAL_LEADERBOARD],
			:data => {
				:stage_id => stage_id,
				:scope => scope
			}
		})
	end
	
	#Title:			generate_global_leaderboard
	#Description:	Generates global leaderboard
	#Params:		stage_id - Stage ID
	#				scope - COMPETITION_SCOPE constants
	def self.generate_global_leaderboard(data)
		require_dependency 'leaderboard_module'
		
		stage_id = data['stage_id']
		scope = data['scope']
		
		#Individual
		LeaderboardModule::get_global_stage_leaderboard(stage_id, scope, true)
		
		#Cumulative
		stage_list = []
		stage = Stage.find_by_id(stage_id)
		stages = Stage.where('stages.race_id=? AND stages.status=? AND stages.starts_on <=?', stage.race_id, STATUS[:ACTIVE], stage.starts_on).order('starts_on ASC')
		stages.each {|s| stage_list.push(s.id)}
		
		LeaderboardModule::get_cumulative_global_stage_leaderboard(stage_list, scope, true)
	end
	
	##############################
	##### Competition leaderboards
	
	#Title:			q_generate_competition_leaderboards
	#Description:	Adds request to generate competition leaderboards
	#Params:		competition_id - Competition ID
	#				stage_id - Stage ID
	def self.q_generate_competition_leaderboard(competition_id, stage_id)
		Resque.enqueue(self, {
			:type => RESQUE_TASK[:GENERATE_COMPETITION_LEADERBOARD],
			:data => {
				:competition_id => competition_id,
				:stage_id => stage_id
			}
		})
	end
	
	#Title:			generate_competition_leaderboard
	#Description:	Generate competition leaderboard
	#Params:		competition_id - Competition ID
	#				group_type - race / stage
	#				group_id - Race or stage ID
	def self.generate_competition_leaderboard(data)
		require_dependency 'leaderboard_module'
		
		competition_id = data['competition_id']
		stage_id = data['stage_id']
		stage = Stage.find_by_id(stage_id)
		
		LeaderboardModule::get_competition_stage_leaderboard(competition_id, stage_id, true)
		
		#Get leaderboard for this stage
		LeaderboardModule::get_competition_stage_leaderboard(competition_id, stage_id, true)

		#Also prepare cumulative stage results
		stage_list = []
		stages = Stage
			.select(:id)
			.where('stages.race_id  = ? AND stages.starts_on <=? AND stages.status = ?', 
				stage.race_id, stage.starts_on, STATUS[:ACTIVE]
			)
		stages.each do |stage|
			stage_list.push(stage.id)
			LeaderboardModule::get_cumulative_competition_stage_leaderboard(competition_id, stage_list, true)
		end
	end
end