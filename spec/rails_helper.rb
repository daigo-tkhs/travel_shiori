# This file is copied to spec/ when you run 'rails generate rspec:install'
require 'spec_helper'
ENV['RAILS_ENV'] ||= 'test'
require_relative '../config/environment'

# 本番環境でテストが実行されないようにガード
abort("The Rails environment is running in production mode!") if Rails.env.production?
require 'rspec/rails'

# spec/support 以下のファイルを読み込む設定（必要になったらコメントアウトを外す）
# Rails.root.glob('spec/support/**/*.rb').sort_by(&:to_s).each { |f| require f }

# 待機中のマイグレーションがないかチェック
begin
  ActiveRecord::Migration.maintain_test_schema!
rescue ActiveRecord::PendingMigrationError => e
  abort e.to_s.strip
end

RSpec.configure do |config|
  config.include FactoryBot::Syntax::Methods

  # トランザクションを使ってテスト毎にデータをロールバックする（DBをクリーンに保つ）
  config.use_transactional_fixtures = true

  # ファイルの場所からスペックのタイプ（model, controller等）を自動推論する
  config.infer_spec_type_from_file_location!

  # バックトレースからRails内部の行を除外してログを見やすくする
  config.filter_rails_from_backtrace!
end