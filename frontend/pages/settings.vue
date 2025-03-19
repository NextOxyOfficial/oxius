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
              class="w-20 h-20 rounded-full bg-emerald-100 flex items-center justify-center text-emerald-600 text-xl font-bold border-4 border-white shadow-md"
            >
              {{ userProfile.first_name ? userProfile.first_name.charAt(0) : ""
              }}{{
                userProfile.last_name ? userProfile.last_name.charAt(0) : ""
              }}
            </div>
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

            <form @submit.prevent="handleForm" class="space-y-6">
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
                      @click="deleteUpload()"
                      aria-label="Remove profile image"
                    >
                      <UIcon name="i-heroicons-trash" class="w-4 h-4" />
                    </button>
                  </div>

                  <!-- Upload button -->
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

              <div class="flex justify-end">
                <button
                  type="submit"
                  class="bg-gradient-to-r from-emerald-500 to-green-600 hover:from-emerald-600 hover:to-green-700 text-white px-8 py-3 rounded-lg font-medium shadow-sm hover:shadow-md transition-all duration-300 hover:-translate-y-0.5 focus:ring focus:ring-emerald-200 active:translate-y-0 flex items-center gap-2"
                  :disabled="isLoading"
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
            </form>
          </div>
        </div>
      </UContainer>
    </div>
  </PublicSection>
</template>

<script setup>
definePageMeta({
  layout: "dashboard",
});

// API & Auth
const { get, post, put } = useApi();
const { user } = useAuth();
const toast = useToast();

// State Management
const activeTab = ref("profile");
const userProfile = ref({});
const errors = ref({});
const isLoading = ref(false);
const passwordLoading = ref(false);
const old_password = ref("");
const new_password = ref("");

// Fetch user profile details
async function getUserDetails() {
  try {
    const res = await get(`/persons/${user.value.user.email}/`);
    userProfile.value = res.data;
  } catch (error) {
    console.error("Error fetching user details:", error);
    toast.add({
      title: "Error",
      description: "Failed to load profile data",
      color: "red",
    });
  }
}

// Handle password change
async function handlePasswordChange() {
  if (!old_password.value || !new_password.value) {
    toast.add({
      title: "Error",
      description: "Both password fields are required",
      color: "red",
    });
    return;
  }

  passwordLoading.value = true;

  try {
    const { data } = await post("/change-password/", {
      old_password: old_password.value,
      new_password: new_password.value,
    });

    if (data) {
      toast.add({
        title: "Success",
        description: data.message || "Password successfully changed",
        color: "green",
      });
      old_password.value = "";
      new_password.value = "";
    }
  } catch (error) {
    toast.add({
      title: "Error",
      description: error.response?.data?.message || "Failed to change password",
      color: "red",
    });
    console.error(error);
  } finally {
    passwordLoading.value = false;
  }
}

// Handle profile update
async function handleForm() {
  const { groups, user_permissions, image, nid, refer, ...rest } =
    userProfile.value;
  rest.name = userProfile.value.first_name + " " + userProfile.value.last_name;

  // Handle image properly
  if (typeof image === "string") {
    if (image.includes("data:image")) {
      rest.image = image;
    } else {
      console.log("Image type is string; omitting from request.");
    }
  } else if (image === null) {
    console.log("Image is null; omitting from request.");
  } else {
    rest.image = image;
  }

  isLoading.value = true;

  try {
    const res = await put(`/persons/update/${userProfile.value.email}/`, rest);

    if (res.data?.data?.email) {
      toast.add({
        title: "Success",
        description: res.data?.message || "Profile updated successfully",
        color: "green",
      });
      res.data.data.image = res.data.data.image ? res.data.data.image : null;
      userProfile.value = res.data.data;
      errors.value = {};
    } else {
      errors.value = res?.error?.data.errors;
      toast.add({
        title: "Error",
        description: "Failed to update profile",
        color: "red",
      });
    }
  } catch (error) {
    toast.add({
      title: "Error",
      description: error.toString(),
      color: "red",
    });
  } finally {
    isLoading.value = false;
  }
}

// Handle profile image upload
function handleFileUpload(event, field) {
  const files = Array.from(event.target.files);
  if (!files.length) return;

  const file = files[0];

  // Validate file type
  if (!file.type.match("image.*")) {
    toast.add({
      title: "Error",
      description: "Please select an image file",
      color: "red",
    });
    return;
  }

  // Validate file size (2MB max)
  if (file.size > 2 * 1024 * 1024) {
    toast.add({
      title: "Error",
      description: "Image size should be less than 2MB",
      color: "red",
    });
    return;
  }

  const reader = new FileReader();

  reader.onload = () => {
    userProfile.value.image = reader.result;
  };

  reader.onerror = (error) => {
    console.error("Error reading file:", error);
    toast.add({
      title: "Error",
      description: "Failed to read the image file",
      color: "red",
    });
  };

  reader.readAsDataURL(file);
}

// Handle profile image removal
function deleteUpload() {
  userProfile.value.image = null;
}

// Load user data on component mount
onMounted(() => {
  getUserDetails();
});
</script>
