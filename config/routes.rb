# frozen_string_literal: true
# typed: strict

Rails.application.routes.draw do
  # API
  scope '/api/0.1/:project/:theme' do
    get 'settings', controller: 'api01'
    get 'menu', controller: 'api01'
    get 'pois', controller: 'api01'
  end
end
