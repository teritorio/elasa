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
      conn.exec(File.new('lib/api.sql').read)
    }

    @schema = YAML.safe_load_file('public/elasa-0.1.swagger.yaml')
  end

  def schema_for(path)
    path = "/{project}/{theme}/#{path}".gsub('/', '~1')
    "#/paths/#{path}/get/responses/200/content/application~1json/schema"
  end

  def test_settings
    get :settings, params: { project: 'seignanx', theme: 'tourism' }
    assert_response :success
    json = JSON.parse(@response.body)
    JSON::Validator.validate!(@schema, json, fragment: schema_for('settings.json'))
  end

  def test_menu
    get :menu, params: { project: 'seignanx', theme: 'tourism' }
    assert_response :success
    json = JSON.parse(@response.body)
    JSON::Validator.validate!(@schema, json, fragment: schema_for('menu.json'))
  end

  def test_poi
    get :poi, params: { project: 'seignanx', theme: 'tourism', id: 1 }
    assert_response :success
    json = JSON.parse(@response.body)
    JSON::Validator.validate!(@schema, json, fragment: schema_for('poi/{id}.geojson'))
  end

  def test_poi_deps
    get :poi, params: { project: 'seignanx', theme: 'tourism', id: 1 }
    assert_response :success
    json = JSON.parse(@response.body)
    JSON::Validator.validate!(@schema, json, fragment: schema_for('poi/{id}/deps.geojson'))
  end

  def test_pois_category
    get :pois_category, params: { project: 'seignanx', theme: 'tourism', category_id: 1175 }
    assert_response :success
    json = JSON.parse(@response.body)
    assert !json['features'].empty?
    JSON::Validator.validate!(@schema, json, fragment: schema_for('pois/category/{id}.{format}'))
  end

  def test_pois
    get :pois, params: { project: 'seignanx', theme: 'tourism' }
    assert_response :success
    json = JSON.parse(@response.body)
    JSON::Validator.validate!(@schema, json, fragment: schema_for('pois.{format}'))
  end

  def test_ids
    get :pois, params: { project: 'seignanx', theme: 'tourism', ids: '1,2' }
    assert_response :success
    json = JSON.parse(@response.body)
    JSON::Validator.validate!(@schema, json, fragment: schema_for('pois.{format}'))
  end

  def test_geometry_as
    # TODO: check with non point geom
    get :pois, params: { project: 'seignanx', theme: 'tourism', geometry_as: 'point' }
    assert_response :success
    json = JSON.parse(@response.body)
    JSON::Validator.validate!(@schema, json, fragment: schema_for('pois.{format}'))
  end

  def test_short_description
    # TODO: check on html long description
    get :pois, params: { project: 'seignanx', theme: 'tourism', short_description: 'true' }
    assert_response :success
    json = JSON.parse(@response.body)
    JSON::Validator.validate!(@schema, json, fragment: schema_for('pois.{format}'))
  end

  def test_dates
    # TODO: check on object with dates
    get :pois, params: { project: 'seignanx', theme: 'tourism', start_date: '2022-01-01', end_date: '2022-12-31' }
    assert_response :success
    json = JSON.parse(@response.body)
    JSON::Validator.validate!(@schema, json, fragment: schema_for('pois.{format}'))
  end
end
