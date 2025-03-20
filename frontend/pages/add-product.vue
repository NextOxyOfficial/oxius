<template>
  <PublicSection>
    <UContainer>
      <div class="add-product-page">
        <!-- Page Header with Animation -->
        <div class="page-header relative overflow-hidden mb-6">
          <div
            class="flex flex-col md:flex-row md:items-center justify-between gap-4 py-2"
          >
            <div class="relative">
              <!-- Subtle animated underline -->
              <h1
                class="text-2xl sm:text-3xl font-bold text-slate-800 dark:text-white relative inline-block"
              >
                Add New Product
                <span
                  class="absolute bottom-0 left-0 w-full h-1 bg-gradient-to-r from-primary-400 to-primary-600 dark:from-primary-600 dark:to-primary-400 transform origin-left scale-x-0 animate-expand"
                ></span>
              </h1>
              <p class="text-slate-500 dark:text-slate-400 mt-1">
                Complete the form below to add a new product to your store
              </p>
            </div>

            <!-- Form Navigation -->
            <div class="flex flex-wrap items-center gap-3">
              <UButton
                color="gray"
                variant="ghost"
                to="/test"
                icon="i-heroicons-arrow-left"
                class="relative overflow-hidden group/back"
              >
                <span class="relative z-10">Back to Products</span>
                <div
                  class="absolute inset-0 w-full h-full bg-gradient-to-r from-transparent via-slate-100 dark:via-slate-700/30 to-transparent -translate-x-full group-hover/back:animate-shimmer"
                ></div>
              </UButton>
            </div>
          </div>
        </div>

        <!-- Form Container -->
        <div
          class="bg-white dark:bg-slate-800 rounded-xl shadow-md border border-slate-100 dark:border-slate-700/60 overflow-hidden"
        >
          <!-- Form Header with Progress Indicator -->
          <div
            class="relative overflow-hidden border-b border-slate-100 dark:border-slate-700/60"
          >
            <!-- Background Pattern -->
            <div
              class="absolute inset-0 bg-gradient-to-r from-primary-50 to-slate-50 dark:from-slate-800/50 dark:to-slate-900/50 opacity-70"
            ></div>

            <!-- Animated Lines -->
            <div class="absolute inset-0">
              <div
                class="absolute top-0 left-0 w-full h-px bg-gradient-to-r from-transparent via-primary-300/50 dark:via-primary-500/30 to-transparent transform translate-x-0 animate-line-scroll"
              ></div>
              <div
                class="absolute bottom-0 left-0 w-full h-px bg-gradient-to-r from-transparent via-primary-300/50 dark:via-primary-500/30 to-transparent transform translate-x-0 animate-line-scroll-reverse"
              ></div>
            </div>

            <!-- Form Steps -->
            <div
              class="relative z-10 flex items-center justify-between px-6 py-4"
            >
              <h2 class="text-lg font-medium text-slate-800 dark:text-white">
                Product Information
              </h2>
            </div>
          </div>

          <!-- Form Content -->
          <div class="p-6">
            <form
              @submit.prevent="submitForm"
              class="bg-white rounded-2xl shadow-lg max-w-3xl mx-auto overflow-hidden border border-gray-100"
            >
              <!-- Product Basic Info Section -->
              <div class="form-section">
                <h3
                  class="text-lg font-medium text-slate-800 dark:text-white mb-4 flex items-center"
                >
                  <UIcon
                    name="i-heroicons-information-circle"
                    class="w-5 h-5 mr-2 text-primary-500"
                  />
                  Basic Information
                </h3>

                <div class="">
                  <!-- Product Name -->
                  <UFormGroup
                    label="Product Name"
                    required
                    :error="
                      !form.name && checkSubmit && 'You must enter a name!'
                    "
                    class="mb-5"
                  >
                    <UInput
                      type="text"
                      size="md"
                      color="white"
                      class="w-full border-gray-200 focus:border-emerald-500 focus:ring focus:ring-emerald-100 transition-all"
                      placeholder="Enter Product Name"
                      v-model="form.name"
                    >
                      <template #leading>
                        <UIcon name="i-heroicons-pencil-square" />
                      </template>
                    </UInput>
                  </UFormGroup>

                  <!-- Product SKU -->
                </div>

                <!-- Categories & Tags -->
                <div class="">
                  <!-- Categories -->
                  <UFormGroup
                    label="Category"
                    required
                    :error="
                      !form.category &&
                      checkSubmit &&
                      'You must select a category'
                    "
                    class="mb-5"
                  >
                    <USelectMenu
                      v-model="form.category"
                      color="white"
                      size="md"
                      :options="categories"
                      placeholder="Select Category"
                      class="w-full border-gray-200 focus:border-emerald-500 focus:ring focus:ring-emerald-100 transition-all"
                      option-attribute="title"
                      value-attribute="id"
                    />
                  </UFormGroup>

                  <!-- Tags -->
                </div>
              </div>
              <!-- Product Details Section -->
              <div class="form-section">
                <h3
                  class="text-lg font-medium text-slate-800 dark:text-white mb-4 flex items-center"
                >
                  <UIcon
                    name="i-heroicons-document-text"
                    class="w-5 h-5 mr-2 text-primary-500"
                  />
                  Product Details
                </h3>

                <!-- Short Description -->
                <UFormGroup label="Description" required class="mb-5">
                  <p class="text-sm text-gray-500 mb-3">
                    Provide detailed information about your product.
                  </p>
                  <div
                    class="border border-gray-200 rounded-lg overflow-hidden focus-within:ring-2 focus-within:ring-emerald-100 focus-within:border-emerald-500 transition-all"
                  >
                    <CommonEditor
                      v-if="router.query.id && form.description"
                      :content="form.description"
                      @updateContent="
                        (content) => {
                          form.description = content;
                        }
                      "
                    />
                    <CommonEditor
                      v-else
                      v-model="form.description"
                      @updateContent="updateContent"
                    />
                  </div>
                </UFormGroup>

                <!-- Full Description -->
                <!-- <div class="form-group">
                  <label for="fullDescription" class="form-label"
                    >Full Description <span class="text-red-500">*</span></label
                  >
                  <div class="relative">
                    <textarea
                      id="fullDescription"
                      v-model="form.fullDescription"
                      rows="6"
                      class="form-input !pt-3 !pl-10"
                      placeholder="Detailed description of your product..."
                      required
                    ></textarea>
                    <div
                      class="absolute top-3 left-3 flex items-start pointer-events-none"
                    >
                      <UIcon
                        name="i-heroicons-document"
                        class="w-5 h-5 text-slate-400"
                      />
                    </div>
                  </div>
                  <div class="form-hint">
                    Detailed product information, features, and specifications
                  </div>
                </div> -->
              </div>
              <!-- Product Media Section - FIXED STRUCTURE -->
              <div class="form-section">
                <h3
                  class="text-lg font-medium text-slate-800 dark:text-white mb-4 flex items-center"
                >
                  <UIcon
                    name="i-heroicons-photo"
                    class="w-5 h-5 mr-2 text-primary-500"
                  />
                  Media Gallery
                </h3>

                <p class="text-sm text-slate-500 dark:text-slate-400 mb-4">
                  Add photos or videos to showcase your product (upload up to 5
                  images)
                </p>

                <div class="flex flex-wrap gap-4 mt-4">
                  <!-- Uploaded images -->
                  <div
                    v-for="(img, i) in form.images"
                    :key="i"
                    class="w-32 h-32 rounded-lg overflow-hidden relative border border-gray-200 bg-gray-50 group"
                  >
                    <img
                      v-if="img.image"
                      :src="img.image"
                      :alt="`Uploaded file ${i}`"
                      class="w-full h-full object-cover transition-transform group-hover:scale-105"
                    />
                    <img
                      v-else
                      :src="img"
                      :alt="`Uploaded file ${i}`"
                      class="w-full h-full object-cover transition-transform group-hover:scale-105"
                    />
                    <div
                      class="absolute inset-0 bg-black bg-opacity-0 group-hover:bg-opacity-30 transition-all"
                    ></div>
                    <button
                      type="button"
                      class="absolute top-2 right-2 bg-white rounded-full w-8 h-8 flex items-center justify-center text-red-500 shadow-md hover:bg-red-50 hover:scale-110 transition-all"
                      @click="deleteUpload(i)"
                      aria-label="Delete image"
                    >
                      <UIcon name="i-heroicons-trash" />
                    </button>
                  </div>

                  <!-- Upload button -->
                  <div
                    class="w-32 h-32 rounded-lg relative border-2 border-dashed border-gray-300 bg-gray-50 hover:border-emerald-500 hover:bg-emerald-50/20 transition-colors flex items-center justify-center cursor-pointer group"
                    v-if="form.images.length < 5"
                  >
                    <input
                      type="file"
                      ref="fileInput"
                      class="absolute inset-0 w-full h-full opacity-0 cursor-pointer z-10"
                      @change="handleFileUpload"
                      accept="image/*"
                    />
                    <div
                      class="flex flex-col items-center gap-2 text-gray-500 text-sm text-center p-2 group-hover:text-emerald-600"
                    >
                      <UIcon
                        name="i-heroicons-arrow-up-tray"
                        class="text-2xl text-emerald-500"
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
                  <UIcon
                    name="i-heroicons-arrow-path"
                    class="animate-spin mr-1"
                  />
                  Uploading image...
                </p>
              </div>

              <!-- Product Pricing Section -->
              <div class="form-section">
                <h3
                  class="text-lg font-medium text-slate-800 dark:text-white mb-4 flex items-center"
                >
                  <UIcon
                    name="i-heroicons-currency-bangladeshi"
                    class="w-5 h-5 mr-2 text-primary-500"
                  />
                  Pricing & Inventory
                </h3>

                <div class="grid grid-cols-1 md:grid-cols-3 gap-6">
                  <!-- Regular Price -->
                  <div class="form-group">
                    <label for="regularPrice" class="form-label"
                      >Regular Price <span class="text-red-500">*</span></label
                    >
                    <div class="relative">
                      <input
                        id="regularPrice"
                        v-model="form.regularPrice"
                        type="number"
                        min="0"
                        step="0.01"
                        class="form-input pl-10"
                        placeholder="0.00"
                        required
                      />
                      <div
                        class="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none"
                      >
                        <span class="text-slate-500">৳</span>
                      </div>
                    </div>
                  </div>

                  <!-- Discounted Price -->
                  <div class="form-group">
                    <label for="salePrice" class="form-label"
                      >Discounted Price</label
                    >
                    <div class="relative">
                      <input
                        id="salePrice"
                        v-model="form.salePrice"
                        type="number"
                        min="0"
                        step="0.01"
                        class="form-input pl-10"
                        placeholder="Enter discounted price"
                      />
                      <div
                        class="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none"
                      >
                        <span class="text-slate-500">৳</span>
                      </div>
                    </div>
                    <div class="form-hint">Leave empty if not on discount</div>
                  </div>

                  <!-- Stock Quantity -->
                  <div class="form-group">
                    <label for="stockQuantity" class="form-label"
                      >Stock Quantity <span class="text-red-500">*</span></label
                    >
                    <div class="relative">
                      <input
                        id="stockQuantity"
                        v-model="form.stock"
                        type="number"
                        min="0"
                        step="1"
                        class="form-input pl-10"
                        placeholder="Enter stock quantity"
                        required
                      />
                      <div
                        class="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none"
                      >
                        <UIcon
                          name="i-heroicons-cube"
                          class="w-5 h-5 text-slate-400"
                        />
                      </div>
                    </div>
                  </div>
                </div>
              </div>

              <!-- NEW: Delivery Information Section -->
              <div class="form-section">
                <h3
                  class="text-lg font-medium text-slate-800 dark:text-white mb-4 flex items-center"
                >
                  <UIcon
                    name="i-heroicons-truck"
                    class="w-5 h-5 mr-2 text-primary-500"
                  />
                  Delivery Information
                </h3>

                <div class="">
                  <!-- Weight -->
                  <div class="form-group">
                    <label for="productWeight" class="form-label"
                      >Weight (kg)</label
                    >
                    <div class="relative">
                      <input
                        id="productWeight"
                        v-model="form.weight"
                        type="number"
                        min="0"
                        step="0.01"
                        class="form-input pl-10"
                        placeholder="0.00"
                      />
                      <div
                        class="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none"
                      >
                        <UIcon
                          name="i-heroicons-scale"
                          class="w-5 h-5 text-slate-400"
                        />
                      </div>
                    </div>
                    <div class="form-hint">
                      Product weight for shipping calculation
                    </div>
                  </div>

                  <!-- Dimensions -->
                  <!-- <div class="form-group">
                    <label for="productDimensions" class="form-label"
                      >Dimensions (L × W × H)</label
                    >
                    <div class="grid grid-cols-3 gap-2">
                      <div class="relative">
                        <input
                          v-model="form.length"
                          type="number"
                          min="0"
                          step="0.1"
                          class="form-input"
                          placeholder="Length"
                        />
                      </div>
                      <div class="relative">
                        <input
                          v-model="form.width"
                          type="number"
                          min="0"
                          step="0.1"
                          class="form-input"
                          placeholder="Width"
                        />
                      </div>
                      <div class="relative">
                        <input
                          v-model="form.height"
                          type="number"
                          min="0"
                          step="0.1"
                          class="form-input"
                          placeholder="Height"
                        />
                      </div>
                    </div>
                    <div class="form-hint">
                      Product dimensions in centimeters
                    </div>
                  </div> -->
                </div>

                <!-- Delivery Options -->

                <!-- Shipping Notes -->
                <div class="mt-6">
                  <label for="shippingNotes" class="form-label"
                    >Delivery Information</label
                  >
                  <textarea
                    id="shippingNotes"
                    v-model="form.shippingNotes"
                    rows="3"
                    class="w-full px-4 py-2.5 rounded-lg border border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-800 text-slate-800 dark:text-slate-200 placeholder-slate-400 dark:placeholder-slate-500 focus:outline-none focus:ring-2 focus:ring-primary-500/30 focus:border-primary-500 transition-all duration-200"
                    placeholder="Add any special shipping or handling instructions..."
                  ></textarea>
                  <div class="form-hint">
                    Special instructions for shipping and handling
                  </div>
                </div>
              </div>

              <!-- Form Actions -->
              <div
                class="flex flex-col sm:flex-row items-center justify-end gap-4 p-8 border-t border-slate-200 dark:border-slate-700/60"
              >
                <UButton
                  color="gray"
                  variant="ghost"
                  class="w-full sm:w-auto"
                  @click="resetForm"
                >
                  Reset Form
                </UButton>

                <UButton
                  color="gray"
                  variant="soft"
                  class="w-full sm:w-auto"
                  @click="saveAsDraft"
                >
                  <span class="flex items-center gap-1.5">
                    <UIcon name="i-heroicons-document" class="w-4 h-4" />
                    <span>Save as Draft</span>
                  </span>
                </UButton>

                <UButton
                  type="submit"
                  color="primary"
                  class="w-full sm:w-auto submit-btn group relative overflow-hidden"
                  :loading="isSubmitting"
                >
                  <span class="flex items-center gap-1.5 relative z-10">
                    <UIcon name="i-heroicons-check" class="w-4 h-4" />
                    <span>Publish Product</span>
                  </span>

                  <!-- Shine effect on hover -->
                  <div
                    class="absolute inset-0 w-full h-full bg-gradient-to-r from-transparent via-white/20 dark:via-white/10 to-transparent -translate-x-full group-hover:animate-shimmer"
                  ></div>
                </UButton>
              </div>
            </form>
          </div>
        </div>
      </div>
    </UContainer>

    <!-- Success Modal Component -->
    <UModal v-model="isSuccessModalOpen">
      <div class="p-6 flex flex-col items-center">
        <div
          class="w-16 h-16 rounded-full bg-primary-100 dark:bg-primary-900/30 flex items-center justify-center mb-4 animate-[success-pulse_1s_infinite]"
        >
          <UIcon
            name="i-heroicons-check"
            class="w-8 h-8 text-primary-500 dark:text-primary-400"
          />
        </div>
        <h3 class="text-xl font-medium text-slate-800 dark:text-white mb-2">
          Success!
        </h3>
        <p class="text-slate-600 dark:text-slate-300 text-center mb-6">
          {{ successMessage }}
        </p>
        <UButton color="primary" @click="isSuccessModalOpen = false">
          Close
        </UButton>
      </div>
    </UModal>
  </PublicSection>
