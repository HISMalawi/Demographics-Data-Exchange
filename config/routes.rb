Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
	
  namespace :api do
		namespace :v1 do
			resources :user
      resources :people
		end
	end


  post 'auth/register', to: 'api/v1/user#register'
  post 'auth/login', to: 'api/v1/user#login'
  
  #people controller routes
  post 'v1/add_person', to: 'api/v1/people#create'

end
