<template>
  <div />
</template>

<script setup>
// "Amar Sheba" (services) uses the short /classified path in deep links / push
// notifications (the app resolves it directly). On the web the real page lives
// at /classified-categories, so redirect there.
onMounted(() => {
  navigateTo("/classified-categories", { replace: true });
});
</script>