</template>

<script setup>
definePageMeta({
  layout: "dashboard",
});

const router = useRoute();
function updateContent(p) {
  form.value.description = p;
}
// Form state
const form = ref({
  name: "",
  sku: "",
  category: "",
  tags: [],
  featuredImage: "",
  images: [],
  regularPrice: null,
  salePrice: null,
  stock: null,
  shortDescription: "",
  fullDescription: "",
  status: "active",
  isFeatured: false,
  allowReviews: true,
  trackInventory: true,
  // New delivery fields
  weight: null,
  length: null,
  width: null,
  height: null,
  freeShipping: false,
  expressDelivery: false,
  shippingNotes: "",
});

// Loading state
const isSubmitting = ref(false);
const isSuccessModalOpen = ref(false);
const successMessage = ref("");

// Sample data
const categories = [
  { label: "Electronics", value: "electronics" },
  { label: "Clothing", value: "clothing" },
  { label: "Home & Kitchen", value: "home-kitchen" },
  { label: "Beauty", value: "beauty" },
  { label: "Sports", value: "sports" },
];

function handleFileUpload(event, field) {
  const files = Array.from(event.target.files);
  const reader = new FileReader();

  // Event listener for successful read
  reader.onload = () => {
    form.value.medias.push(reader.result);
  };

  // Event listener for errors
  reader.onerror = (error) => reject(error);

  // Read the file as a data URL (Base64 string)
  reader.readAsDataURL(files[0]);
}

