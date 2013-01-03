class CompetitionsController < ApplicationController
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
		
		logger.debug(competition.inspect)
		
		
		
		
		render :json=>{:success=>true, :msg=>'success'}
	end
	
	private
	def send_competition_invitations(emails)
	end
end
