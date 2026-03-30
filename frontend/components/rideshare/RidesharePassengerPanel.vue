<template>
  <div class="space-y-5">
    <!-- Active Ride Section (Searching or In Progress) -->
    <div v-if="activeRide" class="space-y-4">
      <!-- Ride Status Card -->
      <div class="rounded-xl border border-slate-200/80 bg-white overflow-hidden shadow-xs">
        <!-- Header -->
        <div 
          class="px-4 py-3"
          :class="activeRide.status === 'searching_driver' ? 'bg-gradient-to-r from-indigo-500 to-violet-600' : 'bg-gradient-to-r from-emerald-500 to-teal-600'"
        >
          <div class="flex items-center justify-between">
            <div class="flex items-center gap-3">
              <div class="relative">
                <div class="flex h-10 w-10 items-center justify-center rounded-lg bg-white/20">
                  <UIcon 
                    :name="activeRide.status === 'searching_driver' ? 'i-heroicons-magnifying-glass' : 'i-heroicons-truck'" 
                    class="h-5 w-5 text-white" 
                  />
                </div>
                <div v-if="activeRide.status === 'searching_driver'" class="absolute -bottom-0.5 -right-0.5 h-3 w-3 rounded-full bg-white flex items-center justify-center">
                  <div class="h-1.5 w-1.5 rounded-full bg-indigo-500 animate-pulse"></div>
                </div>
              </div>
              <div>
                <div class="text-sm font-bold text-white">
                  {{ activeRide.status === 'searching_driver' ? $t("rideshare_finding_driver") : $t("rideshare_active_ride_alert") }}
                </div>
                <div class="text-[11px] text-white/80 capitalize">{{ formatStatus(activeRide.status) }}</div>
              </div>
            </div>
            <div class="flex h-8 w-8 items-center justify-center rounded-lg bg-white/20">
              <UIcon 
                :name="activeRide.requested_vehicle_type === 'bike' ? 'i-heroicons-truck' : activeRide.requested_vehicle_type === 'cng' ? 'i-heroicons-cube' : 'i-heroicons-truck'" 
                class="h-4 w-4 text-white" 
              />
            </div>
          </div>
        </div>
        
        <!-- Content -->
        <div class="p-4 space-y-3">
          <!-- Route Info -->
          <div class="flex items-start gap-2.5">
            <div class="flex flex-col items-center pt-0.5">
              <div class="h-2 w-2 rounded-full bg-indigo-500"></div>
              <div class="w-0.5 h-6 bg-slate-200 my-0.5"></div>
              <div class="h-2 w-2 rounded-full bg-violet-500"></div>
            </div>
            <div class="flex-1 space-y-2 min-w-0">
              <div>
                <div class="text-[9px] font-semibold uppercase tracking-wide text-slate-400">Pickup</div>
                <div class="text-xs font-medium text-slate-800 truncate">{{ activeRide.pickup_address }}</div>
              </div>
              <div>
                <div class="text-[9px] font-semibold uppercase tracking-wide text-slate-400">Drop</div>
                <div class="text-xs font-medium text-slate-800 truncate">{{ activeRide.drop_address }}</div>
              </div>
            </div>
          </div>
          
          <!-- Stats Row -->
          <div class="flex items-center divide-x divide-slate-200 rounded-lg bg-slate-50 py-2">
            <div class="flex-1 text-center px-2">
              <div class="text-[9px] font-semibold uppercase tracking-wide text-slate-400">Fare</div>
              <div class="text-xs font-bold" :class="activeRide.status === 'searching_driver' ? 'text-indigo-600' : 'text-emerald-600'">৳{{ activeRide.fare_estimate }}</div>
            </div>
            <div class="flex-1 text-center px-2">
              <div class="text-[9px] font-semibold uppercase tracking-wide text-slate-400">Distance</div>
              <div class="text-xs font-bold text-slate-800">{{ activeRide.distance_km }} km</div>
            </div>
            <div class="flex-1 text-center px-2">
              <div class="text-[9px] font-semibold uppercase tracking-wide text-slate-400">{{ activeRide.assigned_driver ? 'Driver' : 'Vehicle' }}</div>
              <div class="text-xs font-bold text-slate-800 capitalize">{{ activeRide.assigned_driver?.user?.name || activeRide.requested_vehicle_type }}</div>
            </div>
          </div>
          
          <!-- Actions -->
          <div class="flex gap-2">
            <button
              type="button"
              class="flex-1 inline-flex items-center justify-center gap-1.5 rounded-lg border border-red-200 bg-red-50 px-3 py-2 text-xs font-semibold text-red-600 transition-all hover:bg-red-100"
              :disabled="cancellingRide"
              @click="cancelActiveRide"
            >
              <span v-if="cancellingRide" class="h-3 w-3 animate-spin rounded-full border-2 border-red-600 border-t-transparent"></span>
              <UIcon v-else name="i-heroicons-x-mark" class="h-3.5 w-3.5" />
              {{ $t("rideshare_cancel_ride") }}
            </button>
          </div>
        </div>
      </div>
      
      <!-- Live Map -->
      <div class="rounded-xl border border-slate-200/80 bg-white overflow-hidden shadow-xs">
        <div class="px-3 py-2 border-b border-slate-100 bg-slate-50/50">
          <div class="flex items-center justify-between">
            <h3 class="text-xs font-bold text-slate-700">Live Map</h3>
            <span class="inline-flex items-center gap-1 text-[10px] font-medium text-emerald-600">
              <span class="h-1.5 w-1.5 rounded-full bg-emerald-500 animate-pulse"></span>
              Live
            </span>
          </div>
        </div>
        <div class="p-1.5">
          <ClientOnly>
            <RideshareMap
              :pickup="activeRidePickupPoint"
              :drop="activeRideDropPoint"
              :route-geometry="activeRide.route_geometry"
              active-selection="pickup"
              height="280px"
            />
            <template #fallback>
              <div class="h-[280px] rounded-lg border border-slate-200 bg-slate-50 flex items-center justify-center text-xs text-slate-400">
                Loading map...
              </div>
            </template>
          </ClientOnly>
        </div>
      </div>
    </div>

    <div v-if="userFacingError" class="rounded-xl border border-amber-200 bg-amber-50 px-4 py-3 text-sm text-amber-700">
      {{ userFacingError }}
    </div>

    <!-- Location Permission Required (only show if no active ride) -->
    <div
      v-if="!activeRide && !locationGranted && !locationLoading"
      class="rounded-2xl border border-amber-200 bg-gradient-to-r from-amber-50 to-orange-50 px-5 py-4 shadow-sm"
    >
      <div class="flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
        <div class="flex items-center gap-3">
          <div class="flex h-10 w-10 items-center justify-center rounded-xl bg-amber-100 text-amber-600">
            <UIcon name="i-heroicons-map-pin" class="h-5 w-5" />
          </div>
          <div>
            <div class="text-sm font-semibold text-amber-800">{{ $t("rideshare_location_required") }}</div>
            <div class="text-xs text-amber-600">{{ $t("rideshare_location_required_desc") }}</div>
          </div>
        </div>
        <button
          type="button"
          class="inline-flex items-center gap-2 rounded-xl bg-gradient-to-r from-amber-500 to-orange-500 px-4 py-2.5 text-sm font-semibold text-white shadow-sm transition-all hover:from-amber-600 hover:to-orange-600"
          :disabled="locationLoading"
          @click="requestLocationPermission"
        >
          <UIcon name="i-heroicons-map-pin" class="h-4 w-4" />
          {{ $t("rideshare_allow_location") }}
        </button>
      </div>
    </div>

    <!-- Booking Section - Hidden when active ride exists -->
    <div v-if="!activeRide" class="grid grid-cols-1 xl:grid-cols-5 gap-5">
      <!-- Booking Form -->
      <div class="order-1 xl:col-span-2 space-y-5">
        <div class="overflow-visible rounded-xl border border-slate-200/80 bg-white shadow-xs">
          <div class="border-b border-slate-100 bg-slate-50/50 px-5 py-4">
            <h2 class="text-base font-bold text-slate-800">{{ $t("rideshare_ride_booking") }}</h2>
            <p class="text-xs text-slate-500">{{ $t("rideshare_ride_booking_desc") }}</p>
          </div>

          <div class="space-y-4 p-5">
            <div class="relative flex gap-3">
              <div class="flex flex-col items-center py-3">
                <div class="h-3 w-3 flex-shrink-0 rounded-full bg-gradient-to-br from-indigo-500 to-violet-600"></div>
                <div class="my-1.5 w-0.5 flex-1 bg-slate-200"></div>
                <div class="h-3 w-3 flex-shrink-0 bg-gradient-to-br from-indigo-500 to-violet-600" style="clip-path: polygon(50% 100%, 0 0, 100% 0);"></div>
              </div>

              <div class="min-w-0 flex-1 space-y-3">
                <div ref="pickupSearchRef" class="relative">
                  <div
                    class="flex cursor-text items-center gap-2 rounded-xl border px-4 py-3 transition-all"
                    :class="searchTarget === 'pickup' ? 'border-indigo-400 bg-white ring-2 ring-indigo-100' : 'border-slate-200 bg-slate-50 hover:border-slate-300 hover:bg-white'"
                    @click="focusPickupInput"
                  >
                    <div class="min-w-0 flex-1">
                      <div class="mb-1 text-[10px] font-bold uppercase tracking-wider text-slate-400">
                        {{ $t("rideshare_pickup_location") }}
                      </div>
                      <input
                        ref="pickupInputEl"
                        v-model="pickupQuery"
                        type="text"
                        class="w-full bg-transparent text-sm font-medium text-slate-800 outline-none placeholder:font-normal placeholder:text-slate-400"
                        :placeholder="$t('rideshare_search_pickup')"
                        @focus="onPickupFocus"
                        @input="onPickupInput"
                      />
                    </div>
                    <button
                      type="button"
                      class="inline-flex h-8 flex-shrink-0 items-center justify-center gap-1.5 rounded-lg bg-gradient-to-r from-indigo-500 to-violet-600 px-3 text-xs font-semibold text-white transition-all hover:from-indigo-600 hover:to-violet-700"
                      :disabled="locatingPickup"
                      @click.stop="useCurrentLocation"
                    >
                      <template v-if="locatingPickup">
                        <div class="h-3.5 w-3.5 animate-spin rounded-full border-2 border-white border-t-transparent"></div>
                      </template>
                      <template v-else>
                        <UIcon name="i-heroicons-map-pin" class="h-3.5 w-3.5" />
                        <span>{{ $t("rideshare_current_location") }}</span>
                      </template>
                    </button>
                  </div>
                  <div
                    v-if="searchTarget === 'pickup' && pickupSuggestions.length"
                    class="absolute left-0 right-0 z-30 mt-1 max-h-48 overflow-y-auto rounded-lg border border-slate-200 bg-white shadow-xl"
                  >
                    <button
                      v-for="item in pickupSuggestions"
                      :key="`p-${item.latitude}-${item.longitude}`"
                      type="button"
                      class="flex w-full items-start gap-2 border-b border-slate-50 px-3 py-2 text-left transition-colors last:border-b-0 hover:bg-slate-50"
                      @click="selectSuggestion('pickup', item)"
                    >
                      <div class="mt-0.5 flex h-6 w-6 flex-shrink-0 items-center justify-center rounded-md bg-slate-100">
                        <UIcon name="i-heroicons-map-pin" class="h-3 w-3 text-slate-500" />
                      </div>
                      <div class="min-w-0 flex-1">
                        <div class="truncate text-xs font-medium text-slate-800">{{ item.name }}</div>
                        <div class="truncate text-[10px] text-slate-400">{{ formatAddress(item.address) }}</div>
                      </div>
                    </button>
                  </div>
                </div>

                <div ref="dropSearchRef" class="relative">
                  <div
                    class="flex cursor-text items-center gap-2 rounded-lg border px-3 py-2.5 transition-all"
                    :class="searchTarget === 'drop' ? 'border-indigo-400 bg-white ring-2 ring-indigo-100' : 'border-slate-200 bg-slate-50 hover:border-slate-300 hover:bg-white'"
                    @click="focusDropInput"
                  >
                    <div class="min-w-0 flex-1">
                      <div class="mb-0.5 text-[9px] font-bold uppercase tracking-wider text-slate-400">
                        {{ $t("rideshare_drop_location") }}
                      </div>
                      <input
                        ref="dropInputEl"
                        v-model="dropQuery"
                        type="text"
                        class="w-full bg-transparent text-xs font-medium text-slate-800 outline-none placeholder:font-normal placeholder:text-slate-400"
                        :placeholder="$t('rideshare_search_drop')"
                        @focus="onDropFocus"
                        @input="onDropInput"
                      />
                    </div>
                    <div v-if="searchingDrop" class="flex-shrink-0">
                      <div class="h-3.5 w-3.5 animate-spin rounded-full border-2 border-slate-400 border-t-transparent"></div>
                    </div>
                  </div>
                  <div
                    v-if="searchTarget === 'drop' && dropSuggestions.length"
                    class="absolute left-0 right-0 z-30 mt-1 max-h-48 overflow-y-auto rounded-lg border border-slate-200 bg-white shadow-xl"
                  >
                    <button
                      v-for="item in dropSuggestions"
                      :key="`d-${item.latitude}-${item.longitude}`"
                      type="button"
                      class="flex w-full items-start gap-2 border-b border-slate-50 px-3 py-2 text-left transition-colors last:border-b-0 hover:bg-slate-50"
                      @click="selectSuggestion('drop', item)"
                    >
                      <div class="mt-0.5 flex h-6 w-6 flex-shrink-0 items-center justify-center rounded-md bg-slate-100">
                        <UIcon name="i-heroicons-map-pin" class="h-3 w-3 text-slate-500" />
                      </div>
                      <div class="min-w-0 flex-1">
                        <div class="truncate text-xs font-medium text-slate-800">{{ item.name }}</div>
                        <div class="truncate text-[10px] text-slate-400">{{ formatAddress(item.address) }}</div>
                      </div>
                    </button>
                  </div>
                </div>
              </div>
            </div>

            <div>
              <label class="mb-1.5 block text-sm font-semibold uppercase tracking-wide text-slate-500">
                {{ $t("rideshare_vehicle_type") }}
              </label>
              <div class="grid grid-cols-3 gap-1.5">
                <button
                  v-for="item in vehicleOptions"
                  :key="item.value"
                  type="button"
                  class="rounded-lg border px-2 py-2 text-center transition-all"
                  :class="selectedVehicleType === item.value ? 'border-indigo-400 bg-gradient-to-r from-indigo-500 to-violet-600 text-white shadow-sm' : 'border-slate-200 bg-white text-slate-600 hover:border-slate-300 hover:bg-slate-50'"
                  @click="selectedVehicleType = item.value"
                >
                  <div class="text-2xl">{{ item.icon }}</div>
                  <div class="mt-0.5 text-sm font-semibold">{{ item.label }}</div>
                </button>
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- Map & Fare Combined -->
      <div class="order-2 xl:col-span-3">
        <div class="overflow-hidden rounded-2xl border border-slate-200/80 bg-white/90 backdrop-blur-sm shadow-sm">
          <!-- Map Header -->
          <div class="flex items-center justify-between gap-2 border-b border-slate-100 px-4 py-2.5">
            <div class="flex items-center gap-1.5">
              <UIcon name="i-heroicons-map" class="h-4 w-4 text-indigo-500" />
              <h2 class="text-sm font-bold text-slate-800">{{ $t("rideshare_live_map") }}</h2>
            </div>
            <div class="flex items-center gap-1 text-[10px]">
              <button
                type="button"
                class="flex items-center gap-1 rounded-md px-2.5 py-1 transition-all"
                :class="selectionTarget === 'pickup' ? 'bg-gradient-to-r from-indigo-500 to-violet-600 text-white' : 'bg-slate-100 text-slate-500 hover:bg-slate-200'"
                @click="selectionTarget = 'pickup'"
              >
                <span class="h-1.5 w-1.5 rounded-full bg-current"></span>
                <span class="font-semibold">Pickup</span>
              </button>
              <button
                type="button"
                class="flex items-center gap-1 rounded-md px-2.5 py-1 transition-all"
                :class="selectionTarget === 'drop' ? 'bg-gradient-to-r from-indigo-500 to-violet-600 text-white' : 'bg-slate-100 text-slate-500 hover:bg-slate-200'"
                @click="selectionTarget = 'drop'"
              >
                <span class="h-1.5 w-1.5 bg-current" style="clip-path: polygon(50% 100%, 0 0, 100% 0);"></span>
                <span class="font-semibold">Drop</span>
              </button>
            </div>
          </div>

          <!-- Map -->
          <div class="p-2">
            <ClientOnly>
              <RideshareMap
                :pickup="pickupPoint"
                :drop="dropPoint"
                :nearby-drivers="nearbyDrivers"
                :route-geometry="estimateResult?.route_geometry || null"
                :active-selection="selectionTarget"
                :loading="estimating || nearbyDriversLoading"
                height="min(45vh, 320px)"
                @map-click="handleMapSelection"
                @pickup-dragged="handlePickupDragged"
              />
              <template #fallback>
                <div class="flex h-[280px] items-center justify-center rounded-lg border border-slate-200 bg-slate-50 text-xs text-slate-400">
                  <UIcon name="i-heroicons-map" class="mr-1.5 h-5 w-5" /> Loading map...
                </div>
              </template>
            </ClientOnly>
          </div>

          <!-- Fare Summary (inside same card) -->
          <div v-if="showFareSection" class="border-t border-slate-100 p-3">
            <div v-if="estimating" class="flex items-center justify-center gap-2 py-3 text-xs text-slate-500">
              <div class="h-4 w-4 animate-spin rounded-full border-2 border-indigo-500 border-t-transparent"></div>
              <span>Calculating fare...</span>
            </div>

            <div v-else-if="estimateResult">
              <!-- Fare Stats Row -->
              <div class="flex items-center justify-between gap-2 mb-3">
                <div class="flex items-center gap-4 text-[11px]">
                  <div>
                    <span class="text-slate-400">Vehicle:</span>
                    <span class="ml-1 font-semibold text-slate-700">{{ selectedVehicleLabel }}</span>
                  </div>
                  <div>
                    <span class="text-slate-400">Distance:</span>
                    <span class="ml-1 font-semibold text-slate-700">{{ estimateResult.distance_km }} km</span>
                  </div>
                  <div>
                    <span class="text-slate-400">ETA:</span>
                    <span class="ml-1 font-semibold text-slate-700">{{ formatEta(estimateResult.eta_seconds) }}</span>
                  </div>
                </div>
                <div class="text-right">
                  <div class="text-[10px] text-slate-400">Estimated Fare</div>
                  <div class="text-lg font-bold text-indigo-600">৳{{ estimateResult.fare }}</div>
                </div>
              </div>

              <!-- Confirm Button -->
              <button
                type="button"
                class="w-full rounded-xl bg-gradient-to-r from-indigo-500 to-violet-600 px-4 py-3 text-sm font-semibold text-white shadow-md transition-all hover:from-indigo-600 hover:to-violet-700 disabled:opacity-50"
                :disabled="!estimateResult || Boolean(activeRide) || creatingRide"
                @click="submitRideRequest"
              >
                <span v-if="creatingRide" class="inline-flex items-center gap-2">
                  <span class="h-4 w-4 animate-spin rounded-full border-2 border-white border-t-transparent"></span>
                  Processing...
                </span>
                <span v-else>{{ $t("rideshare_confirm_ride") }} • ৳{{ estimateResult.fare }}</span>
              </button>
            </div>

            <div v-else class="py-3 text-center text-[11px] text-slate-400">
              Select pickup & drop locations to see fare estimate
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
const toast = useToast();
const router = useRouter();
const {
  normalizePoint,
  estimateRide,
  createRide,
  getActiveRide,
  cancelRide,
  searchLocations,
  reverseGeocode,
  getNearbyDrivers,
} = useRideshare();

