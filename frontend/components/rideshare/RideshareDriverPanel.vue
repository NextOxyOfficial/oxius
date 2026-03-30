<template>
  <div class="space-y-5">
    <!-- Location Permission Required for Drivers -->
    <div
      v-if="!locationGranted && !locationLoading"
      class="rounded-2xl border-2 border-red-300 bg-gradient-to-r from-red-50 to-orange-50 px-5 py-5 shadow-sm"
    >
      <div class="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
        <div class="flex items-center gap-4">
          <div class="flex h-12 w-12 items-center justify-center rounded-xl bg-red-100 text-red-600">
            <UIcon name="i-heroicons-exclamation-triangle" class="h-6 w-6" />
          </div>
          <div>
            <div class="text-base font-bold text-red-800">{{ $t("rideshare_location_mandatory") }}</div>
            <div class="text-sm text-red-600">{{ $t("rideshare_location_mandatory_driver_desc") }}</div>
          </div>
        </div>
        <button
          type="button"
          class="inline-flex items-center gap-2 rounded-xl bg-gradient-to-r from-red-500 to-orange-500 px-5 py-3 text-sm font-bold text-white shadow-md transition-all hover:from-red-600 hover:to-orange-600"
          :disabled="locationLoading"
          @click="requestLocationPermission"
        >
          <UIcon name="i-heroicons-map-pin" class="h-5 w-5" />
          {{ $t("rideshare_enable_location") }}
        </button>
      </div>
    </div>

    <div v-if="driverNotice" class="rounded-xl border border-amber-200 bg-amber-50 px-4 py-3 text-sm text-amber-700">
      {{ driverNotice }}
    </div>

    <!-- Stats Grid -->
    <div class="grid grid-cols-2 gap-3 lg:grid-cols-4">
      <div class="rounded-xl border border-slate-200/80 bg-white/90 backdrop-blur-sm px-4 py-4 shadow-sm">
        <div class="flex items-center gap-1.5 text-[11px] font-semibold uppercase tracking-wide text-slate-400">
          <UIcon name="i-heroicons-check-badge" class="h-3.5 w-3.5" />
          Approval
        </div>
        <div class="mt-1.5 text-base font-bold capitalize text-slate-800">{{ driverProfile?.approval_status || 'pending' }}</div>
      </div>
      <div class="rounded-xl border border-slate-200/80 bg-white/90 backdrop-blur-sm px-4 py-4 shadow-sm">
        <div class="flex items-center gap-1.5 text-[11px] font-semibold uppercase tracking-wide text-slate-400">
          <UIcon name="i-heroicons-truck" class="h-3.5 w-3.5" />
          Trips
        </div>
        <div class="mt-1.5 text-base font-bold text-slate-800">{{ earningsSummary?.total_trips || 0 }}</div>
      </div>
      <div class="rounded-xl border border-slate-200/80 bg-white/90 backdrop-blur-sm px-4 py-4 shadow-sm">
        <div class="flex items-center gap-1.5 text-[11px] font-semibold uppercase tracking-wide text-slate-400">
          <UIcon name="i-heroicons-banknotes" class="h-3.5 w-3.5" />
          Earnings
        </div>
        <div class="mt-1.5 text-base font-bold text-indigo-600">৳{{ earningsSummary?.total_earnings || '0.00' }}</div>
      </div>
      <div class="rounded-xl border border-slate-200/80 bg-white/90 backdrop-blur-sm px-4 py-4 shadow-sm">
        <div class="flex items-center gap-1.5 text-[11px] font-semibold uppercase tracking-wide text-slate-400">
          <UIcon name="i-heroicons-signal" class="h-3.5 w-3.5" />
          Updates
        </div>
        <div class="mt-1.5 text-base font-bold text-slate-800">{{ dispatchUpdatesStatus }}</div>
      </div>
    </div>

    <div class="grid grid-cols-1 gap-5 xl:grid-cols-5">
      <!-- Profile Form -->
      <div class="space-y-5 xl:col-span-2">
        <div class="overflow-hidden rounded-2xl border border-slate-200/80 bg-white/90 backdrop-blur-sm shadow-sm">
          <div class="border-b border-slate-100 bg-slate-50/50 px-5 py-4">
            <h2 class="text-base font-bold text-slate-800">Driver Profile</h2>
            <p class="text-xs text-slate-500">Manage your driver information</p>
          </div>

          <form class="space-y-3 p-4" @submit.prevent="saveProfile">
            <div>
              <label class="mb-1.5 block text-xs font-medium text-slate-700">License Number</label>
              <UInput v-model="profileForm.license_number" placeholder="Driving license number" size="sm" />
            </div>
            <div>
              <label class="mb-1.5 block text-xs font-medium text-slate-700">National ID Number</label>
              <UInput v-model="profileForm.national_id_number" placeholder="National ID" size="sm" />
            </div>
            <div>
              <label class="mb-1.5 block text-xs font-medium text-slate-700">Service Radius (km)</label>
              <UInput v-model="profileForm.service_radius_km" type="number" min="1" step="0.1" size="sm" />
            </div>
            <div class="flex flex-wrap gap-2 pt-1">
              <button
                type="submit"
                class="inline-flex items-center gap-1.5 rounded-lg bg-gradient-to-r from-indigo-500 to-violet-600 px-3 py-2 text-xs font-semibold text-white shadow-sm transition-all hover:from-indigo-600 hover:to-violet-700 disabled:opacity-50"
                :disabled="savingProfile"
              >
                <span v-if="savingProfile" class="h-3 w-3 animate-spin rounded-full border-2 border-white border-t-transparent"></span>
                Save Profile
              </button>
              <button
                type="button"
                class="inline-flex items-center gap-1.5 rounded-lg px-3 py-2 text-xs font-semibold transition-all disabled:opacity-50"
                :class="driverProfile?.is_online ? 'bg-red-100 text-red-700 hover:bg-red-200' : 'bg-emerald-100 text-emerald-700 hover:bg-emerald-200'"
                :disabled="!isApprovedDriver || togglingOnline"
                @click="toggleOnlineStatus"
              >
                <span v-if="togglingOnline" class="h-3 w-3 animate-spin rounded-full border-2 border-current border-t-transparent"></span>
                {{ driverProfile?.is_online ? 'Go Offline' : 'Go Online' }}
              </button>
            </div>
            <div class="flex flex-wrap gap-1.5 pt-1">
              <NuxtLink to="/rideshare/vehicles" class="rounded-lg bg-slate-100 px-2.5 py-1.5 text-[10px] font-medium text-slate-600 hover:bg-slate-200">Manage Vehicles</NuxtLink>
              <NuxtLink to="/rideshare/active" class="rounded-lg bg-slate-100 px-2.5 py-1.5 text-[10px] font-medium text-slate-600 hover:bg-slate-200">Active Trip</NuxtLink>
            </div>
          </form>
        </div>
      </div>

      <!-- Ride Requests -->
      <div class="xl:col-span-3">
        <div class="overflow-hidden rounded-xl border border-slate-200/80 bg-white/80 backdrop-blur-sm shadow-sm">
          <div class="flex items-center justify-between gap-3 border-b border-slate-100 bg-slate-50/50 px-4 py-3">
            <div>
              <h2 class="text-sm font-bold text-slate-800">Available Ride Requests</h2>
              <p class="text-[11px] text-slate-500">Live ride requests for your vehicle type</p>
            </div>
            <div class="flex items-center gap-1.5">
              <span class="rounded-md px-2 py-0.5 text-[10px] font-semibold"
                :class="driverProfile?.is_online ? 'bg-gradient-to-r from-indigo-500 to-violet-600 text-white' : 'bg-slate-100 text-slate-500'"
              >
                {{ driverProfile?.is_online ? 'Online' : 'Offline' }}
              </span>
              <button type="button" class="rounded-lg bg-slate-100 px-2.5 py-1.5 text-[10px] font-medium text-slate-600 hover:bg-slate-200" :disabled="loadingRequests" @click="loadAvailableRequests">
                {{ loadingRequests ? '...' : 'Refresh' }}
              </button>
            </div>
          </div>

          <div v-if="!isApprovedDriver" class="p-4">
            <div class="rounded-lg border border-dashed border-slate-200 bg-slate-50 px-4 py-6 text-center">
              <div class="flex h-10 w-10 mx-auto items-center justify-center rounded-lg bg-slate-100 text-slate-400 mb-2">
                <UIcon name="i-heroicons-clock" class="h-5 w-5" />
              </div>
              <div class="text-xs font-medium text-slate-600">Account under review</div>
              <div class="text-[11px] text-slate-400 mt-0.5">Live requests will appear once approved.</div>
            </div>
          </div>

          <div v-else-if="loadingRequests" class="space-y-2 p-4">
            <div v-for="index in 3" :key="index" class="h-20 animate-pulse rounded-lg bg-slate-100"></div>
          </div>

          <div v-else-if="!rideRequests.length" class="p-4">
            <div class="rounded-lg border border-dashed border-slate-200 bg-slate-50 px-4 py-6 text-center">
              <div class="flex h-10 w-10 mx-auto items-center justify-center rounded-lg bg-slate-100 text-slate-400 mb-2">
                <UIcon name="i-heroicons-map" class="h-5 w-5" />
              </div>
              <div class="text-xs font-medium text-slate-600">No ride requests</div>
              <div class="text-[11px] text-slate-400 mt-0.5">Go online to receive dispatch updates.</div>
            </div>
          </div>

          <div v-else class="space-y-2 p-3">
            <div v-for="ride in rideRequests" :key="ride.id" class="rounded-lg border border-slate-200 bg-white px-3 py-3">
              <div class="flex flex-col gap-3 sm:flex-row sm:items-start sm:justify-between">
                <div class="space-y-1.5 min-w-0 flex-1">
                  <div class="flex flex-wrap items-center gap-1.5">
                    <h3 class="text-xs font-semibold text-slate-800 truncate">{{ ride.pickup_address }}</h3>
                    <span class="rounded-md bg-slate-100 px-1.5 py-0.5 text-[9px] font-semibold text-slate-600 capitalize">
                      {{ ride.requested_vehicle_type }}
                    </span>
                  </div>
                  <div class="text-[11px] text-slate-500 truncate">To: {{ ride.drop_address }}</div>
                  <div class="grid grid-cols-4 gap-2 text-[10px]">
                    <div class="rounded bg-slate-50 px-2 py-1">
                      <div class="text-slate-400 font-medium">Fare</div>
                      <div class="text-indigo-600 font-bold">৳{{ ride.fare_estimate }}</div>
                    </div>
                    <div class="rounded bg-slate-50 px-2 py-1">
                      <div class="text-slate-400 font-medium">Distance</div>
                      <div class="text-slate-700 font-semibold">{{ ride.distance_km }} km</div>
                    </div>
                    <div class="rounded bg-slate-50 px-2 py-1">
                      <div class="text-slate-400 font-medium">Status</div>
                      <div class="text-slate-700 font-semibold capitalize">{{ ride.status.replaceAll('_', ' ') }}</div>
                    </div>
                    <div class="rounded bg-slate-50 px-2 py-1">
                      <div class="text-slate-400 font-medium">Time</div>
                      <div class="text-slate-700 font-semibold">{{ formatDateTime(ride.requested_at) }}</div>
                    </div>
                  </div>
                </div>
                <div class="flex-shrink-0">
                  <button
                    type="button"
                    class="inline-flex items-center gap-1.5 rounded-lg bg-gradient-to-r from-indigo-500 to-violet-600 px-3 py-2 text-xs font-semibold text-white shadow-sm transition-all hover:from-indigo-600 hover:to-violet-700 disabled:opacity-50"
                    :disabled="acceptingRideId === ride.id"
                    @click="acceptRequest(ride)"
                  >
                    <span v-if="acceptingRideId === ride.id" class="h-3 w-3 animate-spin rounded-full border-2 border-white border-t-transparent"></span>
                    Accept
                  </button>
                </div>
              </div>
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
  getDriverProfile,
  updateDriverProfile,
  toggleDriverOnline,
  getDriverEarningsSummary,
  listAvailableRideRequests,
  acceptRide,
} = useRideshare();
const {
  dispatchConnectionState,
  connectDriverDispatchSocket,
} = useRideshareSocket();

