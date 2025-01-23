<template>
  <UContainer>
    <div class="flex flex-col-reverse md:flex-row items-center gap-8 py-5 md:py-0">
      <div class="md:w-3/4">
        <NuxtImg
          v-if="banner && banner.image"
          :src="banner.image"
          class="rounded-xl w-full max-h-[360px] object-contain"
          alt="Register"
        />
        <img
          v-else
          src="/static/frontend/images/register.webp"
          class="rounded-xl"
          alt="Register"
        />
      </div>
      <div class="md:py-10 w-full md:w-1/2">
        <CommonRegisterForm />
      </div>
    </div>
  </UContainer>
</template>

<script setup>
const login = ref(true);
const { user, isAuthenticated } = useAuth();
const { get } = useApi();
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
