# frozen_string_literal: true

class TripsController < ApplicationController
  # ▼▼▼ 修正: showアクションの認証ルールを変更 ▼▼▼
  # show以外は通常通りログイン必須
  before_action :authenticate_user!, except: %i[show]
  # showは「ログインユーザー」または「ゲスト」なら許可
  before_action :authenticate_user_or_guest!, only: %i[show]
  # ▲▲▲ 修正終わり ▲▲▲

  before_action :set_trip, only: %i[show edit update destroy sharing clone invite]
  before_action :check_trip_owner, only: %i[edit update destroy]

  skip_before_action :basic_auth, only: [:index]

  # --- Public Actions ---

  def index
    @trips = Trip.shared_with_user(current_user).order(created_at: :desc)
  end

  def show
    @hide_header = true
    prepare_trip_show_data
  end

  def new
    @trip = current_user.owned_trips.build
  end

  def edit; end

  def create
    @trip = current_user.owned_trips.build(trip_params)

    if @trip.save
      redirect_to @trip, notice: t('messages.trip.create_success')
    else
      flash.now[:alert] = t('messages.trip.create_failure')
      render :new, status: :unprocessable_content
    end
  end

  def update
    if @trip.update(trip_params)
      redirect_to @trip, notice: t('messages.trip.update_success')
    else
      flash.now[:alert] = t('messages.trip.update_failure')
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    if @trip.owner == current_user
      @trip.destroy
      redirect_to trips_path, notice: t('messages.trip.delete_success'), status: :see_other
    else
      redirect_to trip_path(@trip), alert: t('messages.trip.delete_permission_denied')
    end
  end

  def sharing
    @trip_users = @trip.trip_users.includes(:user).where.not(id: nil)
    @trip_user = @trip.trip_users.build
    @trip_invitation = @trip.trip_invitations.build
  end

  def invite
    @trip_invitation = @trip.trip_invitations.build(invitation_params)
    @trip_invitation.sender = current_user 

    if @trip_invitation.save
      UserMailer.with(invitation: @trip_invitation, inviter: current_user).invite_email.deliver_now
      
      redirect_to sharing_trip_path(@trip), notice: t('messages.invitation.sent_success', default: '招待状を送信しました。')
    else
      @trip_users = @trip.trip_users.includes(:user).where.not(id: nil)
      @trip_user = @trip.trip_users.build
      flash.now[:alert] = t('messages.invitation.send_failure', default: '招待の送信に失敗しました。入力内容を確認してください。')
      render :sharing, status: :unprocessable_content
    end
  end

  def clone
    cloned_trip = @trip.clone_with_spots(current_user)
    redirect_to cloned_trip, notice: t('messages.trip.clone_success')
  end

  # --- Private Methods ---

  private

  # ▼▼▼ 追加: ゲストアクセス許可ロジック ▼▼▼
  def authenticate_user_or_guest!
    # ログイン済みならOK
    return if user_signed_in?

    # セッションにゲストトークンがあり、それが有効ならOK
    if session[:guest_token]
      invitation = TripInvitation.find_by(token: session[:guest_token])
      # 招待状が存在し、有効期限内であり、アクセスしようとしている旅程と一致するか
      if invitation&.valid_invitation? && invitation.trip_id.to_s == params[:id].to_s
        @guest_invitation = invitation # set_tripで使用するために保存
        return
      end
    end

    # どちらもダメならログイン画面へ強制遷移
    authenticate_user!
  end
  # ▲▲▲ 追加終わり ▲▲▲

  def prepare_trip_show_data
    @spots = @trip.spots.order(:position)

    @trip_days = (@trip.end_date - @trip.start_date).to_i + 1
    @average_daily_budget = begin
      @trip.total_budget.to_i / @trip_days.to_f
    rescue StandardError
      0.0
    end

    calculate_spot_totals

    @daily_stats = @spots.group_by(&:day_number).transform_values do |day_spots|
      {
        cost: day_spots.sum { |s| s.estimated_cost.to_i },
        time: day_spots.sum { |s| s.travel_time.to_i }
      }
    end

    @has_checklist = @trip.checklist_items.any?
    
    token = @trip.invitation_token
    @invitation_link = token ? invitation_url(token) : nil
  end

  def calculate_spot_totals
    @total_travel_time_minutes = @spots.sum(:travel_time).to_i
    @total_estimated_cost = @spots.sum(:estimated_cost).to_i 
  end

  def set_trip
    if user_signed_in?
      # ログインユーザーの場合: 共有された旅程から検索
      @trip = Trip.shared_with_user(current_user).find(params[:id])
    elsif @guest_invitation
      # ゲストの場合: 招待状に紐付く旅程を取得
      @trip = @guest_invitation.trip
    else
      # ここに来ることは基本ないが、念のため
      redirect_to root_path, alert: t('messages.trip.not_found')
    end
  rescue ActiveRecord::RecordNotFound
    redirect_to root_path, alert: t('messages.trip.not_found')
  end

  def check_trip_owner
    return if @trip.owner == current_user

    redirect_to trip_path(@trip), alert: t('messages.trip.delete_permission_denied')
  end

  def trip_params
    params.require(:trip).permit(:title, :start_date, :end_date, :total_budget, :travel_theme)
  end
  
  def invitation_params
    params.permit(:email, :role)
  end
end