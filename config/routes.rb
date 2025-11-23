Rails.application.routes.draw do
  devise_for :users

  # 旅程に関するリソース（作成、一覧、詳細など）を定義
  resources :trips do
    # 旅程にネストする機能（会話履歴、スポット管理）を定義
    resources :messages, only: [:create, :update, :destroy] # コメント投稿・編集・削除機能
    resources :spots, only: [:create, :update, :destroy] # スポットの追加・編集機能
    resources :checklists, only: [:index, :create, :update] # チェックリスト表示・管理機能
    
    # 共有設定画面
    member do
      get 'sharing' # 旅程共有設定画面へのルート (Req H)
    end
  end

  # アプリケーションのルートパスを旅程一覧に設定
  root "trips#index"

  get "up" => "rails/health#show", as: :rails_health_check
end