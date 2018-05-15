Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
	
  namespace :api do
		namespace :v1 do
			resources :user
      resources :people
      resources :location
      resources :npid
		end
	end


  post 'v1/register', to: 'api/v1/user#register'
  post 'v1/login', to: 'api/v1/user#login'
  post 'v1/add_user', to: 'api/v1/user#add_user'
  
  #people controller routes
  post 'v1/add_person', to: 'api/v1/people#create'
  post 'v1/search_by_name_and_gender', to: 'api/v1/people#search_by_name_and_gender'
  post 'v1/search_by_npid/:npid/(*doc_id)', to: 'api/v1/people#search_by_npid'
  post 'v1/search_by_doc_id/:doc_id', to: 'api/v1/people#search_by_doc_id'
  get 'v1/search_by_attributes/', to: 'api/v1/people#search_by_attributes'
  

  #npid controller routes
  post 'v1/assign_npids', to: 'api/v1/npid#assign_npids'

  #location controller routes
  post 'v1/find_location', to: 'api/v1/location#find'




end
