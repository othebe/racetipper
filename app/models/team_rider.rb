class TeamRider < ActiveRecord::Base
  attr_accessible :display_name, :rider_id, :team_id
  belongs_to :rider
end
