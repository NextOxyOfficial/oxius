<template>
  <PublicSection>
    <div class="min-h-screen py-8 bg-gradient-to-b from-gray-50 to-gray-100">
      <UContainer class="max-w-4xl">
        <!-- Header Section -->
        <div class="text-center mb-10">
          <h1
            class="text-4xl font-bold bg-gradient-to-r from-emerald-500 to-green-600 bg-clip-text text-transparent mb-3"
          >
            {{ $t("settings") }}
          </h1>
          <p class="text-gray-600 max-w-xl mx-auto">
            Manage your account settings and preferences
          </p>
        </div>

        <!-- User Info Summary -->
        <div class="text-center flex gap-2 items-center justify-center mb-8">
          <div class="relative">
            <img
              v-if="userProfile.image"
              :src="userProfile.image"
              alt="Profile"
              class="w-20 h-20 rounded-full object-cover border-4 border-white shadow-md"
            />
            <div
              v-else
              class="w-20 h-20 rounded-full bg-emerald-100 flex items-center justify-center text-emerald-600 border-4 border-white shadow-md overflow-hidden"
            >
              <!-- Better profile icon fallback -->
              <UIcon
                v-if="!(userProfile.first_name || userProfile.last_name)"
                name="i-heroicons-user"
                class="w-10 h-10"
              />
              <span v-else class="text-xl font-bold">
                {{
                  userProfile.first_name ? userProfile.first_name.charAt(0) : ""
                }}
                {{
                  userProfile.last_name ? userProfile.last_name.charAt(0) : ""
                }}
              </span>
            </div>
            <!-- Verification badge remains unchanged -->
            <div
              v-if="user.user.kyc"
              class="absolute -bottom-1 -right-1 bg-white rounded-full p-1 shadow-sm"
            >
              <UIcon
                name="i-heroicons-check-badge"
                class="w-6 h-6 text-emerald-600"
              />
            </div>
          </div>
          <div class="text-left ml-2">
            <h2
              class="text-lg font-semibold text-gray-800 flex items-center gap-1"
            >
              {{ userProfile.first_name }} {{ userProfile.last_name }}
            </h2>
            <p class="text-sm text-gray-500">{{ userProfile.email }}</p>
          </div>
        </div>

        <!-- Settings Navigation -->
        <div class="bg-white rounded-xl shadow-md mb-8 overflow-hidden">
          <div class="border-b border-gray-100">
            <nav class="flex space-x-2 p-1">
              <button
                @click="activeTab = 'profile'"
                :class="[
                  'flex-1 py-3 px-4 rounded-lg font-medium transition-all',
                  activeTab === 'profile'
                    ? 'text-white bg-emerald-600 hover:bg-emerald-700'
                    : 'text-gray-600 hover:bg-gray-50',
                ]"
              >
                <div class="flex items-center justify-center gap-2">
                  <UIcon name="i-heroicons-user-circle" />
                  <span>Profile</span>
                </div>
              </button>
              <button
                @click="activeTab = 'password'"
                :class="[
                  'flex-1 py-3 px-4 rounded-lg font-medium transition-all',
                  activeTab === 'password'
                    ? 'text-white bg-emerald-600 hover:bg-emerald-700'
                    : 'text-gray-600 hover:bg-gray-50',
                ]"
              >
                <div class="flex items-center justify-center gap-2">
                  <UIcon name="i-heroicons-key" />
                  <span>Password</span>
                </div>
              </button>
            </nav>
          </div>

          <!-- Password Change Form -->
          <div v-if="activeTab === 'password'" class="p-6">
            <div class="flex items-center gap-3 mb-6">
              <div class="bg-emerald-100 p-2 rounded-full text-emerald-600">
                <UIcon name="i-heroicons-lock-closed" class="text-xl" />
              </div>
              <h2 class="text-2xl font-semibold text-gray-800">
                পাসওয়ার্ড পরিবর্তন
              </h2>
            </div>

            <form @submit.prevent="handlePasswordChange" class="space-y-6">
              <div
                class="bg-emerald-50 p-5 rounded-lg border border-emerald-100"
              >
                <p
                  class="text-sm text-emerald-800 mb-4 flex items-center gap-2"
                >
                  <UIcon name="i-heroicons-information-circle" />
                  Choose a strong password that's at least 8 characters long
                  with letters, numbers, and symbols.
                </p>

                <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
                  <div class="space-y-2">
                    <label
                      for="old_password"
                      class="block text-sm font-medium text-gray-700"
                    >
                      পুরাতন পাসওয়ার্ড
                    </label>
                    <div class="relative">
                      <input
                        id="old_password"
                        type="password"
                        v-model="old_password"
                        placeholder="********"
                        class="w-full px-4 py-3 rounded-lg border border-gray-200 focus:border-emerald-500 focus:ring focus:ring-emerald-100 outline-none transition-all bg-white"
                      />
                      <div
                        class="absolute inset-y-0 right-0 flex items-center pr-3"
                      >
                        <UIcon name="i-heroicons-key" class="text-gray-400" />
                      </div>
                    </div>
                  </div>

                  <div class="space-y-2">
                    <label
                      for="new_password"
                      class="block text-sm font-medium text-gray-700"
                    >
                      নতুন পাসওয়ার্ড
                    </label>
                    <div class="relative">
                      <input
                        id="new_password"
                        type="password"
                        v-model="new_password"
                        placeholder="********"
                        class="w-full px-4 py-3 rounded-lg border border-gray-200 focus:border-emerald-500 focus:ring focus:ring-emerald-100 outline-none transition-all bg-white"
                      />
                      <div
                        class="absolute inset-y-0 right-0 flex items-center pr-3"
                      >
                        <UIcon
                          name="i-heroicons-shield-check"
                          class="text-gray-400"
                        />
                      </div>
                    </div>
                  </div>
                </div>

                <div class="mt-4 pt-4 border-t border-emerald-200">
                  <div class="password-strength" v-if="new_password">
                    <div class="text-xs text-gray-600 mb-1">
                      Password strength
                    </div>
                    <div class="flex gap-1">
                      <div
                        :class="[
                          'h-1 flex-1 rounded-full transition-all',
                          new_password.length > 0
                            ? 'bg-red-400'
                            : 'bg-gray-200',
                          new_password.length >= 8 ? 'bg-yellow-400' : '',
                          new_password.length >= 12 &&
                          /[A-Z]/.test(new_password) &&
                          /[0-9]/.test(new_password)
                            ? 'bg-emerald-400'
                            : '',
                        ]"
                      ></div>
                      <div
                        :class="[
                          'h-1 flex-1 rounded-full transition-all',
                          new_password.length >= 8
                            ? 'bg-yellow-400'
                            : 'bg-gray-200',
                          new_password.length >= 12 &&
                          /[A-Z]/.test(new_password) &&
                          /[0-9]/.test(new_password)
                            ? 'bg-emerald-400'
                            : '',
                        ]"
                      ></div>
                      <div
                        :class="[
                          'h-1 flex-1 rounded-full transition-all',
                          new_password.length >= 12 &&
                          /[A-Z]/.test(new_password) &&
                          /[0-9]/.test(new_password)
                            ? 'bg-emerald-400'
                            : 'bg-gray-200',
                        ]"
                      ></div>
                    </div>
                  </div>
                </div>
              </div>

              <div class="flex justify-end">
                <button
                  type="submit"
                  class="bg-gradient-to-r from-emerald-500 to-green-600 hover:from-emerald-600 hover:to-green-700 text-white px-6 py-2 rounded-lg font-medium shadow-sm hover:shadow-md transition-all duration-300 hover:-translate-y-0.5 focus:ring focus:ring-emerald-200 active:translate-y-0 flex items-center gap-2"
                  :disabled="passwordLoading"
                >
                  <UIcon
                    v-if="passwordLoading"
                    name="i-heroicons-arrow-path"
                    class="animate-spin"
                  />
                  <UIcon v-else name="i-heroicons-check" />
                  Save Password
                </button>
              </div>
            </form>
          </div>

          <!-- Profile Edit Form -->
          <div v-if="activeTab === 'profile'" class="p-6">
            <div class="flex items-center gap-3 mb-6">
              <div class="bg-emerald-100 p-2 rounded-full text-emerald-600">
                <UIcon name="i-heroicons-user" class="text-xl" />
              </div>
              <h2 class="text-2xl font-semibold text-gray-800">
                Profile Information
              </h2>
            </div>

            <form
              id="profileForm"
              @submit.prevent="handleForm"
              class="space-y-6"
            >
              <!-- Profile Image Upload -->
              <div class="bg-gray-50 p-5 rounded-lg border border-gray-100">
                <label class="block text-base font-medium text-gray-700 mb-3"
                  >Profile Image</label
                >
                <div class="flex flex-wrap items-center gap-5">
                  <!-- Current image preview -->
                  <div v-if="userProfile.image" class="relative">
                    <img
                      :src="userProfile.image"
                      alt="Profile"
                      class="w-24 h-24 rounded-full object-cover border-2 border-white shadow"
                    />
                    <button
                      type="button"
                      class="absolute -top-2 -right-2 bg-white rounded-full p-1 shadow-sm text-red-500 hover:bg-red-50 transition-colors"
                      @click="showDeleteConfirmModal = true"
                      aria-label="Remove profile image"
                    >
                      <UIcon name="i-heroicons-trash" class="w-4 h-4" />
                    </button>
                  </div>
                  <!-- Image placeholder when no image -->
                  <div v-else class="relative">
                    <div
                      class="w-24 h-24 rounded-full bg-emerald-50 flex items-center justify-center border-2 border-white shadow overflow-hidden"
                    >
                      <UIcon
                        name="i-heroicons-user"
                        class="w-12 h-12 text-emerald-300"
                      />
                    </div>
                  </div>

                  <!-- Upload button - keep unchanged -->
                  <div class="relative">
                    <input
                      type="file"
                      class="absolute inset-0 w-full h-full opacity-0 cursor-pointer z-10"
                      @change="handleFileUpload($event, 'image')"
                      accept="image/*"
                    />
                    <div
                      class="flex flex-col items-center justify-center gap-2 w-24 h-24 rounded-full border-2 border-dashed border-emerald-300 bg-emerald-50 hover:bg-emerald-100 transition-colors"
                    >
                      <UIcon
                        name="i-heroicons-camera"
                        class="w-6 h-6 text-emerald-500"
                      />
                      <span class="text-xs text-emerald-600 font-medium"
                        >Upload</span
                      >
                    </div>
                  </div>
                </div>
              </div>

              <!-- Personal Information -->
              <div class="space-y-4">
                <h3 class="font-medium text-gray-700">Personal Information</h3>

                <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                  <div>
                    <label class="block text-sm font-medium text-gray-700 mb-1"
                      >First Name</label
                    >
                    <UInput
                      type="text"
                      size="md"
                      color="white"
                      placeholder="First Name"
                      v-model="userProfile.first_name"
                      :disabled="user.user.kyc"
                      class="w-full"
                    />
                  </div>

                  <div>
                    <label class="block text-sm font-medium text-gray-700 mb-1"
                      >Last Name</label
                    >
                    <UInput
                      type="text"
                      size="md"
                      color="white"
                      placeholder="Last Name"
                      v-model="userProfile.last_name"
                      :disabled="user.user.kyc"
                      class="w-full"
                    />
                  </div>
                </div>

                <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                  <div>
                    <label class="block text-sm font-medium text-gray-700 mb-1"
                      >Email</label
                    >
                    <UInput
                      type="text"
                      size="md"
                      color="white"
                      placeholder="Email"
                      v-model="userProfile.email"
                      readonly
                      disabled
                      class="w-full"
                    />
                  </div>

                  <div>
                    <label class="block text-sm font-medium text-gray-700 mb-1"
                      >Phone</label
                    >
                    <UInput
                      type="text"
                      size="md"
                      color="white"
                      placeholder="Phone"
                      v-model="userProfile.phone"
                      readonly
                      :disabled="user.user.kyc"
                      class="w-full"
                    />
                    <p
                      class="text-sm text-red-500 first-letter:capitalize mt-1"
                      v-if="errors?.phone"
                    >
                      {{ errors.phone[0] }}
                    </p>
                  </div>
                </div>
              </div>

              <!-- Address Information -->
              <div class="space-y-4">
                <h3 class="font-medium text-gray-700">Address Information</h3>

                <div>
                  <label class="block text-sm font-medium text-gray-700 mb-1"
                    >Address</label
                  >
                  <UInput
                    type="text"
                    size="md"
                    color="white"
                    placeholder="Address"
                    v-model="userProfile.address"
                    :disabled="user.user.kyc"
                    class="w-full"
                  />
                </div>

                <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
                  <div>
                    <label class="block text-sm font-medium text-gray-700 mb-1"
                      >City</label
                    >
                    <UInput
                      type="text"
                      size="md"
                      color="white"
                      placeholder="City"
                      v-model="userProfile.city"
                      :disabled="user.user.kyc"
                      class="w-full"
                    />
                  </div>

                  <div>
                    <label class="block text-sm font-medium text-gray-700 mb-1"
                      >State</label
                    >
                    <UInput
                      type="text"
                      size="md"
                      color="white"
                      placeholder="State"
                      v-model="userProfile.state"
                      :disabled="user.user.kyc"
                      class="w-full"
                    />
                  </div>

                  <div>
                    <label class="block text-sm font-medium text-gray-700 mb-1"
                      >Zip</label
                    >
                    <UInput
                      type="text"
                      size="md"
                      color="white"
                      placeholder="Zip"
                      v-model="userProfile.zip"
                      :disabled="user.user.kyc"
                      class="w-full"
                    />
                  </div>
                </div>
              </div>

              <!-- Social Media -->
              <div class="space-y-4">
                <h3 class="font-medium text-gray-700">Social Media</h3>

                <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
                  <div>
                    <label class="block text-sm font-medium text-gray-700 mb-1">
                      <div class="flex items-center gap-1">
                        <UIcon name="i-mdi:facebook" class="text-blue-600" />
                        Facebook URL
                      </div>
                    </label>
                    <UInput
                      type="text"
                      size="md"
                      color="white"
                      placeholder="Facebook URL"
                      v-model="userProfile.face_link"
                      class="w-full"
                    />
                  </div>

                  <div>
                    <label class="block text-sm font-medium text-gray-700 mb-1">
                      <div class="flex items-center gap-1">
                        <UIcon name="i-mdi:instagram" class="text-pink-600" />
                        Instagram URL
                      </div>
                    </label>
                    <UInput
                      type="text"
                      size="md"
                      color="white"
                      placeholder="Instagram URL"
                      v-model="userProfile.instagram_link"
                      class="w-full"
                    />
                  </div>

                  <div>
                    <label class="block text-sm font-medium text-gray-700 mb-1">
                      <div class="flex items-center gap-1">
                        <UIcon name="i-mdi:whatsapp" class="text-green-600" />
                        WhatsApp #
                      </div>
                    </label>
                    <UInput
                      type="text"
                      size="md"
                      color="white"
                      placeholder="WhatsApp #"
                      v-model="userProfile.whatsapp_link"
                      class="w-full"
                    />
                  </div>
                </div>
                <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
                  <div>
                    <label class="block text-sm font-medium text-gray-700 mb-1">
                      <div class="flex items-center gap-1">Profession</div>
                    </label>
                    <UInput
                      type="text"
                      size="md"
                      color="white"
                      placeholder="Enter your profession"
                      v-model="userProfile.profession"
                      class="w-full"
                    />
                  </div>

                  <div>
                    <label class="block text-sm font-medium text-gray-700 mb-1">
                      <div class="flex items-center gap-1">Company Name</div>
                    </label>
                    <UInput
                      type="text"
                      size="md"
                      color="white"
                      placeholder="Enter your company name"
                      v-model="userProfile.company"
                      class="w-full"
                    />
                  </div>

                  <div>
                    <label class="block text-sm font-medium text-gray-700 mb-1">
                      <div class="flex items-center gap-1">Website</div>
                    </label>
                    <UInput
                      type="text"
                      size="md"
                      color="white"
                      placeholder="Enter your website"
                      v-model="userProfile.website"
                      class="w-full"
                    />
                  </div>
                </div>
              </div>

              <!-- About Me -->
              <div>
                <label class="block text-sm font-medium text-gray-700 mb-1"
                  >About Me</label
                >
                <UTextarea
                  color="white"
                  variant="outline"
                  class="w-full"
                  v-model="userProfile.about"
                  resize
                  placeholder="Please provide information about your self, profession and services so that public can read about you and find interest"
                />
              </div>
            </form>
          </div>
        </div>
      </UContainer>

      <!-- Sticky Save Button -->
      <div
        v-if="activeTab === 'profile'"
        class="fixed bottom-0 left-0 right-0 bg-white bg-opacity-95 shadow-lg border-t border-gray-100 backdrop-blur-sm transition-all duration-300 z-50 mb-16 sm:mb-0"
        :class="{ 'translate-y-full': !showStickyButton }"
      >
        <div
          class="max-w-4xl mx-auto px-4 py-3 flex items-center justify-between"
        >
          <div class="text-sm text-gray-500">
            <span v-if="formDirty" class="flex items-center gap-1">
              <UIcon name="i-heroicons-pencil" class="w-4 h-4" />
              Profile has unsaved changes
            </span>
          </div>
          <button
            type="submit"
            form="profileForm"
            class="bg-gradient-to-r from-emerald-500 to-green-600 hover:from-emerald-600 hover:to-green-700 text-white px-6 py-2.5 rounded-lg font-medium shadow-sm hover:shadow-md transition-all duration-300 hover:-translate-y-0.5 focus:ring focus:ring-emerald-200 active:translate-y-0 flex items-center gap-2"
            :disabled="isLoading || !formDirty"
          >
            <UIcon
              v-if="isLoading"
              name="i-heroicons-arrow-path"
              class="animate-spin"
            />
            <UIcon v-else name="i-heroicons-check" />
            Save Profile
          </button>
        </div>
      </div>

      <div class="h-24 sm:h-16" v-if="activeTab === 'profile'">
        <!-- Increased spacer to prevent content from being hidden behind the sticky button and mobile menu -->
      </div>
    </div>
    <div
      v-if="showDeleteConfirmModal"
      class="fixed inset-0 z-10 overflow-y-auto"
      aria-labelledby="modal-title"
      role="dialog"
      aria-modal="true"
    >
      <div
        class="flex items-end justify-center min-h-screen pt-4 px-4 pb-20 text-center sm:block sm:p-0"
      >
        <div
          class="fixed inset-0 bg-gray-500 bg-opacity-75 transition-opacity backdrop-blur-sm"
          aria-hidden="true"
          @click="showDeleteConfirmModal = false"
        ></div>
        <span
          class="hidden sm:inline-block sm:align-middle sm:h-screen"
          aria-hidden="true"
          >&#8203;</span
        >
        <div
          class="inline-block align-bottom bg-white rounded-xl text-left overflow-hidden shadow-2xl transform transition-all sm:my-8 sm:align-middle sm:max-w-lg sm:w-full animate-slide-up"
        >
          <div
            class="absolute top-0 left-0 right-0 h-1 bg-gradient-to-r from-red-400 to-red-600"
          ></div>
          <div
            class="px-6 py-5 border-b border-gray-200 flex justify-between items-center"
          >
            <h3
              class="text-xl font-semibold text-gray-900 flex items-center"
              id="modal-title"
            >
              <AlertTriangle class="h-5 w-5 mr-2 text-red-500" />
              Confirm Deletion
            </h3>
            <button
              @click="showDeleteConfirmModal = false"
              class="text-gray-400 hover:text-gray-500 transition-colors duration-150"
            >
              <X class="h-6 w-6" />
            </button>
          </div>
          <div class="px-6 py-4">
            <p class="text-gray-700">
              Are you sure you want to delete profile image?
            </p>
          </div>
          <div class="bg-gray-50 px-6 py-4 flex justify-end space-x-3">
            <button
              @click="deleteUpload()"
              class="inline-flex justify-center items-center rounded-md border border-transparent shadow-sm px-4 py-2 bg-gradient-to-r from-red-500 to-red-600 text-base font-medium text-white hover:from-red-600 hover:to-red-700 focus:outline-none sm:text-sm transition-all duration-200 transform hover:-translate-y-0.5"
              :disabled="isProcessing"
            >
              <span v-if="!isProcessing" class="flex items-center">
                <Trash2 class="h-4 w-4 mr-1.5" />
                Delete
              </span>
              <span v-else class="flex items-center">
                <Loader2 class="h-4 w-4 mr-1.5 animate-spin" />
                Deleting...
              </span>
            </button>
            <button
              @click="showDeleteConfirmModal = false"
              class="inline-flex justify-center items-center rounded-md border border-gray-300 shadow-sm px-4 py-2 bg-white text-base font-medium text-gray-700 hover:bg-gray-50 focus:outline-none sm:text-sm transition-colors duration-200"
            >
              <X class="h-4 w-4 mr-1.5" />
              Cancel
            </button>
          </div>
        </div>
      </div>
    </div>
  </PublicSection>
