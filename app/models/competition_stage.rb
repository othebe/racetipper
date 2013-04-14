class CompetitionStage < ActiveRecord::Base
  attr_accessible :competition_id, :stage_id, :race_id
  
  belongs_to :stage
  belongs_to :race
end
