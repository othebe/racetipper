Racetipper::Application.routes.draw do
	match '/admin' => 'admin#index'
	get 'admin/index'
	get 'admin/dashboard'
	get 'admin/edit_season'
	get 'admin/manage_riders'
	get 'admin/edit_rider'
	get 'admin/manage_season_teams'
	get 'admin/edit_season_team'
	get 'admin/manage_season_races'
	get 'admin/edit_season_race'
	get 'admin/upload_results'
	get 'admin/manage_quotes'
	get 'admin/edit_quote'
	get 'admin/manage_articles'
	get 'admin/edit_article'
	get 'admin/upload_default_riders'
	post 'admin/login'
	post 'admin/save_riders'
	post 'admin/delete_rider'
	post 'admin/upload_riders'
	post 'admin/save_season_teams'
	post 'admin/delete_season_team'
	post 'admin/upload_season_teams'
	post 'admin/save_season_races'
	post 'admin/delete_season_race'
	post 'admin/upload_season_races'
	post 'admin/save_default_riders'
	post 'admin/upload_results'
	post 'admin/save_results'
	post 'admin/save_quote'
	post 'admin/delete_quote'
	post 'admin/save_article'
	post 'admin/delete_article'
	post 'admin/upload_default_riders'
	match 'admin/edit_season/:id' => 'admin#edit_season'
	match 'admin/edit_rider/:id' => 'admin#edit_rider'
	match 'admin/edit_season_team/:id' => 'admin#edit_season_team'
	match 'admin/edit_season_race/:id' => 'admin#edit_season_race'
	match 'admin/edit_quote/:id' => 'admin#edit_quote'
	match 'admin/delete_quote/:id' => 'admin#delete_quote'
	match 'admin/edit_article/:id' => 'admin#edit_article'
	
	root :to => 'dashboard#index'
	get 'dashboard/index'
	get 'dashboard/show_competitions'
	get 'dashboard/show_season_info'
	get 'dashboard/show_profile'
	
	match 'competition/:id' => 'dashboard#show_public', :defaults=>{:mode=>'competition'}
	match 'profile/:id' => 'dashboard#show_public', :defaults=>{:mode=>'profile'}
	match 'profiles/:id' => 'dashboard#show_profile'
	
	get 'users/logout'
	post 'users/create'
	post 'users/login'
	get 'users/login_with_facebook'
	get 'users/link_fb_to_user'
	get 'users/settings'
	
	get 'competitions/edit'
	get 'competitions/show'
	get 'competitions/results'
	get 'competitions/leaderboard'
	get 'competitions/get_competition_stage_info'
	get 'competitions/join_by_code'
	get 'competitions/get_more_competitions'
	get 'competitions/show_tips'
	post 'competitions/save_competition'
	post 'competitions/delete_competition'
	post 'competitions/join'
	post 'competitions/tip'
	post 'competitions/kick'
	post 'competitions/send_invitation_emails'
	match 'competitions/:id' => 'competitions#show'
	match 'competitions/edit/:id' => 'competitions#edit'
	match 'competitions/edit_participants/:id' => 'competitions#edit_participants'
	match 'competitions/show/:id' => 'competitions#show'
	match 'competitions/results/:id' => 'competitions#results'
	match 'competitions/leaderboard/:id' => 'competitions#leaderboard'
	match 'competitions/show_tips/:id' => 'competitions#show_tips'
	match 'invitations/:competition_id/:code' => 'competitions#join_by_code'
	
	get 'races/show'
	match 'races/:id' => 'races#show'
	match 'races/show/:id' => 'races#show'
	
	get 'stages/show'
	match 'stages/:id' => 'stages#show'
	match 'stages/show/:id' => 'stages#show'
	
	get 'articles/read'
	match 'articles/:id' => 'articles#read'
	
	get 'cron/send_tip_default_emails'

  # The priority is based upon order of creation:
  # first created -> highest priority.

  # Sample of regular route:
  #   match 'products/:id' => 'catalog#view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  #   match 'products/:id/purchase' => 'catalog#purchase', :as => :purchase
  # This route can be invoked with purchase_url(:id => product.id)

  # Sample resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Sample resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Sample resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Sample resource route with more complex sub-resources
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', :on => :collection
  #     end
  #   end

  # Sample resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end

  # You can have the root of your site routed with "root"
  # just remember to delete public/index.html.
  # root :to => 'welcome#index'

  # See how all your routes lay out with "rake routes"

  # This is a legacy wild controller route that's not recommended for RESTful applications.
  # Note: This route will make all actions in every controller accessible via GET requests.
  # match ':controller(/:action(/:id))(.:format)'
end
