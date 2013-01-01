class Stage < ActiveRecord::Base
  attr_accessible :description, :image_url, :name, :profile
  
  belongs_to :race
end
