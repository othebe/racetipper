class UsersController < ApplicationController
	def create
		data = params[:data]
		render :json=>{:success=>false, :msg=>'There was an error. Please refresh and try again.'} and return if (!params.has_key?(:data))
		render :json=>{:success=>false, :msg=>'First name is required.'} and return if (!data.has_key?(:firstname) || data[:firstname].empty?)
		render :json=>{:success=>false, :msg=>'Email is required.'} and return if (!data.has_key?(:email) || data[:email].empty?)
		render :json=>{:success=>false, :msg=>'Password is required.'} and return if (!data.has_key?(:password) || data[:password].empty?)
		
		#Check if user exists
		existing = User.find_by_email(data[:email])
		render :json=>{:success=>false, :msg=>'This email has already been registered.'} and return if (!existing.nil?)
		
		userdata = {}
		userdata[:firstname] = data[:firstname]
		userdata[:lastname] = data[:lastname]
		userdata[:email] = data[:email]
		userdata[:password] = data[:password]
		
		user = User.create_new_user(userdata)
		session['user'] = user
		
		render :json=>{:success=>true, :msg=>'success'} and return
	end
	
	def login
		data = params[:data]
		render :json=>{:success=>false, :msg=>'There was an error. Please refresh and try again.'} and return if (!params.has_key?(:data))
		
		userdata = {}
		userdata[:email] = data[:email]
		userdata[:password] = data[:password]
		
		user = User.check_credentials(userdata)
		render :json=>{:success=>false, 'msg'=>'Incorrect email/password combination.'} and return if (user.nil?)
		
		session['user'] = user
		render :json=>{:success=>true, :msg=>'success'}
	end
	
	#Title:			login_with_facebook
	#Description:	Logs a user in w/their Facebook account
	def login_with_facebook
		access_token = params[:access_token]
		
		#url = 'https://graph.facebook.com/me?access_token='+access_token
		begin
			fb_user = FbGraph::User.fetch('me', :access_token=>access_token)
			fb_id = fb_user.identifier
			email = fb_user.email
			
			#Check if user exists
			user = User.find_by_fb_id(fb_id)
				
			#Create new user
			if (user.nil?)
				userdata = {}
				userdata[:firstname] = fb_user.first_name
				userdata[:lastname] = fb_user.last_name
				userdata[:email] = email
				userdata[:password] = User.generate_password
				userdata[:fb_id] = fb_user.identifier
				userdata[:fb_access_token] = access_token
				
				user = User.create_new_user(userdata)
			else
				#Update Facebook info
				user.fb_id = fb_user.identifier
				user.fb_access_token = access_token
				user.save
			end
			
			#Log user in
			user.temp_password = nil
			session['user'] = user
			
			render :json=>{:success=>true, :msg=>'success'} and return
			
		rescue
			render :json=>{:success=>false, :msg=>'There was an error. Refresh the page and try again.'} and return
		end
	end
	
	#Title:			link_fb_to_user
	#Description:	Links a Facebook account to a user
	def link_fb_to_user
		render :json=>{:success=>false, :msg=>'User not logged in.'} and return if @user.nil?

		access_token = params[:access_token]
		
		#url = 'https://graph.facebook.com/me?access_token='+access_token
		begin
			fb_user = FbGraph::User.fetch('me', :access_token=>access_token)
			fb_id = fb_user.identifier
			email = fb_user.email
			
			#Check if user exists by email
			user = User.find_by_email(email)
			render :json=>{:success=>false, :msg=>'An account already exists under your Facebook email.'} and return if (!user.nil? && user.id!=@user.id)
			
			#Check if user exists by Facebook ID
			user = User.find_by_fb_id(fb_id)
			render :json=>{:success=>false, :msg=>'An account already exists under this Facebook account.'} and return if (!user.nil? && user.id!=@user.id)
			
			@user.fb_id = fb_id
			@user.fb_access_token = access_token
			
			@user.save
			session['user'] = @user
			
			render :json=>{:success=>true, :msg=>'success'} and return
			
		rescue
			render :json=>{:success=>false, :msg=>'There was an error. Refresh the page and try again.'} and return
		end
	end
	
	#Title:			change_temp_password
	#Description:	Change temporary password
	def change_temp_password
	end
	
	#Title:			forgot_password
	#Description:	Ask a user for their email to reset password
	def forgot_password
		
	end
	
	#Title:			settings
	#Description:	User settings
	def settings
	end
	
	def logout
		session.delete(:user)
		redirect_to :root
	end
	
	#Title:			change_password
	#Description:	Change password for current user
	def change_password
		#Is user logged in?
		render :json=>{:success=>false, :msg=>'User not logged in.'} and return if @user.nil?
		
		#Is password empty?
		password = params[:password]
		render :json=>{:success=>false, :msg=>'Password cannot be empty.'} and return if password.empty?
		
		@user.set_password(password)
		
		render :json=>{:success=>true, :msg=>'success'} and return
	end
	
	#Title:			reset_password
	#Description:	Generate new temporary password and mail it for current user
	def reset_password
		#Is user logged in?
		render :json=>{:success=>false, :msg=>'User not logged in.'} and return if @user.nil?
		
		@user.set_temp_password()
		
		render :json=>{:success=>true, :msg=>'Temporary password mailed to '+@user.email} and return
	end
	
	#Title:			reset_password_from_email
	#Description:	RGenerate new temporary password and mail it for user account belonging to email
	def reset_password_from_email
		email = params[:email]
		user = User.find_by_email(email)
		
		render :json=>{:success=>false, :msg=>'Email was not found.'} and return if user.nil?
		
		user.set_temp_password()
		
		render :json=>{:success=>true, :msg=>'Temporary password mailed to '+user.email} and return
	end
	
	#Title:			change_time_zone
	#Description:	Change a user's time zone
	def change_time_zone
		#Is user logged in?
		render :json=>{:success=>false, :msg=>'User not logged in.'} and return if @user.nil?
		
		@user.time_zone = params[:time_zone]
		@user.save
		
		render :json=>{:success=>true, :msg=>'success'} and return
	end
end
