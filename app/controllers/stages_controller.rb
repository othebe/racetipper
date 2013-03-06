class StagesController < ApplicationController
	def show
		stage_id = params[:id]
		@stage = Stage.where({:id=>stage_id}).joins(:race).first
		@results = Result.get_results('stage', stage_id)
		@stages = Stage.where({:race_id=>@stage.race_id}).order('starts_on')
		
		render :layout=>false
	end
end
