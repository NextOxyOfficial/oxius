<!-- Gold Sponsor Application Modal -->
<template>
  <transition
    enter-active-class="transition duration-300 ease-out"
    enter-from-class="transform scale-95 opacity-0"
    enter-to-class="transform scale-100 opacity-100"
    leave-active-class="transition duration-200 ease-in"
    leave-from-class="transform scale-100 opacity-100"
    leave-to-class="transform scale-95 opacity-0"
  >
    <div
      v-if="isOpen"
      class="fixed inset-0 z-[9999] overflow-y-auto"
      aria-labelledby="gold-sponsor-modal"
      role="dialog"
      aria-modal="true"
    >
      <div
        class="flex items-end justify-center min-h-screen pt-20 pb-20 text-center sm:block"
      >
        <!-- Background overlay -->
        <div
          class="fixed inset-0 bg-gray-500 bg-opacity-75 transition-opacity"
          aria-hidden="true"
          @click="close"
        ></div>
        <!-- Modal panel -->
        <div
          class="inline-block align-bottom bg-white dark:bg-slate-800 rounded-lg text-left overflow-hidden shadow-xl transform transition-all sm:my-8 sm:align-middle sm:max-w-2xl sm:w-full"
        >
          <div class="absolute top-0 right-0 pt-4 pr-4 z-50">
            <button
              type="button"
              @click="close"
              class="bg-white flex items-center justify-center dark:bg-slate-700 rounded-full p-1 text-gray-400 hover:text-gray-600 dark:hover:text-gray-300 focus:outline-none shadow-md"
            >
              <span class="sr-only">Close</span>
              <UIcon name="i-heroicons-x-mark" class="h-6 w-6" />
            </button>
          </div>

          <!-- Gold sponsor header -->
          <div
            class="relative h-24 bg-gradient-to-r from-amber-500 to-yellow-500 overflow-hidden"
          >
            <div class="absolute inset-0 opacity-30">
              <div
                class="absolute inset-0 bg-amber-500 rotate-45 transform origin-top-left"
              ></div>
              <div
                class="absolute bottom-0 right-0 w-20 h-20 rounded-full bg-yellow-300 -mb-10 -mr-10"
              ></div>
              <div
                class="absolute top-5 right-10 text-4xl text-white opacity-50"
              >
                ✦
              </div>
            </div>
            <div class="absolute inset-0 flex items-center justify-center">
              <h2 class="text-2xl font-bold text-white">
                {{ isEditMode ? "Edit Gold Sponsor" : "Become a Gold Sponsor" }}
              </h2>
            </div>
          </div>

          <!-- Form content -->
          <div class="bg-white dark:bg-slate-800 px-4 pt-5 pb-6 sm:p-6">
            <p class="text-sm text-gray-600 dark:text-gray-300 mb-5">
              Join our exclusive Gold Sponsors and showcase your business to
              thousands of potential customers. Gold Sponsors receive premium
              visibility and additional benefits.
            </p>

            <form @submit.prevent="submitForm">
              <!-- Business Information -->
              <div class="space-y-4">
                <div>
                  <label
                    for="businessName"
                    class="block text-sm font-medium text-gray-800 dark:text-gray-300 mb-1"
                    >Business Name</label
                  >
                  <input
                    id="businessName"
                    v-model="form.businessName"
                    type="text"
                    class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-md focus:outline-none focus:ring-2 focus:ring-amber-500 dark:bg-slate-700 dark:text-white"
                    placeholder="Your business name"
                    required
                  />
                </div>

                <div>
                  <label
                    for="businessDescription"
                    class="block text-sm font-medium text-gray-800 dark:text-gray-300 mb-1"
                    >Business Description</label
                  >
                  <CommonEditor
                    v-model="form.businessDescription"
                    @updateContent="updateContent"
                    class="editor-container text-left"
                    placeholder="Describe your business (max 200 characters)"
                  />
                </div>

                <div>
                  <label
                    for="contactEmail"
                    class="block text-sm font-medium text-gray-800 dark:text-gray-300 mb-1"
                    >Contact Email</label
                  >
                  <input
                    id="contactEmail"
                    v-model="form.contactEmail"
                    type="email"
                    class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-md focus:outline-none focus:ring-2 focus:ring-amber-500 dark:bg-slate-700 dark:text-white"
                    placeholder="email@example.com"
                    required
                  />
                </div>
                <div>
                  <label
                    for="phoneNumber"
                    class="block text-sm font-medium text-gray-800 dark:text-gray-300 mb-1"
                    >Phone Number</label
                  >
                  <input
                    id="phoneNumber"
                    v-model="form.phoneNumber"
                    type="text"
                    class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-md focus:outline-none focus:ring-2 focus:ring-amber-500 dark:bg-slate-700 dark:text-white"
                    placeholder="Enter your phone number"
                    required
                  />
                </div>
                <div>
                  <label
                    for="website"
                    class="block text-sm font-medium text-gray-800 dark:text-gray-300 mb-1"
                    >Website URL</label
                  >
                  <input
                    id="website"
                    v-model="form.website"
                    type="text"
                    class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-md focus:outline-none focus:ring-2 focus:ring-amber-500 dark:bg-slate-700 dark:text-white"
                    placeholder="example.com"
                  />
                </div>

                <div>
                  <label
                    for="profileUrl"
                    class="block text-sm font-medium text-gray-800 dark:text-gray-300 mb-1"
                    >Profile URL
                    <span class="text-xs text-gray-600"
                      >(Users will be redirected here when clicking "Visit
                      Sponsor's Profile")</span
                    ></label
                  >
                  <input
                    id="profileUrl"
                    v-model="form.profileUrl"
                    type="text"
                    class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-md focus:outline-none focus:ring-2 focus:ring-amber-500 dark:bg-slate-700 dark:text-white"
                    placeholder="www.example.com"
                  />
                </div>

                <!-- Logo Upload -->
                <div>
                  <label
                    for="logo"
                    class="block text-sm font-medium text-gray-800 dark:text-gray-300 mb-1"
                    >Business Logo</label
                  >
                  <div class="mt-1 flex items-center space-x-3">
                    <div
                      class="relative h-16 w-16 rounded-md border border-gray-300 dark:border-gray-600 overflow-hidden bg-gray-100 dark:bg-gray-700"
                    >
                      <img
                        v-if="logoPreview"
                        :src="logoPreview"
                        alt="Logo preview"
                        class="h-full w-full object-cover"
                      />
                      <div
                        v-else
                        class="h-full w-full flex items-center justify-center text-gray-400"
                      >
                        <UIcon name="i-heroicons-photo" class="h-8 w-8" />
                      </div>
                    </div>
                    <div class="flex flex-col">
                      <label
                        for="logoFile"
                        class="cursor-pointer px-3 py-1.5 text-xs bg-white dark:bg-slate-700 border border-gray-300 dark:border-gray-600 rounded-md hover:bg-gray-50 dark:hover:bg-slate-600 text-gray-800 dark:text-gray-300"
                      >
                        Choose File
                      </label>
                      <span
                        class="text-xs text-gray-600 dark:text-gray-400 mt-1"
                      >
                        {{ logoFilename || "No file chosen" }}
                      </span>
                    </div>
                    <input
                      type="file"
                      id="logoFile"
                      ref="logoFileInput"
                      @change="handleLogoUpload"
                      accept="image/png,image/jpeg,image/jpg,image/svg+xml"
                      class="hidden"
                    />
                  </div>
                  <p class="mt-1 text-xs text-gray-600 dark:text-gray-400">
                    Recommended: 250x250px, PNG or JPG
                  </p>
                </div>

                <!-- Banner Upload Section -->
                <div>
                  <label
                    class="block text-sm font-medium text-gray-800 dark:text-gray-300 mb-2"
                    >Promotional Banners (Optional)</label
                  >
                  <p class="text-xs text-gray-600 dark:text-gray-400 mb-3">
                    Upload banners to showcase your business. These will be
                    displayed in your sponsor details.
                  </p>

                  <!-- Banner List -->
                  <div v-if="banners.length > 0" class="space-y-3 mb-3">
                    <div
                      v-for="(banner, index) in banners"
                      :key="banner.id"
                      class="border border-gray-200 dark:border-gray-600 rounded-lg p-3"
                    >
                      <div class="flex items-start space-x-3">
                        <!-- Banner Preview -->
                        <div
                          class="relative h-16 w-24 rounded border border-gray-300 dark:border-gray-600 overflow-hidden bg-gray-100 dark:bg-gray-700 flex-shrink-0"
                        >
                          <img
                            v-if="banner.imagePreview"
                            :src="banner.imagePreview"
                            alt="Banner preview"
                            class="h-full w-full object-cover"
                          />
                          <div
                            v-else
                            class="h-full w-full flex items-center justify-center text-gray-400"
                          >
                            <UIcon name="i-heroicons-photo" class="h-6 w-6" />
                          </div>
                        </div>

                        <!-- Banner Details -->
                        <div class="flex-1 space-y-2">
                          <div>
                            <input
                              v-model="banner.title"
                              type="text"
                              placeholder="Banner title (optional)"
                              class="w-full px-2 py-1 text-sm border border-gray-300 dark:border-gray-600 rounded focus:outline-none focus:ring-1 focus:ring-amber-500 dark:bg-slate-700 dark:text-white"
                            />
                          </div>
                          <div>
                            <input
                              v-model="banner.link_url"
                              type="url"
                              placeholder="Link URL (optional)"
                              class="w-full px-2 py-1 text-sm border border-gray-300 dark:border-gray-600 rounded focus:outline-none focus:ring-1 focus:ring-amber-500 dark:bg-slate-700 dark:text-white"
                            />
                          </div>
                          <div class="flex items-center space-x-2">
                            <label
                              :for="`bannerFile-${index}`"
                              class="cursor-pointer px-2 py-1 text-xs bg-white dark:bg-slate-700 border border-gray-300 dark:border-gray-600 rounded hover:bg-gray-50 dark:hover:bg-slate-600 text-gray-800 dark:text-gray-300"
                            >
                              Choose Image
                            </label>
                            <input
                              :id="`bannerFile-${index}`"
                              type="file"
                              @change="handleBannerUpload($event, index)"
                              accept="image/png,image/jpeg,image/jpg"
                              class="hidden"
                            />
                            <button
                              type="button"
                              @click="removeBanner(index)"
                              class="px-2 py-1 text-xs text-red-600 hover:text-red-700 border border-red-300 rounded hover:bg-red-50"
                            >
                              Remove
                            </button>
                          </div>
                        </div>
                      </div>
                    </div>
                  </div>

                  <!-- Add Banner Button -->
                  <button
                    v-if="banners.length < maxBanners"
                    type="button"
                    @click="addBanner"
                    class="w-full py-2 px-3 border-2 border-dashed border-gray-300 dark:border-gray-600 rounded-lg text-sm text-gray-600 dark:text-gray-400 hover:border-amber-400 hover:text-amber-600 focus:outline-none focus:border-amber-500"
                  >
                    <UIcon
                      name="i-heroicons-plus"
                      class="inline h-4 w-4 mr-1"
                    />
                    Add Banner ({{ banners.length }}/{{ maxBanners }})
                  </button>

                  <p class="mt-1 text-xs text-gray-600 dark:text-gray-400">
                    Recommended: 800x400px, PNG or JPG. Max
                    {{ maxBanners }} banners.
                  </p>
                </div>
                <!-- Sponsorship package selection -->
                <div v-if="!isEditMode">
                  <label
                    class="block text-sm font-medium text-gray-800 dark:text-gray-300 mb-2"
                    >Select Sponsorship Package</label
                  >

                  <!-- User Balance Display -->
                  <div
                    class="mb-3 p-3 bg-blue-50 dark:bg-blue-900/20 border border-blue-200 dark:border-blue-800 rounded-lg"
                  >
                    <div class="flex items-center justify-between">
                      <span class="text-sm text-blue-700 dark:text-blue-300"
                        >Your Current Balance:</span
                      >
                      <span
                        v-if="isLoadingBalance"
                        class="text-sm text-blue-600"
                        >Loading...</span
                      >
                      <span
                        v-else-if="balanceError"
                        class="text-sm text-red-600"
                        >{{ balanceError }}</span
                      >
                      <span
                        v-else
                        class="text-sm font-semibold text-blue-800 dark:text-blue-200"
                        >৳{{ userBalance.toLocaleString() }}</span
                      >
                    </div>
                  </div>

                  <!-- Insufficient Balance Warning -->
                  <div
                    v-if="hasInsufficientBalance"
                    class="mb-3 p-3 bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800 rounded-lg"
                  >
                    <p class="text-sm text-red-700 dark:text-red-300">
                      ⚠️ Insufficient balance! You need ৳{{
                        selectedPackage?.price || 0
                      }}
                      but only have ৳{{ userBalance }}. Please
                      <a href="/settings#wallet" class="underline"
                        >add funds to your wallet</a
                      >
                      first.
                    </p>
                  </div>

                  <!-- Loading packages -->
                  <div v-if="isLoadingPackages" class="space-y-2">
                    <div class="border rounded-lg p-3 animate-pulse">
                      <div class="h-4 bg-gray-200 rounded w-3/4 mb-2"></div>
                      <div class="h-3 bg-gray-200 rounded w-1/2"></div>
                    </div>
                  </div>
                  <!-- Package error -->
                  <div
                    v-else-if="packageError"
                    class="p-3 bg-amber-50 border border-amber-200 rounded-lg"
                  >
                    <p class="text-sm text-amber-700">{{ packageError }}</p>
                    <button
                      @click="fetchPackages"
                      class="mt-2 text-sm text-amber-700 underline"
                    >
                      Try again
                    </button>
                  </div>
                  <!-- Package list -->
                  <div v-else class="space-y-2">
                    <div
                      v-for="pkg in sortedPackages"
                      :key="pkg.id"
                      class="relative border rounded-lg p-3 cursor-pointer transition-all"
                      :class="{
                        'border-amber-500 bg-amber-50 dark:bg-amber-900/20':
                          form.selectedPackage === pkg.id,
                        'border-gray-200 dark:border-gray-700':
                          form.selectedPackage !== pkg.id,
                        'opacity-50': userBalance < pkg.price && !balanceError,
                      }"
                      @click="
                        userBalance >= pkg.price || balanceError
                          ? (form.selectedPackage = pkg.id)
                          : null
                      "
                    >
                      <div class="flex justify-between items-center">
                        <div class="flex-1">
                          <span
                            class="font-medium text-gray-800 dark:text-white"
                            >{{ pkg.name }}</span
                          >
                          <p
                            class="text-xs text-gray-600 dark:text-gray-400 mt-1"
                          >
                            {{ pkg.description }}
                          </p>
                          <div
                            v-if="userBalance < pkg.price && !balanceError"
                            class="text-xs text-red-600 mt-1"
                          >
                            Need ৳{{
                              (pkg.price - userBalance).toLocaleString()
                            }}
                            more
                          </div>
                        </div>
                        <div class="text-right">
                          <div
                            class="text-amber-600 dark:text-amber-400 font-bold"
                          >
                            ৳{{ pkg.price.toLocaleString() }}
                          </div>
                          <div
                            v-if="userBalance >= pkg.price || balanceError"
                            class="text-xs text-green-600 mt-1"
                          >
                            ✓ Available
                          </div>
                          <div v-else class="text-xs text-red-600 mt-1">
                            ⚠️ Insufficient
                          </div>
                        </div>
                      </div>
                      <div
                        v-if="form.selectedPackage === pkg.id"
                        class="absolute top-2 right-2 text-amber-500"
                      >
                        <div
                          class="w-5 h-5 rounded-full bg-amber-500 flex items-center justify-center"
                        >
                          <span class="text-white text-xs">✓</span>
                        </div>
                      </div>
                    </div>
                  </div>
                </div>
              </div>
              <!-- Error message - only show if there's an error and no success -->
              <div
                v-if="submitError && !submitSuccess"
                class="mt-4 p-3 bg-red-50 border border-red-200 rounded-lg"
              >
                <p class="text-sm text-red-600">{{ submitError }}</p>
              </div>
              <!-- Success message -->
              <div
                v-if="submitSuccess"
                class="mt-4 p-3 bg-green-50 border border-green-200 rounded-lg"
              >
                <p class="text-sm text-green-600">
                  ✓
                  {{
                    isEditMode
                      ? "Your Gold Sponsor has been updated successfully!"
                      : "Your Gold Sponsor application has been submitted successfully!"
                  }}
                </p>
              </div>
              <!-- Submit buttons -->
              <div class="mt-5">
                <button
                  type="submit"
                  class="w-full py-2 px-4 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-gradient-to-r from-amber-500 to-yellow-500 hover:from-amber-600 hover:to-yellow-600 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-amber-500 disabled:opacity-50 disabled:cursor-not-allowed"
                  :disabled="
                    isSubmitting ||
                    (isLoadingPackages && !isEditMode) ||
                    hasInsufficientBalance
                  "
                >
                  <span
                    v-if="isSubmitting"
                    class="flex items-center justify-center"
                  >
                    <svg
                      class="animate-spin -ml-1 mr-3 h-4 w-4 text-white"
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
                    {{ isEditMode ? "Updating..." : "Submitting..." }}
                  </span>
                  <span v-else-if="hasInsufficientBalance"
                    >Insufficient Balance</span
                  >
                  <span v-else>{{
                    isEditMode ? "Update Sponsor" : "Submit Application"
                  }}</span>
                </button>
                <!-- Alternative submission method if regular method fails and not already successful -->
                <div
                  v-if="submitError && !submitSuccess && !isEditMode"
                  class="mt-3"
                >
                  <button
                    type="button"
                    @click.prevent="submitFormDirectFetch"
                    class="w-full py-2 px-4 border border-amber-300 rounded-md shadow-sm text-sm font-medium text-amber-700 bg-amber-50 hover:bg-amber-100 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-amber-500 disabled:opacity-50 disabled:cursor-not-allowed"
                    :disabled="isSubmitting"
                  >
                    <span
                      v-if="isSubmitting"
                      class="flex items-center justify-center"
                    >
                      <svg
                        class="animate-spin -ml-1 mr-3 h-4 w-4 text-amber-700"
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
                          d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"
                        ></path>
                      </svg>
                      Trying alternative method...
                    </span>
                    <span v-else>Try Alternative Submission Method</span>
                  </button>
                </div>
              </div>
            </form>
          </div>
        </div>
      </div>
    </div>
  </transition>
