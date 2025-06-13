<script setup>
const { login, jwtLogin, logout, user, getValidToken, clearAuthData } = useAuth();
const toast = useToast();
const isLoading = ref(true);

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
  <div class="font-AnekBangla layout-dashboard">
    <NuxtLoadingIndicator class="!opacity-[1]" />
    <section
      class="h-screen w-screen flex items-center justify-center fixed inset-0 z-[99999999] bg-white"
      v-if="isLoading || !user"
    >
      <CommonPreloader />
    </section>    <PublicHeader v-if="!isLoading && user" />
    <slot />
    <PublicFooter v-if="!isLoading && user" />

    <UNotifications />
  </div>
</template>
