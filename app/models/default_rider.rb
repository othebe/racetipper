class DefaultRider < ActiveRecord::Base
	attr_accessible :order_id, :race_id, :rider_id, :season_id
	belongs_to :rider
	
	#Title:			get_default_riders
	#Description:	Gets default riders for a race. If competition_id and user_id are provided, also check for validity.
	#Params:		race_id - Race ID
	#				competition_id - Competition ID
	#				user_id - User ID
	def self.get_default_riders(race_id, competition_id=nil, user_id=nil)
		default_riders = []
		records = self.where({:race_id=>race_id}).order('order_id')
		ndx = 1
		records.each do |default_rider|
			rider_id = default_rider.rider_id
			valid_str = 'allowed'
			valid = (default_rider.status==RIDER_RESULT_STATUS[:ACTIVE])
			
			#Check disqualification status
			if (!valid)
				valid_str = 'DNS' if (default_rider.status==RIDER_RESULT_STATUS[:DNS])
				valid_str = 'DNF' if (default_rider.status==RIDER_RESULT_STATUS[:DNF])
			#Check validity
			elsif (!competition_id.nil? && !user_id!=nil?)
				tip = CompetitionTip.where('competition_participant_id=? AND competition_id=? AND (rider_id=? OR default_rider_id=?)', user_id, competition_id, rider_id, rider_id).first
				valid = (tip.nil?)
				if (!valid)
					stage = Stage.find_by_id(tip.stage_id)
					valid_str = stage.name
				end
			end
			
			default_riders.push({
				:rider_id => rider_id,
				:rider_name => default_rider.rider.name,
				:valid => valid,
				:valid_str => valid_str,
				:ndx => ndx
			})
			
			ndx += 1
		end
		
		return default_riders
	end
end
