<template>
  <UContainer class="py-10 md:py-16">
    <div class="flex flex-col-reverse md:flex-row items-center gap-8 max-w-5xl mx-auto">
      <div class="w-full md:w-3/5 relative">
        <div class="relative">
          <NuxtImg
            v-if="banner && banner.image"
            :src="banner.image"
            class="rounded-xl w-full object-cover shadow-sm"
            alt="Login"
          />
          <img
            v-else
            src="/static/frontend/images/register.webp"
            class="rounded-xl shadow-sm w-full"
            alt="Login"
          />
          
          <!-- Overlay text -->
          <div class="absolute inset-0 flex flex-col items-start justify-end p-8 bg-gradient-to-t from-black/70 to-transparent rounded-xl text-white">
            <h2 class="text-3xl font-bold mb-2">Welcome Back!</h2>
            <p class="text-lg">Sign in to your account to access all features</p>
          </div>
        </div>
      </div>
      
      <div class="w-full md:w-2/5 md:py-5">
        <CommonLoginForm />
      </div>
    </div>
  </UContainer>
</template>

<script setup>
const { user, isAuthenticated } = useAuth();
const { get } = useApi();

const banner = ref({});

async function getBanner() {
  const res = await get("/authentication-banner/");
  banner.value = res.data;
  console.log(res.data);
}

getBanner();

onMounted(() => {
  if (user?.user) {
    console.log(user);
    navigateTo("/");
  }
  if (useCookie("adsyclub-jwt").value) {
    navigateTo("/");
  }
});
</script>

<style>
/* Fade transitions */
.fade-enter-active,
.fade-leave-active {
  transition: opacity 0.3s ease;
}

.fade-enter-from,
.fade-leave-to {
  opacity: 0;
}

/* Page entrance animation */
@keyframes slideInFromRight {
  0% {
    transform: translateX(10%);
    opacity: 0;
  }
  100% {
    transform: translateX(0);
    opacity: 1;
  }
}

.container {
  animation: 0.5s ease-out 0s 1 slideInFromRight;
}
</style>
