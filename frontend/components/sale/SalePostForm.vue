<template>
  <form
    @submit.prevent="submitForm"
    class="bg-white rounded-xl border border-slate-200 overflow-hidden"
  >
    <!-- Basic Details Section -->
    <section class="p-4 sm:p-5">
      <div class="flex items-center gap-2 mb-3">
        <span class="h-7 w-7 rounded-lg bg-emerald-50 text-emerald-600 flex items-center justify-center">
          <UIcon name="i-heroicons-document-text" class="h-4 w-4" />
        </span>
        <h3 class="text-sm font-bold text-slate-800">{{ t("sale_form_basic_details") }}</h3>
      </div>

      <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
        <UFormGroup
          :label="t('sale_form_category')"
          required
          :error="!formData.category && checkSubmit && t('sale_form_err_category')"
        >
          <USelectMenu
            v-model="formData.category"
            color="white"
            size="md"
            :options="categories"
            :placeholder="t('sale_form_select_category')"
            option-attribute="name"
            value-attribute="id"
            @change="handleCategoryChange"
          />
        </UFormGroup>

        <UFormGroup
          v-if="childCategories.length > 0"
          :label="t('sale_form_subcategory')"
          :error="!formData.childCategory && checkSubmit && t('sale_form_err_subcategory')"
        >
          <USelectMenu
            v-model="formData.childCategory"
            color="white"
            size="md"
            :options="childCategories"
            :placeholder="t('sale_form_select_subcategory')"
            option-attribute="name"
            value-attribute="id"
          />
        </UFormGroup>
      </div>

      <UFormGroup
        :label="t('sale_form_title')"
        required
        :error="!formData.title && checkSubmit && t('sale_form_err_title')"
        class="mt-4"
      >
        <UInput
          type="text"
          size="md"
          color="white"
          :placeholder="t('sale_form_title_ph')"
          v-model="formData.title"
          maxlength="100"
        >
          <template #leading>
            <UIcon name="i-heroicons-pencil-square" />
          </template>
        </UInput>
        <div class="text-right text-xs text-gray-400 mt-1">{{ formData.title.length }}/100</div>
      </UFormGroup>

      <UFormGroup
        :label="t('sale_form_description')"
        required
        class="mt-4"
        :error="getTextLength(formData.description) === 0 && checkSubmit && t('sale_form_err_description')"
      >
        <Editor
          :content="formData.description"
          @updateContent="formData.description = $event"
        />
        <div class="text-right text-xs text-gray-400 mt-1">{{ getTextLength(formData.description) }}/1000</div>
      </UFormGroup>
    </section>

    <!-- Pricing & Condition Section -->
    <section class="p-4 sm:p-5 border-t border-slate-100">
      <div class="flex items-center gap-2 mb-3">
        <span class="h-7 w-7 rounded-lg bg-emerald-50 text-emerald-600 flex items-center justify-center">
          <UIcon name="i-mdi:currency-bdt" class="h-4 w-4" />
        </span>
        <h3 class="text-sm font-bold text-slate-800">{{ t("sale_form_pricing_condition") }}</h3>
      </div>

      <UFormGroup
        :label="t('sale_form_condition')"
        required
        :error="!formData.condition && checkSubmit && t('sale_form_err_condition')"
        class="mb-4"
      >
        <div class="grid grid-cols-2 md:grid-cols-5 gap-2.5">
          <label
            v-for="condition in conditions"
            :key="condition.value"
            :class="[
              'flex items-center justify-center px-2 py-2.5 border rounded-lg cursor-pointer transition-all text-sm font-medium text-center',
              formData.condition === condition.value
                ? 'border-emerald-500 bg-emerald-50 text-emerald-700'
                : 'border-gray-200 text-gray-600 hover:border-emerald-300 hover:bg-emerald-50/50',
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
        :label="t('sale_form_price')"
        :error="formData.price <= 0 && !formData.negotiable && checkSubmit && t('sale_form_err_price')"
      >
        <div class="flex items-center gap-4">
          <UInput
            type="number"
            size="md"
            color="white"
            :disabled="formData.negotiable"
            :placeholder="t('sale_form_price_ph')"
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
            :label="t('sale_form_negotiable')"
          />
        </div>
      </UFormGroup>
    </section>

    <!-- Media Upload Section -->
    <section class="p-4 sm:p-5 border-t border-slate-100">
      <div class="flex items-center gap-2 mb-1">
        <span class="h-7 w-7 rounded-lg bg-emerald-50 text-emerald-600 flex items-center justify-center">
          <UIcon name="i-heroicons-photo" class="h-4 w-4" />
        </span>
        <h3 class="text-sm font-bold text-slate-800">{{ t("sale_form_photos") }}</h3>
      </div>
      <p class="text-xs text-gray-500 mb-3 ml-9">{{ t("sale_form_photos_hint") }}</p>

      <div class="flex flex-wrap gap-3">
        <!-- Uploaded images -->
        <div
          v-for="(img, i) in formData.images"
          :key="i"
          class="w-28 h-28 rounded-lg overflow-hidden relative border border-gray-200 bg-gray-50 group"
          v-show="img"
        >
          <img
            :src="imagePreviewUrls[i]"
            :alt="`Uploaded file ${i}`"
            class="w-full h-full object-cover transition-transform group-hover:scale-105"
          />
          <button
            type="button"
            class="absolute top-1.5 right-1.5 bg-white rounded-full w-7 h-7 flex items-center justify-center text-red-500 shadow-sm hover:bg-red-50 hover:scale-110 transition-all"
            @click="removeImage(i)"
          >
            <UIcon name="i-heroicons-trash" class="h-4 w-4" />
          </button>
          <div
            v-if="i === 0"
            class="absolute bottom-1.5 left-1.5 bg-emerald-500 text-white text-[10px] px-1.5 py-0.5 rounded font-medium"
          >
            {{ t("sale_form_main") }}
          </div>
        </div>
        <!-- Upload button -->
        <div
          class="w-28 h-28 rounded-lg relative border-2 border-dashed border-gray-300 bg-gray-50 hover:border-emerald-500 hover:bg-emerald-50/20 transition-colors flex items-center justify-center cursor-pointer group"
          v-if="formData.images.filter((img) => img).length < 8"
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
            class="flex flex-col items-center gap-1.5 text-gray-500 text-xs text-center p-2 group-hover:text-emerald-600 pointer-events-none"
          >
            <UIcon name="i-heroicons-arrow-up-tray" class="text-lg text-emerald-500" />
            <span>{{ t("sale_form_add_photo") }}</span>
          </div>
        </div>
      </div>

      <p v-if="uploadError" class="mt-3 text-red-500 text-sm">{{ uploadError }}</p>
      <p
        v-if="isUploading"
        class="mt-3 text-emerald-600 text-sm flex items-center gap-1"
      >
        <UIcon name="i-heroicons-arrow-path" class="animate-spin" />
        {{ t("sale_form_processing") }}
      </p>
    </section>

    <!-- Location Section -->
    <section class="p-4 sm:p-5 border-t border-slate-100">
      <div class="flex items-center gap-2 mb-3">
        <span class="h-7 w-7 rounded-lg bg-emerald-50 text-emerald-600 flex items-center justify-center">
          <UIcon name="i-heroicons-map-pin" class="h-4 w-4" />
        </span>
        <h3 class="text-sm font-bold text-slate-800">{{ t("sale_form_location") }}</h3>
      </div>

      <UCheckbox
        v-model="allOverBangladesh"
        name="all-bangladesh"
        :label="t('sale_form_all_bangladesh')"
        color="primary"
        class="mb-4"
      />

      <div
        class="grid grid-cols-1 md:grid-cols-3 gap-4"
        v-if="!allOverBangladesh"
      >
        <UFormGroup
          :label="t('sale_form_division')"
          :error="!formData.division && checkSubmit && !allOverBangladesh && t('sale_form_err_division')"
        >
          <USelectMenu
            v-model="formData.division"
            color="white"
            size="md"
            :options="regions"
            :placeholder="t('sale_form_select_division')"
            option-attribute="name_eng"
            value-attribute="name_eng"
          />
        </UFormGroup>

        <UFormGroup
          :label="t('sale_form_district')"
          :error="!formData.district && checkSubmit && !allOverBangladesh && t('sale_form_err_district')"
        >
          <USelectMenu
            v-model="formData.district"
            color="white"
            size="md"
            :options="cities"
            :placeholder="t('sale_form_select_district')"
            option-attribute="name_eng"
            value-attribute="name_eng"
            :disabled="!formData.division"
          />
        </UFormGroup>

        <UFormGroup
          :label="t('sale_form_area')"
          :error="!formData.area && checkSubmit && !allOverBangladesh && t('sale_form_err_area')"
        >
          <USelectMenu
            v-model="formData.area"
            color="white"
            size="md"
            :options="upazilas"
            :placeholder="t('sale_form_select_area')"
            option-attribute="name_eng"
            value-attribute="name_eng"
            :disabled="!formData.district"
          />
        </UFormGroup>
      </div>

      <UFormGroup
        :label="t('sale_form_detailed_address')"
        required
        class="mt-4"
        :error="!formData.detailedAddress && checkSubmit && t('sale_form_err_address')"
      >
        <UTextarea
          v-model="formData.detailedAddress"
          color="white"
          size="md"
          :rows="3"
          :placeholder="t('sale_form_detailed_address_ph')"
          class="resize-none"
        />
      </UFormGroup>
    </section>

    <!-- Contact Information Section -->
    <section class="p-4 sm:p-5 border-t border-slate-100">
      <div class="flex items-center gap-2 mb-3">
        <span class="h-7 w-7 rounded-lg bg-emerald-50 text-emerald-600 flex items-center justify-center">
          <UIcon name="i-heroicons-phone" class="h-4 w-4" />
        </span>
        <h3 class="text-sm font-bold text-slate-800">{{ t("sale_form_contact") }}</h3>
      </div>

      <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
        <UFormGroup
          :label="t('sale_form_phone')"
          required
          :error="!formData.phone && checkSubmit && t('sale_form_err_phone')"
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

        <UFormGroup :label="t('sale_form_email_optional')">
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
    </section>

    <!-- Terms + Submit -->
    <div
      class="p-4 sm:p-5 border-t border-slate-100 bg-slate-50/60 flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between"
    >
      <UCheckbox v-model="formData.termsAccepted" name="terms" color="primary" required>
        <template #label>
          <span class="text-sm text-gray-600">
            {{ t("sale_form_terms_pre") }}
            <NuxtLink to="/terms" target="_blank" class="text-emerald-600 hover:underline font-medium">{{ t("sale_form_terms_link") }}</NuxtLink>
            {{ t("sale_form_terms_and") }}
            <NuxtLink to="/privacy" target="_blank" class="text-emerald-600 hover:underline font-medium">{{ t("sale_form_privacy_link") }}</NuxtLink>
            {{ t("sale_form_terms_suf") }}<span class="text-red-500"> *</span>
          </span>
        </template>
      </UCheckbox>

      <UButton
        type="submit"
        :loading="isSubmitting"
        :disabled="isSubmitting"
        color="emerald"
        size="lg"
        class="px-8 justify-center shrink-0"
      >
        <template #leading>
          <UIcon v-if="!isSubmitting" name="i-heroicons-paper-airplane" />
        </template>
        {{ isSubmitting ? t("sale_form_submitting") : t("sale_form_submit") }}
      </UButton>
    </div>
  </form>
