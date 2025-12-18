# frozen_string_literal: true
require 'uri'
require 'net/http'
require 'json' 

class SpotsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_trip
  before_action :set_spot, only: %i[show edit update destroy move]

  def show
    authorize @spot
  end

  def new
    @hide_header = true
    @spot = @trip.spots.build
    authorize @spot
  end

  def edit
    authorize @spot
  end

  def create
    is_from_chat = params[:spot][:source] == 'chat'
    @spot = @trip.spots.build(spot_params)
    authorize @spot

    redirect_destination = is_from_chat ? trip_messages_path(@trip) : @trip 
                             
    if @spot.save
      calculate_and_update_travel_time(@spot)
      flash[:notice] = "「#{@spot.name}」を旅程のDay #{@spot.day_number}に追加しました。"
      
      if is_from_chat
        respond_to do |format|
          format.turbo_stream
          format.html { redirect_to redirect_destination }
        end
      else
        redirect_to @trip
      end
    else
      flash[:alert] = "スポットの追加に失敗しました: #{@spot.errors.full_messages.join(', ')}"
      redirect_to redirect_destination
    end
  end

  def update
    authorize @spot
    if @spot.update(spot_params)
      recalculate_all_travel_times_for_day(@spot.day_number) 
      
      respond_to do |format|
        format.html { redirect_to @trip, notice: t('messages.spot.update_success') }
        format.turbo_stream do
          @spots_by_day = @trip.spots.order(day_number: :asc, position: :asc).group_by(&:day_number)
          flash.now[:notice] = t('messages.spot.update_success')
          render turbo_stream: [
            turbo_stream.replace(
              "trip_schedule_frame", 
              partial: "trips/schedule", 
              locals: { trip: @trip, spots_by_day: @spots_by_day }
            )
          ]
        end
      end
    else
      flash.now[:alert] = t('messages.spot.update_failure')
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    authorize @spot
    day_to_recalculate = @spot.day_number
    @spot.destroy!
    recalculate_all_travel_times_for_day(day_to_recalculate)
    redirect_to @trip, notice: t('messages.spot.delete_success'), status: :see_other
  end
  
  def move
    authorize @spot
    # 1. 0が送られてきても最低「1」になるように調整
    new_day = params[:spot][:day_number].to_i
    requested_pos = params[:spot][:position].to_i
    new_pos = requested_pos < 1 ? 1 : requested_pos 
    
    old_day = @spot.day_number

    # 2. トランザクションで囲む（データの整合性を守るため）
    ActiveRecord::Base.transaction do
      if @spot.day_number != new_day
        @spot.update!(day_number: new_day) # !をつけて失敗に気づけるように
      end
      @spot.insert_at(new_pos)
    end

    recalculate_all_travel_times_for_day(new_day)
    recalculate_all_travel_times_for_day(old_day) if old_day != new_day

    respond_to do |format|
      format.turbo_stream {
        @spots_by_day = @trip.spots.order(day_number: :asc, position: :asc).group_by(&:day_number)
        render turbo_stream: turbo_stream.replace(
          "trip_schedule_frame", 
          partial: "trips/schedule", 
          locals: { trip: @trip, spots_by_day: @spots_by_day }
        )
      }
      format.html { redirect_to @trip }
    end
  end

  private # クラスを閉じずに内部に配置しました

  def set_trip
    @trip = Trip.find(params[:trip_id])
  rescue ActiveRecord::RecordNotFound
    redirect_to root_path, alert: t('messages.trip.not_found_simple')
  end

  def set_spot
    @spot = @trip.spots.find(params[:id])
  end

  def spot_params
    params.require(:spot).permit(
      :name, :description, :address, :category, :estimated_cost, 
      :duration, :travel_time, :day_number, :position, 
      :latitude, :longitude, :reservation_required
    ).tap do |whitelisted|
      if whitelisted[:estimated_cost].present?
        whitelisted[:estimated_cost] = whitelisted[:estimated_cost].to_s.gsub(/[^0-9]/, '').to_i
      end
    end
  end
  
  def calculate_and_update_travel_time(new_spot)
    previous_spot = @trip.spots.order(:position).where(day_number: new_spot.day_number).where('position < ?', new_spot.position).last
    if previous_spot.present? && new_spot.latitude.present? && new_spot.longitude.present? && previous_spot.latitude.present? && previous_spot.longitude.present?
      begin
        api_key = ENV['GOOGLE_MAPS_API_KEY'] || ENV['Maps_API_KEY']
        return unless api_key.present?
        origin = "#{previous_spot.latitude},#{previous_spot.longitude}"
        destination = "#{new_spot.latitude},#{new_spot.longitude}"
        base_url = "https://maps.googleapis.com/maps/api/directions/json"
        params = { origin: origin, destination: destination, key: api_key, mode: 'driving' }
        uri = URI(base_url); uri.query = URI.encode_www_form(params)
        response = Net::HTTP.get_response(uri); data = JSON.parse(response.body)
        if data['status'] == 'OK' && data['routes'].present?
          duration_in_seconds = data['routes'][0]['legs'][0]['duration']['value'].to_i
          travel_time_in_minutes = (duration_in_seconds / 60.0).round.to_i 
          previous_spot.update_columns(travel_time: travel_time_in_minutes, updated_at: Time.current)
        end
      rescue => e; Rails.logger.error "Google Maps API Error: #{e.message}"; end
    end
  end
  
  def recalculate_all_travel_times_for_day(day_number)
    spots_on_day = @trip.spots.where(day_number: day_number).order(:position)
    return unless spots_on_day.present?
    spots_on_day.first.update_columns(travel_time: nil, updated_at: Time.current)
    spots_on_day.each_with_index do |current_spot, index|
      next if index == 0
      previous_spot = spots_on_day[index - 1]
      if previous_spot.latitude.present? && previous_spot.longitude.present? && current_spot.latitude.present? && current_spot.longitude.present?
        begin
          api_key = ENV['GOOGLE_MAPS_API_KEY'] || ENV['Maps_API_KEY']
          next unless api_key.present?
          origin = "#{previous_spot.latitude},#{previous_spot.longitude}"
          destination = "#{current_spot.latitude},#{current_spot.longitude}"
          uri = URI("https://maps.googleapis.com/maps/api/directions/json")
          uri.query = URI.encode_www_form({ origin: origin, destination: destination, key: api_key, mode: 'driving' })
          data = JSON.parse(Net::HTTP.get(uri))
          if data['status'] == 'OK'
            minutes = (data['routes'][0]['legs'][0]['duration']['value'] / 60.0).round.to_i
            previous_spot.update_columns(travel_time: minutes, updated_at: Time.current)
          end
        rescue => e; Rails.logger.error "Error: #{e.message}"; end
      else
        previous_spot.update_columns(travel_time: nil, updated_at: Time.current)
      end
    end
    spots_on_day.last.update_columns(travel_time: nil, updated_at: Time.current) if spots_on_day.size > 0
  end
end