class UsersController < ApplicationController
	def create
		data = params[:data]
		render :json=>{:success=>false, :msg=>'There was an error. Please refresh and try again.'} and return if (!params.has_key?(:data))
		render :json=>{:success=>false, :msg=>'First name is required.'} and return if (!data.has_key?(:firstname) || data[:firstname].empty?)
		render :json=>{:success=>false, :msg=>'Email is required.'} and return if (!data.has_key?(:email) || data[:email].empty?)
		render :json=>{:success=>false, :msg=>'Password is required.'} and return if (!data.has_key?(:password) || data[:password].empty?)
		
		#Check if user exists
		existing = User.find_by_email(data[:email])
		render :json=>{:success=>false, :msg=>'User already exists.'} and return if (!existing.nil?)
		
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
	
	def logout
		session.delete(:user)
		redirect_to :root
	end
end
