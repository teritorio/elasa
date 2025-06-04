CREATE INDEX pois_idx_ref ON pois USING gin((properties->'tags'->'ref')) WHERE properties->'tags' ? 'ref';
