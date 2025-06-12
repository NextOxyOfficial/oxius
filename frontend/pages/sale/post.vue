<template>
  <PublicSection>
    <div class="min-h-screen py-8 bg-gradient-to-b from-gray-50 to-gray-100">
      <UContainer>
        <!-- Enhanced Header -->
        <div class="text-center mb-10">
          <h1
            class="text-2xl font-semibold mb-2 bg-gradient-to-r from-emerald-500 to-green-600 bg-clip-text text-transparent"
          >
            Post Your Sale Ad
          </h1>
          <p class="text-lg text-gray-600 max-w-lg mx-auto">
            Reach thousands of potential buyers instantly with your listing
          </p>
        </div>

        <!-- Success Modal -->
        <div
          v-if="showSuccessModal"
          class="fixed inset-0 flex items-center justify-center z-50 bg-black/60 backdrop-blur-sm"
        >
          <div
            class="bg-white rounded-2xl shadow-2xl max-w-md w-full mx-4 overflow-hidden"
          >
            <div class="bg-gradient-to-r from-green-400 to-emerald-500 p-6">
              <div
                class="flex items-center justify-center w-16 h-16 bg-white rounded-full mx-auto mb-4"
              >
                <UIcon name="i-heroicons-check" class="w-8 h-8 text-green-500" />
              </div>
              <h3 class="text-xl font-bold text-white text-center">Success!</h3>
            </div>
            <div class="p-6 text-center">
              <p class="text-gray-600 mb-6">
                Your listing has been submitted successfully and is now under
                review.
              </p>
              <button
                @click="closeSuccessModal"
                class="bg-gradient-to-r from-emerald-500 to-teal-600 text-white px-8 py-3 rounded-lg hover:from-emerald-600 hover:to-teal-700 transition-all duration-200 font-medium"
              >
                Got it!
              </button>
            </div>
          </div>
        </div>        
        <form
          @submit.prevent="submitForm"
          class="bg-white rounded-xl shadow-sm max-w-5xl mx-auto overflow-hidden border border-gray-100"
        >
          <!-- Basic Details Section -->
          <div
            class="p-3 md:p-7 border-b border-gray-100 hover:bg-gray-50 transition-colors duration-300"
          >
            <h2
              class="text-xl font-semibold text-gray-800 mb-6 flex items-center gap-2"
            >
              <UIcon
                name="i-heroicons-document-text"
                class="text-emerald-600"
              />
              Basic Details
            </h2>

            <UFormGroup
              label="Category"
              required
              :error="
                !formData.category &&
                checkSubmit &&
                'You must select a category'
              "
              class="mb-5"
            >
              <USelectMenu
                v-model="formData.category"
                color="white"
                size="md"
                :options="categories"
                placeholder="Select Category"
                class="w-full border-gray-200 focus:border-emerald-500 focus:ring focus:ring-emerald-100 transition-all"
                option-attribute="name"
                value-attribute="id"
                @change="handleCategoryChange"
              />
            </UFormGroup>

            <!-- Child Category -->
            <UFormGroup
              v-if="childCategories.length > 0"
              label="Sub Category"
              required
              :error="
                !formData.childCategory &&
                checkSubmit &&
                'You must select a sub category'
              "
              class="mb-5"
            >
              <USelectMenu
                v-model="formData.childCategory"
                color="white"
                size="md"
                :options="childCategories"
                placeholder="Select Sub Category"
                class="w-full border-gray-200 focus:border-emerald-500 focus:ring focus:ring-emerald-100 transition-all"
                option-attribute="name"
                value-attribute="id"
              />
            </UFormGroup>

            <UFormGroup
              label="Title"
              required
              :error="!formData.title && checkSubmit && 'You must enter a title!'"
              class="mb-5"
            >
              <UInput
                type="text"
                size="md"
                color="white"
                class="w-full border-gray-200 focus:border-emerald-500 focus:ring focus:ring-emerald-100 transition-all"
                placeholder="What are you selling?"
                v-model="formData.title"
                maxlength="100"
              >
                <template #leading>
                  <UIcon name="i-heroicons-pencil-square" />
                </template>
              </UInput>
              <div class="text-right text-sm text-gray-500 mt-1">
                {{ formData.title.length }}/100
              </div>
            </UFormGroup>

            <UFormGroup label="Description" required class="mb-5">
              <p class="text-sm text-gray-600 mb-3">
                Describe your item in detail
              </p>
              <UTextarea
                v-model="formData.description"
                color="white"
                size="md"
                :rows="4"
                placeholder="Describe your item in detail..."
                maxlength="1000"
                class="w-full border-gray-200 focus:border-emerald-500 focus:ring focus:ring-emerald-100 transition-all resize-none"
              />
              <div class="text-right text-sm text-gray-500 mt-1">
                {{ formData.description.length }}/1000
              </div>
            </UFormGroup>
          </div>

          <!-- Pricing & Condition Section -->
          <div
            class="p-3 md:p-7 border-b border-gray-100 hover:bg-gray-50 transition-colors duration-300"
          >
            <h2
              class="text-xl font-semibold text-gray-800 mb-6 flex items-center gap-2"
            >
              <UIcon
                name="i-heroicons-currency-dollar"
                class="text-emerald-600"
              />
              Pricing & Condition
            </h2>

            <!-- Condition -->
            <UFormGroup
              label="Condition"
              required
              :error="
                !formData.condition &&
                checkSubmit &&
                'You must select a condition'
              "
              class="mb-5"
            >
              <div class="grid grid-cols-2 md:grid-cols-5 gap-3">
                <label
                  v-for="condition in conditions"
                  :key="condition.value"
                  :class="[
                    'flex items-center justify-center p-3 border-2 rounded-lg cursor-pointer transition-all text-sm font-medium',
                    formData.condition === condition.value
                      ? 'border-emerald-500 bg-emerald-50 text-emerald-700'
                      : 'border-gray-200 hover:border-emerald-300 hover:bg-emerald-50',
                  ]"
                >
                  <input
                    type="radio"
                    :value="condition.value"
                    v-model="formData.condition"
                    class="sr-only"
                  />
                  {{ condition.label }}
                </label>
              </div>
            </UFormGroup>

            <!-- Price -->
            <UFormGroup
              label="Price"
              :error="
                formData.price <= 0 &&
                !formData.negotiable &&
                checkSubmit &&
                'Price must be greater than 0 or mark as Negotiable'
              "
              class="mb-5"
            >
              <div class="flex flex-wrap items-center gap-4">
                <UInput
                  type="number"
                  size="md"
                  color="white"
                  :disabled="formData.negotiable"
                  placeholder="e.g. 1000"
                  min="0"
                  step="0.01"
                  class="w-40 sm:flex-grow-0 border-gray-200 focus:border-emerald-500 focus:ring focus:ring-emerald-100 transition-all"
                  v-model="formData.price"
                >
                  <template #leading>
                    <UIcon name="i-mdi:currency-bdt" />
                  </template>
                </UInput>

                <div class="flex items-center">
                  <UCheckbox
                    v-model="formData.negotiable"
                    name="Negotiable"
                    label="Negotiable"
                  />
                </div>
              </div>
            </UFormGroup>
          </div>

          <!-- Media Upload Section -->
          <div
            class="p-3 md:p-7 border-b border-gray-100 hover:bg-gray-50 transition-colors duration-300"
          >
            <h2
              class="text-xl font-semibold text-gray-800 mb-6 flex items-center gap-2"
            >
              <UIcon name="i-heroicons-photo" class="text-emerald-600" />
              Upload Photos
            </h2>
            <p class="text-sm text-gray-600 mb-4">
              Add photos to showcase your listing (up to 8 images). First image
              will be the main image.
            </p>

            <div class="flex flex-wrap gap-4 mt-4">
              <!-- Uploaded images -->
              <div
                v-for="(img, i) in formData.images"
                :key="i"
                class="w-32 h-32 rounded-lg overflow-hidden relative border border-gray-200 bg-gray-50 group"
                v-show="img"
              >
                <img
                  :src="imagePreviewUrls[i]"
                  :alt="`Uploaded file ${i}`"
                  class="w-full h-full object-cover transition-transform group-hover:scale-105"
                />
                <div
                  class="absolute inset-0 bg-black bg-opacity-0 group-hover:bg-opacity-30 transition-all"
                ></div>
                <button
                  type="button"
                  class="absolute top-2 right-2 bg-white rounded-full w-8 h-8 flex items-center justify-center text-red-500 shadow-sm hover:bg-red-50 hover:scale-110 transition-all"
                  @click="removeImage(i)"
                  aria-label="Delete image"
                >
                  <UIcon name="i-heroicons-trash" />
                </button>
                <div
                  v-if="i === 0"
                  class="absolute top-2 left-2 bg-emerald-500 text-white text-xs px-2 py-1 rounded font-medium"
                >
                  Main
                </div>
              </div>              <!-- Upload button -->
              <div
                class="w-32 h-32 rounded-lg relative border-2 border-dashed border-gray-300 bg-gray-50 hover:border-emerald-500 hover:bg-emerald-50/20 transition-colors flex items-center justify-center cursor-pointer group"
                v-if="formData.images.filter(img => img).length < 8"
                @click="openFileUpload"
              >
                <input
                  type="file"
                  ref="fileInput"
                  class="hidden"
                  @change="handleFileUpload"
                  accept="image/*"
                />
                <div
                  class="flex flex-col items-center gap-2 text-gray-600 text-sm text-center p-2 group-hover:text-emerald-600 pointer-events-none"
                >
                  <UIcon
                    name="i-heroicons-arrow-up-tray"
                    class="text-xl text-emerald-500"
                  />
                  <span>Add Photo</span>
                </div>
              </div>
            </div>

            <!-- Upload status -->
            <p v-if="uploadError" class="mt-3 text-red-500 text-sm">
              {{ uploadError }}
            </p>
            <p
              v-if="isUploading"
              class="mt-3 text-emerald-600 text-sm flex items-center"
            >
              <UIcon name="i-heroicons-arrow-path" class="animate-spin mr-1" />
              Processing image...
            </p>
          </div>

          <!-- Location Section -->
          <div
            class="p-3 md:p-7 border-b border-gray-100 hover:bg-gray-50 transition-colors duration-300"
          >
            <h2
              class="text-xl font-semibold text-gray-800 mb-6 flex items-center gap-2"
            >
              <UIcon name="i-heroicons-map-pin" class="text-emerald-600" />
              Location
            </h2>

            <UCheckbox
              v-model="allOverBangladesh"
              name="all-bangladesh"
              label="All over Bangladesh"
              color="primary"
              class="mb-4"
            />

            <div
              class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4"
              v-if="!allOverBangladesh"
            >
              <UFormGroup
                label="Division"
                :error="
                  !formData.division &&
                  checkSubmit &&
                  !allOverBangladesh &&
                  'You must select a division!'
                "
                class="mb-5"
              >
                <USelectMenu
                  v-model="formData.division"
                  color="white"
                  size="md"
                  :options="regions"
                  placeholder="Select Division"
                  class="w-full border-gray-200 focus:border-emerald-500 focus:ring focus:ring-emerald-100 transition-all"
                  option-attribute="name_eng"
                  value-attribute="name_eng"
                >
                  <template #leading>
                    <UIcon name="i-heroicons-map" />
                  </template>
                </USelectMenu>
              </UFormGroup>

              <UFormGroup
                label="District"
                :error="
                  !formData.district &&
                  checkSubmit &&
                  !allOverBangladesh &&
                  'You must select a district'
                "
                class="mb-5"
              >
                <USelectMenu
                  v-model="formData.district"
                  color="white"
                  size="md"
                  :options="cities"
                  placeholder="Select District"
                  class="w-full border-gray-200 focus:border-emerald-500 focus:ring focus:ring-emerald-100 transition-all"
                  option-attribute="name_eng"
                  value-attribute="name_eng"
                  :disabled="!formData.division"
                >
                  <template #leading>
                    <UIcon name="i-heroicons-building-office-2" />
                  </template>
                </USelectMenu>
              </UFormGroup>

              <UFormGroup
                label="Area"
                :error="
                  !formData.area &&
                  checkSubmit &&
                  !allOverBangladesh &&
                  'You must select an area'
                "
                class="mb-5"
              >
                <USelectMenu
                  v-model="formData.area"
                  color="white"
                  size="md"
                  :options="upazilas"
                  placeholder="Select Area"
                  class="w-full border-gray-200 focus:border-emerald-500 focus:ring focus:ring-emerald-100 transition-all"
                  option-attribute="name_eng"
                  value-attribute="name_eng"
                  :disabled="!formData.district"
                >
                  <template #leading>
                    <UIcon name="i-heroicons-home-modern" />
                  </template>
                </USelectMenu>
              </UFormGroup>
            </div>

            <UFormGroup
              label="Detailed Address"
              required
              :error="
                !formData.detailedAddress &&
                checkSubmit &&
                'You must provide a detailed address!'
              "
              class="mb-5"
            >
              <UTextarea
                v-model="formData.detailedAddress"
                color="white"
                size="md"
                :rows="3"
                placeholder="Provide specific location details..."
                class="w-full border-gray-200 focus:border-emerald-500 focus:ring focus:ring-emerald-100 transition-all resize-none"
              />
            </UFormGroup>
          </div>

          <!-- Contact Information Section -->
          <div
            class="p-3 md:p-7 border-b border-gray-100 hover:bg-gray-50 transition-colors duration-300"
          >
            <h2
              class="text-xl font-semibold text-gray-800 mb-6 flex items-center gap-2"
            >
              <UIcon name="i-heroicons-phone" class="text-emerald-600" />
              Contact Information
            </h2>

            <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
              <UFormGroup
                label="Phone Number"
                required
                :error="
                  !formData.phone && checkSubmit && 'You must enter a phone number!'
                "
                class="mb-5"
              >
                <UInput
                  v-model="formData.phone"
                  type="tel"
                  size="md"
                  color="white"
                  placeholder="01XXXXXXXXX"
                  pattern="[0-9]{11}"
                  class="w-full border-gray-200 focus:border-emerald-500 focus:ring focus:ring-emerald-100 transition-all"
                >
                  <template #leading>
                    <UIcon name="i-heroicons-phone" />
                  </template>
                </UInput>
              </UFormGroup>

              <UFormGroup label="Email (Optional)" class="mb-5">
                <UInput
                  v-model="formData.email"
                  type="email"
                  size="md"
                  color="white"
                  placeholder="your@email.com"
                  class="w-full border-gray-200 focus:border-emerald-500 focus:ring focus:ring-emerald-100 transition-all"
                >
                  <template #leading>
                    <UIcon name="i-heroicons-envelope" />
                  </template>
                </UInput>
              </UFormGroup>
            </div>
          </div>

          <!-- Terms Section -->
          <div
            class="p-3 md:p-7 border-b border-gray-100 hover:bg-gray-50 transition-colors duration-300"
          >
            <UCheckbox
              v-model="formData.termsAccepted"
              name="terms"
              color="primary"
              required
            >
              <template #label>
                <span class="text-sm text-gray-700">
                  I agree to the
                  <a href="#" class="text-emerald-600 hover:underline font-medium"
                    >Terms and Conditions</a
                  >
                  and
                  <a href="#" class="text-emerald-600 hover:underline font-medium"
                    >Privacy Policy</a
                  >
                  <span class="text-red-500">*</span>
                </span>
              </template>
            </UCheckbox>
          </div>

          <!-- Submit Button -->
          <div class="p-3 md:p-7 bg-gray-50">
            <div class="flex justify-end">
              <UButton
                type="submit"
                :loading="isSubmitting"
                :disabled="isSubmitting"
                color="emerald"
                size="lg"
                class="px-8 py-3 font-medium"
              >
                <template #leading>
                  <UIcon
                    v-if="!isSubmitting"
                    name="i-heroicons-paper-airplane"
                  />
                </template>
                {{ isSubmitting ? "Posting..." : "Post Your Ad" }}
              </UButton>
            </div>
          </div>
        </form>
      </UContainer>
    </div>
  </PublicSection>
