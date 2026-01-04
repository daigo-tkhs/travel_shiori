class UsersController < ApplicationController
  before_action :authenticate_user!

  def show
    # URLのIDからユーザーを探す（マイページ遷移時は current_user.id が渡される想定）
    @user = User.find(params[:id])
    
    # 必要に応じて、このユーザーが作成した旅程などを取得してもOK
    # @my_trips = @user.trips.order(created_at: :desc).limit(5)
  end
end