<template>
  <div class="min-h-screen bg-gradient-to-br from-slate-50 via-white to-indigo-50/30 py-4 sm:py-6">
    <UContainer class="max-w-7xl space-y-5">
      <!-- Header Card -->
      <div class="relative z-50 flex items-center justify-between gap-3 rounded-xl border border-slate-200/80 bg-white px-4 py-3 shadow-xs">
        <div class="flex items-center gap-3">
          <div class="flex h-10 w-10 items-center justify-center rounded-lg bg-gradient-to-br from-indigo-500 to-violet-600 text-white">
            <UIcon name="i-heroicons-map-pin" class="h-5 w-5" />
          </div>
          <div>
            <h1 class="text-base font-bold text-slate-800">Ride Share</h1>
            <p class="text-[10px] text-slate-500">Book rides or manage driver operations</p>
          </div>
        </div>
        <RideshareModeSwitch />
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
