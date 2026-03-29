<template>
  <PublicSection>
    <div class="min-h-screen py-8 bg-gradient-to-b from-gray-50 to-gray-100">
      <UContainer class="max-w-7xl">
        <div class="mb-6">
          <h1 class="text-2xl font-semibold text-gray-900">Active Trip</h1>
          <p class="text-sm text-gray-600 mt-2">Track live trip progress, ride status, and driver movement.</p>
        </div>

        <div class="mb-6">
          <RideshareNav current="active" />
        </div>

        <div v-if="pageError" class="mb-6 rounded-xl border border-red-200 bg-red-50 px-4 py-3 text-sm text-red-700">
          {{ pageError }}
        </div>

        <div v-if="loadingRide" class="space-y-4">
          <div class="h-24 rounded-xl bg-gray-100 animate-pulse"></div>
          <div class="h-[420px] rounded-xl bg-gray-100 animate-pulse"></div>
        </div>

        <div v-else-if="!ride" class="rounded-xl border border-dashed border-gray-200 bg-white px-6 py-10 text-center shadow-sm">
          <div class="text-lg font-semibold text-gray-900">No active trip</div>
          <div class="text-sm text-gray-500 mt-2">Create a new booking or wait for a driver assignment.</div>
          <div class="mt-5">
            <UButton to="/rideshare" color="emerald">Go to Booking</UButton>
          </div>
        </div>

        <div v-else class="space-y-6">
          <div class="grid grid-cols-1 md:grid-cols-4 gap-4">
            <div class="rounded-xl border border-gray-200 bg-white px-5 py-4 shadow-sm">
              <div class="text-xs uppercase tracking-wide text-gray-500 font-semibold">Status</div>
              <div class="mt-2 text-lg font-semibold text-gray-900 capitalize">{{ formatStatus(ride.status) }}</div>
            </div>
            <div class="rounded-xl border border-gray-200 bg-white px-5 py-4 shadow-sm">
              <div class="text-xs uppercase tracking-wide text-gray-500 font-semibold">Fare</div>
              <div class="mt-2 text-lg font-semibold text-emerald-700">৳{{ ride.final_fare || ride.fare_estimate }}</div>
            </div>
            <div class="rounded-xl border border-gray-200 bg-white px-5 py-4 shadow-sm">
              <div class="text-xs uppercase tracking-wide text-gray-500 font-semibold">Distance</div>
              <div class="mt-2 text-lg font-semibold text-gray-900">{{ ride.distance_km }} km</div>
            </div>
            <div class="rounded-xl border border-gray-200 bg-white px-5 py-4 shadow-sm">
              <div class="text-xs uppercase tracking-wide text-gray-500 font-semibold">Socket</div>
              <div class="mt-2 text-lg font-semibold text-gray-900 capitalize">{{ rideConnectionState }}</div>
            </div>
          </div>

          <div class="grid grid-cols-1 xl:grid-cols-5 gap-6">
            <div class="xl:col-span-3 space-y-6">
              <div class="bg-white border border-gray-200 rounded-xl shadow-sm overflow-hidden">
                <div class="px-5 py-4 border-b border-gray-100">
                  <h2 class="text-lg font-semibold text-gray-900">Live Map</h2>
                </div>
                <div class="p-4">
                  <ClientOnly>
                    <RideshareMap
                      :pickup="pickupPoint"
                      :drop="dropPoint"
                      :driver-location="driverPoint"
                      :route-geometry="ride.route_geometry"
                      active-selection="pickup"
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
                  <h2 class="text-lg font-semibold text-gray-900">Trip Timeline</h2>
                </div>
                <div class="p-5 space-y-4">
                  <div v-for="item in ride.status_history || []" :key="item.id" class="flex items-start gap-3">
                    <div class="w-3 h-3 rounded-full bg-emerald-500 mt-1.5"></div>
                    <div>
                      <div class="text-sm font-medium text-gray-900 capitalize">{{ formatStatus(item.status) }}</div>
                      <div class="text-xs text-gray-500 mt-1">{{ formatDateTime(item.created_at) }}</div>
                    </div>
                  </div>
                </div>
              </div>
            </div>

            <div class="xl:col-span-2 space-y-6">
              <div class="bg-white border border-gray-200 rounded-xl shadow-sm overflow-hidden">
                <div class="px-5 py-4 border-b border-gray-100">
                  <h2 class="text-lg font-semibold text-gray-900">Trip Details</h2>
                </div>
                <div class="p-5 space-y-4 text-sm">
                  <div>
                    <div class="text-xs uppercase tracking-wide text-gray-500 font-semibold">Pickup</div>
                    <div class="mt-1 text-gray-900">{{ ride.pickup_address }}</div>
                  </div>
                  <div>
                    <div class="text-xs uppercase tracking-wide text-gray-500 font-semibold">Drop</div>
                    <div class="mt-1 text-gray-900">{{ ride.drop_address }}</div>
                  </div>
                  <div v-if="ride.assigned_driver?.user">
                    <div class="text-xs uppercase tracking-wide text-gray-500 font-semibold">Driver</div>
                    <div class="mt-1 text-gray-900">
                      {{ ride.assigned_driver.user.name || ride.assigned_driver.user.username }}
                    </div>
                  </div>
                  <div>
                    <div class="text-xs uppercase tracking-wide text-gray-500 font-semibold">Vehicle Type</div>
                    <div class="mt-1 text-gray-900">{{ ride.requested_vehicle_type }}</div>
                  </div>
                </div>
              </div>

              <div class="bg-white border border-gray-200 rounded-xl shadow-sm overflow-hidden">
                <div class="px-5 py-4 border-b border-gray-100">
                  <h2 class="text-lg font-semibold text-gray-900">Actions</h2>
                </div>
                <div class="p-5 space-y-3">
                  <div v-if="isDriver" class="space-y-3">
                    <UButton
                      v-if="ride.status === 'accepted'"
                      color="blue"
                      block
                      :loading="updatingStatus"
                      @click="changeStatus('driver_arriving')"
                    >
                      Mark Driver Arriving
                    </UButton>
                    <UButton
                      v-if="ride.status === 'driver_arriving'"
                      color="emerald"
                      block
                      :loading="updatingStatus"
                      @click="changeStatus('in_progress')"
                    >
                      Start Trip
                    </UButton>
                    <div v-if="ride.status === 'in_progress'" class="space-y-3">
                      <UInput v-model="completionFare" type="number" min="0" step="0.01" placeholder="Final fare (optional)" />
                      <UButton color="emerald" block :loading="updatingStatus" @click="changeStatus('completed')">
                        Complete Trip
                      </UButton>
                    </div>
                  </div>

                  <UButton
                    v-if="canCancelRide"
                    color="red"
                    variant="soft"
                    block
                    :loading="cancellingRide"
                    @click="cancelCurrentRide"
                  >
                    Cancel Ride
                  </UButton>
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

const isDriver = computed(() => {
  return ride.value?.assigned_driver?.user?.id === user.value?.user?.id;
});

const canCancelRide = computed(() => {
  return ride.value && !["completed", "cancelled"].includes(ride.value.status);
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

  if (stopRideSocket) {
    stopRideSocket();
  }

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

const loadActiveRide = async () => {
  loadingRide.value = true;
  pageError.value = "";
  const result = await getActiveRide();
  if (result.success) {
    ride.value = result.data;
    if (ride.value) {
      completionFare.value = ride.value.final_fare || ride.value.fare_estimate || "";
      startRideSocket();
    }
  } else {
    pageError.value = result.message;
  }
  loadingRide.value = false;
};

const cancelCurrentRide = async () => {
  if (!ride.value) {
    return;
  }

  cancellingRide.value = true;
  const result = await cancelRide(ride.value.id, "Cancelled from active trip page");
  if (result.success) {
    toast.add({ title: "Ride cancelled", description: result.message, color: "green" });
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
    toast.add({ title: "Status updated", description: result.message, color: "green" });
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
});
</script>
