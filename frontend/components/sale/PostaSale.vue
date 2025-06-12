<template>
  <div class="max-w-4xl mx-auto bg-white">
    <!-- Header Section -->
    <div class="bg-gradient-to-r from-emerald-500 to-teal-600 text-white p-6 rounded-t-xl">
      <div class="flex items-center gap-3">
        <div class="bg-white/20 p-3 rounded-lg">
          <Icon name="heroicons:megaphone" class="w-6 h-6" />
        </div>
        <div>
          <h1 class="text-2xl font-bold">{{ editPost ? 'Edit Your Listing' : 'Post Your Ad' }}</h1>
          <p class="text-emerald-100 mt-1">Reach thousands of potential buyers instantly</p>
        </div>
      </div>
    </div>

    <!-- Success Modal -->
    <div v-if="showSuccessModal" class="fixed inset-0 flex items-center justify-center z-50 bg-black/60 backdrop-blur-sm">
      <div class="bg-white rounded-2xl shadow-2xl max-w-md w-full mx-4 overflow-hidden">
        <div class="bg-gradient-to-r from-green-400 to-emerald-500 p-6">
          <div class="flex items-center justify-center w-16 h-16 bg-white rounded-full mx-auto mb-4">
            <Icon name="heroicons:check" class="w-8 h-8 text-green-500" />
          </div>
          <h3 class="text-xl font-bold text-white text-center">Success!</h3>
        </div>
        <div class="p-6 text-center">
          <p class="text-gray-600 mb-6">Your listing has been submitted successfully and is now under review.</p>
          <button
            @click="closeSuccessModal"
            class="bg-gradient-to-r from-emerald-500 to-teal-600 text-white px-8 py-3 rounded-lg hover:from-emerald-600 hover:to-teal-700 transition-all duration-200 font-medium"
          >
            Got it!
          </button>
        </div>
      </div>
    </div>

    <!-- Main Form -->
    <form @submit.prevent="submitForm" class="p-6 space-y-8">
      
      <!-- Basic Information -->
      <div class="bg-gray-50 rounded-xl p-6">
        <h2 class="text-xl font-semibold text-gray-800 mb-6 flex items-center gap-2">
          <Icon name="heroicons:information-circle" class="w-5 h-5 text-emerald-600" />
          Basic Information
        </h2>
        
        <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
          <!-- Category -->
          <div class="col-span-full">
            <label class="block text-sm font-medium text-gray-700 mb-2">
              Category <span class="text-red-500">*</span>
            </label>
            <select
              v-model="formData.category"
              @change="handleCategoryChange"
              class="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-emerald-500 focus:border-transparent transition-all"
              required
            >
              <option value="">Select a category</option>
              <option v-for="category in categories" :key="category.id" :value="category.id">
                {{ category.name }}
              </option>
            </select>
            <p v-if="errors.category" class="mt-1 text-sm text-red-600">{{ errors.category }}</p>
          </div>

          <!-- Child Category -->
          <div v-if="childCategories.length > 0" class="col-span-full">
            <label class="block text-sm font-medium text-gray-700 mb-2">
              Sub Category <span class="text-red-500">*</span>
            </label>
            <select
              v-model="formData.childCategory"
              class="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-emerald-500 focus:border-transparent transition-all"
              required
            >
              <option value="">Select a sub category</option>
              <option v-for="child in childCategories" :key="child.id" :value="child.id">
                {{ child.name }}
              </option>
            </select>
            <p v-if="errors.childCategory" class="mt-1 text-sm text-red-600">{{ errors.childCategory }}</p>
          </div>

          <!-- Title -->
          <div class="col-span-full">
            <label class="block text-sm font-medium text-gray-700 mb-2">
              Title <span class="text-red-500">*</span>
            </label>
            <input
              v-model="formData.title"
              type="text"
              placeholder="What are you selling?"
              maxlength="100"
              class="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-emerald-500 focus:border-transparent transition-all"
              required
            />
            <div class="flex justify-between mt-1">
              <p v-if="errors.title" class="text-sm text-red-600">{{ errors.title }}</p>
              <p class="text-sm text-gray-500">{{ formData.title.length }}/100</p>
            </div>
          </div>

          <!-- Description -->
          <div class="col-span-full">
            <label class="block text-sm font-medium text-gray-700 mb-2">
              Description <span class="text-red-500">*</span>
            </label>
            <textarea
              v-model="formData.description"
              rows="4"
              placeholder="Describe your item in detail..."
              maxlength="1000"
              class="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-emerald-500 focus:border-transparent transition-all resize-none"
              required
            ></textarea>
            <div class="flex justify-between mt-1">
              <p v-if="errors.description" class="text-sm text-red-600">{{ errors.description }}</p>
              <p class="text-sm text-gray-500">{{ formData.description.length }}/1000</p>
            </div>
          </div>
        </div>
      </div>

      <!-- Pricing & Condition -->
      <div class="bg-gray-50 rounded-xl p-6">
        <h2 class="text-xl font-semibold text-gray-800 mb-6 flex items-center gap-2">
          <Icon name="heroicons:currency-dollar" class="w-5 h-5 text-emerald-600" />
          Pricing & Condition
        </h2>
        
        <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
          <!-- Condition -->
          <div class="col-span-full">
            <label class="block text-sm font-medium text-gray-700 mb-3">
              Condition <span class="text-red-500">*</span>
            </label>
            <div class="grid grid-cols-2 md:grid-cols-5 gap-3">
              <label
                v-for="condition in conditions"
                :key="condition.value"
                :class="[
                  'flex items-center justify-center p-3 border-2 rounded-lg cursor-pointer transition-all text-sm font-medium',
                  formData.condition === condition.value
                    ? 'border-emerald-500 bg-emerald-50 text-emerald-700'
                    : 'border-gray-200 hover:border-emerald-300 hover:bg-emerald-50'
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
            <p v-if="errors.condition" class="mt-1 text-sm text-red-600">{{ errors.condition }}</p>
          </div>

          <!-- Price -->
          <div class="col-span-full">
            <label class="block text-sm font-medium text-gray-700 mb-2">
              Price <span class="text-red-500">*</span>
            </label>
            <div class="flex items-center gap-4">
              <div class="flex-1">
                <div class="relative">
                  <span class="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-500 font-medium">৳</span>
                  <input
                    v-model="formData.price"
                    type="number"
                    placeholder="Enter price"
                    min="0"
                    step="0.01"
                    :disabled="formData.negotiable"
                    class="w-full pl-8 pr-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-emerald-500 focus:border-transparent transition-all disabled:bg-gray-100"
                    :required="!formData.negotiable"
                  />
                </div>
              </div>
              <label class="flex items-center gap-2 cursor-pointer bg-white px-4 py-3 border border-gray-300 rounded-lg hover:bg-gray-50">
                <input
                  v-model="formData.negotiable"
                  type="checkbox"
                  class="w-4 h-4 text-emerald-600 border-gray-300 rounded focus:ring-emerald-500"
                />
                <span class="text-sm font-medium text-gray-700">Negotiable</span>
              </label>
            </div>
            <p v-if="errors.price" class="mt-1 text-sm text-red-600">{{ errors.price }}</p>
          </div>
        </div>
      </div>

      <!-- Location -->
      <div class="bg-gray-50 rounded-xl p-6">
        <h2 class="text-xl font-semibold text-gray-800 mb-6 flex items-center gap-2">
          <Icon name="heroicons:map-pin" class="w-5 h-5 text-emerald-600" />
          Location
        </h2>
        
        <div class="space-y-4">
          <!-- All Bangladesh Option -->
          <div class="bg-white p-4 rounded-lg border">
            <label class="flex items-center gap-3 cursor-pointer">
              <input
                v-model="allOverBangladesh"
                type="checkbox"
                class="w-4 h-4 text-emerald-600 border-gray-300 rounded focus:ring-emerald-500"
              />
              <span class="font-medium text-gray-700">All over Bangladesh</span>
            </label>
          </div>

          <!-- Location Fields -->
          <div v-if="!allOverBangladesh" class="grid grid-cols-1 md:grid-cols-3 gap-4">
            <div>
              <label class="block text-sm font-medium text-gray-700 mb-2">Division</label>
              <select
                v-model="formData.division"
                class="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-emerald-500 focus:border-transparent transition-all"
                required
              >
                <option value="">Select Division</option>
                <option v-for="division in regions" :key="division.id" :value="division.name_eng">
                  {{ division.name_eng }}
                </option>
              </select>
            </div>

            <div>
              <label class="block text-sm font-medium text-gray-700 mb-2">District</label>
              <select
                v-model="formData.district"
                :disabled="!formData.division"
                class="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-emerald-500 focus:border-transparent transition-all disabled:bg-gray-100"
                required
              >
                <option value="">Select District</option>
                <option v-for="district in cities" :key="district.id" :value="district.name_eng">
                  {{ district.name_eng }}
                </option>
              </select>
            </div>

            <div>
              <label class="block text-sm font-medium text-gray-700 mb-2">Area</label>
              <select
                v-model="formData.area"
                :disabled="!formData.district"
                class="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-emerald-500 focus:border-transparent transition-all disabled:bg-gray-100"
                required
              >
                <option value="">Select Area</option>
                <option v-for="area in upazilas" :key="area.id" :value="area.name_eng">
                  {{ area.name_eng }}
                </option>
              </select>
            </div>
          </div>

          <!-- Detailed Address -->
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-2">
              Detailed Address <span class="text-red-500">*</span>
            </label>
            <textarea
              v-model="formData.detailedAddress"
              rows="3"
              placeholder="Provide specific location details..."
              class="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-emerald-500 focus:border-transparent transition-all resize-none"
              required
            ></textarea>
            <p v-if="errors.detailedAddress" class="mt-1 text-sm text-red-600">{{ errors.detailedAddress }}</p>
          </div>
        </div>
      </div>

      <!-- Contact Information -->
      <div class="bg-gray-50 rounded-xl p-6">
        <h2 class="text-xl font-semibold text-gray-800 mb-6 flex items-center gap-2">
          <Icon name="heroicons:phone" class="w-5 h-5 text-emerald-600" />
          Contact Information
        </h2>
        
        <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-2">
              Phone Number <span class="text-red-500">*</span>
            </label>
            <input
              v-model="formData.phone"
              type="tel"
              placeholder="01XXXXXXXXX"
              pattern="[0-9]{11}"
              class="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-emerald-500 focus:border-transparent transition-all"
              required
            />
            <p v-if="errors.phone" class="mt-1 text-sm text-red-600">{{ errors.phone }}</p>
          </div>

          <div>
            <label class="block text-sm font-medium text-gray-700 mb-2">Email (Optional)</label>
            <input
              v-model="formData.email"
              type="email"
              placeholder="your@email.com"
              class="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-emerald-500 focus:border-transparent transition-all"
            />
          </div>
        </div>
      </div>

      <!-- Image Upload -->
      <div class="bg-gray-50 rounded-xl p-6">
        <h2 class="text-xl font-semibold text-gray-800 mb-6 flex items-center gap-2">
          <Icon name="heroicons:photo" class="w-5 h-5 text-emerald-600" />
          Upload Photos
        </h2>
        
        <p class="text-sm text-gray-600 mb-6">
          Upload clear photos to get more responses. You can upload up to 8 images.
          <span class="font-medium text-emerald-600">First image will be the main image.</span>
        </p>

        <div class="grid grid-cols-2 md:grid-cols-4 gap-4 mb-6">
          <div
            v-for="n in 8"
            :key="n"
            class="aspect-square relative border-2 border-dashed rounded-xl group transition-all cursor-pointer overflow-hidden"
            :class="
              formData.images[n - 1]
                ? 'border-emerald-500 bg-emerald-50'
                : 'border-gray-300 hover:border-emerald-400 hover:bg-emerald-50'
            "
            @click="openFileUpload(n - 1)"
          >
            <input
              type="file"
              :ref="el => { if (el) fileInputRefs[`fileInput${n - 1}`] = el }"
              class="hidden"
              accept="image/*"
              @change="handleFileUpload($event, n - 1)"
            />

            <div
              v-if="!formData.images[n - 1]"
              class="absolute inset-0 flex flex-col items-center justify-center p-3 text-center"
            >
              <Icon
                name="heroicons:photo"
                class="w-8 h-8 text-gray-400 group-hover:text-emerald-500 transition-colors mb-2"
              />
              <div class="text-xs text-gray-500 group-hover:text-emerald-600 transition-colors">
                {{ n === 1 ? "Main Photo" : "Add Photo" }}
              </div>
            </div>

            <img
              v-else
              :src="imagePreviewUrls[n - 1]"
              class="absolute inset-0 w-full h-full object-cover"
              alt="Preview"
            />

            <button
              v-if="formData.images[n - 1]"
              type="button"
              class="absolute top-2 right-2 bg-red-500 text-white rounded-full w-6 h-6 flex items-center justify-center opacity-0 group-hover:opacity-100 transition-opacity text-xs"
              @click.stop="removeImage(n - 1)"
            >
              ×
            </button>

            <div
              v-if="n === 1 && formData.images[n - 1]"
              class="absolute top-2 left-2 bg-emerald-500 text-white text-xs px-2 py-1 rounded font-medium"
            >
              Main
            </div>
          </div>
        </div>

        <!-- Compression Progress -->
        <div
          v-if="isCompressing"
          class="bg-blue-50 rounded-lg p-4 mb-4 border border-blue-200"
        >
          <div class="flex items-center gap-3 mb-2">
            <Icon name="heroicons:arrow-path" class="w-5 h-5 text-blue-600 animate-spin" />
            <span class="text-sm font-medium text-blue-800">{{ compressionStatus }}</span>
          </div>
          <div class="w-full bg-blue-200 rounded-full h-2">
            <div 
              class="bg-blue-600 h-full rounded-full transition-all duration-300"
              :style="{ width: `${compressionProgress}%` }"
            ></div>
          </div>
        </div>

        <p v-if="errors.images" class="text-sm text-red-600">{{ errors.images }}</p>
      </div>

      <!-- Terms -->
      <div class="bg-gray-50 rounded-xl p-6">
        <label class="flex items-start gap-3 cursor-pointer">
          <input
            v-model="formData.termsAccepted"
            type="checkbox"
            class="w-5 h-5 text-emerald-600 border-gray-300 rounded focus:ring-emerald-500 mt-0.5"
            required
          />
          <div class="text-sm text-gray-700">
            I agree to the
            <a href="#" class="text-emerald-600 hover:underline font-medium">Terms and Conditions</a>
            and
            <a href="#" class="text-emerald-600 hover:underline font-medium">Privacy Policy</a>
            <span class="text-red-500">*</span>
          </div>
        </label>
        <p v-if="errors.termsAccepted" class="mt-2 text-sm text-red-600">{{ errors.termsAccepted }}</p>
      </div>

      <!-- Submit Button -->
      <div class="flex justify-end pt-6">
        <button
          type="submit"
          :disabled="isSubmitting"
          class="bg-gradient-to-r from-emerald-500 to-teal-600 text-white px-8 py-4 rounded-xl hover:from-emerald-600 hover:to-teal-700 transition-all duration-200 font-medium text-lg shadow-lg hover:shadow-xl disabled:opacity-50 disabled:cursor-not-allowed flex items-center gap-2"
        >
          <Icon
            v-if="isSubmitting"
            name="heroicons:arrow-path"
            class="w-5 h-5 animate-spin"
          />
          <Icon
            v-else
            name="heroicons:paper-airplane"
            class="w-5 h-5"
          />
          {{ isSubmitting ? 'Posting...' : (editPost ? 'Update Listing' : 'Post Your Ad') }}
        </button>
      </div>
    </form>
  </div>
