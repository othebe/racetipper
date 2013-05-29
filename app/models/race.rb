class Race < ActiveRecord::Base
  attr_accessible :description, :image_url, :name
  
	#Title:			get_race_results_by_rider
	#Description:	Gets results of race indexed by rider id
	#Params:		race_id
	def self.get_race_results_by_rider(race_id)
		results = Result.where({:race_id=>race_id})
		
		data = {}
		results.each do |result|
			arr = {}
			arr = data[result.rider_id] if (data.has_key?(result.rider_id))
			stage_data = {
				:stage_id => result.season_stage_id,
				:time => result.time,
				:kom => result.kom_points,
				:sprint => result.sprint_points,
				:points => result.points
			}
			arr[result.season_stage_id] = stage_data
			data[result.rider_id] = arr
		end
		return data
	end
	
	#Title:			get_riders_for_race
	#Description:	Gets riders for a race indexed by team
	#Params:		race_id
	def self.get_riders_for_race(race_id)
		#Get all rider teams
		teamriders = TeamRider.where({:race_id=>race_id, :status=>STATUS[:ACTIVE]}).joins(:team).joins(:rider).order('rider_number')

		#Index riders by team
		teams = {}
		teamriders.each do |teamrider|
			team = teamrider.team
			rider = teamrider.rider
			
			team_data = teams[team.id] || {:team=>team, :riders=>[]}
			team_data[:riders].push({
				:rider_id => rider.id,
				:rider_name => rider.name,
				:rider_number => teamrider.rider_number,
			})
			teams[team.id] = team_data
		end
		
		#Generate list
		seen = {}
		rider_list = []
		teamriders.each do |teamrider|
			team_id = teamrider.team_id
			next if (!seen[team_id].nil?)
			rider_list.push({
				:team_name => teams[team_id][:team].name,
				:riders => teams[team_id][:riders]
			})
			seen[team_id] = 1
		end
		
		return rider_list
	end
	
	#Title:			check_completion_status
	#Description:	Check if all stages in a race are complete and sets status to inactive.
	#Params:		race_id
	def self.check_completion_status(race_id)
		race = Race.find_by_id(race_id)
		stages = Stage.where('race_id=? AND NOW() <= starts_on', race_id)
		if (stages.empty?)
			race.is_complete = true
		else 
			race.is_complete = false
		end
		race.save
	end
	
	#Title:			create_competition_from_race
	#Description:	Creates global competition for a race
	def create_competition_from_race
		#Create competition
		competition = Competition.new({
			:creator_id => ADMIN_ID,
			:name => self.name,
			:description => self.description,
			:image_url => self.image_url,
			:season_id => self.season_id,
			:competition_type => COMPETITION_TYPE[:GLOBAL]
		})
		competition.save
		
		#Create competition stages
		stages = Stage.where({:race_id=>self.id, :status=>STATUS[:ACTIVE]}).order(:order_id)
		stages.each do |stage|
			competition_stage = CompetitionStage.new({
				:competition_id => competition.id,
				:stage_id => stage.id,
				:race_id => self.id
			})
			competition_stage.save
		end
		
		#Call Ironworker to queue job
		require 'net/http'

		url = "https://worker-aws-us-east-1.iron.io/2/projects/#{IRONWORKER_PROJECT_ID}/tasks/webhook?code_name=add_participants_to_global_competition&oauth=#{IRONWORKER_TOKEN}"
		uri = URI.parse(url)
		req = Net::HTTP::Post.new(url)
		res = Net::HTTP.start(
			uri.host, uri.port, 
			:use_ssl => true,
			:verify_mode => OpenSSL::SSL::VERIFY_PEER,
			:ca_file => File.join("cacert.pem")) {|http| http.request(req)}
		puts res.body
	end
end
