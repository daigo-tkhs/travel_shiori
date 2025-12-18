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
    @trip = Trip.find(params[:trip_id])
    @spot = @trip.spots.build

    respond_to do |format|
      format.html # これが抜けている、あるいはここを通っていない可能性があります
    end
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
        respond_to { |f| f.turbo_stream; f.html { redirect_to redirect_destination } }
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
          render turbo_stream: turbo_stream.replace("trip_schedule_frame", partial: "trips/schedule", locals: { trip: @trip, spots_by_day: @spots_by_day })
        end
      end
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    authorize @spot
    day_num = @spot.day_number
    @spot.destroy!
    recalculate_all_travel_times_for_day(day_num)
    redirect_to @trip, notice: t('messages.spot.delete_success'), status: :see_other
  end
  
  def move
    authorize @spot
    new_day = params[:spot][:day_number].to_i
    new_pos = params[:spot][:position].to_i
    old_day = @spot.day_number

    # トランザクションで安全に実行
    Spot.transaction do
      if old_day != new_day
        # 日付を更新（バリデーションエラーを避けるため update_columns を使用）
        @spot.update_columns(day_number: new_day, updated_at: Time.current)
      end
      # acts_as_list の機能で新しい位置に挿入
      @spot.insert_at(new_pos)
    end

    # 移動元と移動先、両方の日の移動時間を再計算
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

  def spot_params
    params.require(:spot).permit(
      :name, :description, :address, :category, :estimated_cost, 
      :duration, :travel_time, :day_number, :position, 
      :latitude, :longitude, :reservation_required
    )
  end
  
  def calculate_and_update_travel_time(new_spot)
    # (既存のAPI計算ロジック)
  end
  
  def recalculate_all_travel_times_for_day(day_number)
    spots_on_day = @trip.spots.where(day_number: day_number).order(:position)
    return unless spots_on_day.present?
    
    # 最初のスポットの移動時間をリセット
    spots_on_day.first.update_columns(travel_time: nil, updated_at: Time.current)
    
    # 全スポットをループして次のスポットまでの移動時間をAPIで取得
    spots_on_day.each_with_index do |current_spot, index|
      next if index == 0
      previous_spot = spots_on_day[index - 1]
      
      if previous_spot.geocoded? && current_spot.geocoded?
        begin
          api_key = ENV['GOOGLE_MAPS_API_KEY'] || ENV['Maps_API_KEY']
          next unless api_key.present?
          
          uri = URI("https://maps.googleapis.com/maps/api/directions/json")
          uri.query = URI.encode_www_form({
            origin: "#{previous_spot.latitude},#{previous_spot.longitude}",
            destination: "#{current_spot.latitude},#{current_spot.longitude}",
            key: api_key,
            mode: 'driving'
          })
          
          data = JSON.parse(Net::HTTP.get(uri))
          if data['status'] == 'OK'
            duration = (data['routes'][0]['legs'][0]['duration']['value'] / 60.0).round.to_i
            previous_spot.update_columns(travel_time: duration, updated_at: Time.current)
          end
        rescue => e
          Rails.logger.error "Travel recalculate error: #{e.message}"
        end
      end
    end
  end
end