</template>

<script setup>
import { ref, reactive, computed, watch, onMounted, nextTick } from "vue";
import { useSalePost } from "~/composables/useSalePost";

const { get } = useApi();
const toast = useToast();

// Props
const props = defineProps({
  categories: {
    type: Array,
    default: () => []
  },
  editPost: {
    type: Object,
    default: null,
  },
});

// Emits
const emit = defineEmits(["post-saved"]);

// Composables
const {
  createSalePost,
  updateSalePost,
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
  images: [],
  termsAccepted: false,
});

// State
const allOverBangladesh = ref(false);
const isSubmitting = computed(() => apiLoading.value);
const errors = reactive({});
const showSuccessModal = ref(false);

// Location data
const regions = ref([]);
const cities = ref([]);
const upazilas = ref([]);
const childCategories = ref([]);

// Conditions
const conditions = ref([]);

// Image handling
const imagePreviewUrls = ref([]);
const fileInputRefs = reactive({});
const isCompressing = ref(false);
const compressionProgress = ref(0);
const compressionStatus = ref("");

// Load conditions
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

// Load regions
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
      const response = await get(`/sale/child-categories/?parent_id=${formData.category}`);
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

// Watch for API errors
watch(
  () => apiError.value,
  (newError) => {
    if (newError && !isSubmitting.value) {
      if (typeof newError === "object") {
        Object.keys(newError).forEach((key) => {
          errors[key] = Array.isArray(newError[key]) ? newError[key][0] : newError[key];
        });
      } else {
        console.error("Error occurred:", newError);
      }
    }
  }
);

