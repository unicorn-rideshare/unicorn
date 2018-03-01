Rails.application.routes.draw do

  root to: 'application#index'

  match '/m/:id' => 'shortener/shortened_urls#show', :via => [:get]

  id_regex = /[1-9][0-9]*/

  namespace :api, defaults: { format: 'json' } do
    resources :categories, only: [:index, :show, :create, :update, :destroy], id: id_regex
    resources :checkins, only: [:index, :create, :destroy], id: id_regex
    resources :companies, only: [:index, :show, :create, :update, :destroy], id: id_regex
    resources :contacts, only: [:index, :show, :update], id: id_regex
    resources :customers, only: [:index, :show, :create, :update, :destroy], id: id_regex do
      resources :comments, only: [:index, :create], id: id_regex
    end
    resources :devices, only: [:index, :show, :create, :update, :destroy]
    resources :directions, only: [:index] do
      get :eta, on: :collection
      get :places, on: :collection
    end
    resources :dispatchers, only: [:index, :show, :create, :update, :destroy], id: id_regex
    resources :invitations, only: [:show]
    resources :jobs, only: [:index, :show, :create, :update, :destroy], id: id_regex do
      resources :attachments, only: [:index, :show, :create, :update, :destroy], id: id_regex do
        resources :comments, only: [:index, :create], id: id_regex
      end
      resources :comments, only: [:index, :create], id: id_regex
      resources :expenses, only: [:index, :create, :update, :destroy], id: id_regex do
        resources :attachments, only: [:index, :show, :create, :update, :destroy], id: id_regex
      end
    end
    resources :markets, only: [:index, :show, :create, :update, :destroy], id: id_regex do
      resources :origins, only: [:index, :show, :create, :update, :destroy], id: id_regex do
        resources :dispatcher_origin_assignments, only: [:index, :show, :create, :update, :destroy], id: id_regex do
          resources :routes, only: [:index]
        end
        resources :provider_origin_assignments, only: [:index, :show, :create, :update, :destroy], id: id_regex do
          resources :routes, only: [:index]
        end
      end
    end
    resources :messages, only: [:index, :create, :update, :destroy], id: id_regex do
      get :conversations, on: :collection
    end
    resources :notifications, only: [:index], id: id_regex
    resources :payment_methods, only: [:index, :show, :create, :destroy], id: id_regex do
      post :charge
    end
    resources :products, only: [:index, :show, :create, :update, :destroy], id: id_regex
    resources :providers, only: [:index, :show, :create, :update, :destroy], id: id_regex do
      get :availability, on: :collection
    end
    resources :recaptcha, only: [:create]
    resources :routes, only: [:index, :show, :create, :update, :destroy], id: id_regex do
      resources :route_legs, only: [:index, :update], id: id_regex
    end
    resources :s3, only: [] do
      get :presign, on: :collection
    end
    resources :tasks, only: [:index, :show, :create, :update, :destroy], id: id_regex
    resources :time_zones, only: [:index]
    resources :tokens, only: [:create, :destroy], id: id_regex
    resources :user_order_shares, only: [:index, :show, :create]
    resources :users, only: [:show, :create, :update], id: id_regex do
      resources :attachments, only: [:index, :show, :create, :update, :destroy], id: id_regex
      post :reset_password, on: :collection
    end
    resources :work_orders, only: [:index, :show, :create, :update, :destroy], id: id_regex do
      resources :attachments, only: [:index, :show, :create, :update, :destroy], id: id_regex do
        resources :comments, only: [:index, :create], id: id_regex
      end
      post :call, on: :member, defaults: { format: 'xml' }
      resources :comments, only: [:index, :show, :create], id: id_regex do
        resources :attachments, only: [:index, :show, :create, :update, :destroy], id: id_regex
      end
      resources :expenses, only: [:index, :create, :update, :destroy], id: id_regex do
        resources :attachments, only: [:index, :show, :create, :update, :destroy], id: id_regex
      end
    end
    resources :tasks, only: [:index, :show, :create, :update, :destroy], id: id_regex
  end

  resources :work_orders, only: [:show]
end
