# frozen_string_literal: true
# typed: true

require 'json'
require 'http'
require 'pg'


def fetch_json(url)
  response = HTTP.follow.get(url)
  raise "[ERROR] #{url} => #{response.status}" if !response.status.success?

  JSON.parse(response)
end

def set_default_languages
  PG.connect(host: 'postgres', dbname: 'postgres', user: 'postgres', password: 'postgres') { |conn|
    conn.exec('INSERT INTO languages(code, name, direction) VALUES ($1, $2, $3) ON CONFLICT DO NOTHING', %w[fr-FR French ltr])
    conn.exec('INSERT INTO languages(code, name, direction) VALUES ($1, $2, $3) ON CONFLICT DO NOTHING', %w[en-US English ltr])
    conn.exec('INSERT INTO languages(code, name, direction) VALUES ($1, $2, $3) ON CONFLICT DO NOTHING', %w[es-ES Spanish ltr])
  }
end

def create_user(project_id, project_slug, role_uuid)
  PG.connect(host: 'postgres', dbname: 'postgres', user: 'postgres', password: 'postgres') { |conn|
    email = "#{project_slug}@example.com"
    conn.exec('DELETE FROM directus_users WHERE email = $1', [email])
    conn.exec('
      INSERT INTO directus_users(id, email, password, language, status, role, project_id)
      VALUES (gen_random_uuid(), $1, $2, $3, $4, $5, $6)
    ', [
      email,
      # Default password: d1r3ctu5
      '$argon2id$v=19$m=65536,t=3,p=4$troFBS21lcZamhZNWx0i5A$sPrhE4NWiMx96ck92mXjGVDYt1xzIw1ujXIo1YI3F0E',
      'fr-FR',
      'active', # draft
      role_uuid,
      project_id,
    ])
  }
end

def create_role(project_slug)
  PG.connect(host: 'postgres', dbname: 'postgres', user: 'postgres', password: 'postgres') { |conn|
    role_name = "Local Admin - #{project_slug}"
    conn.exec('DELETE FROM directus_roles WHERE name = $1', [role_name])
    role_uuid = conn.exec('
      INSERT INTO directus_roles(id, name, icon, description, ip_access, enforce_tfa, admin_access, app_access)
      SELECT
        gen_random_uuid(),
        $1,
        icon,
        description,
        ip_access,
        enforce_tfa,
        admin_access,
        app_access
      FROM
        directus_roles
      WHERE
        id = \'5979e2ac-a34f-4c70-bf9d-de48b3900a8f\' -- Local Admin
      RETURNING
        id
    ', [role_name]) { |result|
      result.first['id']
    }
    conn.exec('
      INSERT INTO directus_permissions(role, collection, action, permissions, validation, presets, fields)
      SELECT
        $1,
        collection,
        action,
        permissions,
        validation,
        presets,
        fields
      FROM
        directus_permissions
      WHERE
        role = \'5979e2ac-a34f-4c70-bf9d-de48b3900a8f\'
    ', [role_uuid])
    role_uuid
  }
end
