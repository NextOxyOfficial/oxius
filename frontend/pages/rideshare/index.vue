<template>
  <PublicSection>
    <div class="min-h-screen py-8 bg-gradient-to-b from-gray-50 to-gray-100">
      <UContainer class="max-w-7xl">
        <div class="mb-6">
          <h1 class="text-2xl font-semibold text-gray-900">Ride Share</h1>
          <p class="text-sm text-gray-600 mt-2">
            Book a ride with live route preview, fare estimate, and future-ready realtime tracking.
          </p>
        </div>

        <div class="mb-6">
          <RideshareNav current="booking" />
        </div>

        <div
          v-if="activeRide"
          class="mb-6 rounded-xl border border-emerald-200 bg-emerald-50 px-4 py-4 flex flex-col md:flex-row md:items-center md:justify-between gap-4"
        >
          <div>
            <div class="text-sm font-semibold text-emerald-800">You already have an active ride</div>
            <div class="text-sm text-emerald-700 mt-1">
              Status: <span class="font-medium capitalize">{{ formatStatus(activeRide.status) }}</span>
            </div>
          </div>
          <UButton to="/rideshare/active" color="emerald">Go to Active Trip</UButton>
        </div>

        <div v-if="pageError" class="mb-6 rounded-xl border border-red-200 bg-red-50 px-4 py-3 text-sm text-red-700">
          {{ pageError }}
        </div>

        <div class="grid grid-cols-1 xl:grid-cols-5 gap-6">
          <div class="xl:col-span-2 space-y-6">
            <div class="bg-white border border-gray-200 rounded-xl shadow-sm overflow-hidden">
              <div class="px-5 py-4 border-b border-gray-100">
                <h2 class="text-lg font-semibold text-gray-900">Ride Booking</h2>
                <p class="text-sm text-gray-500 mt-1">Select pickup and drop, then request your ride.</p>
              </div>

              <div class="p-5 space-y-5">
                <div class="grid grid-cols-1 sm:grid-cols-2 gap-3">
                  <button
                    type="button"
                    class="rounded-xl border px-4 py-3 text-left transition-all"
                    :class="selectionTarget === 'pickup' ? 'border-emerald-500 bg-emerald-50' : 'border-gray-200 bg-white hover:bg-gray-50'"
                    @click="selectionTarget = 'pickup'"
                  >
                    <div class="text-xs font-semibold uppercase tracking-wide text-gray-500">Map click target</div>
                    <div class="mt-1 text-sm font-medium text-gray-900">Pickup Point</div>
                  </button>
                  <button
                    type="button"
                    class="rounded-xl border px-4 py-3 text-left transition-all"
                    :class="selectionTarget === 'drop' ? 'border-blue-500 bg-blue-50' : 'border-gray-200 bg-white hover:bg-gray-50'"
                    @click="selectionTarget = 'drop'"
                  >
                    <div class="text-xs font-semibold uppercase tracking-wide text-gray-500">Map click target</div>
                    <div class="mt-1 text-sm font-medium text-gray-900">Drop Point</div>
                  </button>
                </div>

                <div class="relative">
                  <label class="block text-sm font-medium text-gray-800 mb-2">Pickup Location</label>
                  <div class="flex gap-2">
                    <UInput
                      v-model="pickupQuery"
                      class="flex-1"
                      size="lg"
                      placeholder="Search pickup area"
                      @focus="searchTarget = 'pickup'"
                    />
                    <UButton
                      color="emerald"
                      variant="soft"
                      :loading="locatingPickup"
                      @click="useCurrentLocation"
                    >
                      Current
                    </UButton>
                  </div>
                  <div v-if="pickupPoint" class="mt-2 text-xs text-emerald-700 font-medium">
                    {{ pickupPoint.name }}
                  </div>
                  <div
                    v-if="searchTarget === 'pickup' && pickupSuggestions.length"
                    class="absolute z-20 mt-2 w-full rounded-xl border border-gray-200 bg-white shadow-sm overflow-hidden"
                  >
                    <button
                      v-for="item in pickupSuggestions"
                      :key="`${item.latitude}-${item.longitude}-${item.name}`"
                      type="button"
                      class="w-full px-4 py-3 text-left hover:bg-gray-50 border-b border-gray-100 last:border-b-0"
                      @click="selectSuggestion('pickup', item)"
                    >
                      <div class="text-sm font-medium text-gray-800">{{ item.name }}</div>
                      <div class="text-xs text-gray-500 mt-1">{{ formatAddress(item.address) }}</div>
                    </button>
                  </div>
                </div>

                <div class="relative">
                  <label class="block text-sm font-medium text-gray-800 mb-2">Drop Location</label>
                  <UInput
                    v-model="dropQuery"
                    size="lg"
                    placeholder="Search destination"
                    @focus="searchTarget = 'drop'"
                  />
                  <div v-if="dropPoint" class="mt-2 text-xs text-blue-700 font-medium">
                    {{ dropPoint.name }}
                  </div>
                  <div
                    v-if="searchTarget === 'drop' && dropSuggestions.length"
                    class="absolute z-20 mt-2 w-full rounded-xl border border-gray-200 bg-white shadow-sm overflow-hidden"
                  >
                    <button
                      v-for="item in dropSuggestions"
                      :key="`${item.latitude}-${item.longitude}-${item.name}`"
                      type="button"
                      class="w-full px-4 py-3 text-left hover:bg-gray-50 border-b border-gray-100 last:border-b-0"
                      @click="selectSuggestion('drop', item)"
                    >
                      <div class="text-sm font-medium text-gray-800">{{ item.name }}</div>
                      <div class="text-xs text-gray-500 mt-1">{{ formatAddress(item.address) }}</div>
                    </button>
                  </div>
                </div>

                <div>
                  <label class="block text-sm font-medium text-gray-800 mb-2">Vehicle Type</label>
                  <div class="grid grid-cols-3 gap-2">
                    <button
                      v-for="item in vehicleOptions"
                      :key="item.value"
                      type="button"
                      class="rounded-xl border px-3 py-3 text-sm font-medium transition-all"
                      :class="selectedVehicleType === item.value ? 'border-emerald-500 bg-emerald-50 text-emerald-700' : 'border-gray-200 bg-white text-gray-700 hover:bg-gray-50'"
                      @click="selectedVehicleType = item.value"
                    >
                      {{ item.label }}
                    </button>
                  </div>
                </div>

                <div class="flex flex-col sm:flex-row gap-3">
                  <UButton
                    color="emerald"
                    class="justify-center"
                    :loading="estimating"
                    :disabled="!canEstimate || Boolean(activeRide)"
                    @click="requestEstimate"
                  >
                    Get Fare Estimate
                  </UButton>
                  <UButton
                    color="primary"
                    variant="soft"
                    class="justify-center"
                    :loading="creatingRide"
                    :disabled="!estimateResult || Boolean(activeRide)"
                    @click="submitRideRequest"
                  >
                    Confirm Ride
                  </UButton>
                </div>
              </div>
            </div>

            <div class="bg-white border border-gray-200 rounded-xl shadow-sm overflow-hidden">
              <div class="px-5 py-4 border-b border-gray-100 flex items-center justify-between gap-4">
                <div>
                  <h2 class="text-lg font-semibold text-gray-900">Fare Summary</h2>
                  <p class="text-sm text-gray-500 mt-1">Your route estimate will appear here.</p>
                </div>
                <UBadge :color="estimateResult ? 'emerald' : 'gray'" variant="soft">
                  {{ estimateResult ? 'Ready' : 'Waiting' }}
                </UBadge>
              </div>
              <div class="p-5">
                <div v-if="estimateResult" class="grid grid-cols-1 sm:grid-cols-3 gap-3">
                  <div class="rounded-xl bg-gray-50 border border-gray-100 px-4 py-4">
                    <div class="text-xs uppercase tracking-wide text-gray-500 font-semibold">Distance</div>
                    <div class="mt-2 text-lg font-semibold text-gray-900">{{ estimateResult.distance_km }} km</div>
                  </div>
                  <div class="rounded-xl bg-gray-50 border border-gray-100 px-4 py-4">
                    <div class="text-xs uppercase tracking-wide text-gray-500 font-semibold">ETA</div>
                    <div class="mt-2 text-lg font-semibold text-gray-900">{{ formatEta(estimateResult.eta_seconds) }}</div>
                  </div>
                  <div class="rounded-xl bg-emerald-50 border border-emerald-100 px-4 py-4">
                    <div class="text-xs uppercase tracking-wide text-emerald-700 font-semibold">Estimated Fare</div>
                    <div class="mt-2 text-lg font-semibold text-emerald-800">৳{{ estimateResult.fare }}</div>
                  </div>
                </div>
                <div v-else class="rounded-xl border border-dashed border-gray-200 bg-gray-50 px-4 py-6 text-sm text-gray-500">
                  Select both points and request an estimate to preview distance, ETA, fare, and route geometry.
                </div>
              </div>
            </div>
          </div>

          <div class="xl:col-span-3 space-y-6">
            <div class="bg-white border border-gray-200 rounded-xl shadow-sm overflow-hidden">
              <div class="px-5 py-4 border-b border-gray-100 flex items-center justify-between gap-4">
                <div>
                  <h2 class="text-lg font-semibold text-gray-900">Live Route Preview</h2>
                  <p class="text-sm text-gray-500 mt-1">Tap anywhere on the map to set your currently selected point.</p>
                </div>
                <div class="text-xs text-gray-500">
                  Selected: <span class="font-semibold text-gray-800 capitalize">{{ selectionTarget }}</span>
                </div>
              </div>
              <div class="p-4">
                <ClientOnly>
                  <RideshareMap
                    :pickup="pickupPoint"
                    :drop="dropPoint"
                    :route-geometry="estimateResult?.route_geometry || null"
                    :active-selection="selectionTarget"
                    :loading="estimating"
                    @map-click="handleMapSelection"
                  />
                  <template #fallback>
                    <div class="h-[420px] rounded-xl border border-gray-200 bg-gray-50 flex items-center justify-center text-sm text-gray-500">
                      Loading map...
                    </div>
                  </template>
                </ClientOnly>
              </div>
            </div>

            <div class="bg-white border border-gray-200 rounded-xl shadow-sm overflow-hidden">
              <div class="px-5 py-4 border-b border-gray-100">
                <h2 class="text-lg font-semibold text-gray-900">Booking Tips</h2>
              </div>
              <div class="p-5 grid grid-cols-1 md:grid-cols-3 gap-4 text-sm text-gray-600">
                <div class="rounded-xl bg-gray-50 border border-gray-100 px-4 py-4">
                  <div class="font-semibold text-gray-800 mb-2">Use precise map pins</div>
                  <div>Tap map or search exact pickup and drop points for a cleaner route preview.</div>
                </div>
                <div class="rounded-xl bg-gray-50 border border-gray-100 px-4 py-4">
                  <div class="font-semibold text-gray-800 mb-2">Estimate before confirming</div>
                  <div>Fare, ETA, and route are fetched from the backend contract that will later serve Flutter too.</div>
                </div>
                <div class="rounded-xl bg-gray-50 border border-gray-100 px-4 py-4">
                  <div class="font-semibold text-gray-800 mb-2">Wallet-ready booking</div>
                  <div>Your wallet balance is checked before ride creation and again before ride completion.</div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </UContainer>
    </div>
  </PublicSection>
