<template>
  <PublicSection>
    <div class="min-h-screen py-8 bg-gradient-to-b from-gray-50 to-gray-100">
      <UContainer>
        <!-- Enhanced Header -->
        <div class="text-center mb-10">
          <h1
            class="text-2xl font-semibold mb-2 bg-gradient-to-r from-emerald-500 to-green-600 bg-clip-text text-transparent"
          >
            {{ $t("post_classified") }}
          </h1>
          <p class="text-lg text-gray-500 max-w-lg mx-auto">
            {{ $t("post_classified_text") }}
          </p>
        </div>

        <form
          action="#"
          class="bg-white rounded-xl shadow-sm max-w-3xl mx-auto overflow-hidden border border-gray-100"
          @submit.prevent="handlePostGig"
        >
          <!-- Primary Details Section -->
          <div
            class="p-3 border-b border-gray-100 hover:bg-gray-50 transition-colors duration-300"
          >
            <h2
              class="text-xl font-semibold text-gray-700 mb-6 flex items-center gap-2"
            >
              <UIcon
                name="i-heroicons-document-text"
                class="text-emerald-600"
              />
              {{ $t("basic_details") }}
            </h2>

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
                option-attribute="title"
                value-attribute="id"
              />
            </UFormGroup>

            <UFormGroup
              label="Title"
              required
              :error="!form.title && checkSubmit && 'You must enter a title!'"
              class="mb-5"
            >
              <UInput
                type="text"
                size="md"
                color="white"
                class="w-full border-gray-200 focus:border-emerald-500 focus:ring focus:ring-emerald-100 transition-all"
                placeholder="Enter a descriptive title for your classified ad"
                v-model="form.title"
              >
                <template #leading>
                  <UIcon name="i-heroicons-pencil-square" />
                </template>
              </UInput>
            </UFormGroup>

            <UFormGroup label="Description" required class="mb-5">
              <p class="text-sm text-gray-500 mb-3">
                Provide detailed information about your listing
              </p>
              <div
                class="border border-gray-200 rounded-lg overflow-hidden focus-within:ring-2 focus-within:ring-emerald-100 focus-within:border-emerald-500 transition-all"
              >
                <CommonEditor
                  v-if="router.query.id && form.instructions"
                  :content="form.instructions"
                  @updateContent="
                    (content) => {
                      form.instructions = content;
                    }
                  "
                />
                <CommonEditor
                  v-else
                  v-model="form.instructions"
                  @updateContent="updateContent"
                />
              </div>
            </UFormGroup>
          </div>

          <!-- Pricing Section -->
          <div
            class="p-2 md:p-7 border-b border-gray-100 hover:bg-gray-50 transition-colors duration-300"
          >
            <h2
              class="text-xl font-semibold text-gray-700 mb-6 flex items-center gap-2"
            >
              <UIcon
                name="i-heroicons-currency-dollar"
                class="text-emerald-600"
              />
              {{ $t("pricing") }}
            </h2>

            <UFormGroup
              label="Price"
              :error="
                form.price <= 0 &&
                !form.negotiable &&
                checkSubmit &&
                'Price must be greater than 0 or Negotiable'
              "
              class="mb-5"
            >
              <div class="flex flex-wrap items-center gap-4">
                <UInput
                  type="text"
                  size="md"
                  color="white"
                  :disabled="form.negotiable"
                  placeholder="e.g. 1000"
                  class="w-40 sm:flex-grow-0 border-gray-200 focus:border-emerald-500 focus:ring focus:ring-emerald-100 transition-all"
                  v-model="form.price"
                >
                  <template #leading>
                    <UIcon name="i-mdi:currency-bdt" />
                  </template>
                </UInput>

                <div class="flex items-center">
                  <UCheckbox
                    v-model="form.negotiable"
                    name="Negotiable"
                    label="Negotiable"
                  />
                </div>
              </div>
            </UFormGroup>
          </div>

          <!-- Media Upload Section -->
          <div
            class="p-2 md:p-7 border-b border-gray-100 hover:bg-gray-50 transition-colors duration-300"
          >
            <h2
              class="text-xl font-semibold text-gray-700 mb-6 flex items-center gap-2"
            >
              <UIcon name="i-heroicons-photo" class="text-emerald-600" />
              {{ $t("media_gallary") }}
            </h2>
            <p class="text-sm text-gray-500 mb-4">
              Add photos to showcase your listing (up to 5 images)
            </p>

            <div class="flex flex-wrap gap-4 mt-4">
              <!-- Uploaded images -->
              <div
                v-for="(img, i) in form.medias"
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
                v-if="form.medias.length < 5"
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

          <!-- Location Section -->
          <div
            class="p-2 md:p-7 border-b border-gray-100 hover:bg-gray-50 transition-colors duration-300"
          >
            <h2
              class="text-xl font-semibold text-gray-700 mb-6 flex items-center gap-2"
            >
              <UIcon name="i-heroicons-map-pin" class="text-emerald-600" />
              {{ $t("location") }}
            </h2>

            <UCheckbox
              v-model="allOverBangladesh"
              name="all-bangladesh"
              :label="
                t('all_over_bangladesh') ||
                'Show content from all over Bangladesh'
              "
              color="primary"
            />

            <div
              class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 mt-3"
              v-if="!allOverBangladesh"
            >
              <UFormGroup
                label="State"
                :error="
                  !form.state && checkSubmit && 'You must select a state!'
                "
                class="mb-5"
              >
                <USelectMenu
                  v-model="form.state"
                  color="white"
                  size="md"
                  :options="regions"
                  placeholder="Select State"
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
                label="City"
                :error="!form.city && checkSubmit && 'You must select a city'"
                class="mb-5"
              >
                <USelectMenu
                  v-model="form.city"
                  color="white"
                  size="md"
                  :options="cities"
                  placeholder="Select City"
                  class="w-full border-gray-200 focus:border-emerald-500 focus:ring focus:ring-emerald-100 transition-all"
                  option-attribute="name_eng"
                  value-attribute="name_eng"
                  :disabled="!form.state"
                >
                  <template #leading>
                    <UIcon name="i-heroicons-building-office-2" />
                  </template>
                </USelectMenu>
              </UFormGroup>

              <UFormGroup
                label="Area/Upazila"
                :error="
                  !form.upazila &&
                  checkSubmit &&
                  'You must select a Area/Upazila'
                "
                class="mb-5"
              >
                <USelectMenu
                  v-model="form.upazila"
                  color="white"
                  size="md"
                  :options="upazilas"
                  placeholder="Select Area/Upazila"
                  class="w-full border-gray-200 focus:border-emerald-500 focus:ring focus:ring-emerald-100 transition-all"
                  option-attribute="name_eng"
                  value-attribute="name_eng"
                  :disabled="!form.city"
                >
                  <template #leading>
                    <UIcon name="i-heroicons-map-pin" />
                  </template>
                </USelectMenu>
              </UFormGroup>
            </div>

            <UFormGroup
              label="Detailed Address"
              required
              :error="
                !form.location && checkSubmit && 'You must enter your address!'
              "
              class="mb-5"
              :class="allOverBangladesh ? 'mt-3' : 'mt-0'"
            >
              <UTextarea
                v-model="form.location"
                color="white"
                variant="outline"
                class="w-full min-h-20 border-gray-200 focus:border-emerald-500 focus:ring focus:ring-emerald-100 transition-all"
                resize
                placeholder="Enter your complete address (e.g., 1216-Mirpur, Dhaka)"
              />
            </UFormGroup>
          </div>

          <!-- Terms Section -->
          <div class="p-2 md:p-7 bg-gray-50">
            <UCheckbox name="terms_privacy" v-model="form.accepted_privacy">
              <template #label>
                <span class="text-gray-500 text-sm">
                  I agree to the
                  <NuxtLink
                    to="/terms"
                    class="text-emerald-600 font-medium underline hover:text-emerald-700"
                    >Terms & Conditions</NuxtLink
                  >
                  and
                  <NuxtLink
                    to="/privacy"
                    class="text-emerald-600 font-medium underline hover:text-emerald-700"
                    >Privacy Policy</NuxtLink
                  >
                </span>
              </template>
            </UCheckbox>

            <p
              v-if="!form.accepted_privacy && checkSubmit"
              class="text-red-500 text-sm mt-2"
            >
              You must accept our Terms & Conditions and Privacy Policy
            </p>

            <div class="flex justify-center mt-6">
              <UButton
                :loading="isLoading"
                class="min-w-48 px-8 py-3 font-semibold transform hover:-translate-y-1 hover:shadow-sm transition-all duration-300"
                size="lg"
                color="primary"
                variant="solid"
                type="submit"
              >
                <template #leading>
                  <UIcon name="i-heroicons-paper-airplane" />
                </template>
                {{ $t("post_classified_ad") }}
              </UButton>
            </div>
          </div>
        </form>

        <!-- KYC Modal -->
        <UModal v-model="isOpen">
          <div class="p-8 flex flex-col items-center text-center">
            <div
              class="w-20 h-20 bg-amber-50 rounded-full flex items-center justify-center mb-5"
            >
              <UIcon
                name="i-heroicons-shield-exclamation"
                class="h-12 w-12 text-amber-500"
              />
            </div>

            <h2 class="text-xl font-semibold text-gray-700 mb-4">
              KYC Verification Required
            </h2>
            <p class="text-gray-500 mb-6 max-w-md leading-relaxed">
              To ensure trust and safety in our marketplace, we require identity
              verification before posting ads.
            </p>

            <UButton
              size="lg"
              color="primary"
              variant="solid"
              to="/upload-center"
              class="min-w-48"
            >
              <template #leading>
                <UIcon name="i-heroicons-identification" />
              </template>
              Complete Verification
            </UButton>
          </div>
        </UModal>
      </UContainer>
    </div>
  </PublicSection>
