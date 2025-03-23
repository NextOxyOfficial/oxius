<template>
  <NuxtLink to="/">
    <NuxtImg
      v-if="logo?.image"
      :src="logo?.image"
      alt="Logo"
      class="h-6 md:h-8"
    />
    <img
      v-else
      class="h-7 md:h-8"
      src="/static/frontend/images/logo.png"
      alt="Logo"
    />
  </NuxtLink>
</template>

<script setup>
defineProps({
  logo: { type: Object },
});
</script>

<style scoped></style>
