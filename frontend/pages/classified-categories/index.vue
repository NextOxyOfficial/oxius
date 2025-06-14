<template>
  <div>
    <!-- This page will redirect users to the main index -->
  </div>
</template>

<script setup>
// Redirect to main index page
await navigateTo('/', { replace: true })
</script>