const rawError = ref("");
const driverProfile = ref(null);
const earningsSummary = ref({ total_trips: 0, total_earnings: "0.00" });
const rideRequests = ref([]);
const loadingRequests = ref(false);
const savingProfile = ref(false);
const togglingOnline = ref(false);
const acceptingRideId = ref(null);
let stopDispatchSocket = null;

// Location permission state for drivers
const locationGranted = ref(false);
const locationLoading = ref(false);
let locationWatchId = null;

const checkLocationPermission = async () => {
  if (!process.client || !navigator.permissions) {
    return;
  }
  try {
    const result = await navigator.permissions.query({ name: 'geolocation' });
    locationGranted.value = result.state === 'granted';
    result.onchange = () => {
      locationGranted.value = result.state === 'granted';
      if (result.state === 'granted' && driverProfile.value?.is_online) {
        startLocationTracking();
      }
    };
  } catch (error) {
    console.error('Permission check failed:', error);
  }
};

const requestLocationPermission = async () => {
  if (!process.client || !navigator.geolocation) {
    return;
  }
  locationLoading.value = true;
  navigator.geolocation.getCurrentPosition(
    (position) => {
      locationGranted.value = true;
      locationLoading.value = false;
      // Start tracking if driver is online
      if (driverProfile.value?.is_online) {
        startLocationTracking();
      }
    },
    () => {
      locationLoading.value = false;
      toast.add({ 
        title: "Location Required", 
        description: "Please enable location access to use driver features.", 
        color: "red" 
      });
    },
    { enableHighAccuracy: true, timeout: 10000 }
  );
};

