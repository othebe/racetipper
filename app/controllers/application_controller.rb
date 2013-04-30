class ApplicationController < ActionController::Base
  protect_from_forgery
  before_filter :check_user
  before_filter :init_vars
  
  private
  def check_user
	@user = nil
	@user = session['user'] if (session.has_key?(:user))
	
	#User picture
	if (!@user.nil? && !@user.fb_id.nil?)
		@user_img = 'https://graph.facebook.com/'+@user.fb_id.to_s+'/picture?type=square'
	else
		@user_img = '/assets/default_user.jpg'
	end
	
	#User display name
	if (!@user.nil? && (@user.display_name.nil? || @user.display_name.empty?))
		@user[:display_name] = (@user.firstname+' '+@user.lastname).strip
	end
	
	#Invite user to competitions if any
	if (!@user.nil? && session.has_key?(:invited_competitions) && !session[:invited_competitions].empty?)
		session[:invited_competitions].each do |competition_id|
			CompetitionParticipant.add_participant(@user.id, competition_id)
		end
		session.delete(:invited_competitions)
	end
  end
  
	#Title:		init_vars
	#Description:	Initialize variables
	def init_vars
		current_season = Season.find_by_year(Time.now.year)
		@sidebar_races ||= Race.where({:status=>STATUS[:ACTIVE], :season_id=>current_season.id}).order('id DESC').limit(10)
		
		if (@user.nil?)
			@sidebar_competitions ||= Competition.where({:status=>STATUS[:ACTIVE], :is_complete=>false}).order('created_at DESC').limit(5)
		else
			@sidebar_competitions ||= Competition.get_competitions(@user.id, {:limit=>5})
		end
		#@sidebar_races ||= Rails.cache.fetch('races') do
		#	Race.where({:status=>STATUS[:ACTIVE], :season_id=>current_season.id}).order('id DESC').limit(10)
		#end
	end
end
