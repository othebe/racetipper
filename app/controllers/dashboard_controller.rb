class DashboardController < ApplicationController
	def index
		render :layout=>'dashboard'
	end
	
	def show_competitions
		render :layout=>false
	end
end
