# frozen_string_literal: true

class InvitationsController < ApplicationController
  # 修正: skip_before_action を削除し、joinアクションのみログイン必須にする設定に変更
  before_action :authenticate_user!, only: %i[join]
  
  before_action :set_invitation

  # GET /invitations/:token
  def accept
    @hide_header = true
    @hide_footer = true

    # 未ログインの場合、ログイン後にこの画面に戻ってくるよう保存
    store_location_for(:user, request.fullpath) unless user_signed_in?

    # 招待状が無効な場合は set_invitation でリダイレクト済み
  end

  # POST /invitations/:token/join
  def join
    # 上記 before_action でログインチェック済み

    trip = @invitation.trip

    # すでにメンバーに参加している場合のチェック
    if trip.trip_users.exists?(user: current_user)
      redirect_to trip_path(trip), notice: t('messages.member.welcome_existing', trip_title: trip.title)
      return
    end

    # メンバー追加処理
    TripUser.create!(
      trip: trip,
      user: current_user,
      role: @invitation.role
    )

    # 招待状を使用済みに更新
    @invitation.update!(accepted_at: Time.current, user: current_user)

    redirect_to trip_path(trip), notice: t('messages.member.join_success', trip_title: trip.title)
  end

  # POST /invitations/:token/guest
  def accept_guest
    # 編集権限の場合はゲスト参加不可（ログインを促す）
    if @invitation.role == 'editor'
      redirect_to invitation_path(@invitation.token), alert: t('messages.invitation.login_required')
      return
    end

    # 閲覧権限(viewer)の場合のみセッションにトークンを保存して閲覧許可
    if @invitation.valid_invitation?
      session[:guest_token] = @invitation.token
      redirect_to trip_path(@invitation.trip), notice: t('messages.invitation.guest_join_success')
    else
      redirect_to root_path, alert: t('messages.invitation.link_invalid')
    end
  end

  private

  def set_invitation
    @invitation = TripInvitation.find_by(token: params[:token])

    # 招待状が存在しない、または有効期限切れ/使用済みの場合
    if @invitation.nil? || !@invitation.valid_invitation?
      redirect_to root_path, alert: t('messages.invitation.link_invalid')
    end
  end
end