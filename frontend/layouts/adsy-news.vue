<template>
    <div class="font-AnekBangla">
      <AdsyNewsHeader />
      <slot />
      <UNotifications />
  
      <div v-if="loader" class="fixed inset-0 z-[99999999] bg-white">
        <NuxtLoadingIndicator class="!opacity-[1]" />
        <section class="h-screen w-screen flex items-center justify-center">
          <CommonPreloader />
        </section>
      </div>
    </div>
  </template>
    <script setup>  const { jwtLogin } = useAuth();
  const toast = useToast();
  const loader = ref(true);

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
  