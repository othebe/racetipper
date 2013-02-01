class RacesController < ApplicationController
	def show
		race_id = params[:id]
		@race = Race.find_by_id(race_id)
		@stages = Stage.where({:race_id=>race_id})
		
		#Get current results
		@results = Result.get_results('race', race_id)
		
		render :layout=>false
	end
end