</template>

<script setup>
definePageMeta({
  layout: "dashboard",
});

const toast = useToast();
const router = useRouter();
const {
  normalizePoint,
  estimateRide,
  createRide,
  getActiveRide,
  searchLocations,
  reverseGeocode,
} = useRideshare();

const pickupQuery = ref("");
const dropQuery = ref("");
const pickupPoint = ref(null);
const dropPoint = ref(null);
const pickupSuggestions = ref([]);
const dropSuggestions = ref([]);
const searchTarget = ref(null);
const selectionTarget = ref("pickup");
const selectedVehicleType = ref("bike");
const estimating = ref(false);
const creatingRide = ref(false);
const locatingPickup = ref(false);
const pageError = ref("");
const estimateResult = ref(null);
const activeRide = ref(null);

const vehicleOptions = [
  { label: "Bike", value: "bike" },
  { label: "Car", value: "car" },
  { label: "CNG", value: "cng" },
];

const canEstimate = computed(() => {
  return pickupPoint.value && dropPoint.value;
});

const formatAddress = (address) => {
  if (!address || typeof address !== "object") {
    return "Tap to select this location";
  }

  return [
    address.road,
    address.suburb,
    address.city || address.town || address.state_district,
    address.country,
  ]
    .filter(Boolean)
    .slice(0, 3)
    .join(", ");
};

