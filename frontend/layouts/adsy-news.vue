<template>
    <div class="font-AnekBangla">
      <AdsyNewsHeader />
        <!-- Pull to Refresh Wrapper for mobile app experience -->
      <PullToRefreshWrapper
        :enabled="enablePullToRefresh"
        :refresh-callback="handlePageRefresh"
        :auto-reload="false"
        :show-network-status="true"
        :haptic-feedback="true"
        :theme="$colorMode.preference"
        pull-text="Pull down to refresh news"
        release-text="Release to load latest news"
        refreshing-text="Loading latest news..."
        success-message="News refreshed!"
        @refresh-start="onRefreshStart"
        @refresh-success="onRefreshSuccess"
        @refresh-error="onRefreshError"
      >
        <slot />
      </PullToRefreshWrapper>
      
      <UNotifications />
  
      <div v-if="loader" class="fixed inset-0 z-[99999999] bg-white">
        <NuxtLoadingIndicator class="!opacity-[1]" />
        <section class="h-screen w-screen flex items-center justify-center">
          <CommonPreloader />
        </section>
      </div>
    </div>
  </template>
    <script setup>
  const { jwtLogin } = useAuth();
  const toast = useToast();
  const loader = ref(true);

  // Pull to refresh functionality
  const enablePullToRefresh = ref(true);

  // Handle page refresh for news
  const handlePageRefresh = async () => {
    try {
      // Emit global refresh event for news components
      const eventBus = useEventBus();
      eventBus.emit('global-refresh');
      eventBus.emit('news-refresh');
      
      // Refresh any data that might be cached
      await refreshCookie('news-refresh', true);
      
      // Small delay for smooth animation
      await new Promise(resolve => setTimeout(resolve, 500));
      
      // Clear the refresh trigger
      await refreshCookie('news-refresh', false);
      
    } catch (error) {
      console.error('News refresh failed:', error);
      throw error;
    }
  };

  // Refresh handlers
  const onRefreshStart = () => {
    console.log('News refresh started');
  };
  const onRefreshSuccess = () => {
    console.log('News refresh successful');
    // Toast removed - showing visual indicator is sufficient
  };

  const onRefreshError = (error) => {
    console.error('News refresh error:', error);
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
  