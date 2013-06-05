class CompetitionTip < ActiveRecord::Base
	attr_accessible :competition_participant_id, :rider_id, :season_stage_id
	belongs_to :stage
	belongs_to :rider
	
	#Title:			find_default_rider
	#Description:	Finds the next available default rider for this user in this competition's race
	def find_default_rider()
		#Use default rider list
		default_riders = DefaultRider.where({:race_id=>self.race_id, :status=>STATUS[:ACTIVE]}).order('order_id')
		#Use normal rider list
		default_riders = TeamRider.where({:race_id=>self.race_id, :rider_status=>RIDER_RESULT_STATUS[:ACTIVE]}) if (default_riders.empty?)
		default_riders.each do |default_rider|
			checker = self.dup
			checker.rider_id = default_rider.rider_id
			return checker.rider_id if (!checker.is_duplicate({:SCOPE_PAST_TIPS=>1}))
		end
		
		#Fallback: Use regular rider list
		default_riders = TeamRider.where({:race_id=>self.race_id, :rider_status=>RIDER_RESULT_STATUS[:ACTIVE]})
		default_riders.each do |default_rider|
			checker = self.dup
			checker.rider_id = default_rider.rider_id
			return checker.rider_id if (!checker.is_duplicate({:SCOPE_PAST_TIPS=>1}))
		end
		
		return nil
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
		
		return duplicate
	end
	
	#Title:			fill_tips
	#Description:	Fill in tips for this user
	#Params:		user_id - Participant user ID
	#				competition_id - Competition ID
	def self.fill_tips(user_id, competition_id)
		#Add empty tips (Used for defaulting)
		competition_stages = CompetitionStage.where({:competition_id=>competition_id}).select('stage_id, race_id').group('stage_id, race_id')
		competition_stages.each do |competition_stage|
			tip = CompetitionTip.where({:competition_participant_id=>user_id, :stage_id=>competition_stage.stage_id, :competition_id=>competition_id, :race_id=>competition_stage.race_id}).first

			tip ||= CompetitionTip.new
			tip.competition_participant_id = user_id
			tip.stage_id = competition_stage.stage_id
			tip.competition_id = competition_id
			tip.race_id = competition_stage.race_id
			
			#If stage has ended, give this rider a default rider
			stage = Stage.find_by_id(competition_stage.stage_id)
			if (stage.starts_on <= Time.now && tip.rider_id.nil?)
				default_rider_id = tip.find_default_rider()
				tip.default_rider_id ||= default_rider_id if (!default_rider_id.nil? && !default_rider_id.to_s.empty?)
				tip.status = STATUS[:INACTIVE]
				tip.rider_id ||= 0
			end
			
			tip.save
		end
	end
end
