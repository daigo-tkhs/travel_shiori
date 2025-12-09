class TripsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_trip, only: [:show, :edit, :update, :destroy, :sharing]

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
    @hide_header = true
    
    # スポットを日付順・順番通りに取得
    @spots = @trip.spots.order(:day_number, :position)
    
    # --- 全体の集計 ---
    # 概算費用の合計
    @total_estimated_cost = @spots.sum(:estimated_cost)
    # 滞在時間の合計 (分)
    @total_duration_mins = @spots.sum(:duration)
    # 移動時間の合計 (分) - nilの場合は0として計算
    @total_travel_mins = @spots.sum { |s| s.travel_time.to_i }
    # 総合計時間 (分)
    @grand_total_mins = @total_duration_mins + @total_travel_mins
    
    # --- 日ごとの集計 (ハッシュを作成) ---
    # 例: { 1 => { cost: 5000, time: 180 }, 2 => ... }
    @daily_stats = @spots.group_by(&:day_number).transform_values do |day_spots|
      # 修正: .to_i を追加して nil を 0 に変換
      cost = day_spots.sum { |s| s.estimated_cost.to_i }
      stay = day_spots.sum { |s| s.duration.to_i }
      travel = day_spots.sum { |s| s.travel_time.to_i }
      {
        cost: cost,
        stay: stay,
        travel: travel,
        total_time: stay + travel
      }
    end
    
    # 終了日の計算（変更なし）
    max_day = @trip.spots.maximum(:day_number) || 1
    @end_date = @trip.start_date ? @trip.start_date + (max_day - 1).days : nil
  end

  def edit
  end

  def update
    if @trip.update(trip_params)
      redirect_to @trip
    else
      flash.now[:alert] = '更新に失敗しました。入力内容を確認してください。'
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    unless @trip.owner?(current_user)
      redirect_to trip_path(@trip), alert: "旅程を削除する権限がありません。"
      return
    end

    @trip.destroy
    redirect_to trips_path, notice: '旅程を削除しました。', status: :see_other
  end

  def sharing
    # メンバー一覧を取得
    @trip_users = @trip.trip_users.includes(:user).order(permission_level: :asc)
  end

  def invite
    @trip = Trip.find(params[:id])
    
    # 招待データを作成
    @invitation = @trip.trip_invitations.new(
      email: params[:email],
      role: params[:role] || 'viewer'
    )

    if @invitation.save
      # DB保存に成功したら、トークン付きURLのための情報を渡してメール送信
      UserMailer.with(
        to: @invitation.email,
        trip: @trip,
        inviter: current_user,
        invitation_token: @invitation.token # ★重要: トークンを渡す
      ).invite_to_trip.deliver_later

      redirect_to sharing_trip_path(@trip), notice: "#{params[:email]} に招待状を送信しました。"
    else
      redirect_to sharing_trip_path(@trip), alert: "招待の送信に失敗しました: #{@invitation.errors.full_messages.join(', ')}"
    end
  end

  private

  def trip_params
    params.require(:trip).permit(:title, :start_date, :end_date, :total_budget, :travel_theme)
  end

  def set_trip
    @trip = Trip.shared_with_user(current_user).find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to root_path, alert: "指定された旅程が見つからないか、アクセス権がありません。"
  end
end