# frozen_string_literal: true

class TripUsersController < ApplicationController
  before_action :authenticate_user!
  before_action :set_trip
  before_action :set_trip_user, only: %i[destroy]
  
  # 閲覧権限チェック
  before_action :check_trip_view_permission
  
  # メンバーの追加/削除はオーナーのみ可能
  before_action :check_trip_owner_permission, only: %i[create]

  def create
    # Failure 1 対策: email の取得方法を修正
    user = User.find_by(email: params.dig(:trip_user, :email))

    if user.nil?
      redirect_to sharing_trip_path(@trip), alert: t('messages.member.not_found')
      return
    end

    role = params.dig(:trip_user, :role) || 'viewer' 
    user_name = user.nickname || user.email

    if @trip.trip_users.exists?(user: user)
      # 既存ユーザーの場合は通知を出して終了
      redirect_to sharing_trip_path(@trip), alert: t('messages.member.already_member', user_name: user_name)
    elsif @trip.trip_users.create(user: user, permission_level: role)
      role_name = role == 'viewer' ? '閲覧者' : '編集者'
      redirect_to sharing_trip_path(@trip),
                    notice: t('messages.member.invite_success',
                              user_name: user_name, role_name: role_name)
    else
      redirect_to sharing_trip_path(@trip), alert: t('messages.member.invite_failure')
    end
  end

  def destroy
    user_name = @trip_user.user.nickname || @trip_user.user.email

    if @trip_user.user == current_user
      # メンバー自身が旅程から離脱
      @trip_user.destroy
      redirect_to trips_path, notice: t('messages.member.leave_success', trip_title: @trip.title), status: :see_other
    elsif @trip.owner == current_user
      # オーナーが他のユーザーを削除
      @trip_user.destroy
      redirect_to sharing_trip_path(@trip),
                    notice: t('messages.member.delete_success', user_name: user_name),
                    status: :see_other
    else
      # check_trip_owner_permission があれば基本到達しないが、安全策として
      redirect_to sharing_trip_path(@trip), alert: t('messages.member.delete_permission_denied')
    end
  end

  private

  def set_trip
    @trip = Trip.find(params[:trip_id])
  rescue ActiveRecord::RecordNotFound
    redirect_to root_path, alert: t('messages.trip.not_found_simple')
  end

  def set_trip_user
    @trip_user = @trip.trip_users.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to sharing_trip_path(@trip), alert: t('messages.member.member_not_found')
  end

  def check_trip_view_permission
    return if @trip.viewable_by?(current_user)

    # Failure 1 & 3 対策: 権限不足の場合は root_path にリダイレクト (コントローラーの既存ロジックに合わせる)
    redirect_to root_path, alert: t('messages.member.view_permission_denied')
  end
  
  def check_trip_owner_permission
    unless @trip.owner == current_user
      # オーナー権限がない場合、旅程の詳細ページにリダイレクトさせる
      redirect_to trip_path(@trip), alert: t('messages.member.edit_permission_denied')
    end
  end

  def trip_user_params
    params.require(:trip_user).permit(:email, :role)
  end
end