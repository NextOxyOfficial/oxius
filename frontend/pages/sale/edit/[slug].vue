<template>
  <UContainer>
    <form @submit.prevent="submitForm" class="space-y-6">
      <!-- Basic Details Section -->
      <div class="bg-white rounded-lg border border-gray-200 p-6">
        <h3
          class="text-lg font-semibold text-gray-900 mb-4 flex items-center gap-2"
        >
          <UIcon name="i-heroicons-document-text" class="text-emerald-600" />
          Basic Details
        </h3>

        <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
          <UFormGroup
            label="Category"
            required
            :error="
              !formData.category && checkSubmit && 'You must select a category'
            "
          >
            <USelectMenu
              v-model="formData.category"
              color="white"
              size="md"
              :options="categories"
              placeholder="Select Category"
              option-attribute="name"
              value-attribute="id"
              @change="handleCategoryChange"
            />
          </UFormGroup>

          <UFormGroup
            v-if="childCategories.length > 0"
            label="Sub Category"
            :error="
              !formData.child_category &&
              checkSubmit &&
              'You must select a sub category'
            "
          >
            <USelectMenu
              v-model="formData.child_category"
              color="white"
              size="md"
              :options="childCategories"
              placeholder="Select Sub Category"
              option-attribute="name"
              value-attribute="id"
            />
          </UFormGroup>
        </div>

        <UFormGroup
          label="Title"
          required
          :error="!formData.title && checkSubmit && 'You must enter a title!'"
          class="mt-4"
        >
          <UInput
            type="text"
            size="md"
            color="white"
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
        <UFormGroup
          label="Description"
          required
          class="mt-4"
          :error="
            getTextLength(formData.description) === 0 &&
            checkSubmit &&
            'Please provide a description of your item'
          "
        >
          <CommonEditor
            :content="formData.description"
            @updateContent="formData.description = $event"
          />
          <div class="text-right text-sm text-gray-500 mt-1">
            {{ getTextLength(formData.description) }}/1000
          </div>
        </UFormGroup>
      </div>

      <!-- Pricing & Condition Section -->
      <div class="bg-white rounded-lg border border-gray-200 p-6">
        <h3
          class="text-lg font-semibold text-gray-900 mb-4 flex items-center gap-2"
        >
          <UIcon name="i-heroicons-currency-dollar" class="text-emerald-600" />
          Pricing & Condition
        </h3>

        <UFormGroup
          label="Condition"
          required
          :error="
            !formData.condition && checkSubmit && 'You must select a condition'
          "
          class="mb-4"
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

        <UFormGroup
          label="Price"
          :error="
            formData.price <= 0 &&
            !formData.negotiable &&
            checkSubmit &&
            'Price must be greater than 0 or mark as Negotiable'
          "
        >
          <div class="flex items-center gap-4">
            <UInput
              type="number"
              size="md"
              color="white"
              :disabled="formData.negotiable"
              placeholder="e.g. 1000"
              min="0"
              step="0.01"
              class="flex-1"
              v-model="formData.price"
            >
              <template #leading>
                <UIcon name="i-mdi:currency-bdt" />
              </template>
            </UInput>

            <UCheckbox
              v-model="formData.negotiable"
              name="Negotiable"
              label="Negotiable"
            />
          </div>
        </UFormGroup>
      </div>

      <!-- Media Upload Section -->
      <div class="bg-white rounded-lg border border-gray-200 p-6">
        <h3
          class="text-lg font-semibold text-gray-900 mb-4 flex items-center gap-2"
        >
          <UIcon name="i-heroicons-photo" class="text-emerald-600" />
          Upload Photos
        </h3>
        <p class="text-sm text-gray-600 mb-4">
          Add photos to showcase your listing (up to 8 images). First image will
          be the main image.
        </p>

        <div class="flex flex-wrap gap-4">
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
            <button
              type="button"
              class="absolute top-2 right-2 bg-white rounded-full w-8 h-8 flex items-center justify-center text-red-500 shadow-sm hover:bg-red-50 hover:scale-110 transition-all"
              @click="removeImage(i)"
            >
              <UIcon name="i-heroicons-trash" />
            </button>
            <div
              v-if="i === 0"
              class="absolute top-2 left-2 bg-emerald-500 text-white text-xs px-2 py-1 rounded font-medium"
            >
              Main
            </div>
          </div>
          <!-- Upload button -->
          <div
            class="w-32 h-32 rounded-lg relative border-2 border-dashed border-gray-300 bg-gray-50 hover:border-emerald-500 hover:bg-emerald-50/20 transition-colors flex items-center justify-center cursor-pointer group"
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
      <div class="bg-white rounded-lg border border-gray-200 p-6">
        <h3
          class="text-lg font-semibold text-gray-900 mb-4 flex items-center gap-2"
        >
          <UIcon name="i-heroicons-map-pin" class="text-emerald-600" />
          Location
        </h3>

        <UCheckbox
          v-model="allOverBangladesh"
          name="all-bangladesh"
          label="All over Bangladesh"
          color="primary"
          class="mb-4"
        />

        <div
          class="grid grid-cols-1 md:grid-cols-3 gap-4"
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
          >
            <USelectMenu
              v-model="formData.division"
              color="white"
              size="md"
              :options="regions"
              placeholder="Select Division"
              option-attribute="name_eng"
              value-attribute="name_eng"
            />
          </UFormGroup>

          <UFormGroup
            label="District"
            :error="
              !formData.district &&
              checkSubmit &&
              !allOverBangladesh &&
              'You must select a district'
            "
          >
            <USelectMenu
              v-model="formData.district"
              color="white"
              size="md"
              :options="cities"
              placeholder="Select District"
              option-attribute="name_eng"
              value-attribute="name_eng"
              :disabled="!formData.division"
            />
          </UFormGroup>

          <UFormGroup
            label="Area"
            :error="
              !formData.area &&
              checkSubmit &&
              !allOverBangladesh &&
              'You must select an area'
            "
          >
            <USelectMenu
              v-model="formData.area"
              color="white"
              size="md"
              :options="upazilas"
              placeholder="Select Area"
              option-attribute="name_eng"
              value-attribute="name_eng"
              :disabled="!formData.district"
            />
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
          class="mt-4"
        >
          <UTextarea
            v-model="formData.detailedAddress"
            color="white"
            size="md"
            :rows="3"
            placeholder="Provide specific location details..."
            class="resize-none"
          />
        </UFormGroup>
      </div>

      <!-- Contact Information Section -->
      <div class="bg-white rounded-lg border border-gray-200 p-6">
        <h3
          class="text-lg font-semibold text-gray-900 mb-4 flex items-center gap-2"
        >
          <UIcon name="i-heroicons-phone" class="text-emerald-600" />
          Contact Information
        </h3>

        <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
          <UFormGroup
            label="Phone Number"
            required
            :error="
              !formData.phone && checkSubmit && 'You must enter a phone number!'
            "
          >
            <UInput
              v-model="formData.phone"
              type="tel"
              size="md"
              color="white"
              placeholder="01XXXXXXXXX"
              pattern="[0-9]{11}"
            >
              <template #leading>
                <UIcon name="i-heroicons-phone" />
              </template>
            </UInput>
          </UFormGroup>

          <UFormGroup label="Email (Optional)">
            <UInput
              v-model="formData.email"
              type="email"
              size="md"
              color="white"
              placeholder="your@email.com"
            >
              <template #leading>
                <UIcon name="i-heroicons-envelope" />
              </template>
            </UInput>
          </UFormGroup>
        </div>
      </div>

      <!-- Terms Section -->
      <div class="bg-white rounded-lg border border-gray-200 p-6">
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
      <div class="flex justify-end p-4">
        <UButton
          type="submit"
          :loading="isSubmitting"
          :disabled="isSubmitting"
          color="emerald"
          size="lg"
          class="px-8 py-3"
        >
          <template #leading>
            <UIcon v-if="!isSubmitting" name="i-heroicons-paper-airplane" />
          </template>
          {{ isSubmitting ? "Saving..." : "Save Your Ad" }}
        </UButton>
      </div>
    </form>
  </UContainer>
