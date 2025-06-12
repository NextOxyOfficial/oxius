<template>
  <div class="min-h-screen py-8 bg-gradient-to-b from-gray-50 to-gray-100">
    <UContainer>
      <!-- Enhanced Header -->
      <div class="text-center mb-10">        <h1
          class="text-2xl font-semibold mb-2 bg-gradient-to-r from-emerald-500 to-green-600 bg-clip-text text-transparent"
        >
          Add Product
        </h1>
        <p class="text-lg text-gray-600 max-w-lg mx-auto">
          List your product and reach more customers
        </p>
      </div>
        <form
        @submit.prevent="handleAddProduct"
        class="bg-white rounded-xl shadow-sm max-w-3xl mx-auto overflow-hidden border border-gray-100"
      >
        <!-- Form Sections Container -->
        <div>
          <!-- Product Basic Info Section -->
          <div
            class="p-3 border-b border-gray-100 hover:bg-gray-50 transition-colors duration-300"
          >
            <h2
              class="text-xl font-semibold text-gray-800 mb-6 flex items-center gap-2"
            >
              <UIcon
                name="i-heroicons-information-circle"
                class="text-emerald-600"              />
              Basic Information
            </h2>

            <UFormGroup
              label="Product Name"
              required
              :error="
                !form.name && checkSubmit && 'You must enter a product name'
              "
              class="mb-5"
            >
              <UInput
                type="text"
                size="md"
                color="white"
                class="w-full border-gray-200 focus:border-emerald-500 focus:ring focus:ring-emerald-100 transition-all"
                placeholder="Enter a descriptive name for your product"
                v-model="form.name"
              >
                <template #leading>
                  <UIcon name="i-heroicons-pencil-square" />
                </template>              </UInput>
            </UFormGroup>

            <UFormGroup
              label="Category"
              required
              :error="
                !form.category && checkSubmit && 'You must select a category'
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
                option-attribute="name"
                value-attribute="id"
                multiple
              >
                <template #leading>
                  <UIcon name="i-heroicons-squares-2x2" />
                </template>              </USelectMenu>
            </UFormGroup>
          </div>

          <!-- Product Details Section -->
          <div
            class="p-2 md:p-7 border-b border-gray-100 hover:bg-gray-50 transition-colors duration-300"
          >
            <h2
              class="text-xl font-semibold text-gray-800 mb-6 flex items-center gap-2"
            >
              <UIcon name="i-heroicons-document-text" class="text-emerald-600" />
              Product Details
            </h2>

            <UFormGroup label="Description" required class="mb-5">
              <p class="text-sm text-gray-600 mb-3">
                Provide detailed information about your product
              </p>              <div
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
                  class="text-left"
                />
                <CommonEditor
                  v-else
                  v-model="form.description"
                  @updateContent="updateContent"
                  class="text-left px-2"
                />
              </div>
            </UFormGroup>

            <UFormGroup label="Short Description" class="mb-5">
              <UTextarea
                v-model="form.short_description"
                color="white"
                variant="outline"
                class="w-full min-h-20 border-gray-200 focus:border-emerald-500 focus:ring focus:ring-emerald-100 transition-all"
                resize
                placeholder="A brief overview that appears in product listings (150 characters max)"
              />            </UFormGroup>
          </div>

          <!-- Product Media Section -->
          <div
            class="p-2 md:p-7 border-b border-gray-100 hover:bg-gray-50 transition-colors duration-300"
          >
            <h2
              class="text-xl font-semibold text-gray-800 mb-6 flex items-center gap-2"
            >
              <UIcon name="i-heroicons-photo" class="text-emerald-600" />
              Media Gallery
            </h2>
            <p class="text-sm text-gray-600 mb-4">
              Add photos to showcase your product (up to 5 images)
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
                  class="w-full h-full object-contain transition-transform group-hover:scale-105"
                />
                <img
                  v-else
                  :src="img"
                  :alt="`Uploaded file ${i}`"
                  class="w-full h-full object-contain transition-transform group-hover:scale-105"
                />
                <div
                  class="absolute inset-0 bg-black bg-opacity-0 group-hover:bg-opacity-30 transition-all"
                ></div>
                <button
                  type="button"
                  class="absolute top-2 right-2 bg-white rounded-full w-8 h-8 flex items-center justify-center text-red-500 shadow-sm hover:bg-red-50 hover:scale-110 transition-all"
                  @click="deleteUpload(i)"
                  aria-label="Delete image"
                >
                  <UIcon name="i-heroicons-trash" />
                </button>
              </div>

              <!-- Upload button -->
              <div
                class="w-32 h-32 rounded-lg relative border-2 border-dashed border-gray-300 bg-gray-50 hover:border-emerald-500 hover:bg-emerald-50/20 transition-colors flex items-center justify-center cursor-pointer group"
                v-if="!form.images || form.images.length < 5"
              >
                <input
                  type="file"
                  ref="fileInput"
                  class="absolute inset-0 w-full h-full opacity-0 cursor-pointer z-10"
                  @change="handleFileUpload"
                  accept="image/*"
                />
                <div
                  class="flex flex-col items-center gap-2 text-gray-600 text-sm text-center p-2 group-hover:text-emerald-600"
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
              Uploading image...            </p>
          </div>

          <!-- Product Pricing Section -->
          <div
            class="p-2 md:p-7 border-b border-gray-100 hover:bg-gray-50 transition-colors duration-300"
          >
            <h2
              class="text-xl font-semibold text-gray-800 mb-6 flex items-center gap-2"
            >
              <UIcon
                name="i-heroicons-currency-dollar"
                class="text-emerald-600"
              />
              Pricing & Inventory
            </h2>

            <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-6">
              <UFormGroup
                label="Regular Price"
                required
                :error="
                  !form.regular_price && checkSubmit && 'Regular price is required'
                "
                class="mb-5"
              >
                <UInput
                  type="number"
                  size="md"
                  color="white"
                  placeholder="e.g. 1000"
                  class="w-full border-gray-200 focus:border-emerald-500 focus:ring focus:ring-emerald-100 transition-all"
                  v-model="form.regular_price"
                  min="0"
                  step="0.01"
                >
                  <template #leading>
                    <UIcon name="i-mdi:currency-bdt" />
                  </template>
                </UInput>
              </UFormGroup>

              <UFormGroup label="Discounted Price" class="mb-5">
                <UInput
                  type="number"
                  size="md"
                  color="white"
                  placeholder="e.g. 800"
                  class="w-full border-gray-200 focus:border-emerald-500 focus:ring focus:ring-emerald-100 transition-all"
                  v-model="form.sale_price"
                  min="0"
                  step="0.01"
                >
                  <template #leading>
                    <UIcon name="i-mdi:currency-bdt" />
                  </template>
                </UInput>
              </UFormGroup>

              <UFormGroup
                label="Stock Quantity"
                required
                :error="
                  !form.quantity && checkSubmit && 'Stock quantity is required'
                "
                class="mb-5"
              >
                <UInput
                  type="number"
                  size="md"
                  color="white"
                  placeholder="e.g. 50"
                  class="w-full border-gray-200 focus:border-emerald-500 focus:ring focus:ring-emerald-100 transition-all"
                  v-model="form.quantity"
                  min="0"
                  step="1"
                >
                  <template #leading>
                    <UIcon name="i-heroicons-cube" />
                  </template>
                </UInput>              </UFormGroup>
            </div>
          </div>

          <!-- Delivery Information Section -->
          <div
            class="p-2 md:p-7 border-b border-gray-100 hover:bg-gray-50 transition-colors duration-300"
          >
            <h2
              class="text-xl font-semibold text-gray-800 mb-6 flex items-center gap-2"
            >
              <UIcon name="i-heroicons-truck" class="text-emerald-600" />
              Delivery Information
            </h2>

            <UFormGroup label="Weight (kg)" class="mb-5">
              <UInput
                type="number"
                size="md"
                color="white"
                placeholder="e.g. 1.5"
                class="w-full border-gray-200 focus:border-emerald-500 focus:ring focus:ring-emerald-100 transition-all"
                v-model="form.weight"
                min="0"
                step="0.01"
              >
                <template #leading>
                  <UIcon name="i-heroicons-scale" />
                </template>
              </UInput>
            </UFormGroup>

            <UFormGroup
              label="Delivery Method"
              required
              :error="
                !form.deliveryMethod && checkSubmit && 'Please select a delivery method'
              "
              class="mb-5"
            >              <div class="space-y-3">
                <div class="flex items-center">
                  <URadio
                    v-model="form.deliveryMethod"
                    value="free"
                    name="delivery"
                    label="Free Delivery All Over Bangladesh"
                    color="emerald"
                  />
                </div>
                <div class="flex items-center">
                  <URadio
                    v-model="form.deliveryMethod"
                    value="standard"
                    name="delivery"
                    label="Standard Shipping (Location Based)"
                    color="emerald"
                  />
                </div>
              </div>

              <div
                v-if="form.deliveryMethod === 'standard'"
                class="mt-4 grid grid-cols-1 sm:grid-cols-2 gap-4"
              >
                <UFormGroup label="Inside Dhaka Rate">
                  <UInput
                    type="number"
                    size="md"
                    color="white"
                    placeholder="e.g. 100"
                    class="w-full border-gray-200 focus:border-emerald-500 focus:ring focus:ring-emerald-100 transition-all"
                    v-model="form.delivery_fee_inside_dhaka"
                    min="0"
                  >
                    <template #leading>
                      <UIcon name="i-mdi:currency-bdt" />
                    </template>
                  </UInput>
                </UFormGroup>

                <UFormGroup label="Outside Dhaka Rate">
                  <UInput
                    type="number"
                    size="md"
                    color="white"
                    placeholder="e.g. 150"
                    class="w-full border-gray-200 focus:border-emerald-500 focus:ring focus:ring-emerald-100 transition-all"
                    v-model="form.delivery_fee_outside_dhaka"
                    min="0"
                  >
                    <template #leading>
                      <UIcon name="i-mdi:currency-bdt" />
                    </template>
                  </UInput>
                </UFormGroup>
              </div>
            </UFormGroup>
          </div>          <UCard class="mx-2 sm:mx-6">
            <UCheckbox
              name="notifications"
              v-model="advanceEditMode"
              label="Apply Custom Landing Page For This Product"
              class="mb-2"
            />
            <CommonAdvanceProductEditor
              :currentProduct="form"
              v-if="advanceEditMode"
              @update:content="handleEditorUpdate"
            />
          </UCard>

          <!-- Form Submit Section -->
          <div class="p-6">
            <div class="flex flex-col sm:flex-row gap-4 justify-between">
              <UButton
                color="gray"
                variant="outline"
                @click="resetForm"
                class="flex-shrink-0"
              >
                <UIcon name="i-heroicons-arrow-path" class="mr-2" />
                Reset Form
              </UButton>

              <UButton
                type="submit"
                color="primary"
                size="lg"
                :loading="isSubmitting"
                class="bg-emerald-600 hover:bg-emerald-700 focus:ring-emerald-100"
              >
                <UIcon name="i-heroicons-plus-circle" class="mr-2" />
                {{ router.query.id ? 'Update Product' : 'Add Product' }}
              </UButton>
            </div>
          </div>
        </div>
      </form>
    </UContainer>
  </div>
