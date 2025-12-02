module MessagesHelper
  # AIのレスポンスがJSON（スポット提案）かどうかを判定し、パースして返す
  # JSONでない場合やエラーの場合は nil を返す
  def parse_spot_suggestion(response_text)
    return nil if response_text.blank?

    # JSONっぽい文字列が含まれているかチェック（簡易判定）
    return nil unless response_text.include?('is_suggestion')

    # JSONをパース
    # ※ AIがMarkdownのコードブロック ```json ... ``` で囲んでくる場合があるので削除する
    json_text = response_text.gsub(/^```json\n/, '').gsub(/\n```$/, '')
    
    data = JSON.parse(json_text)
    
    # 提案フラグが true の場合のみデータを返す
    if data.is_a?(Hash) && data['is_suggestion']
      return data
    else
      return nil
    end
  rescue JSON::ParserError
    nil
  end
end