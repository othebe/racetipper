class StagesController < ApplicationController
	def show
		stage_id = params[:id]
		@stage = Stage.where({:id=>stage_id}).joins(:race).first
		@results = Result.get_results('stage', stage_id)
		@stages = Stage.where({:race_id=>@stage.race_id}).order('starts_on')
		
		render :layout=>false
	end
	
	#Title:			get_results
	#Description:	Get results for a race
	def get_results
		stage_id = params[:id]
		
		results = Result.get_results('stage', stage_id)
		stage = Stage.find_by_id(stage_id)
		
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
		
		if (!@user.nil? && !@user.time_zone.nil?)
			stage_starts_on = stage.starts_on.gmtime.localtime(@user.time_zone)
		else
			stage_starts_on = stage.starts_on.gmtime
		end
		stage_data = {
			:name => stage.name,
			:description => stage.description,
			:profile => stage.profile,
			:starts_on => stage_starts_on.strftime('%b %e, %Y, %H:%M'),
			:start_location => stage.start_location,
			:end_location => stage.end_location,
			:distance => stage.distance_km
		}
		
		render :json=>{:results=>data, :stage=>stage_data}
	end
end
