<template>
  <PublicSection>
    <div class="min-h-screen py-4 sm:py-6 bg-gradient-to-br from-slate-50 via-white to-indigo-50/30">
      <UContainer class="max-w-7xl space-y-5">
        <!-- Header -->
        <div class="relative z-50 flex items-center justify-between gap-3 rounded-xl border border-slate-200/80 bg-white px-4 py-3 shadow-xs">
          <div class="flex items-center gap-3">
            <div class="flex h-10 w-10 items-center justify-center rounded-lg bg-gradient-to-br from-indigo-500 to-violet-600 text-white">
              <UIcon name="i-heroicons-bolt" class="h-5 w-5" />
            </div>
            <div>
              <h1 class="text-base font-bold text-slate-800">Active Trip</h1>
              <p class="text-[10px] text-slate-500">Track live trip progress</p>
            </div>
          </div>
          <RideshareModeSwitch />
        </div>

        <RideshareNav current="active" />

        <div v-if="pageError" class="rounded-xl border border-red-200 bg-red-50 px-4 py-3 text-sm text-red-700">
          {{ pageError }}
        </div>

        <div v-if="loadingRide" class="space-y-3">
          <div class="h-20 rounded-xl bg-slate-100 animate-pulse"></div>
          <div class="h-[320px] rounded-xl bg-slate-100 animate-pulse"></div>
        </div>

        <div v-else-if="!ride" class="rounded-xl border border-dashed border-slate-200 bg-white px-5 py-8 text-center">
          <div class="flex h-12 w-12 mx-auto items-center justify-center rounded-xl bg-slate-100 text-slate-400 mb-3">
            <UIcon name="i-heroicons-bolt" class="h-6 w-6" />
          </div>
          <div class="text-sm font-semibold text-slate-700">No active trip</div>
          <div class="text-xs text-slate-500 mt-1">Create a new booking or wait for driver assignment.</div>
          <div class="mt-4">
            <NuxtLink to="/rideshare" class="inline-flex items-center gap-1.5 rounded-lg bg-gradient-to-r from-indigo-500 to-violet-600 px-4 py-2 text-xs font-semibold text-white shadow-sm transition-all hover:from-indigo-600 hover:to-violet-700">
              Go to Booking
            </NuxtLink>
          </div>
        </div>

        <div v-else class="space-y-4">
          <!-- Stats Row - Single Card -->
          <div class="rounded-xl border border-slate-200/80 bg-white shadow-xs overflow-hidden">
            <div class="flex items-center divide-x divide-slate-100">
              <div class="flex-1 px-4 py-3 text-center">
                <div class="text-[10px] font-semibold uppercase tracking-wide text-slate-400">Status</div>
                <div class="mt-0.5 text-sm font-bold text-slate-800 capitalize">{{ formatStatus(ride.status) }}</div>
              </div>
              <div class="flex-1 px-4 py-3 text-center">
                <div class="text-[10px] font-semibold uppercase tracking-wide text-slate-400">Fare</div>
                <div class="mt-0.5 text-sm font-bold text-indigo-600">৳{{ ride.final_fare || ride.fare_estimate }}</div>
              </div>
              <div class="flex-1 px-4 py-3 text-center">
                <div class="text-[10px] font-semibold uppercase tracking-wide text-slate-400">Distance</div>
                <div class="mt-0.5 text-sm font-bold text-slate-800">{{ ride.distance_km }} km</div>
              </div>
              <div class="flex-1 px-4 py-3 text-center">
                <div class="text-[10px] font-semibold uppercase tracking-wide text-slate-400">Updates</div>
                <div class="mt-0.5 text-sm font-bold" :class="rideUpdatesStatus === 'Live' ? 'text-emerald-600' : 'text-slate-800'">{{ rideUpdatesStatus }}</div>
              </div>
            </div>
          </div>

          <div class="grid grid-cols-1 xl:grid-cols-5 gap-4">
            <!-- Map & Timeline -->
            <div class="xl:col-span-3 space-y-4">
              <div class="bg-white border border-slate-200/80 rounded-xl shadow-xs overflow-hidden">
                <div class="px-3 py-2 border-b border-slate-100">
                  <h2 class="text-xs font-bold text-slate-800">Live Map</h2>
                </div>
                <div class="p-1.5 sm:p-2">
                  <ClientOnly>
                    <RideshareMap
                      :pickup="pickupPoint"
                      :drop="dropPoint"
                      :driver-location="driverPoint"
                      :route-geometry="ride.route_geometry"
                      active-selection="pickup"
                      height="min(48vh, 360px)"
                    />
                    <template #fallback>
                      <div class="h-[280px] rounded-lg border border-slate-200 bg-slate-50 flex items-center justify-center text-xs text-slate-400">
                        Loading map...
                      </div>
                    </template>
                  </ClientOnly>
                </div>
              </div>

              <div class="bg-white border border-slate-200/80 rounded-xl shadow-xs overflow-hidden">
                <div class="px-3 py-2 border-b border-slate-100">
                  <h2 class="text-xs font-bold text-slate-800">Trip Timeline</h2>
                </div>
                <div class="p-3 space-y-2">
                  <div v-for="item in ride.status_history || []" :key="item.id" class="flex items-start gap-2">
                    <div class="w-2 h-2 rounded-full bg-gradient-to-br from-indigo-500 to-violet-600 mt-1"></div>
                    <div>
                      <div class="text-xs font-semibold text-slate-700 capitalize">{{ formatStatus(item.status) }}</div>
                      <div class="text-[10px] text-slate-400">{{ formatDateTime(item.created_at) }}</div>
                    </div>
                  </div>
                </div>
              </div>
            </div>

            <!-- Details & Actions -->
            <div class="xl:col-span-2 space-y-4">
              <div class="bg-white border border-slate-200/80 rounded-xl shadow-xs overflow-hidden">
                <div class="px-3 py-2 border-b border-slate-100">
                  <h2 class="text-xs font-bold text-slate-800">Trip Details</h2>
                </div>
                <div class="p-3 space-y-2.5 text-xs">
                  <div class="rounded-lg bg-slate-50 px-2.5 py-2">
                    <div class="text-[10px] text-slate-400 font-medium">Pickup</div>
                    <div class="text-slate-700 font-semibold truncate">{{ ride.pickup_address }}</div>
                  </div>
                  <div class="rounded-lg bg-slate-50 px-2.5 py-2">
                    <div class="text-[10px] text-slate-400 font-medium">Drop</div>
                    <div class="text-slate-700 font-semibold truncate">{{ ride.drop_address }}</div>
                  </div>
                  <div v-if="ride.assigned_driver?.user" class="rounded-lg bg-slate-50 px-2.5 py-2">
                    <div class="text-[10px] text-slate-400 font-medium">Driver</div>
                    <div class="text-slate-700 font-semibold">
                      {{ ride.assigned_driver.user.name || ride.assigned_driver.user.username }}
                    </div>
                  </div>
                  <div class="rounded-lg bg-slate-50 px-2.5 py-2">
                    <div class="text-[10px] text-slate-400 font-medium">Vehicle Type</div>
                    <div class="text-slate-700 font-semibold capitalize">{{ ride.requested_vehicle_type }}</div>
                  </div>
                </div>
              </div>

              <div class="bg-white border border-slate-200/80 rounded-xl shadow-xs overflow-hidden">
                <div class="px-3 py-2 border-b border-slate-100">
                  <h2 class="text-xs font-bold text-slate-800">Actions</h2>
                </div>
                <div class="p-3 space-y-2">
                  <div v-if="isDriver" class="space-y-2">
                    <button
                      v-if="ride.status === 'accepted'"
                      type="button"
                      class="w-full rounded-lg bg-gradient-to-r from-indigo-500 to-violet-600 px-4 py-2.5 text-xs font-semibold text-white shadow-sm transition-all hover:from-indigo-600 hover:to-violet-700 disabled:opacity-50"
                      :disabled="updatingStatus"
                      @click="changeStatus('driver_arriving')"
                    >
                      <span v-if="updatingStatus" class="inline-flex items-center gap-1.5">
                        <span class="h-3 w-3 animate-spin rounded-full border-2 border-white border-t-transparent"></span>
                        Updating...
                      </span>
                      <span v-else>Mark Driver Arriving</span>
                    </button>
                    <button
                      v-if="ride.status === 'driver_arriving'"
                      type="button"
                      class="w-full rounded-lg bg-gradient-to-r from-indigo-500 to-violet-600 px-4 py-2.5 text-xs font-semibold text-white shadow-sm transition-all hover:from-indigo-600 hover:to-violet-700 disabled:opacity-50"
                      :disabled="updatingStatus"
                      @click="changeStatus('in_progress')"
                    >
                      <span v-if="updatingStatus" class="inline-flex items-center gap-1.5">
                        <span class="h-3 w-3 animate-spin rounded-full border-2 border-white border-t-transparent"></span>
                        Starting...
                      </span>
                      <span v-else>Start Trip</span>
                    </button>
                    <div v-if="ride.status === 'in_progress'" class="space-y-2">
                      <UInput v-model="completionFare" type="number" min="0" step="0.01" placeholder="Final fare (optional)" size="sm" />
                      <button
                        type="button"
                        class="w-full rounded-lg bg-gradient-to-r from-emerald-500 to-teal-600 px-4 py-2.5 text-xs font-semibold text-white shadow-sm transition-all hover:from-emerald-600 hover:to-teal-700 disabled:opacity-50"
                        :disabled="updatingStatus"
                        @click="changeStatus('completed')"
                      >
                        <span v-if="updatingStatus" class="inline-flex items-center gap-1.5">
                          <span class="h-3 w-3 animate-spin rounded-full border-2 border-white border-t-transparent"></span>
                          Completing...
                        </span>
                        <span v-else>Complete Trip</span>
                      </button>
                    </div>
                  </div>

                  <button
                    v-if="canCancelRide"
                    type="button"
                    class="w-full rounded-lg bg-red-50 px-4 py-2.5 text-xs font-semibold text-red-600 transition-all hover:bg-red-100 disabled:opacity-50"
                    :disabled="cancellingRide"
                    @click="cancelCurrentRide"
                  >
                    <span v-if="cancellingRide" class="inline-flex items-center gap-1.5">
                      <span class="h-3 w-3 animate-spin rounded-full border-2 border-red-600 border-t-transparent"></span>
                      Cancelling...
                    </span>
                    <span v-else>Cancel Ride</span>
                  </button>
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
const { user } = useAuth();
const { getActiveRide, cancelRide, updateRideStatus } = useRideshare();
const { rideConnectionState, connectRideSocket } = useRideshareSocket();

