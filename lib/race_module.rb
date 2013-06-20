module RaceModule
	require 'leaderboard_module'
	
	#Title:			get_user_race_data
	#Description:	Gets race related information for a user
	def self.get_user_race_data(user_id, race, scope)
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
		race_data = {}
		race_data[:race_name] = race.name
		race_data[:next_stage_name] = (next_stage.nil?)?nil:next_stage.name
		race_data[:next_stage_remaining] = (next_stage.nil?)?0:(next_stage.starts_on-Time.now).to_i
		race_data[:has_started] = has_started
		
		#Global results
		global_results = self.get_global_competition_results(race.id, scope, user_id)
		
		#Competitions that haven't been joined
		more_competitions = []
		
		data = []

		competitions = Competition.where('race_id=? AND scope=? AND (status=? OR status=?)', race.id, scope, STATUS[:ACTIVE], STATUS[:PRIVATE])
		competitions.each do |competition|
			participants = CompetitionParticipant.where({:competition_id=>competition.id, :status=>STATUS[:ACTIVE]})
			is_participant = (!participants.where({:user_id=>user_id}).empty?)

			#For private competitions, check participation
			if (competition.status == STATUS[:PRIVATE])
				next if (!is_participant)
			#Ignore non-active competitions
			else
				next if (competition.status != STATUS[:ACTIVE])
			end
			
			#Check if participant
			if (!is_participant)
				more_competitions.push({
					:competition_id => competition.id,
					:competition_name => competition.name,
					:num_participants => participants.length
				}) if (competition.status == STATUS[:ACTIVE])
				next
			end
			
			#Check if this competition is the primary
			is_primary = participants.where({:user_id=>user_id}).first.is_primary
			
			#Leaderboard for this competition
			leaderboard = LeaderboardModule::get_leaderboard(competition.id, 'race', race.id)

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
				rank += 1
				if (entry[:user_id]==user_id)
					username = entry[:username]
					formatted_time = entry[:formatted_time] || '--'
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
		leaderboard = Race.get_global_competition_leaderboard(race_id, 'race', nil, scope)
		
		if (user_id.to_i>0 && !leaderboard.nil?)
			leaderboard.each do |entry|
				rank += 1
				break if (entry[:user].id == user_id)
			end
		end
		
		return {
			:rank => rank,
		}
	end
end