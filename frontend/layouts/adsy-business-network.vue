<template>
  <div class="font-AnekBangla">
    <AdsyBusinessNetworkHeader />
    
    <!-- Pull to Refresh Wrapper for mobile app experience -->
    <PullToRefreshWrapper
      :enabled="enablePullToRefresh"
      :refresh-callback="handlePageRefresh"
      :auto-reload="true"
      :auto-reload-interval="180000"
      :show-network-status="true"
      :haptic-feedback="true"
      :theme="$colorMode.preference"
      pull-text="Pull down to refresh business network"
      release-text="Release to refresh posts"
      refreshing-text="Loading latest business posts..."
      success-message="Business network refreshed!"
      @refresh-start="onRefreshStart"
      @refresh-success="onRefreshSuccess"
      @refresh-error="onRefreshError"
    >
      <div class="max-w-5xl w-full mx-auto relative flex justify-center">
        <AdsyBusinessNetworkSidebar />
        <slot />
      </div>
    </PullToRefreshWrapper>
    
    <AdsyBusinessNetworkFooter />
    <UNotifications />

    <div v-if="loader" class="fixed inset-0 z-[99999999] bg-white">
      <NuxtLoadingIndicator class="!opacity-[1]" />
      <section class="h-screen w-screen flex items-center justify-center">
        <CommonPreloader />
      </section>
    </div class="fixed inset-0 z-[9999]">
    <!-- Chat Floating Button - removed the fixed inset-0 wrapper -->
    <!-- <BusinessNetworkChatFloatingButton /> -->
  </div>
</template>

<script setup>
const { jwtLogin } = useAuth();
const toast = useToast();
const loader = ref(true);

// Pull to refresh functionality
const enablePullToRefresh = ref(true);

// Handle page refresh for business network
const handlePageRefresh = async () => {
  try {
    // Use the global refresh system
    const { $globalRefresh } = useNuxtApp();
    
    if ($globalRefresh) {
      await $globalRefresh.refresh();
    } else {
      // Fallback refresh
      const eventBus = useEventBus();
      eventBus.emit('global-refresh');
      eventBus.emit('business-network-refresh');
      
      await refreshCookie('business-network-refresh', true);
      await new Promise(resolve => setTimeout(resolve, 500));
      await refreshCookie('business-network-refresh', false);
    }
    
  } catch (error) {
    console.error('Business network refresh failed:', error);
    throw error;
  }
};

// Refresh handlers
const onRefreshStart = () => {
  console.log('Business network refresh started');
};

const onRefreshSuccess = () => {
  console.log('Business network refresh successful');
  // Toast removed - showing visual indicator is sufficient
};

const onRefreshError = (error) => {
  console.error('Business network refresh error:', error);
  // Toast removed - showing visual indicator is sufficient
};

await jwtLogin();
onMounted(() => {
  setTimeout(() => {
    loader.value = false;
  }, 1000);
});
useHead({
  title:
    "AdsyClub – Bangladesh’s 1st Social Business Network: Earn Money, Connect with Society & Find the Services You Need!",
});
</script>
