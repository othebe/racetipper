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
		@invitations = CompetitionInvitation.get_user_invitations(@user.id, @scope)
		@races = Race.where({:status=>STATUS[:ACTIVE]}).order('id DESC').limit(3)

		Race.class_eval { attr_accessor :has_join_any }

		@races.each do |race|
			race.has_join_any = !CompetitionParticipant.get_participated_competitions(@user.id, race.id, @scope).empty?
		end
	end
	
	#Title:			safari_fix
	#Description:	Must visit a page in safari to store cookies
	def safari_fix
		if (params.has_key?(:redirect))
			url = params[:redirect]
			url += (url.include?('?'))?'&':'?'
			url += 'safari_fix=true'
		else
			url = :root
		end
		
		redirect_to url and return
	end
	
	#Title:			about_us
	#Description:	About us
	def about
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
