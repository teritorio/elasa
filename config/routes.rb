# frozen_string_literal: true
# typed: strict

Rails.application.routes.draw do
  # API
  scope '/api/0.1/:project/:theme' do
    get 'settings', controller: 'api01'
    get 'articles', controller: 'api01'
    get 'menu', controller: 'api01'
    get 'poi/:id', controller: 'api01', action: :poi
    get 'poi/:id/deps', controller: 'api01', action: :poi, defaults: { deps: 'true' }
    get 'pois', controller: 'api01'
    get 'pois/category/:category_id', controller: 'api01', action: :pois_category
  end
end
