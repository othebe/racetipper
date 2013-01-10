class CompetitionInvitation < ActiveRecord::Base
  attr_accessible :competition_id, :user_id
  
	#Title:			invite_user
	#Description:	Invites a user to a competition
	#Params:		user_id - Invite this user
	#				competition_id - To this competition
	def self.invite_user(user_id, competition_id)
		invitation = self.where({:competition_id=>competition_id, :user_id=>user_id}).first
		return if (!invitation.nil?)
		
		invitation = self.new
		invitation.competition_id = competition_id
		invitation.user_id = user_id
		invitation.save
	end
end
