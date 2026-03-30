<template>
  <PublicSection>
    <div class="min-h-screen py-4 sm:py-8 bg-gradient-to-b from-gray-50 to-gray-100">
      <UContainer class="max-w-7xl">
        <div class="mb-6">
          <h1 class="text-2xl font-semibold text-gray-900">Driver Dashboard</h1>
          <p class="text-sm text-gray-600 mt-2">Manage driver profile, availability, and live ride requests.</p>
        </div>

        <div class="mb-6">
          <RideshareNav current="driver" />
        </div>

        <div v-if="pageError" class="mb-6 rounded-xl border border-red-200 bg-red-50 px-4 py-3 text-sm text-red-700">
          {{ pageError }}
        </div>

        <div class="space-y-6">
          <div class="grid grid-cols-1 lg:grid-cols-4 gap-4">
            <div class="rounded-xl border border-gray-200 bg-white px-5 py-4 shadow-sm">
              <div class="text-xs uppercase tracking-wide text-gray-500 font-semibold">Approval</div>
              <div class="mt-2 text-lg font-semibold text-gray-900 capitalize">{{ driverProfile?.approval_status || 'pending' }}</div>
            </div>
            <div class="rounded-xl border border-gray-200 bg-white px-5 py-4 shadow-sm">
              <div class="text-xs uppercase tracking-wide text-gray-500 font-semibold">Trips</div>
              <div class="mt-2 text-lg font-semibold text-gray-900">{{ earningsSummary?.total_trips || 0 }}</div>
            </div>
            <div class="rounded-xl border border-gray-200 bg-white px-5 py-4 shadow-sm">
              <div class="text-xs uppercase tracking-wide text-gray-500 font-semibold">Earnings</div>
              <div class="mt-2 text-lg font-semibold text-emerald-700">৳{{ earningsSummary?.total_earnings || '0.00' }}</div>
            </div>
            <div class="rounded-xl border border-gray-200 bg-white px-5 py-4 shadow-sm">
              <div class="text-xs uppercase tracking-wide text-gray-500 font-semibold">Updates</div>
              <div class="mt-2 text-lg font-semibold text-gray-900">{{ dispatchUpdatesStatus }}</div>
            </div>
          </div>

          <div class="grid grid-cols-1 xl:grid-cols-5 gap-6">
            <div class="xl:col-span-2 space-y-6">
              <div class="bg-white border border-gray-200 rounded-xl shadow-sm overflow-hidden">
                <div class="px-5 py-4 border-b border-gray-100">
                  <h2 class="text-lg font-semibold text-gray-900">Driver Profile</h2>
                </div>

                <form class="p-5 space-y-4" @submit.prevent="saveProfile">
                  <div>
                    <label class="block text-sm font-medium text-gray-800 mb-2">License Number</label>
                    <UInput v-model="profileForm.license_number" placeholder="Driving license number" />
                  </div>
                  <div>
                    <label class="block text-sm font-medium text-gray-800 mb-2">National ID Number</label>
                    <UInput v-model="profileForm.national_id_number" placeholder="National ID" />
                  </div>
                  <div>
                    <label class="block text-sm font-medium text-gray-800 mb-2">Service Radius (km)</label>
                    <UInput v-model="profileForm.service_radius_km" type="number" min="1" step="0.1" />
                  </div>
                  <div class="flex flex-wrap gap-3">
                    <UButton color="emerald" :loading="savingProfile" type="submit">Save Profile</UButton>
                    <UButton
                      color="primary"
                      variant="soft"
                      :loading="togglingOnline"
                      :disabled="driverProfile?.approval_status !== 'approved'"
                      @click="toggleOnlineStatus"
                    >
                      {{ driverProfile?.is_online ? 'Go Offline' : 'Go Online' }}
                    </UButton>
                  </div>
                  <p v-if="driverProfile?.approval_status !== 'approved'" class="text-xs text-amber-700">
                    Your driver account must be approved before you can go online.
                  </p>
                </form>
              </div>
            </div>

            <div class="xl:col-span-3">
              <div class="bg-white border border-gray-200 rounded-xl shadow-sm overflow-hidden">
                <div class="px-5 py-4 border-b border-gray-100 flex items-center justify-between gap-4">
                  <div>
                    <h2 class="text-lg font-semibold text-gray-900">Available Ride Requests</h2>
                    <p class="text-sm text-gray-500 mt-1">Live list of searchable ride requests for this driver type.</p>
                  </div>
                  <div class="flex items-center gap-2">
                    <UBadge :color="driverProfile?.is_online ? 'emerald' : 'gray'" variant="soft">
                      {{ driverProfile?.is_online ? 'Online' : 'Offline' }}
                    </UBadge>
                    <UButton color="gray" variant="soft" :loading="loadingRequests" @click="loadAvailableRequests">
                      Refresh
                    </UButton>
                  </div>
                </div>

                <div v-if="loadingRequests" class="p-6 space-y-3">
                  <div v-for="index in 3" :key="index" class="h-28 rounded-xl bg-gray-100 animate-pulse"></div>
                </div>

                <div v-else-if="!rideRequests.length" class="p-6">
                  <div class="rounded-xl border border-dashed border-gray-200 bg-gray-50 px-4 py-8 text-center text-sm text-gray-500">
                    No ride requests available right now. Go online and keep this page open for dispatch updates.
                  </div>
                </div>

                <div v-else class="p-5 space-y-4">
                  <div v-for="ride in rideRequests" :key="ride.id" class="rounded-xl border border-gray-200 bg-white px-4 py-4">
                    <div class="flex flex-col md:flex-row md:items-start md:justify-between gap-4">
                      <div class="space-y-2">
                        <div class="flex items-center gap-2 flex-wrap">
                          <h3 class="text-base font-semibold text-gray-900">{{ ride.pickup_address }}</h3>
                          <UBadge color="blue" variant="soft">{{ ride.requested_vehicle_type }}</UBadge>
                        </div>
                        <div class="text-sm text-gray-600">To: {{ ride.drop_address }}</div>
                        <div class="grid grid-cols-2 md:grid-cols-4 gap-3 text-sm">
                          <div>
                            <div class="text-xs uppercase tracking-wide text-gray-500 font-semibold">Fare</div>
                            <div class="mt-1 text-emerald-700 font-semibold">৳{{ ride.fare_estimate }}</div>
                          </div>
                          <div>
                            <div class="text-xs uppercase tracking-wide text-gray-500 font-semibold">Distance</div>
                            <div class="mt-1 text-gray-900">{{ ride.distance_km }} km</div>
                          </div>
                          <div>
                            <div class="text-xs uppercase tracking-wide text-gray-500 font-semibold">Status</div>
                            <div class="mt-1 text-gray-900 capitalize">{{ ride.status.replaceAll('_', ' ') }}</div>
                          </div>
                          <div>
                            <div class="text-xs uppercase tracking-wide text-gray-500 font-semibold">Requested</div>
                            <div class="mt-1 text-gray-900">{{ formatDateTime(ride.requested_at) }}</div>
                          </div>
                        </div>
                      </div>

                      <div class="flex gap-2">
                        <UButton color="emerald" :loading="acceptingRideId === ride.id" @click="acceptRequest(ride)">
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
    toast.add({ title: "Profile updated", description: result.message, color: "green" });
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
    toast.add({ title: "Availability updated", description: result.message, color: "green" });
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
    toast.add({ title: "Ride accepted", description: result.message, color: "green" });
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