</template>

<script setup>
const { get, put } = useApi();
const toast = useToast();
const route = useRoute();

// Form submission state
const isSubmitting = ref(false);

const formData = ref({
  category: null,
  child_category: null,
  title: "",
  description: "",
  condition: null,
  price: null,
  negotiable: false,
  images: Array(8).fill(null),
  division: null,
  district: null,
  area: null,
  detailedAddress: "",
  phone: "",
  email: "",
  termsAccepted: false,
});

const checkSubmit = ref(false);
const allOverBangladesh = ref(false);
const categories = ref([]);
const childCategories = ref([]);
const conditions = ref([]);
const regions = ref([]);
const cities = ref([]);
const upazilas = ref([]);
const imagePreviewUrls = ref(new Array(8).fill(null));

// Add missing variables for image management
const deletedImageIds = ref([]); // Track deleted image IDs
const newImages = ref([]); // Track new images to upload
const fileInput = ref(null); // File input reference
const isUploading = ref(false); // Upload state
const uploadError = ref(""); // Upload error message

async function getSalePost() {
  try {
    const res = await get(`/sale/posts/${route.params.slug}/`);
    if (res.data) {
      console.log("sale post value", res.data);
      formData.value = {
        category: res.data.category,
        child_category: res.data.child_category || null,
        title: res.data.title || "",
        description: res.data.description || "",
        condition: res.data.condition || null,
        price: res.data.price || null,
        negotiable: res.data.negotiable || false,
        division: res.data.division || null,
        district: res.data.district || null,
        area: res.data.area || null,
        detailedAddress: res.data.detailed_address || "",
        phone: res.data.phone || "",
        email: res.data.email || "",
        termsAccepted: true, // For editing, assume terms are already accepted
      };

      // Load child categories if a category is selected
      if (formData.value.category) {
        try {
          const response = await get(
            `/sale/child-categories/?parent_id=${formData.value.category}`
          );
          childCategories.value = response.data || [];
        } catch (error) {
          console.error("Error loading child categories:", error);
        }
      }

      // Handle location data - if all location fields are empty, set "All over Bangladesh"
      if (
        formData.value.division === null &&
        formData.value.district === null &&
        formData.value.area === null
      ) {
        allOverBangladesh.value = true;
      } else {
        allOverBangladesh.value = false;

        // Load cities for the selected division
        if (formData.value.division) {
          try {
            const cityResponse = await get(
              `/geo/cities/?region_name_eng=${formData.value.division}`
            );
            cities.value = cityResponse.data || [];
          } catch (error) {
            console.error("Error loading cities:", error);
          }
        }

        // Load upazilas for the selected district
        if (formData.value.district) {
          try {
            const upazilaResponse = await get(
              `/geo/upazila/?city_name_eng=${formData.value.district}`
            );
            upazilas.value = upazilaResponse.data || [];
          } catch (error) {
            console.error("Error loading upazilas:", error);
          }
        }
      }

      // Handle images from backend
      if (res.data.images && Array.isArray(res.data.images)) {
        // Initialize arrays
        formData.value.images = new Array(8).fill(null);
        imagePreviewUrls.value = new Array(8).fill(null);

        // Place existing images in the arrays
        res.data.images.forEach((img, index) => {
          if (index < 8) {
            formData.value.images[index] = img; // Store the whole image object
            imagePreviewUrls.value[index] = img.image; // Display URL
          }
        });
      } else {
        formData.value.images = new Array(8).fill(null);
        imagePreviewUrls.value = new Array(8).fill(null);
      }
    }
  } catch (err) {
    console.error("Error fetching sale post data:", err);
  }
}

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

