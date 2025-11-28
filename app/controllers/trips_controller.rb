class TripsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_trip, only: [:show, :edit, :update, :destroy]

  def index
    @trips = Trip.shared_with_user(current_user)
  end

  def new
    @trip = current_user.owned_trips.build
  end

  def create
    @trip = current_user.owned_trips.build(trip_params)

    if @trip.save
      # 成功時: 作成された旅程の詳細画面へリダイレクト
      redirect_to @trip, notice: '新しい旅程が作成されました。AIに詳細を相談しましょう！'
    else
      # 失敗時: 再度新規作成フォームを表示
      flash.now[:alert] = '旅程の作成に失敗しました。必須項目を確認してください。'
      render :new, status: :unprocessable_entity
    end
  end

  def show
    # 共通ヘッダーを非表示にするフラグ
    @hide_header = true
    
    # 費用の集計（スポットの概算費用合計）
    @total_estimated_cost = @trip.spots.sum(:estimated_cost) || 0
    
    # 日数の計算（スポットの最大日数、なければ1日）
    max_day = @trip.spots.maximum(:day_number) || 1
    @end_date = @trip.start_date + (max_day - 1).days
  end

  def edit
  end

  def update
    if @trip.update(trip_params)
      redirect_to @trip, notice: '旅程を更新しました。'
    else
      flash.now[:alert] = '更新に失敗しました。入力内容を確認してください。'
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @trip.destroy
    redirect_to trips_path, notice: '旅程を削除しました。', status: :see_other
  end

  private

  def trip_params
    params.require(:trip).permit(:title, :start_date, :total_budget, :travel_theme)
  end

  def set_trip
    @trip = Trip.shared_with_user(current_user).find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to root_path, alert: "指定された旅程が見つからないか、アクセス権がありません。"
  end
end