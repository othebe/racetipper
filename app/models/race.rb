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
	
	#Title:			past_halfway
	#Description:	Determines if over half of the stages in the race have started
	def self.past_halfway(race_id)
		total_stages = Stage.where('race_id = ? AND status = ?', race_id, STATUS[:ACTIVE]).count
		remaining_stages = Stage.where('race_id = ? AND status = ? AND starts_on > ?', race_id, STATUS[:ACTIVE], Time.now).count

		return (remaining_stages < (total_stages*0.5).ceil)
	end
	
	#DEPRECATED
	#Title:			create_competition_from_race
	#Description:	Creates global competition for a race
	def create_competition_from_race
		return
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
	
	#Title:			has_started
	#Description:	Determines if a race has started
	def self.has_started(race_id)
		first_stage = Stage.where({:race_id=>race_id, :status=>STATUS[:ACTIVE]}).order('starts_on ASC').first
		if (!first_stage.nil?)
			has_started = (first_stage.starts_on <= Time.now)
		else 
			has_started = false
		end
		
		return has_started
	end
	
	#Title:			get_global_competition_results
	#Description:	Gets results for global competitions
	def self.get_global_competition_results(race_id, scope)
		return nil if (!self.has_started(race_id))
		
		results = Result.get_results('race', race_id, {:index_by_rider=>true})
		return nil if (results.empty?)
		
		data = []
		
		primaries = CompetitionParticipant.joins(:competition).where('competitions.race_id=? AND is_primary=? AND competition_participants.status=? AND scope=?', race_id, true, STATUS[:ACTIVE], scope)
		primaries.each do |primary|
			tips = CompetitionTip.where({:competition_id=>primary.competition_id})
			user = User.find_by_id(primary.user_id)
			tip_data = {}
			tips.each do |tip|
				rider_id = tip.default_rider_id || tip.rider_id
				stage_id = tip.stage_id
				
				next if (results[rider_id].nil?)
				next if (results[rider_id][:stages][stage_id].nil? || results[rider_id][:stages][stage_id].empty?)
				
				tip_data[stage_id] ||= {}
				
				#Rider data
				tip_data[stage_id][:rider] = {
					:rider_id => rider_id,
					:rider_name => results[rider_id][:rider_name]
				}
				
				#Result data
				tip_data[stage_id][:results] = results[rider_id][:stages][stage_id]
			end
			
			data.push({
				:user => user,
				:tip_data => tip_data
			})
		end
		
		return data
	end
	
	#Title:			get_global_competition_leaderboard
	#Description:	Gets leaderboard for global competitions
	def self.get_global_competition_leaderboard(race_id, group_type, group_id, scope)
		results = self.get_global_competition_results(race_id, scope)
		return nil if (results.nil?)
		
		unsorted = []
		
		results.each do |result|
			time = bonus_time = kom_points = sprint_points = rank = 0
			
			#Cumulative data
			if (group_type=='race')
				result[:tip_data].each do |stage_id, stage_data|
					time += stage_data[:results][:time]
					bonus_time += (stage_data[:results][:bonus_time] || 0)
					kom_points += (stage_data[:results][:kom_points] || 0)
					sprint_points += (stage_data[:results][:sprint_points] || 0)
				end
			#Single stage data
			else
				time = result[:tip_data][group_id][:results][:time]
				bonus_time = (result[:tip_data][group_id][:results][:bonus_time] || 0)
				kom_points = (result[:tip_data][group_id][:results][:kom_points] || 0)
				sprint_points = (result[:tip_data][group_id][:results][:sprint_points] || 0)
				rank = (result[:tip_data][group_id][:results][:rank] || 0)
			end
			
			unsorted.push({
				:user => result[:user],
				:time => time,
				:bonus_time => bonus_time,
				:kom_points => kom_points,
				:sprint_points => sprint_points
			})
		end
		
		if (group_type=='race')
			sorted = unsorted.sort{|x, y| x[:time] <=> y[:time]}
		else
			sorted = unsorted.sort{|x, y| x[:rank] <=> y[:rank]}
		end
		
		return sorted
	end
end
