# frozen_string_literal: true

source 'https://rubygems.org'

ruby '3.2.0'

gem 'rails', '~> 7.1.6'

# -- Database / Server --
gem 'mysql2', '~> 0.5'
gem 'puma', '>= 5.0'

# -- Front-end / Assets --
gem 'importmap-rails'
gem 'sprockets-rails'
gem 'stimulus-rails'
gem 'turbo-rails'
gem 'tailwindcss-rails', '~> 4.4'
gem 'jbuilder'
gem 'image_processing', '~> 1.14.0'

# -- Auth / User --
gem 'devise', '~> 4.9'
gem 'devise-i18n'
gem 'pundit'
gem 'rolify', '~> 6.0'
gem 'bcrypt', '~> 3.1.7' 

# -- Utilities / Logic --
gem 'bootsnap', require: false
gem 'gemini-ai', '~> 4.3' 
gem 'geocoder', '~> 1.8' 
gem 'google_maps_service'
gem 'acts_as_list'
gem 'tzinfo-data', platforms: %i[windows jruby]

# -- Development & Test Group --
group :development, :test do
  gem 'debug', platforms: %i[mri windows]
  gem 'rspec-rails', '~> 6.0'
  gem 'factory_bot_rails'
  gem 'faker' 
  gem 'rubocop', require: false
  gem 'rubocop-performance', require: false
  gem 'rubocop-rails', require: false
  
  # 環境変数管理
  gem 'dotenv-rails'

  # 統合テスト/UIテスト関連
  gem 'capybara', '~> 3.37'
  gem 'selenium-webdriver' 
end

# -- Development Only Group --
group :development do
  gem 'letter_opener_web'
  gem 'web-console'
  
  # 未使用ルート/アクション検出
  gem 'traceroute'
end

# -- Production Only Group --
group :production do
  gem 'pg', '~> 1.0'
end