class CronController < ApplicationController
	
	#Title:			send_tip_default_emails
	#Description:	Sends emails telling users that their tips have changed
	def send_tip_default_emails
		#Get all tips requiring notifications
		notifies = CompetitionTip.where({:notification_required=>true}).limit(100)
		
		notifies.each do |notify|
			next if (notify.default_rider_id.nil?)
			
			#Send emails
			AppMailer.send_tip_default_email(notify).deliver
			
			#Mark as sent
			notify.notification_required = false
			notify.save
		end
		
		render :text=>'done'
	end
end
