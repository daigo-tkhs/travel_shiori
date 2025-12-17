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
    # sourceパラメータは spot_params に含めず、ここで直接取得
    is_from_chat = params[:spot][:source] == 'chat'

    @spot = @trip.spots.build(spot_params)
    authorize @spot

    # リダイレクト先を設定
    redirect_destination = is_from_chat ? trip_messages_path(@trip) : @trip 
                              
    if @spot.save
      calculate_and_update_travel_time(@spot)
      
      flash[:notice] = "「#{@spot.name}」を旅程のDay #{@spot.day_number}に追加しました。"
      
      if is_from_chat
        # チャットからの場合は Turbo Stream でレスポンス
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
      
      redirect_to @trip, notice: t('messages.spot.update_success')
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
  
  # PATCH /trips/:trip_id/spots/:id/move
  def move
    authorize @spot
    
    new_day_number = params[:day_number].to_i
    new_position = params[:position].to_i

    old_day_number = @spot.day_number

    # Dayをまたぐ移動の場合、先に day_number を保存する
    if @spot.day_number != new_day_number
      @spot.update!(day_number: new_day_number) 
    end

    # position を変更
    @spot.insert_at(new_position)

    # 移動時間再計算ロジック
    recalculate_all_travel_times_for_day(new_day_number)
    
    if old_day_number != new_day_number
      recalculate_all_travel_times_for_day(old_day_number)
    end

    head :ok
  end


  private
    def set_trip
      @trip = Trip.find(params[:trip_id])
    rescue ActiveRecord::RecordNotFound
      redirect_to root_path, alert: t('messages.trip.not_found_simple')
    end

    def set_spot
      @spot = @trip.spots.find(params[:id])
    end

    def spot_params
      # :source を削除済み
      params.require(:spot).permit(
        :name, 
        :description, 
        :address, 
        :category, 
        :estimated_cost, 
        :duration, 
        :travel_time, 
        :day_number, 
        :position, 
        :latitude,  
        :longitude,
        :reservation_required
      ).tap do |whitelisted|
        if whitelisted[:estimated_cost].present?
          # 文字列から数字以外の文字（カンマ、記号など）をすべて取り除き、整数に変換
          whitelisted[:estimated_cost] = whitelisted[:estimated_cost].gsub(/[^0-9]/, '').to_i
        end
      end
    end
    
    # スポット追加時用の移動時間計算
    def calculate_and_update_travel_time(new_spot)
      previous_spot = @trip.spots.order(:position).where(day_number: new_spot.day_number).where('position < ?', new_spot.position).last
      
      if previous_spot.present? && 
         new_spot.latitude.present? && new_spot.longitude.present? && 
         previous_spot.latitude.present? && previous_spot.longitude.present?
        
        begin
          # 環境変数からキーを取得
          api_key = ENV['GOOGLE_MAPS_API_KEY'] || ENV['Maps_API_KEY']
          
          return unless api_key.present?
          
          origin      = "#{previous_spot.latitude},#{previous_spot.longitude}"
          destination = "#{new_spot.latitude},#{new_spot.longitude}"
          
          base_url = "https://maps.googleapis.com/maps/api/directions/json"
          
          params = {
            origin: origin,
            destination: destination,
            key: api_key,
            mode: 'driving'
          }

          uri = URI(base_url)
          uri.query = URI.encode_www_form(params)

          response = Net::HTTP.get_response(uri)
          data = JSON.parse(response.body)

          travel_time_in_minutes = nil
          
          if data['status'] == 'OK' && data['routes'].present?
            duration_in_seconds = data['routes'][0]['legs'][0]['duration']['value'].to_i
            travel_time_in_minutes = (duration_in_seconds / 60.0).round.to_i 
          elsif data['error_message'].present?
            Rails.logger.error "Google Maps API Error (Status: #{data['status']}): #{data['error_message']}"
          end

          if travel_time_in_minutes.present?
            # ★変更点: バリデーションをスキップして更新
            previous_spot.update_columns(travel_time: travel_time_in_minutes, updated_at: Time.current)
          end
          
        rescue => e
          Rails.logger.error "Google Maps API/Network Error: #{e.message}"
        end
      end
    end
    
    # 指定された日の全ての移動時間を再計算するメソッド
    def recalculate_all_travel_times_for_day(day_number)
      spots_on_day = @trip.spots.where(day_number: day_number).order(:position)
      
      return unless spots_on_day.present?

      # ★変更点: バリデーションをスキップして更新
      spots_on_day.first.update_columns(travel_time: nil, updated_at: Time.current)
      
      spots_on_day.each_with_index do |current_spot, index|
        next if index == 0

        previous_spot = spots_on_day[index - 1]
        
        if previous_spot.latitude.present? && previous_spot.longitude.present? && 
           current_spot.latitude.present? && current_spot.longitude.present?
          
          begin
            api_key = ENV['GOOGLE_MAPS_API_KEY'] || ENV['Maps_API_KEY']
            return unless api_key.present?
            
            origin      = "#{previous_spot.latitude},#{previous_spot.longitude}"
            destination = "#{current_spot.latitude},#{current_spot.longitude}"
            
            base_url = "https://maps.googleapis.com/maps/api/directions/json"
            
            params = {
              origin: origin,
              destination: destination,
              key: api_key,
              mode: 'driving'
            }

            uri = URI(base_url)
            uri.query = URI.encode_www_form(params)

            response = Net::HTTP.get_response(uri)
            data = JSON.parse(response.body)

            if data['status'] == 'OK' && data['routes'].present?
              duration_in_seconds = data['routes'][0]['legs'][0]['duration']['value'].to_i
              travel_time_in_minutes = (duration_in_seconds / 60.0).round.to_i 
              
              # ★変更点: バリデーションをスキップして更新
              previous_spot.update_columns(travel_time: travel_time_in_minutes, updated_at: Time.current)
            end
            
          rescue => e
            Rails.logger.error "Google Maps API/Network Error during re-sort: #{e.message}"
            # ★変更点: バリデーションをスキップして更新
            previous_spot.update_columns(travel_time: nil, updated_at: Time.current)
          end
        else
          # ★変更点: バリデーションをスキップして更新
          previous_spot.update_columns(travel_time: nil, updated_at: Time.current)
        end
      end
      
      last_spot_on_day = spots_on_day.last
      if last_spot_on_day.travel_time.present?
        # ★変更点: バリデーションをスキップして更新
        last_spot_on_day.update_columns(travel_time: nil, updated_at: Time.current)
      end
    end
end