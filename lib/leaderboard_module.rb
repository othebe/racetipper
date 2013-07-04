module LeaderboardModule
	require_dependency 'cache_module'
	
	#Title:			get_competition_stage_leaderboard
	#Description:	Returns a sorted leaderboard for this competition stage
	#Params:		competition_id - ID of competition
	#				group_type - stage/race
	#				group_id - ID of stage/race
	def self.get_competition_stage_leaderboard(competition_id, stage_id, regenerate=false)
		cache_name = CacheModule::get_cache_name(
			CacheModule::CACHE_TYPE[:LEADERBOARD], 
			{:competition_id=>competition_id, :group_type=>'stage', :group_id=>stage_id}
		)
		leaderboard_with_gap = CacheModule::get(cache_name)
		
		#If not regenerating leaderboard, return cached data
		return leaderboard_with_gap if (!regenerate)
		
		if (regenerate)
			tip_conditions = {:competition_id=>competition_id, :stage_id=>stage_id}
			tips = CompetitionTip.where(tip_conditions)
			
			results = Result.get_results('stage', stage_id, {:index_by_rider=>1}, true)
			
			leaderboard_with_gap = self.combine_leaderboard_tip_results(results, tips)
			
			#Store leaderboard in cache
			CacheModule::set(leaderboard_with_gap, cache_name)
			
			#Index leaderboard by user
			user_indexed_leaderboard_cache_name = CacheModule::get_cache_name(
				CacheModule::CACHE_TYPE[:LEADERBOARD_BY_USER],
				{:competition_id=>competition_id, :group_type=>'stage', :group_id=>stage_id}
			)
			CacheModule::set(self.index_leaderboard_by_user(leaderboard_with_gap), user_indexed_leaderboard_cache_name)
		end
		
		return leaderboard_with_gap
	end
	
	#Title:			get_cumulative_competition_stage_leaderboard
	#Description:	Gets the cumulative leaderboard for a given array of stages in a competition
	#Note:			Individual stage leaderboards will need to be calculated prior to this. Function will NOT regenerate that.
	def self.get_cumulative_competition_stage_leaderboard(competition_id, stages=[], regenerate=false)
		cache_name = CacheModule::get_cache_name(
			CacheModule::CACHE_TYPE[:LEADERBOARD_CUMULATIVE],
			{:competition_id=>competition_id, :stages=>stages}
		)
		leaderboard = CacheModule::get(cache_name)
		
		return leaderboard if (!regenerate)
		
		if (regenerate)
			unranked_cumulative_leaderboard = {}
			stages.each do |stage_id|
				self.get_competition_stage_leaderboard(competition_id, stage_id)
				
				#Get user indexed leaderboard
				user_indexed_leaderboard_cache_name = CacheModule::get_cache_name(
					CacheModule::CACHE_TYPE[:LEADERBOARD_BY_USER],
					{:competition_id=>competition_id, :group_type=>'stage', :group_id=>stage_id}
				)
				leaderboard = CacheModule::get(user_indexed_leaderboard_cache_name)
				next if (leaderboard.nil?)

				unranked_cumulative_leaderboard = self.combine_stage_leaderboards(unranked_cumulative_leaderboard, leaderboard)
			end
			
			#Add rank, formatted times, formatted gaps etc
			leaderboard = self.format_leaderboard(unranked_cumulative_leaderboard, competition_id, nil, 0, stages)

			CacheModule::set(leaderboard, cache_name)
		end
		
		return leaderboard
	end
	
	#Title:			get_competition_race_leaderboard
	#Description:	Gets the cumulative leaderboard for all stages in a competition
	#Params:		competition_id - Competition ID
	#				regenerate - Regenerate caches
	def self.get_competition_race_leaderboard(competition_id, regenerate=false)
		competition = Competition.find_by_id(competition_id)
		
		leaderboard = nil
		
		#Stages in race
		race_stages = []
		stages = Stage.where('stages.race_id=?', competition.race_id).order('starts_on ASC')
		stages.each {|stage| race_stages.push(stage.id) if (!Result.where({:season_stage_id=>stage.id, :status=>STATUS[:ACTIVE]}).first.nil?)}

		return self.get_cumulative_competition_stage_leaderboard(competition_id, race_stages, regenerate)
	end
	
	#Title:			get_global_stage_leaderboard
	#Description:	Get global leaderboard for a stage
	#Params:		stage_id - Stage ID
	#				scope - SCOPE
	def self.get_global_stage_leaderboard(stage_id, scope, regenerate=false)
		cache_name = CacheModule::get_cache_name(
			CacheModule::CACHE_TYPE[:GLOBAL_LEADERBOARD],
			{:group_type=>'stage', :group_id=>stage_id, :scope=>scope}
		)
		leaderboard = CacheModule::get(cache_name)
		
		#If not regenerating leaderboard, return cached data
		return leaderboard if (!regenerate)
		
		#Regenerate leaderboard
		if (regenerate)
			stage = Stage.find_by_id(stage_id)
			race_id = stage.race_id
			tips = []
			participants = CompetitionParticipant.select('competition_id, user_id')
				.joins('INNER JOIN competitions ON (competition_participants.competition_id = competitions.id)')
				.where('competitions.race_id = ? AND competitions.scope = ? AND competition_participants.is_primary = ? AND competition_participants.status = ? AND competitions.status <> ?', 
					race_id, scope, true, STATUS[:ACTIVE], STATUS[:DELETED])
			participants.each do |participant|
				tip = CompetitionTip.where({:competition_participant_id=>participant.user_id, :competition_id=>participant.competition_id, :stage_id=>stage.id}).first
				tips.push(tip)
			end

			results = Result.get_results('stage', stage_id, {:index_by_rider=>1}, true)
			
			leaderboard = self.combine_leaderboard_tip_results(results, tips)
			
			#Store leaderboard in cache
			CacheModule::set(leaderboard, cache_name)
			
			#Index leaderboard by user
			user_indexed_leaderboard_cache_name = CacheModule::get_cache_name(
				CacheModule::CACHE_TYPE[:GLOBAL_LEADERBOARD_BY_USER],
				{:group_type=>'stage', :group_id=>stage_id, :scope=>scope}
			)
			CacheModule::set(self.index_leaderboard_by_user(leaderboard), user_indexed_leaderboard_cache_name)
		end
		
		return leaderboard
	end
	
	#Title:			get_cumulative_global_stage_leaderboard
	#Description:	Gets the cumulative global leaderboard for a given array of stages in a race
	#Note:			Individual stage leaderboards will need to be calculated prior to this. Function will NOT regenerate that.
	def self.get_cumulative_global_stage_leaderboard(stages, scope, regenerate=false)
		return if stages.nil?
		
		cache_name = CacheModule::get_cache_name(
			CacheModule::CACHE_TYPE[:GLOBAL_LEADERBOARD_CUMULATIVE],
			{:stages=>stages, :scope=>scope}
		)
		leaderboard = CacheModule::get(cache_name)
		
		return leaderboard if (!regenerate)
		
		if (regenerate)
			stage = Stage.find_by_id(stages.first)
			
			unranked_cumulative_leaderboard = {}
			stages.each do |stage_id|
				self.get_global_stage_leaderboard(stage_id, scope)
				
				#Get user indexed leaderboard
				user_indexed_leaderboard_cache_name = CacheModule::get_cache_name(
					CacheModule::CACHE_TYPE[:GLOBAL_LEADERBOARD_BY_USER],
					{:group_type=>'stage', :group_id=>stage_id, :scope=>scope}
				)
				leaderboard = CacheModule::get(user_indexed_leaderboard_cache_name)
				next if (leaderboard.nil?)

				unranked_cumulative_leaderboard = self.combine_stage_leaderboards(unranked_cumulative_leaderboard, leaderboard)
			end
			
			#Add rank, formatted times, formatted gaps etc
			leaderboard = self.format_leaderboard(unranked_cumulative_leaderboard, nil, stage.race_id, scope, stages)
			
			CacheModule::set(leaderboard, cache_name)
		end
		
		return leaderboard
	end
	
	#Title:			get_global_race_leaderboard
	#Description:	Gets the cumulative leaderboard for all stages in a race
	#Params:		race_id - Competition ID
	#				scope - COMPETITION_SCOPE
	#				regenerate - Regenerate caches
	def self.get_global_race_leaderboard(race_id, scope, regenerate=false)
		leaderboard = nil
		
		#Stages in race
		race_stages = []
		stages = Stage.where('stages.race_id=?', race_id).order('starts_on ASC')
		stages.each {|stage| race_stages.push(stage.id) if (!Result.where({:season_stage_id=>stage.id, :status=>STATUS[:ACTIVE]}).first.nil?)}

		return self.get_cumulative_global_stage_leaderboard(race_stages, scope, regenerate)
	end
	
	#Title:			combine_leaderboard_tip_results
	#Description:	Combines tips and results to get leaderboard data
	#Params:		results - Results
	#				tips - Tips
	def self.combine_leaderboard_tip_results(results, tips)
		cached_users = {}
		cached_riders = {}
		cached_result = Result.where({:race_id=>tips.first.race_id})
		
		user_scores = {}
		tips.each do |tip|
			#Account for default riders
			if (tip.default_rider_id.nil?)
				rider_id = tip.rider_id
			else
				rider_id = tip.default_rider_id || tip.rider_id
			end
			
			stage_id = tip.stage_id
			user_id = tip.competition_participant_id
			
			user = cached_users[user_id] || User.find_by_id(user_id)
			username = user.display_name
			username = (user.firstname+' '+user.lastname).strip if (username.nil? || username.empty?)

			user_score = user_scores[user_id] || Hash.new
			user_score[:tip] ||= Array.new
			user_score[:user_id] = user_id
			user_score[:username] = username
			user_score[:is_default] = !tip.default_rider_id.nil?
			user_score[:competition_id] = tip.competition_id
			user_score[:time] ||= 0
			user_score[:kom] ||= 0
			user_score[:sprint] ||= 0
			
			#Original rider
			user_score[:original_rider] = nil
			if (user_score[:is_default])
				original_rider = cached_riders[tip.rider_id] || Rider.find_by_id(tip.rider_id)
				cached_riders[tip.rider_id] = original_rider if (cached_riders[tip.rider_id].nil?)
				user_score[:original_rider] = nil
				
				#Get original rider only if it exists
				if (!original_rider.nil?)
					result = cached_result.where({:rider_id=>original_rider.id, :season_stage_id=>tip.stage_id}).first
					user_score[:original_rider] = {
						:id => original_rider.id,
						:name => original_rider.name,
						:reason => Result.rider_status_to_str(result.rider_status)
					} if (!result.nil?)
				end
				
				#No original rider was chosen
				user_score[:original_rider] = {
					:id => nil,
					:name => nil,
					:reason => 'No rider chosen'
				} if (user_score[:original_rider].nil?)
			end

			rider = cached_riders[rider_id] || Rider.find_by_id(rider_id)
			cached_riders[tip.rider_id] = original_rider if (cached_riders[tip.rider_id].nil?)
			
			#Nil rider if no rider chosen, or stage results haven't been released yet
			if (rider_id.nil? || results[rider_id].nil? || results[rider_id][:stages][stage_id].nil?)
				user_score[:tip].push({:id=>nil, :name=>'TBA'})
				user_scores[user_id] = user_score
				next
			#Record user tip
			else
				user_score[:tip].push({:id=>rider_id, :name=>rider.name})
				user_scores[user_id] = user_score
			end
				
			#Get tip data from results
			#Cumulate times
			if (user_score[:time].nil?)
				user_score[:time] = results[rider_id][:stages][stage_id][:time] - results[rider_id][:stages][stage_id][:bonus_time]
			else 
				user_score[:time] += results[rider_id][:stages][stage_id][:time] - results[rider_id][:stages][stage_id][:bonus_time]
			end
			
			#Formatted time
			user_score[:formatted_time] = self.format_time(user_score[:time])
			
			#Cumulate points
			if (user_score[:points].nil?)
				user_score[:points] = results[rider_id][:stages][stage_id][:points]
			else 
				user_score[:points] += results[rider_id][:stages][stage_id][:points]
			end
			
			#Cumulate KOM points
			if (user_score[:kom].nil?)
				user_score[:kom] = results[rider_id][:stages][stage_id][:kom_points]
			else 
				user_score[:kom] += results[rider_id][:stages][stage_id][:kom_points]
			end
			
			#Cumulate sprint points
			if (user_score[:sprint].nil?)
				user_score[:sprint] = results[rider_id][:stages][stage_id][:sprint_points]
			else 
				user_score[:sprint] += results[rider_id][:stages][stage_id][:sprint_points]
			end
			
			#Consider rank if sorting by rank
			user_score[:rank] = results[rider_id][:stages][stage_id][:rank]
			
			user_scores[user_id] = user_score
		end
		
		leaderboard = user_scores.sort_by {|user_id, data| data[:rank]}
		
		#Get gap times and user rank
		leaderboard_with_gap = []
		base_time = base_rank = nil
		rank = ndx = gap = 0
		leaderboard.each do |entry|
			ndx += 1
			gap_formatted = nil
			
			if (base_rank.nil? || (entry[1][:rank] > base_rank))
				rank = ndx
				base_rank = entry[1][:rank]
			end
		
			gap_formatted = self.format_time(gap) if (ndx > 1)

			entry[1][:formatted_gap] = gap_formatted
			entry[1][:rank] = rank
			leaderboard_with_gap.push(entry[1])
		end

		return leaderboard_with_gap
	end
	
	#Title:			combine_stage_leaderboards
	#Description:	Accumulate user indexed leaderboards across individual leaderboards
	#Params:		cumulative_leaderboard - User indexed hash storing cumulative data
	#				leaderboard_data - Data to add to cumulative_leaderboard
	def self.combine_stage_leaderboards(cumulative_leaderboard, leaderboard_data=[])
		leaderboard_data.each do |uid, data|	
			#First entry
			if (cumulative_leaderboard[uid].nil?)
				cumulative_leaderboard[uid] = data
			#Cumulate
			else
				user_data = cumulative_leaderboard[uid]
				user_data[:time] += data[:time]
				user_data[:kom] += data[:kom]
				user_data[:sprint] += data[:sprint]
				
				cumulative_leaderboard[uid] = user_data
			end
		end
		
		return cumulative_leaderboard
	end
	
	#Title:			index_leaderboard_by_user
	#Description:	Index a leaderboard according to user
	#Params:		leaderboard - Leaderboard to be indexed
	def self.index_leaderboard_by_user(leaderboard)
		indexed_leaderboard = {}
		leaderboard.each {|data| indexed_leaderboard[data[:user_id]] = data}
		
		return indexed_leaderboard
	end
	
	#Title:			score_leaderboard
	#Description:	Adds a :sort_score to every entry in the leaderboard
	#Params:		leaderboard[uid] = data
	#				competition_id - Competition ID (nil for global competition)
	#				race_id - Race the competition is associated with. (Req for global competition)
	def self.score_leaderboard(leaderboard, competition_id, race_id, scope, allowed_stages=[])
		is_global = competition_id.nil?
		
		#Get stages in this race
		if (!is_global)
			#Get race ID		
			competition = Competition.find_by_id(competition_id)
			race_id = competition.race_id
		end
		stages = Stage.where({:id=>allowed_stages, :race_id=>race_id, :status=>STATUS[:ACTIVE]}).order('starts_on ASC')
		
		#Cache the stage results locally
		cached_stage_results = {}
		stages.each do |stage| 
			next if (Result.where({:season_stage_id=>stage.id, :status=>STATUS[:ACTIVE]}).first.nil?)
			
			#Get global rank data
			if (is_global)
				user_indexed_leaderboard_cache_name = CacheModule::get_cache_name(
					CacheModule::CACHE_TYPE[:GLOBAL_LEADERBOARD_BY_USER],
					{:group_type=>'stage', :group_id=>stage.id, :scope=>scope}
				)
			#Get competition rank data
			else
				user_indexed_leaderboard_cache_name = CacheModule::get_cache_name(
					CacheModule::CACHE_TYPE[:LEADERBOARD_BY_USER],
					{:competition_id=>competition_id, :group_type=>'stage', :group_id=>stage.id}
				)
			end
			leaderboard_data = CacheModule::get(user_indexed_leaderboard_cache_name)
			cached_stage_results[stage.id] = leaderboard_data
		end
		
		#Generate a user score for the rankings
		leaderboard.each do |uid, data|
			user_id = data[:user_id]
			
			#Get primary competition for global race
			if (is_global)
				competition = CompetitionParticipant.get_primary_competition(user_id, race_id, scope)
				competition_id = competition.competition_id
			end
			
			#Get num participants
			if (is_global)
				num_participants = CompetitionParticipant
					.joins(:competition)
					.where('competitions.race_id=? AND competition_participants.is_primary=? AND competition_participants.status=?',
						race_id, true, STATUS[:ACTIVE])
					.count
			else
				num_participants = CompetitionParticipant.where({:competition_id=>competition_id, :status=>STATUS[:ACTIVE]}).count
			end
			
			#Get rankings in recent stages
			rankings = []
			stages.each do |stage| 
				leaderboard_data = cached_stage_results[stage.id]
				
				next if (leaderboard_data.nil?)
				
				#Add to rankings
				rank = leaderboard_data[user_id][:rank]
				rankings.push(rank)
			end

			################
			#Ranking scores:
			
			#Time provides the base score
			data[:sort_score] = data[:time]
			
			#Use the average of all previous rankings
			average_rank = 0
			if (!rankings.empty?)
				rankings.each {|rank| average_rank += rank}
				average_rank = (average_rank)/(rankings.length)
				data[:sort_score] -= (num_participants-average_rank)*0.1/(num_participants)
			end
			
			#Use lowest ranking on most recent stage
			if (!rankings.empty?)
				data[:sort_score] -= (num_participants-rankings.last)*0.01/(num_participants)
			end
		end
		
		return leaderboard
	end
	
	#Title:			format_leaderboard
	#Description:	Format a leaderboard by adding rank, formatting time, gap time etc
	#Params:		leaderboard[uid] = data
	#				competition_id - Competition ID (nil for global competition)
	#				race_id - Race the competition is associated with. (Req for global competition)
	#				scope - COMPETITION_SCOPE
	#				stages - Limit scoring to these stage IDs (Array)
	def self.format_leaderboard(leaderboard, competition_id, race_id, scope=0, stages)
		formatted_leaderboard = []
		
		return formatted_leaderboard if (leaderboard.empty?)
		
		#Add sorting score for ranking
		leaderboard = self.score_leaderboard(leaderboard, competition_id, race_id, scope, stages)
		
		#Sort leaderboard
		leaderboard = leaderboard.sort_by {|user_id, data| data[:sort_score]}
		
		#Add gaps and ranks
		base_time = leaderboard[0][1][:time]
		base_rank = nil
		rank = ndx = gap = 0
		
		leaderboard.each do |uid, data|
			ndx += 1
			
			#Format gap
			gap = (data[:time] - base_time)
			data[:formatted_gap] = (gap>0)?self.format_time(gap):nil
			
			#Format time
			data[:formatted_time] = self.format_time(data[:time])
			
			#Rank
			if (base_rank.nil? || (data[:sort_score] > base_rank))
				rank = ndx
				base_rank = data[:sort_score]
			end
			data[:rank] = rank
			
			formatted_leaderboard.push(data)
		end
		
		return formatted_leaderboard
	end
	
	#Title:			get_top
	#Description:	Get top scorers in the leaderboard
	def self.get_top(data_sym, count, data)
		return [] if data.nil?
		top = []
		added_ndx = []
		
		for i in 1..count
			max = nil
			current = nil
			ndx = 0
			
			data.each do |d|
				next if (d[data_sym].nil?)
				if (max.nil? || d[data_sym]>max)
					if (!added_ndx.include?(ndx))
						max = d[data_sym]
						current = d
						added_ndx.push(ndx)
					end
				end
				ndx += 1
			end
			
			top.push(current)
		end
		
		return top
	end
	
	#Title:			format_time
	#Description:	Format time by days/HMS
	def self.format_time(time_in_sec)
		if (time_in_sec >= 86400)
			days = (Time.at(time_in_sec).gmtime.strftime('%-d').to_i - 1).to_s
			return Time.at(time_in_sec).gmtime.strftime(days+' day(s), %R:%S')
		else
			return Time.at(time_in_sec).gmtime.strftime('%R:%S')
		end
	end
end