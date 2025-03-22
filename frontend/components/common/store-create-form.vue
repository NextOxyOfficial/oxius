<template>
  <div class="py-10 px-4 sm:px-6 lg:px-8">
    <!-- Toast Notification -->
    <div v-if="toast.show" class="fixed top-4 right-4 z-50 max-w-md">
      <div
        :class="`bg-${toast.type}-100 border-l-4 border-${toast.type}-500 text-${toast.type}-700 p-4 rounded shadow-md`"
      >
        <div class="flex items-center">
          <div class="py-1">
            <svg
              v-if="toast.type === 'success'"
              class="h-6 w-6 text-success-500 mr-4"
              xmlns="http://www.w3.org/2000/svg"
              fill="none"
              viewBox="0 0 24 24"
              stroke="currentColor"
            >
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                stroke-width="2"
                d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"
              />
            </svg>
            <svg
              v-else-if="toast.type === 'error'"
              class="h-6 w-6 text-error-500 mr-4"
              xmlns="http://www.w3.org/2000/svg"
              fill="none"
              viewBox="0 0 24 24"
              stroke="currentColor"
            >
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                stroke-width="2"
                d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"
              />
            </svg>
            <svg
              v-else
              class="h-6 w-6 text-info-500 mr-4"
              xmlns="http://www.w3.org/2000/svg"
              fill="none"
              viewBox="0 0 24 24"
              stroke="currentColor"
            >
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                stroke-width="2"
                d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"
              />
            </svg>
          </div>
          <div>
            <p class="font-bold">{{ toast.title }}</p>
            <p class="text-sm">{{ toast.message }}</p>
          </div>
        </div>
      </div>
    </div>

    <div class="max-w-md mx-auto">
      <!-- Page Header -->
      <div class="mb-8 text-center">
        <h1
          class="text-3xl font-bold text-indigo-600 dark:text-indigo-400 mb-2"
        >
          Create Your Store
        </h1>
        <p class="text-gray-600 dark:text-gray-300">
          Set up your online store and start selling your products
        </p>
      </div>

      <!-- Form Container -->
      <div class="bg-white dark:bg-gray-800 rounded-lg shadow-lg p-6">
        <form @submit.prevent="handleCreateStore">
          <!-- Store Name -->
          <div class="mb-6">
            <label
              for="storeName"
              class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2"
            >
              Store Name <span class="text-red-500">*</span>
            </label>
            <div class="relative">
              <div
                class="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none"
              >
                <svg
                  xmlns="http://www.w3.org/2000/svg"
                  class="h-5 w-5 text-gray-400"
                  fill="none"
                  viewBox="0 0 24 24"
                  stroke="currentColor"
                >
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="2"
                    d="M19 21V5a2 2 0 00-2-2H7a2 2 0 00-2 2v16m14 0h2m-2 0h-5m-9 0H3m2 0h5M9 7h1m-1 4h1m4-4h1m-1 4h1m-5 10v-5a1 1 0 011-1h2a1 1 0 011 1v5m-4 0h4"
                  />
                </svg>
              </div>
              <input
                id="storeName"
                v-model="form.name"
                type="text"
                class="block w-full pl-10 pr-3 py-2 border border-gray-300 dark:border-gray-600 rounded-md shadow-sm placeholder-gray-400 focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 dark:bg-gray-700 dark:text-white"
                placeholder="Enter your store name"
              />
            </div>
            <p v-if="errors.name" class="mt-1 text-sm text-red-600">
              {{ errors.name }}
            </p>
          </div>

          <!-- Store Username -->
          <div class="mb-6">
            <label
              for="storeUsername"
              class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2"
            >
              Store Username <span class="text-red-500">*</span>
            </label>
            <div class="relative">
              <div
                class="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none"
              >
                <svg
                  xmlns="http://www.w3.org/2000/svg"
                  class="h-5 w-5 text-gray-400"
                  fill="none"
                  viewBox="0 0 24 24"
                  stroke="currentColor"
                >
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="2"
                    d="M16 12a4 4 0 10-8 0 4 4 0 008 0zm0 0v1.5a2.5 2.5 0 005 0V12a9 9 0 10-9 9m4.5-1.206a8.959 8.959 0 01-4.5 1.207"
                  />
                </svg>
              </div>
              <input
                id="storeUsername"
                v-model="form.username"
                type="text"
                class="block w-full pl-10 pr-3 py-2 border border-gray-300 dark:border-gray-600 rounded-md shadow-sm placeholder-gray-400 focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 dark:bg-gray-700 dark:text-white"
                placeholder="Enter your store username"
              />
            </div>
            <p v-if="errors.username" class="mt-1 text-sm text-red-600">
              {{ errors.username }}
            </p>

            <!-- Store URL Preview -->
            <div class="mt-3 p-3 bg-gray-50 dark:bg-gray-700 rounded-md">
              <p class="text-xs text-gray-500 dark:text-gray-400 mb-1">
                Your store URL will be:
              </p>
              <div class="flex items-center">
                <span class="text-sm text-gray-600 dark:text-gray-300 font-mono"
                  >https://adsyclub.com/eshop/</span
                >
                <span
                  class="text-sm text-indigo-600 dark:text-indigo-400 font-mono font-medium"
                  >{{ form.username || "your-store" }}</span
                >
              </div>
            </div>
          </div>

          <!-- Submit Button -->
          <div class="mt-8">
            <button
              type="submit"
              class="w-full flex justify-center py-2 px-4 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500 disabled:opacity-50 disabled:cursor-not-allowed"
              :disabled="isSubmitting"
            >
              <svg
                v-if="isSubmitting"
                class="animate-spin -ml-1 mr-3 h-5 w-5 text-white"
                xmlns="http://www.w3.org/2000/svg"
                fill="none"
                viewBox="0 0 24 24"
              >
                <circle
                  class="opacity-25"
                  cx="12"
                  cy="12"
                  r="10"
                  stroke="currentColor"
                  stroke-width="4"
                ></circle>
                <path
                  class="opacity-75"
                  fill="currentColor"
                  d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"
                ></path>
              </svg>
              {{ isSubmitting ? "Creating..." : "Create Store" }}
            </button>
          </div>
        </form>
      </div>
    </div>

    <!-- Success Modal -->
    <div
      v-if="isSuccessModalOpen"
      class="fixed inset-0 z-50 overflow-y-auto"
      aria-labelledby="modal-title"
      role="dialog"
      aria-modal="true"
    >
      <div
        class="flex items-end justify-center min-h-screen pt-4 px-4 pb-20 text-center sm:block sm:p-0"
      >
        <div
          class="fixed inset-0 bg-gray-500 bg-opacity-75 transition-opacity"
          aria-hidden="true"
        ></div>
        <span
          class="hidden sm:inline-block sm:align-middle sm:h-screen"
          aria-hidden="true"
          >&#8203;</span
        >
        <div
          class="inline-block align-bottom bg-white dark:bg-gray-800 rounded-lg text-left overflow-hidden shadow-xl transform transition-all sm:my-8 sm:align-middle sm:max-w-lg sm:w-full"
        >
          <div class="bg-white dark:bg-gray-800 px-4 pt-5 pb-4 sm:p-6 sm:pb-4">
            <div class="sm:flex sm:items-start">
              <div
                class="mx-auto flex-shrink-0 flex items-center justify-center h-12 w-12 rounded-full bg-green-100 sm:mx-0 sm:h-10 sm:w-10"
              >
                <svg
                  class="h-6 w-6 text-green-600"
                  xmlns="http://www.w3.org/2000/svg"
                  fill="none"
                  viewBox="0 0 24 24"
                  stroke="currentColor"
                >
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="2"
                    d="M5 13l4 4L19 7"
                  />
                </svg>
              </div>
              <div class="mt-3 text-center sm:mt-0 sm:ml-4 sm:text-left">
                <h3
                  class="text-lg leading-6 font-medium text-gray-900 dark:text-white"
                  id="modal-title"
                >
                  Store Created Successfully!
                </h3>
                <div class="mt-2">
                  <p class="text-sm text-gray-500 dark:text-gray-400">
                    Your store "{{ form.name }}" has been created. You can now
                    start adding products and customizing your store.
                  </p>
                </div>
              </div>
            </div>
          </div>
          <div
            class="bg-gray-50 dark:bg-gray-700 px-4 py-3 sm:px-6 sm:flex sm:flex-row-reverse"
          >
            <button
              type="button"
              class="w-full inline-flex justify-center rounded-md border border-transparent shadow-sm px-4 py-2 bg-indigo-600 text-base font-medium text-white hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500 sm:ml-3 sm:w-auto sm:text-sm"
              @click="goToStore"
            >
              Go to Store Dashboard
            </button>
            <button
              type="button"
              class="mt-3 w-full inline-flex justify-center rounded-md border border-gray-300 dark:border-gray-600 shadow-sm px-4 py-2 bg-white dark:bg-gray-800 text-base font-medium text-gray-700 dark:text-gray-300 hover:bg-gray-50 dark:hover:bg-gray-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500 sm:mt-0 sm:ml-3 sm:w-auto sm:text-sm"
              @click="isSuccessModalOpen = false"
            >
              Close
            </button>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, reactive } from "vue";

