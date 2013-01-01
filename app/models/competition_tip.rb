class CompetitionTip < ActiveRecord::Base
  attr_accessible :competition_participant_id, :rider_id, :season_stage_id
end
