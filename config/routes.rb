# frozen_string_literal: true
# typed: strict

Rails.application.routes.draw do
  get 'up' => 'rails/health#show'

  # API
  get '/api/0.1', controller: 'api01', action: :projects, defaults: { format: 'json' }
  scope '/api/0.1/:project/:theme' do
    get 'settings', controller: 'api01', action: :project
    get 'articles', controller: 'api01'
    get 'article/:slug(.:format)', controller: 'api01', action: :article
    get 'menu', controller: 'api01'
    get 'poi(.:format)/:id', controller: 'api01', action: :poi
    get 'poi(.:format)/:id/deps', controller: 'api01', action: :poi, defaults: { deps: 'true' }
    get 'pois(.:format)', controller: 'api01', action: :pois
    get 'pois.schema.json', controller: 'api01', action: :pois_schema
    get 'pois/category/:category_id(.:format)', controller: 'api01', action: :pois_category
    get 'attribute_translations/:lang.json', controller: 'api01', action: :attribute_translations
  end

  get '/api/0.2', controller: 'api02', action: :projects, defaults: { format: 'json' }
  scope '/api/0.2/:project/:theme' do
    get 'settings', controller: 'api02', action: :project
    get 'articles', controller: 'api02'
    get 'article/:slug(.:format)', controller: 'api02', action: :article
    get 'menu', controller: 'api02'
    get 'poi/:id', controller: 'api02', action: :poi
    get 'poi/:id/deps', controller: 'api02', action: :poi, defaults: { deps: 'true' }
    get 'pois(.:format)', controller: 'api02', action: :pois
    get 'pois/category/:category_id(.:format)', controller: 'api02', action: :pois_category
    get 'attribute_translations/:lang.json', controller: 'api02', action: :attribute_translations
  end

  scope '/api/0.2/project/:project' do
    scope 'admin' do
      get 'sources/load', controller: 'api02_admin', action: :sources_load
    end
  end
end
