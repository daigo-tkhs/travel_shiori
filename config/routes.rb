Rails.application.routes.draw do
  devise_for :users

  # お気に入り一覧画面
  resources :favorites, only: [:index]

  # 旅程に関するリソースを定義
  resources :trips do
    # --- 旅程にネストする機能 ---
    
    resources :messages, only: [:index, :create, :edit, :update, :destroy] 
    
    resources :spots, only: [:new, :create, :edit, :update, :destroy] do
      member do
        patch :move
      end
    end

    resources :checklists, only: [:index, :create, :update, :destroy] do
      collection do
        post :import
      end
    end
    
    # メンバー管理機能
    resources :trip_users, only: [:create, :destroy]

    # お気に入り機能
    resource :favorite, only: [:create, :destroy]

    # 旅程固有のアクション（共有設定、招待メール送信）
    member do
      get :sharing
      post :invite
    end
  end 

  get '/invitations/:token', to: 'invitations#accept', as: :invitation

  # 開発環境でのみメール確認画面を有効化
  if Rails.env.development?
    mount LetterOpenerWeb::Engine, at: "/letter_opener"
  end

  # アプリケーションのルートパス
  root "trips#index"

  get "up" => "rails/health#show", as: :rails_health_check
end