// File upload functions
const openFileUpload = (index) => {
  if (fileInputRefs[`fileInput${index}`]) {
    fileInputRefs[`fileInput${index}`].click();
  }
};

const handleFileUpload = async (event, index) => {
  const file = event.target.files[0];
  if (!file) return;

  // Validate file
  if (!file.type.match("image.*")) {
    errors.images = "Please upload only image files";
    return;
  }

  if (file.size > 12 * 1024 * 1024) {
    errors.images = "Image size should be less than 12MB";
    return;
  }

  isCompressing.value = true;
  compressionStatus.value = `Compressing ${file.name}...`;
  compressionProgress.value = 0;
  errors.images = "";

  try {
    compressionProgress.value = 20;
    compressionStatus.value = "Analyzing image...";
    
    const compressedImage = await processImageWithCompression(file);
    
    if (compressedImage) {
      compressionProgress.value = 80;
      compressionStatus.value = "Finalizing...";
      
      imagePreviewUrls.value[index] = compressedImage;
      formData.images[index] = compressedImage;

      compressionStatus.value = "Compression completed!";
      compressionProgress.value = 100;

      setTimeout(() => {
        isCompressing.value = false;
      }, 1000);
    }
  } catch (error) {
    console.error("Error compressing image:", error);
    errors.images = "Failed to process image. Please try again.";
    isCompressing.value = false;
  }
};