const formatEta = (seconds) => {
  const totalMinutes = Math.max(1, Math.round(Number(seconds || 0) / 60));
  if (totalMinutes < 60) {
    return `${totalMinutes} min`;
  }
  const hours = Math.floor(totalMinutes / 60);
  const minutes = totalMinutes % 60;
  return `${hours}h ${minutes}m`;
};

const formatStatus = (value) => {
  return String(value || "")
    .replaceAll("_", " ")
    .trim();
};

const runLocationSearch = async (target, query) => {
  if (!query || query.trim().length < 3) {
    if (target === "pickup") {
      pickupSuggestions.value = [];
    } else {
      dropSuggestions.value = [];
    }
    return;
  }

  const result = await searchLocations(query.trim(), 5);
  if (!result.success) {
    return;
  }

  const normalized = (result.data || []).map((item) => normalizePoint(item)).filter(Boolean);
  if (target === "pickup") {
    pickupSuggestions.value = normalized;
  } else {
    dropSuggestions.value = normalized;
  }
};

let pickupTimer = null;
let dropTimer = null;

watch(pickupQuery, (value) => {
  if (pickupTimer) {
    clearTimeout(pickupTimer);
  }
  pickupTimer = setTimeout(() => runLocationSearch("pickup", value), 350);
});