</template>

<script setup>
import { ref, reactive, computed, watch, onMounted } from "vue";
import { useSalePost } from "~/composables/useSalePost";

// Add authentication middleware
definePageMeta({
  middleware: 'auth'
});

const { $t: t } = useI18n();
const { get } = useApi();
const toast = useToast();
const router = useRouter();

// Composables
const {
  createSalePost,
  loading: apiLoading,
  error: apiError,
} = useSalePost();

// Form data
const formData = reactive({
  category: "",
  childCategory: "",
  title: "",
  description: "",
  condition: "",
  price: "",
  negotiable: false,
  division: "",
  district: "",
  area: "",
  detailedAddress: "",
  phone: "",
  email: "",
  images: new Array(8).fill(null),
  termsAccepted: false,
});

// State
const allOverBangladesh = ref(false);
const checkSubmit = ref(false);
const isSubmitting = computed(() => apiLoading.value);
const showSuccessModal = ref(false);

// Data arrays
const categories = ref([]);
const childCategories = ref([]);
const conditions = ref([]);
const regions = ref([]);
const cities = ref([]);
const upazilas = ref([]);

// Image handling
const imagePreviewUrls = ref(new Array(8).fill(null));
const fileInput = ref(null);
const isUploading = ref(false);
const uploadError = ref("");

