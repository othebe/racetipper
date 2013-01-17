class DashboardController < ApplicationController
	def index
		render :layout=>'dashboard'
	end
	
	def show_competitions
		uid = 0
		options = {}
		if (!@user.nil?)
			uid = @user.id
			options[:limit] = 9
		else
			options[:limit] = 10
		end
		competition_list = Competition.get_competitions(uid, options)
		@competitions = []
		competition_list.each do |competition|
			data = {}
			data[:competition] = competition
			if (@user.nil?)
				data[:is_participant] = false
			else
				is_participant = CompetitionParticipant.where('competition_id=? AND user_id=?', competition.id, @user.id)
				data[:is_participant] = !is_participant.empty?
			end
			@competitions.push(data)
		end
		render :layout=>false
	end
	
	def show_season_info
		current_season = Season.find_by_year(Time.now.year)
		@races = Race.where({:season_id=>current_season.id, :status=>STATUS[:ACTIVE]})
		render :layout=>false
	end
	
	def show_profile		
		@user_image = '/assets/default_user.jpg'
		@user_rank = User.get_rank(@user.id)
		
		#Get quote
		quote_count = CyclingQuote.count
		offset = rand(quote_count)
		@quote = CyclingQuote.first(:offset=>offset)
		
		#Get competitions
		@competitions = Competition.where({:creator_id=>@user.id})
		
		render :layout=>false
	end
end
