class StagesController < ApplicationController
	#Title:			information
	#Description:	Gets stage information
	def information
		stage = Stage.find_by_id(params[:id])
		render :json=>{:success=>false} and return if (stage.nil?)
		
		#Get stage tips
		rider = nil
		rider_name = nil
		competition_id = params[:competition_id]
		if (!@user.nil?)
			tip = CompetitionTip.where({:competition_participant_id=>@user.id, :stage_id=>params[:id], :competition_id=>competition_id}).first
			rider_used = (tip.default_rider_id || tip.rider_id)
			rider = Rider.find_by_id(rider_used)
			rider_name = (rider.nil?)?nil:rider.name
		end
		
		#Get current pending/completed status
		status = 'OPEN'
		remaining = stage.starts_on - Time.now
		if (remaining <= 0)
			if (stage.is_complete)
				status = 'COMPLETED'
			else
				status = 'IN PROGRESS'
			end
		end
		
		data = {}
		data[:stage_name] = stage.name
		data[:distance_km] = stage.distance_km
		data[:start_location] = stage.start_location
		data[:end_location] = stage.end_location
		data[:remaining] = remaining
		data[:is_complete] = stage.is_complete
		data[:description] = stage.description
		data[:status] = status
		data[:rider_id] = (rider.nil?)?nil:rider.id
		data[:rider_name] = rider_name
		data[:race_id] = stage.race_id
		
		render :json=>data
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
			:profile => (stage.profile.nil? || stage.profile.empty?)?nil:stage.profile,
			:starts_on => stage_starts_on.strftime('%b %e, %Y, %H:%M'),
			:start_location => stage.start_location,
			:end_location => stage.end_location,
			:distance => stage.distance_km
		}
		
		render :json=>{:results=>data, :stage=>stage_data}
	end
end