</template>

<script setup>
const props = defineProps({
  product: Object,
});
const { get, post, put } = useApi();
const router = useRoute();
const toast = useToast();
const currentStep = ref(0); // Track current step for highlighting
const categories = ref([]);
// Simplified form with only essential fields
const form = ref(
  props.product || {
    name: "",
    category: [],
    description: "",
    short_description: "",
    images: [],
    discount_price: null,
    sale_price: null,
    regular_price: null,
    quantity: null,
    weight: null,
    deliveryMethod: "",
    is_free_delivery: false,
    delivery_fee_free: 0,
    delivery_fee_inside_dhaka: 0,
    delivery_fee_outside_dhaka: 0,
  }
);

// Loading state
const isSubmitting = ref(false);
const isSuccessModalOpen = ref(false);
const successMessage = ref("");
const uploadError = ref("");
const isUploading = ref(false);
const checkSubmit = ref(false);
const advanceEditMode = ref(false);
const productEditorData = ref(null);

// Function to log advanced editor updates
function handleEditorUpdate(editorData) {
  console.group("Advanced Editor Data Update");
  console.log("Received editor data in parent component:", editorData);

  // Log individual sections for better visibility
  console.log("Header texts:", {
    benefitsTitle: editorData.benefitsTitle,
    benefitsCta: editorData.benefitsCta,
    faqsTitle: editorData.faqsTitle,
    faqsSubtitle: editorData.faqsSubtitle,
    ctaTitle: editorData.ctaTitle,
    ctaSubtitle: editorData.ctaSubtitle,
    ctaButtonText: editorData.ctaButtonText,
    ctaButtonSubtext: editorData.ctaButtonSubtext,
  });

  console.log("Benefits:", editorData.benefits);
  console.log("FAQs:", editorData.faqs);
  console.log("Trust badges:", editorData.trustBadges);

  // Store the editor data in the form
  if (editorData) {
    const previousData = form.value.editorData;
    form.value.editorData = editorData;

    // Compare with previous data if available
    if (previousData) {
      console.log("Changes from previous data:", {
        headersChanged:
          JSON.stringify(previousData.benefitsTitle) !==
            JSON.stringify(editorData.benefitsTitle) ||
          JSON.stringify(previousData.faqsTitle) !==
            JSON.stringify(editorData.faqsTitle) ||
          JSON.stringify(previousData.ctaTitle) !==
            JSON.stringify(editorData.ctaTitle),
        benefitsChanged:
          JSON.stringify(previousData.benefits) !==
          JSON.stringify(editorData.benefits),
        faqsChanged:
          JSON.stringify(previousData.faqs) !== JSON.stringify(editorData.faqs),
        trustBadgesChanged:
          JSON.stringify(previousData.trustBadges) !==
          JSON.stringify(editorData.trustBadges),
      });
    }

    // Add timestamp to track when changes occurred
    const now = new Date();
    console.log("Update timestamp:", now.toISOString());

    // Log the full updated form
    console.log("Updated form with editor data:", form.value);

    // Update the reference for display in the template
    productEditorData.value = editorData;

    // Show confirmation toast
    toast.add({
      title: "Editor Content Updated",
      description: `Advanced editor changes saved at ${now.toLocaleTimeString()}`,
      color: "green",
      timeout: 3000,
    });
  }
  console.groupEnd();
}

