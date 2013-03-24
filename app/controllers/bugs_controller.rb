class BugsController < ApplicationController
	#Title:			reedback
	#Description:	Leave feedback
	def feedback
		render :layout=>nil
	end
	
	
	
	######## POST ###########
	
	#Title:			submit_feedback
	#Description:	Submit feedback and send email
	#Params:		title - Title
	#				description - Description
	def submit_feedback
		title = ''
		title = params[:title] if (params.has_key?(:title))
		render :json=>{:success=>false, :msg=>'Please enter a title.'} and return if (title.empty?)
		
		description = ''
		description = params[:description] if (params.has_key?(:description))
		render :json=>{:success=>false, :msg=>'Please enter a description.'} and return if (description.empty?)
		
		AppMailer.submit_bug_report(title, description).deliver
		
		render :json=>{:success=>true, :msg=>'Thank you for your feedback.'}
	end
end
