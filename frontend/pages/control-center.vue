<template>
  <div
    class="min-h-screen flex flex-col items-center justify-center bg-gradient-to-br from-slate-900 to-slate-800"
  >
    <!-- Admin Login Card -->
    <div
      class="w-full max-w-md px-8 py-10 bg-white dark:bg-slate-800 rounded-xl shadow-2xl"
    >
      <!-- Logo and Header -->
      <div class="text-center mb-8">
        <div class="mb-6 flex justify-center">
          <img src="/logo.svg" alt="Logo" class="h-12 w-auto" />
        </div>
        <h1 class="text-2xl font-bold text-slate-800 dark:text-white mb-1">
          Admin Control Center
        </h1>
        <p class="text-slate-500 dark:text-slate-400 text-sm">
          Secure access for authorized administrators only
        </p>
      </div>

      <!-- Login Form -->
      <form @submit.prevent="handleLogin" class="space-y-6">
        <!-- Alert for errors -->
        <UAlert
          v-if="error"
          color="red"
          variant="soft"
          icon="i-heroicons-exclamation-triangle"
          class="mb-6"
        >
          <p>{{ error }}</p>
        </UAlert>

        <!-- Username/Email Field -->
        <div class="space-y-2">
          <UFormGroup label="Username" name="username">
            <UInput
              v-model="credentials.username"
              placeholder="Enter your username"
              icon="i-heroicons-user-circle"
              autocomplete="username"
              :ui="{
                icon: { trailing: { pointer: '' } },
                base: 'relative w-full transition duration-200 dark:bg-slate-800/50',
              }"
              size="lg"
              required
            />
          </UFormGroup>
        </div>

        <!-- Password Field -->
        <div class="space-y-2">
          <UFormGroup label="Password" name="password">
            <UInput
              v-model="credentials.password"
              type="password"
              placeholder="Enter your password"
              icon="i-heroicons-lock-closed"
              autocomplete="current-password"
              :ui="{
                icon: { trailing: { pointer: '' } },
                base: 'relative w-full transition duration-200 dark:bg-slate-800/50',
              }"
              size="lg"
              required
            />
          </UFormGroup>
        </div>

        <!-- Login Button -->
        <div class="pt-2">
          <UButton
            type="submit"
            block
            color="primary"
            size="xl"
            :loading="isLoading"
            :disabled="isLoading"
            :ui="{ rounded: 'rounded-xl' }"
          >
            <template v-if="!isLoading">
              <UIcon name="i-heroicons-lock-open" class="mr-2 w-5 h-5" />
              Sign In to Control Center
            </template>
            <template v-else>Authenticating...</template>
          </UButton>
        </div>
      </form>

      <!-- Security Notice -->
      <div class="mt-8 pt-6 border-t border-slate-200 dark:border-slate-700">
        <div
          class="flex items-center text-sm text-slate-500 dark:text-slate-400"
        >
          <UIcon
            name="i-heroicons-shield-check"
            class="mr-2 w-5 h-5 text-green-500"
          />
          <p>
            This area is strictly for administrators. Unauthorized access
            attempts are monitored and logged.
          </p>
        </div>
      </div>
    </div>

    <!-- Footer -->
    <div class="mt-8 text-center text-sm text-slate-500 dark:text-slate-400">
      <p>
        &copy; {{ new Date().getFullYear() }} OxyUs Admin Portal. All rights
        reserved.
      </p>
    </div>
  </div>
</template>

<script setup>
import { ref, reactive } from "vue";
import { useRouter } from "vue-router";
import { useToast } from "@/composables/useToast";

const router = useRouter();
const toast = useToast();
const isLoading = ref(false);
const error = ref(null);

const credentials = reactive({
  username: "",
  password: "",
});

async function handleLogin() {
  error.value = null;
  isLoading.value = true;

  try {
    // Replace with your API endpoint
    const { post } = useApi();
    const response = await post("/admin/login/", {
      username: credentials.username,
      password: credentials.password,
    });

    // Check if user is admin
    if (
      response.data &&
      response.data.user &&
      response.data.user.is_superuser
    ) {
      // Save admin token/data in localStorage or cookie
      localStorage.setItem("adminToken", response.data.token);
      localStorage.setItem("adminUser", JSON.stringify(response.data.user));

      // Show success message
      toast.add({
        title: "Login Successful",
        description: "Welcome to the control center",
        color: "green",
      });

      // Redirect to admin dashboard
      router.push("/admin/dashboard");
    } else {
      // User is not an admin
      error.value =
        "You don't have administrative privileges to access this area.";

      // Clear any stored tokens that might have been saved
      localStorage.removeItem("adminToken");
      localStorage.removeItem("adminUser");
    }
  } catch (err) {
    console.error("Login error:", err);
    error.value = err.response?.data?.detail || "Invalid username or password";
  } finally {
    isLoading.value = false;
  }
}

// Middleware to check if already logged in as admin
onMounted(() => {
  const adminToken = localStorage.getItem("adminToken");
  const adminUser = JSON.parse(localStorage.getItem("adminUser") || "{}");

  if (adminToken && adminUser.is_superuser) {
    router.push("/admin/dashboard");
  }
});
</script>
