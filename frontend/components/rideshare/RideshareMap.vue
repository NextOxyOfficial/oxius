<template>
  <div class="relative w-full overflow-hidden rounded-xl border border-gray-200 bg-gray-50">
    <div ref="mapElement" :style="{ height }" class="w-full"></div>

    <div class="absolute top-3 left-3 z-[500] space-y-2">
      <div class="rounded-lg bg-white/95 px-3 py-2 shadow-sm border border-gray-100 text-xs text-gray-700">
        <div class="font-semibold text-gray-800 mb-1">Map Selection</div>
        <div>Tap map to set <span class="font-semibold text-emerald-600">{{ activeSelection }}</span>.</div>
      </div>
    </div>

    <div v-if="loading" class="absolute inset-0 z-[600] bg-white/65 backdrop-blur-[1px] flex items-center justify-center">
      <div class="flex items-center gap-3 rounded-xl bg-white px-4 py-3 shadow-sm border border-gray-100 text-sm text-gray-700">
        <div class="w-5 h-5 border-2 border-emerald-500 border-t-transparent rounded-full animate-spin"></div>
        <span>Loading route...</span>
      </div>
    </div>
  </div>
</template>

<script setup>
import "leaflet/dist/leaflet.css";

const props = defineProps({
  pickup: {
    type: Object,
    default: null,
  },
  drop: {
    type: Object,
    default: null,
  },
  driverLocation: {
    type: Object,
    default: null,
  },
  routeGeometry: {
    type: Object,
    default: null,
  },
  height: {
    type: String,
    default: "420px",
  },
  activeSelection: {
    type: String,
    default: "pickup",
  },
  loading: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits(["map-click"]);

const mapElement = ref(null);
let map = null;
let tileLayer = null;
let featureLayer = null;
let leaflet = null;

const defaultCenter = [23.8103, 90.4125];

const getCoordinates = (point) => {
  if (!point) {
    return null;
  }

  const latitude = Number(point.latitude);
  const longitude = Number(point.longitude);
  if (Number.isNaN(latitude) || Number.isNaN(longitude)) {
    return null;
  }

  return [latitude, longitude];
};

const drawFeatures = () => {
  if (!map || !leaflet) {
    return;
  }

  if (featureLayer) {
    featureLayer.clearLayers();
  } else {
    featureLayer = leaflet.layerGroup().addTo(map);
  }

  const bounds = [];
  const pickupCoordinates = getCoordinates(props.pickup);
  const dropCoordinates = getCoordinates(props.drop);
  const driverCoordinates = getCoordinates(props.driverLocation);

  if (pickupCoordinates) {
    leaflet.circleMarker(pickupCoordinates, {
      radius: 8,
      color: "#059669",
      weight: 2,
      fillColor: "#10b981",
      fillOpacity: 0.95,
    }).bindTooltip(props.pickup?.name || "Pickup").addTo(featureLayer);
    bounds.push(pickupCoordinates);
  }

  if (dropCoordinates) {
    leaflet.circleMarker(dropCoordinates, {
      radius: 8,
      color: "#1d4ed8",
      weight: 2,
      fillColor: "#3b82f6",
      fillOpacity: 0.95,
    }).bindTooltip(props.drop?.name || "Drop").addTo(featureLayer);
    bounds.push(dropCoordinates);
  }

  if (driverCoordinates) {
    leaflet.circleMarker(driverCoordinates, {
      radius: 7,
      color: "#b45309",
      weight: 2,
      fillColor: "#f59e0b",
      fillOpacity: 0.95,
    }).bindTooltip(props.driverLocation?.name || "Driver").addTo(featureLayer);
    bounds.push(driverCoordinates);
  }

  const routeCoordinates = props.routeGeometry?.coordinates;
  if (Array.isArray(routeCoordinates) && routeCoordinates.length) {
    const normalizedRoute = routeCoordinates
      .map((item) => [Number(item[1]), Number(item[0])])
      .filter((item) => !Number.isNaN(item[0]) && !Number.isNaN(item[1]));

    if (normalizedRoute.length) {
      leaflet.polyline(normalizedRoute, {
        color: "#0f766e",
        weight: 5,
        opacity: 0.85,
      }).addTo(featureLayer);
      bounds.push(...normalizedRoute);
    }
  }

  if (bounds.length) {
    map.fitBounds(bounds, { padding: [30, 30] });
  } else {
    map.setView(defaultCenter, 12);
  }
};

const initializeMap = async () => {
  if (!process.client || !mapElement.value || map) {
    return;
  }

  leaflet = await import("leaflet");
  map = leaflet.map(mapElement.value, {
    zoomControl: true,
    attributionControl: true,
  }).setView(defaultCenter, 12);

  tileLayer = leaflet.tileLayer("https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png", {
    maxZoom: 19,
    attribution: '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors',
  });

  tileLayer.addTo(map);

  map.on("click", (event) => {
    emit("map-click", {
      latitude: event.latlng.lat,
      longitude: event.latlng.lng,
    });
  });

  drawFeatures();
};

watch(
  () => [props.pickup, props.drop, props.driverLocation, props.routeGeometry],
  () => {
    drawFeatures();
  },
  { deep: true }
);

onMounted(() => {
  initializeMap();
});

onBeforeUnmount(() => {
  if (map) {
    map.remove();
    map = null;
  }
  tileLayer = null;
  featureLayer = null;
});
</script>
