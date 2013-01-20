class AppMailer < ActionMailer::Base
  default from: "from@example.com"
  
	def competition_invitation(emails, competition)
		return if (emails.nil || emails.strip.length==0)
		creator = User.find_by_id(competition.creator_id)
		@competition = competition
		@invitor_name = (creator.firstname.strip.capitalize+' '+creator.lastname.strip.capitalize).strip
		@invitation_url = SITE_URL+'invitations/'+competition.id.to_s+'/'+competition.invitation_code
		mail(:to => emails, :subject => "Invitation for competition.")
	end
end
