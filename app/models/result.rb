class Result < ActiveRecord::Base
  attr_accessible :kom_points, :rider_id, :season_stage_id, :sprint_points, :time
  
  belongs_to :rider
  
	#Title:			get_results
	#Description:	Gets ordered results
	#Params:		group_type - stage/race
	#				group_id - Group ID
	#				options - Hash:
	#					sort_field - Sort results by (DEFAULT: sort_score)
	#					index_by_rank - Return indexed by rank (DEFAULT
	#					index_by_rider - Return indexed by rider ID
	def self.get_results(group_type, group_id, options={})
		selector = nil
		if (group_type == 'stage')
			selector = 'season_stage_id'
		elsif (group_type == 'race')
			selector = 'race_id'
		end
		
		return [] if selector.nil?
		
		#Sort fields
		sort_field = 'sort_score'
		sort_field = options[:sort_field].strip if (options.has_key?(:sort_field) && !options[:sort_field].strip.empty?)
		#Sort direction
		sort_dir = 'ASC'
		sort_dir = options[:sort_dir].strip.upcase if (options.has_key?(:sort_dir) && !options[:sort_dir].strip.empty?)
		
		results  = Result.where({selector.to_sym=>group_id})
		rider_points_unsorted = {}
		results.each do |result|
			rider_id = result.rider_id
			rider_data = rider_points_unsorted[rider_id] || Hash.new
			rider_data[:id] = rider_id
			rider_data[:rider_name] ||= Rider.find_by_id(rider_id).name
			disqualified = rider_status_to_str(result.rider_status)
			score_modifier = get_score_modifier(result.rider_status)
			
			if (options.has_key?(:index_by_rider))
				rider_data[:stages] ||= {}
				rider_data[:stages][result.season_stage_id] ||= {}
				rider_data[:stages][result.season_stage_id][:time] = result.time
				rider_data[:stages][result.season_stage_id][:bonus_time] = result.bonus_time
				if (group_type=='stage')
					rider_data[:stages][result.season_stage_id][:rank] = result.rank
				else
					rider_data[:stages][result.season_stage_id][:rank] = nil
				end
				rider_data[:stages][result.season_stage_id][:kom_points] = result.kom_points
				rider_data[:stages][result.season_stage_id][:sprint_points] = result.sprint_points
				rider_data[:stages][result.season_stage_id][:points] = result.points
				rider_data[:stages][result.season_stage_id][:disqualified] = disqualified
				rider_data[:stages][result.season_stage_id][:time] = 999999999 if (!disqualified.nil?)
				rider_data[:stages][result.season_stage_id][:sort_score] = score_modifier + rider_data[:stages][result.season_stage_id][:time] - result.bonus_time
				#Format time
				if (result.time >= 86400)
					days = (Time.at(result.time).gmtime.strftime('%-d').to_i - 1).to_s
					rider_data[:stages][result.season_stage_id][:time_formatted] = Time.at(result.time).gmtime.strftime(days+' day(s), %R:%S')
				else
					rider_data[:stages][result.season_stage_id][:time_formatted] = Time.at(result.time).gmtime.strftime('%R:%S')
				end
				
				#Format bonus time
				if (result.bonus_time >= 86400)
					days = (Time.at(result.bonus_time).gmtime.strftime('%-d').to_i - 1).to_s
					rider_data[:stages][result.season_stage_id][:bonus_time_formatted] = Time.at(result.bonus_time).gmtime.strftime(days+' day(s), %R:%S')
				else
					rider_data[:stages][result.season_stage_id][:bonus_time_formatted] = Time.at(result.bonus_time).gmtime.strftime('%R:%S')
				end
					
			else
				rider_data[:time] = (rider_data[:time] || 0) + result.time
				rider_data[:bonus_time] = (rider_data[:bonus_time] || 0) + result.bonus_time
				if (group_type=='stage')
					rider_data[:rank] = result.rank
				else
					rider_data[:rank] = nil
				end
				rider_data[:kom_points] = (rider_data[:kom_points] || 0) + result.kom_points
				rider_data[:sprint_points] = (rider_data[:sprint_points] || 0) + result.sprint_points
				rider_data[:points] = (rider_data[:points] || 0) + result.points
				rider_data[:disqualified] = disqualified
				rider_data[:time] = 999999999 if (!disqualified.nil?)
				rider_data[:sort_score] = score_modifier + rider_data[:time] - result.bonus_time
				#Format time
				if (result.time >= 86400)
					days = (Time.at(result.time).gmtime.strftime('%-d').to_i - 1).to_s
					rider_data[:time_formatted] = Time.at(result.time).gmtime.strftime(days+' day(s), %R:%S')
				else
					rider_data[:time_formatted] = Time.at(rider_data[:time]).gmtime.strftime('%R:%S')
				end
				
				#Format bonus time
				if (result.bonus_time >= 86400)
					days = (Time.at(result.bonus_time).gmtime.strftime('%-d').to_i - 1).to_s
					rider_data[:bonus_time_formatted] = Time.at(result.bonus_time).gmtime.strftime(days+' day(s), %R:%S')
				else
					rider_data[:bonus_time_formatted] = Time.at(rider_data[:bonus_time]).gmtime.strftime('%R:%S')
				end
			end
			rider_points_unsorted[rider_id] = rider_data
		end
		
		#Sort to get rank
		riders_ranked = rider_points_unsorted.sort_by{|k, v| v[:sort_score]}
		rank = 1
		riders_ranked.each do |id, data|
			rider_data = rider_points_unsorted[id]
			rider_data[:rank] = rank
			rider_points_unsorted[id] = rider_data
			rank += 1
		end
		
		rider_points_sorted = rider_points_unsorted.sort_by{|k, v| v[sort_field.to_sym]}
		rider_points_sorted = rider_points_sorted.reverse if (sort_dir=='DESC')
		
		#Index by rider ID, and add gap
		base_time = nil
		indexed_hash = {}
		rank = 1
		rider_points_sorted.each do |rider_id, data|
			gap = (data[:time] - base_time - data[:bonus_time]) if (!base_time.nil?)
			gap ||= 0
			
			data[:gap] = ''
			data[:gap] = gap if (!base_time.nil?)
			
			data[:gap_formatted] = ''
			if (gap >= 86400)
				days = (Time.at(gap).gmtime.strftime('%-d').to_i - 1).to_s
				data[:gap_formatted] = '+ '+Time.at(gap).gmtime.strftime(days+'day(s), %R:%S') if (!base_time.nil?)
			else
				data[:gap_formatted] = '+ '+Time.at(gap).gmtime.strftime('%R:%S') if (!base_time.nil?)
			end
			
			key = rank
			key = rider_id if (options.has_key?(:index_by_rider))
			
			indexed_hash[key] = data
			
			rank += 1
			base_time = data[:time] if (base_time.nil?)
		end
		rider_points_sorted = indexed_hash
			
		return rider_points_sorted
	end
	
	#Title:			check_valid_tips
	#Description:	Check if a user's tip is valid for this result and sets  a default rider if not valid.
	def check_valid_tips()
		stage_id = self.season_stage_id
		rider_id = self.rider_id

		tips = CompetitionTip.where('stage_id=? AND (rider_id IS NULL OR rider_id=?)', stage_id, rider_id)
		tips.each do |tip|
			valid = true
			
			#Check if rider has been disqualified
			valid = false if (self.rider_status==RIDER_RESULT_STATUS[:DNF] || self.rider_status==RIDER_RESULT_STATUS[:DNS])
			
			#Check if rider has already been selected as a default
			valid = !tip.is_duplicate({:SCOPE_PAST_TIPS=>1}) if (valid)
			
			#Check for empty tip
			valid = !(tip.rider_id.nil?) if (valid)
			
			#Current tip is invalid
			if (!valid)
				#Set default rider
				tip.default_rider_id = tip.find_default_rider() if (!valid)
				#Set rider id to 0 if it was empty
				tip.rider_id ||= 0
				#Set notification requirement to true
				tip.notification_required = true
			end
			
			#Mark tip as finished
			tip.status = STATUS[:INACTIVE]
			tip.save
		end
	end
	
	#Title:			rider_status_to_str
	#Description:	Convert a rider status to a string
	#Params:		status (integer)
	#Returns:		string
	def self.rider_status_to_str(status)
		return 'DNF' if (status==RIDER_RESULT_STATUS[:DNF])
		return 'DNS' if (status==RIDER_RESULT_STATUS[:DNS])
	end
	
	#Title:			get_score_modifier
	#Description:	Gets a score mofifier
	#Params:		status (integer)
	#Returns:		number
	private
	def self.get_score_modifier(status)
		return SCORE_MODIFIER[:DNF] if (status==RIDER_RESULT_STATUS[:DNF])
		return SCORE_MODIFIER[:DNS] if (status==RIDER_RESULT_STATUS[:DNS])
		
		return 0
	end
end
