<script setup>
const { login, jwtLogin, logout, user } = useAuth();

onMounted(() => {
  setTimeout(() => {
    if (!useCookie("adsyclub-jwt").value) {
      navigateTo("/auth/login/");
    } else {
      jwtLogin();
    }
  }, 1000);
});
useHead({
  title:
    "AdsyClub – Bangladesh’s First Social Business Network: Earn Money, Connect with Society, and Find the Services You Need!",
});
</script>

<template>
  <div class="font-AnekBangla">
    <NuxtLoadingIndicator class="!opacity-[1]" />
    <section
      class="h-screen w-screen flex items-center justify-center"
      v-if="!user"
    >
      <!-- <UIcon
        name="svg-spinners:bars-scale-middle"
        dynamic
        class="text-xl w-12 h-12 text-primary"
      /> -->
      <CommonPreloader />
    </section>
    <template v-if="user">
      <PublicHeader />
      <slot />
      <PublicFooter />
    </template>

    <UNotifications />
  </div>
</template>
