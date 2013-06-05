class PagesController < ApplicationController
	
	#Title:			index
	#Description:	Load layout
	def index
		redirect_to :action=>'home' and return if (!@user.nil?)
		render :layout => 'no_user'
	end
		
	#Title:			home
	#Description:	Home page
	def home
		redirect_to :root and return if (@user.nil?)
		@invitations = CompetitionInvitation.get_user_invitations(@user.id)
		@races = Race.where({:status=>STATUS[:ACTIVE]}).order('id DESC').limit(3)
	end
	
	#Title:			login
	#Description:	Login
	def login
		render :layout => nil
	end
	
	#Title:			about
	#Description:	About us
	def about
		render :layout => nil
	end
end
