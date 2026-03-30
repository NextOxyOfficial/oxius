<template>
  <div class="space-y-5">
    <div
      v-if="activeRide"
      class="rounded-2xl border border-gray-800 bg-gray-950 px-4 py-3 text-white shadow-sm"
    >
      <div class="flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
        <div class="flex items-center gap-3">
          <div class="flex h-9 w-9 items-center justify-center rounded-full bg-white/10">
            <UIcon name="i-heroicons-arrow-path" class="h-4 w-4 animate-spin text-gray-100" />
          </div>
          <div>
            <div class="text-sm font-semibold">{{ $t("rideshare_active_ride_alert") }}</div>
            <div class="mt-0.5 text-xs text-gray-300 capitalize">{{ formatStatus(activeRide.status) }}</div>
          </div>
        </div>
        <UButton to="/rideshare/active" color="gray" variant="solid" size="sm">
          {{ $t("rideshare_go_active_trip") }}
        </UButton>
      </div>
    </div>

    <div v-if="userFacingError" class="rounded-2xl border border-gray-300 bg-white px-4 py-3 text-sm text-gray-700 shadow-sm">
      {{ userFacingError }}
    </div>

    <div class="grid grid-cols-1 xl:grid-cols-5 gap-5">
      <div class="order-1 xl:col-span-2 space-y-5">
        <div class="overflow-visible rounded-2xl border border-gray-200 bg-white shadow-sm">
          <div class="border-b border-gray-200 bg-gray-50 px-4 py-4">
            <h2 class="text-base font-bold text-gray-950">{{ $t("rideshare_ride_booking") }}</h2>
            <p class="mt-0.5 text-xs text-gray-500">{{ $t("rideshare_ride_booking_desc") }}</p>
          </div>

          <div class="space-y-4 p-4 sm:p-5">
            <div class="relative flex gap-3">
              <div class="flex flex-col items-center pb-3 pt-3">
                <div class="h-3 w-3 flex-shrink-0 rounded-full border-2 border-gray-900 bg-gray-900"></div>
                <div class="my-1 w-0.5 flex-1 bg-gray-300"></div>
                <div class="h-3 w-3 flex-shrink-0 bg-gray-900" style="clip-path: polygon(50% 100%, 0 0, 100% 0);"></div>
              </div>

              <div class="min-w-0 flex-1 space-y-2">
                <div ref="pickupSearchRef" class="relative">
                  <div
                    class="flex cursor-text items-center gap-2 rounded-xl border px-3 py-3 transition-all"
                    :class="searchTarget === 'pickup' ? 'border-gray-900 bg-white ring-1 ring-gray-900/10' : 'border-gray-200 bg-gray-50 hover:border-gray-300 hover:bg-white'"
                    @click="focusPickupInput"
                  >
                    <div class="min-w-0 flex-1">
                      <div class="mb-0.5 text-[10px] font-bold uppercase tracking-wider text-gray-400">
                        {{ $t("rideshare_pickup_location") }}
                      </div>
                      <input
                        ref="pickupInputEl"
                        v-model="pickupQuery"
                        type="text"
                        class="w-full bg-transparent text-sm font-medium text-gray-950 outline-none placeholder:font-normal placeholder:text-gray-400"
                        :placeholder="$t('rideshare_search_pickup')"
                        @focus="onPickupFocus"
                        @input="onPickupInput"
                      />
                    </div>
                    <button
                      type="button"
                      class="inline-flex h-9 flex-shrink-0 items-center justify-center gap-1.5 rounded-full bg-gray-900 px-3 text-[11px] font-semibold text-white transition-colors hover:bg-gray-800"
                      :disabled="locatingPickup"
                      :class="locatingPickup ? 'cursor-wait bg-gray-700 text-gray-100' : ''"
                      @click.stop="useCurrentLocation"
                    >
                      <template v-if="locatingPickup">
                        <div class="h-3.5 w-3.5 animate-spin rounded-full border-2 border-white border-t-transparent"></div>
                        <span>{{ $t("rideshare_selecting") }}</span>
                      </template>
                      <template v-else>
                        <UIcon name="i-heroicons-map-pin" class="h-4 w-4 text-white" />
                        <span>{{ $t("rideshare_current_location") }}</span>
                      </template>
                    </button>
                  </div>
                  <div
                    v-if="searchTarget === 'pickup' && pickupSuggestions.length"
                    class="absolute left-0 right-0 z-30 mt-1 max-h-60 overflow-y-auto overflow-hidden rounded-xl border border-gray-200 bg-white shadow-2xl"
                  >
                    <button
                      v-for="item in pickupSuggestions"
                      :key="`p-${item.latitude}-${item.longitude}`"
                      type="button"
                      class="flex w-full items-start gap-2.5 border-b border-gray-50 px-3 py-2.5 text-left transition-colors last:border-b-0 hover:bg-gray-50"
                      @click="selectSuggestion('pickup', item)"
                    >
                      <div class="mt-0.5 flex h-8 w-8 flex-shrink-0 items-center justify-center rounded-full bg-gray-100">
                        <UIcon name="i-heroicons-map-pin" class="h-4 w-4 text-gray-600" />
                      </div>
                      <div class="min-w-0 flex-1">
                        <div class="truncate text-sm font-medium text-gray-900">{{ item.name }}</div>
                        <div class="mt-0.5 truncate text-xs text-gray-400">{{ formatAddress(item.address) }}</div>
                      </div>
                    </button>
                  </div>
                </div>

                <div ref="dropSearchRef" class="relative">
                  <div
                    class="flex cursor-text items-center gap-2 rounded-xl border px-3 py-3 transition-all"
                    :class="searchTarget === 'drop' ? 'border-gray-900 bg-white ring-1 ring-gray-900/10' : 'border-gray-200 bg-gray-50 hover:border-gray-300 hover:bg-white'"
                    @click="focusDropInput"
                  >
                    <div class="min-w-0 flex-1">
                      <div class="mb-0.5 text-[10px] font-bold uppercase tracking-wider text-gray-400">
                        {{ $t("rideshare_drop_location") }}
                      </div>
                      <input
                        ref="dropInputEl"
                        v-model="dropQuery"
                        type="text"
                        class="w-full bg-transparent text-sm font-medium text-gray-950 outline-none placeholder:font-normal placeholder:text-gray-400"
                        :placeholder="$t('rideshare_search_drop')"
                        @focus="onDropFocus"
                        @input="onDropInput"
                      />
                    </div>
                    <div v-if="searchingDrop" class="flex-shrink-0">
                      <div class="h-4 w-4 animate-spin rounded-full border-2 border-gray-400 border-t-transparent"></div>
                    </div>
                  </div>
                  <div
                    v-if="searchTarget === 'drop' && dropSuggestions.length"
                    class="absolute left-0 right-0 z-30 mt-1 max-h-60 overflow-y-auto overflow-hidden rounded-xl border border-gray-200 bg-white shadow-2xl"
                  >
                    <button
                      v-for="item in dropSuggestions"
                      :key="`d-${item.latitude}-${item.longitude}`"
                      type="button"
                      class="flex w-full items-start gap-2.5 border-b border-gray-50 px-3 py-2.5 text-left transition-colors last:border-b-0 hover:bg-gray-50"
                      @click="selectSuggestion('drop', item)"
                    >
                      <div class="mt-0.5 flex h-8 w-8 flex-shrink-0 items-center justify-center rounded-full bg-gray-100">
                        <UIcon name="i-heroicons-map-pin" class="h-4 w-4 text-gray-600" />
                      </div>
                      <div class="min-w-0 flex-1">
                        <div class="truncate text-sm font-medium text-gray-900">{{ item.name }}</div>
                        <div class="mt-0.5 truncate text-xs text-gray-400">{{ formatAddress(item.address) }}</div>
                      </div>
                    </button>
                  </div>
                </div>
              </div>
            </div>

            <div>
              <label class="mb-2 block text-xs font-semibold uppercase tracking-wide text-gray-600">
                {{ $t("rideshare_vehicle_type") }}
              </label>
              <div class="grid grid-cols-3 gap-2">
                <button
                  v-for="item in vehicleOptions"
                  :key="item.value"
                  type="button"
                  class="rounded-xl border px-2 py-3 text-center transition-all"
                  :class="selectedVehicleType === item.value ? 'border-gray-950 bg-gray-950 text-white shadow-sm' : 'border-gray-200 bg-white text-gray-700 hover:border-gray-300 hover:bg-gray-50'"
                  @click="selectedVehicleType = item.value"
                >
                  <div class="text-lg">{{ item.icon }}</div>
                  <div class="mt-1 text-xs font-semibold">{{ item.label }}</div>
                </button>
              </div>
            </div>

            <div class="rounded-2xl border border-gray-200 bg-gray-50 px-4 py-3 text-xs text-gray-600">
              <div class="font-semibold uppercase tracking-wide text-gray-500">Flow</div>
              <div class="mt-1">
                Select pickup, drop, and vehicle. Fare will appear automatically below.
              </div>
            </div>
          </div>
        </div>
      </div>

      <div class="order-2 xl:col-span-3 space-y-5">
        <div class="overflow-hidden rounded-2xl border border-gray-200 bg-white shadow-sm">
          <div class="flex items-center justify-between gap-3 border-b border-gray-200 px-4 py-3">
            <div class="flex items-center gap-2">
              <UIcon name="i-heroicons-map" class="h-4 w-4 text-gray-700" />
              <h2 class="text-sm font-bold text-gray-950">{{ $t("rideshare_live_map") }}</h2>
            </div>
            <div class="flex items-center gap-2 text-[10px]">
              <button
                type="button"
                class="flex items-center gap-1.5 rounded-full px-2.5 py-1 transition-all"
                :class="selectionTarget === 'pickup' ? 'bg-gray-950 text-white' : 'bg-gray-100 text-gray-500 hover:bg-gray-200'"
                @click="selectionTarget = 'pickup'"
              >
                <span class="h-1.5 w-1.5 rounded-full bg-current"></span>
                <span class="font-semibold">Pickup</span>
              </button>
              <button
                type="button"
                class="flex items-center gap-1.5 rounded-full px-2.5 py-1 transition-all"
                :class="selectionTarget === 'drop' ? 'bg-gray-950 text-white' : 'bg-gray-100 text-gray-500 hover:bg-gray-200'"
                @click="selectionTarget = 'drop'"
              >
                <span class="h-1.5 w-1.5 bg-current" style="clip-path: polygon(50% 100%, 0 0, 100% 0);"></span>
                <span class="font-semibold">Drop</span>
              </button>
            </div>
          </div>
          <div class="p-2 sm:p-3">
            <ClientOnly>
              <RideshareMap
                :pickup="pickupPoint"
                :drop="dropPoint"
                :nearby-drivers="nearbyDrivers"
                :route-geometry="estimateResult?.route_geometry || null"
                :active-selection="selectionTarget"
                :loading="estimating || nearbyDriversLoading"
                height="min(54vh, 420px)"
                @map-click="handleMapSelection"
                @pickup-dragged="handlePickupDragged"
              />
              <template #fallback>
                <div class="flex h-[320px] items-center justify-center rounded-xl border border-gray-200 bg-gray-50 text-sm text-gray-400">
                  <UIcon name="i-heroicons-map" class="mr-2 h-6 w-6" /> Loading map...
                </div>
              </template>
            </ClientOnly>
          </div>
        </div>

        <div
          v-if="showFareSection"
          class="overflow-hidden rounded-2xl border border-gray-200 bg-white shadow-sm"
        >
          <div class="flex items-center justify-between gap-3 border-b border-gray-200 bg-gray-50 px-4 py-3">
            <div>
              <h2 class="text-sm font-bold text-gray-950">{{ $t("rideshare_fare_summary") }}</h2>
              <p class="mt-0.5 text-[11px] text-gray-500">Automatic estimate based on your route and selected vehicle.</p>
            </div>
            <span class="rounded-full px-2.5 py-1 text-[11px] font-semibold"
              :class="fareBadgeClass"
            >
              {{ fareBadgeText }}
            </span>
          </div>
          <div class="space-y-4 p-4">
            <div class="grid grid-cols-1 gap-3 sm:grid-cols-4">
              <div class="rounded-xl border border-gray-200 bg-gray-50 px-3 py-3">
                <div class="text-[10px] font-semibold uppercase tracking-wide text-gray-500">Vehicle</div>
                <div class="mt-1 text-sm font-bold text-gray-950">{{ selectedVehicleLabel }}</div>
              </div>
              <div class="rounded-xl border border-gray-200 bg-gray-50 px-3 py-3">
                <div class="text-[10px] font-semibold uppercase tracking-wide text-gray-500">Distance</div>
                <div class="mt-1 text-sm font-bold text-gray-950">{{ estimateResult?.distance_km || '--' }} km</div>
              </div>
              <div class="rounded-xl border border-gray-200 bg-gray-50 px-3 py-3">
                <div class="text-[10px] font-semibold uppercase tracking-wide text-gray-500">ETA</div>
                <div class="mt-1 text-sm font-bold text-gray-950">{{ estimateResult ? formatEta(estimateResult.eta_seconds) : '--' }}</div>
              </div>
              <div class="rounded-xl border border-gray-950 bg-gray-950 px-3 py-3 text-white">
                <div class="text-[10px] font-semibold uppercase tracking-wide text-gray-300">Fare</div>
                <div class="mt-1 text-sm font-bold">৳{{ estimateResult?.fare || '--' }}</div>
              </div>
            </div>

            <div v-if="estimating" class="rounded-xl border border-gray-200 bg-gray-50 px-4 py-4 text-sm text-gray-600">
              <div class="flex items-center gap-2">
                <div class="h-4 w-4 animate-spin rounded-full border-2 border-gray-500 border-t-transparent"></div>
                <span>Connecting route and fare estimate...</span>
              </div>
            </div>

            <div v-else-if="estimateResult" class="space-y-3">
              <div class="rounded-xl border border-gray-200 bg-gray-50 px-4 py-3 text-sm text-gray-700">
                <div class="font-semibold text-gray-950">Ready to confirm</div>
                <div class="mt-1 text-xs text-gray-500">
                  {{ pickupPoint?.name }} → {{ dropPoint?.name }}
                </div>
              </div>
              <UButton
                color="gray"
                block
                :loading="creatingRide"
                :disabled="!estimateResult || Boolean(activeRide)"
                @click="submitRideRequest"
              >
                {{ $t("rideshare_confirm_ride") }}
              </UButton>
            </div>

            <div v-else class="rounded-xl border border-dashed border-gray-200 bg-gray-50 px-4 py-5 text-center text-xs text-gray-500">
              Complete both locations to see your fare summary automatically.
            </div>
          </div>
        </div>

        <div class="overflow-hidden rounded-2xl border border-gray-200 bg-white shadow-sm">
          <div class="border-b border-gray-200 px-4 py-3">
            <h2 class="text-sm font-bold text-gray-950">{{ $t("rideshare_tips_title") }}</h2>
          </div>
          <div class="grid grid-cols-1 gap-3 p-4 text-xs text-gray-500 sm:grid-cols-3">
            <div class="rounded-xl border border-gray-200 bg-gray-50 px-3 py-3">
              <div class="mb-1 font-semibold text-gray-800">{{ $t("rideshare_tip1_title") }}</div>
              <div>{{ $t("rideshare_tip1_desc") }}</div>
            </div>
            <div class="rounded-xl border border-gray-200 bg-gray-50 px-3 py-3">
              <div class="mb-1 font-semibold text-gray-800">{{ $t("rideshare_tip2_title") }}</div>
              <div>{{ $t("rideshare_tip2_desc") }}</div>
            </div>
            <div class="rounded-xl border border-gray-200 bg-gray-50 px-3 py-3">
              <div class="mb-1 font-semibold text-gray-800">{{ $t("rideshare_tip3_title") }}</div>
              <div>{{ $t("rideshare_tip3_desc") }}</div>
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
const selectionTarget = ref("pickup");
const selectedVehicleType = ref("bike");
const estimating = ref(false);
const creatingRide = ref(false);
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
  document.addEventListener("click", handleClickOutside);
});

onBeforeUnmount(() => {
  if (pickupTimer) clearTimeout(pickupTimer);
  if (dropTimer) clearTimeout(dropTimer);
  document.removeEventListener("click", handleClickOutside);
});
</script>
