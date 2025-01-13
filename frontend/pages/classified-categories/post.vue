<template>
  <PublicSection>
    <UContainer>
      <h1 class="text-center text-4xl my-8">Post A Classified Ad</h1>
      <UDivider label="" class="mb-8" />
      <form
        action="#"
        class="max-w-2xl mx-auto space-y-3 bg-white px-2 py-3 sm:px-8 sm:py-6 rounded-lg"
        @submit.prevent="handlePostGig"
      >
        <UFormGroup
          label="Title"
          required
          :error="!form.title && checkSubmit && 'You must enter a title!'"
          :ui="{
            label: {
              base: 'block font-medium text-gray-700 dark:text-slate-700',
            },
          }"
        >
          <UInput
            type="text"
            size="md"
            color="white"
            class="relative"
            placeholder="Title"
            v-model="form.title"
            :ui="{
              size: {
                md: 'text-base',
              },
              placeholder: 'placeholder-gray-400 dark:placeholder-gray-200',
            }"
          >
          </UInput>
        </UFormGroup>
        <div class="flex gap-4 items-center"></div>

        <p class="text-sm font-semibold">
          Instructions <span class="text-red-500">*</span>
        </p>
        <CommonEditor
          v-if="form.instructions"
          :content="form.instructions"
          @updateContent="
            (content) => {
              form.instructions = content;
            }
          "
          class="border border-slate-300 p-2 bg-white"
        />
        <div class="grid md:grid-cols-2 gap-4">
          <UFormGroup
            label="Category"
            required
            :error="
              !form.category && checkSubmit && 'You must select a category'
            "
            :ui="{
              label: {
                base: 'block font-medium text-gray-700 dark:text-slate-700',
              },
            }"
          >
            <USelectMenu
              v-model="form.category"
              color="white"
              size="md"
              :options="categories"
              placeholder="Target Category"
              :ui="{
                size: {
                  md: 'text-base',
                },
                placeholder: 'text-gray-400 dark:text-gray-200',
              }"
              option-attribute="title"
              value-attribute="id"
            />
          </UFormGroup>
          <UFormGroup
            label="Price"
            :error="
              form.price <= 0 &&
              !form.negotiable &&
              checkSubmit &&
              'Price must be greater than 0 or Negotiable'
            "
            :ui="{
              label: {
                base: 'block font-medium text-gray-700 dark:text-slate-700',
              },
            }"
          >
            <div class="flex gap-2 items-center">
              <UInput
                icon="i-mdi:currency-bdt"
                type="text"
                size="md"
                color="white"
                :disabled="form.negotiable"
                :ui="{
                  size: {
                    md: 'text-base',
                  },
                  placeholder: 'placeholder-gray-400 dark:placeholder-gray-200',
                }"
                placeholder="2.0"
                class="max-w-40"
                v-model="form.price"
              />
              <UCheckbox
                v-model="form.negotiable"
                name="Negotiable"
                label="Negotiable"
                :ui="{
                  label:
                    'text-sm font-medium text-gray-700 dark:text-slate-700',
                }"
              />
            </div>
          </UFormGroup>
        </div>

        <!-- <UFormGroup label="Upload Photo/Video">
          <input
            type="file"
            name=""
            id=""
            @change="handleFileUpload($event, 'image')"
          />
        </UFormGroup> -->
        <UFormGroup
          label="Upload Photo/Video"
          :ui="{
            label: {
              base: 'block font-medium text-gray-700 dark:text-slate-700',
            },
          }"
        >
        </UFormGroup>
        <div class="flex flex-wrap gap-2 md:gap-5 mt-4">
          <div
            class="relative max-w-[200px] max-h-[200px] overflow-hidden"
            v-for="(img, i) in form.medias"
            :key="i"
          >
            <img
              v-if="img.image"
              :src="staticURL + img.image"
              :alt="`Uploaded file ${i}`"
              class="object-cover"
            />
            <img
              v-else
              :src="img"
              :alt="`Uploaded file ${i}`"
              class="object-cover"
            />
            <div
              class="absolute top-2 right-2 rounded-sm bg-white cursor-pointer"
              @click="deleteUpload(i)"
            >
              <UIcon name="i-heroicons-trash-solid" class="text-red-500" />
            </div>
          </div>

          <div
            class="w-full h-full border flex items-center justify-center max-w-[200px] max-h-[200px] relative"
          >
            <input
              type="file"
              name=""
              id=""
              class="h-full w-full absolute left-0 top-0 z-10 cursor-pointer opacity-0"
              @change="handleFileUpload($event, 'image')"
            />
            <UIcon name="i-heroicons-plus-solid" size="66" />
          </div>
        </div>
        <!-- <UFormGroup label="Upload Photo/Video">
          <UInput
            type="file"
            size="md"
            color="white"
            :ui="{
              color: {
                white: {
                  outline: 'ring-0',
                },
              },
              size: {
                md: 'text-base',
              },
            }"
            placeholder="Budget Per Action"
            class="max-w-72"
          />
        </UFormGroup> -->
        <div class="grid md:grid-cols-2 gap-4">
          <UFormGroup
            label="State"
            required
            :error="!form.state && checkSubmit && 'You must select a state!'"
            :ui="{
              label: {
                base: 'block font-medium text-gray-700 dark:text-slate-700',
              },
            }"
          >
            <USelectMenu
              v-model="form.state"
              color="white"
              size="md"
              :options="regions"
              placeholder="State"
              :ui="{
                size: {
                  md: 'text-base',
                },
                placeholder: 'text-gray-400 dark:text-gray-200',
              }"
              option-attribute="name_eng"
              value-attribute="name_eng"
            />
          </UFormGroup>
          <UFormGroup
            label="City"
            required
            :error="!form.city && checkSubmit && 'You must select a city'"
            :ui="{
              label: {
                base: 'block font-medium text-gray-700 dark:text-slate-700',
              },
            }"
          >
            <USelectMenu
              v-model="form.city"
              color="white"
              size="md"
              :options="cities"
              placeholder="City"
              :ui="{
                size: {
                  md: 'text-base',
                },
                placeholder: 'text-gray-400 dark:text-gray-200',
              }"
              option-attribute="name_eng"
              value-attribute="name_eng"
            />
          </UFormGroup>
        </div>

        <div class="grid md:grid-cols-2 gap-4">
          <UFormGroup
            label="Thana"
            required
            :error="!form.upazila && checkSubmit && 'You must select a Thana'"
            :ui="{
              label: {
                base: 'block font-medium text-gray-700 dark:text-slate-700',
              },
            }"
          >
            <USelectMenu
              v-model="form.upazila"
              color="white"
              size="md"
              :options="upazilas"
              placeholder="Thana"
              :ui="{
                size: {
                  md: 'text-base',
                },
                placeholder: 'text-gray-400 dark:text-gray-200',
              }"
              option-attribute="name_eng"
              value-attribute="name_eng"
            />
          </UFormGroup>
        </div>

        <div class="grid md:grid-cols-2 gap-4"></div>
        <div>
          <UFormGroup
            label="Address"
            required
            :error="
              !form.location && checkSubmit && 'You must enter your address!'
            "
            :ui="{
              label: {
                base: 'block font-medium text-gray-700 dark:text-slate-700',
              },
            }"
          >
            <UTextarea
              v-model="form.location"
              color="white"
              variant="outline"
              class="w-full"
              resize
              placeholder="1216-Mirpur, Dhaka"
              :ui="{
                placeholder: 'placeholder-gray-400 dark:placeholder-gray-200',
              }"
            />
          </UFormGroup>
        </div>

        <UCheckbox
          name="terms_privacy"
          label="Accept Terms & Privacy "
          v-model="form.accepted_privacy"
          :ui="{
            label: 'text-sm font-medium text-gray-700 dark:text-slate-700',
          }"
        />
        <p
          v-if="!form.accepted_privacy && checkSubmit"
          class="text-sm text-red-500"
        >
          You must accept our Terms Condition & Privacy Policy!
        </p>
        <div class="text-center">
          <UButton
            :loading="isLoading"
            v-if="user.user.kyc"
            class="px-8"
            size="lg"
            color="primary"
            variant="solid"
            label="Post"
            type="submit"
          />
          <UButton
            v-else
            class="px-8"
            size="lg"
            color="primary"
            variant="solid"
            label="Post"
            @click="isOpen = true"
          />
        </div>
      </form>
      <UModal v-model="isOpen">
        <div
          className="fixed inset-0 z-50 flex items-center justify-center p-4"
        >
          <!-- <div 
              className="fixed inset-0 bg-gray-500/75 backdrop-blur-sm transition-opacity"
              onClick={onClose}
            /> -->
          <div
            className="relative w-full max-w-sm transform overflow-hidden rounded-lg bg-white shadow-xl transition-all"
          >
            <div className="px-6 py-8">
              <div className="flex flex-col items-center text-center">
                <div
                  className="rounded-full bg-red-100 p-3 mb-4 inline-flex items-center justify-center"
                >
                  <!-- <AlertCircle className="h-8 w-8 text-red-600" /> -->
                  <UIcon
                    name="i-line-md-alert-circle"
                    class="h-8 w-8 text-red-600"
                  />
                </div>

                <h2 className="text-xl font-semibold text-gray-900 mb-2">
                  KYC Unverified
                </h2>

                <p className="text-gray-600 mb-6">
                  Please Upload your ID to get permission to post a service ad.
                </p>

                <!-- <button
                  className="inline-flex items-center justify-center w-full px-4 py-2.5 rounded-lg bg-emerald-500 text-white hover:bg-emerald-600 active:bg-emerald-700 transition-colors duration-200 focus:outline-none focus:ring-2 focus:ring-emerald-500 focus:ring-offset-2"
                  onClick="{handleUpload}"
                >
                  <Upload className="h-5 w-5 mr-2" />
                  Upload NID
                </button> -->
                <UButton
                  size="md"
                  color="primary"
                  variant="solid"
                  to="/upload-center"
                  label="Upload NID"
                  block
                >
                  <template #leading>
                    <UIcon
                      name="i-material-symbols-upload-rounded"
                      class="h-5 w-5"
                    />
                  </template>
                </UButton>
              </div>
            </div>
          </div>
        </div>

        <!-- </div> -->
      </UModal>
    </UContainer>
  </PublicSection>
