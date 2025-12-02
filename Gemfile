
source "https://rubygems.org"

ruby "3.2.0"

gem "rails", "~> 7.1.6"

# -- Core Tech Stack --
gem "sprockets-rails"
gem "mysql2", "~> 0.5"
gem "puma", ">= 5.0"
gem "importmap-rails"
gem "turbo-rails"
gem "stimulus-rails"
gem "jbuilder"

# -- Database/Security --
gem "tzinfo-data", platforms: %i[ windows jruby ]
gem "bootsnap", require: false
gem "bcrypt", "~> 3.1.7" # Active Model has_secure_password または Deviseで使用

# -- Application Features (Custom Gems) --
gem "devise", "~> 4.9"              # 認証機能 (ユーザー登録/ログイン)
gem 'gemini-ai', '~> 4.3'           # AI連携 (旅程生成/タイトル命名) 
gem "geocoder", "~> 1.8"            # 地図/位置情報 (移動時間計算の土台)
gem "rolify", "~> 6.0"              # 権限管理 (TripUserの権限レベル管理を支援)

group :development, :test do
  gem "debug", platforms: %i[ mri windows ]
end

group :development do
  gem "web-console"
end

group :test do
  gem "capybara"
  gem "selenium-webdriver"
end

group :production do
  gem 'pg', '~> 1.0' 
end

gem "tailwindcss-rails", "~> 4.4"

gem 'devise-i18n'

gem "google_maps_service"

gem 'acts_as_list'