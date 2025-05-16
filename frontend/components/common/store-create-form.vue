<template>
  <div class="py-10">
    <!-- Toast Notification -->
    <div v-if="toast.show" class="fixed top-4 right-4 z-50 max-w-md">
      <div
        :class="`bg-${toast.type}-100 border-l-4 border-${toast.type}-500 text-${toast.type}-700 p-4 rounded shadow-sm`"
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
            <p class="font-semibold">{{ toast.title }}</p>
            <p class="text-sm">{{ toast.message }}</p>
          </div>
        </div>
      </div>
    </div>

    <div class="max-w-md mx-auto">
      <!-- Page Header -->
      <div class="mb-8 text-center">
        <h1
          class="text-3xl font-semibold text-indigo-600 dark:text-indigo-400 mb-2"
        >
          Create Your Store
        </h1>
        <p class="text-gray-600 dark:text-gray-300">
          Set up your online store and start selling your products
        </p>
      </div>

      <!-- Form Container -->
      <div class="bg-white dark:bg-gray-800 rounded-lg shadow-sm p-6">
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
                v-model="form.store_name"
                type="text"
                class="block w-full pl-10 pr-3 py-2 border border-gray-300 dark:border-gray-600 rounded-md shadow-sm placeholder-gray-400 focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 dark:bg-gray-700 dark:text-white"
                placeholder="Enter your business name"
              />
            </div>
            <p v-if="errors.store_name" class="mt-1 text-sm text-red-600">
              {{ errors.store_name }}
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
                :value="form.store_username"
                @change="handleStoreUsername"
                @blur="checkUsernameAvailability"
                type="text"
                class="block w-full pl-10 pr-3 py-2 border border-gray-300 dark:border-gray-600 rounded-md shadow-sm placeholder-gray-400 focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 dark:bg-gray-700 dark:text-white lowercase"
                placeholder="Enter your store username"
              />
              <div v-if="isCheckingUsername" class="absolute right-3 top-2">
                <div
                  class="animate-spin h-5 w-5 border-2 border-indigo-500 rounded-full border-t-transparent"
                ></div>
              </div>
            </div>

            <!-- Username availability messages -->
            <div
              v-if="usernameAvailability.checked && form.store_username"
              class="mt-1"
            >
              <p
                v-if="usernameAvailability.available"
                class="text-sm text-green-600"
              >
                <span class="flex items-center">
                  <svg
                    class="h-4 w-4 mr-1"
                    fill="none"
                    stroke="currentColor"
                    viewBox="0 0 24 24"
                  >
                    <path
                      stroke-linecap="round"
                      stroke-linejoin="round"
                      stroke-width="2"
                      d="M5 13l4 4L19 7"
                    ></path>
                  </svg>
                  Username is available!
                </span>
              </p>
              <div v-else>
                <p class="text-sm text-red-600 flex items-center">
                  <svg
                    class="h-4 w-4 mr-1"
                    fill="none"
                    stroke="currentColor"
                    viewBox="0 0 24 24"
                  >
                    <path
                      stroke-linecap="round"
                      stroke-linejoin="round"
                      stroke-width="2"
                      d="M6 18L18 6M6 6l12 12"
                    ></path>
                  </svg>
                  This username is already taken
                </p>
                <div
                  v-if="usernameAvailability.suggestions.length > 0"
                  class="mt-2"
                >
                  <p class="text-xs text-gray-500 dark:text-gray-400">
                    Try one of these instead:
                  </p>
                  <div class="flex flex-wrap gap-2 mt-1">
                    <button
                      v-for="suggestion in usernameAvailability.suggestions"
                      :key="suggestion"
                      @click="selectSuggestion(suggestion)"
                      class="px-2 py-1 text-xs bg-gray-100 dark:bg-gray-700 hover:bg-indigo-100 dark:hover:bg-indigo-900 rounded text-gray-700 dark:text-gray-300 hover:text-indigo-700 dark:hover:text-indigo-300"
                    >
                      {{ suggestion }}
                    </button>
                  </div>
                </div>
              </div>
            </div>

            <p v-if="errors.store_username" class="mt-1 text-sm text-red-600">
              {{ errors.store_username }}
            </p>

            <!-- Store URL Preview -->
            <div class="mt-3 p-3 bg-gray-50 dark:bg-gray-700 rounded-md">
              <p class="text-xs text-gray-500 dark:text-gray-400 mb-1">
                Your store URL will be:
              </p>
              <div class="flex items-center break-words">
                <span class="text-sm text-gray-600 dark:text-gray-300"
                  >https://adsyclub.com/eshop/</span
                >
                <span
                  class="text-sm text-indigo-600 dark:text-indigo-400 font-medium lowercase"
                  >{{ form.store_username || "your-store" }}</span
                >
              </div>
            </div>
          </div>

          <!-- Submit Button -->
          <div class="mt-8">
            <button
              v-if="user?.user?.kyc"
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
            <button
              v-else
              @click="isOpen = true"
              type="button"
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
          class="inline-block align-bottom bg-white dark:bg-gray-800 rounded-lg text-left overflow-hidden shadow-sm transform transition-all sm:my-8 sm:align-middle sm:max-w-lg sm:w-full"
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
                    Your store {{ form.store_name }}" has been created. You can
                    now start adding products and customizing your store.
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
    <UModal v-model="isOpen">
      <div class="p-4">
        <div class="flex items-center mb-4">
          <div class="mr-3 bg-amber-100 rounded-full p-2">
            <UIcon
              name="i-heroicons-exclamation-triangle"
              class="w-6 h-6 text-amber-600"
            />
          </div>
          <h3 class="text-lg font-medium">KYC Verification Required</h3>
        </div>

        <p class="text-sm text-gray-500 dark:text-gray-400 mb-4">
          Before creating a store, you need to complete your KYC verification.
          This helps us ensure platform security and comply with regulations.
        </p>

        <div class="flex justify-end gap-3 mt-4">
          <UButton color="gray" variant="soft" @click="isOpen = false">
            Cancel
          </UButton>
          <UButton to="/upload-center" color="primary" @click="goToKYC">
            Complete KYC Verification
          </UButton>
        </div>
      </div>
    </UModal>
  </div>
