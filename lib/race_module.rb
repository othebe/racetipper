module RaceModule
	require_dependency 'leaderboard_module'
	
	#Title:			get_user_race_data
	#Description:	Gets race related information for a user
	def self.get_user_race_data(user_id, race, scope)
		user_id = user_id.to_i if (user_id.class==String)
		
		#Next stage
		next_stage = Stage.where('race_id=? AND is_complete=FALSE AND starts_on>NOW()', race.id).order('starts_on ASC').first
		#Has race started?
		first_stage = Stage.where({:race_id=>race.id, :status=>STATUS[:ACTIVE]}).order('starts_on ASC').first
		if (!first_stage.nil?)
			has_started = (first_stage.starts_on <= Time.now)
		else 
			has_started = false
		end

		#Get race data
		race_id = race.id
		race_data = {}
		race_data[:id] = race_id
		race_data[:race_name] = race.name
		race_data[:next_stage_name] = (next_stage.nil?)?nil:next_stage.name
		race_data[:next_stage_remaining] = (next_stage.nil?)?0:(next_stage.starts_on-Time.now).to_i
		race_data[:has_started] = has_started
		
		#Get primary competition
		primary_competition = CompetitionParticipant.get_primary_competition(user_id, race_id, scope)
		
		#Global results
		global_results = self.get_global_competition_results(race.id, scope, user_id)
		
		#Competitions that haven't been joined
		more_competitions = []
		more_competitions_seen = {}
		#Invited competitions
		CompetitionInvitation.get_user_invitations(user_id, scope, race_id).each do |invitation|
			more_competitions_seen[competition.id] = true
			competition = invitation[:competition]
			more_competitions.push({
				:competition_id => competition.id,
				:competition_name => competition.name,
				:num_participants =>CompetitionParticipant.where({:competition_id=>competition.id, :status=>STATUS[:ACTIVE]}).count
			})
		end
		#Public competitions
		Competition.where({:race_id=>race_id, :scope=>scope, :status=>STATUS[:ACTIVE]}).each do |competition|
			next if (!more_competitions_seen[competition.id].nil?)
			next if (!CompetitionParticipant.where({:competition_id=>competition.id, :status=>STATUS[:ACTIVE], :user_id=>user_id}).empty?)
			more_competitions.push({
				:competition_id => competition.id,
				:competition_name => competition.name,
				:num_participants =>CompetitionParticipant.where({:competition_id=>competition.id, :status=>STATUS[:ACTIVE]}).count
			})
		end
		
		#Competitions user is participating in
		data = []
		CompetitionParticipant.get_participated_competitions(user_id, race_id, scope).each do |competition|
			#Check if this competition is the primary
			is_primary = (primary_competition.nil?)?false:(competition.id == primary_competition.competition_id)
			
			#Leaderboard for this competition
			leaderboard = LeaderboardModule::get_competition_race_leaderboard(competition.id)
			leaderboard = [] if leaderboard.nil?

			#Check tip for next stage
			rider = nil
			if (!next_stage.nil?)
				tip = CompetitionTip.where({:competition_participant_id=>user_id, :race_id=>race.id, :stage_id=>next_stage.id, :competition_id=>competition.id}).first
				rider = Rider.find_by_id(tip.rider_id) if (!tip.nil? && !tip.rider_id.nil?) 
			end
			
			current_time = nil;
			rank = 0
			
			#Find leaderboard entry
			username = formatted_time = ''
			leaderboard.each do |entry|
				if (entry[:user_id]==user_id)
					username = entry[:username]
					formatted_time = entry[:formatted_time] || '--'
					rank = entry[:rank]
					break
				end
			end
			
			data.push({
				:user_id => user_id,
				:username => username,
				:time_formatted => formatted_time,
				:competition_id => competition.id,
				:competition_name => competition.name,
				:rank => rank,
				:next_rider => (rider.nil?)?nil:rider.name ,
				:is_primary => is_primary
			})
		end
		
		return {:competition=>data, :global_results=>global_results, :race=>race_data, :more_competitions=>more_competitions}
	end
	
	#Title:			get_global_competition_results
	#Description:	Gets results for global competitions
	def self.get_global_competition_results(race_id, scope, user_id=0)
		rank = 0
		leaderboard = LeaderboardModule::get_global_race_leaderboard(race_id, scope)
		
		if (user_id.to_i>0 && !leaderboard.nil?)
			leaderboard.each do |entry|
				if (entry[:user_id] == user_id)
					rank = entry[:rank]
					break
				end
			end
		end
		
		return {
			:rank => rank,
			:leaderboard => leaderboard
		}
	end
	
	#Title:			get_left_nav_data
	#Description:	Gets data array for the left navigator
	def self.get_left_nav_data(stages, competition_id, user_id)
		tips = CompetitionTip.where({:competition_participant_id=>user_id, :race_id=>stages.first.race_id, :competition_id=>competition_id})
		
		data = []
		stages.each do |stage|
			#Get remaining
			remaining = (stage.starts_on-Time.now)
			if (remaining > 86400)
				remaining = (remaining/86400).to_i.to_s + ' days'
			elsif (remaining > 3600)
				remaining = (remaining/3600).to_i.to_s + ' hours'
			elsif (remaining > 0)
				remaining = (remaining/60).to_i.to_s + ' minutes'
			else 
				remaining = nil
			end
			
			stage_info = {
				:stage_id => stage.id,
				:stage_name => stage.name,
				:stage_type => stage.stage_type,
				:time_remaining => remaining,
			}
			
			#Check participation status
			if (user_id==0)
				stage_info[:participation] = 'NO_LOGIN'
			else
				participant = CompetitionParticipant.where({:competition_id=>competition_id, :user_id=>user_id})
				if (participant.empty?)
					stage_info[:participation] = 'NO_PARTICIPATION'
				else
					stage_info[:participation] = 'OK'
				end
			end
			
			#Get tipped rider info
			rider = nil
			if (user_id > 0)
				tip = tips.where({:stage_id => stage.id}).first
				chosen_rider = (tip.nil?)?nil:(tip.default_rider_id || tip.rider_id)
				if (!chosen_rider.nil?)
					rider = Rider.find_by_id(chosen_rider)
					rider = rider.name if (!rider.nil?)
				end
			end
			stage_info[:tip] = rider;
			
			data.push(stage_info)
		end
		
		return data
	end
end