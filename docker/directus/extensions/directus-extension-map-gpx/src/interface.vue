<template>
	<div class="map-gpx-interface">
		<interface-map
			:value="value"
			:type="type"
			:field-data="fieldData"
			:loading="loading"
			:disabled="disabled"
			:geometry-type="geometryType"
			:default-view="defaultView"
			@input="$emit('input', $event)"
		/>

		<div v-if="!disabled" class="gpx-upload">
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
					type="file"
					accept=".gpx,application/gpx+xml"
					class="file-input"
					@change="onFileSelect"
					@click.stop
				/>
			</div>
		</div>

		<v-notice v-if="error" type="danger" class="error-notice">
			{{ error }}
		</v-notice>
	</div>
</template>

<script lang="ts">
import { defineComponent, ref, PropType } from 'vue';
import { gpx2geojson } from './gpx-parser';

export default defineComponent({
	props: {
		value: {
			type: [Object, Array, String] as PropType<Record<string, unknown> | unknown[] | string | null>,
			default: null,
		},
		type: {
			type: String as PropType<string>,
			default: 'geometry',
		},
		fieldData: {
			type: Object as PropType<Record<string, unknown>>,
			default: undefined,
		},
		loading: {
			type: Boolean,
			default: true,
		},
		disabled: {
			type: Boolean,
			default: false,
		},
		geometryType: {
			type: String as PropType<string>,
			default: undefined,
		},
		defaultView: {
			type: Object as PropType<Record<string, unknown>>,
			default: () => ({}),
		},
	},
	emits: ['input'],
	setup(props, { emit }) {
		const fileName = ref<string | null>(null);
		const error = ref<string | null>(null);
		const dragging = ref(false);

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
			const file = event.dataTransfer?.files[0];
			if (file) processGpxFile(file);
		}

		function onFileSelect(event: Event) {
			const input = event.target as HTMLInputElement;
			const file = input.files?.[0];
			if (file) processGpxFile(file);
			input.value = '';
		}

		return {
			fileName,
			error,
			dragging,
			onDrop,
			onFileSelect,
		};
	},
});
</script>

<style scoped>
.map-gpx-interface {
	width: 100%;
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

.error-notice {
	margin-top: 8px;
}
</style>
