Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Defines the root path route ("/")
  mount ActionCable.server => '/cable'
  get '/hoge', to: 'results#hoge'
  get '/players/:id/solve', to: 'results#solve'
  post '/players/:id/answer', to: 'results#answer'
  get '/players/:id/result', to: 'results#result'
  resources :stories, shallow: true do
    resources :characters
    resources :rooms do  
      resources :players
    end
  end
end
