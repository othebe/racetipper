class Competition < ActiveRecord::Base
	attr_accessible :creator_id, :description, :image_url, :name, :season_id
	
	has_many :CompetitionInvitation
	
	#Title:			get_competitions
	#Description:	Gets available competitions
	#Params:		user_id - View ID
	#				sort_by - Sort by this
	#				options (Hash):
	#					limit
	#					offset
	#					sort_by
	def self.get_competitions(user_id, options={})
		limit = options.has_key?(:limit)?options[:limit]:10
		offset = options.has_key?(:offset)?options[:offset]:0
		sort_by = options.has_key?(:sort_by)?options[:sort_by]:'competitions.id DESC'
		competitions = self.where('competitions.status=? OR (competitions.status=? AND competition_invitations.user_id=? AND competition_invitations.status=?)', STATUS[:ACTIVE], STATUS[:PRIVATE], user_id, STATUS[:ACTIVE]).joins('LEFT JOIN competition_invitations ON competition_invitations.competition_id=competitions.id').order(sort_by).limit(limit).offset(offset)
		
		return competitions
	end
  
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
