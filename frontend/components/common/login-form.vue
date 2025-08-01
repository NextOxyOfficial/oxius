<template>
  <div>
    <div
      class="bg-white rounded-xl shadow-sm p-6 sm:p-8 border border-gray-100"
    >
      <transition name="fade" mode="out-in">
        <!-- Login Form -->
        <form @submit.prevent="handleLogin" class="space-y-6">
          <!-- Form Header -->
          <div class="text-center space-y-2">
            <h2 class="text-2xl font-bold text-gray-800">
              {{ t("welcome_back") }}
            </h2>
            <p class="text-gray-600">{{ t("login_subtitle") }}</p>
          </div>

          <!-- Login Form Fields -->
          <div class="space-y-5">
            <div class="relative">
              <UIcon
                name="i-heroicons-envelope"
                class="absolute left-3 top-3 text-gray-400 w-5 h-5"
              />
              <input
                type="email"
                :placeholder="t('email_address')"
                v-model="username"
                class="w-full pl-10 pr-3 py-2.5 border border-gray-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-purple-500 focus:border-transparent transition-all"
                required
              />
              <p v-if="error" class="text-red-500 text-sm mt-1">
                {{ error }}
              </p>
            </div>

            <div class="relative">
              <UIcon
                name="i-heroicons-lock-closed"
                class="absolute left-3 top-3 text-gray-400 w-5 h-5"
              />
              <input
                :type="isPassword ? 'password' : 'text'"
                :placeholder="t('password')"
                v-model="password"
                class="w-full pl-10 pr-10 py-2.5 border border-gray-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-purple-500 focus:border-transparent transition-all"
                required
              />
              <div
                class="absolute inset-y-0 right-0 flex items-center pr-3 cursor-pointer"
                @click="isPassword = !isPassword"
              >
                <UIcon
                  :name="
                    isPassword ? 'i-heroicons-eye' : 'i-heroicons-eye-slash'
                  "
                  class="w-5 h-5 text-gray-600 hover:text-gray-800"
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
                {{ t("remember_me") }}
              </label>
            </div>
            <NuxtLink
              to="/auth/reset-password/"
              class="text-purple-600 hover:text-purple-500 text-sm font-medium hover:underline"
            >
              {{ t("forgot_password") }}
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
            <UIcon
              name="i-heroicons-arrow-right-on-rectangle"
              class="w-5 h-5 mr-1.5"
            />
            {{ t("sign_in") }}
          </UButton>

          <div class="text-center mt-4">
            <NuxtLink
              to="/auth/register/"
              class="text-purple-600 hover:text-purple-500 text-sm font-medium flex items-center justify-center gap-1 hover:underline"
            >
              <UIcon name="i-heroicons-user-plus" class="w-4 h-4" />
              {{ t("dont_have_account") }}
            </NuxtLink>
          </div>
        </form>
      </transition>
    </div>
  </div>
</template>

<script setup>
const { login } = useAuth();
const toast = useToast();
const { t } = useI18n();
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
      // Enhanced login success toast with personalization
      const welcomeMessages = [
        t("login_success_messages.0") || "Great to see you again!",
        t("login_success_messages.1") || "Welcome back, champion!",
        t("login_success_messages.2") || "You're back in action!",
        t("login_success_messages.3") || "Ready to conquer today?",
        t("login_success_messages.4") || "Welcome back to the community!",
      ];

      const randomWelcome =
        welcomeMessages[Math.floor(Math.random() * welcomeMessages.length)];

      toast.add({
        title: `🎉 ${t("login_success")}`,
        description: randomWelcome,
        color: "green",
        icon: "i-heroicons-sparkles",
        timeout: 4000,
        actions: [
          {
            label: "Explore Dashboard",
            click: () => navigateTo("/"),
          },
        ],
      });

      error.value = "";
    } else {
      toast.add({ title: res._value.data.error, status: "error" });
      error.value = res._value.data.error;
    }
  } catch (error) {
    console.error("error:", error);
  }
  isLoading.value = false;
}
</script>

<style scoped></style>
