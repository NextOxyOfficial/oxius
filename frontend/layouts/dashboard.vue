<script setup>
const { login, jwtLogin, logout, user, getValidToken, clearAuthData } = useAuth();
const toast = useToast();
const isLoading = ref(true);

// Pull to refresh functionality
const enablePullToRefresh = ref(true);

// Handle page refresh for dashboard
const handlePageRefresh = async () => {
  try {
    // Emit global refresh event for dashboard components
    const eventBus = useEventBus();
    eventBus.emit('global-refresh');
    eventBus.emit('dashboard-refresh');
    
    // Refresh user data and any cached content
    await refreshCookie('dashboard-refresh', true);
    
    // Re-validate authentication
    const validToken = await getValidToken();
    if (validToken) {
      await jwtLogin();
    }
    
    // Small delay for smooth animation
    await new Promise(resolve => setTimeout(resolve, 500));
    
    // Clear the refresh trigger
    await refreshCookie('dashboard-refresh', false);
    
  } catch (error) {
    console.error('Dashboard refresh failed:', error);
    throw error;
  }
};

// Refresh handlers
const onRefreshStart = () => {
  console.log('Dashboard refresh started');
};

const onRefreshSuccess = () => {
  console.log('Dashboard refresh successful');
  // Toast removed - showing visual indicator is sufficient
};

const onRefreshError = (error) => {
  console.error('Dashboard refresh error:', error);
  // Toast removed - showing visual indicator is sufficient
};

// Enhanced auth check with proper token refresh handling
const checkAuth = async () => {
  try {
    // Check if we have any tokens
    const jwt = useCookie("adsyclub-jwt");
    const refreshToken = useCookie("adsyclub-refresh");
    
    if (!jwt.value && !refreshToken.value) {
      // No tokens at all, redirect to login
      await navigateTo("/auth/login/");
      return;
    }

    // Try to get a valid token (this will attempt refresh if needed)
    const validToken = await getValidToken();
    
    if (!validToken) {
      // Token refresh failed, clear auth and redirect
      await clearAuthData();
      await navigateTo("/auth/login/");
      return;
    }

    // Validate the token with the server
    const loginSuccess = await jwtLogin();
    if (!loginSuccess) {
      // JWT validation failed even after refresh attempt
      await navigateTo("/auth/login/");
    }
  } catch (error) {
    console.error("Authentication error:", error);
    await clearAuthData();
    await navigateTo("/auth/login/");
  } finally {
    isLoading.value = false;
  }
};

// Run auth check
checkAuth();

useHead({
  title:
    "AdsyClub - Bangladesh's 1st Social Business Network: Earn Money, Connect with Society & Find the Services You Need!",
});
</script>

<template>
  <div class="font-AnekBangla">
    <NuxtLoadingIndicator class="!opacity-[1]" />
    <section
      class="h-screen w-screen flex items-center justify-center fixed inset-0 z-[99999999] bg-white"
      v-if="isLoading || !user"
    >
      <CommonPreloader />
    </section>

    <PublicHeader v-if="!isLoading && user" />
      <!-- Pull to Refresh Wrapper for dashboard content -->
    <PullToRefreshWrapper
      v-if="!isLoading && user"
      :enabled="enablePullToRefresh"
      :refresh-callback="handlePageRefresh"
      :auto-reload="false"
      :show-network-status="true"
      :haptic-feedback="true"
      :theme="$colorMode.preference"
      pull-text="Pull down to refresh dashboard"
      release-text="Release to refresh content"
      refreshing-text="Refreshing dashboard..."
      success-message="Dashboard refreshed!"
      @refresh-start="onRefreshStart"
      @refresh-success="onRefreshSuccess"
      @refresh-error="onRefreshError"
    >
      <slot />
    </PullToRefreshWrapper>
    
    <PublicFooter v-if="!isLoading && user" />

    <UNotifications />
  </div>
</template>