const pickupQuery = ref("");
const dropQuery = ref("");
const pickupPoint = ref(null);
const dropPoint = ref(null);
const pickupSuggestions = ref([]);
const dropSuggestions = ref([]);
const nearbyDrivers = ref([]);
const nearbyDriversLoading = ref(false);
const searchTarget = ref(null);

// Location permission state
const locationGranted = ref(false);
const locationLoading = ref(false);

const checkLocationPermission = async () => {
  if (!navigator.permissions) {
    return;
  }
  try {
    const result = await navigator.permissions.query({ name: 'geolocation' });
    locationGranted.value = result.state === 'granted';
    result.onchange = () => {
      locationGranted.value = result.state === 'granted';
    };
  } catch (error) {
    console.error('Permission check failed:', error);
  }
};

const requestLocationPermission = async () => {
  if (!navigator.geolocation) {
    return;
  }
  locationLoading.value = true;
  navigator.geolocation.getCurrentPosition(
    () => {
      locationGranted.value = true;
      locationLoading.value = false;
    },
    () => {
      locationLoading.value = false;
    },
    { enableHighAccuracy: true, timeout: 10000 }
  );
};
const selectionTarget = ref("pickup");
const selectedVehicleType = ref("bike");
const estimating = ref(false);
const creatingRide = ref(false);
const cancellingRide = ref(false);
const locatingPickup = ref(false);
const searchingPickup = ref(false);
const searchingDrop = ref(false);
const rawError = ref("");
const estimateResult = ref(null);
const activeRide = ref(null);
const pickupSearchRef = ref(null);
const dropSearchRef = ref(null);
const pickupInputEl = ref(null);
const dropInputEl = ref(null);
let suppressPickupWatch = false;
let suppressDropWatch = false;
let pickupSearchRequestId = 0;
let dropSearchRequestId = 0;

