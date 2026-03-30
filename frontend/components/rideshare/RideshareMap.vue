<template>
  <div class="relative z-0 w-full overflow-hidden rounded-xl border border-gray-200 bg-gray-50">
    <div ref="mapElement" :style="{ height }" class="w-full relative z-0"></div>

    <div class="absolute top-3 left-3 z-10">
      <div class="rounded-lg bg-white/95 px-3 py-2 shadow-md border border-gray-100 text-xs text-gray-600 flex items-center gap-2">
        <span class="w-2 h-2 rounded-full" :class="activeSelection === 'pickup' ? 'bg-black' : 'bg-black'"></span>
        <span>Tap map to set <span class="font-bold text-gray-900 capitalize">{{ activeSelection }}</span></span>
      </div>
    </div>

    <div v-if="loading" class="absolute inset-0 z-20 bg-white/65 backdrop-blur-[1px] flex items-center justify-center">
      <div class="flex items-center gap-3 rounded-xl bg-white px-4 py-3 shadow-sm border border-gray-100 text-sm text-gray-700">
        <div class="w-5 h-5 border-2 border-gray-800 border-t-transparent rounded-full animate-spin"></div>
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
  nearbyDrivers: {
    type: Array,
    default: () => [],
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

const emit = defineEmits(["map-click", "pickup-dragged"]);

const mapElement = ref(null);
let map = null;
let tileLayer = null;
let featureLayer = null;
let leaflet = null;
let pickupMarkerRef = null;

const defaultCenter = [23.8103, 90.4125];

const pickupIconSvg = `<svg xmlns="http://www.w3.org/2000/svg" width="28" height="28" viewBox="0 0 28 28"><circle cx="14" cy="14" r="10" fill="#111" stroke="#fff" stroke-width="3"/><circle cx="14" cy="14" r="4" fill="#fff"/></svg>`;

const dropIconSvg = `<svg xmlns="http://www.w3.org/2000/svg" width="28" height="40" viewBox="0 0 28 40"><path d="M14 0C6.268 0 0 6.268 0 14c0 10.5 14 26 14 26s14-15.5 14-26C28 6.268 21.732 0 14 0z" fill="#111" stroke="#fff" stroke-width="1.5"/><rect x="8" y="8" width="12" height="12" rx="2" fill="#fff"/></svg>`;

const driverIconSvg = `<svg xmlns="http://www.w3.org/2000/svg" width="32" height="32" viewBox="0 0 32 32"><circle cx="16" cy="16" r="14" fill="#111" stroke="#fff" stroke-width="2"/><path d="M10 20l6-12 6 12H10z" fill="#fff"/></svg>`;

const nearbyDriverIconSvg = `<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24"><circle cx="12" cy="12" r="10" fill="#374151" stroke="#fff" stroke-width="2"/><path d="M8 15l4-8 4 8H8z" fill="#fff"/></svg>`;

// Vehicle type specific icons for live drivers
const bikeIconSvg = `<svg xmlns="http://www.w3.org/2000/svg" width="32" height="32" viewBox="0 0 32 32"><circle cx="16" cy="16" r="14" fill="#6366f1" stroke="#fff" stroke-width="2"/><path d="M10 20c0-2.2 1.8-4 4-4h4c2.2 0 4 1.8 4 4" stroke="#fff" stroke-width="2" fill="none"/><circle cx="12" cy="20" r="2" fill="#fff"/><circle cx="20" cy="20" r="2" fill="#fff"/><path d="M14 12h4l2 4h-8l2-4z" fill="#fff"/></svg>`;

const carIconSvg = `<svg xmlns="http://www.w3.org/2000/svg" width="32" height="32" viewBox="0 0 32 32"><circle cx="16" cy="16" r="14" fill="#8b5cf6" stroke="#fff" stroke-width="2"/><rect x="8" y="12" width="16" height="8" rx="2" fill="#fff"/><circle cx="11" cy="20" r="2" fill="#fff" stroke="#8b5cf6"/><circle cx="21" cy="20" r="2" fill="#fff" stroke="#8b5cf6"/><path d="M10 12l2-4h8l2 4" fill="#fff"/></svg>`;

const cngIconSvg = `<svg xmlns="http://www.w3.org/2000/svg" width="32" height="32" viewBox="0 0 32 32"><circle cx="16" cy="16" r="14" fill="#10b981" stroke="#fff" stroke-width="2"/><path d="M8 18h16l-2 4H10l-2-4z" fill="#fff"/><path d="M10 18l2-6h8l2 6" fill="#fff"/><circle cx="12" cy="22" r="2" fill="#fff" stroke="#10b981"/><circle cx="20" cy="22" r="2" fill="#fff" stroke="#10b981"/></svg>`;

const getDriverIcon = (vehicleType) => {
  switch (vehicleType) {
    case 'bike':
      return bikeIconSvg;
    case 'car':
      return carIconSvg;
    case 'cng':
      return cngIconSvg;
    default:
      return nearbyDriverIconSvg;
  }
};

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

const createIcon = (svgHtml, size, anchor) => {
  return leaflet.divIcon({
    html: svgHtml,
    className: "rideshare-marker",
    iconSize: size,
    iconAnchor: anchor,
  });
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
  pickupMarkerRef = null;

  const bounds = [];
  const pickupCoordinates = getCoordinates(props.pickup);
  const dropCoordinates = getCoordinates(props.drop);
  const driverCoordinates = getCoordinates(props.driverLocation);

  if (pickupCoordinates) {
    const pickupIcon = createIcon(pickupIconSvg, [28, 28], [14, 14]);
    const pickupMarker = leaflet.marker(pickupCoordinates, {
      icon: pickupIcon,
      draggable: true,
      zIndexOffset: 1000,
    }).bindTooltip(props.pickup?.name || "Pickup", { direction: "top", offset: [0, -14] }).addTo(featureLayer);

    pickupMarker.on("dragend", (e) => {
      const pos = e.target.getLatLng();
      emit("pickup-dragged", { latitude: pos.lat, longitude: pos.lng });
    });
    pickupMarkerRef = pickupMarker;
    bounds.push(pickupCoordinates);
  }

  if (dropCoordinates) {
    const dropIcon = createIcon(dropIconSvg, [28, 40], [14, 40]);
    leaflet.marker(dropCoordinates, {
      icon: dropIcon,
      zIndexOffset: 900,
    }).bindTooltip(props.drop?.name || "Drop", { direction: "top", offset: [0, -40] }).addTo(featureLayer);
    bounds.push(dropCoordinates);
  }

  if (driverCoordinates) {
    const driverIcon = createIcon(driverIconSvg, [32, 32], [16, 16]);
    leaflet.marker(driverCoordinates, {
      icon: driverIcon,
      zIndexOffset: 800,
    }).bindTooltip(props.driverLocation?.name || "Driver", { direction: "top", offset: [0, -16] }).addTo(featureLayer);
    bounds.push(driverCoordinates);
  }

  // Add nearby drivers with vehicle type icons
  if (Array.isArray(props.nearbyDrivers) && props.nearbyDrivers.length > 0) {
    props.nearbyDrivers.forEach((driver) => {
      const coords = getCoordinates(driver);
      if (coords) {
        const vehicleType = driver.vehicle_type || driver.vehicleType || 'bike';
        const iconSvg = getDriverIcon(vehicleType);
        const driverIcon = createIcon(iconSvg, [32, 32], [16, 16]);
        const tooltipText = `${driver.name || 'Driver'} • ${vehicleType.toUpperCase()}`;
        leaflet.marker(coords, {
          icon: driverIcon,
          zIndexOffset: 700,
        }).bindTooltip(tooltipText, { direction: "top", offset: [0, -16] }).addTo(featureLayer);
      }
    });
  }

  const routeCoordinates = props.routeGeometry?.coordinates;
  if (Array.isArray(routeCoordinates) && routeCoordinates.length) {
    const normalizedRoute = routeCoordinates
      .map((item) => [Number(item[1]), Number(item[0])])
      .filter((item) => !Number.isNaN(item[0]) && !Number.isNaN(item[1]));

    if (normalizedRoute.length) {
      leaflet.polyline(normalizedRoute, {
        color: "#111",
        weight: 4,
        opacity: 0.8,
      }).addTo(featureLayer);
      bounds.push(...normalizedRoute);
    }
  }

  if (bounds.length) {
    map.fitBounds(bounds, { padding: [40, 40] });
  } else {
    map.setView(defaultCenter, 12);
  }
};

const initializeMap = async () => {
  if (!process.client || map) {
    return;
  }

  // Wait for DOM to be ready
  await nextTick();
  
  if (!mapElement.value) {
    console.warn('Map element not found, retrying...');
    setTimeout(initializeMap, 100);
    return;
  }

  try {
    leaflet = await import("leaflet");
    map = leaflet.map(mapElement.value, {
      zoomControl: true,
      attributionControl: true,
    }).setView(defaultCenter, 12);
  } catch (error) {
    console.error('Failed to initialize map:', error);
    return;
  }

  // Use CartoDB tile server - more reliable for production
  tileLayer = leaflet.tileLayer("https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png", {
    maxZoom: 19,
    attribution: '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors &copy; <a href="https://carto.com/attributions">CARTO</a>',
    subdomains: 'abcd',
  });

  tileLayer.addTo(map);

  map.on("click", (event) => {
    emit("map-click", {
      latitude: event.latlng.lat,
      longitude: event.latlng.lng,
    });
  });

  // Wait for map to be fully loaded before drawing features
  map.whenReady(() => {
    drawFeatures();
  });
};

watch(
  () => [props.pickup, props.drop, props.driverLocation, props.nearbyDrivers, props.routeGeometry],
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
  pickupMarkerRef = null;
});
</script>

<style>
.rideshare-marker {
  background: transparent !important;
  border: none !important;
}

.leaflet-container,
.leaflet-pane,
.leaflet-top,
.leaflet-bottom,
.leaflet-control {
  z-index: 1 !important;
}
</style>