// Handle product submission with proper delivery fee processing
async function handleAddProduct() {
  // Start logging group
  console.group("Product Submission");
  console.log("Form data before submission:", form.value);

  if (form.value.editorData) {
    console.log(
      "Advanced editor data included in submission:",
      form.value.editorData
    );
  } else {
    console.log("No advanced editor data in submission");
  }

  checkSubmit.value = true;

  // Validate required fields
  if (
    !form.value.name ||
    !form.value.category ||
    !form.value.regular_price ||
    !form.value.quantity ||
    !form.value.deliveryMethod
  ) {
    toast.add({
      title: "Missing Required Fields",
      description: "Please fill in all required fields",
      color: "red",
    });
    console.log("Form validation failed - missing required fields");
    console.groupEnd();
    return;
  }

  // Check product limit before submission (only for new products)
  if (!props.product?.id) {
    try {
      const { data: userProducts } = await get("/my-products/");
      const currentProductCount = userProducts ? userProducts.length : 0;
      const productLimit = user.value?.user?.product_limit || 10;

      if (currentProductCount >= productLimit) {
        toast.add({
          title: "Product Limit Reached",
          description: `You have reached your product limit of ${productLimit}. Delete an existing product or purchase additional product slots to add new products.`,
          color: "red",
          timeout: 8000,
        });
        console.log("Form validation failed - product limit reached");
        console.groupEnd();
        return;
      }

      // Show warning if approaching limit
      if (currentProductCount >= productLimit - 2) {
        const remainingSlots = productLimit - currentProductCount;
        toast.add({
          title: "Approaching Product Limit",
          description: `You can add ${remainingSlots} more product(s) before reaching your limit of ${productLimit}.`,
          color: "amber",
          timeout: 6000,
        });
      }
    } catch (error) {
      console.error("Error checking product limit:", error);
      // Continue with submission even if limit check fails
    }
  }

  isSubmitting.value = true;

  try {
    // Create API submission object from form data
    const productData = {
      ...form.value,
      ...form.value.editorData,
      is_advanced: advanceEditMode.value,
    };
    console.log("Product data for API submission:", productData);

    // Set is_free_delivery based on delivery method selection
    if (form.value.deliveryMethod === "free") {
      productData.is_free_delivery = true;
      productData.delivery_fee_inside_dhaka = 0;
      productData.delivery_fee_outside_dhaka = 0;
    } else {
      productData.is_free_delivery = false;
      // Keep the user-entered delivery fee values
    }

    // Clean up temporary form fields before submission
    delete productData.deliveryMethod;

    console.log("Sending product data to API:", productData);

    // Check if we are updating or creating a product
    let res;
    if (props.product?.id) {
      // Update existing product
      res = await put(`/products/${props.product.slug}/`, productData);
      successMessage.value = "Your product has been updated successfully!";
    } else {
      // Create new product
      res = await post("/products/", productData);
      successMessage.value = "Your product has been published successfully!";
    }

    if (res.data) {
      console.log("API response:", res.data);
      toast.add({
        title: "Success",
        description: successMessage.value,
        color: "green",
      });
      isSuccessModalOpen.value = true;

      // Reset form after successful submission (only for new products)
      if (!props.product?.id) {
        resetForm(false);
        checkSubmit.value = false;
        currentStep.value = 1;
      }
    }
  } catch (error) {
    console.error("Product submission error details:", error);
    toast.add({
      title: "Error",
      description:
        error?.message || "Failed to save product. Please try again.",
      color: "red",
    });
  } finally {
    isSubmitting.value = false;
    console.groupEnd();
  }
}

