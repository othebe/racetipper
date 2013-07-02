class Competition < ActiveRecord::Base
	attr_accessible :creator_id, :description, :image_url, :name, :season_id, :competition_type
	
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
	def check_completion_status
		race = Race.find_by_id(self.race_id)
		return if (race.nil?)
		
		self.is_complete = race.is_complete 
		self.save
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
	
	#Title:			fix_competition_races
	#Description:	Adds race_id to competition
	def self.fix_competition_races
		competitions = Competition.all
		
		competitions.each do |competition|
			competition_stage = CompetitionStage.where({:competition_id=>competition.id}).limit(1).first
			next if (competition_stage.nil?)
			
			competition.race_id = competition_stage.race_id
			competition.save
		end
	end
	
	#Title:			is_competition_code_valid
	#Description:	Determines if a competition code is valid
	#Params:		competition_id - Competition ID
	#				code - Competition code
	def self.is_competition_code_valid(competition_id, code)
		competition = Competition.where({:id=>competition_id, :invitation_code=>code})
		return !competition.empty?
	end
	
	#Title:			add_participants_to_global_competition
	#Description:	Adds participants to a global competition. Called as cron / worker.
	#Returns:		status message
	def add_participants_to_global_competition
		users = User.where({:in_grand_competition=>true})
		
		invitation_count = 0
		users.each do |user|
			CompetitionParticipant.add_participant(user.id, self.id)
			invitation_count += 1
		end
		AppMailer.global_race_admin_notify(self.id, users.length, invitation_count).deliver
		
		return "#{self.name} created. #{invitation_count}/#{users.length} users invited."
	end
	
	#Title:			get_invitation_link
	#Description:	Gets invitation link to competition
	def get_invitation_link
		scope = self.scope
		race_id = self.race_id
		
		base_url = InvitationEmailTarget.get_base_url(race_id, scope)
		
		base_url += case self.scope
		when (COMPETITION_SCOPE[:SITE])
			'competitions/' + self.id.to_s + '?code=' + self.invitation_code
		when (COMPETITION_SCOPE[:CYCLINGTIPS])
			'?competition_id=' + self.id.to_s + '&code=' + self.invitation_code
		end
		
		return base_url
	end
end
