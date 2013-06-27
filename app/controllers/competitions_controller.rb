class CompetitionsController < ApplicationController
	skip_before_filter :verify_authenticity_token
	
	#require 'race_module'
	require_dependency 'leaderboard_module'
	require_dependency 'race_module'
	
	#Title:			index
	#Description:	Show competition grid
	def index
		uid = 0
		options = {}
		if (!@user.nil?)
			uid = @user.id
			options[:limit] = 11
		else
			options[:limit] = 12
		end
		competition_list = Competition.get_competitions(uid, options)
		
		@competitions = []
		competition_list.each do |competition|
			data = {}
			data[:competition] = competition
			if (@user.nil?)
				data[:is_participant] = false
				data[:is_creator] = false
			else
				is_participant = CompetitionParticipant.where('competition_id=? AND user_id=?', competition.id, @user.id)
				data[:is_participant] = !is_participant.empty?
				data[:is_creator] = (uid==competition.creator_id)
			end
			@competitions.push(data)
		end
		render :layout => nil
	end
	
	#Title:			show
	#Description:	General information about a competition
	def show
		#Check for login via access token
		return if login_with_token.nil?

		#Competition
		@competition = Competition.find_by_id(params[:id])
		redirect_to :root and return if (@competition.nil?)
		
		#Redirect path
		redirect_path = case @scope
		when COMPETITION_SCOPE[:CYCLINGTIPS]
			'/races/racebox/' + @competition.race_id.to_s + '?' + @iframe_params
		else
			:root
		end

		user_id = 0
		user_id = @user.id if (!@user.nil?)
		
		if (@competition.status==STATUS[:ACTIVE])
		elsif (@competition.status==STATUS[:PRIVATE])
			#Check participation
			participating = CompetitionParticipant.where({:competition_id=>@competition.id, :user_id=>user_id, :status=>STATUS[:ACTIVE]})
			#Check code if not participating
			if (participating.empty?)
				@code = nil
				@code = params[:code] if (params.has_key?(:code))
				redirect_to redirect_path and return if (!Competition.is_competition_code_valid(@competition.id, @code))
			end
		else
			redirect_to redirect_path and return
		end
		
		#Show this competition on login
		set_auth_redirect(request.fullpath) if (user_id == 0)
		
		@stage_id = params[:stage_id] if (params.has_key?(:stage_id))
		
		#Get leaderboard
		@leaderboard = LeaderboardModule::get_leaderboard(params[:id], 'race', @competition.race_id)

		#Creator
		@creator = User.find_by_id(@competition.creator_id)
		
		#Number of participants
		participants = CompetitionParticipant.where({:competition_id=>params[:id], :status=>STATUS[:ACTIVE]})
		@num_participants = participants.count
		
		#Check if participating
		is_participant = participants.where({:user_id=>user_id})
		@participating = (!is_participant.empty?)
		
		#Race
		@race = Race.find_by_id(@competition.race_id)
		
		#Completed stage count
		@stages = Stage.where({:race_id=>@competition.race_id, :status=>STATUS[:ACTIVE]}).order('starts_on')

		@total_stages = @stages.count
		@completed_stages = @stages.where({:is_complete=>true}).count
		
		#Get top 2 sprint
		@top_sprints = LeaderboardModule::get_top(:sprint, 2, @leaderboard)
		
		#Get top 2 KOM
		@top_koms = LeaderboardModule::get_top(:kom, 2, @leaderboard)
		
		#Competition reports
		@reports = []
		#Get admin reports
		admin_reports = TippingReport.where('stages.race_id=? AND tipping_reports.status=? AND (report_type=? OR report_type=?)', @race.id, STATUS[:ACTIVE], REPORT_TYPE[:STAGE], REPORT_TYPE[:PREVIEW]).joins(:stage)
		admin_reports.each do |r|
			@reports.push({
				:title=>r.title,
				:report=>r.report,
				:stage_id=>r.stage_id,
				:stage_name=>r.stage.name,
				:stage_starts_on=>r.stage.starts_on,
				:report_type=>r.report_type
			})
		end
		#Get user reports
		user_reports = TippingReport.where({:competition_id=>@competition.id, :report_type=>REPORT_TYPE[:TIPPING], :status=>STATUS[:ACTIVE]})
		user_reports.each do |r|
			@reports.push({
				:title=>r.title,
				:report=>r.report,
				:stage_id=>r.stage_id,
				:stage_name=>r.stage.name,
				:stage_starts_on=>r.stage.starts_on,
				:report_type=>r.report_type
			})
		end
		@reports = @reports.sort_by{|r| r[:stage_starts_on]}
		
		#Left nav data
		@left_nav_data = RaceModule::get_left_nav_data(@stages, params[:id], user_id)
		
		#Cycling tips display
		render :layout=>'cyclingtips' and return if (params.has_key?(:display) && params[:display]=='cyclingtips')
	end
	
	#Title:			results
	#Description:	Show results for a race in this competition
	def results
		competition_id = params[:id]
		@data = get_competition_data(competition_id)
		
		@races = []
		CompetitionStage.where({:competition_id=>competition_id, :status=>STATUS[:ACTIVE]}).select(:race_id).group(:race_id).each do |competition_stage|
			race_id = competition_stage.race_id
			race_data = Race.find_by_id(race_id)
			stages = Stage.where({:race_id=>race_id, :status=>STATUS[:ACTIVE], :is_complete=>true}).order('starts_on')
			@races.push({:race_data=>race_data, :stages=>stages})
		end
		
		render :layout => 'competition'
	end
	
	#Title:			leaderboard
	#Description:	Shows the competition leaderboard framework
	def leaderboard
		competition_id = params[:id]
		@data = get_competition_data(competition_id)
		
		@races = []
		CompetitionStage.where({:competition_id=>competition_id, :status=>STATUS[:ACTIVE]}).select(:race_id).group(:race_id).each do |competition_stage|
			race_id = competition_stage.race_id
			race_data = Race.find_by_id(race_id)
			stages = Stage.where({:race_id=>race_id, :status=>STATUS[:ACTIVE], :is_complete=>true}).order('starts_on')
			@races.push({:race_data=>race_data, :stages=>stages})
		end
		
		render :layout => 'competition'
	end
	
	#Title:			get_competition_leaderboard
	#Description:	Get leaderboard for a competition (JSON)
	def get_competition_leaderboard
		competition_id = params[:id]
		group_type = params[:group_type]
		group_id = params[:group_id]
		
		leaderboard = LeaderboardModule::get_leaderboard(competition_id, group_type, group_id)
		@data = []
		
		ndx = 1
		max_rank = display_rank = 0
		
		leaderboard.each do |entry|
			if (!entry[:rank].nil?)
				#Same rider ranking = same user ranking
				if (entry[:rank] > max_rank) 
					display_rank = ndx
					max_rank = entry[:rank]
				end
			else
				display_rank = ndx
			end
			
			line = {
				:user_id => entry[:user_id],
				:username => entry[:username],
				:time_formatted => entry[:formatted_time],
				:gap_formatted => entry[:formatted_gap],
				:kom => entry[:kom],
				:sprint => entry[:sprint],
				:rank => display_rank
			}
			if (group_type == 'stage')
				line[:tip] = entry[:tip]
				line[:is_default] = entry[:is_default]
				line[:original_rider] = entry[:original_rider]
			end
			@data.push(line)
			ndx += 1
		end
		
		render :json => {:leaderboard => @data}
	end
	
	#Title:			user_race_data
	#Description:	Return competition data about a user in a race
	def user_race_data
		race_id = params[:id]
		user_id = params[:user_id]
		
		race = Race.find_by_id(race_id)
		response = RaceModule::get_user_race_data(user_id, race, @scope)
		
		render :json => response
	end
	
	#Title:			show_tips
	#Description:	Shows a user's tips in the competition
	def show_tips
		competition_id = params[:id]
		@data = get_competition_data(competition_id)
		uid = params[:uid]
		
		@tips = get_user_tips(competition_id, uid)
		
		render :layout=>'competition'
	end
	
	#Title:			default_riders
	#Description:	Show the default riders for races in this competitions
	def default_riders
		competition_id = params[:id]
		@data = get_competition_data(competition_id)
		
		#Race list
		@races = []
		CompetitionStage.where({:competition_id=>competition_id, :status=>STATUS[:ACTIVE]}).select(:race_id).group(:race_id).each do |competition_stage|
			race_id = competition_stage.race_id
			race_data = Race.find_by_id(race_id)
			@races.push(race_data)
		end
		
		render :layout=>'competition'
	end
	
	#Title:			get_default_riders
	#Description:	Gets list of default riders for a race
	def get_default_riders
		race_id = params[:race_id]
		competition_id = (params.has_key?(:id))?params[:id]:0
		uid = (@user.nil?)?nil:@user.id
		
		default_riders = DefaultRider.where({:race_id=>race_id}).order(:order_id)
		@data = []
		default_riders.each do |default_rider|
			#Get rider info
			rider = Rider.find_by_id(default_rider.rider_id)
			#Get tip info
			selected = nil
			if (!competition_id.nil? && !uid.nil?)
				#Chosen by default?
				stage_id = CompetitionTip.select(:stage_id).where({:competition_participant_id=>uid, :race_id=>race_id, :competition_id=>competition_id, :default_rider_id=>rider.id})
				#Chosen as tip?
				stage_id = CompetitionTip.select(:stage_id).where({:competition_participant_id=>uid, :race_id=>race_id, :competition_id=>competition_id, :rider_id=>rider.id}) if (stage_id.nil?)
				
				stage = Stage.find_by_id(stage_id)
				selected = stage.name if (!stage.nil?)
			end
			
			rider_data = {
				:name => rider.name,
				:disqualified => Result.rider_status_to_str(default_rider.status),
				:selected => selected
			}
			@data.push(rider_data)
		end
		
		render :json=>{:default_riders => @data}
	end
	
	#Title:			tip
	#Description:	Leave a tip
	def tip
		redirect_to :root and return if (@user.nil?)
		competition_id = params[:id]
		@data = get_competition_data(competition_id)
		@tipping_allowed = false
		
		@races = []
		CompetitionStage.where({:competition_id=>competition_id, :status=>STATUS[:ACTIVE]}).select(:race_id).group(:race_id).each do |competition_stage|
			race_id = competition_stage.race_id
			race_data = Race.find_by_id(race_id)
			stages = Stage.where('race_id=? AND status=? AND starts_on >?', race_id, STATUS[:ACTIVE], Time.now).order('starts_on')
			@races.push({:race_data=>race_data, :stages=>stages})
			
			@tipping_allowed = true if (!stages.empty?)
		end
		
		render :layout => 'competition'
	end
	
	#Title:			get_tip_sheet
	#Description:	Get tip sheet for a user
	def get_tip_sheet
		redirect_to :root and return if (@user.nil?)

		competition_id = params[:id]
		stage_id = params[:stage_id]
		uid = @user.id
		
		#Check if stage is in competition
		competition_stage = CompetitionStage.where({:competition_id=>competition_id, :stage_id=>stage_id}).first
		redirect_to :root and return if (competition_stage.nil?)

		#Get all tips
		race_id = competition_stage.race_id
		tips = CompetitionTip.where({:competition_participant_id=>uid, :competition_id=>competition_id, :race_id=>race_id})
		tips_by_rider = {}
		tips.each do |tip|
			rider_id = tip.rider_id
			rider_id = tip.default_rider_id if (rider_id==0 && !tip.default_rider_id.nil?)
			tips_by_rider[rider_id] = tip.stage_id
		end
		
		#Get all rider teams
		teamriders = TeamRider.where({:race_id=>race_id, :status=>STATUS[:ACTIVE]}).joins(:team).joins(:rider).order('rider_number')

		#Index riders by team
		teams = {}
		teamriders.each do |teamrider|
			team = teamrider.team
			rider = teamrider.rider
			
			#Check allowed status
			allowed = Hash.new
			if (teamrider.rider_status != RIDER_RESULT_STATUS[:ACTIVE])
				allowed[:allowed] = false
				allowed[:reason] = Result.rider_status_to_str(teamrider.rider_status)
			elsif (!tips_by_rider[rider.id].nil? && tips_by_rider[rider.id].to_i != stage_id.to_i)
				stage = Stage.find_by_id(tips_by_rider[rider.id])
				allowed[:allowed] = false
				allowed[:reason] = stage.name
			else
				allowed[:allowed] = true
				allowed[:reason] = 'Open'
			end
			
			#Is current selection
			selected = (tips_by_rider[rider.id].to_i == stage_id.to_i)

			team_data = teams[team.id] || {:team=>team, :riders=>[]}
			team_data[:riders].push({
				:rider_id => rider.id,
				:rider_name => rider.name,
				:rider_number => teamrider.rider_number,
				:allowed => allowed,
				:selected => selected
			})
			teams[team.id] = team_data
		end
		
		#Generate tipsheet
		seen = {}
		tipsheet = []
		teamriders.each do |teamrider|
			team_id = teamrider.team_id
			next if (!seen[team_id].nil?)
			tipsheet.push({
				:team_name => teams[team_id][:team].name,
				:riders => teams[team_id][:riders]
			})
			seen[team_id] = 1
		end
		
		stage = Stage.find_by_id(stage_id)
		render :json => {:tipsheet=>tipsheet, :stage=>{:name=>stage.name, :remaining=>(stage.starts_on-Time.now).to_i}}
	end
	
	#Title:			get_selection_sheet
	#Description:	Get selection sheet for a user
	def get_selection_sheet
		redirect_to :root and return if (@user.nil?)

		competition_id = params[:id]
		race_id = params[:race_id]
		uid = @user.id
		
		#Check if stage is in competition
		competition_stage = CompetitionStage.where({:competition_id=>competition_id, :race_id=>race_id}).first
		redirect_to :root and return if (competition_stage.nil?)

		#Get all tips
		tips = CompetitionTip.where({:competition_participant_id=>uid, :competition_id=>competition_id, :race_id=>race_id})
		tips_by_rider = {}
		tips.each do |tip|
			rider_id = tip.rider_id
			rider_id = tip.default_rider_id if (rider_id==0 && !tip.default_rider_id.nil?)
			tips_by_rider[rider_id] = tip.stage_id
		end
		
		#Get all rider teams
		teamriders = TeamRider.where({:race_id=>race_id, :status=>STATUS[:ACTIVE]}).joins(:team).joins(:rider).order('rider_number')

		#Index riders by team
		teams = {}
		teamriders.each do |teamrider|
			team = teamrider.team
			rider = teamrider.rider
			
			#Check is rider is disqualified, or already selected
			stage = nil
			disqualified = nil
			if (teamrider.rider_status != RIDER_RESULT_STATUS[:ACTIVE])
				disqualified = Result.rider_status_to_str(teamrider.rider_status)
			elsif (!tips_by_rider[rider.id].nil?)
				stage = Stage.find_by_id(tips_by_rider[rider.id])
				stage = stage.name
			end
				#Add selected field to differentiate between selected and DQ -> Can populate input box on selection sheet
			team_data = teams[team.id] || {:team=>team, :riders=>[]}
			team_data[:riders].push({
				:rider_id => rider.id,
				:rider_name => rider.name,
				:rider_number => teamrider.rider_number,
				:disqualified => disqualified,
				:stage => stage
			})
			teams[team.id] = team_data
		end
		
		#Generate selection_sheet
		seen = {}
		selection_sheet = []
		teamriders.each do |teamrider|
			team_id = teamrider.team_id
			next if (!seen[team_id].nil?)
			selection_sheet.push({
				:team_name => teams[team_id][:team].name,
				:riders => teams[team_id][:riders]
			})
			seen[team_id] = 1
		end
		
		render :json => {:selection_sheet=>selection_sheet}
	end
	
	#Title:			edit
	#Description:	Edit or create a new competition
	def edit
		redirect_to :root and return if (@user.nil?)
		
		@competition = nil
		@competition = Competition.find_by_id(params[:id]) if (params.has_key?(:id))
		
		redirect_to :root and return if (!@competition.nil? && @user.id != @competition.creator_id)
		
		@id = params[:id] if (params.has_key?(:id))
		@races = Race.where({:status=>STATUS[:ACTIVE], :is_complete=>FALSE})
		if (!@competition.nil?)
			@is_private = (@competition.status == STATUS[:PRIVATE])
		else
			@is_private = false
		end
		
		@competition_race = Competition.get_all_races(@competition.id).first.race if (!@competition.nil?)
			
		@competition ||= Competition.new
		render :layout=>false
	end
	
	def edit_participants
		@competition_id = params[:id]
		@competition = Competition.find_by_id(@competition_id)
		@participants = CompetitionParticipant.where({:competition_id=>@competition_id, :status=>STATUS[:ACTIVE]}).joins(:user).group('competition_participants.id, competition_participants.user_id')
		render :layout=>false
	end
	
	
	
	#Title:			fill_tips
	#Description:	Fill default user tips for a competition
	#Params:		competition_id
	def fill_tips
		competition_id = params[:competition_id]
		
		participants = CompetitionParticipant.where({:competition_id=>competition_id, :status=>STATUS[:ACTIVE]})
		participants.each do|participant|
			user_id = participant.user_id
			CompetitionTip.fill_tips(user_id, competition_id)
		end
		
		render :text=>'Tips filled. You may close this page now.'
	end
	
	
	#POST
	#Title:			save_competition
	#Description:	Save competition (except image)
	def save_competition
		render :json=>{:success=>false, :msg=>'An error occurred. Please refresh your browser and try again.'} and return if (!params.has_key?(:data))
		render :json=>{:success=>false, :msg=>'You are not logged in.'} and return if (@user.nil?)
		
		current_year = Time.now.year
		season = Season.find_by_year(current_year)
		render :json=>{:success=>false, :msg=>'This season has not been released yet.'} and return if (season.nil?)
		season_id = season.id
		
		competition_data = params[:data]
		
		#Load competition if any
		competition = nil
		if (competition_data.has_key?(:id))
			competition = Competition.find_by_id(competition_data[:id])
		end
		
		render :json=>{:success=>false, :msg=>'Please enter a name for your competition.'} and return if (!competition_data.has_key?(:competition_name) || competition_data[:competition_name].empty?)
		
		#Save competition
		new_competition = competition.nil?
		competition ||= Competition.new
		
		competition.creator_id = @user.id
		competition.name = competition_data[:competition_name]
		competition.description = competition_data[:competition_description]
		competition.season_id = season_id
		competition.race_id = competition_data[:race_id]
		competition.scope = @scope if (new_competition)

		if (competition_data[:open_to]=='private')
			competition.status = STATUS[:PRIVATE]
		else
			competition.status = STATUS[:ACTIVE]
		end

		competition.status = STATUS[:PRIVATE] if !@user.is_admin

		#Generate competition invitation code
		base =  [('a'..'z'),('A'..'Z')].map{|i| i.to_a}.flatten
		competition.invitation_code  ||=  (0...10).map{ base[rand(base.length)] }.join
		competition.save
		
		#Add user as participant
		participation = CompetitionParticipant.where({:competition_id=>competition.id, :user_id=>@user.id, :status=>STATUS[:ACTIVE]}).first
		CompetitionParticipant.add_participant(@user.id, competition.id, @scope) if (participation.nil?)
		
		#Generate invitations
		emails = competition_data[:invitations]
		email_array = emails.split(',')
		email_array.each do |email|
			#If not empty
			if(!email.strip().empty?)
				invited_user = User.find_by_email(email.strip.downcase)
				CompetitionInvitation.invite_user(invited_user.id, competition.id) if (!invited_user.nil?)
			end
		end
		
		#Save races/stages
		CompetitionStage.update_all({:status=>STATUS[:DELETED]}, {:competition_id=>competition.id})
		race_id = competition_data[:race_id]
		competition_races = []
		stages = Stage.where('race_id=? AND season_id=? AND status=?', race_id, season_id, STATUS[:ACTIVE])
		stages.each do |stage|
			competition_stage = CompetitionStage.where('stage_id=? AND competition_id=? AND status=?', stage.id, competition.id, STATUS[:ACTIVE]).first
			competition_stage ||= CompetitionStage.new
			competition_stage.competition_id = competition.id
			competition_stage.stage_id = stage.id
			competition_stage.race_id = race_id
			competition_stage.status = STATUS[:ACTIVE]
			competition_stage.save
		end
		
		#Set default tips (also needed if new stages were added)
		participants = CompetitionParticipant.where({:competition_id=>competition.id, :status=>STATUS[:ACTIVE]})
		participants.each do|participant|
			user_id = participant.user_id
			CompetitionTip.fill_tips(user_id, competition.id)
		end
		
		#Send user their competition link
		AppMailer.competition_link(competition).deliver
		
		#Send emails
		send_competition_invitations(competition_data[:invitations], competition)

		render :json=>{:success=>true, :msg=>'success', :id=>competition.id, :data=>{:name=>competition.name, :link=>competition.get_invitation_link}}
	end
	
	#Title:			save_image
	#Description:	Save competition image
	def save_image
		competition_id = params[:competition_id]
		competition = Competition.find_by_id(competition_id)
		
		#Check that competition exists and user is allowed to save
		redirect_to :root if (competition.creator_id != @user.id)
		
		redirect_to '/competition/'+competition_id.to_s and return if (params[:image_name].nil? || params[:image_name].empty?)
		
		#Save competition image path
		competition.image_url = 'competition_'+competition_id.to_s+'.jpg'
		competition.save
		
		if (!params[:image].nil?)
			options = {
				:public_id => "competition_"+competition_id.to_s,
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
		
		redirect_to '/competition/'+competition_id.to_s
	end
	
	def delete_competition
		render :json=>{:success=>false, :msg=>'User not logged in.'} and return if (@user.nil?)
		render :json=>{:success=>false, :msg=>'There was an error. Please refresh your browser and try again.'} and return if (!params.has_key?(:id))
		
		competition = Competition.find_by_id(params[:id])
		render :json=>{:success=>false, :msg=>'Competition not found.'} and return if (competition.nil?)
		render :json=>{:success=>false, :msg=>'You do not have permission to edit this competition.'} and return if (@user.id != competition.creator_id)
		
		competition.status = STATUS[:DELETED]
		competition.save
		
		CompetitionParticipant.find_and_set_primary_competition(competition.race_id, @user.id, @scope)
		
		render :json=>{:success=>true, :msg=>'success'}
	end
	
	#Title:			add_participants_to_global_competition
	#Description:	Calls a worker process to add participants to a global competition
	def add_participants_to_global_competition
		competition = Competition.where({:competition_type=>COMPETITION_TYPE[:GLOBAL]}).order('id DESC').limit(1).first
		msg = competition.add_participants_to_global_competition
		
		render :json => {:response=>{:sucess=>true, :msg=>msg}}
	end
	
	#JSON
	
	#Title:			get_competition_info
	#Description:	Gets information about a competition
	def get_competition_info
		render :json=>{:success=>false, :msg=>'No competition ID specified.'} and return if (!params.has_key?(:id))
		
		competition_id = params[:id]
		competition = Competition.find_by_id(competition_id) || Competition.new
		
		render :json=>{:success=>true, :data=>{
			:id => competition_id,
			:name => competition.name,
			:description => competition.description,
			:is_private => (competition.status == STATUS[:PRIVATE])
		}} and return
	end
	
	#Title:			get_competition_stage_info
	#Description:	Retrieves stage info for a competition's race including selected tip.
	#Returns:		JSON of data array
	def get_competition_stage_info
		render :json=>{:success=>false} and return if (!params.has_key?(:stage_id) || !params.has_key?(:competition_id))
		render :json=>{:success=>false} and return if (@user.nil?)
		
		stage = Stage.find_by_id(params[:stage_id])
		tip = CompetitionTip.where({
			:competition_participant_id=>@user.id, 
			:competition_id=>params[:competition_id],
			:stage_id=>params[:stage_id]
		}).first
		
		tipped_rider_id = nil
		tipped_rider_id = tip.rider_id if (!tip.nil?)
		
		#Sort fields
		sort_field = sort_dir = ''
		sort_field = params[:sort].strip if (params.has_key?(:sort))
		sort_dir = params[:dir] if (params.has_key?(:dir))
		
		data = {
			:stage_id => stage.id,
			:stage_name => stage.name,
			:stage_description => stage.description,
			:stage_image_url => stage.image_url,
			:stage_profile => stage.profile,
			:stage_starts_on => stage.starts_on,
			:stage_start_location => stage.start_location,
			:stage_end_location => stage.end_location,
			:stage_distance_km => stage.distance_km,
			:tipped_rider_id => tipped_rider_id,
			:time_to_tip => get_remaining_time(stage.starts_on),
			:race_id => stage.race_id,
			:sort_field => sort_field,
			:sort_dir => sort_dir
		}
		
		stage_results = []
		if (stage.starts_on < Time.now)
			results = Result.get_results('stage', stage.id, {:sort_field=>sort_field, :sort_dir=>sort_dir})
			data[:stage_results] = results
		end
		
		render :json=>{:data=>data}
	end
	
	#Title:			get_competition_other_info
	#Description:	Retrieves tie breaker and default riders
	#Returns:		JSON of data array
	def get_competition_other_info
		uid = nil
		uid = @user.id if (!@user.nil?)
		
		competition_id = params[:id]
		competition = Competition.find_by_id(competition_id)
		
		#Participation status
		is_participant = false
		competition_participant = nil
		if (!uid.nil?)
			competition_participant = CompetitionParticipant.where({:user_id=>uid, :competition_id=>competition_id}).first
			is_participant = (!competition_participant.nil?)
		end
		
		#Default riders
		default_riders = DefaultRider.get_default_riders(competition.race_id, competition_id, uid)
		
		#Get tie breaker time
		tie_break_time_sec = 0
		tie_break_time_sec = (competition_participant.tie_break_time||0) if (!competition_participant.nil?)
		tie_break_time = break_time(tie_break_time_sec)
		
		#Get tie break rider
		tie_break_rider_id = nil
		tie_break_rider_id = competition_participant.tie_break_rider_id if (!competition_participant.nil?)
		
		#Rider list
		tie_break_riders = []
		riders = TeamRider.where({:race_id=>competition.race_id, :rider_status=>STATUS[:ACTIVE]})
		riders.each do |rider|
			tie_break_riders.push({
				:rider_id => rider.rider_id,
				:rider_name => rider.rider.name,
				:selected => (rider.rider_id == tie_break_rider_id)
			})
		end
		
		render :json=>{
			:competition_id => competition_id,
			:user_id => uid,
			:is_participant=>is_participant, 
			:default_riders=>default_riders, 
			:tie_break_riders=>tie_break_riders,
			:tie_break_time=>tie_break_time,
			:is_creator => (competition.creator_id == uid)
		}
	end
	
	#Title:			get_more_competitions
	#Description:	Gets next set of competitions
	#Returns:		JSON of data array
	def get_more_competitions
		uid = 0
		uid = @user.id if (!@user.nil?)
		
		options = {}
		options[:limit] = params[:limit] if (params.has_key?(:limit) && !params[:limit].empty?)
		options[:offset] = params[:offset] if (params.has_key?(:offset) && !params[:limit].empty?)
		
		competition_data = []
		competitions = Competition.get_competitions(uid, options)
		competitions.each do |competition|
			data = {}
			data[:id] = competition.id
			data[:creator_id] = competition.creator_id
			data[:name] = competition.name
			data[:description] = competition.description
			data[:image_url] = Cloudinary::Utils.cloudinary_url(competition.image_url, {:width=>220, :height=>180, :crop=>:crop})
			data[:is_complete] = competition.is_complete
			if (uid==0)
				data[:is_participant] = false
			else
				is_participant = CompetitionParticipant.where('competition_id=? AND user_id=?', competition.id, @user.id)
				data[:is_participant] = !is_participant.empty?
			end
			competition_data.push(data)
		end
		
		render :json=>{:competition_data=>competition_data}
	end
	
	#JSON
	
	#Title:			delete_competition
	#Description:	Delete a competition
	def delete_competition
		render :json=>{:success=>false, :msg=>'User not logged in.'} and return if (@user.nil?)
		render :json=>{:success=>false, :msg=>'Competition ID not specified.'} and return if (!params.has_key?(:id))
		
		#Check competition
		competition_id = params[:id]
		competition = Competition.find_by_id(competition_id)
		render :json=>{:success=>false, :msg=>'Invalid competition'} and return if (competition.nil?)
		
		#Is user creator?
		render :json=>{:success=>false, :msg=>'Only the creator can delete a competition.'} and return if (competition.creator_id != @user.id)
		
		competition.status = STATUS[:DELETED]
		competition.save
		
		render :json=>{:success=>true, :msg=>'Competition deleted.'} and return
		
	end
	
	#Title:			remove_invitation
	#Description:	Sets a invitation as DELETED
	def remove_invitation
		render :json=>{:success=>false, :msg=>'User not logged in.'} and return if (@user.nil?)
		render :json=>{:success=>false, :msg=>'No competition selected'} and return if (!params.has_key?(:id))
		
		invitation = CompetitionInvitation.where({:competition_id=>params[:id], :user_id=>@user.id, :status=>STATUS[:ACTIVE]}).first
		if (!invitation.nil?)
			invitation.status = STATUS[:DELETED]
			invitation.save
		end
		
		render :json=>{:success=>true, :msg=>'success'}
	end
	
	#Title:			join
	#Description:	Join a competition
	def join
		render :json=>{:success=>false, :msg=>'User not logged in.'} and return if (@user.nil?)
		render :json=>{:success=>false, :msg=>'No competition selected'} and return if (!params.has_key?(:id))
		
		competition_id = params[:id]
		
		competition = Competition.find_by_id(competition_id)
		if (competition.status == STATUS[:ACTIVE])
			CompetitionParticipant.add_participant(@user.id, competition_id, @scope)
		elsif (competition.status == STATUS[:PRIVATE])
			code = nil
			code = params[:code] if params.has_key?(:code)
			if Competition.is_competition_code_valid(competition_id, code)
				CompetitionParticipant.add_participant(@user.id, competition_id, @scope) 
			else
				render :json=>{:success=>false, :msg=>'Could not join competition. Incorrect invitation code.'} and return
			end
		end
		
		#Check if joined successfully
		participant = CompetitionParticipant.where({:competition_id=>competition_id, :user_id=>@user.id, :status=>STATUS[:ACTIVE]}).first
		render :json=>{:success=>false, :msg=>'Could not join competition. You may have been kicked out.'} and return if (participant.nil?)
		
		CompetitionInvitation.delete_invitation(@user.id, competition_id)
		render :json=>{:success=>true, :msg=>'success'}
	end
	
	#Title:			save_tip
	#Description:	Save a tip
	def save_tip
		render :json=>{:success=>false, :msg=>'Rider not selected.'} and return if (!params.has_key?(:rider_id))
		render :json=>{:success=>false, :msg=>'Competition not selected.'} and return if (!params.has_key?(:id))
		render :json=>{:success=>false, :msg=>'Stage not selected.'} and return if (!params.has_key?(:stage_id))
		render :json=>{:success=>false, :msg=>'User not logged in.'} and return if (@user.nil?)
		
		#Determine if tipping is open
		stage = Stage.find_by_id(params[:stage_id])
		render :json=>{:success=>false, :msg=>'Tipping has ended for this stage.'} and return if (stage.starts_on < Time.now)
		
		#Determine if rider exists
		teamrider = TeamRider.where({:rider_id=>params[:rider_id], :race_id=>stage.race_id})
		render :json=>{:success=>false, :msg=>'This rider is not part of the race.'} and return if (teamrider.empty?)
		
		#Determine if user is trying to tip a disqualified rider
		teamrider = TeamRider.where('rider_id=? AND race_id=? AND rider_status<>?', params[:rider_id], stage.race_id, RIDER_RESULT_STATUS[:ACTIVE])
		render :json=>{:success=>false, :msg=>'This rider has been disqualified.'} and return if (!teamrider.empty?)
		
		#Determine if user is in competition
		participant = CompetitionParticipant.where({:competition_id=>params[:id], :user_id=>@user.id, :status=>STATUS[:ACTIVE]})
		render :json=>{:success=>false, :msg=>'You need to join a competition to tip.'} and return if (participant.empty?)
		
		tip = CompetitionTip.where({
			:competition_participant_id => @user.id,
			:stage_id => params[:stage_id],
			:competition_id => params[:id],
		}).first
		
		tip ||= CompetitionTip.new
		tip.competition_participant_id = @user.id
		tip.stage_id = params[:stage_id]
		tip.rider_id = params[:rider_id]
		tip.race_id = stage.race_id
		tip.competition_id = params[:id]
		tip.default_rider_id = nil
		
		#Determine if rider has already been selected
		render :json=>{:success=>false, :msg=>'This rider has already been used.'} and return if (tip.is_duplicate())
		
		tip.save
		
		rider = Rider.find_by_id(params[:rider_id])
		
		render :json=>{:success=>true, :msg=>stage.name, :data=>{
			:rider_id => rider.id,
			:rider_name => rider.name
		}}
	end
	
	#Title:			kick
	#Description:	Remove a user from competition
	def kick
		render :json=>{:success=>false, :msg=>'User not logged in.'} and return if (@user.nil?)
		
		competition_id = params[:id].to_i
		if (params.has_key?(:user_id) && !params[:user_id].empty?)
			msg = 'User has been kicked from the competition.'
			user_id = params[:user_id].to_i
			#Check if user has authority
			competition = Competition.find_by_id(competition_id)
			render :json=>{:success=>false, :msg=>'Cannot kick creator.'} and return if (competition.creator_id == user_id)
			render :json=>{:success=>false, :msg=>'You do not have permission to do that.'} and return if (competition.creator_id != @user.id)
		else
			msg = 'You have left the competition.'
			user_id = @user.id
		end
			
		#Find participant and kick
		participant = CompetitionParticipant.where({:competition_id=>competition_id, :user_id=>user_id}).first
		if (!participant.nil?)
			participant.status = STATUS[:DELETED]
			participant.save
		end
		
		CompetitionParticipant.find_and_set_primary_competition(competition.race_id, user_id, @scope)
		render :json=>{:success=>true, :msg=>msg}
	end
	
	#Title:			save_tie_break_info
	#Description:	Saves information about tie breaks
	def save_tie_break_info
		render :json=>{:success=>false, :msg=>'User not logged in.'} and return if (@user.nil?)
		
		#Valid competition?
		competition_id = params[:id]
		competition = Competition.find_by_id(competition_id)
		render :json=>{:success=>false, :msg=>'Invalid competition.'} and return if (competition.nil?)
		
		####
		## Some logic to check whether tie break can be save.
		## can_save = Model.can_save? (Use this in the get_other_info function to determine whether to disable tie breaks
		###
		
		#Rider ID
		render :json=>{:success=>false, :msg=>'Please select a rider.'} and return if (!params.has_key?(:rider_id))
		rider = Rider.find_by_id(params[:rider_id])
		render :json=>{:success=>false, :msg=>'Invalid rider.'} and return if (rider.nil?)
		
		time_sec = (params[:days].to_i*24*60*60) + (params[:hours].to_i*60*60) + (params[:minutes].to_i*60) + params[:seconds].to_i
		
		#Participation record
		competition_participant = CompetitionParticipant.where({:competition_id=>competition_id, :user_id=>@user.id}).first
		render :json=>{:success=>false, :msg=>'Participation record not found.'} and return if (competition_participant.nil?)
		
		#Save tie breaks
		competition_participant.tie_break_rider_id = rider.id
		competition_participant.tie_break_time = time_sec
		competition_participant.save
		
		render :json=>{:success=>true, :msg=>'success'}
	end
	
	#Title:			save_report
	#Description:	Save a tipping report for a competition's stage
	def save_report
		render :json=>{:sucess=>false, :msg=>'No competition specified'} and return if (!params.has_key?(:id))
		render :json=>{:sucess=>false, :msg=>'No stage specified'} and return if (!params.has_key?(:stage_id))
		
		#Check competition
		competition = Competition.find_by_id(params[:id])
		render :json=>{:success=>false, :msg=>'Competition not found.'} and return if (competition.nil?)
		
		#Check user
		render :json=>{:success=>false, :msg=>'No user found'} and return if (@user.nil?)
		render :json=>{:sucsess=>false, :msg=>'User not authorized.'} and return if (competition.creator_id != @user.id)
		
		#Check title
		render :json=>{:sucess=>false, :msg=>'Please enter a title.'} and return if (!params.has_key?(:title) || params[:title].empty?)
		
		#Check report
		render :json=>{:sucess=>false, :msg=>'Please enter a report.'} and return if (!params.has_key?(:report) || params[:report].empty?)
		
		#Get the tipping report
		report = TippingReport.where({:status=>STATUS[:ACTIVE], :competition_id=>params[:id], :stage_id=>params[:stage_id]}).first || TippingReport.new
		
		#Save report
		report.competition_id = params[:id]
		report.stage_id = params[:stage_id]
		report.title = params[:title]
		report.report = params[:report]
		report.report_type = REPORT_TYPE[:TIPPING]
		report.save
		
		render :json=>{:success=>true, :msg=>report.id}
	end
	
	#Title:			delete_report
	#Description:	Delete a tipping report for a competition's stage
	def delete_report
		render :json=>{:sucess=>false, :msg=>'No report specified'} and return if (!params.has_key?(:id))
		
		#Check report
		report = TippingReport.find_by_id(params[:id])
		render :json=>{:success=>false, :msg=>'Report not found.'} and return if (report.nil?)
		
		#Check competition
		competition = Competition.find_by_id(report.competition_id)
		render :json=>{:success=>false, :msg=>'Competition not found.'} and return if (competition.nil?)
		
		#Check user
		render :json=>{:success=>false, :msg=>'No user found'} and return if (@user.nil?)
		render :json=>{:sucsess=>false, :msg=>'User not authorized.'} and return if (competition.creator_id != @user.id)
		
		report.status = STATUS[:INACTIVE]
		report.save
		
		render :json=>{:success=>true, :msg=>'success'}
	end
	
	#Title:			set_primary
	#Description:	Sets a competition as the primary
	#Params:		competition_id - Competition to designate as primary
	def set_primary
		render :json=>{:success=>false, :msg=>'No competition specified'} and return if (!params.has_key?(:id))
		render :json=>{:success=>false, :msg=>'User not logged in'} and return if (@user.nil?)
		
		success = CompetitionParticipant.set_primary_competition(params[:id], @user.id, @scope)
		if (success)
			render :json=>{:success=>true, :msg=>'success'} and return
		else
			render :json=>{:success=>false, :msg=>'There was an error. Please refresh and try again.'}
		end
	end
	
	def send_invitation_emails
		render :json=>{:success=>false, :msg=>'Could not read competition data. Please refresh your browser and try again'} and return if (!params.has_key?(:competition_id))
		render :json=>{:success=>false, :msg=>'Could not read invitation data. Please refresh your browser and try again'} and return if (!params.has_key?(:emails))
		render :json=>{:success=>false, :msg=>'User not logged in.'} and return if (@user.nil?)
		
		competition = Competition.find_by_id(params[:competition_id])
		render :json=>{:success=>false, :msg=>'Competition not found.'} and return if (competition.nil?)
	
		render :json=>{:success=>false, :msg=>'You do not have permission to do this.'} and return if (@user.id != competition.creator_id)
		
		send_competition_invitations(params[:emails], competition, @scope) if (params.has_key?(:emails))
		
		render :json=>{:success=>true, :msg=>'success'}
	end
	
	#Title:			send_competition_invitations
	#Description:	Send invitations for a competition
	#Params:		emails - comma separated email recipients
	#				competition - Competition activerecord
	private
	def send_competition_invitations(emails, competition)
		AppMailer.competition_invitation(emails, competition, @scope).deliver
	end
	
	private
	def get_competition_data(competition_id)
		competition = Competition.find_by_id(competition_id)
		redirect_to :root and return if (competition.nil?)
		
		participant = false
		if (!@user.nil?)
			participant = !CompetitionParticipant.where({:competition_id=>competition.id, :user_id=>@user.id, :status=>STATUS[:ACTIVE]}).empty?
		end
		
		data = {}
		data[:competition] = competition
		data[:creator] = User.find_by_id(competition.creator_id)
		data[:creator].display_name = (data[:creator].firstname+' '+data[:creator].lastname).strip if (data[:creator].display_name.nil? || data[:creator].display_name.empty?)
		data[:is_creator] = (@user.nil?)?false:(data[:creator].id == @user.id)
		data[:is_participant] = participant
		
		return data
	end
	
	#Title:			get_remaining_time
	#Description:	Gets verbose remaining time from current time
	#Params:		start_time - Check remaining time for this
	private
	def get_remaining_time(start_time)
		#Timezone
		if (@user.nil?)
			timezone = "+00:00"
		else
			begin
				timezone = @user.time_zone
			rescue
				@user = User.find_by_id(@user.id)
				timezone = @user.time_zone
			end
		end
		
		#Time left to tip
		remaining = start_time - Time.now()
		
		if (remaining <= 0)
			return 'Tipping has ended for this stage.'
		#Less than a minute
		elsif (remaining < 60)
			return Time.at(remaining).gmtime.strftime('%S seconds left.')
		#Less than an hour
		elsif (remaining < 3600)
			return Time.at(remaining).gmtime.strftime('%M minutes, %S seconds left.')
		#Less than a day
		elsif (remaining < 86400)
			return Time.at(remaining).gmtime.strftime('%R hours, %S seconds left.')
		else
			begin
				return 'Ends on '+Time.at(start_time).gmtime.localtime(timezone).to_s
			rescue
				return 'Ends on '+Time.at(start_time).gmtime.to_s
			end
		end
	end
	
	#Title:			get_user_tips
	#Description:	Gets tips for a user
	#Params:		uid
	private
	def get_user_tips(competition_id, uid)
		stages = CompetitionStage.where({:competition_id=>competition_id, :status=>STATUS[:ACTIVE]})
		tips = CompetitionTip.where({:competition_participant_id=>uid, :competition_id=>competition_id}).joins(:stage).order('starts_on')

		#Group tip data into race buckets
		selection_by_races = {}
		race_order = []
		cumulative_time = 0
		tips.each do |tip|
			selection = {}
			stage = Stage.find_by_id(tip[:stage_id])
			next if (Time.now < stage.starts_on)
		
			rider = Rider.find_by_id(tip[:rider_id])
			default_rider = Rider.find_by_id(tip[:default_rider_id])
			
			rider_used = (default_rider || rider)
			result = Result.where({:season_stage_id=>stage.id, :rider_id=>(rider_used).id}).first if (!rider_used.nil?)
			
			#Also load the disqualification status of original rider if using a default
			disqualification_reason = ''
			if (!default_rider.nil? && !rider.nil?)
				original_result = Result.where({:season_stage_id=>stage.id, :rider_id=>rider.id}).first
				disqualification_reason = Result.rider_status_to_str(original_result.rider_status)
			end
			default_result = nil
			if (!default_rider.nil?)
				default_result = Result.where({:season_stage_id=>stage.id, :rider_id=>(default_rider).id}).first
			end
			
			if (result.nil?)
				formatted_time = 'TBA'
				formatted_bonus_time = ''
			else
				formatted_time = format_time(result.time)
				if (result.bonus_time.nil? || result.bonus_time == 0)
					formatted_bonus_time = ''
				else
					formatted_bonus_time = format_time(result.bonus_time)
				end
				cumulative_time += (result.time-result.bonus_time)
			end

			selection[:stage] = stage
			selection[:rider] = rider
			selection[:time_formatted] = formatted_time
			selection[:cumulative_formatted_time] = format_time(cumulative_time)
			selection[:bonus_time_formatted] = formatted_bonus_time
			selection[:default_rider] = default_rider
			selection[:disqualified] = disqualification_reason if (!disqualification_reason.empty?)
			selection_by_races[stage.race_id] ||= []
			selection_by_races[stage.race_id].push(selection)
			
			
			race_order.push(stage.race_id) if (race_order.index(stage.race_id).nil?)
		end
		
		#Order race buckets
		tips = []
		race_order.each do |race_id|
			race = Race.find_by_id(race_id)
			tips.push({:race=>race, :tips=>selection_by_races[race_id]})
		end
		
		return tips
	end
	
	#Title:			format_time
	#Description:	Format time by days/HMS
	def format_time(time_in_sec)
		if (time_in_sec >= 86400)
			days = (Time.at(time_in_sec).gmtime.strftime('%-d').to_i - 1).to_s
			return Time.at(time_in_sec).gmtime.strftime(days+' day(s), %R:%S')
		else
			return Time.at(time_in_sec).gmtime.strftime('%R:%S')
		end
	end
	
	#Title:			break_time
	#Description:	Breaks a time in seconds to a hash of days, hours, minutes and seconds
	def break_time(time)
		result = {}
		tt = time
		
		#Days
		result[:days] = (tt/(24*60*60)).to_i
		tt -= (result[:days]*24*60*60)
		
		#Hours
		result[:hours] = (tt/(60*60)).to_i
		tt -= (result[:hours]*60*60)
		
		#Minutes
		result[:minutes] = (tt/60).to_i
		tt -= (result[:minutes]*60)
		
		#Seconds
		result[:seconds] = tt
		
		return result
	end	
end