</template>

<script setup>
import { ref, reactive, computed, watch, onMounted } from "vue";
import Editor from "~/components/common/editor.vue";

const emit = defineEmits(["post-created"]);

const { get, post } = useApi();
const toast = useToast();
const { t } = useI18n();

// Loading and error states
const apiLoading = ref(false);
const apiError = ref(null);

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
        const response = await get(
          `/geo/cities/?region_name_eng=${newDivision}`
        );
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
        const response = await get(
          `/geo/upazila/?city_name_eng=${newDistrict}`
        );
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
      const emptyIndex = formData.images.findIndex((img) => !img);
      if (emptyIndex !== -1) {
        imagePreviewUrls.value[emptyIndex] = compressedImage;
        formData.images[emptyIndex] = compressedImage;
      } else {
        uploadError.value = "Maximum 8 images allowed";
      }
    }
  } catch (error) {
    console.error("Error uploading image:", error);
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
    category: formData.category,
    title: formData.title?.trim(),
    description:
      getTextLength(formData.description) > 0 ? formData.description : null,
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
      title: t("sale_form_validation_error"),
      description: t("sale_form_fill_required"),
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
      title: t("sale_form_validation_error"),
      description: t("sale_form_price_invalid"),
      color: "red",
      timeout: 5000,
    });
    return;
  }

  // Validate description length
  if (getTextLength(formData.description) > 1000) {
    toast.add({
      title: t("sale_form_validation_error"),
      description: t("sale_form_desc_too_long"),
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
      title: t("sale_form_validation_error"),
      description: t("sale_form_need_image"),
      color: "red",
      timeout: 5000,
    });
    return;
  }

  // Validate terms
  if (!formData.termsAccepted) {
    toast.add({
      title: t("sale_form_validation_error"),
      description: t("sale_form_accept_terms"),
      color: "red",
      timeout: 5000,
    });
    return;
  }
  try {
    // Log image information for debugging
    const imageSizes = validImages.map((img) => {
      const size = Math.round((img.length * 3) / 4);
      return formatFileSize(size);
    });

    // Prepare submission data following business network pattern
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

    // Create a new sale post
    const createSalePost = async (formData) => {
      apiLoading.value = true;
      apiError.value = null;

      try {
        const response = await post("/sale/posts/", formData);

        if (response.error) {
          throw response.error;
        }

        apiError.value = null;

        // Handle both detailed and simplified success responses
        if (response.data && (response.data.id || response.data.message)) {
          return response.data;
        }

        return response.data;
      } catch (err) {
        if (err.response) {
          // Check if it's actually a success with 400 status (our known issue)
          if (
            err.response.status === 400 &&
            err.response.data &&
            (err.response.data.id || err.response.data.message)
          ) {
            apiError.value = null;
            return err.response.data;
          }

          apiError.value =
            err.response.data || "Server error: " + err.response.status;
        } else if (err.request) {
          apiError.value =
            "No response from server. Please check your connection.";
        } else {
          apiError.value = err.message || "Failed to create sale post";
        }
        throw apiError.value;
      } finally {
        apiLoading.value = false;
      }
    };

    const result = await createSalePost(submissionData);

    // Emit success event
    emit("post-created", result);

    // Reset form
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
      title: t("sale_form_error_title"),
      description: errorMessage,
      color: "red",
      timeout: 8000,
    });
  }
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
</script>

<style scoped>
/* Custom focus styles */
.UInput:focus-within,
.UTextarea:focus-within,
.USelectMenu:focus-within {
  box-shadow: 0 0 0 3px rgba(16, 185, 129, 0.1);
}
</style>
