<template>
  <UContainer>
    <div
      class="flex flex-col-reverse md:flex-row items-center gap-8 py-5 md:py-0"
    >
      <div class="md:w-3/4">
        <NuxtImg
          :src="staticURL + banner.image"
          class="rounded-xl max-h-[360px] object-contain"
          alt="Register"
        />
      </div>
      <div class="md:pt-10 w-full md:w-1/2">
        <CommonLoginForm v-if="login" />
        <CommonRegisterForm v-else />
        <p class="my-5 text-center tracking-wide" v-if="!login">
          Already have an account?
          <span @click="login = true" class="font-bold cursor-pointer"
            >Login Now!</span
          >
        </p>
        <p v-else class="my-5 text-center tracking-wide">
          Don't have an account?
          <span @click="login = false" class="font-bold cursor-pointer"
            >Register Now!</span
          >
        </p>
      </div>
    </div>
  </UContainer>
</template>

<script setup>
const login = ref(true);
const { user, isAuthenticated } = useAuth();
const { get, staticURL } = useApi();
const router = useRoute();
const banner = ref({});
if (router.query.ref) {
  login.value = false;
}

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
  if (useCookie("jwt").value) {
    navigateTo("/");
  }
});
</script>

<style></style>