const loadingRide = ref(true);
const pageError = ref("");
const ride = ref(null);
const updatingStatus = ref(false);
const cancellingRide = ref(false);
const completionFare = ref("");
let stopRideSocket = null;
let connectedRideId = null;

const isDriver = computed(() => {
  return ride.value?.assigned_driver?.user?.id === user.value?.user?.id;
});

const canCancelRide = computed(() => {
  return ride.value && !["completed", "cancelled"].includes(ride.value.status);
});

const rideUpdatesStatus = computed(() => {
  if (rideConnectionState.value === "connected") {
    return "Live";
  }
  if (["failed", "error", "closed"].includes(rideConnectionState.value)) {
    return "Disconnected";
  }
  if (rideConnectionState.value === "reconnecting") {
    return "Reconnecting";
  }
  if (rideConnectionState.value === "connecting") {
    return "Connecting";
  }
  return "Disconnected";
});

const pickupPoint = computed(() => {
  if (!ride.value) {
    return null;
  }

  return {
    name: ride.value.pickup_address,
    latitude: Number(ride.value.pickup_latitude),
    longitude: Number(ride.value.pickup_longitude),
  };
});

const dropPoint = computed(() => {
  if (!ride.value) {
    return null;
  }

  return {
    name: ride.value.drop_address,
    latitude: Number(ride.value.drop_latitude),
    longitude: Number(ride.value.drop_longitude),
  };
});