</template>

<script setup>
const { user, jwtLogin } = useAuth();
const { put, get } = useApi();
const isOpen = ref(false);

const { getStoreDetails } = defineProps({
  getStoreDetails: {
    type: Function,
  },
});
// Form state
const form = reactive({
  store_name: "",
  store_username: "",
});

// UI state
const isSubmitting = ref(false);
const isSuccessModalOpen = ref(false);
const errors = reactive({
  store_name: "",
  store_username: "",
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

// Add these new variables and methods to your script
const isCheckingUsername = ref(false);
const usernameAvailability = reactive({
  checked: false,
  available: false,
  suggestions: [],
});

async function checkUsernameAvailability() {
  // Don't check if the username is empty or too short
  if (!form.store_username || form.store_username.length < 3) {
    usernameAvailability.checked = false;
    return;
  }

  try {
    isCheckingUsername.value = true;

    // Call the API endpoint
    const response = await get(
      `/check-store-username/?username=${encodeURIComponent(
        form.store_username
      )}`
    );

    usernameAvailability.checked = true;
    usernameAvailability.available = response.data.available;

    // If not available, store suggestions
    if (!response.data.available && response.data.suggestions) {
      usernameAvailability.suggestions = response.data.suggestions;
    } else {
      usernameAvailability.suggestions = [];
    }

    // Clear the error if the username is available
    if (response.data.available) {
      errors.store_username = "";
    }
  } catch (error) {
    console.error("Error checking username availability:", error);
    usernameAvailability.checked = false;
  } finally {
    isCheckingUsername.value = false;
  }
}

function selectSuggestion(suggestion) {
  form.store_username = suggestion;
  usernameAvailability.available = true;
  usernameAvailability.suggestions = [];
  errors.store_username = "";
}

// Modify your existing handleStoreUsername function to also check availability
function handleStoreUsername(e) {
  form.store_username = e.target.value.toLowerCase();
  usernameAvailability.checked = false; // Reset check when username changes
}

// Update validateForm to use the availability check result
function validateForm() {
  let isValid = true;

  // Reset errors
  errors.store_name = "";
  errors.store_username = "";

  // Validate name
  if (!form.store_name.trim()) {
    errors.store_name = "Store name is required";
    isValid = false;
  }

  // Validate username
  if (!form.store_username.trim()) {
    errors.store_username = "Store username is required";
    isValid = false;
  } else {
    // Check if username contains only allowed characters
    const usernameRegex = /^[a-z0-9-_]+$/;
    if (!usernameRegex.test(form.store_username)) {
      errors.store_username =
        "Username can only contain lowercase letters, numbers, hyphens, and underscores";
      isValid = false;
    }
    // Check if username is at least 3 characters
    else if (form.store_username.length < 3) {
      errors.store_username = "Username must be at least 3 characters long";
      isValid = false;
    }
    // Check if username has been checked and is not available
    else if (usernameAvailability.checked && !usernameAvailability.available) {
      errors.store_username = "This username is already taken";
      isValid = false;
    }
  }

  return isValid;
}

async function handleCreateStore() {
  if (!user.value?.user?.kyc) {
    isOpen.value = true;
    return;
  }
  // Validate form
  if (!validateForm()) {
    showToast("error", "Validation Error", "Please fix the errors in the form");
    return;
  }

  isSubmitting.value = true;

  try {
    // Simulate API call
    const res = await put(`/persons/update/${user.value?.user?.email}/`, {
      store_name: form.store_name,
      store_username: form.store_username.toLowerCase(),
    });
    console.log(res);
    if (res.data) {
      // Show success toast
      showToast(
        "success",
        "Store Created",
        `Your store "${form.name}" has been created successfully!`
      );
      form.store_name = "";
      form.store_username = "";
      getStoreDetails();
      jwtLogin();
    }

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
