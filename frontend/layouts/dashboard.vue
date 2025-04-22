<script setup>
const { login, jwtLogin, logout, user } = useAuth();
const isLoading = ref(true);

// Use an immediately-invoked async function to handle auth
const checkAuth = async () => {
  try {
    if (!useCookie("adsyclub-jwt").value) {
      navigateTo("/auth/login/");
    } else {
      await jwtLogin();
    }
  } catch (error) {
    console.error("Authentication error:", error);
  } finally {
    isLoading.value = false;
  }
};
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
    <slot v-if="!isLoading && user" />
    <PublicFooter v-if="!isLoading && user" />

    <UNotifications />
  </div>
</template>
