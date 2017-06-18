Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  namespace :api do
    namespace :v1 do
      get '/products' => 'products#index'
      post '/products' => 'products#update'
      get '/products/:asin' => 'products#show'
      # resources :products
    end
  end
end
