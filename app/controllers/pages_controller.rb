class PagesController < ApplicationController
	
	#Title:			index
	#Description:	Load layout
	def index
	end
		
	#Title:			home
	#Description:	Home page
	def home
		@articles = Article.order('created_at DESC').limit(1)
		
		render :layout => nil
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
