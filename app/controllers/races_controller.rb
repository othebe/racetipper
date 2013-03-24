class RacesController < ApplicationController
	#Title:			index
	#Description:	Show competition grid
	def index
		@races = Race.all()
		
		render :layout => nil
	end
	
	def show
		race_id = params[:id]
		@race = Race.find_by_id(race_id)
		@stages = Stage.where({:race_id=>race_id}).order('starts_on')
		
		render :layout=>false
	end
	
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
end
