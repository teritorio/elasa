CREATE INDEX pois_idx_geom ON pois USING gist(geom);
