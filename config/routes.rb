# frozen_string_literal: true
# typed: strict

Rails.application.routes.draw do
  # API
  scope '/api/0.1/:project/:theme' do
    get 'settings', controller: 'api01'
    get 'articles', controller: 'api01'
    get 'article/:slug(.:format)', controller: 'api01', action: :article
    get 'menu', controller: 'api01'
    get 'poi/:id', controller: 'api01', action: :poi
    get 'poi/:id/deps', controller: 'api01', action: :poi, defaults: { deps: 'true' }
    get 'pois(.:format)', controller: 'api01', action: :pois
    get 'pois/category/:category_id(.:format)', controller: 'api01', action: :pois_category
    get 'attribute_translations/:lang.json', controller: 'api01', action: :attribute_translations
  end

  scope '/api/0.2/project/:project' do
    scope 'admin' do
      get 'sources/load', controller: 'api02_admin', action: :sources_load
    end
  end
end
