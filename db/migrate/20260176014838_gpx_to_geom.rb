# frozen_string_literal: true
# typed: false

require 'nokogiri'


class GpxToGeom < ActiveRecord::Migration[8.0]
  extend T::Sig

  sig { params(gpx: String).returns(T.nilable(String)) }
  def self.gpx2geojson(gpx)
    doc = Nokogiri::XML(gpx)
    doc.remove_namespaces!

    coordinates = T.let(doc.xpath('/gpx/rte').collect{ |rte|
      rte.xpath('rtept').collect{ |pt|
        [pt.attribute('lon').to_s.to_f, pt.attribute('lat').to_s.to_f]
      }
    } +
      doc.xpath('/gpx/trk').collect{ |trk|
        trk.xpath('trkseg').collect{ |seg|
          seg.xpath('trkpt').collect{ |pt|
            [pt.attribute('lon').to_s.to_f, pt.attribute('lat').to_s.to_f]
          }
        }
      }.flatten(1), T::Array[T::Array[[Float, Float]]])

    sum = T.let([], T::Array[T::Array[[Float, Float]]])
    coordinates.each{ |linestring|
      # Remove consecutive duplicate points
      linestring = linestring.chunk{ |x| x }.to_a.map(&:first)

      next if linestring.size < 2

      if !sum.empty? && sum[-1][-1] == linestring[0]
        sum[-1] += linestring[1..]
      else
        sum << linestring
      end
    }

    if sum.empty?
      nil
    elsif sum.length == 1
      { type: 'LineString', coordinates: sum[0] }.to_json
    else
      { type: 'MultiLineString', coordinates: sum }.to_json
    end
  end

  sig { void }
  def change
    sql = <<~SQL.squish
      SELECT
        DISTINCT tables.table_name
      FROM
        projects
        JOIN sources ON
            sources.project_id = projects.id
        JOIN information_schema.tables AS tables ON
            tables.table_name LIKE 'local-' || projects.slug || '-' || sources.slug || '%'
        JOIN information_schema.key_column_usage ON
            key_column_usage.table_schema = 'public' AND
            key_column_usage.table_name = tables.table_name AND
            key_column_usage.column_name = 'route___gpx_trace'
      ;
    SQL

    result = ActiveRecord::Base.connection.exec_query(sql)
    table_names = result.collect{ |row| row['table_name'] }.to_a

    file_names = table_names.collect { |table|
      puts table
      ActiveRecord::Base.connection.exec_query("SELECT local.id, filename_disk FROM \"#{table}\" AS local JOIN directus_files ON directus_files.id = local.route___gpx_trace").collect{ |gpx|
        file_name = gpx['filename_disk']
        puts "Migrate #{table} #{file_name.inspect}"
        geojson = self.class.gpx2geojson(File.read("/directus/uploads/#{file_name}"))
        ActiveRecord::Base.connection.exec_query("UPDATE \"#{table}\" SET geom = ST_GeomFromGeoJSON($2) WHERE id = $1", 'SQL', [gpx['id'], geojson])
        file_name
      }
      ActiveRecord::Base.connection.exec_query("ALTER TABLE \"#{table}\" DROP COLUMN route___gpx_trace CASCADE")
    }.flatten

    file_names.uniq.each { |file_name|
      ActiveRecord::Base.connection.exec_query('DELETE FROM directus_files WHERE filename_disk = $1', 'SQL', [file_name])
      File.delete("/directus/uploads/#{file_name}")
    }

    ActiveRecord::Base.connection.exec_query("DELETE FROM directus_fields WHERE collection LIKE 'local-%' AND field = 'route___gpx_trace'")
  end
end
