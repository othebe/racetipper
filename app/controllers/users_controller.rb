class UsersController < ApplicationController
	def create
		data = params[:data]
		render :json=>{:success=>false, :msg=>'There was an error. Please refresh and try again.'} and return if (!params.has_key?(:data))
		render :json=>{:success=>false, :msg=>'First name is required.'} and return if (!data.has_key?(:firstname) || data[:firstname].empty?)
		render :json=>{:success=>false, :msg=>'Email is required.'} and return if (!data.has_key?(:email) || data[:email].empty?)
		render :json=>{:success=>false, :msg=>'Password is required.'} and return if (!data.has_key?(:password) || data[:password].empty?)
		
		#Check if user exists
		existing = User.find_by_email(data[:email].downcase)
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
			email = fb_user.email.trim.downcase
			
			#Check if user exists by Facebook ID
			user = User.find_by_fb_id(fb_id)
			user = User.find_by_email(email) if (user.nil?)
				
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
		redirect_to :root if (@user.nil?)
	end
	
	def logout
		session.delete(:user)
		redirect_to :root
	end
	
	#Title:			save_information
	#Description:	Saves information about a user
	def save_information
		#Is user logged in?
		render :json=>{:success=>false, :msg=>'User not logged in.'} and return if @user.nil?
		
		#Check information
		render :json=>{:success=>false, :msg=>'Data error. Please refresh the page and try again.'} and return if (!params.has_key?(:information))
		
		#Set user information
		params[:information].each do |keyval|
			@user[(keyval[0].to_sym)] = keyval[1]
		end
		@user.save
		
		#Change password?
		if (params.has_key?(:password))
			if (!params[:password][:old_password].empty? || !params[:password][:new_password].empty?)
				#Check old password
				user = User.check_credentials({:email=>@user.email, :password=>params[:password][:old_password]})
				render :json=>{:success=>false, :msg=>'Your old password does not match.'} and return if user.nil?
				
				@user.set_password(params[:password][:new_password])
				
				render :json=>{:success=>true, :msg=>'Password changed.'} and return
			end
		end
		
		render :json=>{:success=>true, :msg=>'Information saved.'}
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
	
	#Title:			picture
	#Description:	Get profile picture
	def picture
		id = params.has_key?(:id)?params[:id]:nil
		
		redirect_to '/assets/default_user.jpg' and return if id.nil?
		
		user = User.find_by_id(id)
		
		#User picture
		if (!user.nil? && !user.fb_id.nil?)
			redirect_to 'https://graph.facebook.com/'+user.fb_id.to_s+'/picture?type=square' and return
		else
			redirect_to '/assets/default_user.jpg' and return
		end
	
		render :text=>id
	end
	
	#Title:			change_password
	#Description:	Change password for current user
	private
	def change_password(old_password, new_password)
		#Check old password
		user = User.check_credentials({:email=>@user.email, :password=>old_password})
		render :json=>{:success=>false, :msg=>'Your old password does not match.'} and return if user.nil?
		
		@user.set_password(password)
		
		render :json=>{:success=>true, :msg=>'Password changed.'} and return
	end
	
	###############################
	# Cyclingtips.com integration #
	
	#Title:			login_with_token
	#Description:	Takes user information and an access token, and authenticate the matched user. New user is created is no user found.
	public
	def login_with_token
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
			password  =  (0...10).map{ pw_base[rand(pw_base.length)] }.join
			@user = User.create_new_user({
				:firstname => params[:firstname],
				:lastname => params[:lastname],
				:email => params[:email],
				:password => password
			})
		end
		
		session[:user] = @user if (!@user.nil?)
		
		render :json=>{:success=>true, :msg=>'Success', :data=>nil}
	end
	
end
