<template>
  <div>
    <div class="bg-white rounded-2xl shadow-sm p-4 md:p-8">
      <transition name="fade" mode="out-in">
        <!-- Login Form -->
        <form @submit.prevent="handleLogin" class="space-y-6">
          <div class="space-y-2">
            <h2 class="text-2xl font-semibold text-gray-900">Welcome back</h2>
            <p class="text-gray-600">
              Enter your credentials to access your account
            </p>
          </div>

          <div class="space-y-4">
            <div>
              <input
                type="email"
                placeholder="Email"
                v-model="username"
                class="w-full px-3 py-2 border border-gray-200 rounded-lg focus:outline-none focus:border-gray-400"
                required
              />
            </div>
            <div class="relative">
              <input
                :type="isPassword ? 'password' : 'text'"
                placeholder="Password"
                v-model="password"
                class="w-full px-3 py-2 border border-gray-200 rounded-lg focus:outline-none focus:border-gray-400 text-base md:text-sm"
              />
              <div
                class="absolute inset-y-0 right-0 flex items-center pr-3 cursor-pointer"
                @click="isPassword = !isPassword"
              >
                <UIcon
                  name="i-heroicons-solid-eye"
                  class="w-5 h-5 text-gray-400"
                  v-if="isPassword"
                />
                <UIcon
                  name="i-heroicons-solid-eye-off"
                  class="w-5 h-5 text-gray-400"
                  v-else
                />
              </div>
            </div>
          </div>

          <UButton
            type="submit"
            :loading="isLoading"
            class="w-full py-3 font-semibold text-sm px-4 bg-gray-900 text-white rounded-lg hover:bg-gray-800 transition-colors justify-center"
          >
            Sign in
          </UButton>

          <div class="flex items-center justify-between pt-2 font-semibold">
            <NuxtLink
              to="/auth/reset-password/"
              class="text-purple-600 hover:text-purple-500 text-sm"
            >
              Forgot password?
            </NuxtLink>
            <NuxtLink
              to="/auth/register/"
              class="text-purple-600 hover:text-purple-500 text-sm"
            >
              Create account
            </NuxtLink>
          </div>
        </form>
      </transition>
    </div>
    <!-- <form
      class="bg-white md:px-8 py-6 md:pb-8 mb-4 px-2 sm:px-8"
      @submit.prevent="handleLogin"
    >
      <h1 class="font-bold text-center md:p-5 text-2xl">LOGIN</h1>
      <div class="mb-6">
        <label class="block text-gray-700 text-md font-medium mb-2" for="email">
          Email
        </label>
        <input
          class="w-full py-1.5 px-3 text-sm text-gray-700 bg-[#D9D9D9] rounded-md"
          id="email"
          type="text"
          placeholder="abc@example.com"
          v-model="username"
        />
      </div>

      <div class="mb-2">
        <label
          class="block text-gray-700 text-md font-medium mb-2"
          for="password"
        >
          Password
        </label>
        <input
          class="w-full py-1.5 px-3 text-sm text-gray-700 bg-[#D9D9D9] rounded-md"
          id="password"
          type="password"
          placeholder="********"
          v-model="password"
        />
        <a
          class="inline-block align-baseline font-medium tracking-wide text-sm text-black"
          href="#"
        >
          Forgot Password?
        </a>
      </div>
      <p class="text-red-500 text-sm md:text-base">{{ error }}</p>
      <div class="text-center mt-6">
        <button
          class="bg-orange-500 py-1 text-base text-white px-6 capitalize rounded-md"
          :disabled="btnDisabled"
        >
          Sign In
        </button>
      </div>
    </form> -->
  </div>
</template>

<script setup>
const { login } = useAuth();
const toast = useToast();
const username = ref("");
const password = ref("");
const isPassword = ref(true);
const btnDisabled = ref(false);
const error = ref("");
const isLoading = ref(false);

async function handleLogin() {
  btnDisabled.value = true;
  isLoading.value = true;
  try {
    const res = await login(username.value, password.value);
    if (res.loggedIn) {
      navigateTo("/");
      toast.add({ title: "Login successful!" });
      error.value = "";
    } else {
      toast.add({ title: res._value.data.error, status: "error" });
      error.value = res._value.data.error;
    }
  } catch (error) {
    console.log("error:", error);
  }
  isLoading.value = false;
}
</script>

<style scoped></style>
