<template>
  <PublicSection>
    <div class="min-h-screen py-4 sm:py-6 bg-gradient-to-br from-slate-50 via-white to-indigo-50/30">
      <UContainer class="max-w-7xl space-y-5">
        <!-- Header -->
        <div class="relative z-50 flex items-center justify-between gap-3 rounded-xl border border-slate-200/80 bg-white px-4 py-3 shadow-xs">
          <div class="flex items-center gap-3">
            <div class="flex h-10 w-10 items-center justify-center rounded-lg bg-gradient-to-br from-indigo-500 to-violet-600 text-white">
              <UIcon name="i-heroicons-identification" class="h-5 w-5" />
            </div>
            <div>
              <h1 class="text-base font-bold text-slate-800">Driver Dashboard</h1>
              <p class="text-[10px] text-slate-500">Manage profile and ride requests</p>
            </div>
          </div>
          <RideshareModeSwitch />
        </div>

        <RideshareNav current="driver" />

        <div v-if="pageError" class="rounded-xl border border-red-200 bg-red-50 px-4 py-3 text-sm text-red-700">
          {{ pageError }}
        </div>

        <div class="grid grid-cols-1 xl:grid-cols-5 gap-4">
          <!-- Profile & Stats Combined -->
          <div class="xl:col-span-2">
            <div class="bg-white/90 backdrop-blur-sm border border-slate-200/80 rounded-2xl shadow-sm overflow-hidden">
              <!-- Stats Row inside card -->
              <div class="grid grid-cols-4 border-b border-slate-100">
                <div class="px-3 py-3 text-center border-r border-slate-100">
                  <div class="text-[9px] font-semibold uppercase tracking-wide text-slate-400">Status</div>
                  <div class="mt-0.5 text-xs font-bold capitalize" :class="driverProfile?.approval_status === 'approved' ? 'text-emerald-600' : 'text-amber-600'">{{ driverProfile?.approval_status || 'pending' }}</div>
                </div>
                <div class="px-3 py-3 text-center border-r border-slate-100">
                  <div class="text-[9px] font-semibold uppercase tracking-wide text-slate-400">Trips</div>
                  <div class="mt-0.5 text-xs font-bold text-slate-800">{{ earningsSummary?.total_trips || 0 }}</div>
                </div>
                <div class="px-3 py-3 text-center border-r border-slate-100">
                  <div class="text-[9px] font-semibold uppercase tracking-wide text-slate-400">Earnings</div>
                  <div class="mt-0.5 text-xs font-bold text-indigo-600">৳{{ earningsSummary?.total_earnings || '0.00' }}</div>
                </div>
                <div class="px-3 py-3 text-center">
                  <div class="text-[9px] font-semibold uppercase tracking-wide text-slate-400">Live</div>
                  <div class="mt-0.5 text-xs font-bold" :class="dispatchUpdatesStatus === 'Live' ? 'text-emerald-600' : 'text-slate-500'">{{ dispatchUpdatesStatus }}</div>
                </div>
              </div>

              <!-- Profile Form -->
              <form class="p-4 space-y-3" @submit.prevent="saveProfile">
                <div class="grid grid-cols-2 gap-3">
                  <div>
                    <label class="block text-[10px] font-medium text-slate-600 mb-1">License Number</label>
                    <UInput v-model="profileForm.license_number" placeholder="License #" size="sm" />
                  </div>
                  <div>
                    <label class="block text-[10px] font-medium text-slate-600 mb-1">National ID</label>
                    <UInput v-model="profileForm.national_id_number" placeholder="NID #" size="sm" />
                  </div>
                </div>
                <div>
                  <label class="block text-[10px] font-medium text-slate-600 mb-1">Service Radius (km)</label>
                  <UInput v-model="profileForm.service_radius_km" type="number" min="1" step="0.1" size="sm" />
                </div>
                <div class="flex gap-2 pt-1">
                  <button
                    type="submit"
                    class="flex-1 inline-flex items-center justify-center gap-1.5 rounded-lg bg-gradient-to-r from-indigo-500 to-violet-600 px-3 py-2.5 text-xs font-semibold text-white shadow-sm transition-all hover:from-indigo-600 hover:to-violet-700 disabled:opacity-50"
                    :disabled="savingProfile"
                  >
                    <span v-if="savingProfile" class="h-3 w-3 animate-spin rounded-full border-2 border-white border-t-transparent"></span>
                    Save Profile
                  </button>
                  <button
                    type="button"
                    class="flex-1 inline-flex items-center justify-center gap-1.5 rounded-lg px-3 py-2.5 text-xs font-semibold transition-all disabled:opacity-50"
                    :class="driverProfile?.is_online ? 'bg-red-100 text-red-700 hover:bg-red-200' : 'bg-emerald-100 text-emerald-700 hover:bg-emerald-200'"
                    :disabled="driverProfile?.approval_status !== 'approved' || togglingOnline"
                    @click="toggleOnlineStatus"
                  >
                    <span v-if="togglingOnline" class="h-3 w-3 animate-spin rounded-full border-2 border-current border-t-transparent"></span>
                    {{ driverProfile?.is_online ? 'Go Offline' : 'Go Online' }}
                  </button>
                </div>
                <p v-if="driverProfile?.approval_status !== 'approved'" class="text-[10px] text-amber-600 text-center">
                  Account must be approved to go online.
                </p>
              </form>
            </div>
          </div>

          <!-- Ride Requests -->
          <div class="xl:col-span-3">
            <div class="bg-white/90 backdrop-blur-sm border border-slate-200/80 rounded-2xl shadow-sm overflow-hidden">
              <div class="px-4 py-3 border-b border-slate-100 flex items-center justify-between gap-3">
                <div>
                  <h2 class="text-sm font-bold text-slate-800">Available Ride Requests</h2>
                  <p class="text-[10px] text-slate-500">Live requests for your vehicle type</p>
                </div>
                <div class="flex items-center gap-1.5">
                  <span class="rounded-md px-2 py-0.5 text-[10px] font-semibold" :class="driverProfile?.is_online ? 'bg-gradient-to-r from-indigo-500 to-violet-600 text-white' : 'bg-slate-100 text-slate-500'">
                    {{ driverProfile?.is_online ? 'Online' : 'Offline' }}
                  </span>
                  <button type="button" class="rounded-lg bg-slate-100 px-2.5 py-1.5 text-[10px] font-medium text-slate-600 hover:bg-slate-200" :disabled="loadingRequests" @click="loadAvailableRequests">
                    {{ loadingRequests ? '...' : 'Refresh' }}
                  </button>
                </div>
              </div>

              <div v-if="loadingRequests" class="p-4 space-y-2">
                <div v-for="index in 3" :key="index" class="h-16 rounded-lg bg-slate-100 animate-pulse"></div>
              </div>

              <div v-else-if="!rideRequests.length" class="p-4">
                <div class="rounded-lg border border-dashed border-slate-200 bg-slate-50 px-4 py-6 text-center">
                  <UIcon name="i-heroicons-map" class="h-8 w-8 mx-auto text-slate-300 mb-2" />
                  <div class="text-xs font-medium text-slate-600">No ride requests</div>
                  <div class="text-[10px] text-slate-400 mt-0.5">Go online to receive dispatch updates.</div>
                </div>
              </div>

              <div v-else class="divide-y divide-slate-100">
                <div v-for="ride in rideRequests" :key="ride.id" class="p-3">
                  <div class="flex items-start justify-between gap-3">
                    <div class="min-w-0 flex-1">
                      <div class="flex items-center gap-1.5 mb-1">
                        <span class="text-xs font-semibold text-slate-800 truncate">{{ ride.pickup_address }}</span>
                        <span class="rounded bg-indigo-100 text-indigo-700 px-1.5 py-0.5 text-[9px] font-semibold capitalize">{{ ride.requested_vehicle_type }}</span>
                      </div>
                      <div class="text-[10px] text-slate-500 truncate mb-2">→ {{ ride.drop_address }}</div>
                      <div class="flex items-center gap-3 text-[10px]">
                        <span class="font-bold text-indigo-600">৳{{ ride.fare_estimate }}</span>
                        <span class="text-slate-500">{{ ride.distance_km }} km</span>
                        <span class="text-slate-400">{{ formatDateTime(ride.requested_at) }}</span>
                      </div>
                    </div>
                    <button
                      type="button"
                      class="flex-shrink-0 rounded-lg bg-gradient-to-r from-indigo-500 to-violet-600 px-4 py-2 text-xs font-semibold text-white shadow-sm hover:from-indigo-600 hover:to-violet-700 disabled:opacity-50"
                      :disabled="acceptingRideId === ride.id"
                      @click="acceptRequest(ride)"
                    >
                      <span v-if="acceptingRideId === ride.id" class="h-3 w-3 animate-spin rounded-full border-2 border-white border-t-transparent"></span>
                      <span v-else>Accept</span>
                    </button>
                  </div>
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

