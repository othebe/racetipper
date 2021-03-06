class AppMailer < ActionMailer::Base
	default from: "from@example.com"
	
	#Title:			competition_link
	#Description:	Sends creator the link to their competition
	#Params:		competition - Competition that was created
	def competition_link(competition)
		creator = User.find_by_id(competition.creator_id)
		scope = competition.scope
		
		@competition_name = competition.name
		@creator_name = creator.firstname.strip.capitalize
		@invitation_url = SITE_URL+'competitions/'+competition.id.to_s+'/?code='+competition.invitation_code
		if (scope==COMPETITION_SCOPE[:CYCLINGTIPS])
			race_id = competition.race_id
			invitation_data = InvitationEmailTarget.where({:race_id=>race_id, :scope=>scope}).first
			if (!invitation_data.nil?)
				connector = (invitation_data.target.include?'?')?'&':'?'
				@invitation_url = invitation_data.target + connector + 'competition_id='+competition.id.to_s + '&code=' + competition.invitation_code
			end
		end
		
		mail(:to => creator.email, :subject => "Competition created.")
	end
  
	#Title:			competition_invitation
	#Description:	Invite a user to a competition
	#Params:		emails - Comma delimited list of email addresses
	#				competition - Competition to invite to
	def competition_invitation(emails, competition, scope)
		return if (emails.nil? || emails.strip.length==0)
		creator = User.find_by_id(competition.creator_id)
		@competition = competition
		@invitor_name = (creator.firstname.strip.capitalize+' '+creator.lastname.strip.capitalize).strip
		@invitation_url = SITE_URL+'competitions/'+competition.id.to_s+'/?code='+competition.invitation_code
		if (scope==COMPETITION_SCOPE[:CYCLINGTIPS])
			race_id = @competition.race_id
			invitation_data = InvitationEmailTarget.where({:race_id=>race_id, :scope=>scope}).first
			if (!invitation_data.nil?)
				connector = (invitation_data.target.include?'?')?'&':'?'
				@invitation_url = invitation_data.target + connector + 'competition_id='+competition.id.to_s + '&code=' + competition.invitation_code
			end
		end
		
		mail(:to => emails, :subject => "Invitation for competition.")
	end
	
	#Title:			send_tip_default_email
	#Description:	Notifies a user that a default tip was used. Also checks if the default tip invalidates a future tip.
	#Params:		tip - CompetitionTip object containing default rider.
	def send_tip_default_email(tip)
		result = Result.where({:season_stage_id=>tip.stage_id, :rider_id=>tip.rider_id}).first
		
		@competition = Competition.find_by_id(tip.competition_id)
		@stage = Stage.find_by_id(tip.stage_id)
		@selected_rider = Rider.find_by_id(tip.rider_id)
		@disqualification_status = Result.rider_status_to_str(result.rider_status)
		@default_rider = Rider.find_by_id(tip.default_rider_id)
		
		#Find stage that has used the default rider
		invalid_tip = CompetitionTip.where({:competition_participant_id=>tip.competition_participant_id, :rider_id=>@default_rider.id, :status=>STATUS[:ACTIVE]}).first
		@invalid_stage = Stage.find_by_id(invalid_tip.stage_id) if (!invalid_tip.nil?)
		
		user = User.find_by_id(tip.competition_participant_id)
		mail(:to=>user.email, :subject=>'Competition tip defaulted.')
	end
	
	#Title:			send_welcome_email_from_facebook
	#Description:	Sends a user who signed up from Facebook a welcome email
	#Params:		data - Array
	def send_welcome_email_from_facebook(data)
		email = data[:email]
		@name = data[:firstname]
		@password = data[:password]
		
		mail(:to=>email, :subject=>'Welcome to Racetipper.')
	end
	
	#Title:			password_changed
	#Description:	Notify a user that their password has changed
	#Params:		user - User object
	def password_changed(user)
		email = user.email
		@name = user.firstname
		
		mail(:to=>email, :subject=>'Password change notification.')
	end
	
	#Title:			temporary_password_created
	#Description:	Notify a user that they have a temporary password
	#Params:		user - User object
	#				password - Unencrypted password
	def temporary_password_created(user, password)
		email = user.email
		@name = user.firstname
		@password = password
		
		mail(:to=>email, :subject=>'Temporary password.')
	end
	
	#Title:			submit_bug_report
	#Description:	Submit bug report to BUG_NOTIFY_LIST
	#Params:		title - Bug title
	#				description - Bug body
	def submit_bug_report(title, description)
		@title = title
		@description = description
		
		mail(:to=>BUG_NOTIFY_LIST, :subject=>@title)
	end
	
	#Title:			global_race_admin_notify
	#Description:	Notify administrators that a global race has been created
	#Params:		competition_id - Competition ID
	#				user_count - Count of users that qualify for invitations
	#				invitation_count - Count of users actually invited
	def global_race_admin_notify(competition_id, user_count, invitation_count)
		competition = Competition.find_by_id(competition_id)
		@competition_url = SITE_URL+'#competitions/'+competition_id.to_s
		@competition_name = competition.name
		@user_count = user_count
		@invitation_count = invitation_count
		
		mail(:to=>BUG_NOTIFY_LIST, :subject=>'Global competition created')
	end
	
end
