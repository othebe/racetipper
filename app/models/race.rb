class Race < ActiveRecord::Base
  attr_accessible :description, :image_url, :name
  
	#Title:			get_race_results_by_rider
	#Description:	Gets results of race indexed by rider id
	#Params:		race_id
	def self.get_race_results_by_rider(race_id)
		results = Result.where({:race_id=>race_id})
		
		data = {}
		results.each do |result|
			arr = {}
			arr = data[result.rider_id] if (data.has_key?(result.rider_id))
			stage_data = {
				:stage_id => result.season_stage_id,
				:time => result.time,
				:kom => result.kom_points,
				:sprint => result.sprint_points,
				:points => result.points
			}
			arr[result.season_stage_id] = stage_data
			data[result.rider_id] = arr
		end
		return data
	end
end
