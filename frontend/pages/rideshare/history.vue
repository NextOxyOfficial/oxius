<template>
  <PublicSection>
    <div class="min-h-screen py-4 sm:py-8 bg-gradient-to-b from-gray-50 to-gray-100">
      <UContainer class="max-w-7xl">
        <div class="mb-6">
          <h1 class="text-2xl font-semibold text-gray-900">Ride History</h1>
          <p class="text-sm text-gray-600 mt-2">Review past rides for rider and driver activity.</p>
        </div>

        <div class="mb-6">
          <RideshareNav current="history" />
        </div>

        <div class="mb-6 flex flex-wrap gap-3">
          <UButton :color="asDriver ? 'gray' : 'emerald'" :variant="asDriver ? 'soft' : 'solid'" @click="setMode(false)">
            Rider History
          </UButton>
          <UButton :color="asDriver ? 'emerald' : 'gray'" :variant="asDriver ? 'solid' : 'soft'" @click="setMode(true)">
            Driver History
          </UButton>
        </div>

        <div v-if="pageError" class="mb-6 rounded-xl border border-red-200 bg-red-50 px-4 py-3 text-sm text-red-700">
          {{ pageError }}
        </div>

        <div v-if="loadingRides" class="space-y-4">
          <div v-for="index in 4" :key="index" class="h-24 rounded-xl bg-gray-100 animate-pulse"></div>
        </div>

        <div v-else-if="!rides.length" class="rounded-xl border border-dashed border-gray-200 bg-white px-6 py-10 text-center shadow-sm">
          <div class="text-lg font-semibold text-gray-900">No ride history found</div>
          <div class="text-sm text-gray-500 mt-2">Completed and cancelled rides will appear here.</div>
        </div>

        <div v-else class="space-y-4">
          <div v-for="item in rides" :key="item.id" class="rounded-xl border border-gray-200 bg-white px-5 py-5 shadow-sm">
            <div class="flex flex-col lg:flex-row lg:items-start lg:justify-between gap-5">
              <div class="space-y-3 flex-1">
                <div class="flex items-center gap-2 flex-wrap">
                  <h3 class="text-base font-semibold text-gray-900">{{ item.pickup_address }}</h3>
                  <span class="text-gray-400">→</span>
                  <div class="text-base font-medium text-gray-700">{{ item.drop_address }}</div>
                  <UBadge :color="badgeColor(item.status)" variant="soft">{{ item.status.replaceAll('_', ' ') }}</UBadge>
                </div>
                <div class="grid grid-cols-2 md:grid-cols-5 gap-3 text-sm">
                  <div>
                    <div class="text-xs uppercase tracking-wide text-gray-500 font-semibold">Fare</div>
                    <div class="mt-1 text-emerald-700 font-semibold">৳{{ item.final_fare || item.fare_estimate }}</div>
                  </div>
                  <div>
                    <div class="text-xs uppercase tracking-wide text-gray-500 font-semibold">Distance</div>
                    <div class="mt-1 text-gray-900">{{ item.distance_km }} km</div>
                  </div>
                  <div>
                    <div class="text-xs uppercase tracking-wide text-gray-500 font-semibold">ETA</div>
                    <div class="mt-1 text-gray-900">{{ formatEta(item.duration_seconds) }}</div>
                  </div>
                  <div>
                    <div class="text-xs uppercase tracking-wide text-gray-500 font-semibold">Requested</div>
                    <div class="mt-1 text-gray-900">{{ formatDateTime(item.requested_at) }}</div>
                  </div>
                  <div>
                    <div class="text-xs uppercase tracking-wide text-gray-500 font-semibold">Payment</div>
                    <div class="mt-1 text-gray-900 capitalize">{{ item.payment_status }}</div>
                  </div>
                </div>
              </div>

              <div class="min-w-[220px] rounded-xl bg-gray-50 border border-gray-100 px-4 py-4 text-sm">
                <div class="text-xs uppercase tracking-wide text-gray-500 font-semibold mb-2">
                  {{ asDriver ? 'Rider' : 'Driver' }}
                </div>
                <div v-if="asDriver" class="text-gray-900">
                  {{ item.rider?.name || item.rider?.username || 'Unknown rider' }}
                </div>
                <div v-else class="text-gray-900">
                  {{ item.assigned_driver?.user?.name || item.assigned_driver?.user?.username || 'Unassigned' }}
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

const { listRides } = useRideshare();

const loadingRides = ref(true);
const pageError = ref("");
const rides = ref([]);
const asDriver = ref(false);

const badgeColor = (status) => {
  if (status === "completed") {
    return "emerald";
  }
  if (status === "cancelled") {
    return "red";
  }
  return "blue";
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

const formatDateTime = (value) => {
  return new Date(value).toLocaleString(undefined, {
    month: "short",
    day: "numeric",
    hour: "numeric",
    minute: "2-digit",
  });
};

const loadRides = async () => {
  loadingRides.value = true;
  pageError.value = "";
  const result = await listRides(asDriver.value ? { as_driver: true } : {});
  if (result.success) {
    rides.value = (result.data || []).filter((item) => ["completed", "cancelled"].includes(item.status));
  } else {
    pageError.value = result.message;
  }
  loadingRides.value = false;
};

const setMode = async (driverMode) => {
  asDriver.value = driverMode;
  await loadRides();
};

onMounted(() => {
  loadRides();
});
</script>
