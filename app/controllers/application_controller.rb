# frozen_string_literal: true
# typed: strict

class ApplicationController < ActionController::API
  extend T::Sig

  include ActionController::MimeResponds

  around_action :with_transaction

  delegate :osm_name, to: :current_user, prefix: true

  sig { params(_aaa: T.untyped, _bbb: T.untyped).void }
  def initialize(*_aaa, **_bbb)
    super

    # Stupid code to make typing OK
    @db = T.let(DB_POOL.with do |conn|
      conn.transaction do |tx|
        tx
      end
    end, PG::Connection)
  end

  private

  def with_transaction
    DB_POOL.with do |conn|
      conn.transaction do |tx|
        @db = tx
        yield
      end
    end
  end
end
