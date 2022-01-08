require 'open-uri'
require 'json'
require 'pg'

split_sharp = lambda { |str|
    str.split('#')
}

to_float = lambda { |str|
    str.to_f
}

@fields = {
    # id
    id: 'SyndicObjectID',
    # metadata
    lat: {k: 'LAT', f: to_float},
    lng: {k: 'LON', f: to_float},
    # Mapping to OSM tags
    name: 'SyndicObjectName',
    'addr:street': %w{AD1 AD1SUITE AD2 AD3},
    'addr:postcode': 'CP',
    'addr:city': 'COMMUNE',
    phone: {k: 'TEL', f: split_sharp},
    mobile: {k: 'TELMOB', f: split_sharp},
    email: {k: 'MAIL', f: split_sharp},
    website: {k: 'URL', f: split_sharp},
    image: {k: 'PHOTO', f: split_sharp},
    # Extra mapping
    tis_ObjectTypeName: {k: 'ObjectTypeName'}, # Restauration tis-restaurant
    tis_LOCALISATION: {k: 'LOCALISATION', f: split_sharp},
    tis_CATRES: {k: 'CATRES', f: split_sharp}, # Typo in original data
    tis_TYPEACTIVSPORT: {k: 'TYPEACTIVSPORT', f: split_sharp}, # Surf electrique/foil#Wake board tis-prestataires-activités-sportives
    tis_HABTYPE: {k: 'HABTYPE', f: split_sharp}, # Appartement#Châteaux et demeures de prestige tis-locations
    tis_TYPEITI: {k: 'TYPEITI', f: split_sharp}, # Pédestre#Routier#Vélo" tis-balades-pedestres
    tis_MONUMTYPE: {k: 'MONUMTYPE', f: split_sharp}, # Abbaye#Cloître#Eglise tis-monuments-ouverts-visite
}

def parse_tourinsoft(json)
    json['d'].collect { |obj|
        r = Hash[@fields.collect{ |key, setting|
            # Normalize setting
            if !setting.kind_of? Hash then
                setting = {k: setting}
            end
            if !setting[:k].kind_of? Array then
                setting[:k] = [setting[:k]]
            end

            value = setting[:k].collect{ |kk| obj[kk] }.reject(&:nil?).collect(&:strip).join
            if value != '' then
                if setting[:f] then
                    value = setting[:f].call(value)
                end
                [key, value]
            end
        }.reject(&:nil?)]

        if r[:lng] && r[:lat]
            {
                id: r[:id],
                point: [r[:lng], r[:lat]],
                properties: r.except(:id, :lat, :lng),
            }
        end
    }.reject(&:nil?)
end

def enhance_tourinsoft(pois, photos_base_url)
    pois.collect{ |poi|
        if poi[:properties][:image] then
            poi[:properties][:image] = poi[:properties][:image].collect{ |image| photos_base_url + image }
        end
        poi
    }
end

def insert_tourinsoft(conn, project_id, source_tourinsoft_id, pois)
    conn.exec_params("DELETE FROM poi_tourinsoft WHERE project_id = $1 AND source_tourinsoft_id = $2", [project_id, source_tourinsoft_id])

    copy_query = "COPY poi_tourinsoft(project_id, slug, source_tourinsoft_id, geom, properties) FROM STDIN"
    conn.copy_data(copy_query, PG::TextEncoder::CopyRow.new) {
        pois.each{ |poi|
            conn.put_copy_data([
                project_id,
                poi[:id],
                source_tourinsoft_id,
                "POINT(#{poi[:point][0]} #{poi[:point][1]})",
                JSON.dump(poi[:properties])
            ])
        }
    }
end


conn = PG::Connection.open(host: 'localhost', port: 5432, dbname: 'postgres', user: 'postgres', password: 'postgres')
res = conn.exec_params('SELECT id, url, photos_base_url FROM sources_tourinsoft ORDER BY id')

project_id = 1

total = res.to_a.size
res.to_a.each_with_index { |tourinsoft, index|
# res.to_a[0..1].each { |tourinsoft|
    puts("#{index}/#{total} #{tourinsoft['url']}")
    body = URI.open(tourinsoft['url'], &:read)
    json = JSON.parse(body)
    pois = parse_tourinsoft(json)
    pois = enhance_tourinsoft(pois, tourinsoft['photos_base_url'])
    puts(pois.size)
    insert_tourinsoft(conn, project_id, tourinsoft['id'], pois)
}