</template>

<script setup>
definePageMeta({
  layout: "dashboard",
});
const isOpen = ref(false);
const { get, post, put, baseURL, staticURL } = useApi();
const { user } = useAuth();
const toast = useToast();
const categories = ref([]);
const checkSubmit = ref(false);
const isLoading = ref(false);

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
    location,
    negotiable,
    accepted_privacy,
    service_status,
  };
}

function validateForm() {
  // Determine the base submit values based on conditions
  const { negotiable, price, ...rest } = form.value;
  submitValues.value = negotiable ? { ...rest } : { ...rest, price };

  // Validate each field in submitValues
  for (const key in submitValues.value) {
    const value = submitValues.value[key];
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
  rest.service_status = "pending";

  const res = await (router.query.id
    ? put(`/update-user-classified-post/${router.query.id}/`, rest)
    : post("/classified-categories-post/", submitValues.value));
  if (res.data) {
    navigateTo("/");
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

function deleteUpload(ind) {
  if (ind >= 0 && ind < form.value.medias.length) {
    form.value.medias.splice(ind, 1);
  }
}

async function getMicroGigsCategory() {
  try {
    const [categoriesResponse] = await Promise.all([
      get("/classified-categories/"),
    ]);
    categories.value = categoriesResponse.data.results;
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
const cities = ref();
const upazilas = ref();

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

<style scoped></style>
