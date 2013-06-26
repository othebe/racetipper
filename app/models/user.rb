class User < ActiveRecord::Base
	attr_accessible :email, :firstname, :last_activity, :lastname, :password, :salt
	require 'digest'
	
	#Title:			create_new_user
	#Description:	Create a new user
	#Params:		data - Array of fields for user
	def self.create_new_user(data)
		#Generate salt
		base =  [('a'..'z'),('A'..'Z')].map{|i| i.to_a}.flatten
		salt  =  (0...50).map{ base[rand(base.length)] }.join
		
		enc_password = Digest::SHA1.hexdigest(salt+data[:password])
		user = self.new
		user.firstname = data[:firstname]
		user.lastname = data[:lastname]
		user.email = data[:email].strip.downcase
		user.salt = salt
		user.password = enc_password
		user.last_activity = Time.now.to_datetime
		user.fb_id = data[:fb_id] if (!data[:fb_id].nil?)
		user.fb_access_token = data[:fb_access_token] if (!data[:fb_access_token].nil?)
		user.display_name = (user.firstname+' '+(user.lastname||'')).strip
		
		#Send welcome emails
		if (data[:fb_id].nil?)
			#Manual signup
		else
			#Facebook signup
			AppMailer.send_welcome_email_from_facebook(data).deliver
		end
		
		user.save
		
		return self.find_by_id(user.id)
	end

	#Title:			set_password
	#Description:	Sets user password and salt
	#Params:		password - User password
	def set_password(password) 
		#Generate salt
		base =  [('a'..'z'),('A'..'Z')].map{|i| i.to_a}.flatten
		salt  =  (0...50).map{ base[rand(base.length)] }.join
		
		enc_password = Digest::SHA1.hexdigest(salt+password)
		
		self.salt = salt
		self.password = enc_password
		self.temp_password = nil
		self.save
	end
	
	#Title:			set_temp_password
	#Description:	Sets temporary user password using existing salt
	#Params:		password - User password
	def set_temp_password() 
		#Generate new password
		password = User.generate_password()
		
		salt = self.salt
		enc_password = Digest::SHA1.hexdigest(salt+password)
		
		self.temp_password = enc_password
		self.save
		
		#Ignore temp password if user is already logged in
		self.temp_password = nil
		
		#Notify user
		AppMailer.temporary_password_created(self, password).deliver
	end
	
	#Title:			check_credentials
	#Description:	Checks to see if a username/password (unencrypted) matches any user
	#Params:		data - Array of email and password
	def self.check_credentials(data)
		user = self.find_by_email(data[:email].strip.downcase)
		
		return nil if (user.nil?)
		
		enc_password = Digest::SHA1.hexdigest(user.salt+data[:password])
		
		#Logged in with regular password
		if (enc_password == user.password)
			return user
		#Logged in with temporary password
		elsif (enc_password == user.temp_password)
			user.set_password(data[:password])
			return user
		#No user found
		else
			return nil
		end
	end
	
	#Title:			get_user_rank
	#Description:	Gets user rank string
	def self.get_rank(user_id)
		rank = 'Just starting out.'
		
		return rank
	end
	
	#Title:			generate_password
	#Description:	Generate a random password
	def self.generate_password(len=10)
		#Generate salt
		base =  [('a'..'z'),('A'..'Z')].map{|i| i.to_a}.flatten
		password  =  (0...len).map{ base[rand(base.length)] }.join
		
		return password
	end
	
	#Title:			add_to_global_competition
	#Description:	Adds a user to open global competitions
	def add_to_global_competition
		return if (!self.in_grand_competition)
		
		competitions = Competition.where({:status=>STATUS[:ACTIVE], :is_complete=>false, :competition_type=>COMPETITION_TYPE[:GLOBAL]})
		competitions.each do |competition|
			CompetitionParticipant.add_participant(self.id, competition.id)
		end
	end
end
