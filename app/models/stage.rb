class Stage < ActiveRecord::Base
  attr_accessible :description, :image_url, :name, :profile, :race_id
  
  belongs_to :race
end