function deleteUpload(ind) {
  if (ind >= 0 && ind < form.value.medias.length) {
    // Create a new array without the deleted item to maintain reactivity
    form.value.medias = form.value.medias.filter((_, i) => i !== ind);
    uploadError.value = ""; // Clear any error messages
  }
}

function submitForm() {
  isSubmitting.value = true;

  // Simulate form submission with validation
  setTimeout(() => {
    isSubmitting.value = false;
    // Show success notification and redirect
    successMessage.value = "Product published successfully!";
    isSuccessModalOpen.value = true;

    // Simulate redirect after success
    setTimeout(() => {
      isSuccessModalOpen.value = false;
      // In a real app, you might redirect here
    }, 3000);
  }, 1500);
}

function saveAsDraft() {
  form.value.status = "draft";
  isSubmitting.value = true;

  // Simulate saving draft
  setTimeout(() => {
    isSubmitting.value = false;
    // Show success notification
    successMessage.value = "Draft saved successfully!";
    isSuccessModalOpen.value = true;

    // Auto-close notification
    setTimeout(() => {
      isSuccessModalOpen.value = false;
    }, 3000);
  }, 800);
}

function resetForm() {
  if (
    confirm(
      "Are you sure you want to reset the form? All changes will be lost."
    )
  ) {
    form.value = {
      name: "",
      sku: "",
      category: "",
      tags: [],
      featuredImage: "",
      gallery: [],
      regularPrice: null,
      salePrice: null,
      stock: null,
      shortDescription: "",
      fullDescription: "",
      status: "active",
      isFeatured: false,
      allowReviews: true,
      trackInventory: true,
      weight: null,
      length: null,
      width: null,
      height: null,
      freeShipping: false,
      expressDelivery: false,
      shippingNotes: "",
    };
  }
}
</script>

