class CompetitionStage < ActiveRecord::Base
  attr_accessible :competition_id, :stage_id
  
  belongs_to :stage
end
