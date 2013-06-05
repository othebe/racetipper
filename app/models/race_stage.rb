class RaceStage < ActiveRecord::Base
  attr_accessible :race_id, :stage_id
  belongs_to :stage
  belongs_to :race
end
