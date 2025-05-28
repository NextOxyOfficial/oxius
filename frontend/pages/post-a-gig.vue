<template>
  <PublicSection>
    <div class="min-h-screen py-8 bg-gradient-to-b from-gray-50 to-gray-100">
      <UContainer>
        <!-- Enhanced Header -->
        <div class="text-center mb-10">
          <h1
            class="text-2xl font-semibold mb-2 bg-gradient-to-r from-emerald-500 to-green-600 bg-clip-text text-transparent"
          >
            {{ $t("post_gigs") }}
          </h1>
          <p class="text-lg text-gray-600 max-w-lg mx-auto">
            Create a new micro-gig and reach potential customers
          </p>
        </div>

        <form
          action="#"
          class="bg-white rounded-xl shadow-sm max-w-3xl mx-auto overflow-hidden border border-gray-100"
        >
          <!-- Primary Details Section -->
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
              Basic Details
            </h2>

            <UFormGroup
              label="Category"
              required
              :error="
                !form.category && checkSubmit && 'You must select a category!'
              "
              class="mb-5"
            >
              <USelectMenu
                v-model="form.category"
                color="white"
                size="md"
                :options="categories"
                placeholder="Target Category"
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
                placeholder="Title"
                v-model="form.title"
                class="w-full border-gray-200 focus:border-emerald-500 focus:ring focus:ring-emerald-100 transition-all"
              >
                <template #leading>
                  <UIcon name="i-heroicons-pencil-square" />
                </template>
              </UInput>
            </UFormGroup>
          </div>

          <!-- Pricing Section -->
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
              Pricing & Quantity
            </h2>

            <div class="grid grid-cols-1 sm:grid-cols-2 gap-5">
              <UFormGroup
                label="Budget Per Action"
                required
                :error="
                  form.price <= 0 &&
                  checkSubmit &&
                  'You must enter budget per action!'
                "
                class="mb-5"
              >
                <UInput
                  type="text"
                  size="md"
                  color="white"
                  placeholder="2.0"
                  class="w-full border-gray-200 focus:border-emerald-500 focus:ring focus:ring-emerald-100 transition-all"
                  v-model="form.price"
                >
                  <template #leading>
                    <UIcon name="i-mdi:currency-bdt" />
                  </template>
                </UInput>
              </UFormGroup>

              <UFormGroup
                label="Required Quantity"
                required
                :error="
                  form.required_quantity <= 0 &&
                  checkSubmit &&
                  'You must enter required quantity!'
                "
                class="mb-5"
              >
                <UInput
                  type="text"
                  size="md"
                  color="white"
                  placeholder="10"
                  class="w-full border-gray-200 focus:border-emerald-500 focus:ring focus:ring-emerald-100 transition-all"
                  v-model="form.required_quantity"
                >
                  <template #leading>
                    <UIcon name="i-heroicons-calculator" />
                  </template>
                </UInput>
              </UFormGroup>
            </div>

            <div class="bg-gray-50 p-4 rounded-lg border border-gray-200 mt-2">
              <UFormGroup
                label="Total Cost (Service handling fee 10% included)"
                class="mb-0"
              >
                <p
                  class="text-lg font-semibold text-emerald-700 flex items-center gap-1"
                >
                  <UIcon name="i-mdi:currency-bdt" />
                  {{
                    form.price * form.required_quantity +
                    (form.price * form.required_quantity * 10) / 100
                  }}
                </p>
              </UFormGroup>
            </div>
          </div>

          <!-- Instructions Section -->
          <div
            class="p-2 md:p-7 border-b border-gray-100 hover:bg-gray-50 transition-colors duration-300"
          >
            <h2
              class="text-xl font-semibold text-gray-800 mb-6 flex items-center gap-2"
            >
              <UIcon
                name="i-heroicons-clipboard-document-list"
                class="text-emerald-600"
              />
              Instructions & Details
            </h2>

            <UFormGroup label="Task URL" class="mb-5">
              <UInput
                type="text"
                size="md"
                color="white"
                placeholder="Task URL"
                v-model="form.action_link"
                class="w-full border-gray-200 focus:border-emerald-500 focus:ring focus:ring-emerald-100 transition-all"
              >
                <template #leading>
                  <UIcon name="i-heroicons-link" />
                </template>
              </UInput>
            </UFormGroup>

            <UFormGroup
              label="Instructions"
              required
              :error="
                !form.instructions &&
                checkSubmit &&
                'You must enter instructions!'
              "
              class="mb-5"
            >
              <p class="text-sm text-gray-600 mb-3">
                Provide detailed instructions for completing this gig
              </p>
              <div
                class="border border-gray-200 rounded-lg overflow-hidden focus-within:ring-2 focus-within:ring-emerald-100 focus-within:border-emerald-500 transition-all"
              >
                <CommonEditor
                  v-model="form.instructions"
                  @updateContent="updateContent"
                />
              </div>
            </UFormGroup>
          </div>

          <!-- Media Upload Section -->
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
              Add photos or videos to explain your task (optional)
            </p>

            <div class="flex flex-wrap gap-4 mt-4">
              <!-- Uploaded images -->
              <div
                v-for="(img, i) in form.medias"
                :key="i"
                class="w-32 h-32 rounded-lg overflow-hidden relative border border-gray-200 bg-gray-50 group"
              >
                <img
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
              >
                <input
                  type="file"
                  ref="fileInput"
                  class="absolute inset-0 w-full h-full opacity-0 cursor-pointer z-10"
                  @change="handleFileUpload"
                  accept="image/*,video/*"
                />
                <div
                  class="flex flex-col items-center gap-2 text-gray-600 text-sm text-center p-2 group-hover:text-emerald-600"
                >
                  <UIcon
                    name="i-heroicons-arrow-up-tray"
                    class="text-xl text-emerald-500"
                  />
                  <span>Add Media</span>
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
              Uploading media...
            </p>
          </div>

          <!-- Targeting Section -->
          <div
            class="p-2 md:p-7 border-b border-gray-100 hover:bg-gray-50 transition-colors duration-300"
          >
            <h2
              class="text-xl font-semibold text-gray-800 mb-6 flex items-center gap-2"
            >
              <UIcon
                name="i-heroicons-cursor-arrow-rays"
                class="text-emerald-600"
              />
              Targeting Options
            </h2>

            <div class="grid grid-cols-1 sm:grid-cols-2 gap-5">
              <UFormGroup
                label="Target Country"
                required
                :error="
                  !form.target_country &&
                  checkSubmit &&
                  'You must select a target country!'
                "
                class="mb-5"
              >
                <USelectMenu
                  v-model="form.target_country"
                  color="white"
                  size="md"
                  placeholder="Target Country"
                  :options="country"
                  class="w-full border-gray-200 focus:border-emerald-500 focus:ring focus:ring-emerald-100 transition-all"
                  option-attribute="title"
                  value-attribute="title"
                >
                  <template #leading>
                    <UIcon name="i-heroicons-globe-alt" />
                  </template>
                </USelectMenu>
              </UFormGroup>

              <UFormGroup
                label="Target Device"
                required
                :error="
                  !form.target_device &&
                  checkSubmit &&
                  'You must select a target device!'
                "
                class="mb-5"
              >
                <USelectMenu
                  v-model="form.target_device"
                  color="white"
                  size="md"
                  placeholder="Target Device"
                  multiple
                  :options="device"
                  class="w-full border-gray-200 focus:border-emerald-500 focus:ring focus:ring-emerald-100 transition-all"
                  option-attribute="title"
                  value-attribute="id"
                >
                  <template #leading>
                    <UIcon name="i-heroicons-device-phone-mobile" />
                  </template>
                </USelectMenu>
              </UFormGroup>
            </div>

            <UFormGroup
              label="Target Network"
              required
              :error="
                !form.target_network &&
                checkSubmit &&
                'You must select a target network!'
              "
              class="mb-5"
            >
              <USelectMenu
                v-model="form.target_network"
                color="white"
                size="md"
                :options="network"
                multiple
                placeholder="Target Network"
                class="w-full border-gray-200 focus:border-emerald-500 focus:ring focus:ring-emerald-100 transition-all"
                option-attribute="title"
                value-attribute="id"
              >
                <template #leading>
                  <UIcon name="i-heroicons-signal" />
                </template>
              </USelectMenu>
            </UFormGroup>
          </div>

          <!-- Submit Section -->
          <div class="p-2 md:p-7 bg-gray-50">
            <div
              v-if="showError"
              class="mb-4 p-4 bg-red-50 border border-red-200 rounded-lg text-red-700"
            >
              <p class="flex items-center gap-2">
                <UIcon name="i-heroicons-exclamation-circle" />
                <span>{{ showError }}!</span>
              </p>
              <NuxtLink
                to="/deposit-withdraw/"
                class="text-emerald-600 font-medium underline hover:text-emerald-700"
              >
                Click here to make a deposit
              </NuxtLink>
            </div>

            <div class="flex justify-center">
              <UButton
                :loading="isLoading"
                class="min-w-48 px-8 py-3 font-semibold transform hover:-translate-y-1 hover:shadow-sm transition-all duration-300"
                size="lg"
                color="primary"
                variant="solid"
                type="button"
                @click="handlePostGig"
              >
                <template #leading>
                  <UIcon name="i-heroicons-paper-airplane" />
                </template>
                Post Gig
              </UButton>

              <!-- <UButton
                v-else
                class="min-w-48 px-8 py-3 font-semibold transform hover:-translate-y-1 hover:shadow-sm transition-all duration-300"
                size="lg"
                color="primary"
                variant="solid"
                @click="isOpen = true"
              >
                <template #leading>
                  <UIcon name="i-heroicons-paper-airplane" />
                </template>
                Post Gig
              </UButton> -->
            </div>
          </div>
        </form>

        <!-- KYC Modal -->
        <UModal v-model="isOpen">
          <div class="p-2 md:p-8 flex flex-col items-center text-center">
            <div
              class="w-20 h-20 bg-amber-50 rounded-full flex items-center justify-center mb-5"
            >
              <UIcon
                name="i-heroicons-shield-exclamation"
                class="h-12 w-12 text-amber-500"
              />
            </div>

            <h2 class="text-xl font-semibold text-gray-800 mb-4">
              KYC Verification Required
            </h2>
            <p class="text-gray-600 mb-6 max-w-md leading-relaxed">
              Please Upload your ID to get permission to post a service ad.
            </p>

            <UButton
              size="lg"
              color="primary"
              variant="solid"
              to="/upload-center"
              class="min-w-48"
            >
              <template #leading>
                <UIcon name="i-material-symbols-upload-rounded" />
              </template>
              Upload NID
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
const isOpen = ref(false);
const { user } = useAuth();
const { get, post } = useApi();
const toast = useToast();
const categories = ref([]);
const network = ref([]);
const device = ref([]);
const country = ref([{ title: "Bangladesh" }]);
const checkSubmit = ref(false);
const showError = ref("");
const isLoading = ref(false);
const fileInput = ref(null);
const isUploading = ref(false);
const uploadError = ref("");

