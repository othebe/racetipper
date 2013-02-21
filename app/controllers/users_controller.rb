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
	
	#Title:			settings
	#Description:	User settings
	def settings
	end
	
	def logout
		session.delete(:user)
		redirect_to :root
	end
end
