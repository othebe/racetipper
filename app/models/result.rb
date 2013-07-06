class Result < ActiveRecord::Base
	attr_accessible :kom_points, :rider_id, :season_stage_id, :sprint_points, :time

	belongs_to :rider
	
	require_dependency 'cache_module'
	require_dependency 'leaderboard_module'
  
	#Title:			get_results
	#Description:	Gets ordered results
	#Params:		group_type - stage/race
	#				group_id - Group ID
	#				options - Hash:
	#					sort_field - Sort results by (DEFAULT: sort_score)
	#					index_by_rank - Return indexed by rank (DEFAULT)
	#					index_by_rider - Return indexed by rider ID
	#				regenerate - Determines if cache should be generated
	def self.get_results(group_type, group_id, options={}, regenerate=false)
		cache_name = CacheModule::get_cache_name(
			CacheModule::CACHE_TYPE[:RESULTS], 
			{:group_type=>group_type, :group_id=>group_id, :options=>options}
		)
		rider_points_sorted = CacheModule::get(cache_name)
		
		#If not regenerating results, return data
		return rider_points_sorted if (!regenerate)
		
		if (regenerate)
			selector = nil
			if (group_type == 'stage')
				selector = 'season_stage_id'
			elsif (group_type == 'race')
				selector = 'race_id'
			end
			
			return [] if selector.nil?
			
			#Sort fields
			sort_field = 'rank'
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
					net_time = rider_data[:stages][result.season_stage_id][:time] - rider_data[:stages][result.season_stage_id][:bonus_time]
					if (net_time >= 86400)
						days = (Time.at(net_time).gmtime.strftime('%-d').to_i - 1).to_s
						rider_data[:stages][result.season_stage_id][:time_formatted] = Time.at(net_time).gmtime.strftime(days+'d %R:%S')
					else
						rider_data[:stages][result.season_stage_id][:time_formatted] = Time.at(net_time).gmtime.strftime('%R:%S')
					end
					
					#Format bonus time
					if (result.bonus_time >= 86400)
						days = (Time.at(rider_data[:stages][result.season_stage_id][:bonus_time]).gmtime.strftime('%-d').to_i - 1).to_s
						rider_data[:stages][result.season_stage_id][:bonus_time_formatted] = Time.at(rider_data[:stages][result.season_stage_id][:bonus_time]).gmtime.strftime(days+'d %R:%S')
					elsif (result.bonus_time.nil? || result.bonus_time == 0)
						rider_data[:stages][result.season_stage_id][:bonus_time_formatted] = nil
					elsif (result.bonus_time <= 60)
						rider_data[:stages][result.season_stage_id][:bonus_time_formatted] = result.bonus_time.to_s + '"'
					else
						rider_data[:stages][result.season_stage_id][:bonus_time_formatted] = Time.at(rider_data[:stages][result.season_stage_id][:bonus_time]).gmtime.strftime('%R:%S')
					end
						
				else
					rider_data[:time] = (rider_data[:time] || 0) + result.time
					rider_data[:bonus_time] = (rider_data[:bonus_time] || 0) + result.bonus_time.to_i
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
					net_time = rider_data[:time] - rider_data[:bonus_time]
					if (net_time >= 86400)
						days = (Time.at(net_time).gmtime.strftime('%-d').to_i - 1).to_s
						rider_data[:time_formatted] = Time.at(net_time).gmtime.strftime(days+'d %R:%S')
					else
						rider_data[:time_formatted] = Time.at(net_time).gmtime.strftime('%R:%S')
					end
					
					#Format bonus time
					if (rider_data[:bonus_time] >= 86400)
						days = (Time.at(rider_data[:bonus_time]).gmtime.strftime('%-d').to_i - 1).to_s
						rider_data[:bonus_time_formatted] = Time.at(rider_data[:bonus_time]).gmtime.strftime(days+'d %R:%S')
					elsif (rider_data[:bonus_time].nil? || rider_data[:bonus_time] == 0)
						rider_data[:bonus_time_formatted] = nil
					elsif (rider_data[:bonus_time] <= 60)
						rider_data[:bonus_time_formatted] = rider_data[:bonus_time].to_s + '"'
					else
						rider_data[:bonus_time_formatted] = Time.at(rider_data[:bonus_time]).gmtime.strftime('%R:%S')
					end
				end
				rider_points_unsorted[rider_id] = rider_data
			end
			
			#If indexed by rider, sort by time to get the rank
			if (!options.has_key?(:index_by_rider))
				riders_ranked = rider_points_unsorted.sort_by{|k, v| v[:sort_score]}
				rank = 0
				ndx = 0
				base_time = nil

				riders_ranked.each do |id, data|
					rider_data = rider_points_unsorted[id]
					ndx += 1
					if (base_time.nil? || (base_time<rider_data[:time]))
						base_time = rider_data[:time]
						rank = ndx
					end
					rider_data[:rank] = rank if (rider_data[:rank].nil? || rider_data[:rank]==0)
					rider_points_unsorted[id] = rider_data
				end
			end

			rider_points_sorted = rider_points_unsorted.sort_by{|k, v| v[sort_field.to_sym]}
			rider_points_sorted = rider_points_sorted.reverse if (sort_dir=='DESC')
			
			#Index by rider ID, and add gap
			base_time = nil
			indexed_hash = {}
			rank = 1
			rider_points_sorted.each do |rider_id, data|
				data[:time] ||= 0
				data[:bonus_time] ||= 0
				gap = (data[:time] - base_time - data[:bonus_time]) if (!base_time.nil?)
				gap ||= 0
				
				data[:gap] = ''
				data[:gap] = gap if (!base_time.nil?)
				
				data[:gap_formatted] = ''
				if (gap >= 86400)
					days = (Time.at(gap).gmtime.strftime('%-d').to_i - 1).to_s
					data[:gap_formatted] = Time.at(gap).gmtime.strftime(days+'d %R:%S') if (!base_time.nil?)
				else
					data[:gap_formatted] = Time.at(gap).gmtime.strftime('%R:%S') if (!base_time.nil?)
				end
				
				key = rank
				key = rider_id if (options.has_key?(:index_by_rider))
				
				indexed_hash[key] = data
				
				rank += 1
				base_time = (data[:time]-data[:bonus_time]) if (base_time.nil?)
			end
			rider_points_sorted = indexed_hash
			CacheModule::set(rider_points_sorted, cache_name)
		end
		
		return rider_points_sorted
	end
	
	#Title:			get_cumulative_stage_results
	#Description:	Return aggregate results for an array of stages
	#Params:		stages - Array of Stage ID's
	#				options - get_results options
	def self.get_cumulative_stage_results(stages, options={}, regenerate=false)
		cache_name = CacheModule::get_cache_name(
			CacheModule::CACHE_TYPE[:RESULTS_CUMULATIVE],
			{:stages=>stages}
		)
		cumulative_results = CacheModule::get(cache_name)
		cumulative_results = nil if (regenerate)
		
		return cumulative_results if (!cumulative_results.nil?)
		
		cumulative_results = []
		
		#Unsorted cumulative
		interim_results = {}
		stages.each do |stage_id|
			stage_results = self.get_results('stage', stage_id, options)
			next if (stage_results.nil?)
			
			stage_results.each do |result|
				rider_id = result[1][:id]
				result_data = result[1]
				if (interim_results[rider_id].nil?)
					interim_results[rider_id] = result_data
				else
					rider_data = interim_results[rider_id]
					rider_data[:time] += result_data[:time]
					rider_data[:bonus_time] += result_data[:bonus_time]
					rider_data[:kom_points] += result_data[:kom_points]
					rider_data[:sprint_points] += result_data[:sprint_points]
					rider_data[:disqualified] ||= result_data[:disqualified]
					
					interim_results[rider_id] = rider_data
				end
			end
		end
		
		#No results?
		return interim_results if (interim_results.empty?)
		
		#Sort by net time
		interim_results = interim_results.sort_by{|rider_id, rider_data| (rider_data[:time]-rider_data[:bonus_time])}
		
		#Format results
		rank = 0
		base_time = interim_results.first[1][:time] - interim_results.first[1][:bonus_time]
		interim_results.each do |rider_id, rider_data|
			#Format time
			rider_data[:time_formatted] = LeaderboardModule::format_time(rider_data[:time]-rider_data[:bonus_time])
			
			#Format bonus time
			rider_data[:bonus_time_formatted] = LeaderboardModule::format_time(rider_data[:bonus_time])
			
			#Format gap
			gap = (rider_data[:time] - rider_data[:bonus_time])
			rider_data[:gap_formatted] = LeaderboardModule::format_time(gap)
			
			#Rank
			rank += 1
			rider_data[:rank] = rank
			
			cumulative_results.push(rider_data)
		end
		
		CacheModule::set(cumulative_results, cache_name)
		
		return cumulative_results
	end
	
	#Title:			get_race_results
	#Description:	Return aggregate results for an array of completed stages
	#Params:		race_id
	def self.get_race_results(race_id, regenerate=false)
		stage_list = []
		stages = Stage.where('stages.race_id=?', race_id).order('starts_on ASC')
		stages.each {|stage| stage_list.push(stage.id) if (!Result.where(:season_stage_id=>stage.id, :status=>STATUS[:ACTIVE]).first.nil?)}
		
		return self.get_cumulative_stage_results(stage_list)
	end
	
	#Title:			check_valid_tips
	#Description:	Check if a user's tip is valid for this result and sets  a default rider if not valid.
	def check_valid_tips()
		stage_id = self.season_stage_id
		rider_id = self.rider_id

		tips = CompetitionTip.where('stage_id=? AND (rider_id IS NULL OR rider_id=0 OR rider_id=?) AND status=?', stage_id, rider_id, STATUS[:ACTIVE])
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