// Load initial data
const loadCategories = async () => {
  try {
    const response = await get("/sale/categories/");
    categories.value = response.data || [];
  } catch (error) {
    console.error("Error loading categories:", error);
  }
};

const loadConditions = async () => {
  try {
    const response = await get("/sale/conditions/");
    if (response?.data && Array.isArray(response.data)) {
      conditions.value = response.data.map((condition) => ({
        label: condition.name,
        value: condition.value,
        description: condition.description,
      }));
    } else {
      // Fallback conditions
      conditions.value = [
        { label: "Brand New", value: "brand-new" },
        { label: "Like New", value: "like-new" },
        { label: "Good", value: "good" },
        { label: "Fair", value: "fair" },
        { label: "For Parts", value: "for-parts" },
      ];
    }
  } catch (error) {
    console.error("Error loading conditions:", error);
    // Use fallback conditions
    conditions.value = [
      { label: "Brand New", value: "brand-new" },
      { label: "Like New", value: "like-new" },
      { label: "Good", value: "good" },
      { label: "Fair", value: "fair" },
      { label: "For Parts", value: "for-parts" },
    ];
  }
};

const loadRegions = async () => {
  try {
    const response = await get("/geo/regions/?country_name_eng=Bangladesh");
    regions.value = response.data || [];
  } catch (error) {
    console.error("Error loading regions:", error);
  }
};

