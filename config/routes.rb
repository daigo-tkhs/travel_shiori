# frozen_string_literal: true

Rails.application.routes.draw do
  devise_for :users
  
  resources :users, only: [:show]

  authenticated :user do
    root 'trips#index', as: :authenticated_root
  end

  root 'static_pages#top'

  resources :favorites, only: [:index]

  resources :trips do
    resources :messages, only: %i[index show create edit update destroy]

    resources :spots, only: %i[new create edit update destroy] do
      member do
        patch :move
        post :duplicate
      end
    end

    resources :checklists, only: %i[index create update destroy] do
      collection do
        post :import
      end
    end

    resources :trip_users, only: %i[create destroy]
    resource :favorite, only: %i[create destroy]

    member do
      get :sharing
      post :invite
    end
  end

  get '/invitations/:token', to: 'invitations#accept', as: :invitation
  post '/invitations/:token/join', to: 'invitations#join', as: :join_invitation
  post '/invitations/:token/guest', to: 'invitations#accept_guest', as: :accept_guest_invitation

  mount LetterOpenerWeb::Engine, at: '/letter_opener' if Rails.env.development?
  get 'up' => 'rails/health#show', as: :rails_health_check
end