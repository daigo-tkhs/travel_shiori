# frozen_string_literal: true

require 'active_support/core_ext/integer/time'

Rails.application.configure do
  # Code is not reloaded between requests.
  config.cache_classes = true

  # Eager load code on boot. This eager loads most of Rails and
  # your application in preparation for page requests.
  config.eager_load = true

  # Full error reports are disabled and caching is turned on.
  config.consider_all_requests_local = false

  # Code reloading is disabled in production.
  config.enable_reloading = false

  # Ensures that a master key has been made available in ENV["RAILS_MASTER_KEY"]
  # and config/credentials.yml.enc in production.
  config.require_master_key = true

  # Enable servers-side caching.
  config.action_controller.perform_caching = true

  # Disable serving static files from the `/public` folder by default since
  # Apache or NGINX generally work better for this.
  config.public_file_server.enabled = ENV['RAILS_SERVE_STATIC_FILES'].present?
  config.public_file_server.headers = {
    'Cache-Control' => "public, max-age=#{1.year.to_i}"
  }

  # Do not fallback to assets pipeline if a precompiled asset is missing.
  config.assets.compile = false

  # Enable automatic file revisioning based on file digests.
  config.assets.digest = true

  # Disable generation of digests for original assets.
  config.assets.precompile_uncompressed = true

  # Store uploaded files on the local file system (see config/storage.yml for options).
  config.active_storage.service = :local

  # Action Mailer Settings
  config.action_mailer.raise_delivery_errors = true
  config.action_mailer.perform_caching = false
  config.action_mailer.perform_deliveries = true
  config.action_mailer.delivery_method = :smtp
  config.action_mailer.smtp_settings = {
    user_name: 'apikey',
    password: ENV['SENDGRID_API_KEY'],
    # 修正: Renderの公開ドメイン名を削除（ActionMailerのhost設定に統一）
    address: 'smtp.sendgrid.net',
    port: 587,
    authentication: :plain,
    enable_starttls_auto: true
  }

  # ▼▼▼ 修正: メーラー内でのURL生成エラー対策 ▼▼▼
  # Action Mailerが絶対URLを生成するために必要
  config.action_mailer.default_url_options = { host: 'travel-shiori.onrender.com', protocol: 'https' }

  # Log to STDOUT by default
  config.logger = ActiveSupport::Logger.new($stdout)
                                       .tap    { |logger| logger.formatter = ::Logger::Formatter.new }
                                       .then { |logger| ActiveSupport::TaggedLogging.new(logger) }

  # Prepend all log lines with the following tags.
  config.log_tags = [:request_id]

  # Info, Warn, Error, Fatal, Unknown
  config.log_level = ENV.fetch('RAILS_LOG_LEVEL', 'info')

  # Do not dump pending migration after rails db:migrate
  config.active_record.dump_schema_after_migration = false

  # config.active_storage.queue = :default

  # Rails.application.config.after_initialize do
  #   ActiveStorage::Engine.config.active_storage.variant_processor = :vips
  # end
end