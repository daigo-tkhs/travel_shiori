Rails.application.routes.draw do
  devise_for :users

  # 旅程に関するリソースを定義
  resources :trips do
    # 旅程にネストする機能（spots, messages, checklists）を定義
    
    # メッセージ（AIチャット）機能
    # indexアクションがmessages#indexに必要です
    resources :messages, only: [:index, :create, :update, :destroy] 
    
    # スポット機能: ★edit を追加し、ビューのエラーを解消★
    resources :spots, only: [:new, :create, :edit, :update, :destroy] do
      member do
        patch :move
      end
    end
    
    # チェックリスト機能
    resources :checklists, only: [:index, :create, :update]
    
    # 共有設定画面
    member do
      get 'sharing'
    end
  end

  # アプリケーションのルートパスを旅程一覧に設定
  root "trips#index"

  get "up" => "rails/health#show", as: :rails_health_check
end