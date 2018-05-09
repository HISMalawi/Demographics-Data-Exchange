Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
	
  namespace :api do
		namespace :v1 do
			resources :users
		end
	end


  post 'auth/register', to: 'api/v1/users#register'
  post 'auth/login', to: 'api/v1/users#login'

end
