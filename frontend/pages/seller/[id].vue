<script setup>
const route = useRoute();
const sellerId = Array.isArray(route.params.id)
  ? route.params.id[0]
  : route.params.id;

await navigateTo(`/sale/user-profile/${encodeURIComponent(sellerId || '')}`, {
  replace: true,
  redirectCode: 301,
});
</script>

<template>
  <div />
</template>
