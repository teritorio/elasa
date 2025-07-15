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
    conn.exec('INSERT INTO languages(code, name, direction) VALUES ($1, $2, $3) ON CONFLICT DO NOTHING', %w[pt-PT Portuguese ltr])
    conn.exec('INSERT INTO languages(code, name, direction) VALUES ($1, $2, $3) ON CONFLICT DO NOTHING', %w[it-IT Italian ltr])
    conn.exec('INSERT INTO languages(code, name, direction) VALUES ($1, $2, $3) ON CONFLICT DO NOTHING', %w[nl-NL Dutch ltr])
    conn.exec('INSERT INTO languages(code, name, direction) VALUES ($1, $2, $3) ON CONFLICT DO NOTHING', %w[de-DE German ltr])
  }
end

def create_user(project_id, project_slug, role_uuid)
  PG.connect(host: 'postgres', dbname: 'postgres', user: 'postgres', password: 'postgres') { |conn|
    email = "#{project_slug}@example.com"
    conn.exec('
      INSERT INTO directus_users(id, email, password, language, status, role, project_id)
      VALUES (gen_random_uuid(), $1, $2, $3, $4, $5, $6)
      ON CONFLICT ON CONSTRAINT directus_users_email_unique DO UPDATE SET
        password = EXCLUDED.password,
        language = EXCLUDED.language,
        status = EXCLUDED.status,
        role = EXCLUDED.role,
        project_id = EXCLUDED.project_id
      RETURNING id
    ', [
      email,
      # Default password: d1r3ctu5
      '$argon2id$v=19$m=65536,t=3,p=4$troFBS21lcZamhZNWx0i5A$sPrhE4NWiMx96ck92mXjGVDYt1xzIw1ujXIo1YI3F0E',
      'fr-FR',
      'active', # draft
      role_uuid,
      project_id,
    ]) { |result|
      result.first['id']
    }
  }
end

def create_role(project_slug)
  PG.connect(host: 'postgres', dbname: 'postgres', user: 'postgres', password: 'postgres') { |conn|
    role_name = "Local Admin - #{project_slug}"
    conn.exec('DELETE FROM directus_roles WHERE name = $1', [role_name])
    role_uuid = conn.exec('
      MERGE
        INTO directus_roles
      USING (SELECT gen_random_uuid()::uuid, $1, \'supervised_user_circle\', \'5979e2ac-a34f-4c70-bf9d-de48b3900a8f\'::uuid) AS source(id, name, icon, parent) ON
        directus_roles.name = source.name
      WHEN MATCHED THEN
        UPDATE SET
          icon = source.icon,
          parent = source.parent
      WHEN NOT MATCHED THEN
        INSERT (id, name, icon, parent)
        VALUES (source.id, source.name, source.icon, source.parent)
      RETURNING
        directus_roles.id
    ', [role_name]) { |result|
      result.first['id']
    }
    policy_uuid = conn.exec('
      MERGE INTO
        directus_policies
      USING (SELECT gen_random_uuid()::uuid, $1, \'supervised_user_circle\') AS source(id, name, icon) ON
        directus_policies.name = source.name
      WHEN MATCHED THEN
        UPDATE SET
          icon = source.icon
      WHEN NOT MATCHED THEN
        INSERT (id, name, icon)
        VALUES (source.id, source.name, source.icon)
      RETURNING
        directus_policies.id
    ', [role_name]) { |result|
      result.first['id']
    }
    conn.exec('
      MERGE INTO
        directus_access
      USING (SELECT gen_random_uuid()::uuid, $1::uuid, $2::uuid) AS source(id, role, policy) ON
        directus_access.role = source.role AND
        directus_access.policy = source.policy
      WHEN NOT MATCHED THEN
        INSERT (id, role, policy)
        VALUES (source.id, source.role, source.policy)
    ', [role_uuid, policy_uuid])

    [role_uuid, policy_uuid]
  }
end
