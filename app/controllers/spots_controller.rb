class SpotsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_trip
  before_action :set_spot, only: [:edit, :update, :destroy, :move]
  before_action :authorize_editor!
  before_action :hide_global_header, only: [:new, :create, :edit, :update]

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

  # --- 並び替え処理 ---
  def move
    # パラメータの取得
    new_day = params[:day_number].to_i
    new_position = params[:position].to_i
    # トランザクションで囲んで、失敗したらロールバックさせる
    Spot.transaction do
      # 1. 日付の変更がある場合（かつ、1以上の有効な値の場合）
      if new_day > 0 && @spot.day_number != new_day
        # 日付を更新（バリデーションエラーならここで例外発生）
        @spot.update!(day_number: new_day)
        # acts_as_listのスコープが変わるため、一度リストから外れて新リストの末尾に移動する
      end
      # 2. 並び順の変更
      # insert_at は acts_as_list のメソッド
      @spot.insert_at(new_position)
    end
    head :ok
  rescue => e
    # 失敗した場合はログに出力し、エラーを返す
    Rails.logger.error "Move failed: #{e.message}"
    head :unprocessable_entity
  end

  private

  def set_trip
    @trip = Trip.shared_with_user(current_user).find(params[:trip_id])
  rescue ActiveRecord::RecordNotFound
    redirect_to root_path, alert: "指定された旅程が見つからないか、アクセス権がありません。"
  end

  def set_spot
    @spot = @trip.spots.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to trip_path(@trip), alert: "指定されたスポットが見つかりませんでした。"
  end

  def authorize_editor!
    unless @trip.editable_by?(current_user)
      redirect_to trip_path(@trip), alert: "編集権限がありません。"
    end
  end

  def hide_global_header
    @hide_header = true
  end

  def spot_params
    params.require(:spot).permit(:name, :day_number, :estimated_cost, :duration, :booking_url, :reservation_required)
  end
end