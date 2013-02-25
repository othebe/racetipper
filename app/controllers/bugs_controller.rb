class BugsController < ApplicationController
	#Title:			report
	#Description:	Report a bug
	def report
	end
	
	
	
	######## POST ###########
	
	#Title:			submit_bug
	#Description:	Save bug and send email
	#Params:		title - Bug title
	#				description - Bug description
	def submit_bug
		title = ''
		title = params[:title] if (params.has_key?(:title))
		render :json=>{:success=>false, :msg=>'Please enter a title for this bug.'} and return if (title.empty?)
		
		description = ''
		description = params[:description] if (params.has_key?(:description))
		render :json=>{:success=>false, :msg=>'Please enter a description for this bug.'} and return if (description.empty?)
		
		AppMailer.submit_bug_report(title, description).deliver
		
		render :json=>{:success=>true, :msg=>'Bug submitted. You may close this page now.'}
	end
end