// Handle category change
const handleCategoryChange = async () => {
  formData.childCategory = "";
  childCategories.value = [];

  if (formData.category) {
    try {
      const response = await get(
        `/sale/child-categories/?parent_id=${formData.category}`
      );
      childCategories.value = response.data || [];
    } catch (error) {
      console.error("Error loading child categories:", error);
    }
  }
};

// Watch division change
watch(
  () => formData.division,
  async (newDivision) => {
    if (newDivision) {
      try {
        const response = await get(`/geo/cities/?region_name_eng=${newDivision}`);
        cities.value = response.data || [];
        formData.district = "";
        formData.area = "";
      } catch (error) {
        console.error("Error loading cities:", error);
      }
    } else {
      cities.value = [];
    }
  }
);

// Watch district change
watch(
  () => formData.district,
  async (newDistrict) => {
    if (newDistrict) {
      try {
        const response = await get(`/geo/upazila/?city_name_eng=${newDistrict}`);
        upazilas.value = response.data || [];
        formData.area = "";
      } catch (error) {
        console.error("Error loading upazilas:", error);
      }
    } else {
      upazilas.value = [];
    }
  }
);

// File upload functions
const openFileUpload = () => {
  if (fileInput.value) {
    // Clear any previous selection to ensure fresh state
    fileInput.value.value = "";
    // Trigger the file picker
    fileInput.value.click();
    console.log("File picker opened");
  } else {
    console.error("File input reference not found");
  }
};

