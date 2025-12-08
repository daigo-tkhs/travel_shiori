Rails.application.routes.draw do
  devise_for :users

  # お気に入り一覧画面
  resources :favorites, only: [:index]

  # 旅程に関するリソースを定義
  resources :trips do
    # 旅程にネストする機能（spots, messages, checklists, trip_user）を定義
    
    # メッセージ（AIチャット）機能
    resources :messages, only: [:index, :create, :edit, :update, :destroy] 
    
    # スポット機能: ★edit を追加し、ビューのエラーを解消★
    resources :spots, only: [:new, :create, :edit, :update, :destroy] do
      member do
        patch :move
      end
    end

    # チェックリスト機能
    resources :checklists, only: [:index, :create, :update, :destroy] do
      collection do
        post :import
      end
    end
    
    # 共有設定画面
    member do
      get 'sharing'
    end

    # メンバー管理機能 (作成と削除のみ)
    resources :trip_users, only: [:create, :destroy]

    # お気に入り機能 (単数形 resource なのでURLにidが含まれません)
    resource :favorite, only: [:create, :destroy]

    # 招待メールを送るためのURL (POST /trips/:id/invite)
    member do
      post :invite
    end
  end

  # 開発環境でのみメール確認画面を有効化
  if Rails.env.development?
    mount LetterOpenerWeb::Engine, at: "/letter_opener"
  end

  # アプリケーションのルートパスを旅程一覧に設定
  root "trips#index"

  get "up" => "rails/health#show", as: :rails_health_check
end