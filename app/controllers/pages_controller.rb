class PagesController < ApplicationController
	
	#Title:			index
	#Description:	Load layout
	def index
	end
		
	#Title:			home
	#Description:	Home page
	def home
		carousel_stages = Stage.order('starts_on DESC').limit(2)
		carousel_competitions = Competition.order('creator_id, created_at DESC').limit(1)
		carousel_races = Race.order('created_at DESC').limit(1)
		
		#Add carousel slides
		@carousel_slides = []
		carousel_stages.each {|data| @carousel_slides.push({:image=>data.image_url, :title=>data.name, :description=>data.description})}
		carousel_competitions.each {|data| @carousel_slides.push({:image=>data.image_url, :title=>data.name, :description=>data.description})}
		carousel_races.each {|data| @carousel_slides.push({:image=>data.image_url, :title=>data.name, :description=>data.description})}
		
		@articles = Article.order('created_at DESC').limit(1)
		
		render :layout => nil
	end
	
	#Title:			login
	#Description:	Login
	def login
		render :layout => nil
	end
end