<style scoped>
/* Form Element Styling */
.form-section {
  @apply bg-white px-6 py-3;
}

.form-label {
  @apply block text-sm font-medium text-slate-700 dark:text-slate-300 mb-2;
}

.form-input {
  @apply w-full pl-10 pr-4 py-2 rounded-lg border border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-800 text-slate-800 dark:text-slate-200 
  placeholder-slate-400 dark:placeholder-slate-500 focus:outline-none focus:ring-2 focus:ring-primary-500/30 focus:border-primary-500 transition-all duration-200;
}

.form-select {
  @apply w-full px-4 py-2.5 rounded-lg border border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-800 text-slate-800 dark:text-slate-200;
}

.form-hint {
  @apply mt-1.5 text-xs text-slate-500 dark:text-slate-400;
}

.form-group {
  @apply relative;
}

/* Animations */
@keyframes shimmer {
  100% {
    transform: translateX(100%);
  }
}

.group-hover\:animate-shimmer {
  animation: shimmer 1.5s ease;
}

@keyframes expand {
  0% {
    transform: scaleX(0);
  }
  100% {
    transform: scaleX(1);
  }
}

.animate-expand {
  animation: expand 1s ease-out forwards;
}

@keyframes line-scroll {
  0% {
    transform: translateX(-100%);
  }
  100% {
    transform: translateX(100%);
  }
}

