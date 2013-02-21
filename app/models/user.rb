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
		user.email = data[:email]
		user.salt = salt
		user.password = enc_password
		user.last_activity = Time.now.to_datetime
		user.fb_id = data[:fb_id] if (!data[:fb_id].nil?)
		user.fb_access_token = data[:fb_access_token] if (!data[:fb_access_token].nil?)
		user.save
		
		return self.find_by_id(user.id)
	end
	
	#Title:			check_credentials
	#Description:	Checks to see if a username/password (unencrypted) matches any user
	#Params:		data - Array of email and password
	def self.check_credentials(data)
		user = self.find_by_email(data[:email])
		return nil if (user.nil?)
		
		enc_password = Digest::SHA1.hexdigest(user.salt+data[:password])
		if (enc_password==user.password)
			return user
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
end
