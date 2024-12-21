<template>
  <NuxtLink to="/">
    <NuxtImg
      v-if="logo?.image"
      :src="staticURL + logo?.image"
      alt="Logo"
      class="h-6 md:h-8"
    />
    <NuxtImg
      v-else
      class="h-6 md:h-8"
      src="/static/frontend/images/logo.jpg"
      alt="Logo"
    />
  </NuxtLink>
</template>

<script setup>
defineProps({
  logo: { type: Object },
  staticURL: { type: String },
});
</script>

<style scoped></style>
