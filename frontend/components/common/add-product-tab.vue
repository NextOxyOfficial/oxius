<template>
  <div class="min-h-screen pb-8 bg-gradient-to-b from-gray-50 to-gray-100">
    <UContainer>
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
                class="text-emerald-600"
              />
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
                </template>
              </UInput>
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
                </template>
              </USelectMenu>
            </UFormGroup>

            <UFormGroup label="Keywords (Optional)" class="mb-5">
              <!-- Keywords Input Section -->
              <div class="space-y-3">
                <!-- Input Row -->
                <div class="flex gap-3">
                  <div class="flex-1">
                    <UInput
                      ref="keywordInput"
                      type="text"
                      size="md"
                      color="white"
                      v-model="currentKeyword"
                      placeholder="Enter a keyword (e.g., electronics, mobile, smartphone)"
                      class="w-full border-gray-200 focus:border-emerald-500 focus:ring focus:ring-emerald-100 transition-all"
                      maxlength="50"
                      @keydown.enter.prevent="addKeyword"
                    >
                      <template #leading>
                        <UIcon name="i-heroicons-tag" />
                      </template>
                    </UInput>
                  </div>
                  <UButton
                    type="button"
                    @click="addKeyword"
                    :disabled="
                      !currentKeyword.trim() || keywordChips.length >= 20
                    "
                    color="emerald"
                    variant="solid"
                    size="md"
                    class="px-6"
                  >
                    <UIcon name="i-heroicons-plus" class="w-4 h-4 mr-2" />
                    Add
                  </UButton>
                </div>

                <!-- Keywords Chips Display -->
                <div v-if="keywordChips.length > 0" class="space-y-2">
                  <div class="flex items-center justify-between">
                    <label class="text-sm font-medium text-gray-700"
                      >Added Keywords:</label
                    >
                    <span class="text-xs text-gray-500"
                      >{{ keywordChips.length }}/20</span
                    >
                  </div>

                  <div
                    class="flex flex-wrap gap-2 p-3 bg-gray-50 rounded-lg border border-gray-200 min-h-[60px]"
                  >
                    <div
                      v-for="(keyword, index) in keywordChips"
                      :key="index"
                      class="inline-flex items-center gap-2 px-3 py-2 bg-emerald-500 text-white rounded-full text-sm font-medium shadow-sm hover:bg-emerald-600 transition-all duration-200 group"
                    >
                      <UIcon name="i-heroicons-tag" class="w-3 h-3" />
                      <span>{{ keyword }}</span>
                      <button
                        type="button"
                        @click="removeKeyword(index)"
                        class="ml-1 hover:bg-emerald-700 rounded-full p-1 transition-all duration-200 group-hover:bg-emerald-700"
                        :aria-label="`Remove ${keyword} keyword`"
                      >
                        <UIcon name="i-heroicons-x-mark" class="w-3 h-3" />
                      </button>
                    </div>
                  </div>
                </div>

                <!-- Empty State -->
                <div
                  v-else
                  class="p-6 text-center border-2 border-dashed border-gray-300 rounded-lg bg-gray-50"
                >
                  <UIcon
                    name="i-heroicons-tag"
                    class="w-8 h-8 text-gray-400 mx-auto mb-2"
                  />
                  <p class="text-sm text-gray-500">No keywords added yet</p>
                  <p class="text-xs text-gray-400 mt-1">
                    Keywords help customers find your product when searching
                  </p>
                </div>
              </div>

              <!-- Help Text -->
              <div class="mt-3 flex items-start justify-between">
                <p class="text-sm text-gray-500 flex-1">
                  Add relevant keywords to help customers find your product.
                  Type a keyword and click "Add" to create tags.
                </p>
                <div
                  class="flex items-center gap-2 ml-4"
                  v-if="keywordChips.length >= 18"
                >
                  <UIcon
                    name="i-heroicons-exclamation-triangle"
                    class="w-4 h-4 text-amber-500"
                  />
                  <span class="text-xs text-amber-600 whitespace-nowrap">
                    {{ 20 - keywordChips.length }} remaining
                  </span>
                </div>
              </div>
            </UFormGroup>
          </div>

          <!-- Product Details Section -->
          <div
            class="p-2 md:p-7 border-b border-gray-100 hover:bg-gray-50 transition-colors duration-300"
          >
            <h2
              class="text-xl font-semibold text-gray-800 mb-6 flex items-center gap-2"
            >
              <UIcon
                name="i-heroicons-document-text"
                class="text-emerald-600"
              />
              Product Details
            </h2>

            <UFormGroup label="Description" required class="mb-5">
              <p class="text-sm text-gray-600 mb-3">
                Provide detailed information about your product
              </p>
              <div
                class="border border-gray-200 rounded-lg overflow-hidden focus-within:ring-2 focus-within:ring-emerald-100 focus-within:border-emerald-500 transition-all"
              >
                <CommonEditor
                  v-if="route.params.id && form.description"
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
              />
            </UFormGroup>
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
                  multiple
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
              Uploading image...
            </p>
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

            <div class="grid grid-cols-1 sm:grid-cols-2 gap-1 lg:grid-cols-3">
              <UFormGroup
                label="Regular Price"
                required
                :error="
                  !form.regular_price &&
                  checkSubmit &&
                  'Regular price is required'
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
                </UInput>
              </UFormGroup>
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
                !form.deliveryMethod &&
                checkSubmit &&
                'Please select a delivery method'
              "
              class="my-5"
              style="margin-bottom: 1.25rem !important"
              ><div class="space-y-3">
                <div class="flex items-center mt-4">
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
          </div>
          <UCard class="mx-2 sm:mx-6">
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
            <div class="flex flex-row gap-3 justify-between">
              <UButton
                color="gray"
                variant="outline"
                @click="resetForm"
                class="flex-1"
              >
                <UIcon name="i-heroicons-arrow-path" class="mr-2" />
                Reset Form
              </UButton>

              <UButton
                type="submit"
                color="primary"
                size="lg"
                :loading="isSubmitting"
                class="bg-emerald-600 hover:bg-emerald-700 focus:ring-emerald-100 flex-1"
                ><UIcon name="i-heroicons-plus-circle" class="mr-2" />
                {{ route.query.id ? "Update Product" : "Add Product" }}
              </UButton>
            </div>
          </div>
        </div>
      </form>
    </UContainer>
  </div>