</template>

<script setup>
import { ref, onMounted, computed, watch } from "vue";
import { useApi } from "~/composables/useApi";
import { useAuth } from "~/composables/useAuth";

const props = defineProps({
  isOpen: {
    type: Boolean,
    default: false,
  },
  editSponsor: {
    type: Object,
    default: null,
  },
});

// Import useApi and useAuth composables
const { get, post, put } = useApi();
const { user } = useAuth();

const emit = defineEmits(["close", "sponsor-created", "sponsor-updated"]);

// Check if we're in edit mode
const isEditMode = computed(() => !!props.editSponsor);

// Form data
const form = ref({
  businessName: "",
  businessDescription: "",
  contactEmail: "",
  phoneNumber: "",
  website: "",
  profileUrl: "",
  selectedPackage: 1,
  logo: null,
  banners: [],
});

// Logo handling
const logoFileInput = ref(null);
const logoPreview = ref(null);
const logoFilename = ref("");

// Banner handling
const banners = ref([]);
const maxBanners = 5;

// Define resetForm function before using it in watch
const resetForm = () => {
  form.value = {
    businessName: "",
    businessDescription: "",
    contactEmail: "",
    phoneNumber: "",
    website: "",
    profileUrl: "",
    selectedPackage: 1,
    logo: null,
  };
  logoPreview.value = null;
  logoFilename.value = "";
  banners.value = [];

  // Reset file input
  if (logoFileInput.value) {
    logoFileInput.value.value = "";
  }
};