</template>

<script setup>
definePageMeta({
  layout: "dashboard",
});
import { Trash2, X, AlertTriangle, Loader2 } from "lucide-vue-next";
const { get, post, put } = useApi();
const { user } = useAuth();
const toast = useToast();
// State Management
const showDeleteConfirmModal = ref(false);
const isProcessing = ref(false);
const activeTab = ref("profile");
const userProfile = ref({});
const errors = ref({});
const isLoading = ref(false);
const passwordLoading = ref(false);
const old_password = ref("");
const new_password = ref("");

// Add these new state variables
const showStickyButton = ref(true);
const formDirty = ref(false);
const originalProfile = ref({});
const lastScrollPosition = ref(0);
const activeToasts = ref(new Set()); // Track active toast messages

// Improved toast function to prevent duplicates and ensure timeouts
function showToast(title, description, color, timeout = 5000) {
  // Create a unique key for this toast message
  const messageKey = `${title}:${description}`;

  // Check if this exact toast is already showing
  if (activeToasts.value.has(messageKey)) {
    return; // Skip showing duplicate toast
  }

  // Add to active toasts set
  activeToasts.value.add(messageKey);

  // Show the toast with guaranteed timeout
  const toastId = toast.add({
    title,
    description,
    color,
    timeout: timeout, // Default 5 seconds unless specified otherwise
    onClose: () => {
      activeToasts.value.delete(messageKey); // Remove from active toasts
    },
  });

  // Safety mechanism: ensure toast is removed after timeout + 1s buffer
  if (timeout > 0) {
    setTimeout(() => {
      toast.remove(toastId);
      activeToasts.value.delete(messageKey);
    }, timeout + 1000);
  }

  return toastId;
}

