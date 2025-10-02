Rails.application.routes.draw do
  root 'root#index'

  resources :collages, only: [:create, :show, :update, :destroy] do
    resources :photos, only: [:index, :create, :show, :update, :destroy]
  end

  # Catch-all route for Backbone-style client routing (collage show pages)
  get '/collages/:guid', to: 'collages#show', constraints: { guid: /[a-zA-Z0-9_-]+/ }
end
