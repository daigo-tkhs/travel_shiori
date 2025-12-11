# frozen_string_literal: true

require_relative 'boot'

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module TravelShiori
  class Application < Rails::Application
    config.load_defaults 7.1
    config.autoload_lib(ignore: %w[assets tasks])
    config.i18n.default_locale = :ja

    config.generators do |g|
      g.test_framework :rspec,
        fixtures: false,          # FactoryBotを使うのでfixtureは生成しない
        view_specs: false,        # ビューのテストは生成しない
        helper_specs: false,      # ヘルパーのテストは生成しない
        routing_specs: false      # ルーティングのテストは生成しない
    end
  end
end