// Watch for editSponsor changes to populate form
watch(
  () => props.editSponsor,
  (sponsor) => {
    if (sponsor) {
      populateFormForEdit(sponsor);
    } else {
      resetForm();
    }
  },
  { immediate: true }
);

// Populate form for editing
const populateFormForEdit = (sponsor) => {
  form.value = {
    businessName: sponsor.business_name || "",
    businessDescription: sponsor.business_description || "",
    contactEmail: sponsor.contact_email || "",
    phoneNumber: sponsor.phone_number || "",
    website: sponsor.website || "",
    profileUrl: sponsor.profile_url || "",
    selectedPackage: sponsor.package?.id || 1,
    logo: null, // Don't pre-populate file input
  };

  // Set logo preview if exists
  if (sponsor.logo) {
    logoPreview.value = sponsor.logo;
    logoFilename.value = "Current logo";
  }

  // Populate banners if they exist
  if (sponsor.banners && Array.isArray(sponsor.banners)) {
    banners.value = sponsor.banners.map((banner) => ({
      id: banner.id || Date.now() + Math.random(),
      title: banner.title || "",
      image: null, // Don't pre-populate file input
      imagePreview: banner.image || null,
      link_url: banner.link_url || "",
      order: banner.order || 1,
      is_active: banner.is_active !== false,
      existingId: banner.id, // Track existing banner ID for updates
    }));
  }
};