@keyframes line-scroll-reverse {
  0% {
    transform: translateX(100%);
  }
  100% {
    transform: translateX(-100%);
  }
}

.animate-line-scroll {
  animation: line-scroll 8s infinite linear;
}

.animate-line-scroll-reverse {
  animation: line-scroll-reverse 8s infinite linear;
}

@keyframes form-field-pulse {
  0%,
  100% {
    box-shadow: 0 0 0 0 rgba(79, 70, 229, 0.2);
    border-color: rgba(79, 70, 229, 0.4);
  }
  50% {
    box-shadow: 0 0 0 4px rgba(79, 70, 229, 0.2);
    border-color: rgba(79, 70, 229, 0.8);
  }
}

.animate-form-field-pulse {
  animation: form-field-pulse 1s ease;
}

/* Image Upload Effects */
.image-upload-area {
  transition: all 0.3s cubic-bezier(0.21, 0.61, 0.35, 1);
}

.image-upload-area:hover {
  border-color: #3b82f6; /* Replace with a valid color code or a theme color */
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.05);
}

/* Form Section hover effects */
.form-section {
  transition: all 0.3s ease;
}

.form-section:hover {
  box-shadow: 0 4px 15px rgba(0, 0, 0, 0.03);
}

/* Success animation */
@keyframes success-pulse {
  0%,
  100% {
    transform: scale(1);
  }
  50% {
    transform: scale(1.05);
  }
}
</style>