const form = ref({
  price: null,
  required_quantity: null,
  instructions: "",
  title: "",
  medias: [],
  target_country: "Bangladesh",
  target_device: "",
  target_network: "",
  category: "",
  active_gig: true,
  action_link: "",
});

function updateContent(p) {
  form.value.instructions = p;
}

function handleFileUpload(event) {
  const files = Array.from(event.target.files);
  if (!files.length) return;

  const file = files[0];

  // Validate file type
  if (!file.type.match("image.*") && !file.type.match("video.*")) {
    uploadError.value = "Please select an image or video file";
    return;
  }

  // Validate file size (10MB max)
  if (file.size > 12 * 1024 * 1024) {
    uploadError.value = "File size should be less than 12MB";
    return;
  }

  uploadError.value = "";
  isUploading.value = true;

  const reader = new FileReader();

  reader.onload = () => {
    form.value.medias.push(reader.result);
    isUploading.value = false;

    // Reset the file input so the same file can be selected again
    if (fileInput.value) {
      fileInput.value.value = "";
    }
  };

  reader.onerror = (error) => {
    console.error("Error reading file:", error);
    uploadError.value = "Failed to read the file";
    isUploading.value = false;
  };

  reader.readAsDataURL(file);
}

function deleteUpload(ind) {
  if (ind >= 0 && ind < form.value.medias.length) {
    // Create a new array without the deleted item to maintain reactivity
    form.value.medias = form.value.medias.filter((_, i) => i !== ind);
  }
}