const handleFileUpload = async (event) => {
  const files = event.target.files;
  if (!files || files.length === 0) {
    console.warn("No files selected");
    return;
  }

  const file = files[0];
  console.log("File selected:", file.name, file.type, file.size);

  // Validate file
  if (!file.type.match("image.*")) {
    uploadError.value = "Please upload only image files";
    return;
  }

  if (file.size > 12 * 1024 * 1024) {
    uploadError.value = "Image size should be less than 12MB";
    return;
  }

  isUploading.value = true;  uploadError.value = "";

  try {
    const compressedImage = await processImageWithCompression(file);

    if (compressedImage) {
      // Find first empty slot
      const emptyIndex = formData.images.findIndex((img) => !img);
      if (emptyIndex !== -1) {
        imagePreviewUrls.value[emptyIndex] = compressedImage;
        formData.images[emptyIndex] = compressedImage;
        console.log("Image added to slot:", emptyIndex);
      } else {
        uploadError.value = "Maximum 8 images allowed";
      }
    }
  } catch (error) {
    console.error("Error compressing image:", error);
    uploadError.value = "Failed to process image. Please try again.";
  } finally {
    isUploading.value = false;
    // Reset file input to allow selecting the same file again
    if (fileInput.value) {
      fileInput.value.value = "";
    }
  }
};