watch(dropQuery, (value) => {
  if (dropTimer) {
    clearTimeout(dropTimer);
  }
  dropTimer = setTimeout(() => runLocationSearch("drop", value), 350);
});

watch(selectedVehicleType, () => {
  if (canEstimate.value) {
    requestEstimate();
  }
});

const selectSuggestion = async (target, item) => {
  if (target === "pickup") {
    pickupPoint.value = item;
    pickupQuery.value = item.name;
    pickupSuggestions.value = [];
  } else {
    dropPoint.value = item;
    dropQuery.value = item.name;
    dropSuggestions.value = [];
  }
  searchTarget.value = null;

  if (canEstimate.value) {
    await requestEstimate();
  }
};

const handleMapSelection = async ({ latitude, longitude }) => {
  const target = selectionTarget.value;
  const result = await reverseGeocode(latitude, longitude);
  const normalized = normalizePoint(result.data || {
    name: `${latitude.toFixed(5)}, ${longitude.toFixed(5)}`,
    latitude,
    longitude,
  }) || {
    name: `${latitude.toFixed(5)}, ${longitude.toFixed(5)}`,
    latitude,
    longitude,
    address: {},
  };

  if (target === "pickup") {
    pickupPoint.value = normalized;
    pickupQuery.value = normalized.name;
    pickupSuggestions.value = [];
  } else {
    dropPoint.value = normalized;
    dropQuery.value = normalized.name;
    dropSuggestions.value = [];
  }

  if (canEstimate.value) {
    await requestEstimate();
  }
};

const useCurrentLocation = async () => {
  if (!navigator.geolocation) {
    toast.add({ title: "Location not supported", color: "red" });
    return;
  }

  locatingPickup.value = true;
  navigator.geolocation.getCurrentPosition(
    async (position) => {
      const latitude = position.coords.latitude;
      const longitude = position.coords.longitude;
      await handleMapSelection({ latitude, longitude });
      selectionTarget.value = "drop";
      locatingPickup.value = false;
    },
    () => {
      locatingPickup.value = false;
      toast.add({ title: "Unable to fetch current location", color: "red" });
    },
    {
      enableHighAccuracy: true,
      timeout: 10000,
      maximumAge: 0,
    }
  );
};

const requestEstimate = async () => {
  if (!pickupPoint.value || !dropPoint.value) {
    return;
  }

  estimating.value = true;
  pageError.value = "";

  const result = await estimateRide({
    pickup_latitude: pickupPoint.value.latitude,
    pickup_longitude: pickupPoint.value.longitude,
    drop_latitude: dropPoint.value.latitude,
    drop_longitude: dropPoint.value.longitude,
    pickup_address: pickupPoint.value.name,
    drop_address: dropPoint.value.name,
    vehicle_type: selectedVehicleType.value,
  });

  if (result.success) {
    estimateResult.value = result.data;
  } else {
    estimateResult.value = null;
    pageError.value = result.message;
  }

  estimating.value = false;
};

const submitRideRequest = async () => {
  if (!estimateResult.value || !pickupPoint.value || !dropPoint.value) {
    return;
  }

  creatingRide.value = true;
  pageError.value = "";

  const result = await createRide({
    pickup_latitude: pickupPoint.value.latitude,
    pickup_longitude: pickupPoint.value.longitude,
    drop_latitude: dropPoint.value.latitude,
    drop_longitude: dropPoint.value.longitude,
    pickup_address: pickupPoint.value.name,
    drop_address: dropPoint.value.name,
    vehicle_type: selectedVehicleType.value,
  });

  if (result.success) {
    toast.add({
      title: "Ride requested",
      description: result.message,
      color: "green",
    });
    await router.push("/rideshare/active");
  } else {
    pageError.value = result.message;
    toast.add({
      title: "Ride request failed",
      description: result.message,
      color: "red",
    });
  }

  creatingRide.value = false;
};

const loadActiveRide = async () => {
  const result = await getActiveRide();
  if (result.success && result.data) {
    activeRide.value = result.data;
  }
};

onMounted(() => {
  loadActiveRide();
});

onBeforeUnmount(() => {
  if (pickupTimer) {
    clearTimeout(pickupTimer);
  }
  if (dropTimer) {
    clearTimeout(dropTimer);
  }
});
</script>
