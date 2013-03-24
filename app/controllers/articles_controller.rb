class ArticlesController < ApplicationController
	#Title:			index
	#Description:	Index page for articles
	def index
		render :layout => nil
	end
	
	def read
		redirect_to :root if (!params.has_key?(:id))
		
		@article = Article.find_by_id(params[:id])
		@links = @article.ArticleLinks
		
		render :layout=>'blank'
	end
end
