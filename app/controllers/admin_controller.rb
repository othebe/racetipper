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
	
	def manage_season_teams
		@title = 'Manage season teams'
		@teams = Team.where(:status=>STATUS[:ACTIVE])
	end
	
	def edit_season_team
		@team = nil
		@team_riders = []
		@riders = Rider.where(:status=>STATUS[:ACTIVE])
		@races = Race.where({:status=>STATUS[:ACTIVE], 'season_id'=>session[:season_id]})
		@edit_mode = params.has_key?(:id)
		if (@edit_mode)
			@team = Team.find_by_id(params[:id])
			@team_riders = TeamRider.where('team_id=? AND status=?', params[:id], STATUS[:ACTIVE])
		end
		@edit_mode = !@team.nil?
		render :layout => false
	end
		
	def manage_season_races
		@title = 'Manage season races'
		@races = Race.where('season_id=? AND status=?', session[:season_id], STATUS[:ACTIVE])
	end
	
	def edit_season_race
		@race = nil
		@stages = []
		
		@race = Race.find_by_id(params[:id]) if (params.has_key?(:id))
		@stages = Stage.where('race_id=? AND status=?', @race.id, STATUS[:ACTIVE]) if (!@race.nil?)
		render :layout=>false
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
			team.race_id = info[:race_id]
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
	
	def save_season_races
		render :json=>{:success=>false, :msg=>'Select a season first.'} and return if (!session.has_key?(:season_id) || session[:season_id].empty?)
		race_info = params[:race_info]
		if (race_info.has_key?(:id))
			race = Race.find_by_id(race_info[:id])
		end
		race ||= Race.new
		
		race.name = race_info[:race_name]
		race.description = race_info[:race_description]
		race.image_url = race_info[:race_image_url]
		race.season_id = session[:season_id]
		race.save
		
		stage_arr = []
		race_info[:stage_data].each do |ndx, stage_info|
			stage = Stage.find_by_id(stage_info[:stage_id]) if (stage_info.has_key?(:stage_id))
			stage ||= Stage.new
			stage.name = stage_info[:stage_name]
			stage.description = stage_info[:stage_description]
			stage.image_url = stage_info[:stage_image_url]
			stage.profile = stage_info[:stage_profile]
			stage.order_id = ndx
			stage.race_id = race.id
			stage.season_id = session[:season_id]
			stage.starts_on = stage_info[:stage_starts_on]
			stage.start_location = stage_info[:stage_start_location]
			stage.end_location = stage_info[:stage_end_location]
			stage.distance_km = stage_info[:stage_distance]
			stage.save
			stage_arr.push(stage.id)
		end
		Stage.where('race_id=? AND season_id=? AND id NOT IN (?)', race.id, session[:season_id], stage_arr).delete_all
		
		render :json=>{:success=>true, :msg=>'success'} and return
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