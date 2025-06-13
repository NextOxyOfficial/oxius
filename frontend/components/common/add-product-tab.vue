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
              </p>              
              <div
                class="border border-gray-200 rounded-lg overflow-hidden focus-within:ring-2 focus-within:ring-emerald-100 focus-within:border-emerald-500 transition-all"
              >                
              <CommonEditor
                  v-if="route.query.id && form.description"
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

            <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3">
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
              class="my-5"
              style="margin-bottom: 1.25rem !important;"
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
                    </template>                  </UInput>
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
                {{ route.query.id ? 'Update Product' : 'Add Product' }}
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
const route = useRoute();
const router = useRouter();
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
      console.log("API response:", res.data);      toast.add({
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
          router.push('/my-products');
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

    const reader = new FileReader();    reader.onload = (e) => {
      const img = new Image();
      img.onload = () => {
        const canvas = document.createElement("canvas");
        let width = img.width;
        let height = img.height;
        
        // Calculate original file size for comparison
        const originalSize = file.size;        // Enhanced compression: resize while maintaining aspect ratio
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
        ctx.imageSmoothingQuality = 'high';
        ctx.drawImage(img, 0, 0, width, height);

        // Higher quality settings for product images
        let quality = 0.9; // High quality for product photos
        if (originalSize > 10 * 1024 * 1024) { // > 10MB
          quality = 0.85;
        } else if (originalSize > 5 * 1024 * 1024) { // > 5MB
          quality = 0.88;
        }

        const compressedDataUrl = canvas.toDataURL("image/jpeg", quality);

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
  background: rgba(255, 255, 255, 0.9);
  backdrop-filter: blur(12px);
}

.dark .glassmorphism-card {
  background: rgba(30, 41, 59, 0.9);
}

/* Section Styling */
.form-section {
  padding: 1.25rem 0.5rem;
  border-radius: 0.75rem;
  position: relative;
  transition: all 0.3s ease;
}

@media (min-width: 640px) {
  .form-section {
    padding: 1.25rem 1.5rem;
  }
}

.section-header {
  display: flex;
  align-items: center;
  gap: 0.75rem;
  margin-bottom: 1rem;
}

.section-icon-wrapper {
  width: 2.5rem;
  height: 2.5rem;
  border-radius: 50%;
  background: rgb(239 246 255);
  display: flex;
  align-items: center;
  justify-content: center;
  border: 1px solid rgb(219 234 254);
}

.dark .section-icon-wrapper {
  background: rgba(59, 130, 246, 0.3);
  border-color: rgba(59, 130, 246, 0.5);
}

.section-icon {
  width: 1.25rem;
  height: 1.25rem;
  color: rgb(37, 99, 235);
}

.dark .section-icon {
  color: rgb(96, 165, 250);
}

.section-title {
  font-size: 1.125rem;
  font-weight: 500;
  color: rgb(31, 41, 55);
}

.dark .section-title {
  color: white;
}

/* Premium Floating Form Controls */
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

.premium-btn-outline {
  border-radius: 0.5rem;
  padding: 0.625rem 1.25rem;
  border: 1px solid rgb(226, 232, 240);
  color: rgb(51, 65, 85);
  transition: all 0.3s ease;
  transform: translateY(0);
}

.premium-btn-outline:hover {
  border-color: rgb(96, 165, 250);
  background: rgb(239, 246, 255);
  color: rgb(37, 99, 235);
  transform: translateY(-0.125rem);
}

.dark .premium-btn-outline {
  border-color: rgb(51, 65, 85);
  color: rgb(203, 213, 225);
}

.dark .premium-btn-outline:hover {
  border-color: rgb(59, 130, 246);
  background: rgba(59, 130, 246, 0.1);
  color: rgb(96, 165, 250);
}

.premium-btn-secondary {
  border-radius: 0.5rem;
  padding: 0.625rem 1.25rem;
  color: rgb(75, 85, 99);
  transition: all 0.3s ease;
}

.premium-btn-secondary:hover {
  background: rgb(241, 245, 249);
  color: rgb(31, 41, 55);
}

.dark .premium-btn-secondary {
  color: rgb(148, 163, 184);
}

.dark .premium-btn-secondary:hover {
  background: rgba(51, 65, 85, 0.5);
  color: white;
}

/* Additional Hover Effects */
.form-section:hover {
  background: rgba(248, 250, 252, 0.7);
}

.dark .form-section:hover {
  background: rgba(30, 41, 59, 0.6);
}

/* Premium Modal */
.premium-modal {
  backdrop-filter: blur(12px);
}

/* Animation keyframes */
@keyframes pulse {
  0%, 100% {
    opacity: 0.5;
  }
  50% {
    opacity: 0;
  }
}

@keyframes success-pulse {
  0%, 100% {
    transform: scale(1);
    box-shadow: 0 0 0 0 rgba(255, 255, 255, 0.7);
  }
  50% {
    transform: scale(1.05);
    box-shadow: 0 0 0 15px rgba(255, 255, 255, 0);
  }
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

@keyframes shimmer {
  100% {
    transform: translateX(100%);
  }
}

/* Animation classes */
.pulse-animation {
  border: 2px solid rgba(96, 165, 250, 0.5);
  animation: pulse 2s cubic-bezier(0.4, 0, 0.6, 1) infinite;
}

.dark .pulse-animation {
  border-color: rgba(59, 130, 246, 0.5);
}

.success-pulse-animation {
  animation: success-pulse 1.5s ease-in-out infinite;
}

.success-particle {
  position: absolute;
  width: 0.5rem;
  height: 0.5rem;
  border-radius: 50%;
  background: rgba(255, 255, 255, 0.4);
  animation: float-up 3s ease-in-out infinite;
  top: 100%;
}

.animate-line-scroll {
  animation: line-scroll 3s infinite linear;
}

.animate-line-scroll-reverse {
  animation: line-scroll-reverse 3s infinite linear;
}

.premium-upload-container {
  transition: all 0.3s ease;
}

.premium-editor-container {
  transition: all 0.3s ease;
}
</style>
