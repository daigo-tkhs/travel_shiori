# config/initializers/assets.rb

Rails.application.config.assets.version = '1.0'

# app/javascript フォルダをアセットの読み込み対象に追加
Rails.application.config.assets.paths << Rails.root.join("app/javascript")

# Tailwind CSS のビルドパス
Rails.application.config.assets.paths << Rails.root.join('app', 'assets', 'builds')