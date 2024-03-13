Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Defines the root path route ("/")
  mount ActionCable.server => '/cable'
  resources :stories, shallow: true do
    resources :characters
    resources :rooms do  
      resources :players
    end
  end
end
