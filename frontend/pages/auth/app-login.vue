<template>
  <div class="flex items-center justify-center min-h-screen bg-gray-50">
    <div class="text-center p-8">
      <div v-if="loading" class="space-y-4">
        <div class="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600 mx-auto"></div>
        <p class="text-gray-600">Logging you in...</p>
      </div>
      <div v-else-if="error" class="space-y-4">
        <p class="text-red-600">{{ error }}</p>
        <NuxtLink to="/auth/login" class="text-blue-600 underline">Go to Login</NuxtLink>
      </div>
    </div>
  </div>
</template>

<script setup>
definePageMeta({
  layout: false,
});

const route = useRoute();
const { post } = useApi();
const { setTokens, jwtLogin } = useAuth();

const loading = ref(true);
const error = ref('');

onMounted(async () => {
  const token = route.query.token;
  const redirect = route.query.redirect || '/';

  if (!token) {
    error.value = 'Invalid login link';
    loading.value = false;
    return;
  }

  try {
    const res = await post('/auth/exchange-web-token/', { token });
    if (res?.data?.access && res?.data?.refresh) {
      await setTokens(res.data.access, res.data.refresh);
      await jwtLogin();
      await navigateTo(redirect, { replace: true });
    } else {
      error.value = 'Login failed. Please try again.';
      loading.value = false;
    }
  } catch (e) {
    error.value = 'Session expired. Please login manually.';
    loading.value = false;
  }
});
</script>
