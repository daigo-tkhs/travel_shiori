class ChecklistsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_trip
  before_action :set_checklist_item, only: [:update, :destroy]

  def index
    @hide_header = true
    @checklist_items = @trip.checklist_items.order(created_at: :asc)
    @checklist_item = ChecklistItem.new
  end

  def create
    @checklist_item = @trip.checklist_items.build(checklist_item_params)
    
    if @checklist_item.save
      redirect_to trip_checklists_path(@trip), notice: "「#{@checklist_item.name}」を追加しました。"
    else
      @checklist_items = @trip.checklist_items.order(created_at: :asc)
      render :index, status: :unprocessable_entity
    end
  end

  def update
    # チェックボックスの切り替え処理（Turbo Streamを使わずシンプルにリダイレクト）
    @checklist_item.update(checklist_item_params)
    redirect_to trip_checklists_path(@trip)
  end

  def destroy
    @checklist_item.destroy
    redirect_to trip_checklists_path(@trip), notice: "「#{@checklist_item.name}」を削除しました。", status: :see_other
  end

  # 自動生成（プリセットの追加）
  def import
    presets = ["パスポート", "現金・クレジットカード", "スマートフォン・充電器", "着替え", "洗面用具", "常備薬", "雨具"]
    
    presets.each do |name|
      # 重複を防ぎつつ追加
      @trip.checklist_items.find_or_create_by(name: name)
    end

    redirect_to trip_checklists_path(@trip), notice: "持ち物リストを自動生成しました！"
  end

  private

  def set_trip
    @trip = Trip.shared_with_user(current_user).find(params[:trip_id])
  end

  def set_checklist_item
    @checklist_item = @trip.checklist_items.find(params[:id])
  end

  def checklist_item_params
    params.require(:checklist_item).permit(:name, :is_checked)
  end
end