class AdminController < ApplicationController
	before_filter :check_access, :get_seasons, :except=>[:index, :login]
	
	layout 'admin'
	
	#GET
	def index
		render :layout => false
		redirect_to :action=>'dashboard' if (cookies.has_key?(:admin_access) || session.has_key?(:admin_access)) and return
	end
	
	def dashboard
		@title = ''
	end
	
	def edit_season
		@title = 'Edit season'
		if (params.has_key?:id)
			session[:season_id] = params[:id]
		end
	end
	
	def manage_riders
		@title = 'Manage riders'
		@riders = Rider.all
	end
	
	def edit_rider
		@edit_mode = params.has_key?(:id)
		if (@edit_mode)
			@rider = Rider.find_by_id(params[:id])
		end
		@edit_mode = !@rider.nil?
		render :layout => false
	end
	
	def manage_stages
		@title = 'Manage stages'
		@stages = Stage.where(:status=>STATUS[:ACTIVE])
	end
	
	def edit_stage
		@edit_mode = params.has_key?(:id)
		if (@edit_mode)
			@stage = Stage.find_by_id(params[:id])
		end
		@edit_mode = !@stage.nil?
		render :layout => false
	end
	
	def manage_races
		@title = 'Manage races'
		@races = Race.where(:status=>STATUS[:ACTIVE])
	end
	
	def edit_race
		@race = nil
		@race_stages = []
		@stages = Stage.where(:status=>STATUS[:ACTIVE])
		@edit_mode = params.has_key?(:id)
		if (@edit_mode)
			@race = Race.find_by_id(params[:id])
			@race_stages = RaceStage.where('race_stages.race_id=?', params[:id]).joins(:stage)
		end
		@edit_mode = !@race.nil?
		render :layout => false
	end
	
	def manage_season_teams
		@title = 'Manage season teams'
		@teams = Team.where(:status=>STATUS[:ACTIVE])
	end
	
	def edit_season_team
		@team = nil
		@team_riders = []
		@riders = Rider.where(:status=>STATUS[:ACTIVE])
		@edit_mode = params.has_key?(:id)
		if (@edit_mode)
			@team = Team.find_by_id(params[:id])
			@team_riders = TeamRider.where('team_id=? AND status=?', params[:id], STATUS[:ACTIVE])
		end
		@edit_mode = !@team.nil?
		render :layout => false
	end
	
	def manage_season_stages
		@title = 'Manage season stages'
		@races = {}
		stages = RaceStage.where(:status=>STATUS[:ACTIVE]).order(:order_id).joins(:race).joins(:stage)
		stages.each do |racestage|
			race_id = racestage.race_id
			@races[race_id] = {} if (@races[race_id].nil?)
			race = @races[race_id]
			race[:name] = racestage.race.name
			race[:stages] = [] if (race[:stages].nil?)
			race[:stages].push(racestage.stage)
			@races[race_id] = race
		end
	end
	
	#POST
	def login
		validated = true
		
		username = params[:username]
		password = params[:password]
		
		validated = validated && (username == 'admin')
		validated = validated && (password == 'tim123456')
		
		#Wrong credentials
		if (!validated)
			flash[:admin_login] = 'Incorrect username/password'
			redirect_to :action=>'index' and return
		end
		
		#Allow access
		session[:admin_access] = 1
		redirect_to :action=>'dashboard' and return
	end
	
	def save_riders
		rider_info = params[:rider_info]
		rider_info.each do |ndx, info|
			next if (info[:rider_name].length == 0)
			if (info.has_key?(:id))
				rider = Rider.find_by_id(info[:id])
			end
			rider ||= Rider.new
			rider.name = info[:rider_name]
			rider.photo_url = info[:image_url]
			rider.save
		end
		render :json => {:success=>true}
	end
	
	def save_stages
		stage_info = params[:stage_info]
		stage_info.each do |ndx, info|
			next if (info[:stage_name].length == 0)
			if (info.has_key?(:id))
				stage = Stage.find_by_id(info[:id])
			end
			stage ||= Stage.new
			stage.name = info[:stage_name]
			stage.description = info[:stage_description]
			stage.profile = info[:stage_profile]
			stage.image_url = info[:image_url]
			stage.save
		end
		render :json => {:success=>true}
	end
	
	def save_races
		race_info = params[:race_info]
		race_info.each do |ndx, info|
			next if (info[:race_name].length==0 || info[:stages].empty?)
			
			if (info.has_key?(:id))
				race = Race.find_by_id(info[:id])
			end
			race ||= Race.new
			race.name = info[:race_name]
			race.description = info[:race_description]
			race.image_url = info[:image_url]
			race.save
			
			ndx = 0
			info[:stages].each do |stage_id|
				racestage = RaceStage.where('race_id=? AND stage_id=?', race.id, stage_id).first
				racestage ||= RaceStage.new
				racestage.race_id = race.id
				racestage.stage_id = stage_id
				racestage.order_id = ndx
				racestage.save
				ndx += 1
				
				stage = Stage.find_by_id(stage_id)
				stage.race_id = race.id
				stage.save
			end
			
			RaceStage.where('race_id=? AND stage_id NOT IN (?)', race.id, info[:stages]).delete_all
		end
		
		render :json => {:success=>true} and return
	end
	
	def save_season_teams
		render :json=>{:success=>false, :msg=>'Select a season first.'} and return if (!session.has_key?(:season_id) || session[:season_id].empty?)
		team_info = params[:team_info]
		team_info.each do |ndx, info|
			next if (info[:team_name].length==0 || info[:riders].empty?)
			if (info.has_key?(:id))
				team = Team.find_by_id(info[:id])
			end
			team ||= Team.new
			team.name = info[:team_name]
			team.image_url = info[:image_url]
			team.season_id = session[:season_id]
			team.save
			
			rider_arr = []
			info[:riders].each do |ndx, rider_info|
				rider_arr.push(rider_info[:id])
				teamrider = TeamRider.where('team_id=? AND rider_id=?', team.id, rider_info[:id]).first
				teamrider ||= TeamRider.new
				teamrider.team_id = team.id
				teamrider.rider_id = rider_info[:id]
				teamrider.display_name = rider_info[:display_name]
				teamrider.save
			end
			
			TeamRider.where('team_id=? AND rider_id NOT IN (?)', team.id, rider_arr).delete_all
		end
		
		render :json => {:success=>true, :msg=>'success'} and return
	end
	
	def save_season_stages
		render :json=>{:success=>false, :msg=>'Select a season first.'} and return if (!session.has_key?(:season_id) || session[:season_id].empty?)
		season_stage_info = params[:season_stage_info]
		
		season_stage_info.each do |ndx, info|
			season_id = session[:season_id]
			stage_id = info[:stage_id]
			stage = Stage.find_by_id(stage_id)
			next if stage.nil?
			race_id = stage.race_id
			
			season_stage = SeasonStage.where('season_id=? AND stage_id=? AND race_id=?', season_id, stage_id, race_id).first
			season_stage ||= SeasonStage.new
			season_stage.season_id = season_id
			season_stage.race_id = race_id
			season_stage.stage_id = stage_id
			season_stage.start_dt = info[:start_dt]
			season_stage.save
		end
		render :json=>{:success=>true}
	end
	
	private
	def check_access
		redirect_to :action=>'index' if !(cookies.has_key?(:admin_access) || session.has_key?(:admin_access))
		session[:admin_access] = 1
		cookies[:admin_access] = { :value => 1, :expires => Time.now + 7200}
	end
	
	private
	def get_seasons
		#Find current season
		current = Season.where('year=?', Time.now.year)
		if (current.empty?)
			current = Season.new
			current.year = Time.now.year
			current.status = STATUS[:INACTIVE]
			current.save
		end
		@seasons = Season.all
	end
end