const startLocationTracking = () => {
  if (!process.client || !navigator.geolocation || locationWatchId) {
    return;
  }
  locationWatchId = navigator.geolocation.watchPosition(
    (position) => {
      // Send location to backend
      // This will be handled by the existing location update mechanism
      console.log('Driver location updated:', position.coords.latitude, position.coords.longitude);
    },
    (error) => {
      console.error('Location tracking error:', error);
    },
    { enableHighAccuracy: true, timeout: 10000, maximumAge: 5000 }
  );
};

const stopLocationTracking = () => {
  if (locationWatchId && navigator.geolocation) {
    navigator.geolocation.clearWatch(locationWatchId);
    locationWatchId = null;
  }
};

const profileForm = ref({
  license_number: "",
  national_id_number: "",
  service_radius_km: 8,
});

const isApprovedDriver = computed(() => driverProfile.value?.approval_status === "approved");
const driverNotice = computed(() => {
  if (rawError.value) {
    return "Some driver tools are temporarily unavailable. Please try again shortly.";
  }
  if (!driverProfile.value) {
    return "Loading driver workspace...";
  }
  if (!isApprovedDriver.value) {
    return "Switch to Passenger Mode while your driver profile is pending approval, or complete your driver details below.";
  }
  return "";
});
const dispatchUpdatesStatus = computed(() => {
  if (!isApprovedDriver.value) {
    return "Approval Required";
  }
  if (!driverProfile.value?.is_online) {
    return "Offline";
  }
  if (dispatchConnectionState.value === "connected") {
    return "Live";
  }
  if (["failed", "error", "closed"].includes(dispatchConnectionState.value)) {
    return "Unavailable";
  }
  if (dispatchConnectionState.value === "reconnecting") {
    return "Reconnecting";
  }
  if (dispatchConnectionState.value === "connecting") {
    return "Connecting";
  }
  return "Offline";
});

