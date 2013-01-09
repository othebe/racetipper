class StagesController < ApplicationController
	def show
		stage_id = params[:id]
		@stage = Stage.where({:id=>stage_id}).joins(:race).first
		@results = get_stage_results(stage_id)
		@stages = Stage.where({:race_id=>@stage.race_id})
		
		render :layout=>false
	end
	
	private
	def get_stage_results(stage_id, sort_field='points')
		results  = Result.where({:season_stage_id=>stage_id})
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