// Form state
const form = reactive({
  name: "",
  username: "",
});

// UI state
const isSubmitting = ref(false);
const isSuccessModalOpen = ref(false);
const errors = reactive({
  name: "",
  username: "",
});

// Toast notification
const toast = reactive({
  show: false,
  type: "info", // 'success', 'error', 'info'
  title: "",
  message: "",
  timeout: null,
});

// Show toast notification
function showToast(type, title, message, duration = 3000) {
  // Clear any existing timeout
  if (toast.timeout) {
    clearTimeout(toast.timeout);
  }

  // Set toast properties
  toast.show = true;
  toast.type = type;
  toast.title = title;
  toast.message = message;

  // Auto hide after duration
  toast.timeout = setTimeout(() => {
    toast.show = false;
  }, duration);
}

// Validate form
function validateForm() {
  let isValid = true;

  // Reset errors
  errors.name = "";
  errors.username = "";

  // Validate name
  if (!form.name.trim()) {
    errors.name = "Store name is required";
    isValid = false;
  }

  // Validate username
  if (!form.username.trim()) {
    errors.username = "Store username is required";
    isValid = false;
  } else {
    // Check if username contains only allowed characters
    const usernameRegex = /^[a-z0-9-_]+$/;
    if (!usernameRegex.test(form.username)) {
      errors.username =
        "Username can only contain lowercase letters, numbers, hyphens, and underscores";
      isValid = false;
    }

    // Check if username is at least 3 characters
    else if (form.username.length < 3) {
      errors.username = "Username must be at least 3 characters long";
      isValid = false;
    }

    // Check if username is available (mock check)
    else {
      const takenUsernames = ["mystore", "store", "admin", "test"];
      if (takenUsernames.includes(form.username.toLowerCase())) {
        errors.username = "This username is already taken";
        isValid = false;
      }
    }
  }

  return isValid;
}