const formatDateTime = (value) => {
  return new Date(value).toLocaleString(undefined, {
    month: "short",
    day: "numeric",
    hour: "numeric",
    minute: "2-digit",
  });
};

const loadProfile = async () => {
  const result = await getDriverProfile();
  if (result.success) {
    driverProfile.value = result.data;
    profileForm.value = {
      license_number: result.data?.license_number || "",
      national_id_number: result.data?.national_id_number || "",
      service_radius_km: result.data?.service_radius_km || 8,
    };
  } else {
    rawError.value = result.message;
  }
};

const loadSummary = async () => {
  if (!isApprovedDriver.value) {
    earningsSummary.value = { total_trips: 0, total_earnings: "0.00" };
    return;
  }
  const result = await getDriverEarningsSummary();
  if (result.success) {
    earningsSummary.value = result.data;
  }
};

const loadAvailableRequests = async () => {
  if (!isApprovedDriver.value) {
    rideRequests.value = [];
    loadingRequests.value = false;
    return;
  }
  loadingRequests.value = true;
  const result = await listAvailableRideRequests();
  if (result.success) {
    rideRequests.value = result.data || [];
  } else {
    rawError.value = result.message;
  }
  loadingRequests.value = false;
};

const saveProfile = async () => {
  savingProfile.value = true;
  rawError.value = "";
  const result = await updateDriverProfile({
    license_number: profileForm.value.license_number,
    national_id_number: profileForm.value.national_id_number,
    service_radius_km: profileForm.value.service_radius_km,
  });

  if (result.success) {
    driverProfile.value = result.data;
    toast.add({ title: "Profile updated", description: result.message, color: "gray" });
  } else {
    rawError.value = result.message;
    toast.add({ title: "Profile update failed", description: "Please review the form and try again.", color: "red" });
  }
  savingProfile.value = false;
};

