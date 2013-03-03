class Competition < ActiveRecord::Base
	attr_accessible :creator_id, :description, :image_url, :name, :season_id
	
	has_many :CompetitionInvitation
	has_many :CompetitionParticipation
	
	#Title:			get_competitions
	#Description:	Gets available competitions
	#Params:		user_id - View ID
	#				sort_by - Sort by this
	#				options (Hash):
	#					limit
	#					offset
	#					sort_by
	def self.get_competitions(user_id, options={})
		limit = options.has_key?(:limit)?options[:limit]:COMPETITION_LOAD_QTY
		offset = options.has_key?(:offset)?options[:offset]:0
		sort_by = options.has_key?(:sort_by)?options[:sort_by]:'competitions.id DESC'
		competitions = self.where('competitions.status=? OR (competitions.status=? AND competition_participants.user_id=? AND competition_participants.status=?)', STATUS[:ACTIVE], STATUS[:PRIVATE], user_id, STATUS[:ACTIVE]).joins('LEFT JOIN competition_participants ON competition_participants.competition_id=competitions.id').group('competitions.id').order(sort_by).limit(limit).offset(offset)
		
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
		races = CompetitionStage.where({:competition_id=>competition_id, :status=>STATUS[:ACTIVE]}).select(:race_id).group(:race_id)
		return races
	end
	
	#Title:			check_completion_status
	#Description:	Checks if all races in a competition are completed, and marks competition as inactive
	#Params:		competition_id
	def self.check_completion_status(competition_id)
		races = CompetitionStage.where('competition_id=? AND races.is_complete=FALSE', competition_id).joins(:race)
		competition = Competition.find_by_id(competition_id)
		return if (competition.nil?)
		if (races.empty?)
			competition.is_complete = true
		else
			competition.is_complete = false
		end
		competition.save
	end
	
	#Title:			fix_completion_status
	#Description:	Fix completion status for all races and competitions
	def self.fix_completion_status()
		races = Race.all
		races.each do |race|
			Race.check_completion_status(race.id)
		end
		
		competitions = Competition.all
		competitions.each do |competition|
			Competition.check_completion_status(competition.id)
		end
	end
end