async function handleCreateStore() {
  // Validate form
  if (!validateForm()) {
    showToast("error", "Validation Error", "Please fix the errors in the form");
    return;
  }

  isSubmitting.value = true;

  try {
    // Simulate API call
    await new Promise((resolve) => setTimeout(resolve, 1500));

    // Show success toast
    showToast(
      "success",
      "Store Created",
      `Your store "${form.name}" has been created successfully!`
    );

    // Show success modal
    isSuccessModalOpen.value = true;
  } catch (error) {
    console.error("Error creating store:", error);
    showToast("error", "Error", "Failed to create store. Please try again.");
  } finally {
    isSubmitting.value = false;
  }
}

function goToStore() {
  isSuccessModalOpen.value = false;
  // In a real app, this would navigate to the store dashboard
  showToast("info", "Redirecting", "Navigating to store dashboard...");
}
</script>

<style>
/* Toast colors */
.bg-success-100 {
  background-color: #d1fae5;
}
.bg-error-100 {
  background-color: #fee2e2;
}
.bg-info-100 {
  background-color: #e0f2fe;
}
.border-success-500 {
  border-color: #10b981;
}
.border-error-500 {
  border-color: #ef4444;
}
.border-info-500 {
  border-color: #3b82f6;
}
.text-success-500 {
  color: #10b981;
}
.text-success-700 {
  color: #047857;
}
.text-error-500 {
  color: #ef4444;
}
.text-error-700 {
  color: #b91c1c;
}
.text-info-500 {
  color: #3b82f6;
}
.text-info-700 {
  color: #1d4ed8;
}
</style>
