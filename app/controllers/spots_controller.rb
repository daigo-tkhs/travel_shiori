# frozen_string_literal: true
require 'uri'
require 'net/http'
require 'json' 

class SpotsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_trip
  before_action :ensure_editable!, only: %i[new create edit update destroy move]
  before_action :set_spot, only: %i[show edit update destroy move]
  before_action :clean_spot_params, only: %i[create update]

  def show
    redirect_to root_path, alert: "アクセス権限がありません。" unless @trip.viewable_by?(current_user)
  end

  def new
    @spot = @trip.spots.build
  end

  def edit
  end

  def create
    is_from_chat = params[:spot][:source] == 'chat'
    @spot = @trip.spots.build(spot_params)
                             
    if @spot.save
      # ★不具合修正：メソッド名を正しい名前に修正
      recalculate_all_travel_times_for_day(@spot.day_number)
      
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.append("messages", html: "<script>if(window.showSuccessAnimation){ window.showSuccessAnimation('#{@spot.name} を追加しました！'); }</script>".html_safe)
          ]
        end
        format.html { redirect_to (is_from_chat ? trip_messages_path(@trip) : @trip) }
      end
    else
      flash.now[:alert] = "入力内容を確認してください。"
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @spot.update(spot_params)
      recalculate_all_travel_times_for_day(@spot.day_number) 
      
      respond_to do |format|
        # 1. 通常のフォーム送信（HTML）への対応
        format.html { redirect_to trip_path(@trip), notice: "#{@spot.name} を更新しました。" }
        
        # 2. Turbo環境（JS）での強制リダイレクト対応
        # これを書くことで、ブラウザのURLが強制的に旅程詳細ページへ移動します
        format.turbo_stream do
          render turbo_stream: turbo_stream.action(:redirect, trip_path(@trip))
        end
      end
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    day_num = @spot.day_number
    spot_name = @spot.name
    @spot.destroy!
    recalculate_all_travel_times_for_day(day_num)

    respond_to do |format|
      format.turbo_stream do
        @spots_by_day = @trip.spots.order(day_number: :asc, position: :asc).group_by(&:day_number)
        render turbo_stream: [
          turbo_stream.replace("trip_schedule_frame", partial: "trips/schedule", locals: { trip: @trip, spots_by_day: @spots_by_day }),
          turbo_stream.append("flash_container", html: "<script>if(window.showSuccessAnimation){ window.showSuccessAnimation('#{spot_name} を削除しました'); }</script>".html_safe)
        ]
      end
      format.html { redirect_to @trip, status: :see_other }
    end
  end
  
  def move
    new_day = params[:spot][:day_number].to_i
    new_pos = params[:spot][:position].to_i
    old_day = @spot.day_number

    Spot.transaction do
      if old_day != new_day
        @spot.update_columns(day_number: new_day, updated_at: Time.current)
      end
      @spot.insert_at(new_pos)
    end

    recalculate_all_travel_times_for_day(new_day)
    recalculate_all_travel_times_for_day(old_day) if old_day != new_day

    respond_to do |format|
      format.turbo_stream do
        @spots_by_day = @trip.spots.order(day_number: :asc, position: :asc).group_by(&:day_number)
        render turbo_stream: turbo_stream.replace("trip_schedule_frame", partial: "trips/schedule", locals: { trip: @trip, spots_by_day: @spots_by_day })
      end
    end
  rescue => e
    Rails.logger.error "Move Failed: #{e.message}"
    head :unprocessable_entity
  end

  private

  def set_trip
    @trip = Trip.find(params[:trip_id])
  end

  def set_spot
    @spot = @trip.spots.find(params[:id])
  end

  def ensure_editable!
    unless @trip.editable_by?(current_user)
      redirect_to trip_path(@trip), alert: "この操作を行う権限がありません。"
    end
  end

  def spot_params
    params.require(:spot).permit(
      :name, :description, :address, :category, :estimated_cost, 
      :duration, :travel_time, :day_number, :position, 
      :latitude, :longitude, :reservation_required, :booking_url
    )
  end

  def clean_spot_params
    return unless params[:spot] && params[:spot][:estimated_cost].present?
    raw_cost = params[:spot][:estimated_cost].to_s.gsub(/[^\d.]/, '')
    params[:spot][:estimated_cost] = raw_cost.to_f.to_i
  end
  
  def recalculate_all_travel_times_for_day(day_number)
    spots_on_day = @trip.spots.where(day_number: day_number).order(:position)
    return unless spots_on_day.present?
    
    spots_on_day.update_all(travel_time: nil)
    
    spots_on_day.each_with_index do |current_spot, index|
      next if index == spots_on_day.size - 1
      next_spot = spots_on_day[index + 1]
      
      if current_spot.geocoded? && next_spot.geocoded?
        begin
          api_key = ENV['GOOGLE_MAPS_API_KEY'] || ENV['Maps_API_KEY']
          next unless api_key.present?
          
          uri = URI("https://maps.googleapis.com/maps/api/directions/json")
          uri.query = URI.encode_www_form({
            origin: "#{current_spot.latitude},#{current_spot.longitude}",
            destination: "#{next_spot.latitude},#{next_spot.longitude}",
            key: api_key,
            mode: 'driving'
          })
          
          data = JSON.parse(Net::HTTP.get(uri))
          if data['status'] == 'OK'
            duration = (data['routes'][0]['legs'][0]['duration']['value'] / 60.0).round.to_i
            current_spot.update_columns(travel_time: duration, updated_at: Time.current)
          end
        rescue => e
          Rails.logger.error "Travel recalculate error: #{e.message}"
        end
      end
    end
  end
end