class CompetitionParticipant < ActiveRecord::Base
	attr_accessible :competition_id, :user_id, :is_primary
	belongs_to :user
	belongs_to :competition
	
	require_dependency 'cache_module'

	#Title:			add_participant
	#Description:	Adds a participant to a competition. Adds empty tips for all stages in the competition.
	#Params:		user_id - Participant user ID
	#				competition_id - Competition ID
	def self.add_participant(user_id, competition_id, scope)
		competition = Competition.find_by_id(competition_id)
		return if (competition.nil?)
		
		#Add user to competition
		participation = self.where({:competition_id=>competition_id, :user_id=>user_id}).first
		participation ||= self.new
		participation.competition_id = competition_id
		participation.user_id = user_id
		participation.status = STATUS[:ACTIVE]
		participation.save
		
		CompetitionTip.fill_tips(user_id, competition_id)
		
		#Designate this competition as the primary if its the first
		has_primary = (self.joins(:competition).where('user_id=? AND competitions.race_id=? AND is_primary=? AND scope=?', user_id, competition.race_id, true, scope).count > 0)
		self.set_primary_competition(competition_id, user_id, scope) if (!has_primary)
	end
	
	#Title:			find_and_set_primary_competition
	#Description:	Finds and designates the first suitable competition as the sitewide
	#Params:		race_id - Race ID
	#				user_id - User ID
	#				scope - COMPETITION_SCOPE
	def self.find_and_set_primary_competition(race_id, user_id, scope)
		primary = self.get_primary_competition(user_id, race_id, scope)
		if (primary.nil?)
			competitions = self.get_participated_competitions(user_id, race_id, scope)
			self.set_primary_competition(competitions.first.competition_id, user_id, scope) if (!competitions.empty?)
		end
	end
	
	#Title:			set_primary_competition
	#Description:	Designates a competition as the primary for sitewide
	#Params:		competition_id - Competition ID
	#				user_id - User ID
	#				scope - COMPETITION_SCOPE
	def self.set_primary_competition(competition_id, user_id, scope) 
		#Get competition data
		competition = Competition.find_by_id(competition_id)
		return false if (competition.nil?)
		
		#Cant change primaries for a competition thats ended
		return false if (competition.is_complete)
		
		#Find valid record
		participation = self.where({:competition_id=>competition_id, :user_id=>user_id, :status=>STATUS[:ACTIVE]}).first
		return false if (participation.nil?)
		
		#Cant set primaries for a race thats already started, AND you already have one chosen
		has_started = false
		first_stage = Stage.where({:race_id=>competition.race_id, :status=>STATUS[:ACTIVE]}).order('starts_on ASC').first
		has_started = (first_stage.starts_on <= Time.now) if (!first_stage.nil?)
		has_chosen = !self.get_primary_competition(user_id, competition.race_id, scope).nil?
		return if (has_started && has_chosen)
		
		#Remove primary status from other records
		primaries = self.joins(:competition).where('user_id=? AND competitions.race_id=? AND is_primary=? AND scope=? AND competition_participants.id<>?', user_id, competition.race_id, true, scope, participation.id)
		primaries.each do |primary|
			record = self.find_by_id(primary.id)
			record.is_primary = false
			record.save
		end
		
		participation.is_primary = true
		participation.save
		
		return true
	end
	
	#Title:			get_primary_competition
	#Description:	Gets primary competition for a user
	def self.get_primary_competition(user_id, race_id, scope)
		primary = self.joins(:competition).where('user_id=? AND competitions.race_id=? AND scope=? AND is_primary=? AND competition_participants.status=? AND competitions.status<>?', 
			user_id, race_id, scope, true, STATUS[:ACTIVE], STATUS[:DELETED]).first
		return primary.competition_id if (!primary.nil?)
	end
	
	#Title:			fix_set_primaries
	#Description:	Set a primary competition for everyone. (Run once to initialize the site-wide functionality)
	def self.fix_set_primaries
		records = self.all
		records.each do |record|
			competition = Competition.find_by_id(record.competition_id)
			next if competition.nil?
			user_id = record.user_id
			has_primary = (self.joins(:competition).where('user_id=? AND competitions.race_id=? AND is_primary=?', user_id, competition.race_id, true).count > 0)
			self.set_primary_competition(competition.id, user_id) if (!has_primary)
		end
	end

	#Title:			get_participated_competitions
	#Description:	Gets competitions a user is participating in
	def self.get_participated_competitions(user_id, race_id, scope)
		return CompetitionParticipant.joins(:competition).where(
				'user_id=? AND competitions.race_id=? AND scope=? AND competitions.status<>? AND competition_participants.status=?', 
					user_id, race_id, scope, STATUS[:DELETED], STATUS[:ACTIVE]).all
	end
end
