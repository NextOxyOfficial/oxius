<template>
  <NuxtLink to="/" class="flex items-center gap-2">
    <!-- Mobile: Show app icon only -->
    <div class="md:hidden flex items-center">
      <div class="w-9 h-9 rounded-lg bg-gradient-to-br from-emerald-500 to-teal-600 flex items-center justify-center shadow-md">
        <img 
          src="/static/frontend/favicon.png" 
          alt="AdsyClub" 
          class="w-6 h-6"
          loading="eager"
        />
      </div>
    </div>
    
    <!-- Desktop: Show full logo -->
    <div class="hidden md:block">
      <NuxtImg
        v-if="logo?.image"
        :src="logo?.image"
        alt="Logo"
        :class="customClass ? customClass : 'h-8 sm:h-4 lg:h-8 object-contain'"
      />
      <img
        v-else
        class="h-8 sm:h-4 lg:h-8 object-contain"
        src="/static/frontend/images/logo.png"
        alt="Logo"
      />
    </div>
  </NuxtLink>
</template>

<script setup>
defineProps({
  customClass: {
    type: String,
    default: "",
  },
});
const { get } = useApi();
const logo = ref({});
async function getLogo() {
  try {
    const res = await get("/logo/");
    if (res.data) {
      logo.value = res.data;
    }
  } catch (error) {
    // Silently fallback to default logo
    logo.value = {};
  }
}
await getLogo();
</script>

<style scoped></style>