const driverPoint = computed(() => {
  if (!ride.value?.latest_driver_location) {
    return null;
  }

  return {
    name: "Driver",
    latitude: Number(ride.value.latest_driver_location.latitude),
    longitude: Number(ride.value.latest_driver_location.longitude),
  };
});

const formatStatus = (value) => {
  return String(value || "").replaceAll("_", " ");
};

const formatDateTime = (value) => {
  return new Date(value).toLocaleString(undefined, {
    month: "short",
    day: "numeric",
    hour: "numeric",
    minute: "2-digit",
  });
};

const startRideSocket = () => {
  if (!ride.value?.id) {
    return;
  }

  if (connectedRideId === ride.value.id && stopRideSocket) {
    return;
  }

  if (stopRideSocket) {
    stopRideSocket();
  }

  connectedRideId = ride.value.id;
  stopRideSocket = connectRideSocket(ride.value.id, (payload) => {
    if (payload?.type === "driver.location") {
      ride.value = {
        ...ride.value,
        latest_driver_location: {
          latitude: payload.latitude,
          longitude: payload.longitude,
          heading: payload.heading,
          speed_kph: payload.speed_kph,
          accuracy_meters: payload.accuracy_meters,
          recorded_at: payload.recorded_at,
        },
      };
    }

    if (payload?.type === "ride.event") {
      loadActiveRide();
    }
  });
};

const loadActiveRide = async (silent = false) => {
  if (!silent) {
    loadingRide.value = true;
  }
  pageError.value = "";
  const result = await getActiveRide();
  if (result.success) {
    ride.value = result.data;
    if (ride.value) {
      completionFare.value = ride.value.final_fare || ride.value.fare_estimate || "";
      startRideSocket();
    } else {
      connectedRideId = null;
      if (stopRideSocket) {
        stopRideSocket();
        stopRideSocket = null;
      }
    }
  } else {
    pageError.value = result.message;
  }
  if (!silent) {
    loadingRide.value = false;
  }
};

const cancelCurrentRide = async () => {
  if (!ride.value) {
    return;
  }

  cancellingRide.value = true;
  const result = await cancelRide(ride.value.id, "Cancelled from active trip page");
  if (result.success) {
    toast.add({ title: "Ride cancelled", description: result.message, color: "gray" });
    await loadActiveRide();
  } else {
    pageError.value = result.message;
    toast.add({ title: "Cancel failed", description: result.message, color: "red" });
  }
  cancellingRide.value = false;
};

const changeStatus = async (status) => {
  if (!ride.value) {
    return;
  }

  updatingStatus.value = true;
  const result = await updateRideStatus(
    ride.value.id,
    status,
    status === "completed" ? completionFare.value : undefined
  );

  if (result.success) {
    toast.add({ title: "Status updated", description: result.message, color: "gray" });
    await loadActiveRide();
  } else {
    pageError.value = result.message;
    toast.add({ title: "Status update failed", description: result.message, color: "red" });
  }

  updatingStatus.value = false;
};

onMounted(() => {
  loadActiveRide();
});

onBeforeUnmount(() => {
  if (stopRideSocket) {
    stopRideSocket();
  }
  connectedRideId = null;
});
</script>