const removeImage = (index) => {
  imagePreviewUrls.value[index] = null;
  formData.images[index] = null;
  
  if (fileInputRefs[`fileInput${index}`]) {
    fileInputRefs[`fileInput${index}`].value = "";
  }
  
  errors.images = "";
};

// Image compression function
const processImageWithCompression = (file) => {
  return new Promise((resolve, reject) => {
    const reader = new FileReader();
    reader.onload = (e) => {
      const img = new Image();
      img.onload = () => {
        const canvas = document.createElement("canvas");
        const ctx = canvas.getContext("2d");
        
        // Calculate new dimensions
        const maxWidth = 800;
        const maxHeight = 600;
        let { width, height } = img;
        
        if (width > height) {
          if (width > maxWidth) {
            height = (height * maxWidth) / width;
            width = maxWidth;
          }
        } else {
          if (height > maxHeight) {
            width = (width * maxHeight) / height;
            height = maxHeight;
          }
        }
        
        canvas.width = width;
        canvas.height = height;
        
        // Draw and compress
        ctx.drawImage(img, 0, 0, width, height);
        const compressedDataUrl = canvas.toDataURL("image/jpeg", 0.8);
        resolve(compressedDataUrl);
      };
      img.onerror = reject;
      img.src = e.target.result;
    };
    reader.onerror = reject;
    reader.readAsDataURL(file);
  });
};

