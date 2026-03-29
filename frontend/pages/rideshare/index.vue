<template>
  <PublicSection>
    <div class="min-h-screen py-4 sm:py-8 bg-gradient-to-b from-gray-50 to-gray-100">
      <UContainer class="max-w-7xl">
        <div class="mb-5">
          <div class="flex items-center gap-3 mb-1">
            <div class="w-10 h-10 rounded-xl bg-emerald-100 flex items-center justify-center">
              <UIcon name="i-heroicons-map-pin" class="w-5 h-5 text-emerald-600" />
            </div>
            <div>
              <h1 class="text-xl sm:text-2xl font-bold text-gray-900">{{ $t("rideshare_booking") }}</h1>
              <p class="text-xs sm:text-sm text-gray-500">{{ $t("rideshare_booking_desc") }}</p>
            </div>
          </div>
        </div>

        <div class="mb-5">
          <RideshareNav current="booking" />
        </div>

        <div
          v-if="activeRide"
          class="mb-5 rounded-xl border border-emerald-200 bg-emerald-50/80 backdrop-blur-sm px-4 py-3 flex flex-col sm:flex-row sm:items-center sm:justify-between gap-3"
        >
          <div class="flex items-center gap-3">
            <div class="w-8 h-8 rounded-full bg-emerald-200 flex items-center justify-center flex-shrink-0">
              <UIcon name="i-heroicons-arrow-path" class="w-4 h-4 text-emerald-700 animate-spin" />
            </div>
            <div>
              <div class="text-sm font-semibold text-emerald-800">{{ $t("rideshare_active_ride_alert") }}</div>
              <div class="text-xs text-emerald-600 mt-0.5 capitalize">{{ formatStatus(activeRide.status) }}</div>
            </div>
          </div>
          <UButton to="/rideshare/active" color="emerald" size="sm">{{ $t("rideshare_go_active_trip") }}</UButton>
        </div>

        <div v-if="pageError" class="mb-5 rounded-xl border border-red-200 bg-red-50 px-4 py-3 text-sm text-red-700 flex items-center gap-2">
          <UIcon name="i-heroicons-exclamation-triangle" class="w-4 h-4 flex-shrink-0" />
          {{ pageError }}
        </div>

        <div class="grid grid-cols-1 xl:grid-cols-5 gap-5">
          <!-- Booking Form -->
          <div class="xl:col-span-2 space-y-5 order-last xl:order-none">
            <div class="bg-white border border-gray-200 rounded-xl shadow-sm overflow-visible">
              <div class="px-4 py-3 border-b border-gray-100 bg-gradient-to-r from-emerald-50/50 to-white">
                <h2 class="text-base font-bold text-gray-900">{{ $t("rideshare_ride_booking") }}</h2>
                <p class="text-xs text-gray-500 mt-0.5">{{ $t("rideshare_ride_booking_desc") }}</p>
              </div>

              <div class="p-4 space-y-4">
                <!-- Uber-style pickup/drop inputs with vertical timeline -->
                <div class="relative flex gap-3">
                  <!-- Timeline dots and line -->
                  <div class="flex flex-col items-center pt-3 pb-3">
                    <div class="w-3 h-3 rounded-full bg-black border-2 border-black flex-shrink-0"></div>
                    <div class="w-0.5 flex-1 bg-gray-300 my-1"></div>
                    <div class="w-3 h-3 bg-black flex-shrink-0" style="clip-path: polygon(50% 100%, 0 0, 100% 0);"></div>
                  </div>

                  <!-- Input fields -->
                  <div class="flex-1 space-y-2 min-w-0">
                    <!-- Pickup input -->
                    <div class="relative" ref="pickupSearchRef">
                      <div
                        class="flex items-center gap-2 rounded-lg border px-3 py-2.5 cursor-text transition-all"
                        :class="searchTarget === 'pickup' ? 'border-gray-900 ring-1 ring-gray-900/10 bg-white' : 'border-gray-200 bg-gray-50 hover:bg-white hover:border-gray-300'"
                        @click="focusPickupInput"
                      >
                        <div class="flex-1 min-w-0">
                          <div class="text-[10px] font-bold uppercase tracking-wider text-gray-400 mb-0.5">{{ $t("rideshare_pickup_location") }}</div>
                          <input
                            ref="pickupInputEl"
                            v-model="pickupQuery"
                            type="text"
                            class="w-full text-sm font-medium text-gray-900 bg-transparent outline-none placeholder:text-gray-400 placeholder:font-normal"
                            :placeholder="$t('rideshare_search_pickup')"
                            @focus="onPickupFocus"
                            @input="onPickupInput"
                          />
                        </div>
                        <button
                          type="button"
                          class="flex-shrink-0 h-8 rounded-full bg-gray-100 hover:bg-gray-200 inline-flex items-center justify-center gap-1.5 px-3 text-[11px] font-semibold text-gray-700 transition-colors"
                          :disabled="locatingPickup"
                          :class="locatingPickup ? 'cursor-wait bg-gray-200 text-gray-600' : ''"
                          @click.stop="useCurrentLocation"
                        >
                          <template v-if="locatingPickup">
                            <div class="w-3.5 h-3.5 border-2 border-gray-400 border-t-transparent rounded-full animate-spin"></div>
                            <span>{{ $t("rideshare_selecting") }}</span>
                          </template>
                          <template v-else>
                            <UIcon name="i-heroicons-map-pin" class="w-4 h-4 text-gray-600" />
                            <span>{{ $t("rideshare_current_location") }}</span>
                          </template>
                        </button>
                      </div>
                      <!-- Pickup suggestions dropdown -->
                      <div
                        v-if="searchTarget === 'pickup' && pickupSuggestions.length"
                        class="absolute z-30 mt-1 left-0 right-0 rounded-lg border border-gray-200 bg-white shadow-xl overflow-hidden max-h-60 overflow-y-auto"
                      >
                        <button
                          v-for="item in pickupSuggestions"
                          :key="`p-${item.latitude}-${item.longitude}`"
                          type="button"
                          class="w-full px-3 py-2.5 text-left hover:bg-gray-50 border-b border-gray-50 last:border-b-0 transition-colors flex items-start gap-2.5"
                          @click="selectSuggestion('pickup', item)"
                        >
                          <div class="w-8 h-8 rounded-full bg-gray-100 flex items-center justify-center flex-shrink-0 mt-0.5">
                            <UIcon name="i-heroicons-map-pin" class="w-4 h-4 text-gray-600" />
                          </div>
                          <div class="min-w-0 flex-1">
                            <div class="text-sm font-medium text-gray-900 truncate">{{ item.name }}</div>
                            <div class="text-xs text-gray-400 mt-0.5 truncate">{{ formatAddress(item.address) }}</div>
                          </div>
                        </button>
                      </div>
                    </div>

                    <!-- Drop input -->
                    <div class="relative" ref="dropSearchRef">
                      <div
                        class="flex items-center gap-2 rounded-lg border px-3 py-2.5 cursor-text transition-all"
                        :class="searchTarget === 'drop' ? 'border-gray-900 ring-1 ring-gray-900/10 bg-white' : 'border-gray-200 bg-gray-50 hover:bg-white hover:border-gray-300'"
                        @click="focusDropInput"
                      >
                        <div class="flex-1 min-w-0">
                          <div class="text-[10px] font-bold uppercase tracking-wider text-gray-400 mb-0.5">{{ $t("rideshare_drop_location") }}</div>
                          <input
                            ref="dropInputEl"
                            v-model="dropQuery"
                            type="text"
                            class="w-full text-sm font-medium text-gray-900 bg-transparent outline-none placeholder:text-gray-400 placeholder:font-normal"
                            :placeholder="$t('rideshare_search_drop')"
                            @focus="onDropFocus"
                            @input="onDropInput"
                          />
                        </div>
                        <div v-if="searchingDrop" class="flex-shrink-0">
                          <div class="w-4 h-4 border-2 border-gray-400 border-t-transparent rounded-full animate-spin"></div>
                        </div>
                      </div>
                      <!-- Drop suggestions dropdown -->
                      <div
                        v-if="searchTarget === 'drop' && dropSuggestions.length"
                        class="absolute z-30 mt-1 left-0 right-0 rounded-lg border border-gray-200 bg-white shadow-xl overflow-hidden max-h-60 overflow-y-auto"
                      >
                        <button
                          v-for="item in dropSuggestions"
                          :key="`d-${item.latitude}-${item.longitude}`"
                          type="button"
                          class="w-full px-3 py-2.5 text-left hover:bg-gray-50 border-b border-gray-50 last:border-b-0 transition-colors flex items-start gap-2.5"
                          @click="selectSuggestion('drop', item)"
                        >
                          <div class="w-8 h-8 rounded-full bg-gray-100 flex items-center justify-center flex-shrink-0 mt-0.5">
                            <UIcon name="i-heroicons-map-pin" class="w-4 h-4 text-gray-600" />
                          </div>
                          <div class="min-w-0 flex-1">
                            <div class="text-sm font-medium text-gray-900 truncate">{{ item.name }}</div>
                            <div class="text-xs text-gray-400 mt-0.5 truncate">{{ formatAddress(item.address) }}</div>
                          </div>
                        </button>
                      </div>
                    </div>
                  </div>
                </div>

                <!-- Vehicle type -->
                <div>
                  <label class="block text-xs font-semibold text-gray-700 mb-1.5">{{ $t("rideshare_vehicle_type") }}</label>
                  <div class="grid grid-cols-3 gap-2">
                    <button
                      v-for="item in vehicleOptions"
                      :key="item.value"
                      type="button"
                      class="rounded-lg border px-2 py-2.5 text-center transition-all"
                      :class="selectedVehicleType === item.value ? 'border-emerald-500 bg-emerald-50 text-emerald-700 ring-1 ring-emerald-200' : 'border-gray-200 bg-white text-gray-600 hover:bg-gray-50'"
                      @click="selectedVehicleType = item.value"
                    >
                      <div class="text-lg">{{ item.icon }}</div>
                      <div class="text-xs font-semibold mt-0.5">{{ item.label }}</div>
                    </button>
                  </div>
                </div>

                <!-- Action buttons -->
                <div class="pt-1">
                  <UButton
                    color="emerald"
                    block
                    :loading="estimating"
                    :disabled="!canEstimate || Boolean(activeRide)"
                    @click="requestEstimate"
                  >
                    {{ $t("rideshare_get_estimate") }}
                  </UButton>
                </div>

                <!-- Fare Summary -->
                <div class="rounded-xl border border-gray-200 overflow-hidden bg-white">
                  <div class="px-4 py-3 border-b border-gray-100 flex items-center justify-between gap-3 bg-gray-50/70">
                    <h2 class="text-sm font-bold text-gray-900">{{ $t("rideshare_fare_summary") }}</h2>
                    <UBadge :color="estimateResult ? 'emerald' : 'gray'" variant="soft" size="xs">
                      {{ estimateResult ? $t("rideshare_ready") : $t("rideshare_waiting") }}
                    </UBadge>
                  </div>
                  <div class="p-4">
                    <div v-if="estimateResult" class="space-y-3">
                      <div class="grid grid-cols-3 gap-2">
                        <div class="rounded-lg bg-gray-50 border border-gray-100 px-3 py-3 text-center">
                          <div class="text-[10px] uppercase tracking-wider text-gray-400 font-semibold">{{ $t("rideshare_distance") }}</div>
                          <div class="mt-1 text-sm font-bold text-gray-900">{{ estimateResult.distance_km }} km</div>
                        </div>
                        <div class="rounded-lg bg-gray-50 border border-gray-100 px-3 py-3 text-center">
                          <div class="text-[10px] uppercase tracking-wider text-gray-400 font-semibold">{{ $t("rideshare_eta") }}</div>
                          <div class="mt-1 text-sm font-bold text-gray-900">{{ formatEta(estimateResult.eta_seconds) }}</div>
                        </div>
                        <div class="rounded-lg bg-emerald-50 border border-emerald-100 px-3 py-3 text-center">
                          <div class="text-[10px] uppercase tracking-wider text-emerald-600 font-semibold">{{ $t("rideshare_fare") }}</div>
                          <div class="mt-1 text-sm font-bold text-emerald-800">৳{{ estimateResult.fare }}</div>
                        </div>
                      </div>
                      <UButton
                        color="gray"
                        variant="soft"
                        block
                        :loading="creatingRide"
                        :disabled="!estimateResult || Boolean(activeRide)"
                        @click="submitRideRequest"
                      >
                        {{ $t("rideshare_confirm_ride") }}
                      </UButton>
                    </div>
                    <div v-else class="rounded-lg border border-dashed border-gray-200 bg-gray-50 px-3 py-5 text-xs text-gray-400 text-center">
                      {{ $t("rideshare_fare_placeholder") }}
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>

          <!-- Map + Tips -->
          <div class="xl:col-span-3 space-y-5 order-first xl:order-none">
            <div class="bg-white border border-gray-200 rounded-xl shadow-sm overflow-hidden">
              <div class="px-4 py-3 border-b border-gray-100 flex items-center justify-between gap-3">
                <div class="flex items-center gap-2">
                  <UIcon name="i-heroicons-map" class="w-4 h-4 text-gray-700" />
                  <h2 class="text-sm font-bold text-gray-900">{{ $t("rideshare_live_map") }}</h2>
                </div>
                <div class="flex items-center gap-3 text-[10px]">
                  <button
                    type="button"
                    class="flex items-center gap-1.5 px-2 py-1 rounded-full transition-all"
                    :class="selectionTarget === 'pickup' ? 'bg-gray-900 text-white' : 'bg-gray-100 text-gray-500 hover:bg-gray-200'"
                    @click="selectionTarget = 'pickup'"
                  >
                    <span class="w-1.5 h-1.5 rounded-full bg-current"></span>
                    <span class="font-semibold">Pickup</span>
                  </button>
                  <button
                    type="button"
                    class="flex items-center gap-1.5 px-2 py-1 rounded-full transition-all"
                    :class="selectionTarget === 'drop' ? 'bg-gray-900 text-white' : 'bg-gray-100 text-gray-500 hover:bg-gray-200'"
                    @click="selectionTarget = 'drop'"
                  >
                    <span class="w-1.5 h-1.5 bg-current" style="clip-path: polygon(50% 100%, 0 0, 100% 0);"></span>
                    <span class="font-semibold">Drop</span>
                  </button>
                </div>
              </div>
              <div class="p-2 sm:p-3">
                <ClientOnly>
                  <RideshareMap
                    :pickup="pickupPoint"
                    :drop="dropPoint"
                    :route-geometry="estimateResult?.route_geometry || null"
                    :active-selection="selectionTarget"
                    :loading="estimating"
                    @map-click="handleMapSelection"
                    @pickup-dragged="handlePickupDragged"
                  />
                  <template #fallback>
                    <div class="h-[320px] sm:h-[420px] rounded-lg border border-gray-200 bg-gray-50 flex items-center justify-center text-sm text-gray-400">
                      <UIcon name="i-heroicons-map" class="w-6 h-6 mr-2" /> Loading map...
                    </div>
                  </template>
                </ClientOnly>
              </div>
            </div>

            <div class="bg-white border border-gray-200 rounded-xl shadow-sm overflow-hidden">
              <div class="px-4 py-3 border-b border-gray-100">
                <h2 class="text-sm font-bold text-gray-900">{{ $t("rideshare_tips_title") }}</h2>
              </div>
              <div class="p-4 grid grid-cols-1 sm:grid-cols-3 gap-3 text-xs text-gray-500">
                <div class="rounded-lg bg-emerald-50/50 border border-emerald-100 px-3 py-3">
                  <div class="font-semibold text-gray-800 mb-1">{{ $t("rideshare_tip1_title") }}</div>
                  <div>{{ $t("rideshare_tip1_desc") }}</div>
                </div>
                <div class="rounded-lg bg-blue-50/50 border border-blue-100 px-3 py-3">
                  <div class="font-semibold text-gray-800 mb-1">{{ $t("rideshare_tip2_title") }}</div>
                  <div>{{ $t("rideshare_tip2_desc") }}</div>
                </div>
                <div class="rounded-lg bg-amber-50/50 border border-amber-100 px-3 py-3">
                  <div class="font-semibold text-gray-800 mb-1">{{ $t("rideshare_tip3_title") }}</div>
                  <div>{{ $t("rideshare_tip3_desc") }}</div>
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