// Function to handle logo upload
const handleLogoUpload = (event) => {
  const file = event.target.files[0];
  if (!file) return;

  // Validate file type
  const allowedTypes = [
    "image/png",
    "image/jpeg",
    "image/jpg",
    "image/svg+xml",
  ];
  if (!allowedTypes.includes(file.type)) {
    alert("Please select a valid image file (PNG, JPG, or SVG)");
    return;
  }

  // Validate file size (max 5MB)
  const maxSize = 5 * 1024 * 1024; // 5MB
  if (file.size > maxSize) {
    alert("File size must be less than 5MB");
    return;
  }

  logoFilename.value = file.name;
  form.value.logo = file;

  // Create preview URL
  const reader = new FileReader();
  reader.onload = (e) => {
    logoPreview.value = e.target.result;
  };
  reader.readAsDataURL(file);
};

// Banner functions
const addBanner = () => {
  if (banners.value.length < maxBanners) {
    banners.value.push({
      id: Date.now(),
      title: "",
      image: null,
      imagePreview: null,
      link_url: "",
      order: banners.value.length + 1,
      is_active: true,
    });
  }
};

const removeBanner = (index) => {
  banners.value.splice(index, 1);
  // Update order for remaining banners
  banners.value.forEach((banner, idx) => {
    banner.order = idx + 1;
  });
};

