<template>
  <NuxtLink to="/">
    <NuxtImg
      v-if="logo?.image"
      :src="staticURL + logo?.image"
      alt="Logo"
      class="h-12"
    />
    <NuxtImg v-else src="/images/logo.jpg" alt="Logo" />
    {{ logo }}
  </NuxtLink>
</template>

<script setup>
defineProps({
  logo: { type: Object },
  staticURL: { type: String },
});
</script>

<style scoped></style>