async function getCategories() {
  const { data } = await get("/product-categories/");
  categories.value = data;
}

await getCategories();

// Add these improved functions to your script setup section

// Enhanced file upload handling with better error handling and file input reset
function handleFileUpload(event) {
  isUploading.value = true;
  uploadError.value = "";

  try {
    const files = Array.from(event.target.files);

    if (!files || files.length === 0) {
      uploadError.value = "No file selected";
      isUploading.value = false;
      return;
    }

    const file = files[0];

    if (!file.type.startsWith("image/")) {
      uploadError.value = "Please select a valid image file";
      isUploading.value = false;
      return;
    }

    if (file.size > 12 * 1024 * 1024) {
      uploadError.value = "Image size must be less than 12MB";
      isUploading.value = false;
      return;
    }

    if (!form.value.images) {
      form.value.images = [];
    }

    if (form.value.images.length >= 5) {
      uploadError.value = "Maximum 5 images allowed";
      isUploading.value = false;
      return;
    }

    const reader = new FileReader();

    reader.onload = (e) => {
      const img = new Image();
      img.onload = () => {
        const canvas = document.createElement("canvas");
        let width = img.width;
        let height = img.height;

        // Resize while maintaining aspect ratio
        const maxSize = 1000;
        if (width > maxSize || height > maxSize) {
          if (width > height) {
            height = height * (maxSize / width);
            width = maxSize;
          } else {
            width = width * (maxSize / height);
            height = maxSize;
          }
        }

        canvas.width = width;
        canvas.height = height;

        const ctx = canvas.getContext("2d");
        ctx.drawImage(img, 0, 0, width, height);

        const compressedDataUrl = canvas.toDataURL("image/jpeg", 0.8); // 80% quality

        form.value.images.push(compressedDataUrl);
        isUploading.value = false;

        if (event.target) {
          event.target.value = null;
        }
      };

      img.onerror = () => {
        uploadError.value = "Invalid image. Please try again.";
        isUploading.value = false;
      };

      img.src = e.target.result;
    };

    reader.onerror = (error) => {
      console.error("FileReader error:", error);
      uploadError.value = "Error uploading image. Please try again.";
      isUploading.value = false;
    };

    reader.readAsDataURL(file);
  } catch (error) {
    console.error("File upload error:", error);
    uploadError.value = "Unexpected error occurred during upload";
    isUploading.value = false;
  }
}