const handleBannerUpload = (event, index) => {
  const file = event.target.files[0];
  if (!file) return;

  // Validate file type
  const allowedTypes = ["image/png", "image/jpeg", "image/jpg"];
  if (!allowedTypes.includes(file.type)) {
    alert("Please select a valid image file (PNG or JPG)");
    return;
  }

  // Validate file size (max 10MB)
  const maxSize = 10 * 1024 * 1024; // 10MB
  if (file.size > maxSize) {
    alert("Banner file size must be less than 10MB");
    return;
  }

  const banner = banners.value[index];
  banner.image = file;

  // Create preview URL
  const reader = new FileReader();
  reader.onload = (e) => {
    banner.imagePreview = e.target.result;
  };
  reader.readAsDataURL(file);
};

// Sponsorship packages
const packages = ref([]);
const isLoadingPackages = ref(false);
const packageError = ref("");

// User balance and balance deduction
const userBalance = ref(0);
const isLoadingBalance = ref(false);
const balanceError = ref("");

// Form submission state
const isSubmitting = ref(false);
const submitError = ref("");
const submitSuccess = ref(false);

// Fetch user balance
const fetchUserBalance = async () => {
  if (isEditMode.value) return; // No balance check needed for edits

  try {
    isLoadingBalance.value = true;
    balanceError.value = "";

    // Get balance from the user store instead of making an API call
    if (user.value?.user?.balance !== undefined) {
      userBalance.value = Number(user.value.user.balance);
    } else {
      balanceError.value = "Balance information not available";
    }
  } catch (error) {
    console.error("Error accessing user balance:", error);
    balanceError.value = "Could not access balance";
  } finally {
    isLoadingBalance.value = false;
  }
};

// Check if user has sufficient balance for selected package
const hasInsufficientBalance = computed(() => {
  if (isEditMode.value) return false; // No balance check for edits
  if (balanceError.value) return false; // Don't show insufficient balance if there's a balance error
  const selectedPkg = packages.value.find(
    (pkg) => pkg.id === form.value.selectedPackage
  );
  const userBal = Number(userBalance.value);
  const pkgPrice = Number(selectedPkg?.price || 0);
  const result = selectedPkg && userBal < pkgPrice;

  return result;
});