function validateForm() {
  const { medias, action_link, ...rest } = form.value;
  for (const key in rest) {
    const value = rest[key];
    // Check for empty strings, false values, or empty arrays
    if (
      (typeof value === "string" && !value.trim()) ||
      (typeof value === "boolean" && !value) ||
      (Array.isArray(value) && value.length === 0)
    ) {
      return false; // Validation failed
    }
  }
  return true; // All fields are valid
}

async function handlePostGig() {
  console.log(form.value.instructions);

  if (!validateForm()) {
    checkSubmit.value = true;
    toast.add({ title: "Please fill in all required fields." });
    return;
  }
  isLoading.value = true;
  const balance = form.value.required_quantity * form.value.price;
  const total_cost = balance + (balance * 10) / 100;
  const submitValue = { ...form.value, total_cost, balance };
  console.log(submitValue);

  try {
    const res = await post("/post-micro-gigs/", submitValue);
    console.log(res);

    if (res.data) {
      navigateTo("/");
      toast.add({ title: "MicroGig Added" });
    } else {
      toast.add({ title: res.error.data.errors });
      showError.value = res.error.data.errors;
    }
  } catch (error) {
    console.error("Error posting gig:", error);
    toast.add({ title: "Error posting gig. Please try again." });
  } finally {
    isLoading.value = false;
  }
}

async function getMicroGigsCategory() {
  try {
    const [categoriesResponse, devicesResponse, networksResponse] =
      await Promise.all([
        get("/micro-gigs-categories/"),
        get("/target-device/"),
        get("/target-network/"),
      ]);

    categories.value = categoriesResponse.data;
    device.value = devicesResponse.data;
    network.value = networksResponse.data;
  } catch (error) {
    console.error("Error fetching micro-gigs data:", error);
  }
}

onMounted(() => {
  getMicroGigsCategory();
});
</script>

<style scoped>
/* All styling is handled through Tailwind classes in the template */
</style>
