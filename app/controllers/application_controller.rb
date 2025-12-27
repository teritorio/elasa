# frozen_string_literal: true
# typed: strict

class ApplicationController < ActionController::API
  include ActionController::MimeResponds

  around_action :with_transaction

  delegate :osm_name, to: :current_user, prefix: true

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
