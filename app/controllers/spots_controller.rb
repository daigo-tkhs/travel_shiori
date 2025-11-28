class SpotsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_trip
  before_action :set_spot, only: [:edit, :update, :destroy]

  def new
    @spot = @trip.spots.build
  end

  def create
    @spot = @trip.spots.build(spot_params)
    
    if @spot.save
      redirect_to trip_path(@trip)
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @spot.update(spot_params)
      redirect_to trip_path(@trip)
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @spot.destroy
    redirect_to trip_path(@trip), status: :see_other
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

  def spot_params
    params.require(:spot).permit(:name, :day_number, :estimated_cost, :duration, :booking_url)
  end
end