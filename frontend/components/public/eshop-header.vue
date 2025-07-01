<template>
  <div
    class="py-3 backdrop-blur-sm max-sm:bg-slate-200/70 bg-white shadow-sm rounded-b-lg transition-all duration-300 z-[99999999] w-full"
    :class="[
      isScrolled
        ? 'fixed top-0 left-0 right-0 backdrop-blur-sm max-sm:bg-slate-200/70 bg-white shadow-sm rounded-b-lg border-gray-200/50 dark:border-gray-800/50'
        : 'sticky top-0 w-full shadow-sm',
      'sm:py-3 py-1.5', // Smaller padding on mobile
    ]"
  >
    <UContainer class="px-2">
      <div class="flex items-center justify-between gap-2">
        <PublicLogo />
        <div class="flex-1">
          <UInput
            icon="i-heroicons-magnifying-glass-20-solid"
            size="sm"
            color="green"
            :trailing="false"
            placeholder="Search..."
          />
        </div>
      </div>
    </UContainer>
  </div>
</template>

<script setup>
// Handle scroll events
const isScrolled = ref(false);
const handleScroll = () => {
  isScrolled.value = window.scrollY > 80;
};

onMounted(() => {
  window.addEventListener("scroll", handleScroll);
});

onBeforeUnmount(() => {
  window.removeEventListener("scroll", handleScroll);
});
</script>
