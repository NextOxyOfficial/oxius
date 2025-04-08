<template>
  <div class="font-AnekBangla">
    <template v-if="loader">
      <NuxtLoadingIndicator class="!opacity-[1]" />
      <section
        class="h-screen w-screen flex items-center justify-center"
        v-if="!user"
      >
        <div class="opacity-0 absolute -z-50">
          <slot />
        </div>
        <CommonPreloader />
      </section>
    </template>
    <template v-else>
      <PublicHeader />
      <slot />
      <PublicFooter />
    </template>
    <UNotifications />
  </div>
</template>

<script setup>
const { jwtLogin, user } = useAuth();
const loader = ref(true);

onMounted(() => {
  setTimeout(() => {
    if (!useCookie("adsyclub-jwt").value) {
      loader.value = false;
    } else {
      jwtLogin();
      loader.value = false;
    }
  }, 1000);
});
useHead({
  title:
    "AdsyClub, The Business Network | Earn Money, Connect with Society & Find the services you need!",
});
</script>
