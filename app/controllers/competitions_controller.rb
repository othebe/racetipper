class CompetitionsController < ApplicationController
	def show
		redirect_to :root if (!params.has_key?(:id))
		@data = get_competition_data(params[:id])
		@data[:races] = Competition.get_all_races(params[:id])
	end
	
	def results
		redirect_to :root if (!params.has_key?(:id))
		
		race_id = Competition.get_current_race(params[:id])
		
		@data = get_competition_data(params[:id])
		@data[:race_id] = race_id
		
		stages = Stage.where({:race_id=>race_id, :status=>STATUS[:ACTIVE]}).order(:order_id)
		@data[:stages] = stages
		
		first_stage_tip = CompetitionTip.where({
			:competition_participant_id => @user.id,
			:stage_id => stages.first.id,
			:competition_id => params[:id]
		})
		if (!first_stage_tip.empty?)
			@data[:first_stage_tipped_rider_id] = first_stage_tip.first.rider_id
		else
			@data[:first_stage_tipped_rider_id] = nil
		end
		
		teams = Team.where({:season_id=>@data[:competition].season_id, :status=>STATUS[:ACTIVE]})
		team_arr = []
		teams.each do |team|
			team_data = {}
			riders = TeamRider.where({:team_id=>team.id, :status=>STATUS[:ACTIVE]})
			team_data[:team_id] = team.id
			team_data[:team_name] = team.name
			team_data[:riders] = riders
			team_arr.push(team_data)
		end
		@data[:teams] = team_arr
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
				competition_stage.race_id = race_id
				competition_stage.status = STATUS[:ACTIVE]
				competition_stage.save
			end
		end

		render :json=>{:success=>true, :msg=>'success'}
	end
	
	#Title:			get_competition_stage_info
	#Description:	Retrieves stage info for a competition's race including selected tip.
	#Returns:		JSON of data array
	def get_competition_stage_info
		render :json=>{:success=>false} and return if (!params.has_key?(:stage_id) || !params.has_key?(:competition_id))
		render :json=>{:success=>false} and return if (@user.nil?)
		
		stage = Stage.find_by_id(params[:stage_id])
		tip = CompetitionTip.where({
			:competition_participant_id=>@user.id, 
			:competition_id=>params[:competition_id],
			:stage_id=>params[:stage_id]
		}).first
		
		tipped_rider_id = nil
		tipped_rider_id = tip.rider_id if (!tip.nil?)
		
		data = {
			:stage_id => stage.id,
			:stage_name => stage.name,
			:stage_description => stage.description,
			:stage_image_url => stage.image_url,
			:stage_profile => stage.profile,
			:stage_starts_on => stage.starts_on,
			:stage_start_location => stage.start_location,
			:stage_end_location => stage.end_location,
			:stage_distance_km => stage.distance_km,
			:tipped_rider_id => tipped_rider_id
		}
		
		render :json=>{:data=>data}
	end
	
	#POST
	def join
		render :json=>{:success=>false, :msg=>'User not logged in.'} and return if (@user.nil?)
		render :json=>{:success=>false, :msg=>'No competition selected'} and return if (!params.has_key?(:competition_id))
		
		competition = Competition.find_by_id(params[:competition_id])
		if (competition.status = STATUS[:ACTIVE])
			participation = CompetitionParticipant.where({:competition_id=>params[:competition_id], :user_id=>@user.id}).first
			participation ||= CompetitionParticipant.new
			participation.competition_id = params[:competition_id]
			participation.user_id = @user.id
			participation.save
		elsif (competition.status = STATUS[:PRIVATE])
		end
		render :json=>{:success=>true, :msg=>'success'}
	end
	
	def tip
		render :json=>{:success=>false, :msg=>'Rider not selected.'} and return if (!params.has_key?(:rider_id))
		render :json=>{:success=>false, :msg=>'Competition not selected.'} and return if (!params.has_key?(:competition_id))
		render :json=>{:success=>false, :msg=>'Stage not selected.'} and return if (!params.has_key?(:stage_id))
		render :json=>{:success=>false, :msg=>'User not logged in.'} and return if (@user.nil?)
		
		tip = CompetitionTip.where({
			:competition_participant_id => @user.id,
			:stage_id => params[:stage_id],
			:competition_id => params[:competition_id]
		}).first
		
		tip ||= CompetitionTip.new
		tip.competition_participant_id = @user.id
		tip.stage_id = params[:stage_id]
		tip.rider_id = params[:rider_id]
		tip.competition_id = params[:competition_id]
		tip.save
		
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
