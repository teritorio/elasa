# frozen_string_literal: true
# typed: true

require 'yaml'
require 'json'
require 'json-schema'
require_relative '../test_helper'

class Api01ControllerTest < ActionController::TestCase
  def setup
    PG.connect(host: 'postgres', dbname: 'postgres', user: 'postgres', password: 'postgres') { |conn|
      conn.exec(File.new('lib/api.sql').read)
    }

    @schema = YAML.safe_load_file('public/elasa-0.1.swagger.yaml')
  end

  def schema_for(path)
    "#/paths/~1{project}~1{theme}~1#{path}/get/responses/200/content/application~1json/schema"
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

  def test_pois
    get :pois, params: { project: 'seignanx', theme: 'tourism' }
    assert_response :success
    json = JSON.parse(@response.body)
    puts JSON.pretty_generate(json)
    JSON::Validator.validate!(@schema, json, fragment: schema_for('pois.{format}'))
  end
end
