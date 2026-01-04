# frozen_string_literal: true

module TripsHelper
  def theme_badge_class(theme)
    case theme
    when '温泉巡り'
      'bg-orange-100 text-orange-700 border border-orange-200'
    when '食体験重視'
      'bg-yellow-100 text-yellow-800 border border-yellow-200'
    when '歴史・文化'
      'bg-purple-100 text-purple-700 border border-purple-200'
    when 'アウトドア・アクティビティ'
      'bg-green-100 text-green-700 border border-green-200'
    when 'ショッピング'
      'bg-pink-100 text-pink-700 border border-pink-200'
    when 'リゾート・保養'
      'bg-cyan-100 text-cyan-700 border border-cyan-200'
    else # 'その他'、または未設定の場合
      'bg-gray-100 text-gray-700 border border-gray-200'
    end
  end

  def trip_days_options(trip)
    days = []
    # 期間計算（終了日がなければ1日のみ）
    duration = (trip.end_date ? (trip.end_date - trip.start_date).to_i + 1 : 1)

    (1..duration).each do |day_num|
      date = trip.start_date + (day_num - 1).days
      label = "#{day_num}日目 (#{date.strftime('%m/%d')})"
      days << [label, day_num]
    end
    days
  end
end