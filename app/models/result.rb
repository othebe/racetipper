class Result < ActiveRecord::Base
  attr_accessible :kom_points, :rider_id, :season_stage_id, :sprint_points, :time
  
  belongs_to :rider
end