// Form submission
const submitForm = async () => {
  if (isSubmitting.value) return;

  // Clear errors
  Object.keys(errors).forEach((key) => (errors[key] = ""));

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
    if (!value || value === '') {
      missingFields.push(key);
    }
  });

  if (missingFields.length > 0) {
    toast.add({
      title: "Validation Error",
      description: `Please fill in all required fields: ${missingFields.join(', ')}`,
      color: "red",
      timeout: 5000,
    });
    return;
  }

  // Validate price
  if (!formData.negotiable && (!formData.price || parseFloat(formData.price) <= 0)) {
    toast.add({
      title: "Validation Error",
      description: "Please enter a valid price or mark as negotiable",
      color: "red",
      timeout: 5000,
    });
    return;
  }

  // Validate images
  const validImages = formData.images.filter((img) => img && typeof img === 'string');
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

  try {
    // Prepare submission data
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
      images: validImages,
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
      submissionData.price = formData.price && formData.price !== '' ? parseFloat(formData.price) : null;
    } else {
      submissionData.price = parseFloat(formData.price);
    }

    console.log("Submitting data:", submissionData);

    let result;
    if (props.editPost) {
      result = await updateSalePost(props.editPost.id, submissionData);
    } else {
      result = await createSalePost(submissionData);
      showSuccessModal.value = true;
      
      // Auto-close modal after 5 seconds
      setTimeout(() => {
        closeSuccessModal();
      }, 5000);
    }

    console.log("Submission successful:", result);
    emit("post-saved", result);

  } catch (error) {
    console.error("Error submitting form:", error);
    
    let errorMessage = "Failed to submit your listing. Please try again.";
    
    if (error?.response?.status === 400) {
      errorMessage = "Please check your form data and try again.";
    } else if (error?.message?.includes('network')) {
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
};

// Reset form
const resetForm = () => {
  Object.keys(formData).forEach((key) => {
    if (key === "termsAccepted" || key === "negotiable") {
      formData[key] = false;
    } else if (key === "images") {
      formData[key] = [];
    } else {
      formData[key] = "";
    }
  });

  imagePreviewUrls.value = [];
  Object.keys(fileInputRefs).forEach((key) => {
    if (fileInputRefs[key]) {
      fileInputRefs[key].value = "";
    }
  });

  Object.keys(errors).forEach((key) => {
    errors[key] = "";
  });

  childCategories.value = [];
  allOverBangladesh.value = false;
};

// Populate form for editing
const populateFormWithEditData = async () => {
  const post = props.editPost;
  if (!post) return;

  // Load child categories if needed
  if (post.category) {
    try {
      const response = await get(`/sale/child-categories/?parent_id=${post.category}`);
      childCategories.value = response.data || [];
    } catch (error) {
      console.error("Error loading child categories:", error);
    }
  }

  // Populate form fields
  formData.category = post.category;
  formData.childCategory = post.child_category || "";
  formData.title = post.title;
  formData.description = post.description;
  formData.condition = post.condition;
  formData.price = post.price;
  formData.negotiable = post.negotiable || false;
  formData.division = post.division;
  formData.district = post.district;
  formData.area = post.area;
  formData.detailedAddress = post.detailed_address;
  formData.phone = post.phone;
  formData.email = post.email;
  formData.termsAccepted = true;

  // Handle existing images
  if (post.images && Array.isArray(post.images)) {
    post.images.forEach((image, index) => {
      if (index < 8) {
        const imageUrl = image.image || image;
        imagePreviewUrls.value[index] = imageUrl;
        formData.images[index] = imageUrl;
      }
    });
  }
};

// Initialize component
onMounted(async () => {
  await Promise.all([
    loadConditions(),
    loadRegions()
  ]);

  if (props.editPost) {
    await populateFormWithEditData();
  }
});

// Watch for edit post changes
watch(
  () => props.editPost,
  (newEditPost) => {
    if (newEditPost) {
      populateFormWithEditData();
    }
  }
);
</script>

<style scoped>
/* Custom scrollbar for textareas */
textarea::-webkit-scrollbar {
  width: 6px;
}

textarea::-webkit-scrollbar-track {
  background: #f1f1f1;
  border-radius: 3px;
}

textarea::-webkit-scrollbar-thumb {
  background: #cbd5e0;
  border-radius: 3px;
}

textarea::-webkit-scrollbar-thumb:hover {
  background: #a0aec0;
}

/* Loading animation for submit button */
@keyframes spin {
  to {
    transform: rotate(360deg);
  }
}

.animate-spin {
  animation: spin 1s linear infinite;
}

/* Focus styles */
input:focus,
select:focus,
textarea:focus {
  outline: none;
  box-shadow: 0 0 0 3px rgba(16, 185, 129, 0.1);
}

/* Disabled styles */
input:disabled,
select:disabled {
  cursor: not-allowed;
  opacity: 0.6;
}

/* Hover effects */
.group:hover .group-hover\:opacity-100 {
  opacity: 1;
}

.group:hover .group-hover\:text-emerald-500 {
  color: #10b981;
}

.group:hover .group-hover\:text-emerald-600 {
  color: #059669;
}
</style>
