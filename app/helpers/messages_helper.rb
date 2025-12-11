# app/helpers/messages_helper.rb (修正版全文)
# frozen_string_literal: true

module MessagesHelper
  # ------------------------------------------------------------------
  # 1. AIへのシステムインストラクション生成
  # ------------------------------------------------------------------
  def build_system_instruction_for_ai
    <<~INSTRUCTION
      あなたは旅行プランニングのアシスタントです。
      ユーザーの要望に合わせて、観光スポット、レストラン、または宿泊施設（ホテル・旅館）を提案してください。

      【重要】
      具体的な場所を提案する場合は、必ず以下の**JSON形式のみ**で返答してください。余計な文章は不要です。
      提案する場所がない場合（挨拶や質問への回答など）は、普通のテキストで返答してください。

      # スポット提案時のJSONフォーマット例:
      {
        "is_suggestion": true,
        "spots": [
          {
            "name": "東京タワー",
            "description": "東京のシンボル。メインデッキからは東京の景色を一望できます。",
            "estimated_cost": 1200,
            "duration": 60
          }
        ],
        "message": "東京タワーはいかがでしょうか？定番ですが外せません！"
      }

      # 注意事項:
      1. estimated_cost は必ず**日本円(JPY)**の数値で入力してください。（ホテルの場合は1泊1名あたりの目安）
      2. description は簡潔に魅力的な説明を入れてください。
    INSTRUCTION
  end

  # ------------------------------------------------------------------
  # 2. AIレスポンスのパース処理 (今回追加するメソッド)
  # ------------------------------------------------------------------
  # AIのレスポンス(JSON文字列)をパースしてハッシュにする
  # JSONでない場合（通常の会話）は nil を返す
  def parse_spot_suggestion(response_text)
    return nil if response_text.blank?

    begin
      # AIがMarkdownのコードブロック(```json ... ```)を含めてくる場合があるため除去
      cleaned_text = response_text.to_s.gsub(/^```json\s*/, '').gsub(/\s*```$/, '')
      
      # JSONとしてパースを試みる
      JSON.parse(cleaned_text)
    rescue JSON::ParserError
      # JSONでない場合（通常の会話テキストなど）は nil を返す
      nil
    end
  end
end