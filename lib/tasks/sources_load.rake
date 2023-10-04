# frozen_string_literal: true
# typed: true

require 'rake'

namespace :sources do
  desc 'Load Sources and POIs from datasource'
  task :load, [] => :environment do
    url_base, project_slug = ARGV[2..]
    load_sources("#{url_base}/data", project_slug)
    exit 0 # Beacause of manually deal with rake command line arguments
  end
end