// Add scroll detection
function handleScroll() {
  // Show/hide button based on scroll direction
  const currentScrollPosition = window.scrollY;

  if (currentScrollPosition < 100) {
    // Always show at the top of the page
    showStickyButton.value = true;
  } else if (currentScrollPosition < lastScrollPosition.value) {
    // Scrolling up - show the button
    showStickyButton.value = true;
  } else if (currentScrollPosition > lastScrollPosition.value) {
    // Scrolling down - hide the button
    showStickyButton.value = false;
  }

  lastScrollPosition.value = currentScrollPosition;
}

// Track form changes
function checkFormChanges() {
  if (
    !originalProfile.value ||
    Object.keys(originalProfile.value).length === 0
  ) {
    return;
  }

  // Compare current form with original values
  const currentValues = JSON.stringify(userProfile.value);
  const originalValues = JSON.stringify(originalProfile.value);

  formDirty.value = currentValues !== originalValues;
}

// Watch for profile changes
watch(
  userProfile,
  () => {
    checkFormChanges();
  },
  { deep: true }
);

// Fetch user profile details
async function getUserDetails() {
  try {
    const res = await get(`/persons/${user.value?.user.email}/`);
    userProfile.value = res.data;
    // Store original state for comparison
    originalProfile.value = JSON.parse(JSON.stringify(res.data));
    formDirty.value = false;
  } catch (error) {
    console.error("Error fetching user details:", error);
    showToast("Error", "Failed to load profile data", "red");
  }
}

