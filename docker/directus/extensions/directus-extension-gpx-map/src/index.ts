import { defineInterface } from '@directus/extensions-sdk';
import InterfaceComponent from './interface.vue';

export default defineInterface({
	id: 'gpx-map',
	name: 'Map (GPX)',
	icon: 'map',
	description: 'Map interface with GPX file import for geometry fields',
	component: InterfaceComponent,
	types: [
		'geometry.Point',
		'geometry.LineString',
		'geometry.Polygon',
		'geometry.MultiPoint',
		'geometry.MultiLineString',
		'geometry.MultiPolygon',
		'geometry',
		'json',
		'text',
	],
	group: 'selection',
	recommendedDisplays: [],
	options: [
		{
			field: 'defaultView',
			name: 'Default Map View',
			type: 'json',
			meta: {
				interface: 'input-code',
				width: 'full',
				options: { language: 'json' },
			},
			schema: {
				default_value: '{"center": [46.8, 2.3], "zoom": 5}',
			},
		},
	],
});
