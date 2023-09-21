# frozen_string_literal: true
# typed: true

require 'yaml'
require 'json'
require 'json-schema'
require_relative '../test_helper'

class Api01ControllerTest < ActionController::TestCase
  def setup
    PG.connect(host: ENV.fetch('POSTGRES_HOST', nil), dbname: ENV['RAILS_ENV'] == 'test' ? 'test' : 'postgres', user: ENV.fetch('POSTGRES_USER', nil), password: ENV.fetch('POSTGRES_PASSWORD', nil)) { |conn|
      conn.exec(File.new('docker/directus/elasa-schema.sql').read
        .gsub('DROP SCHEMA IF EXISTS public;', '')
        .gsub('CREATE SCHEMA public;', ''))
      conn.exec(File.new('tests/elasa-fixtures.sql').read)
      conn.exec(File.new('lib/api.sql').read)
    }

    @schema = YAML.safe_load_file('public/elasa-0.1.swagger.yaml')
  end

  def schema_for(path)
    path = "/{project}/{theme}/#{path}".gsub('/', '~1')
    "#/paths/#{path}/get/responses/200/content/application~1json/schema"
  end

  def test_settings
    get :settings, params: { project: 'test', theme: 'theme' }
    assert_response :success
    json = JSON.parse(@response.body)
    JSON::Validator.validate!(@schema, json, fragment: schema_for('settings.json'))
  end

  def test_menu
    get :menu, params: { project: 'test', theme: 'theme' }
    assert_response :success
    json = JSON.parse(@response.body)
    JSON::Validator.validate!(@schema, json, fragment: schema_for('menu.json'))
  end

  def test_poi
    get :poi, params: { project: 'test', theme: 'theme', id: 1 }
    assert_response :success
    json = JSON.parse(@response.body)
    JSON::Validator.validate!(@schema, json, fragment: schema_for('poi/{id}.geojson'))
  end

  def test_poi_deps
    get :poi, params: { project: 'test', theme: 'theme', id: 1, deps: 'true' }
    assert_response :success
    json = JSON.parse(@response.body)
    JSON::Validator.validate!(@schema, json, fragment: schema_for('poi/{id}/deps.geojson'))

    assert 2, json['features'].size
  end

  def test_pois_category
    get :pois_category, params: { project: 'test', theme: 'theme', category_id: 5 }
    assert_response :success
    json = JSON.parse(@response.body)
    assert !json['features'].empty?
    JSON::Validator.validate!(@schema, json, fragment: schema_for('pois/category/{id}.{format}'))

    assert 2, json['features'].size
  end

  def test_pois
    get :pois, params: { project: 'test', theme: 'theme' }
    assert_response :success
    json = JSON.parse(@response.body)
    JSON::Validator.validate!(@schema, json, fragment: schema_for('pois.{format}'))

    assert 2, json['features'].size
  end

  def test_ids
    get :pois, params: { project: 'test', theme: 'theme', ids: '1,2' }
    assert_response :success
    json = JSON.parse(@response.body)
    JSON::Validator.validate!(@schema, json, fragment: schema_for('pois.{format}'))

    assert 2, json['features'].size
  end

  def test_geometry_as
    # TODO: check with non point geom
    get :pois, params: { project: 'test', theme: 'theme', geometry_as: 'point' }
    assert_response :success
    json = JSON.parse(@response.body)
    JSON::Validator.validate!(@schema, json, fragment: schema_for('pois.{format}'))
  end

  def test_short_description
    get :pois, params: { project: 'test', theme: 'theme', short_description: 'true' }
    assert_response :success
    json = JSON.parse(@response.body)
    JSON::Validator.validate!(@schema, json, fragment: schema_for('pois.{format}'))

    assert 20, json['features'][0]['properties']['description'].size
    # TODO: assert no html tags
  end

  def test_dates
    # TODO: check on object with dates
    get :pois, params: { project: 'test', theme: 'theme', start_date: '2022-01-01', end_date: '2022-12-31' }
    assert_response :success
    json = JSON.parse(@response.body)
    JSON::Validator.validate!(@schema, json, fragment: schema_for('pois.{format}'))
  end
end