// Sorted packages by price (smallest first)
const sortedPackages = computed(() => {
  return [...packages.value].sort((a, b) => a.price - b.price);
});

// Get selected package details
const selectedPackage = computed(() => {
  return packages.value.find((pkg) => pkg.id === form.value.selectedPackage);
});

// Fetch packages from API
const fetchPackages = async () => {
  isLoadingPackages.value = true;
  packageError.value = "";

  try {
    // Try direct fetch first as a more reliable option
    try {
      const directResponse = await $fetch("/api/bn/gold-sponsors/packages/", {
        method: "GET",
        headers: {
          Accept: "application/json",
        },
      });

      if (Array.isArray(directResponse)) {
        packages.value = directResponse;

        return;
      }
    } catch (directError) {
      console.error(
        "Direct fetch failed, falling back to useApi:",
        directError
      );
    }

    // Fall back to useApi if direct fetch failed
    // Note: useApi already adds /api prefix, so we shouldn't include it in the path
    const result = await get("/bn/gold-sponsors/packages/");

    if (result.error) {
      console.error("API Error fetching packages:", result.error);
      throw new Error(
        "Failed to fetch packages: " +
          (result.error?.message || "Unknown error")
      );
    } else if (result.data && Array.isArray(result.data)) {
      packages.value = result.data;
    } else {
      packageError.value = "No sponsorship packages available.";
      packages.value = [];
    }
  } catch (error) {
    console.error("Error fetching packages:", error);
    packageError.value =
      "Using default package options. You can still submit your application.";

    // Fallback to default packages
    packages.value = [
      {
        id: 1,
        name: "1 Month Gold Sponsor",
        description: "Premium visibility for 1 month",
        price: 2999,
        duration_months: 1,
      },
      {
        id: 2,
        name: "3 Months Gold Sponsor",
        description: "Premium visibility for 3 months (10% discount)",
        price: 8099,
        duration_months: 3,
      },
      {
        id: 3,
        name: "6 Months Gold Sponsor",
        description: "Premium visibility for 6 months (15% discount)",
        price: 15299,
        duration_months: 6,
      },
    ];
  } finally {
    isLoadingPackages.value = false;
  }
};

