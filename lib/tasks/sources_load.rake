# frozen_string_literal: true
# typed: true

require 'rake'
require 'sentry-ruby'

if ENV['SENTRY_DSN_TOOLS'].present?
  Sentry.init do |config|
    config.dsn = ENV['SENTRY_DSN_TOOLS']
    # enable performance monitoring
    config.enable_tracing = true
    # get breadcrumbs from logs
    config.breadcrumbs_logger = [:http_logger]
  end
end

namespace :sources do
  desc 'Load Sources and POIs from datasource'
  task :load, [] => :environment do
    url_base, project_slug = ARGV[2..]
    load_from_source("#{url_base}/data", project_slug)
    i18ns = fetch_json("#{url_base}/data/#{project_slug}/i18n.json")
    load_i18n(project_slug, i18ns)
    exit 0 # Beacause of manually deal with rake command line arguments
  rescue StandardError => e
    Sentry.capture_exception(e)
    raise
  end
end
