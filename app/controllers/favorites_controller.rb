# frozen_string_literal: true

class FavoritesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_trip, only: %i[create destroy]

  # 一覧表示
  def index
    # NOTE: indexアクションは認証済みユーザーのfavorite_tripsを表示するだけなので、
    # 認可(Authorization)は不要。認証(Authentication)で保護されている。
    
    @trips = current_user.favorite_trips.includes(:trip_users).order('favorites.created_at DESC')
  end

  # お気に入り登録
  def create
    # Favoriteリソースの作成に必要なTripの閲覧権限をチェック
    favorite = @trip.favorites.new(user: current_user)
    authorize favorite
    
    if favorite.save
      redirect_to trip_path(@trip), notice: t('messages.favorite.create_success')
    else
      redirect_to trip_path(@trip), alert: t('messages.favorite.create_failure')
    end
  end

  # お気に入り解除
  def destroy
    # Favoriteリソースの削除権限をチェック
    favorite = @trip.favorites.find_by(user: current_user)
    
    # 削除対象が存在しない場合はエラーとしない (冪等性を維持するため)
    if favorite
      authorize favorite
      favorite.destroy
      notice_message = t('messages.favorite.delete_success')
    else
      notice_message = t('messages.favorite.delete_success') # 既に削除済みとして成功通知
    end

    redirect_to trip_path(@trip), notice: notice_message, status: :see_other
  end

  private

  def set_trip
    # 閲覧権限があるかどうかのチェックは Policy に任せるため、単純にIDで検索
    @trip = Trip.find(params[:trip_id])
  rescue ActiveRecord::RecordNotFound
    redirect_to root_path, alert: t('messages.trip.not_found')
  end
end