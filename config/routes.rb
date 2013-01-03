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
	post 'admin/login'
	post 'admin/save_riders'
	post 'admin/save_season_teams'
	post 'admin/save_season_races'
	match 'admin/edit_season/:id' => 'admin#edit_season'
	match 'admin/edit_rider/:id' => 'admin#edit_rider'
	match 'admin/edit_season_team/:id' => 'admin#edit_season_team'
	match 'admin/edit_season_race/:id' => 'admin#edit_season_race'
	
	root :to => 'dashboard#index'
	get 'dashboard/index'
	get 'dashboard/show_competitions'
	
	get 'users/logout'
	post 'users/create'
	post 'users/login'
	
	get 'competitions/edit'
	post 'competitions/save_competition'
	match 'competitions/edit/:id' => 'competitions#edit'
  

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
