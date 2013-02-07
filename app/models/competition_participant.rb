class CompetitionParticipant < ActiveRecord::Base
	attr_accessible :competition_id, :user_id
	belongs_to :user
  
	#Title:			add_participant
	#Description:	Adds a participant to a competition. Adds empty tips for all stages in the competition.
	#Params:		user_id - Participant user ID
	#				competition_id - Competition ID
	def self.add_participant(user_id, competition_id)
		#Add user to competition
		participation = self.where({:competition_id=>competition_id, :user_id=>user_id}).first
		participation ||= self.new
		participation.competition_id = competition_id
		participation.user_id = user_id
		participation.save
		
		#Add empty tips (Used for defauting)
		competition_stages = CompetitionStage.where({:competition_id=>competition_id})
		competition_stages.each do |competition_stage|
			tip = CompetitionTip.new
			tip.competition_participant_id = user_id
			tip.stage_id = competition_stage.stage_id
			tip.competition_id = competition_id
			tip.race_id = competition_stage.race_id
			
			#If stage has ended, give this rider a default rider
			stage = Stage.find_by_id(competition_stage.stage_id)
			if (stage.starts_on <= Time.now)
				tip.default_rider_id = tip.find_default_rider()
				tip.status = STATUS[:INACTIVE]
				tip.rider_id = 0
			end
			
			tip.save
		end
	end
end
