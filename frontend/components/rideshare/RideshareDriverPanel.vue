<template>
  <div class="space-y-5">
    <div v-if="driverNotice" class="rounded-2xl border border-gray-300 bg-white px-4 py-3 text-sm text-gray-700 shadow-sm">
      {{ driverNotice }}
    </div>

    <div class="grid grid-cols-1 gap-4 lg:grid-cols-4">
      <div class="rounded-2xl border border-gray-200 bg-white px-5 py-4 shadow-sm">
        <div class="text-xs font-semibold uppercase tracking-wide text-gray-500">Approval</div>
        <div class="mt-2 text-lg font-semibold capitalize text-gray-950">{{ driverProfile?.approval_status || 'pending' }}</div>
      </div>
      <div class="rounded-2xl border border-gray-200 bg-white px-5 py-4 shadow-sm">
        <div class="text-xs font-semibold uppercase tracking-wide text-gray-500">Trips</div>
        <div class="mt-2 text-lg font-semibold text-gray-950">{{ earningsSummary?.total_trips || 0 }}</div>
      </div>
      <div class="rounded-2xl border border-gray-200 bg-white px-5 py-4 shadow-sm">
        <div class="text-xs font-semibold uppercase tracking-wide text-gray-500">Earnings</div>
        <div class="mt-2 text-lg font-semibold text-gray-950">৳{{ earningsSummary?.total_earnings || '0.00' }}</div>
      </div>
      <div class="rounded-2xl border border-gray-200 bg-white px-5 py-4 shadow-sm">
        <div class="text-xs font-semibold uppercase tracking-wide text-gray-500">Updates</div>
        <div class="mt-2 text-lg font-semibold text-gray-950">{{ dispatchUpdatesStatus }}</div>
      </div>
    </div>

    <div class="grid grid-cols-1 gap-5 xl:grid-cols-5">
      <div class="space-y-5 xl:col-span-2">
        <div class="overflow-hidden rounded-2xl border border-gray-200 bg-white shadow-sm">
          <div class="border-b border-gray-200 bg-gray-50 px-5 py-4">
            <h2 class="text-base font-bold text-gray-950">Driver Profile</h2>
            <p class="mt-0.5 text-xs text-gray-500">Manage your approval-ready driver information.</p>
          </div>

          <form class="space-y-4 p-5" @submit.prevent="saveProfile">
            <div>
              <label class="mb-2 block text-sm font-medium text-gray-800">License Number</label>
              <UInput v-model="profileForm.license_number" placeholder="Driving license number" />
            </div>
            <div>
              <label class="mb-2 block text-sm font-medium text-gray-800">National ID Number</label>
              <UInput v-model="profileForm.national_id_number" placeholder="National ID" />
            </div>
            <div>
              <label class="mb-2 block text-sm font-medium text-gray-800">Service Radius (km)</label>
              <UInput v-model="profileForm.service_radius_km" type="number" min="1" step="0.1" />
            </div>
            <div class="flex flex-wrap gap-3">
              <UButton color="gray" :loading="savingProfile" type="submit">Save Profile</UButton>
              <UButton
                color="gray"
                variant="soft"
                type="button"
                :loading="togglingOnline"
                :disabled="!isApprovedDriver"
                @click="toggleOnlineStatus"
              >
                {{ driverProfile?.is_online ? 'Go Offline' : 'Go Online' }}
              </UButton>
            </div>
            <div class="flex flex-wrap gap-2 pt-1">
              <UButton to="/rideshare/vehicles" color="gray" variant="soft" size="sm">Manage Vehicles</UButton>
              <UButton to="/rideshare/active" color="gray" variant="soft" size="sm">Open Active Trip</UButton>
            </div>
          </form>
        </div>
      </div>

      <div class="xl:col-span-3">
        <div class="overflow-hidden rounded-2xl border border-gray-200 bg-white shadow-sm">
          <div class="flex items-center justify-between gap-4 border-b border-gray-200 bg-gray-50 px-5 py-4">
            <div>
              <h2 class="text-base font-bold text-gray-950">Available Ride Requests</h2>
              <p class="mt-1 text-sm text-gray-500">Live searchable ride requests for your driver type.</p>
            </div>
            <div class="flex items-center gap-2">
              <span class="rounded-full px-2.5 py-1 text-xs font-semibold"
                :class="driverProfile?.is_online ? 'bg-gray-950 text-white' : 'bg-gray-100 text-gray-500'"
              >
                {{ driverProfile?.is_online ? 'Online' : 'Offline' }}
              </span>
              <UButton color="gray" variant="soft" :loading="loadingRequests" @click="loadAvailableRequests">
                Refresh
              </UButton>
            </div>
          </div>

          <div v-if="!isApprovedDriver" class="p-6">
            <div class="rounded-2xl border border-dashed border-gray-300 bg-gray-50 px-4 py-8 text-center text-sm text-gray-600">
              Your driver account is still under review. Once approved, live requests and online mode will appear here.
            </div>
          </div>

          <div v-else-if="loadingRequests" class="space-y-3 p-6">
            <div v-for="index in 3" :key="index" class="h-28 animate-pulse rounded-2xl bg-gray-100"></div>
          </div>

          <div v-else-if="!rideRequests.length" class="p-6">
            <div class="rounded-2xl border border-dashed border-gray-300 bg-gray-50 px-4 py-8 text-center text-sm text-gray-500">
              No ride requests available right now. Go online and keep this page open for dispatch updates.
            </div>
          </div>

          <div v-else class="space-y-4 p-5">
            <div v-for="ride in rideRequests" :key="ride.id" class="rounded-2xl border border-gray-200 bg-white px-4 py-4">
              <div class="flex flex-col gap-4 md:flex-row md:items-start md:justify-between">
                <div class="space-y-2">
                  <div class="flex flex-wrap items-center gap-2">
                    <h3 class="text-base font-semibold text-gray-950">{{ ride.pickup_address }}</h3>
                    <span class="rounded-full bg-gray-100 px-2 py-1 text-xs font-semibold text-gray-700">
                      {{ ride.requested_vehicle_type }}
                    </span>
                  </div>
                  <div class="text-sm text-gray-600">To: {{ ride.drop_address }}</div>
                  <div class="grid grid-cols-2 gap-3 text-sm md:grid-cols-4">
                    <div>
                      <div class="text-xs font-semibold uppercase tracking-wide text-gray-500">Fare</div>
                      <div class="mt-1 font-semibold text-gray-950">৳{{ ride.fare_estimate }}</div>
                    </div>
                    <div>
                      <div class="text-xs font-semibold uppercase tracking-wide text-gray-500">Distance</div>
                      <div class="mt-1 text-gray-900">{{ ride.distance_km }} km</div>
                    </div>
                    <div>
                      <div class="text-xs font-semibold uppercase tracking-wide text-gray-500">Status</div>
                      <div class="mt-1 capitalize text-gray-900">{{ ride.status.replaceAll('_', ' ') }}</div>
                    </div>
                    <div>
                      <div class="text-xs font-semibold uppercase tracking-wide text-gray-500">Requested</div>
                      <div class="mt-1 text-gray-900">{{ formatDateTime(ride.requested_at) }}</div>
                    </div>
                  </div>
                </div>
                <div class="flex gap-2">
                  <UButton color="gray" :loading="acceptingRideId === ride.id" @click="acceptRequest(ride)">
                    Accept Ride
                  </UButton>
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
  await loadProfile();
  if (isApprovedDriver.value) {
    await loadSummary();
    await loadAvailableRequests();
    startDispatchSocket();
  }
});

onBeforeUnmount(() => {
  if (stopDispatchSocket) {
    stopDispatchSocket();
  }
});
</script>
