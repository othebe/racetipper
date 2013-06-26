module LeaderboardModule
	require_dependency 'cache_module'
	
	#Title:			get_leaderboard
	#Description:	Returns a sorted leaderboard for this competition
	#Params:		competition_id - ID of competition
	#				group_type - stage/race
	#				group_id - ID of stage/race
	#				limit - How many entries in the leaderboard to show
	def self.get_leaderboard(competition_id, group_type, group_id, limit=10)
		cache_name = CacheModule::get_cache_name(
			CacheModule::CACHE_TYPE[:LEADERBOARD], 
			{:competition_id=>competition_id, :group_type=>group_type, :group_id=>group_id}
		)
		leaderboard_with_gap = CacheModule::get(cache_name)
		if (leaderboard_with_gap.nil?)
			tip_conditions = {:competition_id=>competition_id}
			tip_conditions[:stage_id] = group_id if (group_type=='stage')
			
			results = Result.get_results(group_type, group_id, {:index_by_rider=>1})
			tips = CompetitionTip.where(tip_conditions)
			
			if (group_type=='stage')
				leaderboard_with_gap = self.combine_leaderboard_tip_results(results, tips, true)
			else
				leaderboard_with_gap = self.combine_leaderboard_tip_results(results, tips, false)
			end
			
			CacheModule::set(leaderboard_with_gap, cache_name, CacheModule::CACHE_TTL[:DAY])
		end
		
		return leaderboard_with_gap
	end
	
	#Title:			get_global_leaderboard
	#Description:	Get global leaderboard
	#Params:		group_type - race/stage
	#				group_id - Race/stage ID
	#				scope - SCOPE
	def self.get_global_leaderboard(group_type, group_id, scope)
		cache_name = CacheModule::get_cache_name(
			CacheModule::CACHE_TYPE[:GLOBAL_LEADERBOARD],
			{:group_type=>group_type, :group_id=>group_id, :scope=>scope}
		)
		leaderboard = CacheModule::get(cache_name)
		if (leaderboard.nil?)
			if (group_type=='race')
				race_id = group_id
			else
				stage = Stage.find_by_id(group_id)
				race_id = stage.race_id
			end
			results = Result.get_results(group_type, group_id, {:index_by_rider=>1})
			tips = CompetitionTip
					.select('competition_tips.*').uniq
					.joins('INNER JOIN competition_participants ON competition_participants.competition_id=competition_tips.competition_id')
					.joins('INNER JOIN competitions ON competitions.id=competition_participants.competition_id')
					.where('competition_tips.race_id=? AND competitions.scope=? AND competition_participants.is_primary=?', race_id, scope, true)
					
			if (group_type=='race')
				leaderboard = self.combine_leaderboard_tip_results(results, tips)
			else
				leaderboard = self.combine_leaderboard_tip_results(results, tips, true)
			end
			
			CacheModule::set(leaderboard, cache_name, CacheModule::CACHE_TTL[:DAY])
		end
		
		return leaderboard
	end
	
	#Title:			combine_leaderboard_tip_results
	#Description:	Combines tips and results to get leaderboard data
	#Params:		results - Results
	#				tips - Tips
	#				sort_by_rank - Sort riders 
	def self.combine_leaderboard_tip_results(results, tips, sort_by_rank=false)
		user_scores = {}
		
		tips.each do |tip|
			#Skip non participants
			participation_data = CompetitionParticipant.select(:status).where({:user_id=>tip.competition_participant_id, :competition_id=>tip.competition_id}).first
			next if (participation_data.nil? || participation_data.status != STATUS[:ACTIVE])
			
			#Account for default riders
			if (tip.default_rider_id.nil?)
				modifier = 0
				rider_id = tip.rider_id
			else
				rider_id = tip.default_rider_id || tip.rider_id
				modifier = 1/(SCORE_MODIFIER[:DEFAULT]**5.to_f)
			end
			
			stage_id = tip.stage_id
			user_id = tip.competition_participant_id
			
			user = User.find_by_id(user_id)
			username = user.display_name
			username = (user.firstname+' '+user.lastname).strip if (username.nil? || username.empty?)

			user_score = user_scores[user_id] || Hash.new
			user_score[:tip] ||= Array.new
			user_score[:user_id] = user_id
			user_score[:username] = username
			user_score[:is_default] = !tip.default_rider_id.nil?
			user_score[:time] = 0
			
			#Original rider
			user_score[:original_rider] = nil
			if (user_score[:is_default])
				original_rider = Rider.find_by_id(tip.rider_id)
				user_score[:original_rider] = nil
				
				#Get original rider only if it exists
				if (!original_rider.nil?)
					result = Result.where({:rider_id=>original_rider.id, :season_stage_id=>tip.stage_id}).first
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
			
			rider = Rider.find_by_id(rider_id)
			
			#User has not tipped for a stage that does not have results
			if (rider.nil?)
				user_score[:tip].push({:id=>nil, :name=>'TBA'})
				user_scores[user_id] = user_score
				next
			end

			next if (results[rider_id].nil? || results[rider_id][:stages][stage_id].nil?)
				
			#Get tip data from results
			#Cumulate times
			if (user_score[:time].nil?)
				user_score[:time] = results[rider_id][:stages][stage_id][:time] - results[rider_id][:stages][stage_id][:bonus_time] + modifier
			else 
				user_score[:time] += results[rider_id][:stages][stage_id][:time] - results[rider_id][:stages][stage_id][:bonus_time] + modifier
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
			
			#Rank
			user_score[:rank] = results[rider_id][:stages][stage_id][:rank]
			
			user_score[:tip].push({:id=>rider_id, :name=>rider.name})
			user_scores[user_id] = user_score
		end
		
		#Sort leaderboard
		if (sort_by_rank)
			leaderboard = user_scores.sort_by {|user_id, data| data[:rank]}
		else
			leaderboard = user_scores.sort_by {|user_id, data| data[:time]}
		end
		
		#Get gap times
		leaderboard_with_gap = []
		base_time = nil
		leaderboard.each do |entry|
			gap_formatted = nil
			gap = (entry[1][:time] - base_time) if (!base_time.nil?)
			gap_formatted = self.format_time(gap) if (!gap.nil?)
			entry[1][:formatted_gap] = gap_formatted
			leaderboard_with_gap.push(entry[1])
			
			base_time ||= entry[1][:time]
		end
		
		return leaderboard_with_gap
	end
	
	#Title:			get_top
	#Description:	Get top scorers in the leaderboard
	def self.get_top(data_sym, count, data)
		top = []
		added_ndx = []
		
		for i in 1..count
			max = nil
			current = nil
			ndx = 0
			
			data.each do |d|
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