const vehicleOptions = [
  { label: "Bike", value: "bike", icon: "🏍️" },
  { label: "Car", value: "car", icon: "🚗" },
  { label: "CNG", value: "cng", icon: "🛺" },
];

const canEstimate = computed(() => pickupPoint.value && dropPoint.value);
const showFareSection = computed(() => Boolean(selectedVehicleType.value && (pickupPoint.value || dropPoint.value)));
const selectedVehicleLabel = computed(() => vehicleOptions.find((item) => item.value === selectedVehicleType.value)?.label || "Vehicle");
const fareBadgeText = computed(() => {
  if (estimating.value) return "Connecting";
  if (estimateResult.value) return "Ready";
  return "Waiting";
});
const fareBadgeClass = computed(() => {
  if (estimating.value) return "bg-gray-900 text-white";
  if (estimateResult.value) return "bg-gray-200 text-gray-900";
  return "bg-gray-100 text-gray-500";
});
const userFacingError = computed(() => {
  if (!rawError.value) return "";
  return "We couldn’t complete that ride action right now. Please review the route and try again.";
});

// Active ride map points
const activeRidePickupPoint = computed(() => {
  if (!activeRide.value) return null;
  return {
    latitude: activeRide.value.pickup_latitude,
    longitude: activeRide.value.pickup_longitude,
    name: activeRide.value.pickup_address,
  };
});

