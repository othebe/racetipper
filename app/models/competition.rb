class Competition < ActiveRecord::Base
	attr_accessible :creator_id, :description, :image_url, :name, :season_id
  
	#Title:			get_current_race
	#Description:	Retrieves the current race by looking at the date
	#Params:		competition_id
	def self.get_current_race(competition_id)
		stage = CompetitionStage.where('competition_id=?', competition_id).joins(:stage).first
		return stage.stage.race_id
	end
	
	#Title:			get_all_races
	#Description:	Get all races in competition
	#Params:		competition_id
	def self.get_all_races(competition_id)
		races = CompetitionStage.where({:competition_id=>competition_id, :status=>STATUS[:ACTIVE]}).select(:race_id).uniq()
		return races
	end
end
