class CompetitionsController < ApplicationController
	def show
		redirect_to :root if (!params.has_key?(:id))
		@data = get_competition_data(params[:id])
	end
	
	def results
		redirect_to :root if (!params.has_key?(:id))
		
		@data = get_competition_data(params[:id])
		
		race_id = Competition.get_current_race(params[:id])
		stages = Stage.where({:race_id=>race_id, :status=>STATUS[:ACTIVE]}).order(:order_id)
		@data[:stages] = stages
		
		teams = Team.where({:season_id=>@data[:competition].season_id, :status=>STATUS[:ACTIVE]})
		team_arr = []
		teams.each do |team|
			team_data = {}
			riders = TeamRider.where({:team_id=>team.id, :status=>STATUS[:ACTIVE]})
			team_data['team_id'] = team.id
			team_data['riders'] = riders
			team_arr.push(team_data)
		end
		
		logger.debug(teams.inspect)
		@data[:teams] = teams
	end
	
	def leaderboard
	end
	
	def edit
		@races = Race.where(:status=>STATUS[:ACTIVE])
		render :layout=>false
	end
	
	def save_competition
		render :json=>{:success=>false, :msg=>'An error occurred. Please refresh your browser and try again.'} and return if (!params.has_key?(:data))
		render :json=>{:success=>false, :msg=>'You are not logged in.'} and return if (@user.nil?)
		
		current_year = Time.now.year
		season_id = Season.find_by_year(current_year)
		render :json=>{:success=>false, :msg=>'This season has not been released yet.'} and return if (season_id.nil?)
		
		competition_data = params[:data]
		
		#Save competition
		competition = nil
		if (params.has_key?(:id))
			competition = Competition.find_by_id(params[:id])
		end
		competition ||= Competition.new
		
		competition.creator_id = @user.id
		competition.name = competition_data[:competition_name]
		competition.description = competition_data[:competition_description]
		competition.image_url = competition_data[:competition_image_url]
		competition.season_id = season_id
		if (competition_data[:open_to]=='private')
			competition.status = STATUS[:PRIVATE]
			send_competition_invitations(competition_data[:invitations])
		else
			competition.status = STATUS[:ACTIVE]
		end
		competition.save
		
		#Save races/stages
		competition_data[:races].each do |race_id|
			stages = Stage.where('race_id=? AND season_id=? AND status=?', race_id, season_id, STATUS[:ACTIVE])
			stages.each do |stage|
				competition_stage = CompetitionStage.where('stage_id=? AND competition_id=? AND status=?', stage.id, competition.id, STATUS[:ACTIVE]).first
				competition_stage ||= CompetitionStage.new
				competition_stage.competition_id = competition.id
				competition_stage.stage_id = stage.id
				competition_stage.status = STATUS[:ACTIVE]
				competition_stage.save
			end
		end

		render :json=>{:success=>true, :msg=>'success'}
	end
	
	#Title:			get_competition_stage_info
	#Description:	Retrieves stage info for a competition's race including selected tip.
	#Returns:		JSON of data array
	def get_competition_race_info
		render :json=>{:success=>false} and return if (!params.has_key?(:race_id) || !params.has_key?(:competition_id))
		
		uid = 0
		uid = @user.id if (!@user.nil?)
		
		data = []
		race_id = params[:race_id]
		competition_id = params[:competition_id]
		stages = Stage.where({:race_id=>race_id, :status=>STATUS[:ACTIVE]}).order(:order_id)
		stages.each do |stage|
			tip = CompetitionTip.where({:competition_id=>competition_id, :stage_id=>stage.id, :competition_participant_id=>uid}).first
			tipped_rider_id = -1;
			tipped_rider_id = tip.rider_id if (!tip.nil?)
			stage_data = {
				:stage_id => stage.id,
				:stage_name => stage.name,
				:stage_description => stage.description,
				:stage_profile => stage.profile,
				:stage_starts_on => stage.starts_on,
				:stage_start_location => stage.start_location,
				:stage_end_location => stage.end_location,
				:stage_distance_km => stage.distance_km,
				:tipped_rider_id => tipped_rider_id
			}
			data.push(stage_data)
		end
		render :json=>{:stage_data=>data}
	end
	
	#POST
	def join
		render :json=>{:success=>true, :msg=>'success'}
	end
	
	private
	def send_competition_invitations(emails)
	end
	
	private
	def get_competition_data(competition_id)
		competition = Competition.find_by_id(competition_id)
		redirect_to :root if (competition.nil?)
		
		participant = false
		if (!@user.nil?)
			participant = !CompetitionParticipant.where({:competition_id=>competition.id, :user_id=>@user.id}).empty?
		end
		
		data = {}
		data[:competition] = competition
		data[:creator] = User.find_by_id(competition.creator_id)
		data[:is_participant] = participant
		
		return data
	end
end
