<template>
  <div>
    <div class="bg-white rounded-xl shadow-sm p-6 sm:p-8 border border-gray-100">
      <transition name="fade" mode="out-in">
        <!-- Login Form -->
        <form @submit.prevent="handleLogin" class="space-y-6">
          <!-- Form Header -->
          <div class="text-center space-y-2">
            <h2 class="text-2xl font-bold text-gray-800">Welcome Back</h2>
            <p class="text-gray-500">Enter your credentials to access your account</p>
          </div>

          <!-- Login Form Fields -->
          <div class="space-y-5">
            <div class="relative">
              <UIcon name="i-heroicons-envelope" class="absolute left-3 top-3 text-gray-400 w-5 h-5" />
              <input
                type="email"
                placeholder="Email address"
                v-model="username"
                class="w-full pl-10 pr-3 py-2.5 border border-gray-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-purple-500 focus:border-transparent transition-all"
                required
              />
              <p v-if="error" class="text-red-500 text-sm mt-1">
                {{ error }}
              </p>
            </div>
            
            <div class="relative">
              <UIcon name="i-heroicons-lock-closed" class="absolute left-3 top-3 text-gray-400 w-5 h-5" />
              <input
                :type="isPassword ? 'password' : 'text'"
                placeholder="Password"
                v-model="password"
                class="w-full pl-10 pr-10 py-2.5 border border-gray-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-purple-500 focus:border-transparent transition-all"
                required
              />
              <div
                class="absolute inset-y-0 right-0 flex items-center pr-3 cursor-pointer"
                @click="isPassword = !isPassword"
              >
                <UIcon
                  :name="isPassword ? 'i-heroicons-eye' : 'i-heroicons-eye-slash'"
                  class="w-5 h-5 text-gray-500 hover:text-gray-800"
                />
              </div>
            </div>
          </div>

          <!-- Remember me checkbox -->
          <div class="flex items-center justify-between">
            <div class="flex items-center">
              <input
                id="remember-me"
                name="remember-me"
                type="checkbox"
                class="h-4 w-4 text-purple-600 focus:ring-purple-500 border-gray-300 rounded"
              />
              <label for="remember-me" class="ml-2 block text-sm text-gray-800">
                Remember me
              </label>
            </div>
            <NuxtLink
              to="/auth/reset-password/"
              class="text-purple-600 hover:text-purple-500 text-sm font-medium hover:underline"
            >
              Forgot password?
            </NuxtLink>
          </div>

          <!-- Submit Button -->
          <UButton
            type="submit"
            :loading="isLoading"
            color="purple"
            class="w-full py-2.5 font-medium text-sm px-4 rounded-lg justify-center"
            :class="{ 'opacity-75 cursor-not-allowed': isLoading }"
          >
            <UIcon name="i-heroicons-arrow-right-on-rectangle" class="w-5 h-5 mr-1.5" />
            Sign in
          </UButton>

          <div class="text-center mt-4">
            <NuxtLink
              to="/auth/register/"
              class="text-purple-600 hover:text-purple-500 text-sm font-medium flex items-center justify-center gap-1 hover:underline"
            >
              <UIcon name="i-heroicons-user-plus" class="w-4 h-4" />
              Don't have an account? Register now
            </NuxtLink>
          </div>
        </form>
      </transition>
    </div>
    <!-- <form
      class="bg-white md:px-8 py-6 md:pb-8 mb-4 px-2 sm:px-8"
      @submit.prevent="handleLogin"
    >
      <h1 class="font-semibold text-center md:p-5 text-xl">LOGIN</h1>
      <div class="mb-6">
        <label class="block text-gray-800 text-md font-medium mb-2" for="email">
          Email
        </label>
        <input
          class="w-full py-1.5 px-3 text-sm text-gray-800 bg-[#D9D9D9] rounded-md"
          id="email"
          type="text"
          placeholder="abc@example.com"
          v-model="username"
        />
      </div>

      <div class="mb-2">
        <label
          class="block text-gray-800 text-md font-medium mb-2"
          for="password"
        >
          Password
        </label>
        <input
          class="w-full py-1.5 px-3 text-sm text-gray-800 bg-[#D9D9D9] rounded-md"
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
