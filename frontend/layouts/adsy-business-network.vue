<template>
  <div class="font-AnekBangla layout-adsy-business-network">
    <AdsyBusinessNetworkHeader />
    <div class="max-w-5xl w-full mx-auto relative flex justify-center">
      <AdsyBusinessNetworkSidebar />
      <slot />
    </div>    <AdsyBusinessNetworkFooter />
    <UNotifications />
    
    <!-- Create Post Modal -->
    <BusinessNetworkCreatePost />

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

// Pull to refresh functionality removed

await jwtLogin();
onMounted(() => {
  setTimeout(() => {
    loader.value = false;
  }, 1000);
});
useHead({
  title:
    "AdsyClub – Social Business Network: Earn Money, Connect with Society & Find the Services You Need!",
});
</script>
