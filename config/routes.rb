# frozen_string_literal: true

Rails.application.routes.draw do
  devise_for :users

  # お気に入り一覧画面
  resources :favorites, only: [:index]

  # 旅程に関するリソースを定義
  resources :trips do
    # --- 旅程にネストする機能 ---

    resources :messages, only: %i[index create edit update destroy]

    resources :spots, only: %i[new create edit update destroy] do
      member do
        patch :move
      end
    end

    resources :checklists, only: %i[index create update destroy] do
      collection do
        post :import
      end
    end

    # メンバー管理機能
    resources :trip_users, only: %i[create destroy]

    # お気に入り機能
    resource :favorite, only: %i[create destroy]

    # 旅程固有のアクション（共有設定、招待メール送信）
    member do
      get :sharing
      post :invite
    end
  end

  # ▼▼▼ 修正: 招待関連のルーティングを追加・整理 ▼▼▼
  # 招待受諾画面 (GET)
  get '/invitations/:token', to: 'invitations#accept', as: :invitation

  # 参加確定 (POST) - 新規追加
  post '/invitations/:token/join', to: 'invitations#join', as: :join_invitation

  # ゲスト参加 (POST)
  post '/invitations/:token/guest', to: 'invitations#accept_guest', as: :accept_guest_invitation
  # ▲▲▲ 修正終わり ▲▲▲

  # 開発環境でのみメール確認画面を有効化
  mount LetterOpenerWeb::Engine, at: '/letter_opener' if Rails.env.development?

  # アプリケーションのルートパス
  root 'trips#index'

  get 'up' => 'rails/health#show', as: :rails_health_check
end