class Result < ActiveRecord::Base
  attr_accessible :kom_points, :rider_id, :season_stage_id, :sprint_points, :time
  
  belongs_to :rider
  
	#Title:			get_results
	#Description:	Gets ordered results
	#Params:		group_type - stage/race
	#				group_id - Group ID
	#				options - Hash:
	#					sort_field - Sort results by (DEFAULT: time)
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
		
		sort_field = 'time'
		sort_field = options[:sort_field] if (options.has_key?(:sort_field))
		
		results  = Result.where({selector.to_sym=>group_id})
		rider_points_unsorted = {}
		results.each do |result|
			rider_id = result.rider_id
			rider_data = rider_points_unsorted[rider_id] || Hash.new
			rider_data[:id] = rider_id
			rider_data[:rider_name] ||= Rider.find_by_id(rider_id).name
			if (options.has_key?(:index_by_rider))
				rider_data[:stages] ||= {}
				rider_data[:stages][result.season_stage_id] ||= {}
				rider_data[:stages][result.season_stage_id][:time] = result.time
				rider_data[:stages][result.season_stage_id][:time_formatted] = Time.at(result.time).gmtime.strftime('%R:%S')
				rider_data[:stages][result.season_stage_id][:kom_points] = result.kom_points
				rider_data[:stages][result.season_stage_id][:sprint_points] = result.sprint_points
				rider_data[:stages][result.season_stage_id][:points] = result.points
			else
				rider_data[:time] = (rider_data[:time] || 0) + result.time
				rider_data[:time_formatted] = Time.at(rider_data[:time]).gmtime.strftime('%R:%S')
				rider_data[:kom_points] = (rider_data[:kom_points] || 0) + result.kom_points
				rider_data[:sprint_points] = (rider_data[:sprint_points] || 0) + result.sprint_points
				rider_data[:points] = (rider_data[:points] || 0) + result.points
			end
			rider_points_unsorted[rider_id] = rider_data
		end
		rider_points_sorted = rider_points_unsorted.sort_by{|k, v| v[sort_field.to_sym]}
		
		#Index by rider ID, and add gap
		base_time = nil
		indexed_hash = {}
		rank = 1
		rider_points_sorted.each do |rider_id, data|
			gap = Time.at(data[:time] - base_time) if (!base_time.nil?)
			
			data[:gap] = ''
			data[:gap] = gap if (!base_time.nil?)
			
			data[:gap_formatted] = ''
			data[:gap_formatted] = '+ '+Time.at(gap).gmtime.strftime('%R:%S') if (!base_time.nil?)
			
			key = rank
			key = rider_id if (options.has_key?(:index_by_rider))
			
			indexed_hash[key] = data
			
			rank += 1
			base_time = data[:time] if (base_time.nil?)
		end
		rider_points_sorted = indexed_hash
			
		return rider_points_sorted
  end
end
