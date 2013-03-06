class ArticlesController < ApplicationController
	def read
		redirect_to :root if (!params.has_key?(:id))
		
		@article = Article.find_by_id(params[:id])
		@links = @article.ArticleLinks
		
		render :layout=>'blank'
	end
end
