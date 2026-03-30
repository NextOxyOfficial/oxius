<template>
  <PublicSection>
    <div class="min-h-screen py-4 sm:py-6 bg-gradient-to-br from-slate-50 via-white to-indigo-50/30">
      <UContainer class="max-w-7xl space-y-5">
        <!-- Header -->
        <div class="relative z-50 flex items-center justify-between gap-3 rounded-xl border border-slate-200/80 bg-white px-4 py-3 shadow-xs">
          <div class="flex items-center gap-3">
            <div class="flex h-10 w-10 items-center justify-center rounded-lg bg-gradient-to-br from-indigo-500 to-violet-600 text-white">
              <UIcon name="i-heroicons-clock" class="h-5 w-5" />
            </div>
            <div>
              <h1 class="text-base font-bold text-slate-800">Ride History</h1>
              <p class="text-[10px] text-slate-500">Review your past rides</p>
            </div>
          </div>
          <RideshareModeSwitch />
        </div>

        <RideshareNav current="history" />

        <div v-if="pageError" class="rounded-xl border border-red-200 bg-red-50 px-4 py-3 text-sm text-red-700">
          {{ pageError }}
        </div>

        <div v-if="loadingRides" class="space-y-4">
          <div v-for="index in 4" :key="index" class="h-24 rounded-xl bg-slate-100 animate-pulse"></div>
        </div>

        <div v-else-if="!rides.length" class="rounded-2xl border border-dashed border-slate-200 bg-white/90 px-6 py-10 text-center shadow-sm">
          <div class="flex h-14 w-14 mx-auto items-center justify-center rounded-xl bg-slate-100 text-slate-400 mb-4">
            <UIcon name="i-heroicons-clock" class="h-7 w-7" />
          </div>
          <div class="text-base font-semibold text-slate-700">No ride history found</div>
          <div class="text-sm text-slate-500 mt-1">Completed and cancelled rides will appear here.</div>
        </div>

        <div v-else class="bg-white/90 backdrop-blur-sm border border-slate-200/80 rounded-2xl shadow-sm overflow-hidden divide-y divide-slate-100">
          <div v-for="item in rides" :key="item.id" class="p-4">
            <div class="flex items-start justify-between gap-3">
              <div class="min-w-0 flex-1">
                <!-- Route -->
                <div class="flex items-center gap-2 mb-2">
                  <span class="text-sm font-semibold text-slate-800 truncate">{{ item.pickup_address }}</span>
                  <UIcon name="i-heroicons-arrow-right" class="h-3.5 w-3.5 text-slate-400 flex-shrink-0" />
                  <span class="text-sm text-slate-600 truncate">{{ item.drop_address }}</span>
                </div>
                <!-- Stats Row -->
                <div class="flex items-center gap-4 text-[11px]">
                  <span class="font-bold text-indigo-600">৳{{ item.final_fare || item.fare_estimate }}</span>
                  <span class="text-slate-500">{{ item.distance_km }} km</span>
                  <span class="text-slate-500">{{ formatEta(item.duration_seconds) }}</span>
                  <span class="text-slate-400">{{ formatDateTime(item.requested_at) }}</span>
                  <span v-if="asDriver" class="text-slate-500">Rider: {{ item.rider?.name || 'Unknown' }}</span>
                  <span v-else class="text-slate-500">Driver: {{ item.assigned_driver?.user?.name || 'Unassigned' }}</span>
                </div>
              </div>
              <!-- Status Badge -->
              <span
                class="flex-shrink-0 inline-flex items-center gap-1 rounded-lg px-2.5 py-1 text-[10px] font-semibold capitalize"
                :class="badgeClass(item.status)"
              >
                <UIcon :name="statusIcon(item.status)" class="h-3 w-3" />
                {{ item.status.replaceAll('_', ' ') }}
              </span>
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

const badgeClass = (status) => {
  if (status === "completed") {
    return "bg-emerald-100 text-emerald-700";
  }
  if (status === "cancelled") {
    return "bg-red-100 text-red-700";
  }
  return "bg-indigo-100 text-indigo-700";
};

const statusIcon = (status) => {
  if (status === "completed") {
    return "i-heroicons-check-circle";
  }
  if (status === "cancelled") {
    return "i-heroicons-x-circle";
  }
  return "i-heroicons-clock";
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
