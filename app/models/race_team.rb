class RaceTeam < ActiveRecord::Base
	attr_accessible :race_id, :status, :team_id
	
	belongs_to :team
end
