class ApplicationController < ActionController::Base
  protect_from_forgery
  before_filter :check_user
  
  private
  def check_user
	@user = nil
	@user = session['user'] if (session.has_key?(:user))
	
	#Is user on a temporary password?
	if (!@user.nil? && !@user.temp_password.nil?)
		#Redirect to the change temporary password page
		allowed = 
			(params[:controller]=='users' && params[:action]=='change_temp_password') ||
			(params[:controller]=='users' && params[:action]=='change_password') ||
			(params[:controller]=='users' && params[:action]=='logout')
			
		redirect_to '/users/change_temp_password' if (!allowed)
	end
	
	#User picture
	if (!@user.nil? && !@user.fb_id.nil?)
		@user_img = 'https://graph.facebook.com/'+@user.fb_id.to_s+'/picture?type=square'
	else
		@user_img = '/assets/default_user.jpg'
	end
	
	#Invite user to competitions if any
	if (!@user.nil? && session.has_key?(:invited_competitions) && !session[:invited_competitions].empty?)
		session[:invited_competitions].each do |competition_id|
			CompetitionParticipant.add_participant(@user.id, competition_id)
		end
		session.delete(:invited_competitions)
	end
  end
end
