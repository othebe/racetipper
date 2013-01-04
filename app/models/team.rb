class Team < ActiveRecord::Base
  attr_accessible :name, :season_id
  
  belongs_to :rider
end
