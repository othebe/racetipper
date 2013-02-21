class CompetitionsController < ApplicationController
	def show
		redirect_to :root if (!params.has_key?(:id))
		@data = get_competition_data(params[:id])
		@data[:races] = Competition.get_all_races(params[:id])
		
		@is_owner = false
		@is_owner = true if (!@user.nil? && @user.id==@data[:creator].id)
		
		render :layout=>false
	end
	
	def results
		redirect_to :root if (!params.has_key?(:id))
		
		@data = get_competition_data(params[:id])
		@is_owner = false
		@is_owner = true if (!@user.nil? && @user.id==@data[:creator].id)
		@results = []
		
		races = []
		CompetitionStage.where({:competition_id=>params[:id], :status=>STATUS[:ACTIVE]}).select(:race_id).group(:race_id).each do |race|
			races.push(race.race_id)
		end
		
		#Starting stage and tip
		@selected_stage = nil
		@selected_tip = nil
		default_stage = nil
		
		@data[:race_data] = {}
		races.each do |race_id|
			race = Race.find_by_id(race_id)
			@data[:race_data][race_id] = {}
			@data[:race_data][race_id][:name] = race.name
			stages = Stage.where({:race_id=>race_id, :status=>STATUS[:ACTIVE]}).order(:order_id)
			@data[:race_data][race_id][:stages] = stages
			next if (!@selected_stage.nil?)
			
			stages.each do |stage|
				next if (!@selected_stage.nil?)
				
				default_stage = stage if (default_stage.nil?)
				if (stage.starts_on > Time.now)
					@selected_stage = stage
					tip = CompetitionTip.where({
						:competition_participant_id => @user.id,
						:stage_id => stage.id,
						:competition_id => params[:id]
					}).first
					@selected_tip = tip.rider_id if (!tip.nil?)
				end
			end
		end
		
		#Grab existing tips
		tip_data = CompetitionTip.where({
			:competition_participant_id => @user.id,
			:competition_id => params[:id]
		})
		@tips = {}
		tip_data.each do |tip|
			rider_id = tip.default_rider_id || tip.rider_id
			stage = Stage.find_by_id(tip.stage_id)
			@tips[rider_id] = {}
			@tips[rider_id][stage.race_id] = {:stage=>stage}
		end
		
		#If tipping is not open for any stage, show results for starting stage
		if (@selected_stage.nil?)
			@selected_stage = default_stage
			@results = Result.get_results('stage', @selected_stage.id)
		end
		
		#Grab team data
		raceteams = RaceTeam.where({
			:status=>STATUS[:ACTIVE],
			:race_id=>races
		}).joins(:team)
		
		allowed_teams = []
		race_team_map = {}
		raceteams.each do |raceteam|
			allowed_teams.push(raceteam.team_id)
			race_team_map[raceteam.team_id] ||= []
			race_team_map[raceteam.team_id].push(raceteam.race_id)
		end
		
		teams = Team.where({
					:id=>allowed_teams,
					:season_id=>@data[:competition].season_id, 
					:status=>STATUS[:ACTIVE]
				}).joins(:TeamRiders).order('team_riders.rider_number')
				
		team_hash = {}
		teams.each do |team|
			team_data = {}
			team_data[:team_id] = team.id
			team_data[:team_name] = team.name
			team_data[:riders] = []
			race_team_map[team.id].each do |race_id|
				rider_data = {}
				rider_data[:race_id] = race_id
				rider_data[:riders] = team.TeamRiders.where(:race_id=>race_id)
				team_data[:riders].push(rider_data)
			end
			team_hash[team.id] = team_data
		end
		@data[:teams] = team_hash
		
		@time_to_tip = get_remaining_time(@selected_stage.starts_on)
		
		render :layout=>false
	end
	
	def leaderboard
		@data = get_competition_data(params[:id])
		
		@races = []
		@is_owner = false
		@is_owner = true if (!@user.nil? && @user.id==@data[:creator].id)
		
		#Drill down by stage
		if (params.has_key?(:stage_id))
			@stage_id = params[:stage_id]
			stage = Stage.find_by_id(@stage_id)
			@result_name = stage.name
			@race_id  = stage.race_id
			@stages = Stage.where({:race_id=>@race_id, :status=>STATUS[:ACTIVE]}).order('starts_on')
			@group_type = 'stage'
			group_id = @stage_id
		
		#Drill down by race
		elsif (params.has_key?(:race_id))
			@race_id = params[:race_id]
			@stages = Stage.where({:race_id=>@race_id, :status=>STATUS[:ACTIVE]}).order('starts_on')
			current_race_id = @race_id
			race = Race.find_by_id(params[:race_id])
			@result_name = race.name
			@group_type = 'race'
			group_id = current_race_id
		
		#Show first race if only race, else show race list
		else
			@races = Competition.get_all_races(params[:id])
			if (@races.length==1)
				@result_name = @races.first.race.name
				current_race_id = @races.first.race_id	
				@race_id = current_race_id
				@stages = Stage.where({:race_id=>current_race_id, :status=>STATUS[:ACTIVE]}).order('order_id')
				@group_type = 'race'
				group_id = current_race_id
			else
				@leaderboard = nil
			end
		end
		
		@leaderboard ||= get_leaderboard(params[:id], @group_type, group_id) if (!@group_type.nil? && !group_id.nil?)
		
		render :layout=>false
	end
	
	def edit
		redirect_to :root and return if (@user.nil?)
		
		@competition = nil
		@competition = Competition.find_by_id(params[:id]) if (params.has_key?(:id))
		
		redirect_to :root and return if (!@competition.nil? && @user.id != @competition.creator_id)
		
		@id = params[:id] if (params.has_key?(:id))
		@races = Race.where(:status=>STATUS[:ACTIVE])
		if (!@competition.nil?)
			@is_private = (@competition.status == STATUS[:PRIVATE])
		else
			@is_private = false
		end
		
		@competition_races = []
		if (!@competition.nil?)
			Competition.get_all_races(@competition.id).each do |race|
				@competition_races.push(race.race_id)
			end
		end
			
		render :layout=>false
	end
	
	def edit_participants
		@competition_id = params[:id]
		@competition = Competition.find_by_id(@competition_id)
		@participants = CompetitionParticipant.where({:competition_id=>@competition_id, :status=>STATUS[:ACTIVE]}).joins(:user).group('competition_participants.id, competition_participants.user_id')
		render :layout=>false
	end
	
	def show_tips
		@competition_id = params[:id]
		@competition = Competition.find_by_id(@competition_id)
		uid = params[:uid]
		
		@tips = get_user_tips(@competition_id, uid)
		render :layout=>false
	end
	
	
	#POST
	
	def join_by_code
		competition_id = params[:competition_id]
		code = params[:code]
		
		competition = Competition.where({:id=>competition_id, :invitation_code=>code}).first
		redirect_to :root and return if (competition.nil?)
		
		#If user not logged in, store invitation in session until they login.
		if (@user.nil?)
			session[:invited_competitions] ||= []
			session[:invited_competitions].push(competition.id) if session[:invited_competitions].index(competition_id).nil?
			redirect_to('/#/competitions/'+competition_id) and return
		else
			CompetitionParticipant.add_participant(@user.id, competition.id)
			redirect_to('/#/competitions/'+competition_id) and return
		end
	end
	
	def save_competition
		render :json=>{:success=>false, :msg=>'An error occurred. Please refresh your browser and try again.'} and return if (!params.has_key?(:data))
		render :json=>{:success=>false, :msg=>'You are not logged in.'} and return if (@user.nil?)
		
		current_year = Time.now.year
		season = Season.find_by_year(current_year)
		render :json=>{:success=>false, :msg=>'This season has not been released yet.'} and return if (season.nil?)
		season_id = season.id
		
		competition_data = params[:data]
		
		render :json=>{:success=>false, :msg=>'Please enter a name for your competition.'} and return if (!competition_data.has_key?(:competition_name) || competition_data[:competition_name].empty?)
		render :json=>{:success=>false, :msg=>'Please enter an image URL for your competition.'} and return if (!competition_data.has_key?(:competition_image_url) || competition_data[:competition_image_url].empty?)
		render :json=>{:success=>false, :msg=>'Please select races for your competition.'} and return if (!competition_data.has_key?(:races) || competition_data[:races].empty?)
		
		#Save competition
		competition = nil
		if (competition_data.has_key?(:id))
			competition = Competition.find_by_id(competition_data[:id])
		end
		competition ||= Competition.new
		
		competition.creator_id = @user.id
		competition.name = competition_data[:competition_name]
		competition.description = competition_data[:competition_description]
		competition.image_url = competition_data[:competition_image_url]
		competition.season_id = season_id
		if (competition_data[:open_to]=='private')
			competition.status = STATUS[:PRIVATE]
		else
			competition.status = STATUS[:ACTIVE]
		end
		
		#Generate competition invitation code
		base =  [('a'..'z'),('A'..'Z')].map{|i| i.to_a}.flatten
		competition.invitation_code  =  (0...10).map{ base[rand(base.length)] }.join

		competition.save
		
		#Add user as participant
		participation = CompetitionParticipant.where({:competition_id=>competition.id, :user_id=>@user.id}).first || CompetitionParticipant.new
		participation.competition_id = competition.id
		participation.user_id = @user.id
		participation.save
		
		#Generate invitations
		if (competition_data[:open_to]=='private')
			CompetitionInvitation.invite_user(@user.id, competition.id)
		end
		
		#Send emails
		send_competition_invitations(competition_data[:invitations], competition)
		
		#Save races/stages
		CompetitionStage.update_all({:status=>STATUS[:DELETED]}, {:competition_id=>competition.id})
		competition_races = []
		competition_data[:races].each do |race_id|
			competition_races.push(race_id)
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
		end

		render :json=>{:success=>true, :msg=>'success'}
	end
	
	def delete_competition
		render :json=>{:success=>false, :msg=>'User not logged in.'} and return if (@user.nil?)
		render :json=>{:success=>false, :msg=>'There was an error. Please refresh your browser and try again.'} and return if (!params.has_key?(:id))
		
		competition = Competition.find_by_id(params[:id])
		render :json=>{:success=>false, :msg=>'Competition not found.'} and return if (competition.nil?)
		render :json=>{:success=>false, :msg=>'You do not have permission to edit this competition.'} and return if (@user.id != competition.creator_id)
		
		competition.status = STATUS[:DELETED]
		competition.save
		
		render :json=>{:success=>true, :msg=>'success'}
	end
	
	#JSON
	
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
			:race_id => stage.race_id
		}
		
		stage_results = []
		if (stage.starts_on < Time.now)
			results = Result.get_results('stage', stage.id)
			data[:stage_results] = results
		end
		
		render :json=>{:data=>data}
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
			data[:image_url] = competition.image_url
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
	
	#POST
	def join
		render :json=>{:success=>false, :msg=>'User not logged in.'} and return if (@user.nil?)
		render :json=>{:success=>false, :msg=>'No competition selected'} and return if (!params.has_key?(:competition_id))
		
		competition = Competition.find_by_id(params[:competition_id])
		if (competition.status = STATUS[:ACTIVE])
			CompetitionParticipant.add_participant(@user.id, params[:competition_id])
		elsif (competition.status = STATUS[:PRIVATE])
			#Check if invited?
		end
		
		#Check if joined successfully
		participant = CompetitionParticipant.where({:competition_id=>competition.id, :user_id=>@user.id, :status=>STATUS[:ACTIVE]}).first
		render :json=>{:success=>false, :msg=>'Could not join competition. You may have been kicked out.'} and return if (participant.nil?)
		
		render :json=>{:success=>true, :msg=>'success'}
	end
	
	def tip
		render :json=>{:success=>false, :msg=>'Rider not selected.'} and return if (!params.has_key?(:rider_id))
		render :json=>{:success=>false, :msg=>'Competition not selected.'} and return if (!params.has_key?(:competition_id))
		render :json=>{:success=>false, :msg=>'Stage not selected.'} and return if (!params.has_key?(:stage_id))
		render :json=>{:success=>false, :msg=>'User not logged in.'} and return if (@user.nil?)
		
		#Determine if tipping is open
		stage = Stage.find_by_id(params[:stage_id])
		render :json=>{:success=>false, :msg=>'Tipping has ended for this stage.'} and return if (stage.starts_on < Time.now)
		
		#Determine if rider exists
		teamrider = TeamRider.where({:rider_id=>params[:rider_id], :race_id=>stage.race_id})
		render :json=>{:success=>false, :msg=>'This rider is not part of the race.'} and return if (teamrider.empty?)
		
		#Determine if user is trying to tip a disqualified rider
		teamrider = TeamRider.where('rider_id=? AND race_id=? AND rider_status<>?', params[:rider_id], stage.race_id, RIDER_RESULT_STATUS[:ACTIVE]).joins(:team)
		render :json=>{:success=>false, :msg=>'This rider has been disqualified.'} and return if (!teamrider.empty?)
		
		tip = CompetitionTip.where({
			:competition_participant_id => @user.id,
			:stage_id => params[:stage_id],
			:competition_id => params[:competition_id],
		}).first
		
		tip ||= CompetitionTip.new
		tip.competition_participant_id = @user.id
		tip.stage_id = params[:stage_id]
		tip.rider_id = params[:rider_id]
		tip.race_id = stage.race_id
		tip.competition_id = params[:competition_id]
		tip.default_rider_id = nil
		
		#Determine if rider has already been selected
		render :json=>{:success=>false, :msg=>'This rider has already been used.'} and return if (tip.is_duplicate())
		
		tip.save
		
		render :json=>{:success=>true, :msg=>'success'}
	end
	
	def kick
		render :json=>{:success=>false, :msg=>'User not logged in.'} and return if (@user.nil?)
		
		competition_id = params[:competition_id]
		user_id = params[:user_id]
		
		#Check if user has authority
		competition = Competition.find_by_id(competition_id)
		render :json=>{:success=>false, :msg=>'You do not have permission to do that.'} and return if (competition.creator_id != @user.id)
		render :json=>{:success=>false, :msg=>'Cannot kick creator.'} and return if (competition.creator_id == user_id)
		
		#Find participant and kick
		participant = CompetitionParticipant.where({:competition_id=>competition_id, :user_id=>user_id}).first
		if (!participant.nil?)
			participant.status = STATUS[:DELETED]
			participant.save
		end
		render :json=>{:success=>true, :msg=>'User has been kicked from the competition.'}
	end
	
	def send_invitation_emails
		render :json=>{:success=>false, :msg=>'Could not read competition data. Please refresh your browser and try again'} and return if (!params.has_key?(:competition_id))
		render :json=>{:success=>false, :msg=>'Could not read invitation data. Please refresh your browser and try again'} and return if (!params.has_key?(:emails))
		render :json=>{:success=>false, :msg=>'User not logged in.'} and return if (@user.nil?)
		
		competition = Competition.find_by_id(params[:competition_id])
		render :json=>{:success=>false, :msg=>'Competition not found.'} and return if (competition.nil?)
	
		render :json=>{:success=>false, :msg=>'You do not have permission to do this.'} and return if (@user.id != competition.creator_id)
		
		send_competition_invitations(params[:emails], competition) if (params.has_key?(:emails))
		
		render :json=>{:success=>true, :msg=>'success'}
	end
	
	#Title:			send_competition_invitations
	#Description:	Send invitations for a competition
	#Params:		emails - comma separated email recipients
	#				competition - Competition activerecord
	private
	def send_competition_invitations(emails, competition)
		AppMailer.competition_invitation(emails, competition).deliver
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
		data[:is_participant] = participant
		
		return data
	end
	
	#Title:			get_leaderboard
	#Description:	Returns a sorted leaderboard for this competition
	#Params:		competition_id - ID of competition
	#				group_type - stage/race
	#				group_id - ID of stage/race
	#				limit - How many entries in the leaderboard to show
	private
	def get_leaderboard(competition_id, group_type, group_id, limit=10)
		tip_conditions = {:competition_id=>competition_id}
		tip_conditions[:stage_id] = group_id if (group_type=='stage')
		
		race_results = Result.get_results(group_type, group_id, {:index_by_rider=>1})
		tips = CompetitionTip.where(tip_conditions)
		user_scores = {}
		tips.each do |tip|
			next if (race_results.nil?)
			
			#Account for default riders
			if (tip.default_rider_id.nil?)
				modifier = 0
				rider_id = tip.rider_id
			else
				rider_id = tip.default_rider_id || tip.rider_id
				modifier = 1/(SCORE_MODIFIER[:DEFAULT]**5.to_f)
			end
			next if (race_results[rider_id].nil?)
			
			stage_id = tip.stage_id
			user_id = tip.competition_participant_id
			
			user = User.find_by_id(user_id)
			username = (user.firstname+' '+user.lastname).strip

			user_score = user_scores[user_id] || Hash.new
			user_score[:tip] ||= Array.new
			user_score[:user_id] = user_id
			user_score[:username] = username
			
			if (!race_results[rider_id][:stages][stage_id].nil?)
				#Cumulate times
				if (user_score[:time].nil?)
					user_score[:time] = race_results[rider_id][:stages][stage_id][:time]+modifier
				else 
					user_score[:time] += race_results[rider_id][:stages][stage_id][:time]+modifier
				end
				
				#Cumulate points
				if (user_score[:points].nil?)
					user_score[:points] = race_results[rider_id][:stages][stage_id][:points]
				else 
					user_score[:points] += race_results[rider_id][:stages][stage_id][:points]
				end
				
				#Cumulate KOM points
				if (user_score[:kom].nil?)
					user_score[:kom] = race_results[rider_id][:stages][stage_id][:kom_points]
				else 
					user_score[:kom] += race_results[rider_id][:stages][stage_id][:kom_points]
				end
				
				#Cumulate sprint points
				if (user_score[:sprint].nil?)
					user_score[:sprint] = race_results[rider_id][:stages][stage_id][:sprint_points]
				else 
					user_score[:sprint] += race_results[rider_id][:stages][stage_id][:sprint_points]
				end
			end
			
			user_score[:tip].push({:id=>rider_id, :name=>race_results[rider_id][:rider_name]})
			user_scores[user_id] = user_score
		end
		
		#Sort leaderboard
		leaderboard = user_scores.sort_by {|user_id, data| data[:time]}
		
		return leaderboard
	end
	
	#Title:			get_remaining_time
	#Description:	Gets verbose remaining time from current time
	#Params:		start_time - Check remaining time for this
	private
	def get_remaining_time(start_time)
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
			return 'Ends on '+start_time.to_s
		end
	end
	
	#Title:			get_user_tips
	#Description:	Gets tips for a user
	#Params:		uid
	private
	def get_user_tips(competition_id, uid)
		stages = CompetitionStage.where({:competition_id=>competition_id, :status=>STATUS[:ACTIVE]})
		tips = CompetitionTip.where({:competition_participant_id=>uid, :competition_id=>competition_id})

		#Group tip data into race buckets
		selection_by_races = {}
		race_order = []
		tips.each do |tip|
			selection = {}
			stage = Stage.find_by_id(tip[:stage_id])
			next if (Time.now < stage.starts_on)
		
			rider = Rider.find_by_id(tip[:rider_id])
			default_rider = Rider.find_by_id(tip[:default_rider_id])

			result = Result.where({:season_stage_id=>stage.id, :rider_id=>(rider||default_rider).id}).first
			default_result = nil
			if (!default_rider.nil?)
				default_result = Result.where({:season_stage_id=>stage.id, :rider_id=>(default_rider).id}).first
			end
			
			selection[:stage] = stage
			selection[:rider] = rider
			selection[:result] = result
			selection[:default_rider] = default_rider
			selection[:default_result] = default_result
			selection[:disqualified] = Result.rider_status_to_str(result.rider_status) if (!result.nil?)
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
end
