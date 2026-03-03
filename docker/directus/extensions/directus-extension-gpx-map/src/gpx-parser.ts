type Coord = [number, number];

interface LineStringGeometry {
	type: 'LineString';
	coordinates: Coord[];
}

interface MultiLineStringGeometry {
	type: 'MultiLineString';
	coordinates: Coord[][];
}

export type GeoJSONGeometry = LineStringGeometry | MultiLineStringGeometry;

/**
 * Parse a GPX string into a GeoJSON LineString or MultiLineString geometry.
 * Ported from db/migrate/20260176014838_gpx_to_geom.rb
 */
export function gpx2geojson(gpx: string): GeoJSONGeometry {
	const parser = new DOMParser();
	const doc = parser.parseFromString(gpx, 'application/xml');

	const parseError = doc.querySelector('parsererror');
	if (parseError) {
		throw new Error('Invalid XML: ' + parseError.textContent);
	}

	// Extract coordinates from <rte>/<rtept> and <trk>/<trkseg>/<trkpt>
	const coordinates: Coord[][] = [];

	// Routes
	const routes = doc.querySelectorAll('rte');
	routes.forEach((rte) => {
		const points: Coord[] = [];
		rte.querySelectorAll('rtept').forEach((pt) => {
			const lon = parseFloat(pt.getAttribute('lon') || '0');
			const lat = parseFloat(pt.getAttribute('lat') || '0');
			points.push([lon, lat]);
		});
		if (points.length > 0) {
			coordinates.push(points);
		}
	});

	// Tracks
	const tracks = doc.querySelectorAll('trk');
	tracks.forEach((trk) => {
		trk.querySelectorAll('trkseg').forEach((seg) => {
			const points: Coord[] = [];
			seg.querySelectorAll('trkpt').forEach((pt) => {
				const lon = parseFloat(pt.getAttribute('lon') || '0');
				const lat = parseFloat(pt.getAttribute('lat') || '0');
				points.push([lon, lat]);
			});
			if (points.length > 0) {
				coordinates.push(points);
			}
		});
	});

	// Remove consecutive duplicate points and merge contiguous linestrings
	const merged: Coord[][] = [];
	for (const linestring of coordinates) {
		// Remove consecutive duplicates
		const deduped: Coord[] = [];
		for (const coord of linestring) {
			const last = deduped[deduped.length - 1];
			if (!last || last[0] !== coord[0] || last[1] !== coord[1]) {
				deduped.push(coord);
			}
		}

		if (deduped.length < 2) continue;

		// Merge with previous if contiguous
		const lastMerged = merged[merged.length - 1];
		if (lastMerged) {
			const lastPoint = lastMerged[lastMerged.length - 1]!;
			if (lastPoint[0] === deduped[0]![0] && lastPoint[1] === deduped[0]![1]) {
				lastMerged.push(...deduped.slice(1));
				continue;
			}
		}
		merged.push(deduped);
	}

	if (merged.length === 0) {
		throw new Error('No routes or tracks found in GPX file');
	}

	if (merged.length === 1) {
		return { type: 'LineString', coordinates: merged[0]! };
	}

	return { type: 'MultiLineString', coordinates: merged };
}