// More robust image deletion with confirmation and error handling
function deleteUpload(index) {
  try {
    if (index < 0 || !form.value.images || index >= form.value.images.length) {
      console.warn("Invalid image index for deletion:", index);
      return;
    }

    // Optional: Add confirmation dialog
    if (confirm("Are you sure you want to remove this image?")) {
      // Create a new array without the deleted item
      const newImages = [...form.value.images];
      newImages.splice(index, 1);
      form.value.images = newImages;

      // Success notification
      toast.add({
        title: "Image Removed",
        description: "The image has been removed successfully",
        color: "blue",
        timeout: 2000,
      });
    }
  } catch (error) {
    console.error("Error removing image:", error);
    toast.add({
      title: "Error",
      description: "Failed to remove the image. Please try again.",
      color: "red",
    });
  }
}

// Updated function to log changes in the editor content
function updateContent(p) {
  console.log(
    "Content updated:",
    p.substring(0, 100) + (p.length > 100 ? "..." : "")
  );
  form.value.description = p;
}

function resetForm(showConfirm = true) {
  const doReset = showConfirm
    ? confirm(
        "Are you sure you want to reset the form? All changes will be lost."
      )
    : true;

  if (doReset) {
    console.log("Resetting form");
    form.value = {
      name: "",
      category: "",
      description: "",
      short_description: "",
      images: [],
      discount_price: null,
      sale_price: null,
      quantity: null,
      weight: null,
      delivery_fee_free: 0,
      delivery_fee_inside_dhaka: 0,
      delivery_fee_outside_dhaka: 0,
    };
    // Also reset editor data
    productEditorData.value = null;
  }
}
</script>

