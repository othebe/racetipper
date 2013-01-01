class Competition < ActiveRecord::Base
  attr_accessible :creator_id, :description, :image_url, :name, :season_id
end