// After successful form submission, update original profile
const handleFormSuccess = () => {
  originalProfile.value = JSON.parse(JSON.stringify(userProfile.value));
  formDirty.value = false;
};

// Handle password change
async function handlePasswordChange() {
  if (!old_password.value || !new_password.value) {
    showToast("Error", "Both password fields are required", "red");
    return;
  }

  passwordLoading.value = true;

  try {
    const { data } = await post("/change-password/", {
      old_password: old_password.value,
      new_password: new_password.value,
    });

    if (data) {
      showToast(
        "Success",
        data.message || "Password successfully changed",
        "green"
      );
      old_password.value = "";
      new_password.value = "";
    }
  } catch (error) {
    showToast(
      "Error",
      error.response?.data?.message || "Failed to change password",
      "red"
    );
    console.error(error);
  } finally {
    passwordLoading.value = false;
  }
}

// Handle profile update
async function handleForm() {
  isLoading.value = true;

  try {
    // Create a copy of the profile data
    const profileData = { ...userProfile.value };

    // Set the name properly
    profileData.name = `${profileData.first_name || ""} ${
      profileData.last_name || ""
    }`.trim();

    // Remove properties that shouldn't be sent to the API
    const {
      groups,
      user_permissions,
      nid,
      refer,
      store_logo,
      store_banner,
      ...dataToSend
    } = profileData;

    // Handle image more explicitly
    if (typeof profileData.image === "string") {
      if (profileData.image.includes("data:image")) {
        // This is a new image upload as base64
        dataToSend.image = profileData.image;
      } else if (profileData.image.includes("http")) {
        // This is an existing image URL - don't include it in the update
        delete dataToSend.image;
      }
    } else {
      // Explicitly set image to empty string for removal
      // Some APIs handle null differently than empty string, so try both approaches
      dataToSend.image = "";
    }

    console.log(
      "Sending profile update with image type:",
      dataToSend.image
        ? typeof dataToSend.image === "string"
          ? "string"
          : typeof dataToSend.image
        : "empty"
    );

    const res = await put(`/persons/update/${profileData.email}/`, dataToSend);

    if (res.data?.data?.email) {
      showToast("Success", "Profile updated successfully", "green");
      // Update the profile with the returned data
      userProfile.value = res.data.data;
      errors.value = {};
      // Mark form as clean after successful submission
      handleFormSuccess();

      // Refresh profile data to ensure we get the latest from the server
      await getUserDetails();
    } else {
      errors.value = res?.error?.data?.errors || {};
      showToast("Error", "Failed to update profile", "red");
    }
  } catch (error) {
    console.error("Profile update error:", error);
    // More detailed error message
    showToast(
      "Error",
      error.response?.data?.message ||
        "Profile update failed. Check your internet connection or try again.",
      "red"
    );
  } finally {
    isLoading.value = false;
  }
}

