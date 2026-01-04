# config/environments/development.rb
# frozen_string_literal: true

require 'active_support/core_ext/integer/time'

Rails.application.configure do
  # Code is not reloaded between requests.
  config.cache_classes = false

  # Eager load code on boot.
  config.eager_load = false

  # Full error reports are disabled and caching is turned on.
  config.consider_all_requests_local = true
  config.action_controller.perform_caching = false

  # Code reloading is disabled in production.
  config.enable_reloading = true

  # config.require_master_key = true # コメントアウトのまま維持
  # config.public_file_server.enabled = false # コメントアウトのまま維持
  config.assets.compile = true
  config.assets.digest = false
  config.assets.precompile_uncompressed = true
  config.active_storage.service = :local

  # Action Mailer Settings
  config.action_mailer.raise_delivery_errors = true
  config.action_mailer.perform_caching = false
  config.action_mailer.perform_deliveries = true
  
  config.action_mailer.delivery_method = :letter_opener_web
  # config.action_mailer.smtp_settings は Letter Opener Web を使うため不要 (削除推奨)

  config.action_mailer.default_url_options = { host: 'localhost', port: 3000, protocol: 'http' } 

  # Log to STDOUT by default
  config.logger = ActiveSupport::Logger.new($stdout)
                                       .tap    { |logger| logger.formatter = ::Logger::Formatter.new }
                                       .then { |logger| ActiveSupport::TaggedLogging.new(logger) }

  config.log_tags = [:request_id]
  config.log_level = ENV.fetch('RAILS_LOG_LEVEL', 'debug')

  config.active_record.dump_schema_after_migration = true  
  # I18n settings remain the same
  config.i18n.fallbacks = true
  config.active_support.report_deprecations = false
end