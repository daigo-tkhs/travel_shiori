class SpotsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_trip
  before_action :set_spot, only: [:edit, :update, :destroy, :move]

  def new
    @spot = @trip.spots.build
  end

  def create
    @spot = @trip.spots.build(spot_params)
    
    if @spot.save
      redirect_to trip_path(@trip), notice: 'スポットを追加しました！'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    # set_spot で @spot が取得されているため、ここは空でOK
  end

  def update
    if @spot.update(spot_params)
      redirect_to trip_path(@trip), notice: 'スポットを更新しました。'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @spot.destroy
    redirect_to trip_path(@trip), notice: 'スポットを削除しました。', status: :see_other
  end

  def move
    # acts_as_list のメソッドを使って位置を変更
    @spot.insert_at(params[:position].to_i)
    head :ok # 画面遷移せず、成功ステータスだけ返す
  end

  private

  def set_trip
    # URLの :trip_id パラメータから旅程を取得し、アクセス権限をチェック
    @trip = Trip.shared_with_user(current_user).find(params[:trip_id])
  rescue ActiveRecord::RecordNotFound
    redirect_to root_path, alert: "指定された旅程が見つからないか、アクセス権がありません。"
  end

  def set_spot
    # 現在の旅程 (@trip) に紐づくスポットのみを検索
    @spot = @trip.spots.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to trip_path(@trip), alert: "指定されたスポットが見つかりませんでした。"
  end
  # ↑↑↑ ここまで ↑↑↑

  def spot_params
    params.require(:spot).permit(:name, :day_number, :estimated_cost, :duration, :booking_url, :reservation_required)
  end
end