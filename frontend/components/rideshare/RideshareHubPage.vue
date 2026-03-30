<template>
  <div class="min-h-screen bg-gradient-to-b from-gray-50 to-gray-100 py-4 sm:py-8">
    <UContainer class="max-w-7xl space-y-5">
      <div class="flex flex-col gap-4 rounded-3xl border border-gray-200 bg-white px-4 py-4 shadow-sm sm:px-6 sm:py-5 lg:flex-row lg:items-center lg:justify-between">
        <div class="flex items-center gap-3">
          <div class="flex h-11 w-11 items-center justify-center rounded-2xl bg-gray-950 text-white shadow-sm">
            <UIcon name="i-heroicons-map-pin" class="h-5 w-5" />
          </div>
          <div>
            <h1 class="text-xl font-bold text-gray-950 sm:text-2xl">Ride Share</h1>
            <p class="mt-1 text-xs text-gray-500 sm:text-sm">
              Switch between passenger booking and driver operations from one clean workspace.
            </p>
          </div>
        </div>

        <div class="flex flex-col items-start gap-2 sm:items-end">
          <div class="text-[11px] font-semibold uppercase tracking-[0.18em] text-gray-400">Mode</div>
          <div class="inline-flex rounded-2xl border border-gray-200 bg-gray-100 p-1 shadow-inner">
            <button
              type="button"
              class="inline-flex items-center gap-2 rounded-xl px-4 py-2 text-sm font-semibold transition-all"
              :class="mode === 'passenger' ? 'bg-white text-gray-950 shadow-sm' : 'text-gray-500 hover:text-gray-800'"
              @click="mode = 'passenger'"
            >
              <UIcon name="i-heroicons-user" class="h-4 w-4" />
              <span>Passenger Mode</span>
            </button>
            <button
              type="button"
              class="inline-flex items-center gap-2 rounded-xl px-4 py-2 text-sm font-semibold transition-all"
              :class="mode === 'driver' ? 'bg-gray-950 text-white shadow-sm' : 'text-gray-500 hover:text-gray-800'"
              @click="mode = 'driver'"
            >
              <UIcon name="i-heroicons-identification" class="h-4 w-4" />
              <span>Driver Mode</span>
            </button>
          </div>
        </div>
      </div>

      <RideshareNav :current="mode === 'driver' ? 'driver' : 'booking'" :mode="mode" />

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
