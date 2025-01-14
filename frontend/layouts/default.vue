<template>
  <div>
    <template v-if="loader">
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
    if (!useCookie("jwt").value) {
      loader.value = false;
    } else {
      jwtLogin();
      loader.value = false;
    }
  }, 1000);
});
useHead({
  title:
    "AdsyClub | Earn Money, Connect with Society & Find the services you need!",
});
</script>