</template>

<script setup>
import { nextTick, onMounted } from "vue";

const props = defineProps({
  product: Object,
});

const emit = defineEmits(["tabChange"]);

const { get, post, put } = useApi();
const route = useRoute();
const router = useRouter();
const toast = useToast();
const currentStep = ref(0); // Track current step for highlighting
const categories = ref([]);
const currentKeyword = ref("");
const keywordChips = ref([]);
const keywordInput = ref(null);

// Simplified form with only essential fields
const form = ref(
  props.product || {
    name: "",
    keywords: "",
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

  // Store the editor data in the form
  if (editorData) {
    const previousData = form.value.editorData;
    form.value.editorData = editorData;

    // Add timestamp to track when changes occurred
    const now = new Date();

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

    console.groupEnd();
    return;
  }

  // Check product limit before submission (only for new products)
  if (!props.product?.id) {
    try {
      const { data: userProducts } = await get("/shop-manager/");
      const currentProductCount = userProducts ? userProducts.length : 0;
      const productLimit = user.value?.user?.product_limit || 10;

      if (currentProductCount >= productLimit) {
        toast.add({
          title: "Product Limit Reached",
          description: `You have reached your product limit of ${productLimit}. Delete an existing product or purchase additional product slots to add new products.`,
          color: "red",
          timeout: 8000,
        });

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

        // Navigate to my-products page after successful creation
        setTimeout(() => {
          emit("tabChange", "products");
        }, 2000); // Wait 2 seconds to show success message
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

// Initialize keywords from existing form data if editing a product
onMounted(() => {
  initializeKeywords();
});

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

    if (!form.value.images) {
      form.value.images = [];
    }

    // Check if adding these files would exceed the limit
    const remainingSlots = 5 - form.value.images.length;
    if (files.length > remainingSlots) {
      uploadError.value = `You can only add ${remainingSlots} more image(s). Maximum 5 images allowed.`;
      isUploading.value = false;
      return;
    }

    // Validate all files first
    for (const file of files) {
      if (!file.type.startsWith("image/")) {
        uploadError.value = `"${file.name}" is not a valid image file`;
        isUploading.value = false;
        return;
      }

      if (file.size > 12 * 1024 * 1024) {
        uploadError.value = `"${file.name}" is too large. Image size must be less than 12MB`;
        isUploading.value = false;
        return;
      }
    }

    // Process all files
    let processedCount = 0;
    const totalFiles = files.length;

    files.forEach((file, index) => {
      const reader = new FileReader();
      reader.onload = (e) => {
        const img = new Image();
        img.onload = () => {
          const canvas = document.createElement("canvas");
          let width = img.width;
          let height = img.height;

          // Calculate original file size for comparison
          const originalSize = file.size;
          // Enhanced compression: resize while maintaining aspect ratio
          // Increased max size for better product image quality
          const maxSize = 1600; // Higher max size for product photos
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
          // Enable image smoothing for better quality
          ctx.imageSmoothingEnabled = true;
          ctx.imageSmoothingQuality = "high";
          ctx.drawImage(img, 0, 0, width, height);

          // Higher quality settings for product images
          let quality = 0.9; // High quality for product photos
          if (originalSize > 10 * 1024 * 1024) {
            // > 10MB
            quality = 0.85;
          } else if (originalSize > 5 * 1024 * 1024) {
            // > 5MB
            quality = 0.88;
          }

          const compressedDataUrl = canvas.toDataURL("image/jpeg", quality);

          form.value.images.push(compressedDataUrl);
          processedCount++;

          // Check if all files have been processed
          if (processedCount === totalFiles) {
            isUploading.value = false;

            // Show success message
            toast.add({
              title: "Images Uploaded",
              description: `Successfully uploaded ${totalFiles} image(s)`,
              color: "green",
              timeout: 3000,
            });

            // Reset file input
            if (event.target) {
              event.target.value = null;
            }
          }
        };

        img.onerror = () => {
          uploadError.value = `Invalid image "${file.name}". Please try again.`;
          isUploading.value = false;
        };

        img.src = e.target.result;
      };

      reader.onerror = (error) => {
        console.error("FileReader error:", error);
        uploadError.value = `Error uploading "${file.name}". Please try again.`;
        isUploading.value = false;
      };

      reader.readAsDataURL(file);
    });
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
  form.value.description = p;
}

// Keyword management functions
function addKeyword() {
  const keyword = currentKeyword.value.trim();

  // Validation checks
  if (!keyword) {
    return;
  }

  if (keywordChips.value.length >= 20) {
    toast.add({
      title: "Keyword Limit Reached",
      description: "You can add a maximum of 20 keywords",
      color: "amber",
      timeout: 3000,
    });
    return;
  }

  if (keyword.length < 2) {
    toast.add({
      title: "Keyword Too Short",
      description: "Keywords must be at least 2 characters long",
      color: "amber",
      timeout: 2000,
    });
    return;
  }

  if (
    keywordChips.value.some((k) => k.toLowerCase() === keyword.toLowerCase())
  ) {
    toast.add({
      title: "Duplicate Keyword",
      description: `"${keyword}" is already added`,
      color: "amber",
      timeout: 2000,
    });
    return;
  }

  // Add the keyword
  keywordChips.value.push(keyword);
  currentKeyword.value = "";
  updateFormKeywords();

  // Show success feedback
  toast.add({
    title: "Keyword Added",
    description: `"${keyword}" added successfully`,
    color: "green",
    timeout: 2000,
  });

  // Focus back to input for better UX
  nextTick(() => {
    if (keywordInput.value) {
      keywordInput.value.focus();
    }
  });
}

function removeKeyword(index) {
  const removedKeyword = keywordChips.value[index];
  keywordChips.value.splice(index, 1);
  updateFormKeywords();

  toast.add({
    title: "Keyword Removed",
    description: `"${removedKeyword}" removed successfully`,
    color: "blue",
    timeout: 2000,
  });
}

function updateFormKeywords() {
  // Update the form.keywords string with comma-separated values
  form.value.keywords = keywordChips.value.join(", ");
}

function initializeKeywords() {
  // Initialize chips from existing form data
  if (form.value.keywords) {
    keywordChips.value = form.value.keywords
      .split(",")
      .map((keyword) => keyword.trim())
      .filter((keyword) => keyword.length > 0);
  }
}

function resetForm(showConfirm = true) {
  const doReset = showConfirm
    ? confirm(
        "Are you sure you want to reset the form? All changes will be lost."
      )
    : true;

  if (doReset) {
    form.value = {
      name: "",
      keywords: "",
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
    // Reset keyword chips
    keywordChips.value = [];
    currentKeyword.value = "";
    // Also reset editor data
    productEditorData.value = null;
  }
}
</script>

<style scoped>
/* Premium Form Controls */
.form-floating-group {
  position: relative;
}

.floating-input-wrapper {
  position: relative;
}

.floating-input {
  width: 100%;
  padding: 0.625rem 1rem 0.625rem 2.5rem;
  padding-top: 1.25rem;
  border-radius: 0.5rem;
  border: 1px solid rgb(226, 232, 240);
  background: white;
  color: rgb(31, 41, 55);
  transition: all 0.2s ease;
}

.floating-input:focus {
  outline: none;
  border-color: rgb(59, 130, 246);
  box-shadow: 0 0 0 2px rgba(59, 130, 246, 0.2);
}

.dark .floating-input {
  border-color: rgb(51, 65, 85);
  background: rgb(30, 41, 59);
  color: rgb(226, 232, 240);
}

.dark .floating-input:focus {
  border-color: rgb(96, 165, 250);
  box-shadow: 0 0 0 2px rgba(96, 165, 250, 0.2);
}

.floating-label {
  position: absolute;
  left: 2.5rem;
  top: 0.875rem;
  font-size: 0.875rem;
  color: rgb(100, 116, 139);
  transition: all 0.2s ease;
  pointer-events: none;
}

.floating-input:focus ~ .floating-label,
.floating-input:not(:placeholder-shown) ~ .floating-label {
  top: 0.375rem;
  font-size: 0.875rem;
  color: rgb(59, 130, 246);
}

.dark .floating-label {
  color: rgb(148, 163, 184);
}

.dark .floating-input:focus ~ .floating-label,
.dark .floating-input:not(:placeholder-shown) ~ .floating-label {
  color: rgb(96, 165, 250);
}

.floating-icon {
  position: absolute;
  left: 0.75rem;
  top: 50%;
  transform: translateY(-50%);
  width: 1.25rem;
  height: 1.25rem;
  color: rgb(148, 163, 184);
}

.dark .floating-icon {
  color: rgb(100, 116, 139);
}

/* Premium Currency Input */
.premium-currency-input {
  position: relative;
}

.currency-symbol {
  position: absolute;
  left: 0.75rem;
  top: 50%;
  transform: translateY(-50%);
  color: rgb(100, 116, 139);
  font-weight: 500;
}

.dark .currency-symbol {
  color: rgb(148, 163, 184);
}

.premium-input {
  width: 100%;
  padding: 0.625rem 1rem 0.625rem 2.5rem;
  padding-top: 1.25rem;
  border-radius: 0.5rem;
  border: 1px solid rgb(226, 232, 240);
  background: white;
  color: rgb(31, 41, 55);
  transition: all 0.2s ease;
}

.premium-input:focus {
  outline: none;
  border-color: rgb(59, 130, 246);
  box-shadow: 0 0 0 2px rgba(59, 130, 246, 0.2);
}

.dark .premium-input {
  border-color: rgb(51, 65, 85);
  background: rgb(30, 41, 59);
  color: rgb(226, 232, 240);
}

.dark .premium-input:focus {
  border-color: rgb(96, 165, 250);
  box-shadow: 0 0 0 2px rgba(96, 165, 250, 0.2);
}

.premium-input-label {
  position: absolute;
  left: 2.5rem;
  top: 0.375rem;
  font-size: 0.875rem;
  color: rgb(100, 116, 139);
}

.dark .premium-input-label {
  color: rgb(148, 163, 184);
}

/* Premium Textarea */
.premium-textarea {
  width: 100%;
  padding: 0.625rem 1rem;
  padding-top: 1.25rem;
  border-radius: 0.5rem;
  border: 1px solid rgb(226, 232, 240);
  background: white;
  color: rgb(31, 41, 55);
  transition: all 0.2s ease;
  resize: none;
}

.premium-textarea:focus {
  outline: none;
  border-color: rgb(59, 130, 246);
  box-shadow: 0 0 0 2px rgba(59, 130, 246, 0.2);
}

.dark .premium-textarea {
  border-color: rgb(51, 65, 85);
  background: rgb(30, 41, 59);
  color: rgb(226, 232, 240);
}

.dark .premium-textarea:focus {
  border-color: rgb(96, 165, 250);
  box-shadow: 0 0 0 2px rgba(96, 165, 250, 0.2);
}

.floating-label-textarea {
  position: absolute;
  left: 1rem;
  top: 0.375rem;
  font-size: 0.875rem;
  color: rgb(100, 116, 139);
}

.dark .floating-label-textarea {
  color: rgb(148, 163, 184);
}

/* Premium Select */
.premium-select {
  border-color: rgb(226, 232, 240);
  padding-top: 1rem;
}

.premium-select:focus {
  border-color: rgb(59, 130, 246);
  box-shadow: 0 0 0 2px rgba(59, 130, 246, 0.2);
}

.dark .premium-select {
  border-color: rgb(51, 65, 85);
}

.dark .premium-select:focus {
  border-color: rgb(96, 165, 250);
  box-shadow: 0 0 0 2px rgba(96, 165, 250, 0.2);
}

/* Form Hints & Errors */
.form-hint {
  margin-top: 0.375rem;
  font-size: 0.875rem;
  color: rgb(100, 116, 139);
  display: flex;
  align-items: center;
}

.dark .form-hint {
  color: rgb(148, 163, 184);
}

.form-error {
  margin-top: 0.375rem;
  font-size: 0.875rem;
  color: rgb(239, 68, 68);
  display: flex;
  align-items: center;
}

/* Premium Buttons */
.premium-btn-primary {
  border-radius: 0.5rem;
  padding: 0.625rem 1.25rem;
  background: linear-gradient(to right, rgb(59, 130, 246), rgb(37, 99, 235));
  border: none;
  box-shadow: 0 1px 2px 0 rgba(0, 0, 0, 0.05);
  transition: all 0.3s ease;
  transform: translateY(0);
}

.premium-btn-primary:hover {
  background: linear-gradient(to right, rgb(37, 99, 235), rgb(29, 78, 216));
  box-shadow: 0 1px 3px 0 rgba(0, 0, 0, 0.1), 0 1px 2px 0 rgba(0, 0, 0, 0.06);
  transform: translateY(-0.125rem);
}

/* Form Transitions */
.form-section:hover {
  background: rgba(248, 250, 252, 0.7);
}

.dark .form-section:hover {
  background: rgba(30, 41, 59, 0.6);
}
</style>
