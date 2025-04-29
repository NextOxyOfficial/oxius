<template>
  <div>
    <NuxtLayout>
      <NuxtPage />
    </NuxtLayout>
  </div>
</template>

<style>
/* Add these styles to prevent zooming issues on mobile */
@viewport {
  width: device-width;
  zoom: 1.0;
}

html, body {
  max-width: 100%;
  overflow-x: hidden;
  -webkit-text-size-adjust: 100%;
}

/* Fix for potential overflow issues in nested elements */
* {
  box-sizing: border-box;
}
</style>
