require "active_support/core_ext/integer/time"

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
  config.public_file_server.enabled = ENV["RAILS_SERVE_STATIC_FILES"].present?
  config.public_file_server.headers = {
    'Cache-Control' => "public, max-age=#{1.year.to_i}"
  }

  # Compress CSS using a preprocessor.
  # config.assets.css_compressor = :sass

  # Do not fallback to assets pipeline if a precompiled asset is missing.
  config.assets.compile = false

  # Enable automatic file revisioning based on file digests.
  config.assets.digest = true

  # Defaults to nil and all registered servers are used.
  # config.action_cable.allowed_request_origins = [ "http://example.com", /http:\/\/example.*/ ]

  # Disable generation of digests for original assets.
  config.assets.precompile_uncompressed = true

  # Specifies the header that your server uses for sending files.
  # config.action_dispatch.x_sendfile_header = 'X-Sendfile' # for Apache
  # config.action_dispatch.x_sendfile_header = 'X-Accel-Redirect' # for NGINX

  # Store uploaded files on the local file system (see config/storage.yml for options).
  config.active_storage.service = :local
  
  # ▼ ベーシック認証のミドルウェアはApplicationControllerに移動したため削除
  # config.middleware.use Rack::Auth::Basic do |...| ... end  <- このブロック全体を削除

  # Mount Action Cable outside main process or thread
  # config.action_cable.mount_path = nil
  # config.action_cable.url = "wss://example.com/cable"
  
  # Force all access to the app over SSL, use Strict-Transport-Security, and use secure cookies.
  # config.force_ssl = true

  # Action Mailer Settings
  config.action_mailer.raise_delivery_errors = true
  config.action_mailer.perform_caching = false
  config.action_mailer.perform_deliveries = true
  config.action_mailer.delivery_method = :smtp
  config.action_mailer.smtp_settings = {
    user_name: 'apikey',
    password: ENV['SENDGRID_API_KEY'],
    # ▼ Renderの公開ドメイン名に修正
    domain: 'travel-shiori.onrender.com', 
    address: 'smtp.sendgrid.net',
    port: 587,
    authentication: :plain,
    enable_starttls_auto: true
  }
  
  # ▼ 🚨 致命的なメールリンクの修正 🚨 (Renderの公開URLを設定)
  config.action_mailer.default_url_options = { host: 'travel-shiori.onrender.com', protocol: 'https' }

  # Assume all access to the app is coming from a trusted proxy.
  # config.action_controller.trusted_proxies = %r{
  #   ^192\.168\.1\.1$
  #   ^e45f10a1\.ngrok\.io$
  # }i

  # Log to STDOUT by default
  config.logger = ActiveSupport::Logger.new(STDOUT)
                                       .tap  { |logger| logger.formatter = ::Logger::Formatter.new }
                                       .then { |logger| ActiveSupport::TaggedLogging.new(logger) }

  # Prepend all log lines with the following tags.
  config.log_tags = [ :request_id ]

  # Info, Warn, Error, Fatal, Unknown
  config.log_level = ENV.fetch("RAILS_LOG_LEVEL", "info")

  # Use default logging formatter so that PID and timestamp are not suppressed.
  # config.log_formatter = ::Logger::Formatter.new

  # Do not dump pending migration after rails db:migrate
  config.active_record.dump_schema_after_migration = false
end