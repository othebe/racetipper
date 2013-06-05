class Article < ActiveRecord::Base
  attr_accessible :author, :body, :title, :type
  
  has_many :ArticleLinks
  
	#Get articles for a competition's stages
	def self.get_articles_for_competition(competition_id)
		data = []
		stages = CompetitionStage.select(:stage_id).where(:competition_id=>competition_id, :status=>STATUS[:ACTIVE]).order(:stage_id)
		stages.each do |stage|
			articles = Article.where(:stage_id=>stage.stage_id)
			articles.each do |article|
				data.push(article)
			end
		end
		return data
	end
end
