# config/initializers/assets.rb

# アセットのバージョン設定（キャッシュ更新用）
Rails.application.config.assets.version = '1.0'

# Stimulusなどのアセットパスを追加（必要な場合のみ）
if defined?(Stimulus::Rails::Engine)
  Rails.application.config.assets.paths << Stimulus::Rails::Engine.root.join('app', 'assets', 'javascripts')
end

# Tailwind CSS のビルドパスを追加
Rails.application.config.assets.paths << Rails.root.join('app', 'assets', 'builds')