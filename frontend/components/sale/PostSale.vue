<template>
  <div class="post-sale-container max-w-4xl mx-auto text-left">
    <!-- Success Modal -->
    <div
      v-if="showSuccessModal"
      class="fixed inset-0 flex items-center justify-center z-50 bg-black/60"
    >
      <div
        class="bg-white rounded-lg shadow-sm max-w-md w-full p-8 transform transition-all"
      >
        <div class="text-center">
          <div class="mb-5 flex justify-center">
            <div class="rounded-full bg-yellow-100 p-4">
              <Icon name="heroicons:clock" class="h-12 w-12 text-yellow-500" />
            </div>
          </div>
          <h3 class="text-xl font-semibold text-gray-800 mb-3">
            Post Submitted Successfully!
          </h3>
          <p class="text-gray-600 mb-5">
            Your listing has been submitted and is now
            <span
              class="font-medium text-yellow-600 bg-yellow-50 px-2 py-0.5 rounded"
              >under review</span
            >. We'll notify you once it's approved.
          </p>
          <div class="flex justify-center">
            <button
              @click="closeSuccessModal"
              class="bg-primary text-white px-8 py-1.5 rounded-md hover:bg-primary/90 transition font-medium"
            >
              Got it
            </button>
          </div>
        </div>
      </div>
    </div>

    <div class="bg-white rounded-xl shadow-sm border border-gray-100">
      <!-- Progress Steps Indicator -->
      <div class="px-6 sm:px-8 pt-1">
        <div class="flex justify-between mb-8">
          <div
            v-for="(step, index) in formSteps"
            :key="index"
            class="flex flex-col items-center relative w-full"
          >
            <div
              :class="[
                'w-10 h-10 rounded-full flex items-center justify-center z-10 relative mb-2 shadow-sm',
                currentStep > index
                  ? 'bg-green-500 text-white'
                  : currentStep === index
                  ? 'bg-primary text-white'
                  : 'bg-gray-100 text-gray-600',
              ]"
            >
              <span v-if="currentStep > index">
                <Icon name="heroicons:check" class="w-5 h-5" />
              </span>
              <span v-else class="font-medium">{{ index + 1 }}</span>
            </div>
            <span
              class="text-sm font-medium text-center"
              :class="currentStep >= index ? 'text-gray-800' : 'text-gray-600'"
              >{{ step }}</span
            >
            <!-- Connector line -->
            <div
              v-if="index < formSteps.length - 1"
              :class="[
                'absolute top-5 left-1/2 h-0.5 w-full',
                currentStep > index ? 'bg-green-500' : 'bg-gray-200',
              ]"
            ></div>
          </div>
        </div>
      </div>

      <form @submit.prevent="validateStep">
        <!-- Step 1: Basic Details -->
        <div v-if="currentStep === 0" class="fade-transition px-2 sm:px-8 pb-8">
          <h3 class="text-xl font-semibold text-gray-800 mb-6">
            Basic Details
          </h3>

          <!-- Parent Category Selection -->
          <div class="mb-6">
            <label
              for="category"
              class="block text-sm font-medium text-gray-800 mb-2"
              >Category <span class="text-red-500">*</span></label
            >
            <div class="relative">
              <select
                id="category"
                v-model="formData.category"
                class="w-full border border-gray-300 rounded-md pl-4 pr-10 py-1.5 appearance-none bg-white focus:ring-primary focus:border-primary text-gray-800 shadow-sm"
                required
                @change="handleCategoryChange"
              >
                <option value="" disabled>Select a category</option>
                <option
                  v-for="category in categories"
                  :key="category.id"
                  :value="category.id"
                >
                  {{ category.name }}
                </option>
              </select>
              <div
                class="absolute inset-y-0 right-0 flex items-center px-3 pointer-events-none"
              >
                <Icon
                  name="heroicons:chevron-down"
                  class="h-5 w-5 text-gray-600"
                />
              </div>
            </div>
            <p v-if="errors.category" class="mt-2 text-red-500 text-sm">
              {{ errors.category }}
            </p>
          </div>

          <!-- Child Category Selection -->
          <div class="mb-6" v-if="formData.category">
            <label
              for="childCategory"
              class="block text-sm font-medium text-gray-800 mb-2"
              >Sub Category
              <span v-if="childCategories.length" class="text-red-500"
                >*</span
              ></label
            >
            <div class="relative">
              <select
                id="childCategory"
                v-model="formData.childCategory"
                class="w-full border border-gray-300 rounded-md pl-4 pr-10 py-1.5 appearance-none bg-white focus:ring-primary focus:border-primary text-gray-800 shadow-sm"
                :required="childCategories.length > 0"
              >
                <option value="" disabled>
                  {{
                    childCategories.length
                      ? "Select a sub category"
                      : "No sub categories available"
                  }}
                </option>
                <option
                  v-for="childCategory in childCategories"
                  :key="childCategory.id"
                  :value="childCategory.id"
                >
                  {{ childCategory.name }}
                </option>
              </select>
              <div
                class="absolute inset-y-0 right-0 flex items-center px-3 pointer-events-none"
              >
                <Icon
                  name="heroicons:chevron-down"
                  class="h-5 w-5 text-gray-600"
                />
              </div>
            </div>
            <p v-if="errors.childCategory" class="mt-2 text-red-500 text-sm">
              {{ errors.childCategory }}
            </p>
          </div>

          <!-- Title -->
          <div class="mb-6">
            <label
              for="title"
              class="block text-sm font-medium text-gray-800 mb-2"
              >Title <span class="text-red-500">*</span></label
            >
            <div class="relative">
              <input
                type="text"
                id="title"
                v-model="formData.title"
                class="w-full border border-gray-300 rounded-md pl-10 pr-3 py-1.5 focus:ring-primary focus:border-primary shadow-sm"
                placeholder="Enter a descriptive title"
                required
                maxlength="100"
              />
              <div
                class="absolute inset-y-0 left-0 flex items-center pl-3 pointer-events-none"
              >
                <Icon
                  name="heroicons:document-text"
                  class="h-5 w-5 text-gray-600"
                />
              </div>
              <div class="absolute right-3 bottom-3 text-xs text-gray-600">
                {{ formData.title.length }}/100
              </div>
            </div>
            <p v-if="errors.title" class="mt-2 text-red-500 text-sm">
              {{ errors.title }}
            </p>
          </div>

          <!-- Description -->
          <div class="mb-6">
            <label
              for="description"
              class="block text-sm font-medium text-gray-800 mb-2"
              >Description <span class="text-red-500">*</span></label
            >
            <div class="relative">
              <CommonEditor
                v-model="formData.description"
                @updateContent="updateContent"
                class="editor-container text-left"
                placeholder="Describe what you're selling in detail"
              />

              <div class="absolute right-3 bottom-3 text-xs text-gray-600">
                {{ formData.description.length }}/1000
              </div>
            </div>
            <p v-if="errors.description" class="mt-2 text-red-500 text-sm">
              {{ errors.description }}
            </p>
          </div>

          <!-- Condition -->
          <div class="mb-6">
            <label class="block text-sm font-medium text-gray-800 mb-2"
              >Condition <span class="text-red-500">*</span></label
            >
            <div class="flex flex-wrap gap-3">
              <label
                v-for="condition in conditions"
                :key="condition.value"
                :class="[
                  'flex items-center px-5 py-1.5 border rounded-md cursor-pointer transition-colors',
                  formData.condition === condition.value
                    ? 'border-primary bg-primary/10 text-primary font-medium shadow-sm'
                    : 'border-gray-300 hover:bg-gray-50',
                ]"
              >
                <input
                  type="radio"
                  :value="condition.value"
                  v-model="formData.condition"
                  class="hidden"
                />
                <span>{{ condition.label }}</span>
              </label>
            </div>
            <p v-if="errors.condition" class="mt-2 text-red-500 text-sm">
              {{ errors.condition }}
            </p>
          </div>
        </div>

        <!-- Step 2: Price and Location -->
        <div v-if="currentStep === 1" class="fade-transition px-2 sm:px-8 pb-8">
          <h3 class="text-xl font-semibold text-gray-800 mb-6">
            Pricing & Location
          </h3>

          <!-- Price -->
          <div class="mb-6">
            <label class="block text-sm font-medium text-gray-800 mb-2"
              >Price <span class="text-red-500">*</span></label
            >
            <div class="flex items-center">
              <div class="relative flex-grow">
                <div
                  class="absolute inset-y-0 left-0 flex items-center pl-3 pointer-events-none"
                >
                  <Icon name="mdi:currency-bdt" class="h-5 w-5 text-gray-600" />
                </div>
                <input
                  type="number"
                  v-model="formData.price"
                  class="w-full border border-gray-300 rounded-l-md pl-10 pr-3 py-1.5 focus:ring-primary focus:border-primary shadow-sm"
                  placeholder="Enter your price"
                  min="0"
                  :disabled="formData.negotiable"
                  required
                />
              </div>
              <label
                class="flex items-center border border-l-0 border-gray-300 rounded-r-md px-4 py-1.5 bg-gray-50 hover:bg-gray-100 cursor-pointer"
              >
                <input
                  type="checkbox"
                  v-model="formData.negotiable"
                  class="rounded text-primary focus:ring-primary h-4 w-4 mr-2"
                />
                <span class="text-sm font-medium">Negotiable</span>
              </label>
            </div>
            <p v-if="errors.price" class="mt-2 text-red-500 text-sm">
              {{ errors.price }}
            </p>
          </div>

          <!-- Location Selection -->
          <div class="mb-6">
            <label class="block text-sm font-medium text-gray-800 mb-2"
              >Targeted Location <span class="text-red-500">*</span>
              <span class="text-xs"
                >(Where you want to show your ad)</span
              ></label
            >
            <UCheckbox
              v-model="allOverBangladesh"
              name="all-bangladesh"
              :label="
                t('all_over_bangladesh') ||
                'Show content from all over Bangladesh'
              "
              color="primary"
            />
            <UDivider label="OR" />
            <div
              class="grid grid-cols-1 md:grid-cols-3 gap-4 mt-2"
              v-if="!allOverBangladesh"
            >
              <div>
                <select
                  v-model="formData.division"
                  class="w-full border border-gray-300 rounded-md px-4 py-0.5 focus:ring-primary focus:border-primary shadow-sm"
                  required
                >
                  <option value="" disabled>Select Division</option>
                  <option
                    v-for="division in regions"
                    :key="division.id"
                    :value="division.name_eng"
                  >
                    {{ division.name_eng }}
                  </option>
                </select>
                <p v-if="errors.division" class="mt-2 text-red-500 text-sm">
                  {{ errors.division }}
                </p>
              </div>

              <div>
                <select
                  v-model="formData.district"
                  class="w-full border border-gray-300 rounded-md px-4 py-0.5 focus:ring-primary focus:border-primary shadow-sm"
                  required
                  :disabled="!formData.division"
                >
                  <option value="" disabled>Select District</option>
                  <option
                    v-for="district in cities"
                    :key="district.id"
                    :value="district.name_eng"
                  >
                    {{ district.name_eng }}
                  </option>
                </select>
                <p v-if="errors.district" class="mt-2 text-red-500 text-sm">
                  {{ errors.district }}
                </p>
              </div>

              <div>
                <select
                  v-model="formData.area"
                  class="w-full border border-gray-300 rounded-md px-4 py-0.5 focus:ring-primary focus:border-primary shadow-sm"
                  required
                  :disabled="!formData.district"
                >
                  <option value="" disabled>Select Area</option>
                  <option
                    v-for="area in upazilas"
                    :key="area.id"
                    :value="area.name_eng"
                  >
                    {{ area.name_eng }}
                  </option>
                </select>
                <p v-if="errors.area" class="mt-2 text-red-500 text-sm">
                  {{ errors.area }}
                </p>
              </div>
            </div>
          </div>

          <!-- Detailed Address -->
          <div class="mb-6">
            <label
              for="detailedAddress"
              class="block text-sm font-medium text-gray-800 mb-2"
              >Item/Property Address <span class="text-red-500">*</span></label
            >
            <textarea
              id="detailedAddress"
              v-model="formData.detailedAddress"
              class="w-full border border-gray-300 rounded-md px-4 py-1.5 focus:ring-primary focus:border-primary shadow-sm"
              rows="3"
              placeholder="Provide specific location details"
              required
            ></textarea>
            <p v-if="errors.detailedAddress" class="mt-2 text-red-500 text-sm">
              {{ errors.detailedAddress }}
            </p>
          </div>

          <!-- Contact Info -->
          <div class="mb-6">
            <label class="block text-sm font-medium text-gray-800 mb-3"
              >Contact Information <span class="text-red-500">*</span></label
            >

            <div class="space-y-4">
              <div class="relative">
                <div
                  class="absolute inset-y-0 left-0 flex items-center pl-3 pointer-events-none"
                >
                  <Icon name="heroicons:phone" class="h-5 w-5 text-gray-600" />
                </div>
                <input
                  type="tel"
                  v-model="formData.phone"
                  class="w-full border border-gray-300 rounded-md pl-10 pr-3 py-1.5 focus:ring-primary focus:border-primary shadow-sm"
                  placeholder="Phone Number"
                  required
                  pattern="[0-9]{11}"
                />
                <p v-if="errors.phone" class="mt-2 text-red-500 text-sm">
                  {{ errors.phone }}
                </p>
              </div>

              <div class="relative">
                <div
                  class="absolute inset-y-0 left-0 flex items-center pl-3 pointer-events-none"
                >
                  <Icon
                    name="heroicons:envelope"
                    class="h-5 w-5 text-gray-600"
                  />
                </div>
                <input
                  type="email"
                  v-model="formData.email"
                  class="w-full border border-gray-300 rounded-md pl-10 pr-3 py-1.5 focus:ring-primary focus:border-primary shadow-sm"
                  placeholder="Email (optional)"
                />
              </div>
            </div>
          </div>
        </div>

        <!-- Step 3: Images Upload -->
        <div v-if="currentStep === 2" class="fade-transition px-2 sm:px-8 pb-8">
          <h3 class="text-xl font-semibold text-gray-800 mb-6">
            Upload Photos
          </h3>

          <p class="text-sm text-gray-600 mb-6">
            Upload clear photos to get more responses. You can upload up to 8
            images.
            <span class="font-medium text-primary"
              >First image will be the main image.</span
            >
          </p>

          <div class="grid grid-cols-2 sm:grid-cols-4 gap-5 mb-6">
            <div
              v-for="n in 8"
              :key="n"
              class="aspect-square relative border-2 border-dashed rounded-lg group transition-all shadow-sm hover:shadow"
              :class="
                formData.images[n - 1]
                  ? 'border-primary bg-primary/5'
                  : 'border-gray-300 bg-gray-50'
              "
              @click="openFileUpload(n - 1)"
            >
              <input
                type="file"
                :ref="
                  (el) => {
                    if (el) fileInputRefs[`fileInput${n - 1}`] = el;
                  }
                "
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
                  class="text-gray-600 text-2xl mb-2 group-hover:text-primary transition-colors"
                />
                <div
                  class="text-sm text-gray-600 group-hover:text-primary transition-colors"
                >
                  {{ n === 1 ? "Add main photo" : "Add photo" }}
                </div>
              </div>

              <img
                v-else
                :src="imagePreviewUrls[n - 1]"
                class="absolute inset-0 w-full h-full object-contain rounded-lg"
                alt="Preview"
              />

              <button
                v-if="formData.images[n - 1]"
                type="button"
                class="absolute top-2 right-2 bg-red-500 text-white rounded-full w-7 h-7 flex items-center justify-center opacity-0 group-hover:opacity-100 transition-opacity shadow-sm"
                @click.stop="removeImage(n - 1)"
              >
                <Icon name="heroicons:x-mark" size="18px" />
              </button>

              <div
                v-if="n === 1"
                class="absolute top-2 left-2 bg-primary text-white text-xs px-2.5 py-1 rounded font-medium shadow-sm"
              >
                Main
              </div>
            </div>          </div>          <!-- Compression Progress Indicator -->
          <transition
            enter-active-class="transition-all duration-300 ease-out"
            enter-from-class="opacity-0 -translate-y-4"
            enter-to-class="opacity-100 translate-y-0"
            leave-active-class="transition-all duration-200 ease-in"
            leave-from-class="opacity-100 translate-y-0"
            leave-to-class="opacity-0 -translate-y-4"
          >
            <div
              v-if="isCompressing"
              class="bg-blue-50 rounded-lg p-4 space-y-3 mb-4 border border-blue-100"
            >
              <div class="flex items-center gap-3">
                <div class="w-5 h-5 rounded-full bg-blue-600 flex items-center justify-center">
                  <Icon name="heroicons:arrow-path" class="h-3 w-3 text-white animate-spin" />
                </div>
                <span class="text-sm font-medium text-blue-800">
                  {{ compressionStatus }}
                </span>
              </div>
              
              <!-- Progress Bar -->
              <div class="w-full bg-blue-200 rounded-full h-2 overflow-hidden">
                <div 
                  class="bg-blue-600 h-full rounded-full transition-all duration-300 ease-out"
                  :style="{ width: `${compressionProgress}%` }"
                ></div>
              </div>
              
              <p class="text-xs text-blue-700">
                Please wait while we optimize your image for the best quality and performance.
              </p>
            </div>
          </transition>

          <p v-if="errors.images" class="mt-2 text-red-500 text-sm">
            {{ errors.images }}
          </p>

          <div
            class="flex items-center gap-2 mt-4 bg-blue-50 p-3 rounded-lg border border-blue-100"
          >
            <Icon
              name="heroicons:information-circle"
              class="text-blue-500 h-5 w-5 flex-shrink-0"
            />
            <p class="text-sm text-blue-700">
              Recommended: Upload at least 3 high-quality images from different
              angles for better responses
            </p>
          </div>

          <!-- Terms and Conditions Acceptance -->
          <div class="mt-8 border-t border-gray-200 pt-6">
            <label class="flex items-start gap-3 cursor-pointer group">
              <input
                type="checkbox"
                v-model="formData.termsAccepted"
                class="rounded border-gray-300 text-primary focus:ring-primary mt-1 h-5 w-5"
                required
              />
              <div>
                <span class="text-sm text-gray-800">I agree to the</span>
                <a
                  href="#"
                  class="text-sm text-primary hover:underline ml-1 font-medium"
                  >Terms and Conditions</a
                >
                <span class="text-sm text-gray-800">,</span>
                <a
                  href="#"
                  class="text-sm text-primary hover:underline ml-1 font-medium"
                  >Privacy Policy</a
                >
                <span class="text-red-500 ml-0.5">*</span>
                <p
                  class="mt-1.5 text-sm text-gray-600 group-hover:text-gray-800 transition-colors"
                >
                  By posting, you confirm that this ad complies with our
                  policies and you own or have rights to the content you're
                  posting.
                </p>
              </div>
            </label>
            <p v-if="errors.termsAccepted" class="mt-2 text-red-500 text-sm">
              {{ errors.termsAccepted }}
            </p>
          </div>
        </div>

        <!-- Action Buttons -->
        <div class="px-8 py-5 bg-gray-50 border-t flex justify-between">
          <button
            v-if="currentStep > 0"
            type="button"
            class="px-6 py-2.5 border border-gray-300 rounded-md text-gray-800 hover:bg-gray-100 transition font-medium"
            @click="goToPreviousStep"
          >
            <Icon
              name="heroicons:arrow-left"
              class="w-5 h-5 mr-1.5 inline-block"
            />
            Previous
          </button>
          <div v-else></div>

          <button
            type="submit"
            class="bg-primary text-white px-8 py-2.5 rounded-md hover:bg-primary/90 transition font-medium shadow-sm"
            :disabled="isSubmitting"
          >
            <span v-if="isSubmitting" class="flex items-center">
              <Icon
                name="heroicons:arrow-path"
                class="animate-spin w-5 h-5 mr-1.5"
              />
              Processing...
            </span>
            <span
              v-else-if="currentStep < formSteps.length - 1"
              class="flex items-center"
            >
              Next
              <Icon name="heroicons:arrow-right" class="w-5 h-5 ml-1.5" />
            </span>
            <span v-else class="flex items-center">
              Post Sale
              <Icon name="heroicons:paper-airplane" class="w-5 h-5 ml-1.5" />
            </span>
          </button>
        </div>
      </form>
    </div>
  </div>
