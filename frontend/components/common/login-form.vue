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

          <!-- Divider -->
          <div class="relative my-1">
            <div class="absolute inset-0 flex items-center">
              <div class="w-full border-t border-gray-200"></div>
            </div>
            <div class="relative flex justify-center text-xs">
              <span class="px-3 bg-white text-gray-400 uppercase tracking-wide">{{ t("or") || "or" }}</span>
            </div>
          </div>

          <!-- Continue with Google -->
          <button
            type="button"
            @click="handleGoogleLogin"
            :disabled="isGoogleLoading"
            class="w-full flex items-center justify-center gap-2.5 py-2.5 px-4 border border-gray-300 rounded-lg bg-white hover:bg-gray-50 transition-all text-sm font-medium text-gray-700 disabled:opacity-60 disabled:cursor-not-allowed"
          >
            <svg v-if="!isGoogleLoading" class="w-5 h-5" viewBox="0 0 48 48">
              <path fill="#FFC107" d="M43.611 20.083H42V20H24v8h11.303c-1.649 4.657-6.08 8-11.303 8-6.627 0-12-5.373-12-12s5.373-12 12-12c3.059 0 5.842 1.154 7.961 3.039l5.657-5.657C34.046 6.053 29.268 4 24 4 12.955 4 4 12.955 4 24s8.955 20 20 20 20-8.955 20-20c0-1.341-.138-2.65-.389-3.917z"/>
              <path fill="#FF3D00" d="M6.306 14.691l6.571 4.819C14.655 15.108 18.961 12 24 12c3.059 0 5.842 1.154 7.961 3.039l5.657-5.657C34.046 6.053 29.268 4 24 4 16.318 4 9.656 8.337 6.306 14.691z"/>
              <path fill="#4CAF50" d="M24 44c5.166 0 9.86-1.977 13.409-5.192l-6.19-5.238C29.211 35.091 26.715 36 24 36c-5.202 0-9.619-3.317-11.283-7.946l-6.522 5.025C9.505 39.556 16.227 44 24 44z"/>
              <path fill="#1976D2" d="M43.611 20.083H42V20H24v8h11.303c-.792 2.237-2.231 4.166-4.087 5.571l6.19 5.238C36.971 39.205 44 34 44 24c0-1.341-.138-2.65-.389-3.917z"/>
            </svg>
            <UIcon v-else name="i-heroicons-arrow-path" class="w-5 h-5 animate-spin" />
            <span>{{ googleButtonLabel }}</span>
          </button>

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
const { login, socialLogin } = useAuth();
const { signInWithGoogle } = useFirebaseAuth();
const toast = useToast();
const { t } = useI18n();
const username = ref("");
const password = ref("");
const isPassword = ref(true);
const btnDisabled = ref(false);
const error = ref("");
const isLoading = ref(false);
const isGoogleLoading = ref(false);

const translateOr = (key, fallback) => {
  const value = t(key);
  return value && value !== key ? value : fallback;
};

const googleButtonLabel = computed(() =>
  isGoogleLoading.value
    ? translateOr("please_wait", "Please wait...")
    : translateOr("continue_with_google", "Continue with Google")
);

async function handleGoogleLogin() {
  if (isGoogleLoading.value) return;
  isGoogleLoading.value = true;
  try {
    const { idToken } = await signInWithGoogle();
    // Login screen: don't auto-create — confirm first if the account is new.
    let res = await socialLogin(idToken, { createIfMissing: false });
    if (!res.loggedIn && res.accountNotFound) {
      const ok = window.confirm(
        `${res.email || "এই Google অ্যাকাউন্ট"} দিয়ে কোনো AdsyClub অ্যাকাউন্ট নেই। নতুন অ্যাকাউন্ট তৈরি করবেন?`
      );
      if (!ok) {
        isGoogleLoading.value = false;
        return;
      }
      res = await socialLogin(idToken, { createIfMissing: true });
    }
    if (res.loggedIn) {
      toast.add({
        title: `🎉 ${t("login_success")}`,
        color: "green",
        icon: "i-heroicons-sparkles",
        timeout: 4000,
      });
      navigateTo("/");
    } else {
      toast.add({ title: res.message || t("login_error"), color: "red" });
    }
  } catch (e) {
    const code = e?.code || "";
    if (
      code !== "auth/popup-closed-by-user" &&
      code !== "auth/cancelled-popup-request"
    ) {
      toast.add({
        title: t("login_error") || "Google sign-in failed. Please try again.",
        color: "red",
      });
    }
  } finally {
    isGoogleLoading.value = false;
  }
}

async function handleLogin() {
  btnDisabled.value = true;
  isLoading.value = true;
  error.value = "";
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
      toast.add({ title: res.message || t("login_error"), color: "red" });
      error.value = res.message || t("login_error");
    }
  } catch (error) {
    console.error("error:", error);
  } finally {
    btnDisabled.value = false;
    isLoading.value = false;
  }
}
</script>

<style scoped></style>
