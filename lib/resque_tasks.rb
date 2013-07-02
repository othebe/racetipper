class ResqueTasks
	@queue = :racetipper
	
	#Resque tasks
	RESQUE_TASK = {
		:CRON_LEADERBOARD => 'CRON_LEADERBOARD',
		:CHECK_DEFAULT_RIDERS_FOR_STAGE => 'CHECK_DEFAULT_RIDERS_FOR_STAGE',
		:GENERATE_RESULTS_FOR_STAGE => 'GENERATE_RESULTS_FOR_STAGE',
		:GENERATE_GLOBAL_LEADERBOARD => 'GENERATE_GLOBAL_LEADERBOARD',
		:GENERATE_COMPETITION_LEADERBOARDS => 'GENERATE_COMPETITION_LEADERBOARDS',
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
			when RESQUE_TASK[:GENERATE_COMPETITION_LEADERBOARDS]
				self.generate_competition_leaderboards(data)
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
			#Global leaderboard
			COMPETITION_SCOPE.each do |k, scope|
				stages = Stage.where({:race_id=>race.id, :status=>STATUS[:ACTIVE]})
				#Stage leaderboard
				stages.each {|stage| self.q_generate_global_leaderboard('stage', stage.id, scope)}
				
				#Race leaderboard
				self.q_generate_global_leaderboard('race', race.id, scope)
			end
			
			#Competition stage leaderboards
			stages = Stage.where({:race_id=>race.id, :status=>STATUS[:ACTIVE]})
			stages.each {|stage| self.q_generate_competition_leaderboards('stage', stage.id, true)}
			
			#Competition race leaderboard
			self.q_generate_competition_leaderboards('race', race.id)
		end
		
		#Loop back to self
		self.q_cron_leaderboard
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
		
		#Worker leaderboard generation
		COMPETITION_SCOPE.each do |k, scope|
			ResqueTasks::q_generate_global_leaderboard('stage', stage_id, scope)
			ResqueTasks::q_generate_global_leaderboard('race', race_id, scope)
		end
		ResqueTasks::q_generate_competition_leaderboards('stage', stage_id)
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
	end
	
	#########################
	##### Global leaderboards
	
	#Title:			q_generate_global_leaderboard
	#Description:	Adds request to generate global leaderboard
	#Params:		group_type - race / stage
	#				group_id - Race or stage ID
	#				scope - COMPETITION_SCOPE constants
	def self.q_generate_global_leaderboard(group_type, group_id, scope)
		Resque.enqueue(self, {
			:type => RESQUE_TASK[:GENERATE_GLOBAL_LEADERBOARD],
			:data => {
				:group_type => group_type,
				:group_id => group_id,
				:scope => scope
			}
		})
	end
	
	#Title:			generate_global_leaderboard
	#Description:	Generates global leaderboard
	#Params:		group_type - race / stage
	#				group_id - Race or stage ID
	#				scope - COMPETITION_SCOPE constants
	def self.generate_global_leaderboard(data)
		require_dependency 'leaderboard_module'
		LeaderboardModule::get_global_leaderboard(data['group_type'], data['group_id'], data['scope'], true)
	end
	
	##############################
	##### Competition leaderboards
	
	#Title:			q_generate_competition_leaderboards
	#Description:	Adds request to generate competition leaderboards
	#Params:		group_type - race / stage
	#				group_id - Race or stage ID
	#				stage_only - Ignore race leaderboard
	def self.q_generate_competition_leaderboards(group_type, group_id, stage_only=false)
		Resque.enqueue(self, {
			:type => RESQUE_TASK[:GENERATE_COMPETITION_LEADERBOARDS],
			:data => {
				:group_type => group_type,
				:group_id => group_id,
				:stage_only => stage_only
			}
		})
	end
	
	#Title:			generate_competition_leaderboards
	#Description:	Prepares request to generate leaderboards for all competitions by group ID and type
	#Params:		group_type - race / stage
	#				group_id - Race or stage ID
	def self.generate_competition_leaderboards(data)
		group_type = data['group_type']
		group_id = data['group_id']

		#Find race ID
		race_id = data['group_id']
		if (group_type == 'stage')
			stage = Stage.find_by_id(group_id)
			race_id = stage.race_id
		end
		
		#Generate leaderboards for all related competitions
		competitions = Competition.where({:race_id=>race_id})
		competitions.each do |competition|
			#Generate stage leaderboard
			if (group_type == 'stage')
				Resque.enqueue(self, {
					:type => RESQUE_TASK[:GENERATE_COMPETITION_LEADERBOARD],
					:data => {
						:competition_id => competition.id,
						:group_type => 'stage',
						:group_id => group_id
					}
				})
			end
			
			#Also regenerate race leaderboard
			Resque.enqueue(self, {
				:type => RESQUE_TASK[:GENERATE_COMPETITION_LEADERBOARD],
				:data => {
					:competition_id => competition.id,
					:group_type => 'race',
					:group_id => race_id
				}
			}) if (!data['stage_only'])
		end
	end
	
	#Title:			generate_competition_leaderboard
	#Description:	Generate competition leaderboard
	#Params:		competition_id - Competition ID
	#				group_type - race / stage
	#				group_id - Race or stage ID
	def self.generate_competition_leaderboard(data)
		require_dependency 'leaderboard_module'
		LeaderboardModule::get_leaderboard(data['competition_id'], data['group_type'], data['group_id'], 10, true)		
	end
end