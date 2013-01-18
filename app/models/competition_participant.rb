class CompetitionParticipant < ActiveRecord::Base
	attr_accessible :competition_id, :user_id
	belongs_to :user
  
	#Title:			add_participant
	#Description:	Adds a participant to a competition
	#Params:		user_id - Participant user ID
	#				competition_id - Competition ID
	def self.add_participant(user_id, competition_id)
		participation = self.where({:competition_id=>competition_id, :user_id=>user_id}).first
		participation ||= self.new
		participation.competition_id = competition_id
		participation.user_id = user_id
		participation.save
	end
end
