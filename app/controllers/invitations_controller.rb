class InvitationsController < ApplicationController

  # GET /invitations/:token
  def accept
    @hide_header = true
    @hide_footer = true
    # URLのトークンから招待データを検索
    @invitation = TripInvitation.find_by(token: params[:token])

    # 1. 招待が無効（存在しない、期限切れ、使用済み）ならトップへ
    if @invitation.nil? || !@invitation.valid_invitation?
      redirect_to root_path, alert: "この招待リンクは無効になっているか、期限切れです。"
      return
    end

    # 2. ログイン済みなら、即座に参加処理を実行
    if user_signed_in?
      process_join_trip(current_user)
    else
      # 3. 未ログインなら、専用の受け入れ画面（Step 5-3で作るビュー）を表示
      # ここで「ログインして参加」か「ゲスト閲覧（プランA）」かを選ばせます
      render :accept
    end
  end

  def accept_guest
    @invitation = TripInvitation.find_by(token: params[:token])

    # 招待が無効ならトップへ
    if @invitation.nil? || !@invitation.valid_invitation?
      redirect_to root_path, alert: "この招待リンクは無効になっているか、期限切れです。"
      return
    end

    # 閲覧権限(viewer)以外なら弾く（編集者は登録必須のため）
    unless @invitation.role == 'viewer'
      redirect_to invitation_path(@invitation.token), alert: "編集権限での参加にはログインが必要です。"
      return
    end

    session[:guest_trip_ids] ||= []
    session[:guest_trip_ids] << @invitation.trip_id
    session[:guest_trip_ids].uniq! # 重複を防ぐ

    # 招待状を使用済みに更新
    @invitation.update!(accepted_at: Time.current)

    redirect_to trip_path(@invitation.trip), notice: "ゲストとして旅程に参加しました！"
  end

  private

  # ユーザーを旅程に参加させる処理
  def process_join_trip(user)
    trip = @invitation.trip
    
    # すでにメンバーなら何もしない
    if trip.trip_users.exists?(user: user)
      redirect_to trip_path(trip), notice: "すでにこの旅程のメンバーに参加しています。"
      return
    end

    # メンバーに追加（TripUser作成）
    # roleの値をそのまま permission_level に渡します
    TripUser.create!(user: user, trip: trip, permission_level: @invitation.role)
    
    # 招待状を使用済みに更新
    @invitation.update!(accepted_at: Time.current)

    redirect_to trip_path(trip), notice: "旅程「#{trip.title}」に参加しました！"
  end
end