const activeRideDropPoint = computed(() => {
  if (!activeRide.value) return null;
  return {
    latitude: activeRide.value.drop_latitude,
    longitude: activeRide.value.drop_longitude,
    name: activeRide.value.drop_address,
  };
});

const formatAddress = (address) => {
  if (!address || typeof address !== "object") {
    return "";
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

const formatStatus = (value) => String(value || "").replaceAll("_", " ").trim();

const focusPickupInput = () => {
  pickupInputEl.value?.focus();
};

const focusDropInput = () => {
  dropInputEl.value?.focus();
};

const onPickupFocus = () => {
  searchTarget.value = "pickup";
  selectionTarget.value = "pickup";
};

const onDropFocus = () => {
  searchTarget.value = "drop";
  selectionTarget.value = "drop";
};

const onPickupInput = () => {
  searchTarget.value = "pickup";
};

const onDropInput = () => {
  searchTarget.value = "drop";
};

const buildAddressName = (data) => {
  if (!data) return null;
  const addr = data.address || {};
  const parts = [
    addr.road,
    addr.neighbourhood || addr.suburb || addr.hamlet || addr.village,
    addr.city || addr.town || addr.state_district || addr.county,
  ].filter(Boolean);
  if (parts.length) return parts.slice(0, 3).join(", ");
  if (data.display_name) return data.display_name.split(",").slice(0, 3).join(",").trim();
  if (data.name) return data.name;
  return null;
};

const serializeCoordinate = (value) => Number(Number(value || 0).toFixed(6));

const searchCache = new Map();
const CACHE_TTL = 60000;
const MIN_SEARCH_LENGTH = 3;
const SEARCH_DEBOUNCE_MS = 120;

const getSuggestionSearchText = (item) => {
  return [item?.name, formatAddress(item?.address)]
    .filter(Boolean)
    .join(" ")
    .toLowerCase();
};

const getInstantSuggestions = (query) => {
  const trimmed = query.trim().toLowerCase();
  if (trimmed.length < MIN_SEARCH_LENGTH) {
    return [];
  }

  const matches = [];
  for (const [cachedQuery, cachedEntry] of searchCache.entries()) {
    if (!cachedEntry?.data?.length || Date.now() - cachedEntry.ts >= CACHE_TTL) {
      continue;
    }
    if (!trimmed.startsWith(cachedQuery) && !cachedQuery.startsWith(trimmed)) {
      continue;
    }
    for (const item of cachedEntry.data) {
      const searchText = getSuggestionSearchText(item);
      if (!searchText.includes(trimmed)) {
        continue;
      }
      if (matches.some((existing) => existing.latitude === item.latitude && existing.longitude === item.longitude)) {
        continue;
      }
      matches.push(item);
      if (matches.length >= 5) {
        return matches;
      }
    }
  }
  return matches;
};

const runLocationSearch = async (target, query, requestId) => {
  if (!query || query.trim().length < MIN_SEARCH_LENGTH) {
    if (target === "pickup") {
      pickupSuggestions.value = [];
      searchingPickup.value = false;
    } else {
      dropSuggestions.value = [];
      searchingDrop.value = false;
    }
    return;
  }

  const trimmed = query.trim().toLowerCase();
  if (target === "pickup" && pickupQuery.value.trim().toLowerCase() !== trimmed) {
    return;
  }
  if (target === "drop" && dropQuery.value.trim().toLowerCase() !== trimmed) {
    return;
  }

  const cacheKey = trimmed;
  const cached = searchCache.get(cacheKey);
  if (cached && Date.now() - cached.ts < CACHE_TTL) {
    if (target === "pickup" && requestId !== pickupSearchRequestId) {
      return;
    }
    if (target === "drop" && requestId !== dropSearchRequestId) {
      return;
    }
    if (target === "pickup") {
      pickupSuggestions.value = cached.data;
      searchingPickup.value = false;
    } else {
      dropSuggestions.value = cached.data;
      searchingDrop.value = false;
    }
    return;
  }

  if (target === "pickup") {
    searchingPickup.value = true;
  } else {
    searchingDrop.value = true;
  }

  const result = await searchLocations(query.trim(), 5);
  if (target === "pickup" && requestId !== pickupSearchRequestId) {
    return;
  }
  if (target === "drop" && requestId !== dropSearchRequestId) {
    return;
  }
  if (target === "pickup" && pickupQuery.value.trim().toLowerCase() !== trimmed) {
    return;
  }
  if (target === "drop" && dropQuery.value.trim().toLowerCase() !== trimmed) {
    return;
  }

  if (target === "pickup") {
    searchingPickup.value = false;
  } else {
    searchingDrop.value = false;
  }

  if (!result.success) {
    return;
  }

  const normalized = (result.data || []).map((item) => normalizePoint(item)).filter(Boolean);
  searchCache.set(cacheKey, { data: normalized, ts: Date.now() });

  if (target === "pickup") {
    pickupSuggestions.value = normalized;
  } else {
    dropSuggestions.value = normalized;
  }
};

let pickupTimer = null;
let dropTimer = null;

watch(pickupQuery, (value) => {
  if (pickupTimer) clearTimeout(pickupTimer);
  if (suppressPickupWatch) {
    pickupSearchRequestId += 1;
    suppressPickupWatch = false;
    return;
  }
  estimateResult.value = null;
  if (!value || value.trim().length < MIN_SEARCH_LENGTH) {
    pickupSearchRequestId += 1;
    pickupSuggestions.value = [];
    searchingPickup.value = false;
    return;
  }
  const instantSuggestions = getInstantSuggestions(value);
  if (instantSuggestions.length) {
    pickupSuggestions.value = instantSuggestions;
  }
  searchingPickup.value = true;
  pickupSearchRequestId += 1;
  const requestId = pickupSearchRequestId;
  pickupTimer = setTimeout(() => runLocationSearch("pickup", value, requestId), SEARCH_DEBOUNCE_MS);
});

watch(dropQuery, (value) => {
  if (dropTimer) clearTimeout(dropTimer);
  if (suppressDropWatch) {
    dropSearchRequestId += 1;
    suppressDropWatch = false;
    return;
  }
  estimateResult.value = null;
  if (!value || value.trim().length < MIN_SEARCH_LENGTH) {
    dropSearchRequestId += 1;
    dropSuggestions.value = [];
    searchingDrop.value = false;
    return;
  }
  const instantSuggestions = getInstantSuggestions(value);
  if (instantSuggestions.length) {
    dropSuggestions.value = instantSuggestions;
  }
  searchingDrop.value = true;
  dropSearchRequestId += 1;
  const requestId = dropSearchRequestId;
  dropTimer = setTimeout(() => runLocationSearch("drop", value, requestId), SEARCH_DEBOUNCE_MS);
});

watch(selectedVehicleType, async () => {
  estimateResult.value = null;
  if (canEstimate.value) {
    await requestEstimate();
  }
  await loadNearbyDrivers();
});

watch(
  () => pickupPoint.value,
  async () => {
    await loadNearbyDrivers();
  },
  { deep: true }
);

const selectSuggestion = async (target, item) => {
  rawError.value = "";
  if (target === "pickup") {
    pickupSearchRequestId += 1;
    pickupPoint.value = item;
    suppressPickupWatch = true;
    pickupQuery.value = item.name;
    pickupSuggestions.value = [];
    selectionTarget.value = "drop";
    searchTarget.value = null;
    nextTick(() => {
      dropInputEl.value?.focus();
    });
  } else {
    dropSearchRequestId += 1;
    dropPoint.value = item;
    suppressDropWatch = true;
    dropQuery.value = item.name;
    dropSuggestions.value = [];
    searchTarget.value = null;
  }

  if (canEstimate.value) {
    await requestEstimate();
  }
};

const resolveLocationName = async (latitude, longitude) => {
  const result = await reverseGeocode(latitude, longitude);
  const raw = result.data || {};
  const addressName = buildAddressName(raw);
  const name = addressName || raw.display_name || raw.name || "Selected location";
  return normalizePoint({ ...raw, name, latitude, longitude }) || {
    name,
    latitude,
    longitude,
    address: raw.address || {},
  };
};

const handleMapSelection = async ({ latitude, longitude }) => {
  rawError.value = "";
  const target = selectionTarget.value;
  const resolved = await resolveLocationName(latitude, longitude);

  if (target === "pickup") {
    pickupSearchRequestId += 1;
    pickupPoint.value = resolved;
    suppressPickupWatch = true;
    pickupQuery.value = resolved.name;
    pickupSuggestions.value = [];
    selectionTarget.value = "drop";
  } else {
    dropSearchRequestId += 1;
    dropPoint.value = resolved;
    suppressDropWatch = true;
    dropQuery.value = resolved.name;
    dropSuggestions.value = [];
  }
  searchTarget.value = null;

  if (canEstimate.value) {
    await requestEstimate();
  }
};

const handlePickupDragged = async ({ latitude, longitude }) => {
  rawError.value = "";
  const resolved = await resolveLocationName(latitude, longitude);
  pickupSearchRequestId += 1;
  pickupPoint.value = resolved;
  suppressPickupWatch = true;
  pickupQuery.value = resolved.name;
  pickupSuggestions.value = [];
  searchTarget.value = null;

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
  const prevTarget = selectionTarget.value;
  selectionTarget.value = "pickup";

  navigator.geolocation.getCurrentPosition(
    async (position) => {
      const latitude = position.coords.latitude;
      const longitude = position.coords.longitude;
      const resolved = await resolveLocationName(latitude, longitude);
      pickupSearchRequestId += 1;
      pickupPoint.value = resolved;
      suppressPickupWatch = true;
      pickupQuery.value = resolved.name;
      pickupSuggestions.value = [];
      searchTarget.value = null;
      selectionTarget.value = "drop";
      locatingPickup.value = false;

      if (canEstimate.value) {
        await requestEstimate();
      }
    },
    () => {
      locatingPickup.value = false;
      selectionTarget.value = prevTarget;
      toast.add({ title: "Unable to fetch current location", color: "red" });
    },
    {
      enableHighAccuracy: true,
      timeout: 10000,
      maximumAge: 0,
    }
  );
};

const loadNearbyDrivers = async () => {
  if (!pickupPoint.value) {
    nearbyDrivers.value = [];
    return;
  }
  nearbyDriversLoading.value = true;
  const result = await getNearbyDrivers(
    serializeCoordinate(pickupPoint.value.latitude),
    serializeCoordinate(pickupPoint.value.longitude),
    selectedVehicleType.value
  );
  if (result.success) {
    nearbyDrivers.value = result.data || [];
  } else {
    nearbyDrivers.value = [];
  }
  nearbyDriversLoading.value = false;
};

const requestEstimate = async () => {
  if (!pickupPoint.value || !dropPoint.value) {
    return;
  }

  estimating.value = true;
  rawError.value = "";

  const result = await estimateRide({
    pickup_latitude: serializeCoordinate(pickupPoint.value.latitude),
    pickup_longitude: serializeCoordinate(pickupPoint.value.longitude),
    drop_latitude: serializeCoordinate(dropPoint.value.latitude),
    drop_longitude: serializeCoordinate(dropPoint.value.longitude),
    pickup_address: pickupPoint.value.name,
    drop_address: dropPoint.value.name,
    vehicle_type: selectedVehicleType.value,
  });

  if (result.success) {
    estimateResult.value = result.data;
  } else {
    estimateResult.value = null;
    rawError.value = result.message;
  }

  estimating.value = false;
};

const submitRideRequest = async () => {
  if (!estimateResult.value || !pickupPoint.value || !dropPoint.value) {
    return;
  }

  creatingRide.value = true;
  rawError.value = "";

  const result = await createRide({
    pickup_latitude: serializeCoordinate(pickupPoint.value.latitude),
    pickup_longitude: serializeCoordinate(pickupPoint.value.longitude),
    drop_latitude: serializeCoordinate(dropPoint.value.latitude),
    drop_longitude: serializeCoordinate(dropPoint.value.longitude),
    pickup_address: pickupPoint.value.name,
    drop_address: dropPoint.value.name,
    vehicle_type: selectedVehicleType.value,
  });

  if (result.success) {
    toast.add({ title: "Ride requested", description: result.message, color: "gray" });
    await router.push("/rideshare/active");
  } else {
    rawError.value = result.message;
    toast.add({ title: "Ride request failed", description: "Please try again in a moment.", color: "red" });
  }

  creatingRide.value = false;
};

const loadActiveRide = async () => {
  const result = await getActiveRide();
  if (result.success && result.data) {
    activeRide.value = result.data;
  } else {
    activeRide.value = null;
  }
};

const cancelActiveRide = async () => {
  if (!activeRide.value) return;
  
  cancellingRide.value = true;
  const result = await cancelRide(activeRide.value.id, "Cancelled by passenger");
  
  if (result.success) {
    activeRide.value = null;
    toast.add({ title: "Ride cancelled", description: "Your ride has been cancelled.", color: "gray" });
  } else {
    toast.add({ title: "Cancel failed", description: result.message || "Please try again.", color: "red" });
  }
  
  cancellingRide.value = false;
};

const handleClickOutside = (event) => {
  const clickedInPickup = pickupSearchRef.value && pickupSearchRef.value.contains(event.target);
  const clickedInDrop = dropSearchRef.value && dropSearchRef.value.contains(event.target);

  if (!clickedInPickup && searchTarget.value === "pickup") {
    pickupSuggestions.value = [];
    searchTarget.value = null;
  }
  if (!clickedInDrop && searchTarget.value === "drop") {
    dropSuggestions.value = [];
    searchTarget.value = null;
  }
};

onMounted(() => {
  loadActiveRide();
  checkLocationPermission();
  document.addEventListener("click", handleClickOutside);
});

onBeforeUnmount(() => {
  if (pickupTimer) clearTimeout(pickupTimer);
  if (dropTimer) clearTimeout(dropTimer);
  document.removeEventListener("click", handleClickOutside);
});
</script>
