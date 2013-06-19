class ApplicationController < ActionController::Base
	protect_from_forgery
	before_filter :check_user
	before_filter :init_vars
	before_filter :set_iframe_data

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
  
	#Title:			init_vars
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
	
	
	################### IFrame embedding stuff ###########################
	
	#Title:			login_with_token
	#Description:	Takes user information and an access token, and authenticate the matched user. New user is created is no user found.
	def login_with_token
		if (params.has_key?(:pid))
			#Check email
			render :json=>{:success=>false, :msg=>'email field is missing.'} and return if (!params.has_key?(:email))
			render :json=>{:success=>false, :msg=>'Email cannot be empty.'} and return if (params[:email].empty?)
			
			#Check partner ID
			render :json=>{:success=>false, :msg=>'pid field is missing.'} and return if (!params.has_key?(:pid))
			render :json=>{:success=>false, :msg=>'Partner ID cannot be empty.'} and return if (params[:pid].empty?)
			
			#Check partner access token
			partner_access_token = PARTNER_ACCESS_TOKEN[params[:pid].upcase.to_sym]
			render :json=>{:success=>false, :msg=>'Invalid pid.'} and return if (partner_access_token.nil?)
			
			#Check key
			render :json=>{:success=>false, :msg=>'key field is missing.'} and return if (!params.has_key?(:key))
			render :json=>{:success=>false, :msg=>'Key cannot be empty.'} and return if (params[:key].empty?)
			render :json=>{:success=>false, :msg=>'Invalid key.'} and return if (Digest::SHA1.hexdigest(params[:email]+partner_access_token) != params[:key])
			
			#Find user
			@user = User.find_by_email(params[:email])
			
			#Create new user if no user found
			if (@user.nil?)
				#Check firstname
				render :json=>{:success=>false, :msg=>'firstname field is missing.'} and return if (!params.has_key?(:firstname))
				render :json=>{:success=>false, :msg=>'Firstname cannot be empty.'} and return if (params[:firstname].empty?)
			
				pw_base = [('a'..'z'),('A'..'Z')].map{|i| i.to_a}.flatten
				password  =  (0...10).map{ base[rand(base.length)] }.join
				@user = User.create_new_user({
					:firstname => params[:firstname],
					:lastname => params[:lastname],
					:email => params[:email],
					:password => password
				})
			end
			
			session[:user] = @user if (!@user.nil?)
			return true
		end
		return true
	end
	
	#Title:			set_iframe_data
	#Description:	Gets iframe params if any and sets the layout
	def set_iframe_data
		@iframe_params = ''
		@iframe_params += ('pid=' + params[:pid]) if (params.has_key?(:pid))
		@iframe_params += ('&email=' + params[:email]) if (params.has_key?(:email))
		@iframe_params += ('&key=' + params[:key]) if (params.has_key?(:key))
		@iframe_params += ('&display=' + params[:display]) if (params.has_key?(:display))
	end
end
