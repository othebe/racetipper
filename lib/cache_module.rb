module CacheModule
	#Cache types
	CACHE_TYPE = {
		:LEADERBOARD => 'leaderboard',
		:LEADERBOARD_BY_USER => 'leaderboard_by_user',
		:LEADERBOARD_CUMULATIVE => 'leaderboard_cumulative',
		:GLOBAL_LEADERBOARD => 'global_leaderboard',
		:GLOBAL_LEADERBOARD_BY_USER => 'global_leaderboard_by_user',
		:GLOBAL_LEADERBOARD_CUMULATIVE => 'global_leaderboard_cumulative',
		:RESULTS => 'results',
		:RESULTS_CUMULATIVE => 'results_cumulative',
		:STAGE_IMAGES => 'stageimages',
		:COMPETITION_TIPS => 'competition_tips'
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
		when CACHE_TYPE[:LEADERBOARD_BY_USER]
			self.get_leaderboard_by_user_cache_name(identifiers)
		when CACHE_TYPE[:LEADERBOARD_CUMULATIVE]
			self.get_leaderboard_cumulative_cache_name(identifiers)
		when CACHE_TYPE[:RESULTS]
			self.get_results_cache_name(identifiers)
		when CACHE_TYPE[:RESULTS_CUMULATIVE]
			self.get_results_cumulative_cache_name(identifiers)
		when CACHE_TYPE[:STAGE_IMAGES]
			self.get_stageimages_cache_name(identifiers)
		when CACHE_TYPE[:GLOBAL_LEADERBOARD]
			self.get_global_leaderboard_cache_name(identifiers)
		when CACHE_TYPE[:GLOBAL_LEADERBOARD_BY_USER]
			self.get_global_leaderboard_by_user_cache_name(identifiers)
		when CACHE_TYPE[:GLOBAL_LEADERBOARD_CUMULATIVE]
			self.get_global_leaderboard_cumulative_cache_name(identifiers)
		when CACHE_TYPE[:COMPETITION_TIPS]
			self.get_competition_tips_cache_name(identifiers)
		else
			return nil
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
	def self.set(data, cache_name, ttl=nil)
		return if (cache_name.nil?)
		
		REDIS.set(cache_name, data)
		REDIS.expire(cache_name, ttl) if (!ttl.nil?)
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
		return [CACHE_TYPE[:GLOBAL_LEADERBOARD], identifiers[:group_type], identifiers[:group_id].to_s, identifiers[:scope].to_s].join('_')
	end
	
	#Title:			get_global_leaderboard_by_user_cache_name
	#Description:	Gets global leaderboard indexed by user cache name
	def self.get_global_leaderboard_by_user_cache_name(identifiers)
		return [CACHE_TYPE[:GLOBAL_LEADERBOARD_BY_USER], identifiers[:group_type], identifiers[:group_id].to_s, identifiers[:scope].to_s].join('_')
	end
	
	#Title:			get_global_leaderboard_cumulative_cache_name
	#Description:	Gets cumulative global leaderboard across stages
	def self.get_global_leaderboard_cumulative_cache_name(identifiers)
		base = [CACHE_TYPE[:LEADERBOARD_CUMULATIVE], identifiers[:scope].to_s]
		identifiers[:stages].each {|stage_id| base.push(stage_id)}
		
		return base.join('_')
	end
	
	#Title:			get_leaderboard_cache_name
	#Description:	Gets leaderboard cache name
	def self.get_leaderboard_cache_name(identifiers)
		return [CACHE_TYPE[:LEADERBOARD], identifiers[:competition_id].to_s, identifiers[:group_type], identifiers[:group_id].to_s].join('_')
	end
	
	#Title:			get_leaderboard_by_user_cache_name
	#Description:	Gets leaderboard indexed by user cache name
	def self.get_leaderboard_by_user_cache_name(identifiers)
		return [CACHE_TYPE[:LEADERBOARD_BY_USER], identifiers[:competition_id].to_s, identifiers[:group_type], identifiers[:group_id].to_s].join('_')
	end
	
	#Title:			get_leaderboard_cumulative_cache_name
	#Description:	Gets cumulative leaderboard across stages
	def self.get_leaderboard_cumulative_cache_name(identifiers)
		base = [CACHE_TYPE[:LEADERBOARD_CUMULATIVE], identifiers[:competition_id].to_s]
		identifiers[:stages].each {|stage_id| base.push(stage_id)}
		
		return base.join('_')
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
	
	#Title:			get_results_cumulative_cache_name
	#Description:	Gets cumulative results across stages
	def self.get_results_cumulative_cache_name(identifiers)
		base = [CACHE_TYPE[:RESULTS_CUMULATIVE]]
		identifiers[:stages].each {|stage_id| base.push(stage_id)}
		
		return base.join('_')
	end
	
	#Title:			get_competition_tips_cache_name
	#Description:	Gets results cache name
	def self.get_competition_tips_cache_name(identifiers)
		return base = [CACHE_TYPE[:COMPETITION_TIPS], identifiers[:competition_id].to_s, identifiers[:stage_id].to_s].join('_')
	end
	
	###########
	# Helpers #
	###########
	
	#Title:			delete_global_leaderboard_for_race
	#Description:	Deletes the global leaderboard for a race
	def self.delete_global_leaderboard_for_race(race_id, scope)
		#Clear global leaderboard race cache
		cache_name = self.get_cache_name(CACHE_TYPE[:GLOBAL_LEADERBOARD], {
			:group_type => 'race',
			:group_id => race_id,
			:scope => scope
		})
		self.delete(cache_name+'*')
		
		#Clear global leaderboard stage cache
		stages = Stage.where({:race_id=>race_id, :status=>STATUS[:ACTIVE]})
		stages.each do |stage|
			cache_name = self.get_cache_name(CACHE_TYPE[:GLOBAL_LEADERBOARD], {
				:group_type => 'stage',
				:group_id => stage.id,
				:scope => scope
			})
			self.delete(cache_name+'*')
		end
	end
	
	#Title:			delete_results
	#Description:	Deletes results cache
	def self.delete_results(group_type, group_id)
		#Cache name
		cache_name = self.get_cache_name(CACHE_TYPE[:RESULTS], {
			:group_type => group_type,
			:group_id => group_id,
			:options => {}
		})
		self.delete(cache_name+'*')
	end
end