// Watch division change
watch(
  () => formData.value.division,
  async (newDivision) => {
    if (newDivision) {
      try {
        const response = await get(
          `/geo/cities/?region_name_eng=${newDivision}`
        );
        cities.value = response.data || [];
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
  () => formData.value.district,
  async (newDistrict) => {
    if (newDistrict) {
      try {
        const response = await get(
          `/geo/upazila/?city_name_eng=${newDistrict}`
        );
        upazilas.value = response.data || [];
      } catch (error) {
        console.error("Error loading upazilas:", error);
      }
    } else {
      upazilas.value = [];
    }
  }
);

async function getChildCategories() {
  try {
    const response = await get(
      `/sale/child-categories/?parent_id=${formData.value.category}`
    );
    childCategories.value = response.data || [];
  } catch (error) {
    console.error("Error loading child categories:", error);
  }
}

// Handle category change
const handleCategoryChange = async () => {
  formData.value.child_category = "";
  childCategories.value = [];

  if (formData.value.category) {
    try {
      const response = await get(
        `/sale/child-categories/?parent_id=${formData.value.category}`
      );
      childCategories.value = response.data || [];
    } catch (error) {
      console.error("Error loading child categories:", error);
    }
  }
};

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

  isUploading.value = true;
  uploadError.value = "";

  try {
    const compressedImage = await processImageWithCompression(file);

    if (compressedImage) {
      // Find first empty slot
      const emptyIndex = formData.value.images.findIndex((img) => !img);
      if (emptyIndex !== -1) {
        // Store the base64 image in the images array
        formData.value.images[emptyIndex] = compressedImage;
        imagePreviewUrls.value[emptyIndex] = compressedImage;

        // Add to new images for submission
        newImages.value.push(compressedImage);
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
  const img = formData.value.images[index];

  if (img) {
    // If it's an existing image (object with id), mark for deletion
    if (typeof img === "object" && img.id) {
      deletedImageIds.value.push(img.id);
    }
    // If it's a new image (base64 string), remove from new images array
    else if (typeof img === "string" && img.startsWith("data:image")) {
      const newImageIndex = newImages.value.indexOf(img);
      if (newImageIndex !== -1) {
        newImages.value.splice(newImageIndex, 1);
      }
    }
  }

  // Clear the slot
  formData.value.images[index] = null;
  imagePreviewUrls.value[index] = null;
  uploadError.value = "";
};

// Enhanced image compression function with aggressive optimization
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

        // Calculate new dimensions with more aggressive optimization
        let { width, height } = img;

        // Get optimized settings based on file size and image dimensions
        const settings = getCompressionSettings(file.size, width, height);

        // Smart resizing with aspect ratio preservation
        if (width > settings.maxDimension || height > settings.maxDimension) {
          const aspectRatio = width / height;

          if (width > height) {
            width = settings.maxDimension;
            height = Math.round(width / aspectRatio);
          } else {
            height = settings.maxDimension;
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
        let quality = settings.initialQuality;
        let resultImage = canvas.toDataURL("image/jpeg", quality);
        let resultSize = Math.round((resultImage.length * 3) / 4);

        // Phase 1: Fine quality reduction
        while (
          resultSize > settings.targetSize &&
          quality > settings.minQuality + 0.1
        ) {
          quality -= 0.02;
          resultImage = canvas.toDataURL("image/jpeg", quality);
          resultSize = Math.round((resultImage.length * 3) / 4);
        }

        // Phase 2: Dimensional reduction if needed
        if (
          resultSize > settings.targetSize &&
          quality <= settings.minQuality + 0.1
        ) {
          const scaleFactor = Math.sqrt(settings.targetSize / resultSize) * 0.9;
          const newWidth = Math.max(400, Math.round(width * scaleFactor));
          const newHeight = Math.max(400, Math.round(height * scaleFactor));

          canvas.width = newWidth;
          canvas.height = newHeight;
          ctx.drawImage(img, 0, 0, newWidth, newHeight);

          quality = Math.max(settings.minQuality, 0.65);
          resultImage = canvas.toDataURL("image/jpeg", quality);
          resultSize = Math.round((resultImage.length * 3) / 4);
        }

        // Final quality fine-tuning
        while (
          resultSize > settings.targetSize &&
          quality > settings.minQuality
        ) {
          quality -= 0.05;
          resultImage = canvas.toDataURL("image/jpeg", quality);
          resultSize = Math.round((resultImage.length * 3) / 4);
        }

        console.log(
          `Image compressed: ${formatFileSize(file.size)} → ${formatFileSize(
            resultSize
          )} (${(quality * 100).toFixed(0)}% quality)`
        );
        resolve(resultImage);
      };
      img.onerror = reject;
      img.src = e.target.result;
    };
    reader.onerror = reject;
    reader.readAsDataURL(file);
  });
};

// Get optimized compression settings based on image characteristics
const getCompressionSettings = (fileSize, imageWidth, imageHeight) => {
  const settings = {
    maxDimension: 1200,
    targetSize: 80 * 1024, // 80KB aggressive target
    initialQuality: 0.78,
    minQuality: 0.45,
  };

  // Adjust for large files (>5MB) - more aggressive
  if (fileSize > 5 * 1024 * 1024) {
    settings.maxDimension = 1000;
    settings.targetSize = 75 * 1024; // 75KB for large files
    settings.initialQuality = 0.75;
    settings.minQuality = 0.4;
  }

  // Adjust for very large images (>4000px) - prioritize size reduction
  if (imageWidth > 4000 || imageHeight > 4000) {
    settings.maxDimension = 800;
    settings.targetSize = 70 * 1024; // 70KB
    settings.initialQuality = 0.7;
    settings.minQuality = 0.35;
  }

  // Adjust for small files (<1MB) - maintain reasonable quality
  if (fileSize < 1024 * 1024) {
    settings.targetSize = 85 * 1024; // 85KB for small files
    settings.minQuality = 0.5;
    settings.initialQuality = 0.8;
  }

  return settings;
};

// Format file size utility
const formatFileSize = (bytes) => {
  if (bytes === 0) return "0 Bytes";
  const k = 1024;
  const sizes = ["Bytes", "KB", "MB", "GB"];
  const i = Math.floor(Math.log(bytes) / Math.log(k));
  return parseFloat((bytes / Math.pow(k, i)).toFixed(1)) + " " + sizes[i];
};

// Get text length from HTML content
const getTextLength = (htmlContent) => {
  if (!htmlContent) return 0;
  // Create a temporary div to strip HTML tags and get text content
  const tempDiv = document.createElement("div");
  tempDiv.innerHTML = htmlContent;
  return tempDiv.textContent?.length || 0;
};

// Form submission
const submitForm = async () => {
  checkSubmit.value = true;

  if (isSubmitting.value) return;
  // Validate required fields
  const requiredFields = {
    category: formData.value.category,
    title: formData.value.title?.trim(),
    description:
      getTextLength(formData.value.description) > 0
        ? formData.value.description
        : null,
    condition: formData.value.condition,
    detailed_address: formData.value.detailedAddress?.trim(),
    phone: formData.value.phone?.trim(),
  };

  // Add location validation if not all over Bangladesh
  if (!allOverBangladesh.value) {
    requiredFields.division = formData.value.division;
    requiredFields.district = formData.value.district;
    requiredFields.area = formData.value.area;
  }

  const missingFields = [];
  Object.entries(requiredFields).forEach(([key, value]) => {
    if (!value || value === "") {
      missingFields.push(key);
    }
  });

  if (missingFields?.length > 0) {
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
    !formData.value.negotiable &&
    (!formData.value.price || parseFloat(formData.value.price) <= 0)
  ) {
    toast.add({
      title: "Validation Error",
      description: "Please enter a valid price or mark as negotiable",
      color: "red",
      timeout: 5000,
    });
    return;
  }

  // Validate description length
  if (getTextLength(formData.value.description) > 1000) {
    toast.add({
      title: "Validation Error",
      description: "Description must be less than 1000 characters",
      color: "red",
      timeout: 5000,
    });
    return;
  }
  // Prepare images - only new base64 images for submission
  const newImageData = formData.value.images.filter(
    (img) => img && typeof img === "string" && img.startsWith("data:image")
  );

  // Check if we have at least one image remaining (existing or new)
  const remainingImages = formData.value.images.filter(
    (img) => img && !deletedImageIds.value.includes(img?.id)
  );
  if (remainingImages.length === 0) {
    toast.add({
      title: "Validation Error",
      description: "Please keep at least one image",
      color: "red",
      timeout: 5000,
    });
    return;
  }

  // Validate terms
  if (!formData.value.termsAccepted) {
    toast.add({
      title: "Validation Error",
      description: "Please accept the terms and conditions",
      color: "red",
      timeout: 5000,
    });
    return;
  }

  isSubmitting.value = true;

  try {
    // Prepare submission data for updating
    const submissionData = {
      category: parseInt(formData.value.category),
      child_category: formData.value.child_category
        ? parseInt(formData.value.child_category)
        : null,
      title: formData.value.title.trim(),
      description: formData.value.description.trim(),
      condition: formData.value.condition,
      detailed_address: formData.value.detailedAddress.trim(),
      phone: formData.value.phone.trim(),
      negotiable: Boolean(formData.value.negotiable),
      division: allOverBangladesh.value ? "" : formData.value.division,
      district: allOverBangladesh.value ? "" : formData.value.district,
      area: allOverBangladesh.value ? "" : formData.value.area,
      images: newImageData, // Only new images (base64)
      deleted_images: deletedImageIds.value, // Images to delete
    };

    if (formData.value.email?.trim()) {
      submissionData.email = formData.value.email.trim();
    }

    // Handle price
    if (formData.value.negotiable) {
      submissionData.price = 0;
    } else {
      submissionData.price = parseFloat(formData.value.price);
    }

    console.log("Updating post with data:", submissionData);

    // Make API call to update the post

    const response = await put(
      `/sale/posts/${route.params.slug}/`,
      submissionData
    );

    if (response) {
      toast.add({
        title: "Success",
        description: "Your listing has been updated successfully!",
        color: "green",
        timeout: 5000,
      });

      // Redirect to the updated post
      navigateTo(`/sale/${route.params.slug}`);
    }
    resetForm();
  } catch (error) {
    console.error("Error submitting form:", error);
    console.error("Error details:", {
      status: error?.response?.status,
      statusText: error?.response?.statusText,
      data: error?.response?.data,
      message: error?.message,
    });
    let errorMessage = "Failed to submit your listing. Please try again.";

    if (error?.response?.status === 400) {
      // Check for specific validation errors
      const errorData = error.response.data;
      if (errorData?.detail) {
        errorMessage = `Validation Error: ${errorData.detail}`;
      } else if (errorData?.non_field_errors) {
        errorMessage = `Validation Error: ${errorData.non_field_errors.join(
          ", "
        )}`;
      } else if (typeof errorData === "object") {
        // Extract field-specific errors
        const fieldErrors = Object.entries(errorData)
          .map(
            ([field, errors]) =>
              `${field}: ${Array.isArray(errors) ? errors.join(", ") : errors}`
          )
          .join("; ");
        errorMessage = fieldErrors
          ? `Validation Errors: ${fieldErrors}`
          : "Please check your form data and try again.";
      } else {
        errorMessage = "Please check your form data and try again.";
      }
    } else if (error?.response?.status === 413) {
      errorMessage = "Request too large. Please try uploading smaller images.";
    } else if (error?.message?.includes("network")) {
      errorMessage = "Network error. Please check your connection.";
    }

    toast.add({
      title: "Error",
      description: errorMessage,
      color: "red",
      timeout: 8000,
    });
  } finally {
    isSubmitting.value = false;
  }
};

// Reset form
const resetForm = () => {
  Object.keys(formData.value).forEach((key) => {
    if (key === "termsAccepted" || key === "negotiable") {
      formData.value[key] = false;
    } else if (key === "images") {
      formData.value[key] = new Array(8).fill(null);
    } else {
      formData.value[key] = "";
    }
  });

  imagePreviewUrls.value = new Array(8).fill(null);
  childCategories.value = [];
  allOverBangladesh.value = false;
  checkSubmit.value = false;
};

// Initialize component
onMounted(async () => {
  await Promise.all([
    loadCategories(),
    loadConditions(),
    loadRegions(),
    getSalePost(),
  ]);
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
