# frozen_string_literal: true
# typed: true

require 'rake'

namespace :sources do
  desc 'Load Sources and POIs from datasource'
  task :load, [] => :environment do
    url_base, project_slug, datasource_project = ARGV[2..]
    load_from_source("#{url_base}/data", project_slug, datasource_project)
    i18ns = fetch_json("#{url_base}/data/#{project_slug}/i18n.json")
    load_i18n(project_slug, i18ns)
    exit 0 # Beacause of manually deal with rake command line arguments
  end
end