</template>

<script setup>
import { ref, reactive, computed, watch, onMounted } from "vue";
import { useSalePost } from "~/composables/useSalePost";
const { get } = useApi();

const { t } = useI18n();
const toast = useToast();
// Initialize composables
const {
  createSalePost,
  updateSalePost,
  loading: apiLoading,
  error: apiError,
} = useSalePost();

// Props definition
const props = defineProps({
  categories: {
    type: Array,
  },
  editPost: {
    type: Object,
    default: null,
  },
});

const allOverBangladesh = ref(false);

// Form data with simplified fields
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

// Child categories based on selected parent category
const childCategories = ref([]);

// Emit events
const emit = defineEmits(["post-saved"]);

// Success modal state
const showSuccessModal = ref(false);

// Multi-step form - simplified to 3 steps
const formSteps = ["Basic Info", "Price & Location", "Photos"];
const currentStep = ref(0);

const goToNextStep = () => {
  if (currentStep.value < formSteps.length - 1) {
    currentStep.value++;
  }
};

const goToPreviousStep = () => {
  if (currentStep.value > 0) {
    currentStep.value--;
  }
};

// Conditions for items
const conditions = ref([]);

// Load all available conditions from backend
const loadConditions = async () => {
  try {
    const response = await get("/sale/conditions/");
    if (response && Array.isArray(response.data)) {
      conditions.value = response.data.map((condition) => ({
        label: condition.name,
        value: condition.value,
        description: condition.description,
      }));
      console.log("Conditions loaded successfully:", conditions.value.length);
    } else {
      // Fallback to hardcoded conditions if API fails
      console.warn("API response invalid, using fallback conditions");
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
    console.warn("Using fallback conditions due to error");
    conditions.value = [
      { label: "Brand New", value: "brand-new" },
      { label: "Like New", value: "like-new" },
      { label: "Good", value: "good" },
      { label: "Fair", value: "fair" },
      { label: "For Parts", value: "for-parts" },
    ];
  }
};

// Location data
const regions = ref([]);
const cities = ref([]);
const upazilas = ref([]);

// Load regions (divisions)
const loadRegions = async () => {
  try {
    const regions_response = await get(
      `/geo/regions/?country_name_eng=Bangladesh`
    );
    regions.value = regions_response.data;
  } catch (error) {
    console.error("Error loading regions:", error);
  }
};

// Load regions on component mount
loadRegions();

// Load conditions on component mount
loadConditions();

// Watch for division change to load cities
watch(
  () => formData.division,
  async (newDivision) => {
    if (newDivision) {
      try {
        const cities_response = await get(
          `/geo/cities/?region_name_eng=${newDivision}`
        );
        cities.value = cities_response.data;
        formData.district = ""; // Reset district when division changes
        formData.area = ""; // Reset area when division changes
      } catch (error) {
        console.error("Error loading cities:", error);
      }
    } else {
      cities.value = [];
    }
  }
);

// Watch for district change to load areas (upazilas)
watch(
  () => formData.district,
  async (newDistrict) => {
    if (newDistrict) {
      try {
        const thana_response = await get(
          `/geo/upazila/?city_name_eng=${newDistrict}`
        );
        upazilas.value = thana_response.data;
      } catch (error) {
        console.error("Error loading upazilas:", error);
      }
    } else {
      upazilas.value = [];
    }
  }
);

// Status variables
const isSubmitting = computed(() => apiLoading.value);
const errors = reactive({});

// Watch for API errors and update local error state
watch(
  () => apiError.value,
  (newError) => {
    if (newError) {
      // Process validation errors from the API
      if (typeof newError === "object") {
        Object.keys(newError).forEach((key) => {
          errors[key] = Array.isArray(newError[key])
            ? newError[key][0]
            : newError[key];
        });
      } else {
        // Handle general error messages
        console.error("Error occurred:", newError);
      }
    }
  }
);

// Image preview URLs for display
const imagePreviewUrls = ref([]);

// File input references
const fileInputRefs = reactive({});

// Compression progress tracking
const isCompressing = ref(false);
const compressionProgress = ref(0);
const compressionStatus = ref("");

// Open file upload dialog
const openFileUpload = (index) => {
  if (fileInputRefs[`fileInput${index}`]) {
    fileInputRefs[`fileInput${index}`].click();
  }
};

// Handle file upload with compression
async function handleFileUpload(event, index) {
  const file = event.target.files[0];
  if (!file) return;

  // Validate file type
  if (!file.type.match("image.*")) {
    errors.images = "Please upload only image files";
    return;
  }

  // Validate file size (max 12MB)
  if (file.size > 12 * 1024 * 1024) {
    errors.images = "Image size should be less than 12MB";
    return;
  }

  isCompressing.value = true;
  compressionStatus.value = `Compressing ${file.name}...`;
  compressionProgress.value = 0;
  errors.images = "";
  try {
    // Update progress incrementally
    compressionProgress.value = 20;
    compressionStatus.value = "Analyzing image...";
    
    // Process image with compression
    const compressedImage = await processImageWithCompression(file);
    
    if (compressedImage) {
      compressionProgress.value = 80;
      compressionStatus.value = "Finalizing...";
      
      // Update preview URL and store compressed base64 data
      const newImagePreviewUrls = [...imagePreviewUrls.value];
      newImagePreviewUrls[index] = compressedImage;
      imagePreviewUrls.value = newImagePreviewUrls;

      // Store the compressed base64 data for API submission
      formData.images[index] = compressedImage;

      compressionStatus.value = "Compression completed!";
      compressionProgress.value = 100;

      // Log compression success
      const originalSize = formatFileSize(file.size);
      const compressedSize = Math.round((compressedImage.length * 3) / 4);
      console.log(`Image compressed successfully: ${originalSize} → ${formatFileSize(compressedSize)}`);

      // Hide compression indicator after a short delay
      setTimeout(() => {
        isCompressing.value = false;
      }, 1500);
    }
  } catch (error) {
    console.error("Error compressing image:", error);
    errors.images = "Failed to process image. Please try again.";
    isCompressing.value = false;
  }
}

// Remove image
function removeImage(index) {
  if (formData.images[index]) {
    // Update preview URLs
    const newImagePreviewUrls = [...imagePreviewUrls.value];
    newImagePreviewUrls[index] = null;
    imagePreviewUrls.value = newImagePreviewUrls;

    // Remove image from formData
    formData.images[index] = null;

    // Clear the file input value
    if (fileInputRefs[`fileInput${index}`]) {
      fileInputRefs[`fileInput${index}`].value = "";
    }

    // Clear any error
    errors.images = "";
  }
}

// Get category name
const getCategoryName = (categoryId) => {
  const category = props.categories.find((c) => c.id === categoryId);
  return category ? category.name : "";
};

// Handle parent category change - load child categories
const handleCategoryChange = async () => {
  formData.childCategory = ""; // Reset child category

  if (formData.category) {
    try {
      const response = await get(
        `/sale/child-categories/?parent_id=${formData.category}`
      );
      childCategories.value = response.data || [];
    } catch (error) {
      console.error("Error loading child categories:", error);
      childCategories.value = [];
    }
  } else {
    childCategories.value = [];
  }
};

// Validate current step
const validateStep = () => {
  // Reset errors for this step
  Object.keys(errors).forEach((key) => (errors[key] = ""));

  if (currentStep.value === 0) {
    // Validate basic details
    if (!formData.category) errors.category = "Please select a category";

    // Validate child category if options are available
    if (childCategories.value.length > 0 && !formData.childCategory) {
      errors.childCategory = "Please select a sub category";
    }

    if (!formData.title) errors.title = "Please enter a title";
    if (!formData.description)
      errors.description = "Please enter a description";
    if (!formData.condition) errors.condition = "Please select condition";

    if (
      !errors.category &&
      !errors.childCategory &&
      !errors.title &&
      !errors.description &&
      !errors.condition
    ) {
      goToNextStep();
    }
  } else if (currentStep.value === 1) {
    // Validate price and location
    if (!formData.negotiable && !formData.price) {
      errors.price = "Please enter a price or mark as negotiable";
    }

    // Additional validation for location fields
    if (!allOverBangladesh.value) {
      if (!formData.division || !formData.district || !formData.area) {
        console.error("Location validation failed:", {
          division: formData.division,
          district: formData.district,
          area: formData.area,
          allOverBangladesh: allOverBangladesh.value
        });
        const toast = useToast();
        toast.add({
          title: "Validation Error",
          description: "Please select division, district, and area when not targeting all over Bangladesh",
          color: "red",
          timeout: 5000,
        });
        return;
      }
    }
    if (!formData.detailedAddress)
      errors.detailedAddress = "Please enter detailed address";
    if (!formData.phone) errors.phone = "Please enter phone number";

    if (
      !errors.price &&
      !errors.division &&
      !errors.district &&
      !errors.area &&
      !errors.detailedAddress &&
      !errors.phone
    ) {
      goToNextStep();
    }
  } else if (currentStep.value === 2) {
    // Check if at least one image is uploaded
    if (!formData.images.some((img) => img)) {
      errors.images = "Please upload at least one image";
      return;
    }

    // Validate terms acceptance
    if (!formData.termsAccepted) {
      errors.termsAccepted = "You must accept the terms and conditions";
      return;
    }

    // Submit the form if all validations pass
    if (!errors.images && !errors.termsAccepted) {
      submitForm();
    }
  }
};

const submitForm = async () => {
  // Check if already submitting to prevent duplicate submissions
  if (isSubmitting.value) {
    console.log(
      "Form submission already in progress, preventing duplicate submission"
    );
    return;
  }
  
  try {
    console.log("Starting form submission process...");
    
    // Clear all previous errors at the start of submission
    Object.keys(errors).forEach((key) => (errors[key] = ""));    // Wait for conditions to be loaded if they're not ready yet
    if (conditions.value.length === 0) {
      console.log("Conditions not loaded yet, loading them now...");
      try {
        await loadConditions();
        
        // Wait a bit more to ensure they're properly set
        if (conditions.value.length === 0) {
          console.error("Failed to load conditions, cannot proceed");
          const toast = useToast();
          toast.add({
            title: "Initialization Error",
            description: "Form data is still loading. Please try again in a moment.",
            color: "red",
            timeout: 5000,
          });
          return;
        }
      } catch (conditionError) {
        console.error("Error loading conditions:", conditionError);
        const toast = useToast();
        toast.add({
          title: "Loading Error",
          description: "Failed to load required form data. Please refresh the page.",
          color: "red",
          timeout: 5000,
        });
        return;
      }
    }

    // Validate condition is from available options
    const validCondition = conditions.value.find(c => c.value === formData.condition);
    if (!validCondition) {
      console.error("Invalid condition selected:", formData.condition);
      console.error("Available conditions:", conditions.value.map(c => c.value));
      const toast = useToast();
      toast.add({
        title: "Validation Error",
        description: "Please select a valid condition from the available options",
        color: "red",
        timeout: 5000,
      });
      return;
    }// Validate all required fields before submission
    const requiredFields = {
      category: formData.category,
      title: formData.title?.trim(),
      description: formData.description?.trim(),
      condition: formData.condition,
      // When "All over Bangladesh" is selected, location fields are optional, otherwise they're required
      division: allOverBangladesh.value ? "optional" : formData.division,
      district: allOverBangladesh.value ? "optional" : formData.district,
      area: allOverBangladesh.value ? "optional" : formData.area,
      detailed_address: formData.detailedAddress?.trim(),
      phone: formData.phone?.trim()
    };// Check for missing required fields
    const missingFields = [];
    Object.entries(requiredFields).forEach(([key, value]) => {
      if (value !== "optional" && (!value || value === '')) {
        missingFields.push(key);
      }
    });

    if (missingFields.length > 0) {
      console.error("Missing required fields:", missingFields);
      const toast = useToast();
      toast.add({
        title: "Validation Error",
        description: `Missing required fields: ${missingFields.join(', ')}`,
        color: "red",
        timeout: 5000,
      });
      return;
    }    // Prepare form data as a regular object (not FormData)
    const formDataObj = {
      category: parseInt(formData.category), // Ensure category is always integer
      title: formData.title.trim(), // Trim whitespace
      description: formData.description.trim(), // Trim whitespace
      condition: formData.condition, // String value from condition model
      // Handle location fields - when "All over Bangladesh" is selected, omit location fields as they're optional
      division: allOverBangladesh.value ? "" : formData.division,
      district: allOverBangladesh.value ? "" : formData.district,
      area: allOverBangladesh.value ? "" : formData.area,
      detailed_address: formData.detailedAddress.trim(), // Trim whitespace
      phone: formData.phone.trim(), // Trim whitespace
      negotiable: Boolean(formData.negotiable), // Ensure boolean type
    };

    // Debug condition value
    console.log("Condition value being sent:", formData.condition);
    console.log("Available conditions:", conditions.value);    // Add optional fields only if they have values
    if (formData.childCategory) {
      formDataObj.child_category = parseInt(formData.childCategory);
    }

    if (formData.email && formData.email.trim()) {
      formDataObj.email = formData.email.trim();
    }

    // Validate category is a valid integer
    if (!formDataObj.category || isNaN(formDataObj.category)) {
      console.error("Invalid category ID:", formData.category);
      const toast = useToast();
      toast.add({
        title: "Validation Error",
        description: "Please select a valid category",
        color: "red",
        timeout: 5000,
      });
      return;
    }// Handle price - always include price field for validation, but handle null case properly
    if (formData.negotiable) {
      // When negotiable, price can be null, but still send the field
      formDataObj.price = formData.price && formData.price !== '' ? parseFloat(formData.price) : null;
    } else {
      // When not negotiable, price is required and must be > 0
      if (!formData.price || formData.price === '' || parseFloat(formData.price) <= 0) {
        console.error("Valid price is required when not negotiable");
        const toast = useToast();
        toast.add({
          title: "Validation Error",
          description: "Please enter a valid price when item is not negotiable",
          color: "red",
          timeout: 5000,
        });
        return;
      }
      formDataObj.price = parseFloat(formData.price);
    }

    // Validate that either price or negotiable is set
    if (!formData.negotiable && (!formData.price || formData.price === '')) {
      console.error("Either price must be provided or item must be marked as negotiable");
      const toast = useToast();
      toast.add({
        title: "Validation Error",
        description: "Either provide a price or mark the item as negotiable",
        color: "red",
        timeout: 5000,
      });
      return;
    }// Filter and process images - ensure they're valid base64 strings and limit to 4 images
    const validImages = formData.images.filter((img) => img && typeof img === 'string').slice(0, 4);
    
    if (validImages.length > 0) {
      // Log image details for debugging
      console.log(`Processing ${validImages.length} images for submission:`);
      let totalImageSize = 0;
      validImages.forEach((img, index) => {
        const sizeEstimate = Math.round((img.length * 3) / 4);
        totalImageSize += sizeEstimate;
        console.log(`Image ${index + 1}: ${formatFileSize(sizeEstimate)}`);
        
        // Check if individual image is too large (over 200KB after compression)
        if (sizeEstimate > 200 * 1024) {
          console.warn(`Image ${index + 1} is still large after compression: ${formatFileSize(sizeEstimate)}`);
        }
      });
      
      console.log(`Total images size: ${formatFileSize(totalImageSize)}`);
      
      // Check total payload size
      if (totalImageSize > 800 * 1024) { // 800KB limit for all images combined
        throw new Error("Images are too large. Please use fewer or smaller images.");
      }
      
      formDataObj.images = validImages;
    }

    // Enhanced debugging - log all form data before submission
    console.log("=== FORM SUBMISSION DEBUG ===");
    console.log("Raw form data:", {
      category: formData.category,
      childCategory: formData.childCategory,
      title: formData.title,
      description: formData.description?.substring(0, 50) + "...",
      condition: formData.condition,
      price: formData.price,
      negotiable: formData.negotiable,
      division: formData.division,
      district: formData.district,
      area: formData.area,
      detailedAddress: formData.detailedAddress?.substring(0, 50) + "...",
      phone: formData.phone,
      email: formData.email,
      images: formData.images?.filter(img => img)?.length || 0,
      allOverBangladesh: allOverBangladesh.value
    });
    
    // Debug conditions
    console.log("Condition validation:");
    console.log("- Selected condition:", formData.condition);
    console.log("- Available conditions:", conditions.value.map(c => ({ value: c.value, label: c.label })));
    
    // Debug category
    console.log("Category validation:");
    console.log("- Selected category:", formData.category, typeof formData.category);
    console.log("- Selected child category:", formData.childCategory, typeof formData.childCategory);
    
    // Log the final payload (without images for readability)
    const logPayload = { ...formDataObj };
    if (logPayload.images) {
      logPayload.images = `[${logPayload.images.length} images - total size: ${formatFileSize(logPayload.images.reduce((total, img) => total + Math.round((img.length * 3) / 4), 0))}]`;
    }
    console.log("Final submission payload:", logPayload);
    console.log("Payload size estimate:", JSON.stringify(logPayload).length, "bytes");
    console.log("=== END DEBUG ===");
    
    // Ensure all reactive changes have settled
    await nextTick();
    
    // Small delay to ensure form state is stable
    await new Promise(resolve => setTimeout(resolve, 100));    let result;
    if (props.editPost) {
      result = await updateSalePost(props.editPost.id, formDataObj);
    } else {
      result = await createSalePost(formDataObj);
      showSuccessModal.value = true;

      // Auto-close modal after 3 seconds
      setTimeout(() => {
        closeSuccessModal();
      }, 3000);
    }

    console.log("Server response:", result);
    emit("post-saved", result);  } catch (error) {
    console.error("Error submitting form:", error);
    
    // Enhanced error handling with detailed logging
    console.error("Full error object:", JSON.stringify(error, null, 2));
    
    let errorMessage = "Failed to submit your listing. Please try again.";
    
    if (error && typeof error === 'object') {
      // Check if it's a network error
      if (error.code === 'NETWORK_ERROR' || error.message?.includes('network')) {
        errorMessage = "Network error. Please check your internet connection and try again.";
      }      // Check if it's a server validation error
      else if (error.response && error.response.status) {
        console.error("Server error status:", error.response.status);
        console.error("Server error data:", error.response.data);
        
        if (error.response.status === 400) {
          // Try to extract specific validation errors
          if (error.response.data && typeof error.response.data === 'object') {
            const validationErrors = [];
            Object.entries(error.response.data).forEach(([field, fieldErrors]) => {
              if (Array.isArray(fieldErrors)) {
                validationErrors.push(`${field}: ${fieldErrors.join(', ')}`);
              } else {
                validationErrors.push(`${field}: ${fieldErrors}`);
              }
            });
            
            if (validationErrors.length > 0) {
              errorMessage = `Validation failed: ${validationErrors.join('; ')}`;
            } else {
              errorMessage = "Invalid data submitted. Please check your inputs and try again.";
            }
          } else {
            errorMessage = `Validation error: ${error.response.data?.detail || error.response.data || 'Invalid data submitted'}`;
          }
        } else if (error.response.status === 401) {
          errorMessage = "You need to be logged in to submit a listing.";
        } else if (error.response.status === 413) {
          errorMessage = "Request too large. Please use smaller images.";
        } else if (error.response.status >= 500) {
          errorMessage = "Server error. Please try again later.";
        } else {
          errorMessage = `Server error (${error.response.status}): ${error.response.data?.message || error.response.data?.detail || 'Unknown error'}`;
        }
      }
      // Check for specific field errors
      else if (error.images) {
        errorMessage = "Image upload failed. Please try with smaller images or fewer images.";
      } else if (error.message) {
        errorMessage = error.message;
      }
    } else if (typeof error === 'string') {
      errorMessage = error;
    }
    
    console.error("Final error message:", errorMessage);
    
    const toast = useToast();
    toast.add({
      title: "Error",
      description: errorMessage,
      color: "red",
      timeout: 8000,
    });
  }
};

// Close success modal and reset form
const closeSuccessModal = () => {
  showSuccessModal.value = false;
  resetForm();

  toast.add({
    title: "Success!",
    description:
      "Your listing has been submitted successfully and is under review.",
    color: "green",
  });
};

// Reset form to initial state
const resetForm = () => {
  // Reset all form fields
  Object.keys(formData).forEach((key) => {
    if (key === "termsAccepted") {
      formData[key] = false;
    } else if (key === "negotiable") {
      formData[key] = false;
    } else if (key === "images") {
      formData[key] = [];
    } else {
      formData[key] = "";
    }
  });

  // Clean up image previews
  imagePreviewUrls.value = [];

  // Reset file inputs
  Object.keys(fileInputRefs).forEach((key) => {
    if (fileInputRefs[key]) {
      fileInputRefs[key].value = "";
    }
  });

  // Reset errors
  Object.keys(errors).forEach((key) => {
    errors[key] = "";
  });

  // Reset child categories
  childCategories.value = [];

  // Go back to first step
  currentStep.value = 0;
};

// Load edit data if available
onMounted(() => {
  if (props.editPost) {
    populateFormWithEditData();
  }
});

// Watch for changes in edit post data
watch(
  () => props.editPost,
  (newEditPost) => {
    if (newEditPost) {
      populateFormWithEditData();
    }
  }
);

// Populate form with edit data
const populateFormWithEditData = async () => {
  const post = props.editPost;
  if (!post) return;

  // Load child categories
  if (post.category) {
    try {
      const response = await get(
        `/sale/child-categories/?parent_id=${post.category}`
      );
      childCategories.value = response.data || [];
    } catch (error) {
      console.error("Error loading child categories:", error);
    }
  }

  // Basic fields
  formData.category = post.category;
  formData.childCategory = post.child_category || "";
  formData.title = post.title;
  formData.description = post.description;
  formData.condition = post.condition;
  formData.price = post.price;
  formData.negotiable = post.negotiable || false;

  // Location fields
  formData.division = post.division;
  formData.district = post.district;
  formData.area = post.area;
  formData.detailedAddress = post.detailed_address;

  // Contact info
  formData.phone = post.phone;
  formData.email = post.email;

  // Set existing images if available
  if (post.images && Array.isArray(post.images)) {
    post.images.forEach((image, index) => {
      if (index < 8) {
        // Maximum 8 images
        const imageUrl = image.image || image;
        imagePreviewUrls.value[index] = imageUrl;
        // For editing, we just need to display the existing images
        // The backend already has them, so we don't need to upload them again
        formData.images[index] = imageUrl;
      }
    });
  }

  // Accept terms by default when editing
  formData.termsAccepted = true;
};

function updateContent(p) {
  formData.description = p;
}

// Advanced image compression function
const processImageWithCompression = (file) => {
  return new Promise((resolve, reject) => {
    const reader = new FileReader();

    reader.onload = (e) => {
      const img = new Image();

      img.onload = () => {
        try {
          // Apply advanced compression
          const compressedImage = performAdvancedCompression(img, file.size);
          resolve(compressedImage);
        } catch (error) {
          console.error(`Error compressing image ${file.name}:`, error);
          reject(error);
        }
      };

      img.onerror = () => {
        reject(new Error(`Invalid image: ${file.name}`));
      };

      img.src = e.target.result;
    };

    reader.onerror = reject;
    reader.readAsDataURL(file);
  });
};

// Advanced compression algorithm with enhanced optimization
const performAdvancedCompression = (img, originalFileSize) => {
  const canvas = document.createElement("canvas");
  const ctx = canvas.getContext("2d");
  
  // Enable image smoothing for better quality
  ctx.imageSmoothingEnabled = true;
  ctx.imageSmoothingQuality = "high";
  
  // Get optimized settings based on image characteristics
  const settings = optimizeCompressionSettings(originalFileSize, img.width, img.height);
  
  let width = img.width;
  let height = img.height;

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

  // Apply advanced preprocessing for better compression
  preprocessImageForCompression(canvas, ctx, width, height);

  // Progressive compression with quality optimization
  let quality = settings.initialQuality;
  let resultImage = canvas.toDataURL("image/jpeg", quality);
  let resultSize = Math.round((resultImage.length * 3) / 4);
  
  // Phase 1: Gentle quality reduction with fine increments
  while (resultSize > settings.targetSize && quality > settings.minQuality + 0.1) {
    quality -= 0.01;
    resultImage = canvas.toDataURL("image/jpeg", quality);
    resultSize = Math.round((resultImage.length * 3) / 4);
  }

  // Phase 2: Moderate quality reduction if still over target
  while (resultSize > settings.targetSize && quality > settings.minQuality + 0.05) {
    quality -= 0.02;
    resultImage = canvas.toDataURL("image/jpeg", quality);
    resultSize = Math.round((resultImage.length * 3) / 4);
  }

  // Phase 3: Smart dimensional reduction if quality limit reached
  if (resultSize > settings.targetSize && quality <= settings.minQuality + 0.05) {
    const scaleFactor = Math.sqrt(settings.targetSize / resultSize) * 0.90;
    const newWidth = Math.max(300, Math.round(width * scaleFactor));
    const newHeight = Math.max(300, Math.round(height * scaleFactor));

    if (newWidth >= width * 0.6 && newHeight >= height * 0.6) {
      canvas.width = newWidth;
      canvas.height = newHeight;
      
      ctx.imageSmoothingEnabled = true;
      ctx.imageSmoothingQuality = "high";
      ctx.filter = "contrast(1.05) saturate(1.02)";
      ctx.drawImage(img, 0, 0, newWidth, newHeight);
      ctx.filter = "none";

      quality = Math.max(settings.minQuality + 0.10, 0.65);
      resultImage = canvas.toDataURL("image/jpeg", quality);
      resultSize = Math.round((resultImage.length * 3) / 4);

      while (resultSize > settings.targetSize && quality > settings.minQuality) {
        quality -= 0.015;
        resultImage = canvas.toDataURL("image/jpeg", quality);
        resultSize = Math.round((resultImage.length * 3) / 4);
      }
    }
  }

  // Final fallback: Try WebP format if supported
  if (resultSize > settings.targetSize * 1.2) {
    try {
      const webpImage = canvas.toDataURL("image/webp", quality);
      const webpSize = Math.round((webpImage.length * 3) / 4);
      
      if (webpSize < resultSize * 0.8) {
        return webpImage;
      }
    } catch (e) {
      // WebP not supported, continue with JPEG
    }
  }

  return resultImage;
};

// Advanced pre-processing for optimal compression
const preprocessImageForCompression = (canvas, ctx, width, height) => {
  const imageData = ctx.getImageData(0, 0, width, height);
  const data = imageData.data;
  
  // Simple noise reduction while preserving edges
  for (let i = 0; i < data.length; i += 4) {
    const r = data[i];
    const g = data[i + 1];
    const b = data[i + 2];
    
    data[i] = Math.round(r * 0.98 + (r > 200 ? 2 : 0));
    data[i + 1] = Math.round(g * 0.98 + (g > 200 ? 2 : 0));
    data[i + 2] = Math.round(b * 0.98 + (b > 200 ? 2 : 0));
  }
  
  ctx.putImageData(imageData, 0, 0);
};

// Optimize compression settings based on image characteristics - More aggressive compression
const optimizeCompressionSettings = (fileSize, imageWidth, imageHeight) => {
  const settings = {
    maxDimension: 1200, // Reduced from 1920
    targetSize: 60 * 1024, // Reduced to 60KB target
    initialQuality: 0.75, // Reduced from 0.82
    minQuality: 0.40, // Reduced from 0.55
  };

  // Adjust for large files (>5MB) - very aggressive compression
  if (fileSize > 5 * 1024 * 1024) {
    settings.maxDimension = 1000; // Reduced from 1600
    settings.targetSize = 50 * 1024; // Reduced to 50KB for large files
    settings.initialQuality = 0.65; // Reduced from 0.78
    settings.minQuality = 0.35; // Reduced from 0.50
  }

  // Adjust for very large images (>4000px) - prioritize size reduction
  if (imageWidth > 4000 || imageHeight > 4000) {
    settings.maxDimension = 800; // Reduced from 1400
    settings.targetSize = 40 * 1024; // Reduced to 40KB
    settings.initialQuality = 0.60; // Reduced from 0.72
    settings.minQuality = 0.30; // Reduced from 0.45
  }

  // Adjust for small files (<1MB) - maintain quality while achieving tiny size
  if (fileSize < 1024 * 1024) {
    settings.targetSize = 50 * 1024; // Reduced to 50KB for small files
    settings.minQuality = 0.45; // Reduced from 0.60
    settings.initialQuality = 0.70; // Reduced from 0.85
  }

  // Special handling for mobile photos (typical sizes) - very aggressive
  if (imageWidth >= 3000 && imageHeight >= 4000) {
    settings.maxDimension = 800; // Reduced from 1080
    settings.targetSize = 45 * 1024; // Reduced to 45KB
    settings.initialQuality = 0.60; // Reduced from 0.75
  }

  return settings;
};

// Utility function to format file sizes
const formatFileSize = (bytes) => {
  if (bytes === 0) return '0 Bytes';
  const k = 1024;
  const sizes = ['Bytes', 'KB', 'MB', 'GB'];
  const i = Math.floor(Math.log(bytes) / Math.log(k));
  return parseFloat((bytes / Math.pow(k, i)).toFixed(1)) + ' ' + sizes[i];
};
</script>

<style scoped>
.fade-transition {
  transition: all 0.3s ease;
}

/* Fix for number input spinner buttons */
input[type="number"]::-webkit-inner-spin-button,
input[type="number"]::-webkit-outer-spin-button {
  -webkit-appearance: none;
  appearance: none;
  margin: 0;
}
input[type="number"] {
  -moz-appearance: textfield;
  appearance: textfield;
}

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
