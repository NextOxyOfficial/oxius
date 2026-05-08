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

/* Ensure proper status bar spacing on mobile */
@media (max-width: 768px) {
  body {
    /* Add padding top to account for status bar on mobile devices */
    padding-top: env(safe-area-inset-top);
  }
  
  /* Ensure the main content doesn't overlap with status bar */
  #header-container {
    padding-top: env(safe-area-inset-top);
  }
}

/* Additional mobile adjustments for Capacitor apps */
.capacitor-app {
  body {
    padding-top: env(safe-area-inset-top);
  }
}
</style>
