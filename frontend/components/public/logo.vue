<template>
  <NuxtLink to="/">
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
    logo.value = res.data;
  } catch (error) {
    // Fallback to default logo if API fails
    console.warn('Logo API not available, using default logo');
    logo.value = {};
  }
}
await getLogo();
</script>

<style scoped></style>