const { $i18n } = useNuxtApp();
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
const searchingPickup = ref(false);
const searchingDrop = ref(false);
const pageError = ref("");
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
  { label: "Bike", value: "bike", icon: "\uD83C\uDFCD\uFE0F" },
  { label: "Car", value: "car", icon: "\uD83D\uDE97" },
  { label: "CNG", value: "cng", icon: "\uD83D\uDEFA" },
];

const canEstimate = computed(() => {
  return pickupPoint.value && dropPoint.value;
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

const formatStatus = (value) => {
  return String(value || "").replaceAll("_", " ").trim();
};

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

watch(selectedVehicleType, () => {
  if (canEstimate.value) {
    requestEstimate();
  }
});

const selectSuggestion = async (target, item) => {
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

const requestEstimate = async () => {
  if (!pickupPoint.value || !dropPoint.value) {
    return;
  }

  estimating.value = true;
  pageError.value = "";

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
    pickup_latitude: serializeCoordinate(pickupPoint.value.latitude),
    pickup_longitude: serializeCoordinate(pickupPoint.value.longitude),
    drop_latitude: serializeCoordinate(dropPoint.value.latitude),
    drop_longitude: serializeCoordinate(dropPoint.value.longitude),
    pickup_address: pickupPoint.value.name,
    drop_address: dropPoint.value.name,
    vehicle_type: selectedVehicleType.value,
  });

  if (result.success) {
    toast.add({ title: "Ride requested", description: result.message, color: "green" });
    await router.push("/rideshare/active");
  } else {
    pageError.value = result.message;
    toast.add({ title: "Ride request failed", description: result.message, color: "red" });
  }

  creatingRide.value = false;
};

const loadActiveRide = async () => {
  const result = await getActiveRide();
  if (result.success && result.data) {
    activeRide.value = result.data;
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
