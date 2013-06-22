class RacesController < ApplicationController
	require_dependency 'race_module'
	require_dependency 'leaderboard_module'
	
	#Title:			index
	#Description:	Show competition grid
	def index
		user_id = 0
		user_id = @user.id if (!@user.nil?)
		
		@racedata = []
		races = Race.where({:status=>STATUS[:ACTIVE]}).order('id DESC')
		
		races.each do |race|
			#Next stage info
			next_stage = Stage.where('race_id=? AND is_complete=FALSE AND starts_on>NOW()', race.id).order('starts_on ASC').first
			next_stage_data = {
				:next_stage_name => (next_stage.nil?)?nil:next_stage.name,
				:next_stage_remaining => (next_stage.nil?)?0:(next_stage.starts_on-Time.now).to_i
			}
			
			#Allow new competitions?
			allow_new_competition = false
			allow_new_competition = (!next_stage.nil?) if (user_id > 0)
			
			#Get competitions
			competition_data = []
			competitions = Competition.where({:race_id=>race.id, :status=>STATUS[:ACTIVE], :scope=>@scope})
			competitions.each do |competition|
				#Only get valid competitions
				next if (![STATUS[:ACTIVE], STATUS[:PRIVATE]].include?(competition.status))
				
				#Participation data
				participants = CompetitionParticipant.where({:competition_id=>competition.id})
				is_participant = (!participants.where({:user_id=>user_id}).empty?)
				
				#Must be participant for private competitions
				next if (!is_participant && competition.status==STATUS[:PRIVATE])
				
				competition[:num_participants] = participants.length
				competition_data.push(competition)
			end
			
			@racedata.push({
				:race => race,
				:competitions => competition_data,
				:allow_new_competition => allow_new_competition,
				:next_stage => next_stage_data
			})
		end
	end
	
	#Title:			show
	#Description:	Landing page for a race
	def show
		@race = Race.find_by_id(params[:id])
		
		#Get stages
		@stages = Stage.where('race_id=?', @race.id).order('starts_on ASC')
		
		#Riders
		@riders = Race.get_riders_for_race(@race.id)
		#Rider count
		@num_riders = 0
		@riders.each do |rider_data|
			rider_data[:riders].each {|rider| @num_riders += 1}
		end
		
		#Next stage info
		next_stage = @stages.where('is_complete=FALSE AND starts_on>NOW()').first
		@next_stage_data = {
			:next_stage_name => (next_stage.nil?)?nil:next_stage.name,
			:next_stage_remaining => (next_stage.nil?)?0:(next_stage.starts_on-Time.now).to_i
		}
		
		#Race first stage
		@race[:first_stage] = @stages.first
		@race[:last_stage] = @stages.last
	end
	
	#Title:			racebox
	#Description:	Show a single race box similar to a single instance of the races in the home screen
	def racebox
		redirect_to :root and return if (!params.has_key?(:id))

		#Check for login via access token
		return if login_with_token.nil?
		
		user_id = 0
		user_id = @user.id if (!@user.nil?)
		
		race_id = params[:id]
		@race = Race.find_by_id(race_id)
		@user_race_data = RaceModule::get_user_race_data(user_id, @race, @scope)
		
		@invitations = CompetitionInvitation.get_user_invitations(user_id)
		
		redirect_to :root and return if (@race.nil?)
		
		#Cycling tips display
		render :layout=>'cyclingtips' and return if (params.has_key?(:display) && params[:display]=='cyclingtips')
	end
	
	#Title:			leaderboard
	#Description:	Global (sitewide) leaderboard
	def leaderboard
		redirect_to :root and return if (!params.has_key?(:id))
		redirect_to :root and return if (@user.nil?)
		
		race_id = params[:id]
		@race = Race.find_by_id(race_id)
		
		competition_id = CompetitionParticipant.get_primary_competition(@user.id, race_id, @scope)
		redirect_to :root and return if (competition_id.nil?)
		
		@competition = Competition.find_by_id(competition_id)
		@competition.name = 'Sitewide'
		@competition.description = ''
		@leaderboard = LeaderboardModule::get_global_leaderboard(race_id, @scope)
		
		#Get primary competition
		primary_competition_id = CompetitionParticipant.get_primary_competition(@user.id, race_id, @scope)
		@stages = Stage.where({:race_id=>race_id, :status=>STATUS[:ACTIVE]}).order('starts_on')
		
		@completed_stages = @stages.where({:is_complete=>true}).count
		
		#Number of participants
		participants = CompetitionParticipant
						.joins(:competition)
						.where('competitions.race_id=? AND competitions.scope=? AND competition_participants.status=?', 
							race_id, @scope, STATUS[:ACTIVE])
		@num_participants = participants.count
		
		#Get top 2 sprint
		@top_sprints = LeaderboardModule::get_top(:sprint, 2, @leaderboard)
		
		#Get top 2 KOM
		@top_koms = LeaderboardModule::get_top(:kom, 2, @leaderboard)
		
		@left_nav_data = RaceModule::get_left_nav_data(@stages, primary_competition_id, @user.id)
		
		@hide_action_buttons = true
		
		#Cycling tips display
		render :layout=>'cyclingtips' and return if (params.has_key?(:display) && params[:display]=='cyclingtips')
	end
	
	
	######################################
	#### JSON
	######################################
	
	#Title:			get_results
	#Description:	Get results for a race
	def get_results
		race_id = params[:id]
		
		race = Race.find_by_id(race_id)
		results = Result.get_results('race', race_id)
		
		data = []
		results.each do |ndx, result|
			data.push({
				:rider_name => result[:rider_name],
				:kom_points => result[:kom_points],
				:sprint_points => result[:sprint_points],
				:disqualified => result[:disqualified],
				:rank => result[:rank],
				:time_formatted => result[:time_formatted],
				:bonus_time_formatted => result[:bonus_time_formatted],
				:gap_formatted => result[:gap_formatted]
			})
		end
		
		race_data = {
			:name => race.name,
			:description => race.description,
			:season => Season.find_by_id(race.season_id).year
		}
		
		render :json=>{:results=>data, :race=>race_data}
	end
	
	#Title:			get_stages
	#Description:	Get the stages in a race
	def get_stages
		render :json=>{:success=>false, :msg=>'Missing race ID'} and return if (!params.has_key?(:id))
		
		race = Race.find_by_id(params[:id])
		render :json=>{:success=>false, :msg=>'Invalid race ID'} and return if (race.nil?)
		
		data = []
		stages = Stage.where({:race_id=>race.id, :status=>STATUS[:ACTIVE]})
		stages.each do |stage|
			data.push({
				:id => stage.id,
				:name => stage.name
			})
		end
		
		render :json=>{:success=>true, :data=>data}
	end
end