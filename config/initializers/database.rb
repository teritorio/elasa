# frozen_string_literal: true
# typed: false

require 'connection_pool'

DB_POOL = ConnectionPool.new(size: 5, timeout: 5) {
  PG.connect(
    host: ENV.fetch('POSTGRES_HOST', nil),
    dbname: ENV['RAILS_ENV'] == 'test' ? 'test' : 'postgres',
    user: ENV.fetch('POSTGRES_USER', nil),
    password: ENV.fetch('POSTGRES_PASSWORD', nil),
  )
}
