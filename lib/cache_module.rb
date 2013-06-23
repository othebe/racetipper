module CacheModule
	#Cache types
	CACHE_TYPE = {
		:LEADERBOARD => 'leaderboard',
		:GLOBAL_LEADERBOARD => 'global_leaderboard',
		:RESULTS => 'results',
		:STAGE_IMAGES => 'stageimages'
	}
	
	#Cache TTL
	CACHE_TTL = {
		:MINUE => 60,
		:HOUR => 60*60,
		:DAY => 24*60*60
	}
	
	#Title:			get_cache_name
	#Decription:	Gets cache name based on type
	#Params:		cache_type - CACHE_TYPE symbol
	def self.get_cache_name(cache_type, identifiers)
		name = case cache_type
		when CACHE_TYPE[:LEADERBOARD]
			self.get_leaderboard_cache_name(identifiers)
		when CACHE_TYPE[:RESULTS]
			self.get_results_cache_name(identifiers)
		when CACHE_TYPE[:STAGE_IMAGES]
			self.get_stageimages_cache_name(identifiers)
		when CACHE_TYPE[:GLOBAL_LEADERBOARD]
			self.get_global_leaderboard_cache_name(identifiers)
		end
		
		name = name.chop if (name.end_with?('_'))
		
		return name
	end
	
	####################
	# Cache operations #
	####################
	
	#Title:			get
	#Description:	Gets value in cache
	def self.get(cache_name)
		value = nil
		value = eval(REDIS.get(cache_name)) if (REDIS.exists(cache_name))
		
		return value
	end
	
	#Title:			set
	#Description:	Sets value in cache
	def self.set(data, cache_name, ttl)
		REDIS.set(cache_name, data)
		REDIS.expire(cache_name, ttl)
	end
	
	#Title:			delete
	#Description:	Delete a value in cache
	def self.delete(cache_name)
		keys = REDIS.keys(cache_name)
		keys.each {|k| REDIS.del(k)}
	end
	
	###############
	# Cache names #
	###############
	
	#Title:			get_global_leaderboard_cache_name
	#Description:	Gets global leaderboard cache name
	def self.get_global_leaderboard_cache_name(identifiers)
		return [CACHE_TYPE[:GLOBAL_LEADERBOARD], identifiers[:race_id].to_s, identifiers[:scope].to_s].join('_')
	end
	
	#Title:			get_leaderboard_cache_name
	#Description:	Gets leaderboard cache name
	def self.get_leaderboard_cache_name(identifiers)
		return [CACHE_TYPE[:LEADERBOARD], identifiers[:competition_id].to_s, identifiers[:group_type], identifiers[:group_id].to_s].join('_')
	end
	
	#Title:			get_stageimages_cache_name
	#Description:	Gets stage images cache name
	def self.get_stageimages_cache_name(identifiers)
		return [CACHE_TYPE[:STAGE_IMAGES], identifiers[:id].to_s].join('_')
	end
	
	#Title:			get_results_cache_name
	#Description:	Gets results cache name
	def self.get_results_cache_name(identifiers)
		base = [CACHE_TYPE[:RESULTS], identifiers[:group_type], identifiers[:group_id].to_s]
		identifiers[:options].each do |k,v|
			base.push(k)
			base.push(v)
		end
		
		return base.join('_')
	end
end