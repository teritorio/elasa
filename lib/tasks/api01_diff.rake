# frozen_string_literal: true
# typed: true

require 'rake'
require 'json'
require 'http'
require 'hash_diff'


def fetch_json(url)
  puts url.inspect
  JSON.parse(HTTP.follow.get(url))
end

class Object
  def compact_blank_deep
    self
  end
end

class Array
  def compact_blank_deep
    r = map(&:compact_blank_deep).compact_blank

    r.presence
  end
end

class Hash
  def compact_blank_deep
    r = each_with_object({}) { |(k, v), h|
      if (_v = v.compact_blank_deep)
        h[k] = _v
      end
    }.compact_blank

    r.presence
  end
end

def compare_settings(url_old, url_new)
  hashes = [
    "#{url_old}/settings.json",
    "#{url_new}/settings.json",
  ].collect{ |url|
    hash = fetch_json(url).except('id', 'slug')
    hash['themes'].each{ |theme|
      theme.delete('id')
    }
    hash
  }

  diff = HashDiff::Comparison.new(hashes[0], hashes[1])
  puts JSON.dump(diff.diff) if !diff.diff.empty?
end

def compare_articles(url_old, url_new)
  hashes = [
    "#{url_old}/articles.json?slug=non-classe",
    "#{url_new}/articles.json",
  ].collect{ |url|
    array = fetch_json(url)
    array.collect{ |article|
      article.except('post_id')
    }
  }

  diff = HashDiff::Comparison.new(hashes[0], hashes[1])
  puts JSON.dump(diff.diff) if !diff.diff.empty?
end

def compare_menu(url_old, url_new)
  hashes = [
    "#{url_old}/menu.json",
    "#{url_new}/menu.json",
  ].collect{ |url|
    array = fetch_json(url).compact_blank_deep
    array.sort_by{ |menu|
      menu['id']
    }.collect{ |menu|
      menu['menu_group']&.delete('id')
      menu['category']&.delete('id')
      menu['link']&.delete('id')

      if menu['category']
        menu['category']['zoom'] = menu['category']['zoom'].to_i
      end

      menu
    }
  }

  diff = HashDiff::Comparison.new(hashes[0], hashes[1])
  puts JSON.dump(diff.diff) if !diff.diff.empty?
end

def compare_pois(url_old, url_new)
  hashes = [
    "#{url_old}/pois.json",
    "#{url_new}/pois.json",
  ].collect{ |url|
    array = fetch_json(url)['features'].compact_blank_deep
    array.sort_by{ |poi|
      poi['id']
    }
  }

  diff = HashDiff::Comparison.new(hashes[0], hashes[1])
  puts JSON.dump(diff.diff) if !diff.diff.empty?
end

def compare_attribute_translations(url_old, url_new)
  hashes = [
    "#{url_old}/attribute_translations/fr.json",
    "#{url_new}/attribute_translations/fr.json",
  ].collect{ |url|
    hash = fetch_json(url).except('id', 'slug')
    hash
  }

  diff = HashDiff::Comparison.new(hashes[0], hashes[1])
  puts JSON.dump(diff.diff) if !diff.diff.empty?
end

namespace :api do
  desc 'Validate API JSON with Swagger Schema'
  task :diff, [] => :environment do
    url_old, url_new = ARGV[2..]
    compare_settings(url_old, url_new)
    compare_articles(url_old, url_new)
    compare_menu(url_old, url_new)
    compare_pois(url_old, url_new)
    compare_attribute_translations(url_old, url_new)

    exit 0 # Beacause of manually deal with rake command line arguments
  end
end
