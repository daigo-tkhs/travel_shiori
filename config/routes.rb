Rails.application.routes.draw do
  devise_for :users

  # 旅程に関するリソース（作成、一覧、詳細など）を定義
  resources :trips do
    # 旅程にネストする機能
    resources :messages, only: [:index, :create, :update, :destroy]
    
    resources :spots, only: [:new, :create, :edit, :update, :destroy] 
    
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