<template>
	<div class="gpx-map-interface">
		<div ref="mapContainer" class="map-container" />

		<div class="gpx-upload">
			<div
				class="drop-zone"
				:class="{ dragging }"
				@dragover.prevent="dragging = true"
				@dragleave="dragging = false"
				@drop.prevent="onDrop"
			>
				<v-icon name="upload_file" />
				<span>{{ fileName || 'Drop a GPX file here or click to browse' }}</span>
				<input
					ref="fileInput"
					type="file"
					accept=".gpx,application/gpx+xml"
					class="file-input"
					@change="onFileSelect"
					@click.stop
				/>
			</div>

			<v-button v-if="value" secondary small icon rounded class="clear-button" @click="clear">
				<v-icon name="close" />
			</v-button>
		</div>

		<v-notice v-if="error" type="danger" class="error-notice">
			{{ error }}
		</v-notice>
	</div>
</template>

<script lang="ts">
import { defineComponent, ref, watch, onMounted, onBeforeUnmount, PropType } from 'vue';
import L from 'leaflet';
import { gpx2geojson, GeoJSONGeometry } from './gpx-parser';

export default defineComponent({
	props: {
		value: {
			type: Object as PropType<GeoJSONGeometry | null>,
			default: null,
		},
		disabled: {
			type: Boolean,
			default: false,
		},
		defaultView: {
			type: [String, Object] as PropType<string | { center: [number, number]; zoom: number } | null>,
			default: null,
		},
	},
	emits: ['input'],
	setup(props, { emit }) {
		const mapContainer = ref<HTMLElement | null>(null);
		const fileInput = ref<HTMLInputElement | null>(null);
		const fileName = ref<string | null>(null);
		const error = ref<string | null>(null);
		const dragging = ref(false);

		let map: L.Map | null = null;
		let geojsonLayer: L.GeoJSON | null = null;

		function getDefaultView(): { center: [number, number]; zoom: number } {
			const fallback = { center: [46.8, 2.3] as [number, number], zoom: 5 };
			if (!props.defaultView) return fallback;

			try {
				const parsed = typeof props.defaultView === 'string'
					? JSON.parse(props.defaultView)
					: props.defaultView;
				return {
					center: parsed.center || fallback.center,
					zoom: parsed.zoom ?? fallback.zoom,
				};
			} catch {
				return fallback;
			}
		}

		function initMap() {
			if (!mapContainer.value || map) return;

			const view = getDefaultView();
			map = L.map(mapContainer.value).setView(view.center, view.zoom);

			L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
				attribution: '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a>',
				maxZoom: 19,
			}).addTo(map);

			displayGeometry(props.value);
		}

		function displayGeometry(geojson: GeoJSONGeometry | null) {
			if (!map) return;

			if (geojsonLayer) {
				geojsonLayer.remove();
				geojsonLayer = null;
			}

			if (!geojson) return;

			geojsonLayer = L.geoJSON(geojson, {
				style: {
					color: '#6644FF',
					weight: 4,
					opacity: 0.8,
				},
			}).addTo(map);

			const bounds = geojsonLayer.getBounds();
			if (bounds.isValid()) {
				map.fitBounds(bounds, { padding: [20, 20] });
			}
		}

		function processGpxFile(file: File) {
			error.value = null;

			if (!file.name.toLowerCase().endsWith('.gpx')) {
				error.value = 'Please select a .gpx file';
				return;
			}

			const reader = new FileReader();
			reader.onload = (e) => {
				try {
					const gpxContent = e.target?.result as string;
					const geojson = gpx2geojson(gpxContent);
					fileName.value = file.name;
					emit('input', geojson);
				} catch (err) {
					error.value = err instanceof Error ? err.message : 'Failed to parse GPX file';
				}
			};
			reader.onerror = () => {
				error.value = 'Failed to read file';
			};
			reader.readAsText(file);
		}

		function onDrop(event: DragEvent) {
			dragging.value = false;
			if (props.disabled) return;

			const file = event.dataTransfer?.files[0];
			if (file) processGpxFile(file);
		}

		function onFileSelect(event: Event) {
			if (props.disabled) return;

			const input = event.target as HTMLInputElement;
			const file = input.files?.[0];
			if (file) processGpxFile(file);
			input.value = '';
		}

		function clear() {
			if (props.disabled) return;
			fileName.value = null;
			error.value = null;
			emit('input', null);
		}

		onMounted(() => {
			initMap();
		});

		onBeforeUnmount(() => {
			if (map) {
				map.remove();
				map = null;
			}
		});

		watch(() => props.value, (newVal) => {
			displayGeometry(newVal);
		});

		return {
			mapContainer,
			fileInput,
			fileName,
			error,
			dragging,
			onDrop,
			onFileSelect,
			clear,
		};
	},
});
</script>

<style>
@import 'leaflet/dist/leaflet.css';
</style>

<style scoped>
.gpx-map-interface {
	width: 100%;
}

.map-container {
	width: 100%;
	height: 400px;
	border-radius: var(--theme--border-radius);
	border: var(--theme--border-width) solid var(--theme--form--field--input--border-color);
	overflow: hidden;
	z-index: 0;
}

.gpx-upload {
	display: flex;
	align-items: center;
	gap: 8px;
	margin-top: 8px;
}

.drop-zone {
	position: relative;
	flex: 1;
	display: flex;
	align-items: center;
	gap: 8px;
	padding: 12px 16px;
	border: 2px dashed var(--theme--form--field--input--border-color);
	border-radius: var(--theme--border-radius);
	color: var(--theme--foreground-subdued);
	cursor: pointer;
	transition: border-color 0.2s, background-color 0.2s;
}

.drop-zone:hover,
.drop-zone.dragging {
	border-color: var(--theme--primary);
	background-color: var(--theme--primary-background);
}

.file-input {
	position: absolute;
	inset: 0;
	opacity: 0;
	cursor: pointer;
}

.clear-button {
	flex-shrink: 0;
}

.error-notice {
	margin-top: 8px;
}
</style>
