require_relative 'boot'

require 'rails/all'
require 'csv'
require "active_storage/engine"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module MeoTool
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 5.2
    config.i18n.default_locale = :ja
    config.time_zone = 'Asia/Tokyo'
    config.active_record.default_timezone = :local
    config.eager_load_paths << Rails.root.join('lib')
    config.autoload_paths += Dir["#{config.root}/app/models/**/"]
  end

  Raven.configure do |config|
    if Rails.env.production?
      config.dsn = 'https://0c868d71cddf4626a8f3ea44383fea26:629a817f3d1547d49cb647fd15ea25a8@sentry.io/1777157'
    end
  end
end