// Handle profile image upload
function handleFileUpload(event, field) {
  const files = Array.from(event.target.files);
  if (!files.length) return;

  const file = files[0];

  // More thorough validation
  if (!file.type.match(/^image\/(jpeg|png|gif|webp|bmp)$/i)) {
    showToast(
      "Invalid File Type",
      "Please select a valid image file (JPEG, PNG, GIF)",
      "red"
    );
    return;
  }

  // More reasonable size limit with clear message
  const maxSize = 1 * 1024 * 1024; // 1MB
  if (file.size > maxSize) {
    showToast(
      "File Too Large",
      `Image must be smaller than 1MB. Current size: ${(
        file.size /
        (1024 * 1024)
      ).toFixed(1)}MB`,
      "red"
    );
    return;
  }

  // Show loading state
  const loadingToast = showToast(
    "Processing Image",
    "Please wait while we process your image...",
    "blue",
    0 // No timeout for loading toast
  );

  const reader = new FileReader();

  reader.onload = () => {
    // Resize the image if needed
    const img = new Image();
    img.onload = function () {
      // Remove the loading toast
      toast.remove(loadingToast);
      activeToasts.value.delete(
        "Processing Image:Please wait while we process your image..."
      );

      // If image is already small enough, use as is
      if (reader.result.length <= maxSize) {
        userProfile.value.image = reader.result;
        showToast(
          "Image Ready",
          "Your image has been prepared for upload",
          "green"
        );
        return;
      }

      // Otherwise, resize the image
      const MAX_WIDTH = 800;
      const MAX_HEIGHT = 800;

      let width = img.width;
      let height = img.height;

      // Calculate new dimensions
      if (width > height) {
        if (width > MAX_WIDTH) {
          height *= MAX_WIDTH / width;
          width = MAX_WIDTH;
        }
      } else {
        if (height > MAX_HEIGHT) {
          width *= MAX_HEIGHT / height;
          height = MAX_HEIGHT;
        }
      }

      // Create canvas to resize image
      const canvas = document.createElement("canvas");
      canvas.width = width;
      canvas.height = height;

      // Draw image at new size
      const ctx = canvas.getContext("2d");
      ctx.drawImage(img, 0, 0, width, height);

      // Get resized image as base64 string
      const quality = 0.8; // Good balance between size and quality
      const resizedImage = canvas.toDataURL("image/jpeg", quality);

      // Update the profile image
      userProfile.value.image = resizedImage;

      showToast(
        "Image Ready",
        "Your image has been resized and is ready for upload",
        "green"
      );
    };
    img.src = reader.result;
  };

  reader.onerror = (error) => {
    toast.remove(loadingToast);
    activeToasts.value.delete(
      "Processing Image:Please wait while we process your image..."
    );
    console.error("Error reading file:", error);
    showToast("Error", "Failed to process the image file", "red");
  };

  reader.readAsDataURL(file);
}