const removeImage = (index) => {
  imagePreviewUrls.value[index] = null;
  formData.images[index] = null;
  uploadError.value = "";
};

// Image compression function - enhanced like business network
const processImageWithCompression = (file) => {
  return new Promise((resolve, reject) => {
    const reader = new FileReader();
    reader.onload = (e) => {
      const img = new Image();
      img.onload = () => {
        const canvas = document.createElement("canvas");
        const ctx = canvas.getContext("2d");

        // Enable image smoothing for better quality
        ctx.imageSmoothingEnabled = true;
        ctx.imageSmoothingQuality = "high";

        // Calculate new dimensions with better optimization
        let { width, height } = img;
        const maxDimension = 1600; // Larger max for better quality
        
        // Smart resizing with aspect ratio preservation
        if (width > maxDimension || height > maxDimension) {
          const aspectRatio = width / height;
          
          if (width > height) {
            width = maxDimension;
            height = Math.round(width / aspectRatio);
          } else {
            height = maxDimension;
            width = Math.round(height * aspectRatio);
          }
        }

        canvas.width = width;
        canvas.height = height;

        // Apply subtle sharpening for better perceived quality
        ctx.filter = "contrast(1.05) saturate(1.02)";
        ctx.drawImage(img, 0, 0, width, height);
        ctx.filter = "none";

        // Progressive compression with quality optimization
        let quality = 0.85; // Start with higher quality
        let resultImage = canvas.toDataURL("image/jpeg", quality);
        let resultSize = Math.round((resultImage.length * 3) / 4);
        
        const targetSize = 150 * 1024; // 150KB target
        const minQuality = 0.60;

        // Optimize compression
        while (resultSize > targetSize && quality > minQuality) {
          quality -= 0.05;
          resultImage = canvas.toDataURL("image/jpeg", quality);
          resultSize = Math.round((resultImage.length * 3) / 4);
        }

        console.log(`Image compressed: ${formatFileSize(file.size)} → ${formatFileSize(resultSize)} (${quality * 100}% quality)`);
        resolve(resultImage);
      };
      img.onerror = reject;
      img.src = e.target.result;
    };
    reader.onerror = reject;
    reader.readAsDataURL(file);
  });
};

// Format file size utility
const formatFileSize = (bytes) => {
  if (bytes === 0) return '0 Bytes';
  const k = 1024;
  const sizes = ['Bytes', 'KB', 'MB', 'GB'];
  const i = Math.floor(Math.log(bytes) / Math.log(k));
  return parseFloat((bytes / Math.pow(k, i)).toFixed(1)) + ' ' + sizes[i];
};

