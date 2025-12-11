# config/environments/development.rb (修正版全文)
# frozen_string_literal: true

require 'active_support/core_ext/integer/time'

Rails.application.configure do
  # Code is not reloaded between requests.
  config.cache_classes = false # 開発環境ではfalse

  # Eager load code on boot.
  config.eager_load = false # 開発環境ではfalse

  # Full error reports are disabled and caching is turned on.
  config.consider_all_requests_local = true # 開発環境ではtrue
  config.action_controller.perform_caching = false # 開発環境ではfalse

  # Code reloading is disabled in production.
  config.enable_reloading = true # 開発環境ではtrue

  # config.require_master_key = true # コメントアウトのまま維持
  # config.public_file_server.enabled = false # コメントアウトのまま維持
  config.assets.compile = true # 開発中はtrueの方が便利
  config.assets.digest = false # 開発中はfalseの方が便利
  config.assets.precompile_uncompressed = true
  config.active_storage.service = :local

  # Action Mailer Settings
  config.action_mailer.raise_delivery_errors = true
  config.action_mailer.perform_caching = false
  config.action_mailer.perform_deliveries = true
  
  # ▼▼▼ 修正: 開発時はLetter Opener Webへ向ける設定を推奨 ▼▼▼
  config.action_mailer.delivery_method = :letter_opener_web
  # config.action_mailer.smtp_settings は Letter Opener Web を使うため不要 (削除推奨)

  # ▼▼▼ 修正: ローカルホストの設定に合わせる ▼▼▼
  config.action_mailer.default_url_options = { host: 'localhost', port: 3000, protocol: 'http' } 

  # Log to STDOUT by default
  config.logger = ActiveSupport::Logger.new($stdout)
                                       .tap    { |logger| logger.formatter = ::Logger::Formatter.new }
                                       .then { |logger| ActiveSupport::TaggedLogging.new(logger) }

  config.log_tags = [:request_id]
  config.log_level = ENV.fetch('RAILS_LOG_LEVEL', 'debug') # 開発は debug に推奨

  config.active_record.dump_schema_after_migration = true # 開発中はtrueがデフォルト
  
  # I18n settings remain the same
  config.i18n.fallbacks = true
  config.active_support.report_deprecations = false
end