</template>

<script setup>
definePageMeta({
  layout: "dashboard",
});
const { t } = useI18n();
const isOpen = ref(false);
const { get, post, put, baseURL } = useApi();
const { user } = useAuth();
const toast = useToast();
const categories = ref([]);
const checkSubmit = ref(false);
const isLoading = ref(false);
const allOverBangladesh = ref(false);

const form = ref({
  price: 0,
  instructions: "",
  title: "",
  medias: [],
  category: "",
  country: "Bangladesh",
  state: "",
  city: "",
  location: "",
  negotiable: false,
  accepted_privacy: false,
});
function updateContent(p) {
  form.value.instructions = p;
}
const submitValues = ref({});

const router = useRoute();

async function fetchServices() {
  const response = await $fetch(
    `${baseURL}/classified-categories/post/${router.query.id}/`
  );
  console.log(response);
  const {
    price,
    instructions,
    title,
    medias,
    category,
    country,
    state,
    city,
    upazila,
    location,
    negotiable,
    accepted_privacy,
    service_status,
  } = response;
  form.value = {
    price,
    instructions,
    title,
    medias,
    category,
    country,
    state,
    city,
    upazila,
    location,
    negotiable,
    accepted_privacy,
    service_status,
  };
}

function validateForm() {
  // Determine the base submit values based on conditions
  const { negotiable, price, ...rest } = form.value;
  submitValues.value = negotiable
    ? { ...rest, negotiable }
    : { ...rest, price };
  const { state, city, upazila, ...filetered } = submitValues.value;
  // Validate each field in submitValues
  for (const key in filetered) {
    const value = filetered[key];
    if (
      (typeof value === "string" && !value.trim()) || // Check empty strings
      (typeof value === "boolean" && !value) //|| // Check false booleans
      //(Array.isArray(value) && value.length === 0) // Check empty arrays
    ) {
      return false; // Validation fails
    }
  }

  return true; // Validation succeeds
}

