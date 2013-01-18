class ApplicationController < ActionController::Base
  protect_from_forgery
  before_filter :check_user
  
  private
  def check_user
	@user = nil
	@user = session['user'] if (session.has_key?(:user))
	
	#Invite user to competitions if any
	if (!@user.nil? && session.has_key?(:invited_competitions) && !session[:invited_competitions].empty?)
		session[:invited_competitions].each do |competition_id|
			CompetitionParticipant.add_participant(@user.id, competition_id)
		end
		session.delete(:invited_competitions)
	end
  end
end
