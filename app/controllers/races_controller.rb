class RacesController < ApplicationController
	def show
		race_id = params[:id]
		@race = Race.find_by_id(race_id)
		@stages = Stage.where({:race_id=>race_id})
		
		#Get current results
		@results = get_race_results(race_id)
		
		render :layout=>false
	end
	
	private
	def get_race_results(race_id, sort_field='points')
		results  = Result.where({:race_id=>race_id})
		rider_points_unsorted = {}
		results.each do |result|
			rider_id = result.rider_id
			rider_data = rider_points_unsorted[rider_id] || Hash.new
			rider_data[:id] = rider_id
			rider_data[:rider_name] ||= Rider.find_by_id(rider_id).name
			rider_data[:time] = (rider_data[:time] || 0) + result.time
			rider_data[:kom_points] = (rider_data[:kom_points] || 0) + result.kom_points
			rider_data[:sprint_points] = (rider_data[:sprint_points] || 0) + result.sprint_points
			rider_data[:points] = (rider_data[:points] || 0) + result.points
			rider_points_unsorted[rider_id] = rider_data
		end
		rider_points_sorted = rider_points_unsorted.sort_by{|k, v| v[sort_field.to_sym]*-1}
		return rider_points_sorted
	end
end
