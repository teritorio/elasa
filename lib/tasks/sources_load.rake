# frozen_string_literal: true
# typed: true

require 'rake'
require_relative 'sources_load'

namespace :sources do
  desc 'Load Sources and POIs from datasource'
  task :load, [] => :environment do
    url_base, project_slug, datasource_project = ARGV[2..]
    load_from_source("#{url_base}/data", project_slug, datasource_project)
    exit 0 # Beacause of manually deal with rake command line arguments
  end
end
