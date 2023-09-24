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

  def test_articles
    get :articles, params: { project: 'test', theme: 'theme' }
    assert_response :success
    json = JSON.parse(@response.body)
    JSON::Validator.validate!(@schema, json, fragment: schema_for('articles.json'))

    assert_equal 1, json.size
  end

  def test_menu
    get :menu, params: { project: 'test', theme: 'theme' }
    assert_response :success
    json = JSON.parse(@response.body)
    JSON::Validator.validate!(@schema, json, fragment: schema_for('menu.json'))

    assert_equal 5, json[3]['id']
    assert !json[3]['category']['filters'].empty?
  end

  def test_poi
    get :poi, params: { project: 'test', theme: 'theme', id: 1 }
    assert_response :success
    json = JSON.parse(@response.body)
    JSON::Validator.validate!(@schema, json, fragment: schema_for('poi/{id}.geojson'))

    assert json.dig('properties', 'editorial', 'popup_fields')
  end

  def test_poi_deps
    get :poi, params: { project: 'test', theme: 'theme', id: 1, deps: 'true' }
    assert_response :success
    json = JSON.parse(@response.body)
    JSON::Validator.validate!(@schema, json, fragment: schema_for('poi/{id}/deps.geojson'))

    assert_equal 2, json['features'].size
  end

  def test_pois_category
    get :pois_category, params: { project: 'test', theme: 'theme', category_id: 5 }
    assert_response :success
    json = JSON.parse(@response.body)
    assert !json['features'].empty?
    JSON::Validator.validate!(@schema, json, fragment: schema_for('pois/category/{id}.{format}'))

    assert_equal 2, json['features'].size
  end

  def test_pois
    get :pois, params: { project: 'test', theme: 'theme' }
    assert_response :success
    json = JSON.parse(@response.body)
    JSON::Validator.validate!(@schema, json, fragment: schema_for('pois.{format}'))

    assert_equal 2, json['features'].size
    assert 'Point', json['features'][0]['geometry']['type']
    assert 'Polygon', json['features'][1]['geometry']['type']
  end

  def test_ids
    get :pois, params: { project: 'test', theme: 'theme', ids: '1,2' }
    assert_response :success
    json = JSON.parse(@response.body)
    JSON::Validator.validate!(@schema, json, fragment: schema_for('pois.{format}'))

    assert_equal 2, json['features'].size
  end

  def test_geometry_as
    get :poi, params: { project: 'test', theme: 'theme', id: 2, geometry_as: 'point' }
    assert_response :success
    json = JSON.parse(@response.body)
    JSON::Validator.validate!(@schema, json, fragment: schema_for('poi/{id}.geojson'))

    assert 'Point', json['geometry']['type']
  end

  def test_short_description
    get :pois, params: { project: 'test', theme: 'theme', short_description: 'true' }
    assert_response :success
    json = JSON.parse(@response.body)
    JSON::Validator.validate!(@schema, json, fragment: schema_for('pois.{format}'))

    assert_equal 20, json['features'][0]['properties']['description'].size
    # TODO: assert no html tags
  end

  def test_dates
    get :pois, params: { project: 'test', theme: 'theme', start_date: '2022-01-01', end_date: '2022-12-31' }
    assert_response :success
    json = JSON.parse(@response.body)
    JSON::Validator.validate!(@schema, json, fragment: schema_for('pois.{format}'))

    assert_equal 2, json['features'].size
  end
end