<style scoped>
/* Premium Glassmorphism Card */
.glassmorphism-card {
  @apply bg-white/90 dark:bg-slate-800/90 backdrop-blur-md;
}

/* Section Styling */
.form-section {
  @apply px-2 sm:px-6 py-5 rounded-xl relative transition-all duration-300;
}

.section-header {
  @apply flex items-center gap-3 mb-4;
}

.section-icon-wrapper {
  @apply w-10 h-10 rounded-full bg-primary-50 dark:bg-primary-900/30 flex items-center justify-center border border-primary-200 dark:border-primary-800/50;
}

.section-icon {
  @apply w-5 h-5 text-primary-600 dark:text-primary-400;
}

.section-title {
  @apply text-lg font-medium text-gray-800 dark:text-white;
}

/* Premium Floating Form Controls */
.form-floating-group {
  @apply relative;
}

.floating-input-wrapper {
  @apply relative;
}

.floating-input {
  @apply w-full px-4 py-2.5 pt-5 pl-10 rounded-lg border border-slate-200 dark:border-slate-700 
         bg-white dark:bg-slate-800 text-gray-800 dark:text-slate-200 focus:outline-none focus:border-primary-500 
         dark:focus:border-primary-400 focus:ring-2 focus:ring-primary-500/20 dark:focus:ring-primary-400/20 transition-all duration-200;
}

.floating-label {
  @apply absolute left-10 top-3.5 text-sm text-slate-500 dark:text-slate-400 transition-all duration-200 pointer-events-none
         peer-focus:text-sm peer-focus:top-1.5 peer-focus:text-primary-600 dark:peer-focus:text-primary-400
         peer-[:not(:placeholder-shown)]:text-sm peer-[:not(:placeholder-shown)]:top-1.5;
}

.floating-icon {
  @apply absolute left-3 top-1/2 -translate-y-1/2 w-5 h-5 text-slate-400 dark:text-slate-500;
}

/* Premium Currency Input */
.premium-currency-input {
  @apply relative;
}

.currency-symbol {
  @apply absolute left-3 top-1/2 -translate-y-1/2 text-slate-500 dark:text-slate-400 font-medium;
}

.premium-input {
  @apply w-full px-4 py-2.5 pt-5 pl-10 rounded-lg border border-slate-200 dark:border-slate-700
         bg-white dark:bg-slate-800 text-gray-800 dark:text-slate-200 focus:outline-none focus:border-primary-500
         dark:focus:border-primary-400 focus:ring-2 focus:ring-primary-500/20 dark:focus:ring-primary-400/20 transition-all duration-200;
}

.premium-input-label {
  @apply absolute left-10 top-1.5 text-sm text-slate-500 dark:text-slate-400;
}

/* Premium Textarea */
.premium-textarea {
  @apply w-full px-4 py-2.5 pt-5 rounded-lg border border-slate-200 dark:border-slate-700
         bg-white dark:bg-slate-800 text-gray-800 dark:text-slate-200 focus:outline-none focus:border-primary-500
         dark:focus:border-primary-400 focus:ring-2 focus:ring-primary-500/20 dark:focus:ring-primary-400/20 transition-all duration-200 resize-none;
}

.floating-label-textarea {
  @apply absolute left-4 top-1.5 text-sm text-slate-500 dark:text-slate-400;
}

/* Premium Select */
.premium-select {
  @apply border-slate-200 dark:border-slate-700 pt-4 focus:border-primary-500 dark:focus:border-primary-400
         focus:ring-2 focus:ring-primary-500/20 dark:focus:ring-primary-400/20;
}

/* Form Hints & Errors */
.form-hint {
  @apply mt-1.5 text-sm text-slate-500 dark:text-slate-400 flex items-center;
}

.form-error {
  @apply mt-1.5 text-sm text-red-500 flex items-center;
}

/* Premium Buttons */
.premium-btn-primary {
  @apply rounded-lg py-2.5 px-5 bg-gradient-to-r from-primary-500 to-primary-600 border-0 shadow-sm 
         hover:shadow-sm hover:from-primary-600 hover:to-primary-700 transition-all duration-300 transform hover:-translate-y-0.5;
}

