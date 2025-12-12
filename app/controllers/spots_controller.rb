# frozen_string_literal: true

class SpotsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_trip
  before_action :set_spot, only: %i[show edit update destroy move]

  # NOTE: Punditが編集権限チェックを担当するため、独自の check_trip_edit_permission は削除する

  # GET /trips/:trip_id/spots/1
  def show
    # スポットの閲覧権限は旅程の閲覧権限と同じ
    authorize @spot
  end

  # GET /trips/:trip_id/spots/new
  def new
    @spot = @trip.spots.build
    # 作成権限チェック (Tripの編集権限が必要)
    authorize @spot
  end

  # GET /trips/:trip_id/spots/1/edit
  def edit
    # 編集権限チェック
    authorize @spot
  end

  # POST /trips/:trip_id/spots
  def create
    @spot = @trip.spots.build(spot_params)
    # 作成権限チェック
    authorize @spot

    if @spot.save
      redirect_to @trip, notice: t('messages.spot.create_success')
    else
      flash.now[:alert] = t('messages.spot.create_failure')
      render :new, status: :unprocessable_content
    end
  end

  # PATCH/PUT /trips/:trip_id/spots/1
  def update
    # 更新権限チェック
    authorize @spot
    
    if @spot.update(spot_params)
      redirect_to @trip, notice: t('messages.spot.update_success')
    else
      flash.now[:alert] = t('messages.spot.update_failure')
      render :edit, status: :unprocessable_content
    end
  end

  # DELETE /trips/:trip_id/spots/1
  def destroy
    # 削除権限チェック
    authorize @spot
    
    @spot.destroy!
    redirect_to @trip, notice: t('messages.spot.delete_success'), status: :see_other
  end
  
  # PATCH /trips/:trip_id/spots/:id/move
  def move
    # 移動権限チェック
    authorize @spot
    
    @spot.insert_at(params[:position].to_i)
    head :ok
  end


  private
    def set_trip
      @trip = Trip.find(params[:trip_id])
      # NOTE: Punditで権限チェックを行うため、ここで @trip の viewable_by? は不要
    rescue ActiveRecord::RecordNotFound
      redirect_to root_path, alert: t('messages.trip.not_found_simple')
    end

    def set_spot
      @spot = @trip.spots.find(params[:id])
    end

    def spot_params
      params.require(:spot).permit(:name, :start_time, :end_time, :description, :address, :category, :estimated_cost, :travel_time, :day_number, :position, :lat, :lng)
    end
    
    # NOTE: 独自の権限チェックメソッド check_trip_edit_permission は削除
end