// Handle profile image removal
async function deleteUpload() {
  // Mark as explicitly null to ensure the API recognizes it's being removed
  userProfile.value.image = null;

  // Mark form as dirty to enable the save button
  formDirty.value = true;
  isProcessing.value = true;
  try {
    const res = await post(`/persons/${user.value.user.email}/delete_image/`);
    if (res.data) {
      showToast("Success", "Image removed successfully", "green");
      showDeleteConfirmModal.value = false;
    }
  } catch (error) {
    console.error("Error removing image:", error);
    showToast("Error", "Failed to remove image", "red");
  } finally {
    isProcessing.value = false;
  }
}

// Add event listeners when component is mounted
onMounted(() => {
  window.addEventListener("scroll", handleScroll);
});

// Clean up event listeners when component is unmounted
onUnmounted(() => {
  window.removeEventListener("scroll", handleScroll);
});

getUserDetails();
</script>

<style scoped>
/* Add these styles for smooth transition */
.translate-y-full {
  transform: translateY(100%);
}

/* Ensure toast doesn't overlap with sticky button on mobile */
:global(.u-toast-container) {
  bottom: calc(4.5rem + env(safe-area-inset-bottom)) !important;
  z-index: 60;
}

@media (min-width: 640px) {
  :global(.u-toast-container) {
    bottom: calc(3.5rem + env(safe-area-inset-bottom)) !important;
  }
}
</style>
