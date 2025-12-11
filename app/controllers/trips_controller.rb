# frozen_string_literal: true

class TripsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_trip, only: %i[show edit update destroy sharing clone]
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
    @trip_user = @trip.trip_users.build
    @trip_invitation = @trip.trip_invitations.build
  end

  def clone
    cloned_trip = @trip.clone_with_spots(current_user)
    redirect_to cloned_trip, notice: t('messages.trip.clone_success')
  end

  # --- Private Methods ---

  private

  def prepare_trip_show_data
    @spots = @trip.spots.order(:position)

    @trip_days = (@trip.end_date - @trip.start_date).to_i + 1
    @average_daily_budget = begin
      @trip.total_budget.to_i / @trip_days.to_f
    rescue StandardError
      0.0
    end

    calculate_spot_totals

    # nilが含まれていてもエラーにならないよう .to_i を使用するブロック形式に変更
    @daily_stats = @spots.group_by(&:day_number).transform_values do |day_spots|
      {
        cost: day_spots.sum { |s| s.estimated_cost.to_i },
        time: day_spots.sum { |s| s.travel_time.to_i }
      }
    end

    @has_checklist = @trip.checklist_items.any?
    
    # ルーティングエラーとnilエラーを防止
    token = @trip.invitation_token
    @invitation_link = token ? invitation_url(token) : nil
  end

  def calculate_spot_totals
    @total_travel_time_minutes = @spots.sum(:travel_time).to_i
    @total_estimated_cost = @spots.sum(:estimated_cost).to_i 
  end

  def set_trip
    @trip = Trip.shared_with_user(current_user).find(params[:id])
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
end