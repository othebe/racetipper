class ResqueTasks
	@queue = :racetipper
	
	#Resque tasks
	RESQUE_TASK = {
		:CRON_LEADERBOARD => 'CRON_LEADERBOARD',
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
	
	#############################
	# Cron                      #
	#############################
	
	#Title:			cron_leaderboard
	#Description:	Generate leaderboards for on-going races
	def self.cron_leaderboard
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