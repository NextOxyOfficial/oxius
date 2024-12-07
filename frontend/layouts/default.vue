<template>
  <div>
    <!-- <template v-if="!user">
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
    </template> -->
    <template>
      <PublicHeader />

      <slot />
      <PublicFooter />
    </template>
  </div>
</template>

<script setup>
const { jwtLogin, user } = useAuth();

// onMounted(() => {
//   setTimeout(() => {
//     if (!useCookie("jwt").value) {
//       navigateTo("/auth/login/");
//     } else {
//       jwtLogin();
//       navigateTo("/");
//     }
//   }, 1000);
// });
</script>
