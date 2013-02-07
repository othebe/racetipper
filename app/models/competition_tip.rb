class CompetitionTip < ActiveRecord::Base
	attr_accessible :competition_participant_id, :rider_id, :season_stage_id
  
	#Title:			find_default_rider
	#Description:	Finds the next available default rider for this user in this competition's race
	def find_default_rider()
		default_riders = DefaultRider.where({:race_id=>self.race_id, :status=>STATUS[:ACTIVE]}).order('order_id')
		default_riders.each do |default_rider|
			checker = self.dup
			checker.rider_id = default_rider.rider_id
			return checker.rider_id if (!checker.is_duplicate({:SCOPE_PAST_TIPS=>1}))
		end
	end
	
	#Title:			is_duplicate
	#Description:	Determines if the user's tip has already been selected
	#Params:		options - Hash
	#					:SCOPE_PAST_TIPS - Only check past tips
	def is_duplicate(options={})
		conditions = {
			:competition_participant_id => self.competition_participant_id,
			:competition_id => self.competition_id,
			:race_id => self.race_id
		}
		conditions[:status] = STATUS[:INACTIVE] if (!options[:SCOPE_PAST_TIPS].nil?)
		
		duplicate = false
		tips = CompetitionTip.where(conditions)
		tips.each do |tip|
			next if (duplicate)
			if (tip.rider_id==self.rider_id || tip.default_rider_id==self.rider_id)
				duplicate = (tip.id != self.id)
				next if (duplicate)
			end
		end
		
		logger.debug('NOT DUPLICATE') if (!duplicate)
		logger.debug(self.inspect) if (!duplicate)
	
		return duplicate
	end
end
