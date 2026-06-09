<template>
  <div />
</template>

<script setup>
// Mindforce uses the short /mindforce path in deep links / push notifications
// (the app resolves it directly). On the web the page lives under
// /business-network/mindforce, so redirect there.
onMounted(() => {
  navigateTo("/business-network/mindforce", { replace: true });
});
</script>
