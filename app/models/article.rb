class Article < ActiveRecord::Base
  attr_accessible :author, :body, :title, :type
  
  has_many :ArticleLinks
end
