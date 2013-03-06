class DashboardController < ApplicationController
	def index
		@mode = params[:mode] if (params.has_key?(:mode))
		@mode_id = params[:mode_id] if (params.has_key?(:mode_id))
		
		render :layout=>'dashboard'
	end
	
	def show_competitions
		uid = 0
		options = {}
		if (!@user.nil?)
			uid = @user.id
			options[:limit] = 9
		else
			options[:limit] = 10
		end
		competition_list = Competition.get_competitions(uid, options)
		@competitions = []
		competition_list.each do |competition|
			data = {}
			data[:competition] = competition
			if (@user.nil?)
				data[:is_participant] = false
			else
				is_participant = CompetitionParticipant.where('competition_id=? AND user_id=?', competition.id, @user.id)
				data[:is_participant] = !is_participant.empty?
			end
			@competitions.push(data)
		end

		render :layout=>false
	end
	
	def show_season_info
		current_season = Season.find_by_year(Time.now.year)
		@races = Race.where({:season_id=>current_season.id, :status=>STATUS[:ACTIVE]})
		@articles = Article.where({:status=>STATUS[:ACTIVE]}).order('created_at DESC').limit(5)

		render :layout=>false
	end
	
	def show_profile		
		user_id = @user.id
		user_id = params[:id] if (params.has_key?(:id))
		@userprofile = User.find_by_id(user_id)
		@user_rank = User.get_rank(user_id)
		
		#Get profile picture
		profile_user = User.find_by_id(user_id)
		if (!profile_user.nil? && !profile_user.fb_id.nil?)
			@user_image = 'https://graph.facebook.com/'+profile_user.fb_id.to_s+'/picture?type=large'
		else
			@user_image = '/assets/default_user.jpg'
		end
		
		#Get quote
		quote_count = CyclingQuote.count
		offset = rand(quote_count)
		@quote = CyclingQuote.first(:offset=>offset)
		
		#Get competitions
		@competitions = Competition.where('creator_id=? AND (status=? OR status=?)', user_id, STATUS[:ACTIVE], STATUS[:PRIVATE])
		
		if (params.has_key?(:id))
			render :layout=>'public'
		else
			render :layout=>false
		end
	end
	
	def show_public
		@id = params[:id]
		@mode = params[:mode]
		
		if (@mode=='competition')
			competition = Competition.find_by_id(@id)
			redirect_to :root and return if (competition.nil?)
			@name = competition.name
			@description = competition.description
			@image = competition.image_url
			@url = SITE_URL+'competition/'+@id
		elsif (@mode=='profile')
			user = User.find_by_id(@id)
			redirect_to :root and return if (user.nil?)
			@name = (user.firstname+' '+user.lastname).strip+"'s profile."
			@description = 'My profile on Racetipper.'
			@image = SITE_URL+'assets/default_user.jpg'
			@url = SITE_URL+'profile/'+@id
		end
		
		render :layout=>'public'
	end
end
