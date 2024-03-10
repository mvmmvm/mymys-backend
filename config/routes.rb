Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Defines the root path route ("/")
  # root "articles#index"
  # resources :stories
  get "hoge/:id", to: "stories#hoge"

  # resources :stories
  resources :stories, shallow: true do
    resources :rooms do
      resources :characters
      resources :players
    end
  end
end
