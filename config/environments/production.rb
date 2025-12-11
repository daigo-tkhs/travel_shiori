# config/environments/production.rb (修正版全文)
# frozen_string_literal: true

require 'active_support/core_ext/integer/time'

Rails.application.configure do
  # Code is not reloaded between requests.
  config.enable_reloading = false

  # Eager load code on boot.
  config.eager_load = true

  # Full error reports are disabled and caching is turned on.
  config.consider_all_requests_local = false
  config.action_controller.perform_caching = true

  # config.require_master_key = true # 設定は残しますが、ここではコメントアウトのまま維持します

  # Disable serving static files from `public/`...
  # config.public_file_server.enabled = false # こちらもコメントアウトのまま維持します
  config.assets.compile = false
  config.assets.digest = true
  
  # Store uploaded files on the local file system
  config.active_storage.service = :local

  # Log to STDOUT by default
  config.logger = ActiveSupport::Logger.new($stdout)
                                       .tap    { |logger| logger.formatter = ::Logger::Formatter.new }
                                       .then { |logger| ActiveSupport::TaggedLogging.new(logger) }

  # Prepend all log lines with the following tags.
  config.log_tags = [:request_id]
  config.log_level = ENV.fetch('RAILS_LOG_LEVEL', 'info')

  # Do not dump schema after migrations.
  config.active_record.dump_schema_after_migration = false

  # Action Mailer 設定の統一と整理
  config.action_mailer.raise_delivery_errors = true
  config.action_mailer.perform_caching = false
  config.action_mailer.perform_deliveries = true
  config.action_mailer.delivery_method = :smtp

  # ▼▼▼ 修正: 絶対URL生成設定を統一 ▼▼▼
  # Action Mailerが絶対URLを生成するために必要
  config.action_mailer.default_url_options = { host: 'travel-shiori.onrender.com', protocol: 'https' }

  # ▼▼▼ 修正: SMTP設定を統一 (ポート番号を標準の587に戻す) ▼▼▼
  config.action_mailer.smtp_settings = {
    user_name: 'apikey',
    password: ENV['SENDGRID_API_KEY'],
    # domain設定はActionMailerが自動で処理するため、ここでは削除。
    # SendGridの推奨TLSポート587を使用
    address: 'smtp.sendgrid.net',
    port: 2525,
    authentication: :plain,
    enable_starttls_auto: true
  }
end