async function handlePostGig() {
  if (!validateForm()) {
    checkSubmit.value = true;
    toast.add({ title: "Please fill in all required fields." });
    return;
  }
  isLoading.value = true;
  const { medias, ...rest } = form.value;
  console.log(form.value);
  rest.service_status = "pending";

  const res = await (router.query.id
    ? put(`/update-user-classified-post/${router.query.id}/`, form.value)
    : post("/classified-categories-post/", submitValues.value));
  if (res.data) {
    navigateTo("/my-classified-services/");
    toast.add({ title: "Classified Service Added" });
  }
  isLoading.value = false;
}

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

// Replace with this improved version for better reactivity
function deleteUpload(ind) {
  if (ind >= 0 && ind < form.value.medias.length) {
    // Create a new array without the deleted item to maintain reactivity
    form.value.medias = form.value.medias.filter((_, i) => i !== ind);
    uploadError.value = ""; // Clear any error messages
  }
}

async function getMicroGigsCategory() {
  try {
    const [categoriesResponse] = await Promise.all([
      get("/classified-categories-all/"),
    ]);
    categories.value = categoriesResponse.data;
    console.log(categoriesResponse.data);
  } catch (error) {
    console.error("Error fetching micro-gigs data:", error);
  }
}

onMounted(() => {
  getMicroGigsCategory();
  console.log(router.query.id);

  if (router.query.id) {
    fetchServices();
  }
});

// geo filter

const regions = ref([]);
const cities = ref([]);
const upazilas = ref([]);

const regions_response = await get(
  `/geo/regions/?country_name_eng=${form.value.country}`
);
regions.value = regions_response.data;

watch(
  () => form.value.state,
  async (newState) => {
    console.log(newState);
    if (newState) {
      const cities_response = await get(
        `/geo/cities/?region_name_eng=${newState}`
      );
      cities.value = cities_response.data;
      console.log(cities_response.data);
    }
  }
);

watch(
  () => form.value.city,
  async (newCity) => {
    console.log(newCity);
    if (newCity) {
      const thana_response = await get(
        `/geo/upazila/?city_name_eng=${newCity}`
      );
      upazilas.value = thana_response.data;
      console.log(thana_response.data);
    }
  }
);

// geo filter
</script>

<style scoped>
/* All styling is now handled through Tailwind classes in the template */
</style>