// Direct fetch fallback (in case useApi has issues)
const submitFormDirectFetch = async () => {
  try {
    isSubmitting.value = true;
    submitError.value = "";
    submitSuccess.value = false;

    // Create FormData for file upload
    const formData = new FormData();
    formData.append("business_name", form.value.businessName);
    formData.append("business_description", form.value.businessDescription);
    formData.append("contact_email", form.value.contactEmail);
    formData.append("phone_number", form.value.phoneNumber);

    if (form.value.website) {
      // Make sure website has http/https prefix
      const website = form.value.website.trim();
      formData.append(
        "website",
        website.startsWith("http://") || website.startsWith("https://")
          ? website
          : `https://${website}`
      );
    }

    if (form.value.profileUrl) {
      // Make sure profile URL has http/https prefix
      const profileUrl = form.value.profileUrl.trim();
      formData.append(
        "profile_url",
        profileUrl.startsWith("http://") || profileUrl.startsWith("https://")
          ? profileUrl
          : `https://${profileUrl}`
      );
    }

    // Ensure package_id is properly added as a number
    formData.append("package_id", parseInt(form.value.selectedPackage, 10));

    if (form.value.logo) {
      formData.append("logo", form.value.logo);
    }

    // Try with post method from useApi first
    try {
      const apiResponse = await post("/bn/gold-sponsors/apply/", formData);

      if (apiResponse.error) {
        throw new Error(
          apiResponse.error.message || JSON.stringify(apiResponse.error)
        );
      }

      const responseData = apiResponse.data;

      // Additional validation to ensure success
      if (!responseData) {
        throw new Error("No response data received");
      }

      // IMPORTANT: First clear any previous error to avoid displaying both error and success
      submitError.value = "";
      submitSuccess.value = true;

      emit("submit", responseData);

      // Reset form and close modal after success
      resetForm();
      setTimeout(() => {
        close();
      }, 2000);

      return;
    } catch (apiError) {
      console.error("useApi approach failed:", apiError);

      // Fall back to direct fetch with credentials
      const response = await fetch("/api/bn/gold-sponsors/apply/", {
        method: "POST",
        body: formData,
        credentials: "include", // Include credentials like cookies
        headers: {
          Accept: "application/json",
        },
      });

      if (!response.ok) {
        const errorText = await response.text();
        console.error("Server error response:", response.status, errorText);

        // Check if we received HTML instead of JSON
        if (
          errorText.includes("<!DOCTYPE html>") ||
          errorText.includes("<html")
        ) {
          console.error(
            "Received HTML response instead of JSON. This could be a server error or CSRF issue."
          );
          throw {
            response: {
              status: response.status,
              data: "Server error - received HTML instead of JSON. Try refreshing the page.",
            },
            message: `Error ${response.status}: Server returned HTML instead of JSON`,
          };
        }

        try {
          // Try to parse the error as JSON
          const errorData = JSON.parse(errorText);
          throw {
            response: {
              status: response.status,
              data: errorData,
            },
            message: `Error ${response.status}: ${JSON.stringify(errorData)}`,
          };
        } catch (jsonError) {
          // If can't parse as JSON, use the raw text
          throw {
            response: {
              status: response.status,
              data: errorText,
            },
            message: `Error ${response.status}: ${errorText}`,
          };
        }
      }

      let responseData;
      try {
        responseData = await response.json();

        // Validate the response to ensure it's actually successful
        if (responseData && responseData.error) {
          throw new Error(responseData.error);
        }
      } catch (parseError) {
        console.error("Error parsing response as JSON:", parseError);
        const rawText = await response.text();
        throw new Error("Invalid JSON response from server");
      }

      // IMPORTANT: First clear any previous error to avoid displaying both error and success
      submitError.value = "";
      submitSuccess.value = true;

      emit("submit", responseData);

      // Reset form and close modal after success
      resetForm();
      setTimeout(() => {
        close();
      }, 2000);
    }
  } catch (error) {
    console.error("Error in direct fetch submission:", error);

    // More detailed error handling for direct fetch
    if (error.response?.data) {
      const errorData = error.response.data;

      if (typeof errorData === "object" && !Array.isArray(errorData)) {
        const errorMessages = [];

        Object.keys(errorData).forEach((key) => {
          if (Array.isArray(errorData[key])) {
            errorData[key].forEach((message) => {
              errorMessages.push(`${key}: ${message}`);
            });
          } else if (typeof errorData[key] === "object") {
            errorMessages.push(`${key}: ${JSON.stringify(errorData[key])}`);
          } else {
            errorMessages.push(`${key}: ${errorData[key]}`);
          }
        });

        if (errorMessages.length > 0) {
          submitError.value = `Alternative method error: ${errorMessages.join(
            ", "
          )}`;
        } else {
          submitError.value = `Alternative method error: ${JSON.stringify(
            errorData
          )}`;
        }
      } else if (typeof errorData === "string") {
        submitError.value = `Alternative method error: ${errorData}`;
      } else {
        submitError.value = `Alternative method error: ${JSON.stringify(
          errorData
        )}`;
      }
    } else if (error.data) {
      // Some fetch libraries put the response data in error.data

      submitError.value = `Alternative method error: ${
        typeof error.data === "string" ? error.data : JSON.stringify(error.data)
      }`;
    } else {
      submitError.value = `Alternative method error: ${
        error.message || "Failed to submit application. Please try again."
      }`;
    }
  } finally {
    isSubmitting.value = false;
  }
};

// Initialize packages and user balance on component mount
onMounted(() => {
  fetchPackages();
  fetchUserBalance();
});

// Close modal function
const close = () => {
  emit("close");
};

