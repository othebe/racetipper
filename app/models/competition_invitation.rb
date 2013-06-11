class CompetitionInvitation < ActiveRecord::Base
  attr_accessible :competition_id, :user_id
  belongs_to :competition
  belongs_to :user
  
	#Title:			invite_user
	#Description:	Invites a user to a competition
	#Params:		user_id - Invite this user
	#				competition_id - To this competition
	def self.invite_user(user_id, competition_id, inviter_id)
		invitation = self.where({:competition_id=>competition_id, :user_id=>user_id}).first
		return if (!invitation.nil?)
		
		invitation = self.new
		invitation.competition_id = competition_id
		invitation.user_id = user_id
		invitation.save
	end

	#Title:			delete_invitation
	#Description:	Change invitation status to 2 which means deleted
	#Params:		user_id - The invited user
	#				competition_id - The invited competition
	def self.delete_invitation(user_id, competition_id)
		invitation = self.where({:user_id=>user_id, :competition_id=>competition_id}).first
		invitation.status = 2
		invitation.save
	end
	
	#Title:			get_user_invitations
	#Description:	Gets open invitations to a competiton
	#Params:		user_id - User to search on
	def self.get_user_invitations(user_id)
		response = []
		invitations = self.where({:user_id=>user_id})
		invitations.each do |invitation|
			race_id = CompetitionStage.select('race_id').where({:competition_id=>invitation.competition.id}).first
			#If invitation haven't been accepted
			if invitation.status == 1
				response.push({
					:invitation => invitation,
					:competition => invitation.competition,
					:creator => User.find_by_id(invitation.competition.creator_id),
					:race => Race.find_by_id(race_id.race_id)
				})
			end
  		end
 		return response
 	end
end
