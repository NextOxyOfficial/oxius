<template>
  <div class="relative z-[100]">
    <button
      type="button"
      class="inline-flex items-center gap-1.5 rounded-lg border border-slate-200 bg-white px-3 py-1.5 text-xs font-semibold text-slate-700 shadow-sm transition-all hover:bg-slate-50"
      @click="toggleDropdown"
    >
      <UIcon :name="mode === 'driver' ? 'i-heroicons-identification' : 'i-heroicons-user'" class="h-3.5 w-3.5 text-indigo-500" />
      <span>{{ mode === 'driver' ? 'Driver' : 'Passenger' }}</span>
      <UIcon name="i-heroicons-chevron-down" class="h-3 w-3 text-slate-400" />
    </button>
    
    <div
      v-if="dropdownOpen"
      class="absolute right-0 top-full z-50 mt-1 w-36 overflow-hidden rounded-lg border border-slate-200 bg-white shadow-lg"
    >
      <button
        type="button"
        class="flex w-full items-center gap-2 px-3 py-2 text-left text-xs font-medium transition-colors"
        :class="mode === 'passenger' ? 'bg-gradient-to-r from-indigo-500 to-violet-600 text-white' : 'text-slate-600 hover:bg-slate-50'"
        @click="selectMode('passenger')"
      >
        <UIcon name="i-heroicons-user" class="h-3.5 w-3.5" />
        <span>Passenger</span>
      </button>
      <button
        type="button"
        class="flex w-full items-center gap-2 px-3 py-2 text-left text-xs font-medium transition-colors"
        :class="mode === 'driver' ? 'bg-gradient-to-r from-indigo-500 to-violet-600 text-white' : 'text-slate-600 hover:bg-slate-50'"
        @click="selectMode('driver')"
      >
        <UIcon name="i-heroicons-identification" class="h-3.5 w-3.5" />
        <span>Driver</span>
      </button>
    </div>
  </div>
</template>

<script setup>
const modeCookie = useCookie("rideshare-mode", {
  default: () => "passenger",
  maxAge: 60 * 60 * 24 * 30,
});

const mode = computed(() => modeCookie.value === "driver" ? "driver" : "passenger");
const dropdownOpen = ref(false);

const toggleDropdown = () => {
  dropdownOpen.value = !dropdownOpen.value;
};

const selectMode = (newMode) => {
  modeCookie.value = newMode;
  dropdownOpen.value = false;
};

const handleClickOutside = (event) => {
  if (dropdownOpen.value && !event.target.closest('.relative')) {
    dropdownOpen.value = false;
  }
};

onMounted(() => {
  document.addEventListener('click', handleClickOutside);
});

onBeforeUnmount(() => {
  document.removeEventListener('click', handleClickOutside);
});
</script>