// Submit form function
const submitForm = async () => {
  isSubmitting.value = true;
  submitError.value = "";
  submitSuccess.value = false;

  try {
    // Create FormData for file upload
    const formData = new FormData();
    formData.append("business_name", form.value.businessName);
    formData.append("business_description", form.value.businessDescription);
    formData.append("contact_email", form.value.contactEmail);
    formData.append("phone_number", form.value.phoneNumber);

    // Check if optional fields are empty and provide defaults
    if (form.value.website) {
      // Make sure website has http/https prefix
      const website = form.value.website.trim();
      formData.append(
        "website",
        website.startsWith("http://") || website.startsWith("https://")
          ? website
          : `https://${website}`
      );
    }

    if (form.value.profileUrl) {
      // Make sure profile URL has http/https prefix
      const profileUrl = form.value.profileUrl.trim();
      formData.append(
        "profile_url",
        profileUrl.startsWith("http://") || profileUrl.startsWith("https://")
          ? profileUrl
          : `https://${profileUrl}`
      );
    }

    // Only add package_id for new sponsors (not for edits)
    if (!isEditMode.value) {
      formData.append("package_id", parseInt(form.value.selectedPackage, 10));
    }

    if (form.value.logo) {
      formData.append("logo", form.value.logo);
    } // Add banner data - Send as separate fields that the backend can handle
    banners.value.forEach((banner, index) => {
      if (banner.title) {
        formData.append(`banner_${index}_title`, banner.title);
      }
      if (banner.link_url) {
        formData.append(`banner_${index}_link_url`, banner.link_url);
      }
      if (banner.image) {
        formData.append(`banner_${index}_image`, banner.image);
      }
      formData.append(`banner_${index}_order`, banner.order.toString());
      formData.append(`banner_${index}_is_active`, banner.is_active.toString());
      if (banner.existingId) {
        formData.append(`banner_${index}_id`, banner.existingId.toString());
      }
    });

    // Add banner count for backend processing
    formData.append("banner_count", banners.value.length.toString());

    // Determine endpoint based on mode
    const endpoint = isEditMode.value
      ? `/bn/gold-sponsors/update/${props.editSponsor.id}/`
      : "/bn/gold-sponsors/apply/";

    const method = isEditMode.value ? "PUT" : "POST";

    let responseData;

    try {
      // Using fetch with credentials
      const response = await fetch(`/api${endpoint}`, {
        method: method,
        body: formData,
        credentials: "include",
        headers: {
          Accept: "application/json",
        },
      });

      if (!response.ok) {
        const errorText = await response.text();
        console.error("Server error response:", response.status, errorText);

        // Check if the response is HTML (likely CSRF or server error page)
        if (
          errorText.includes("<!DOCTYPE html>") ||
          errorText.includes("<html")
        ) {
          throw new Error(
            "Server returned HTML instead of JSON - possible CSRF or server error."
          );
        }

        // Try to parse error as JSON
        const errorData = JSON.parse(errorText);
        throw {
          response: { status: response.status, data: errorData },
          message: `Error ${response.status}: ${JSON.stringify(errorData)}`,
        };
      }

      try {
        responseData = await response.json();

        // Additional validation to ensure the response is actually successful
        if (responseData && responseData.error) {
          throw new Error(responseData.error);
        }
      } catch (parseError) {
        console.error("Error parsing response as JSON:", parseError);
        const rawText = await response.text();

        throw new Error("Invalid JSON response from server");
      }
    } catch (fetchError) {
      console.error("Fetch attempt failed:", fetchError);

      // Try useApi as fallback
      const apiMethod = isEditMode.value ? put : post;
      const apiResponse = await apiMethod(endpoint, formData);

      if (apiResponse.error) {
        throw new Error(
          apiResponse.error.message || JSON.stringify(apiResponse.error)
        );
      }

      responseData = apiResponse.data;

      // Better validation of the useApi response
      if (!responseData) {
        console.error("No data in useApi response");
        throw new Error("No data received from server");
      }

      if (responseData.error || responseData.status === "error") {
        console.error("Error indicated in useApi response data:", responseData);
        throw new Error(responseData.error || "Unknown server error");
      }
    }

    // IMPORTANT: Clear any previous error to prevent showing both error and success
    submitError.value = "";
    submitSuccess.value = true;

    // Emit the appropriate event with the response data
    if (isEditMode.value) {
      emit("sponsor-updated", responseData);
    } else {
      emit("sponsor-created", responseData);
    }

    // Reset form after successful submission
    resetForm();

    // Close the modal after a short delay to show success message
    setTimeout(() => {
      close();
    }, 2000);
  } catch (error) {
    console.error(
      `Error ${isEditMode.value ? "updating" : "creating"} gold sponsor:`,
      error
    );

    // Improved error handling to show more detailed error messages
    if (error.response?.data) {
      // Handle Django REST framework validation errors
      const errorData = error.response.data;

      if (typeof errorData === "object" && !Array.isArray(errorData)) {
        const errorMessages = [];

        // Process DRF validation errors which come as field->error array
        Object.keys(errorData).forEach((key) => {
          if (Array.isArray(errorData[key])) {
            errorData[key].forEach((message) => {
              errorMessages.push(`${key}: ${message}`);
            });
          } else if (typeof errorData[key] === "object") {
            errorMessages.push(`${key}: ${JSON.stringify(errorData[key])}`);
          } else {
            errorMessages.push(`${key}: ${errorData[key]}`);
          }
        });

        if (errorMessages.length > 0) {
          submitError.value = errorMessages.join("\n");
        } else {
          submitError.value = JSON.stringify(errorData);
        }
      } else if (typeof errorData === "string") {
        submitError.value = errorData;
      } else {
        submitError.value = JSON.stringify(errorData);
      }
    } else if (error.data) {
      // Some fetch libraries put the response data in error.data

      submitError.value =
        typeof error.data === "string"
          ? error.data
          : JSON.stringify(error.data);
    } else {
      submitError.value =
        error.message ||
        `Failed to ${
          isEditMode.value ? "update" : "submit"
        } application. Please try again.`;
    }

    // If the primary submission method failed, suggest using the alternative method
    if (!isEditMode.value) {
      submitError.value +=
        "\n\nPlease try the alternative submission method below.";
    }
  } finally {
    isSubmitting.value = false;
  }
};

// Function to update content from editor
function updateContent(p) {
  form.value.businessDescription = p;
}
</script>

<style scoped>
/* Add any component-specific styles here */
/* Editor Container */
.editor-container {
  border-radius: 0.5rem;
  border: 1px solid #e5e7eb;
  min-height: 150px;
  transition: all 0.2s ease;
}

.editor-container:focus-within {
  border-color: #3b82f6;
  box-shadow: 0 0 0 2px rgba(59, 130, 246, 0.2);
}

/* Dark mode adjustments */
.dark .editor-container {
  border-color: #374151;
}

.dark .editor-container:focus-within {
  border-color: #3b82f6;
  box-shadow: 0 0 0 2px rgba(59, 130, 246, 0.2);
}
</style>
