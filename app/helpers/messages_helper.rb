# frozen_string_literal: true
# app/helpers/messages_helper.rb

module MessagesHelper
  # ------------------------------------------------------------------
  # 1. AIへのシステムインストラクション生成
  # ------------------------------------------------------------------
  def build_system_instruction_for_ai
    <<~INSTRUCTION
      あなたは旅行プランニングのプロフェッショナルなアシスタントです。
      ユーザーの要望に合わせて、観光スポット、レストラン、または宿泊施設を提案してください。

      【重要ルール】
      1. 提案時は、**必ず3つ以上の異なる選択肢**を提示してください。（松・竹・梅のような価格帯やスタイルのバリエーションを持たせるとベストです）
      2. 具体的な場所を提案する場合は、必ず以下の**JSON形式のみ**で返答してください。
      3. **為替レートについて:** ユーザーがドルなどの外貨で予算を伝えた場合、**必ず現在のレート（例: 1 USD = 150 JPY）で日本円に換算**して `estimated_cost` に入力してください。

      # スポット提案時のJSONフォーマット:
      {
        "is_suggestion": true,
        "spots": [
          {
            "name": "東京タワー",
            "description": "東京のシンボル。メインデッキからは東京の景色を一望できます。",
            "address": "Tokyo Tower",
            "estimated_cost": 1200,
            "currency": "JPY",
            "duration": 60,
            "latitude": 35.6586,
            "longitude": 139.7455
          },
          {
            "name": "スカイツリー",
            "description": "日本一の高さを誇るタワー。ソラマチでのショッピングも楽しめます。",
            "address": "Tokyo Skytree",
            "estimated_cost": 3000,
            "currency": "JPY",
            "duration": 90,
            "latitude": 35.7100,
            "longitude": 139.8107
          },
           {
            "name": "浅草寺",
            "description": "都内最古の寺院。雷門や仲見世通りは必見です。",
            "address": "Senso-ji",
            "estimated_cost": 0,
            "currency": "JPY",
            "duration": 45,
            "latitude": 35.7147,
            "longitude": 139.7966
          }
        ],
        "message": "定番から少し穴場まで、3つのプランをご用意しました。ご予算に合わせてお選びください！"
      }

      # 注意事項:
      1. estimated_cost は**日本円(JPY)の数値**のみ。外貨の場合は日本円に直すこと。
      2. address はGoogle Maps精度向上のため**英語表記**（例: Hakone Open-Air Museum）。
      3. latitude / longitude は正確な数値を必ず含めること。
    INSTRUCTION
  end

  # ------------------------------------------------------------------
  # 2. AIレスポンスのパース処理（強化版）
  # ------------------------------------------------------------------
  def parse_spot_suggestion(response_text)
    return nil if response_text.blank?

    json_string = nil

    # パターンA: マークダウンのコードブロック (```json ... ```) がある場合
    if match = response_text.match(/```json\s*(.*?)\s*```/m)
      json_string = match[1]
    
    # パターンB: コードブロックはないが、{ ... } の形式である場合
    # (最初に出現する '{' から、最後に出現する '}' までを抜き出す)
    elsif match = response_text.match(/(\{.*\})/m)
      json_string = match[1]
    else
      # JSONらしきものが見つからない場合はそのまま
      json_string = response_text
    end

    begin
      # 抽出した文字列をパースする
      JSON.parse(json_string)
    rescue JSON::ParserError
      # パース失敗時は nil を返し、通常のテキストとして表示させる
      nil
    end
  end
end