.premium-btn-outline {
  @apply rounded-lg py-2.5 px-5 border border-slate-200 dark:border-slate-700 hover:border-primary-400 
         dark:hover:border-primary-500 hover:bg-primary-50 dark:hover:bg-primary-900/10 
         text-slate-700 dark:text-slate-300 hover:text-primary-600 dark:hover:text-primary-400
         transition-all duration-300 transform hover:-translate-y-0.5;
}

.premium-btn-secondary {
  @apply rounded-lg py-2.5 px-5 text-gray-600 dark:text-slate-400 hover:bg-slate-100 
         dark:hover:bg-slate-700/50 hover:text-gray-800 dark:hover:text-white
         transition-all duration-300;
}

/* Premium Checkboxes */
.premium-checkbox-container {
  @apply cursor-pointer;
}

.premium-checkbox {
  @apply sr-only;
}

.premium-checkbox-bg {
  @apply absolute w-5 h-5 border-2 border-slate-300 dark:border-slate-600 rounded 
         transition-colors duration-200;
}

.premium-checkbox-container input:checked ~ .premium-checkbox-bg {
  @apply bg-primary-500 border-primary-500 dark:bg-primary-600 dark:border-primary-600;
}

.premium-checkbox-icon {
  @apply absolute w-3 h-3 text-white opacity-0 transform scale-90 
         transition-all duration-200 pointer-events-none;
}

.premium-checkbox-container input:checked ~ .premium-checkbox-icon {
  @apply opacity-100 scale-100;
}

/* Premium Radio Buttons */
.premium-radio-container {
  @apply cursor-pointer;
}

.premium-radio {
  @apply sr-only;
}

.premium-radio-bg {
  @apply absolute w-5 h-5 border-2 border-slate-300 dark:border-slate-600 rounded-full 
         transition-colors duration-200;
}

.premium-radio-dot {
  @apply absolute w-2.5 h-2.5 top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 rounded-full 
         bg-primary-500 scale-0 opacity-0 transition-all duration-200;
}

.premium-radio-container input:checked ~ .premium-radio-bg {
  @apply border-primary-500 dark:border-primary-500;
}

.premium-radio-container input:checked ~ .premium-radio-dot {
  @apply scale-100 opacity-100;
}

/* Upload Container Animations */
.premium-upload-container {
  @apply transition-all duration-300;
}

.premium-editor-container {
  @apply transition-all duration-300;
}

/* Pulse Animation */
.pulse-animation {
  @apply border-2 border-primary-400/50 dark:border-primary-500/50;
  animation: pulse 2s cubic-bezier(0.4, 0, 0.6, 1) infinite;
}

@keyframes pulse {
  0%,
  100% {
    opacity: 0.5;
  }
  50% {
    opacity: 0;
  }
}

/* Success Animation */
.success-pulse-animation {
  animation: success-pulse 1.5s ease-in-out infinite;
}

@keyframes success-pulse {
  0%,
  100% {
    transform: scale(1);
    box-shadow: 0 0 0 0 rgba(255, 255, 255, 0.7);
  }
  50% {
    transform: scale(1.05);
    box-shadow: 0 0 0 15px rgba(255, 255, 255, 0);
  }
}

/* Success Modal Particles */
.success-particle {
  @apply absolute w-2 h-2 rounded-full bg-white/40;
  animation: float-up 3s ease-in-out infinite;
  top: 100%;
  left: calc(random(100) * 1%);
  animation-delay: calc(random(3) * 1s);
}

@keyframes float-up {
  0% {
    transform: translateY(0) scale(0);
    opacity: 0;
  }
  50% {
    opacity: 1;
  }
  100% {
    transform: translateY(-300px) scale(1);
    opacity: 0;
  }
}

/* Animation Lines */
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
  animation: line-scroll 3s infinite linear;
}

.animate-line-scroll-reverse {
  animation: line-scroll-reverse 3s infinite linear;
}

/* Shimmer animation */
@keyframes shimmer {
  100% {
    transform: translateX(100%);
  }
}

/* Additional Hover Effects */
.form-section:hover {
  @apply bg-slate-50/70 dark:bg-slate-800/60;
}

/* Premium Modal */
.premium-modal {
  @apply backdrop-blur-md;
}
</style>
