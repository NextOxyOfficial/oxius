<template>
  <div class="min-h-screen bg-gradient-to-br from-slate-50 via-white to-indigo-50/30 py-4 sm:py-6">
    <UContainer class="max-w-7xl space-y-5">
      <!-- Header Card -->
      <div class="relative z-50 flex flex-col gap-4 rounded-xl border border-slate-200/80 bg-white px-4 py-3 shadow-xs sm:px-5 sm:py-4 lg:flex-row lg:items-center lg:justify-between">
        <div class="flex items-center gap-3">
          <div class="flex h-10 w-10 items-center justify-center rounded-lg bg-gradient-to-br from-indigo-500 to-violet-600 text-white">
            <UIcon name="i-heroicons-map-pin" class="h-5 w-5" />
          </div>
          <div>
            <h1 class="text-base font-bold text-slate-800">Ride Share</h1>
            <p class="text-xs text-slate-500 sm:text-sm">
              Book rides or manage driver operations
            </p>
          </div>
        </div>

        <!-- Mode Switch -->
        <div class="flex flex-col items-start gap-2 sm:items-end">
          <div class="text-[11px] font-semibold uppercase tracking-wider text-slate-400">Mode</div>
          <div class="inline-flex rounded-xl border border-slate-200 bg-slate-100/80 p-1">
            <button
              type="button"
              class="inline-flex items-center gap-2 rounded-lg px-4 py-2 text-sm font-semibold transition-all"
              :class="mode === 'passenger' ? 'bg-gradient-to-r from-indigo-500 to-violet-600 text-white shadow-sm' : 'text-slate-500 hover:text-slate-700'"
              @click="mode = 'passenger'"
            >
              <UIcon name="i-heroicons-user" class="h-4 w-4" />
              <span>Passenger</span>
            </button>
            <button
              type="button"
              class="inline-flex items-center gap-2 rounded-lg px-4 py-2 text-sm font-semibold transition-all"
              :class="mode === 'driver' ? 'bg-gradient-to-r from-indigo-500 to-violet-600 text-white shadow-sm' : 'text-slate-500 hover:text-slate-700'"
              @click="mode = 'driver'"
            >
              <UIcon name="i-heroicons-identification" class="h-4 w-4" />
              <span>Driver</span>
            </button>
          </div>
        </div>
      </div>

      <RideshareNav :current="mode === 'driver' ? 'driver' : 'booking'" />

      <div v-if="mode === 'passenger'">
        <RidesharePassengerPanel />
      </div>
      <div v-else>
        <RideshareDriverPanel />
      </div>
    </UContainer>
  </div>
</template>

<script setup>
const modeCookie = useCookie("rideshare-mode", {
  default: () => "passenger",
  maxAge: 60 * 60 * 24 * 30,
});

const mode = computed({
  get: () => (modeCookie.value === "driver" ? "driver" : "passenger"),
  set: (value) => {
    modeCookie.value = value === "driver" ? "driver" : "passenger";
  },
});
</script>