const pageError = ref("");
const driverProfile = ref(null);
const earningsSummary = ref(null);
const rideRequests = ref([]);
const loadingRequests = ref(false);
const savingProfile = ref(false);
const togglingOnline = ref(false);
const acceptingRideId = ref(null);
let stopDispatchSocket = null;

const profileForm = ref({
  license_number: "",
  national_id_number: "",
  service_radius_km: 8,
});

const isApprovedDriver = computed(() => driverProfile.value?.approval_status === "approved");

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
    return "Disconnected";
  }
  if (dispatchConnectionState.value === "reconnecting") {
    return "Reconnecting";
  }
  if (dispatchConnectionState.value === "connecting") {
    return "Connecting";
  }
  return "Disconnected";
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
    pageError.value = result.message;
  }
};

const loadSummary = async () => {
  if (!isApprovedDriver.value) {
    earningsSummary.value = {
      total_trips: 0,
      total_earnings: "0.00",
    };
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
    pageError.value = result.message;
  }
  loadingRequests.value = false;
};

const saveProfile = async () => {
  savingProfile.value = true;
  pageError.value = "";
  const result = await updateDriverProfile({
    license_number: profileForm.value.license_number,
    national_id_number: profileForm.value.national_id_number,
    service_radius_km: profileForm.value.service_radius_km,
  });

  if (result.success) {
    driverProfile.value = result.data;
    toast.add({ title: "Profile updated", description: result.message, color: "gray" });
  } else {
    pageError.value = result.message;
    toast.add({ title: "Profile update failed", description: result.message, color: "red" });
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
    pageError.value = result.message;
    toast.add({ title: "Availability update failed", description: result.message, color: "red" });
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
    toast.add({ title: "Accept failed", description: result.message, color: "red" });
    pageError.value = result.message;
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
        color: "blue",
      });
    }
    if (payload?.type === "ride.event" && ["ride_accepted", "ride_cancelled"].includes(payload.event)) {
      loadAvailableRequests();
    }
  });
};

onMounted(async () => {
  await loadProfile();
  if (isApprovedDriver.value) {
    await loadSummary();
    await loadAvailableRequests();
    startDispatchSocket();
  } else {
    earningsSummary.value = {
      total_trips: 0,
      total_earnings: "0.00",
    };
    rideRequests.value = [];
  }
});

onBeforeUnmount(() => {
  if (stopDispatchSocket) {
    stopDispatchSocket();
  }
});
</script>
