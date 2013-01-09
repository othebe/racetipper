class DashboardController < ApplicationController
	def index
		render :layout=>'dashboard'
	end
	
	def show_competitions
		competition_list = Competition.where('status=?', STATUS[:ACTIVE])
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
		@races = Race.where({:season_id=>current_season.id})
		render :layout=>false
	end
end
