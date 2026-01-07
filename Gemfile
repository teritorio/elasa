# frozen_string_literal: true

source 'https://rubygems.org'

git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby '>= 3.4'

# Bundle edge Rails instead: gem "rails", github: "rails/rails", branch: "main"
gem 'rails', '~> 8.0.0'

# Use the Puma web server [https://github.com/puma/puma]
gem 'puma', '~> 6.0'

# Reduces boot times through caching; required in config/boot.rb
gem 'bootsnap', require: false

# Use Rack CORS for handling Cross-Origin Resource Sharing (CORS), making cross-origin AJAX possible
gem 'rack-cors'

gem 'tzinfo-data'

gem 'builder', '~> 3.3'
gem 'concurrent-ruby', '< 1.3.5' # ActiveSupport bug workarround
gem 'connection_pool', '~> 2.5'
gem 'csv'
gem 'http'
gem 'json'
gem 'json-schema'
gem 'mutex_m'
gem 'optparse'
gem 'ostruct'
gem 'pg', '~> 1.1'
gem 'sentry-rails'
gem 'sentry-ruby'
gem 'sorbet-runtime'
gem 'uri_template', git: 'https://github.com/hannesg/uri_template.git'

group :development do
  gem 'image_size' # WP Imort
  gem 'rake'
  gem 'rubocop', require: false
  gem 'rubocop-rails', require: false
  gem 'rubocop-rake', require: false
  gem 'ruby-lsp', require: false
  gem 'sorbet'
  gem 'sorbet-rails'
  gem 'tapioca', require: false
  gem 'test-unit'

  # Only for sorbet typechecker
  gem 'psych'
  gem 'racc'
  gem 'rbi'
  gem 'yard'

  # See https://guides.rubyonrails.org/debugging_rails_applications.html#debugging-with-the-debug-gem
  gem 'debug', platforms: %i[mri mingw x64_mingw]

  # Speed up commands on slow machines / big apps [https://github.com/rails/spring]
  # gem "spring"

  gem 'css_parser'
  gem 'hash_diff'
end
