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
		@riders = Rider.where({:status=>STATUS[:ACTIVE]})
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
		@races = Race.where({'season_id'=>session[:season_id]})
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
		@races = Race.where('season_id=?', session[:season_id])
	end
	
	def edit_season_race
		@race = nil
		@stages = []
		
		@race = Race.find_by_id(params[:id]) if (params.has_key?(:id))
		@stages = Stage.where('race_id=? AND status=?', @race.id, STATUS[:ACTIVE]) if (!@race.nil?)
		render :layout=>false
	end
	
	def manage_quotes
		@title = 'Manage quotes'
		@quotes = CyclingQuote.all
	end
	
	def edit_quote
		if (params.has_key?(:id))
			@id = params[:id]
			@quote = CyclingQuote.find_by_id(@id)
		end
		render :layout=>false
	end
	
	def manage_articles
		@title = 'Manage articles'
		@articles = Article.where({:status=>STATUS[:ACTIVE]})
	end
	
	def edit_article
		@id = ''
		@id = params[:id] if (params.has_key?(:id))
		@article = Article.find_by_id(params[:id]) if (params.has_key?(:id))
		@article ||= Article.new
		
		render :layout=>false
	end
	
	#POST
	def login
		validated = true
		
		username = params[:username]
		password = params[:password]
		
		userdata = {
			:email => username,
			:password => password
		}
		user = User.check_credentials(userdata)
		validated = (!user.nil? && user.is_admin)
		
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
			#team.race_id = info[:race_id]
			team.save
			
			#RaceTeams
			raceteam = RaceTeam.where({:race_id=>info[:race_id], :team_id=>team.id}).first
			raceteam ||= RaceTeam.new
			raceteam.race_id = info[:race_id]
			raceteam.team_id = team.id
			raceteam.save
			
			rider_arr = []
			info[:riders].each do |ndx, rider_info|
				rider_arr.push(rider_info[:id])
				teamrider = TeamRider.where('team_id=? AND rider_id=? AND (race_id=? OR race_id IS NULL)', team.id, rider_info[:id], info[:race_id]).first
				teamrider ||= TeamRider.new
				teamrider.team_id = team.id
				teamrider.rider_id = rider_info[:id]
				teamrider.display_name = rider_info[:display_name]
				teamrider.rider_number = rider_info[:rider_number]
				teamrider.race_id = info[:race_id]
				teamrider.save
			end
			
			TeamRider.where('team_id=? AND rider_id NOT IN (?)', team.id, rider_arr).delete_all
		end
		
		render :json => {:success=>true, :msg=>'success'} and return
	end
	
	#Title:			save_race_image
	#Description:	Save the image for a race
	def save_race_image
		race_id = params[:race_id]
		race = Race.find_by_id(race_id)
		
		#Check that competition exists and user is allowed to save
		#redirect_to :root if (competition.creator_id != @user.id)
		
		#Save competition image path
		race.image_url = 'race_'+race_id.to_s+'.jpg'
		race.save
		
		if (!params[:image].nil?)
			options = {
				:public_id => "race_"+race_id.to_s,
				:format => 'jpg',
				:transformation => {
					:x => params[:crop_x].to_i,
					:y => params[:crop_y].to_i,
					:width => params[:crop_w].to_i,
					:height => params[:crop_h].to_i,
					:crop => :crop
				}
			}
			Cloudinary::Uploader.upload(params[:image].tempfile.path, options)
		end
		
		render :text=>params.inspect
	end
	
	def save_season_races
		render :json=>{:success=>false, :msg=>'Select a season first.'} and return if (!session.has_key?(:season_id) || session[:season_id].empty?)
		
		#Determine if a new global competition needs to be created
		create_global_competition = false
		
		race_info = params[:race_info]
		if (race_info.has_key?(:id))
			race = Race.find_by_id(race_info[:id])
		end
		race ||= Race.new
		race.name = race_info[:race_name]
		race.description = race_info[:race_description]
		race.image_url = race_info[:race_image_url]
		race.season_id = session[:season_id]
		create_global_competition = race.id.nil?
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
		
		#Create a global competition and add participants
		Race.create_competition_from_race if (create_global_competition)
		
		render :json=>{:success=>true, :msg=>'success'} and return
	end
	
	def save_results
		stage_id = params[:stage_id]
		race_id = params[:race_id]
		result_data = params[:result_data]
		
		#Clear old result data for this stage
		Result.where({:season_stage_id=>stage_id}).delete_all
		
		result_data.each do |ndx, result|
			data = Result.new
			data.season_stage_id = stage_id
			data.race_id = race_id
			data.rider_id = result[:rider_id].to_i
			if (result[:time]=='DNF' || result[:time]=='DNS')
				data.time = 0
				data.rider_status = RIDER_RESULT_STATUS[result[:time].to_sym]
				
				#Disqualify rider from default rider list
				default_rider = DefaultRider.find_by_rider_id(result[:rider_id])
				if (!default_rider.nil?)
					default_rider.status = STATUS[:INACTIVE]
					default_rider.save
				end
				
				#Add disqualification status to team rider
				teamrider = TeamRider.where('rider_id=? AND race_id=?', result[:rider_id], race_id).joins(:team).first
				if (!teamrider.nil?)
					teamrider = TeamRider.find_by_id(teamrider.id)
					teamrider.rider_status = RIDER_RESULT_STATUS[result[:time].to_sym]
					teamrider.save
				end
			else
				data.time = result[:time].to_f
			end
			data.kom_points = result[:kom_points].to_f
			data.sprint_points = result[:sprint_points].to_f
			data.points = result[:points].to_f
			data.bonus_time = result[:bonus_time].to_i
			data.rank = result[:rank].to_i
			data.save
		end
		
		#Check if any tips for this result need to be defaulted. Go in order of default riders so empty tips are filled accordingly.
		default_riders = DefaultRider.where({:race_id=>race_id}).order('order_id')
		default_riders.each do |default_rider|
			result = Result.where({:season_stage_id=>stage_id, :rider_id=>default_rider.rider_id, :race_id=>race_id}).first
			result.check_valid_tips()
		end
		
		#Mark stage as done
		stage = Stage.find_by_id(stage_id)
		stage.is_complete = true
		stage.save
		
		#Check if any races need to be marked as completed
		Race.check_completion_status(race_id)
		
		#Check if any competitions need to be marked as completed
		competitions = CompetitionStage.where('stage_id=?', stage_id).select('competition_id').group('competition_id, id')
		competitions.each do |competition|
			Competition.check_completion_status(competition.competition_id)
		end
		
		render :json=>{:success=>true}
	end
	
	def save_default_riders
		race_id = params[:race_id]
		season_id = params[:season_id]
		rider_data = params[:rider_data]
		
		ndx = 0
		rider_data.each do |rider_id|
			default_rider = DefaultRider.where({:season_id=>season_id, :race_id=>race_id, :rider_id=>rider_id}).first
			
			default_rider ||= DefaultRider.new
			default_rider.season_id = season_id
			default_rider.race_id = race_id
			default_rider.order_id = ndx
			default_rider.rider_id = rider_id
			default_rider.save
			
			ndx += 1
		end
		
		render :json=>{:success=>true}
	end
	
	def save_quote
		quote_data = params[:quote_data]
		quote = quote_data[:quote]
		author = quote_data[:author]
		
		render :json=>{:success=>false, :msg=>'Please enter a quote.'} and return if (quote.empty?)
		render :json=>{:success=>false, :msg=>'Please enter the author.'} and return if (author.empty?)
		
		data_obj = CyclingQuote.find_by_id(quote_data[:id]) if (quote_data.has_key?(:id))
		
		data_obj ||= CyclingQuote.new
		data_obj.quote = quote
		data_obj.author = author
		data_obj.save
		
		render :json=>{:success=>true, :msg=>'success'}
	end
	
	def save_article
		article_data = params[:article_data]
		
		render :json=>{:success=>false, :msg=>'Please enter a stage ID.'} and return if (article_data[:stage_id].empty?)
		render :json=>{:success=>false, :msg=>'Please enter a title.'} and return if (article_data[:title].empty?)
		render :json=>{:success=>false, :msg=>'Please enter a author.'} and return if (article_data[:author].empty?)
		render :json=>{:success=>false, :msg=>'Please enter a body.'} and return if (article_data[:body].empty?)
		
		stage = Stage.find_by_id(article_data[:stage_id])
		render :json=>{:success=>false, :msg=>'Please enter a valid stage ID.'} and return if (stage.nil?)
		
		article = Article.find_by_id(article_data[:id]) if (article_data.has_key?(:id))
		article ||= Article.new
		
		article.stage_id = article_data[:stage_id]
		article.title = article_data[:title]
		article.author = article_data[:author]
		article.body = article_data[:body]
		article.save
		
		render :json=>{:success=>true, :msg=>'success'}
	end
	
	def delete_quote
		id = params[:id]
		CyclingQuote.where({:id=>id}).delete_all
		
		render :json=>{:success=>true, :msg=>'success'}
	end
	
	def delete_rider
		id = params[:id]
		rider = Rider.find_by_id(id)
		if (!rider.nil?)
			rider.status = STATUS[:DELETED]
			rider.save
		end
		
		render :json=>{:success=>true, :msg=>'success'}
	end
	
	def delete_season_team
		id = params[:id]
		team = Team.find_by_id(id)
		if (!team.nil?)
			team.status = STATUS[:DELETED]
			team.save
		end
		
		render :json=>{:success=>true, :msg=>'succcess'}
	end
	
	def delete_season_race
		id = params[:id]
		race = Race.find_by_id(id)
		if (!race.nil?)
			race.status = STATUS[:DELETED]
			race.save
		end
		
		render :json=>{:success=>true, :msg=>'success'}
	end
	
	def upload_results
		@title = 'Upload stage results'
		if (params.has_key?(:upload))
			@result_keys = []
			@result_data = []
			@stage = nil
			@race = nil
			@season = nil
			
			file_data = params[:upload][:datafile].read
			ndx = 0
			file_data.each_line do |line|
				next if (line.strip.length==0)
				next if (line.start_with?('#'))
				
				ndx += 1
				#Read stage/race/season info
				if (ndx==1)
					line_arr = line.split(',')
					@stage = Stage.find_by_id(line_arr[0].strip)
					@race = Race.find_by_id(line_arr[1].strip)
					@season = Season.find_by_year(line_arr[2].strip)
					next
				end
				
				#Read result keys
				if (line.starts_with?('!'))
					key_line = line[1..-1]
					line_arr = key_line.split(',')
					line_arr.each do |key|
						@result_keys.push(key.strip)
					end
					next
				end
				
				#Read results
				line_arr = line.split(',')
				data = []
				line_arr.each do |l|
					data.push(l.strip)
				end
				@result_data.push(data)
			end
			
			#Sort results
			sort_column = @result_keys.index('time')
			@result_data = @result_data.sort_by {|data| data[sort_column]}
			
			#Special keys
			@rider_column = @result_keys.index('rider_id')
			@time_column = @result_keys.index('time')
		end
	end
	
	def upload_default_riders
		@title = 'Upload default riders'
		
		if (params.has_key?(:upload))
			file_data = params[:upload][:datafile].read
			
			@riders = []
			ndx = 0
			file_data.each_line do |line|
				next if (line.strip.length==0)
				next if (line.start_with?('#'))

				ndx += 1
				#Read race/season info
				if (ndx==1)
					line_arr = line.split(',')
					@race = Race.find_by_id(line_arr[0].strip)
					@season = Season.find_by_year(line_arr[1].strip)
					next
				end
				
				#Read key info
				next if (line.starts_with?('!'))
				
				#Read rider list
				rider_id = line.strip
				@riders.push(Rider.find_by_id(rider_id))
			end
		end
	end
	
	def upload_riders
		@title = 'Upload riders'
		@rider_count = Rider.count
		if (params.has_key?(:upload))
			@result_keys = []
			@result_data = []
			
			file_data = params[:upload][:datafile].read

			file_data.each_line do |line|
				next if (line.strip.length==0)
				next if (line.start_with?('#'))
								
				#Read result keys
				if (line.starts_with?('!'))
					key_line = line[1..-1]
					line_arr = key_line.split(',')
					line_arr.each do |key|
						@result_keys.push(key.strip)
					end
					next
				end
				
				#Read results
				line_arr = line.split(',')
				data = []
				line_arr.each do |l|
					data.push(l.strip)
				end
				@result_data.push(data)
			end
		end
	end
	
	def upload_season_races
		@title = 'Upload season races'
		if (params.has_key?(:upload))
			@result_keys = []
			@result_data = []
			@race_name = ''
			@race_description = ''
			@race_image_url = ''
			
			file_data = params[:upload][:datafile].read
			ndx = 0
			file_data.each_line do |line|
				next if (line.strip.length==0)
				next if (line.start_with?('#'))
				
				ndx += 1
				#Read race name/description/image_url info
				if (ndx==1)
					line_arr = line.split(',')
					@race_name = line_arr[0].strip
					@race_description = line_arr[1].strip
					@race_image_url = line_arr[2].strip
					next
				end
				
				#Read result keys
				if (line.starts_with?('!'))
					key_line = line[1..-1]
					line_arr = key_line.split(',')
					line_arr.each do |key|
						@result_keys.push(key.strip)
					end
					next
				end
				
				#Read results
				line_arr = line.split(',')
				data = []
				line_arr.each do |l|
					data.push(l.strip)
				end
				@result_data.push(data)
			end
		end
	end
	
	def upload_season_teams
		@title = 'Upload season teams'
		if (params.has_key?(:upload))
			@result_keys = []
			@result_data = []
			@team_name = ''
			@team_image_url = ''
			@race_id = ''
			
			file_data = params[:upload][:datafile].read
			ndx = 0
			file_data.each_line do |line|
				next if (line.strip.length==0)
				next if (line.start_with?('#'))
				
				ndx += 1
				#Read race name/description/image_url/team_id(OPT) info
				if (ndx==1)
					line_arr = line.split(',')
					@team_name = line_arr[0].strip
					@team_image_url = line_arr[1].strip
					@race_id = line_arr[2].strip
					@team_id = line_arr[3].strip if (!line_arr[3].nil?)
					@race = Race.find_by_id(@race_id)
					next
				end
				
				#Read result keys
				if (line.starts_with?('!'))
					key_line = line[1..-1]
					line_arr = key_line.split(',')
					line_arr.each do |key|
						@result_keys.push(key.strip)
					end
					next
				end
				
				#Read results
				line_arr = line.split(',')
				data = []
				line_arr.each do |l|
					data.push(l.strip)
				end
				@result_data.push(data)
			end
		end
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
