class InvitationEmailTarget < ActiveRecord::Base
	attr_accessible :race_id, :scope, :target
	
	#Title:			get_base_url
	#Description:	Gets the target URL given a raceID and scope
	def self.get_base_url(race_id, scope)
		base_url = SITE_URL
		
		row = self.where({:race_id=>race_id, :scope=>scope}).first
		base_url = row.target if (!row.nil?)
		
		return base_url
	end
end
