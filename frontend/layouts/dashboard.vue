<script setup>
const { login, jwtLogin, logout, user, isAuthenticated, toBalance } = useAuth();

onMounted(() => {
  setTimeout(() => {
    if (!useCookie("jwt").value) {
      // navigateTo("/auth/login/");
    } else {
      jwtLogin();
    }
  }, 1000);
});
</script>

<template>
  <div>
    <NuxtLoadingIndicator class="!opacity-[1]" />
    <section
      class="h-screen w-screen flex items-center justify-center"
      v-if="!user"
    >
      <UIcon
        name="svg-spinners:bars-scale-middle"
        dynamic
        class="text-xl w-12 h-12 text-primary"
      />
    </section>
    <template v-if="user">
      <PublicHeader />
      <slot />
      <PublicFooter />
    </template>

    <UNotifications />
  </div>
</template>