// Form submission
const submitForm = async () => {
  checkSubmit.value = true;

  if (isSubmitting.value) return;

  // Validate required fields
  const requiredFields = {
    category: formData.category,
    title: formData.title?.trim(),
    description: formData.description?.trim(),
    condition: formData.condition,
    detailed_address: formData.detailedAddress?.trim(),
    phone: formData.phone?.trim(),
  };

  // Add location validation if not all over Bangladesh
  if (!allOverBangladesh.value) {
    requiredFields.division = formData.division;
    requiredFields.district = formData.district;
    requiredFields.area = formData.area;
  }

  const missingFields = [];
  Object.entries(requiredFields).forEach(([key, value]) => {
    if (!value || value === "") {
      missingFields.push(key);
    }
  });

  if (missingFields.length > 0) {
    toast.add({
      title: "Validation Error",
      description: `Please fill in all required fields: ${missingFields.join(
        ", "
      )}`,
      color: "red",
      timeout: 5000,
    });
    return;
  }

  // Validate price
  if (
    !formData.negotiable &&
    (!formData.price || parseFloat(formData.price) <= 0)
  ) {
    toast.add({
      title: "Validation Error",
      description: "Please enter a valid price or mark as negotiable",
      color: "red",
      timeout: 5000,
    });
    return;
  }

  // Validate images
  const validImages = formData.images.filter(
    (img) => img && typeof img === "string"
  );
  if (validImages.length === 0) {
    toast.add({
      title: "Validation Error",
      description: "Please upload at least one image",
      color: "red",
      timeout: 5000,
    });
    return;
  }

  // Validate terms
  if (!formData.termsAccepted) {
    toast.add({
      title: "Validation Error",
      description: "Please accept the terms and conditions",
      color: "red",
      timeout: 5000,
    });
    return;
  }

  try {    // Prepare submission data following business network pattern
    const submissionData = {
      category: parseInt(formData.category),
      title: formData.title.trim(),
      description: formData.description.trim(),
      condition: formData.condition,
      detailed_address: formData.detailedAddress.trim(),
      phone: formData.phone.trim(),
      negotiable: Boolean(formData.negotiable),
      division: allOverBangladesh.value ? "" : formData.division,
      district: allOverBangladesh.value ? "" : formData.district,
      area: allOverBangladesh.value ? "" : formData.area,
      images: validImages, // Send as array like business network
    };

    // Add optional fields
    if (formData.childCategory) {
      submissionData.child_category = parseInt(formData.childCategory);
    }

    if (formData.email?.trim()) {
      submissionData.email = formData.email.trim();
    }

    // Handle price
    if (formData.negotiable) {
      submissionData.price =
        formData.price && formData.price !== ""
          ? parseFloat(formData.price)
          : null;
    } else {
      submissionData.price = parseFloat(formData.price);
    }

    console.log("Submitting data:", submissionData);

    const result = await createSalePost(submissionData);
    console.log("Submission successful:", result);
    
    showSuccessModal.value = true;

    // Auto-close modal after 5 seconds
    setTimeout(() => {
      closeSuccessModal();
    }, 5000);

  } catch (error) {
    console.error("Error submitting form:", error);

    let errorMessage = "Failed to submit your listing. Please try again.";

    if (error?.response?.status === 400) {
      errorMessage = "Please check your form data and try again.";
    } else if (error?.message?.includes("network")) {
      errorMessage = "Network error. Please check your connection.";
    }

    toast.add({
      title: "Error",
      description: errorMessage,
      color: "red",
      timeout: 8000,
    });
  }
};

// Close success modal
const closeSuccessModal = () => {
  showSuccessModal.value = false;
  resetForm();

  toast.add({
    title: "Success!",
    description: "Your listing has been submitted successfully.",
    color: "green",
  });

  // Navigate to sale listings
  router.push("/sale");
};

// Reset form
const resetForm = () => {
  Object.keys(formData).forEach((key) => {
    if (key === "termsAccepted" || key === "negotiable") {
      formData[key] = false;
    } else if (key === "images") {
      formData[key] = new Array(8).fill(null);
    } else {
      formData[key] = "";
    }
  });

  imagePreviewUrls.value = new Array(8).fill(null);
  childCategories.value = [];
  allOverBangladesh.value = false;
  checkSubmit.value = false;
};

// Initialize component
onMounted(async () => {
  await Promise.all([loadCategories(), loadConditions(), loadRegions()]);
});

// SEO
useHead({
  title: "Post Sale Ad - Sell Your Items",
  meta: [
    {
      name: "description",
      content: "Post your sale advertisement and reach thousands of potential buyers instantly.",
    },
  ],
});
</script>

<style scoped>
/* Custom focus styles */
.UInput:focus-within,
.UTextarea:focus-within,
.USelectMenu:focus-within {
  box-shadow: 0 0 0 3px rgba(16, 185, 129, 0.1);
}
</style>