const toggleOnlineStatus = async () => {
  togglingOnline.value = true;
  const result = await toggleDriverOnline(!(driverProfile.value?.is_online));
  if (result.success) {
    driverProfile.value = result.data;
    toast.add({ title: "Availability updated", description: result.message, color: "gray" });
    if (driverProfile.value?.is_online) {
      startDispatchSocket();
    } else if (stopDispatchSocket) {
      stopDispatchSocket();
      stopDispatchSocket = null;
    }
    await loadSummary();
    await loadAvailableRequests();
  } else {
    rawError.value = result.message;
    toast.add({ title: "Availability update failed", description: "Please try again shortly.", color: "red" });
  }
  togglingOnline.value = false;
};

const acceptRequest = async (ride) => {
  acceptingRideId.value = ride.id;
  const result = await acceptRide(ride.id);
  if (result.success) {
    toast.add({ title: "Ride accepted", description: result.message, color: "gray" });
    await router.push("/rideshare/active");
  } else {
    rawError.value = result.message;
    toast.add({ title: "Accept failed", description: "The request is no longer available.", color: "red" });
  }
  acceptingRideId.value = null;
};

const startDispatchSocket = () => {
  if (stopDispatchSocket) {
    stopDispatchSocket();
  }

  if (!isApprovedDriver.value || !driverProfile.value?.is_online) {
    return;
  }

  stopDispatchSocket = connectDriverDispatchSocket((payload) => {
    if (payload?.type === "ride.request") {
      loadAvailableRequests();
      toast.add({
        title: "New ride request",
        description: payload.pickup_address || "A new rider request is available.",
        color: "gray",
      });
    }
    if (payload?.type === "ride.event" && ["ride_accepted", "ride_cancelled"].includes(payload.event)) {
      loadAvailableRequests();
    }
  });
};

onMounted(async () => {
  checkLocationPermission();
  await loadProfile();
  if (isApprovedDriver.value) {
    await loadSummary();
    await loadAvailableRequests();
    startDispatchSocket();
    if (locationGranted.value && driverProfile.value?.is_online) {
      startLocationTracking();
    }
  }
});

onBeforeUnmount(() => {
  if (stopDispatchSocket) {
    stopDispatchSocket();
  }
  stopLocationTracking();
});
</script>
