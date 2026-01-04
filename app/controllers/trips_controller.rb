# frozen_string_literal: true
require 'uri'
require 'net/http'
require 'json'

class TripsController < ApplicationController
  before_action :authenticate_user!, except: %i[index show]
  before_action :check_guest_token_for_show, only: %i[show]
  before_action :set_trip, only: %i[show edit update destroy sharing clone invite]
  skip_before_action :basic_auth, only: [:index]

  def index
    @trips = policy_scope(Trip).order(created_at: :desc)
  end

  def show
    authorize @trip
    @trip.spots.reload
    prepare_trip_show_data
    @hide_header = true
  end

  def new
    @trip = current_user.owned_trips.build
    authorize @trip
  end

  def edit
    unless @trip.editable_by?(current_user)
      redirect_to trip_path(@trip), alert: "編集権限がありません。"
      return
    end
    @hide_header = true
  end

  def create
    @trip = current_user.owned_trips.build(trip_params)
    authorize @trip

    if @trip.save
      redirect_to @trip, notice: t('messages.trip.create_success')
    else
      flash.now[:alert] = t('messages.trip.create_failure')
      render :new, status: :unprocessable_content
    end
  end

  def update
    unless @trip.editable_by?(current_user)
      redirect_to trip_path(@trip), alert: "編集権限がありません。"
      return
    end

    if @trip.update(trip_params)
      redirect_to @trip, notice: t('messages.trip.update_success')
    else
      flash.now[:alert] = t('messages.trip.update_failure')
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    authorize @trip
    @trip.destroy
    redirect_to trips_path, notice: t('messages.trip.delete_success'), status: :see_other
  end

  def sharing
    authorize @trip
    @trip_users = @trip.trip_users.includes(:user).where.not(id: nil)
    @trip_user = @trip.trip_users.build
    @trip_invitation = @trip.trip_invitations.build
  end

  def invite
    authorize @trip
    @trip_invitation = @trip.trip_invitations.build(invitation_params)
    @trip_invitation.sender = current_user

    if @trip_invitation.save
      UserMailer.with(invitation: @trip_invitation, inviter: current_user).invite_email.deliver_now
      redirect_to sharing_trip_path(@trip), notice: t('messages.invitation.sent_success')
    else
      @trip_users = @trip.trip_users.includes(:user).where.not(id: nil)
      @trip_user = @trip.trip_users.build
      flash.now[:alert] = t('messages.invitation.send_failure')
      render :sharing, status: :unprocessable_content
    end
  end

  def clone
    authorize @trip
    cloned_trip = @trip.clone_with_spots(current_user)
    redirect_to cloned_trip, notice: t('messages.trip.clone_success')
  end

  private

  def check_guest_token_for_show
    return if user_signed_in? || session[:guest_token].blank?
    invitation = TripInvitation.find_by(token: session[:guest_token])
    if invitation&.valid_invitation? && invitation.trip_id.to_s == params[:id].to_s
      @guest_invitation = invitation
    else
      session.delete(:guest_token)
    end
  end

  def prepare_trip_show_data
    # ★修正: 日付順・ポジション順でスポットを確定させる
    @spots = @trip.spots.order(:day_number, :position)
    @trip_days = [(@trip.end_date - @trip.start_date).to_i + 1, 1].max
    @average_daily_budget = (@trip.total_budget.to_i / @trip_days.to_f rescue 0.0)
    
    calculate_spot_totals
    
    @daily_stats = @spots.group_by(&:day_number).transform_values do |day_spots|
      {
        cost: day_spots.sum { |s| s.estimated_cost.to_i },
        travel: day_spots.sum { |s| s.travel_time.to_i },
        stay: day_spots.sum { |s| s.duration.to_i }
      }
    end
    @has_checklist = @trip.checklist_items.any?
    token = @trip.invitation_token
    @invitation_link = token ? invitation_url(token) : nil
  end

  def calculate_spot_totals
    @total_travel_mins = @spots.sum { |s| s.travel_time.to_i }
    @total_duration_mins = @spots.sum { |s| s.duration.to_i }
    @total_estimated_cost = @spots.sum { |s| s.estimated_cost.to_i }
    @grand_total_mins = @total_travel_mins + @total_duration_mins
  end

  def set_trip
    if user_signed_in?
      @trip = Trip.shared_with_user(current_user).find(params[:id])
    elsif @guest_invitation
      @trip = @guest_invitation.trip
    else
      @trip = Trip.find(params[:id])
    end
  rescue ActiveRecord::RecordNotFound
    redirect_to root_path, alert: t('messages.trip.not_found')
  end

  def trip_params
    params.require(:trip).permit(:title, :start_date, :end_date, :total_budget, :travel_theme)
  end

  def invitation_params
    params.permit(:email, :role)
  end
end