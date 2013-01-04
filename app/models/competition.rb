class Competition < ActiveRecord::Base
	attr_accessible :creator_id, :description, :image_url, :name, :season_id
  
	#Title:			get_current_race
	#Description:	Retrieves the current race by looking at the date
	#Params:		competition_id
	def self.get_current_race(competition_id)
		stage = CompetitionStage.where('competition_id=? AND stages.race_id=1', competition_id).joins(:stage).first
		return stage.stage.race_id
	end
end
