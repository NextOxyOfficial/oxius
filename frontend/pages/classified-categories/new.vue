<template>
  <PublicSection>
    <UContainer>
      <h1 class="text-center text-4xl my-8">Post A Classified Ad</h1>
      <UDivider label="" class="mb-8" />
      <form
        action="#"
        class="max-w-2xl mx-auto space-y-3"
        @submit.prevent="handlePostGig"
      >
        <UFormGroup
          label="Title"
          required
          :error="!form.title && checkSubmit && 'You must enter a title!'"
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
            }"
          >
          </UInput>
        </UFormGroup>
        <div class="flex gap-4 items-center"></div>
        <UFormGroup
          label="Instruction"
          required
          :error="
            !form.instructions && checkSubmit && 'You must enter instructions!'
          "
        >
          <UTextarea
            color="white"
            variant="outline"
            :ui="{
              size: {
                md: 'text-base',
              },
            }"
            class="w-full"
            resize
            placeholder="Instruction"
            v-model="form.instructions"
          />
        </UFormGroup>
        <div class="grid md:grid-cols-2 gap-4">
          <UFormGroup
            label="Category"
            required
            :error="
              !form.category && checkSubmit && 'You must select a category'
            "
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
                }"
                placeholder="2.0"
                class="max-w-40"
                v-model="form.price"
              />
              <UCheckbox
                v-model="form.negotiable"
                name="Negotiable"
                label="Negotiable"
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
        <UFormGroup label="Upload Photo/Video"> </UFormGroup>
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
          <!-- <UFormGroup label="Country">
            <USelectMenu
              v-model="form.country"
              color="white"
              size="md"
              :options="country"
              placeholder="Country"
              :ui="{
                size: {
                  md: 'text-base',
                },
              }"
              option-attribute="name"
              value-attribute="iso2"
            />
          </UFormGroup> -->
          <UFormGroup
            label="State"
            required
            :error="!form.state && checkSubmit && 'You must select a state!'"
          >
            <USelectMenu
              v-model="form.state"
              color="white"
              size="md"
              :options="state"
              placeholder="State"
              :ui="{
                size: {
                  md: 'text-base',
                },
              }"
              option-attribute="name"
              value-attribute="iso2"
            />
          </UFormGroup>
          <UFormGroup
            label="City"
            required
            :error="!form.city && checkSubmit && 'You must select a city'"
          >
            <USelectMenu
              v-model="form.city"
              color="white"
              size="md"
              :options="city"
              placeholder="City"
              :ui="{
                size: {
                  md: 'text-base',
                },
              }"
              option-attribute="name"
              value-attribute="name"
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
          >
            <UTextarea
              v-model="form.location"
              color="white"
              variant="outline"
              class="w-full"
              resize
              placeholder="1216-Mirpur, Dhaka"
            />
          </UFormGroup>
        </div>

        <UCheckbox
          name="terms_privacy"
          label="Accept Terms & Privacy "
          v-model="form.accepted_privacy"
          :error="
            !form.accepted_privacy &&
            checkSubmit &&
            'You must accept our Terms Condition & Privacy Policy!'
          "
        />
        <div class="text-center">
          <UButton
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
        <div class="p-4 text-center space-y-3">
          <h3 class="text-lg font-semibold">KYC Validation Failed!</h3>
          <p>Please Upload your NID to get permission to post a service ad.</p>

          <UButton
            size="md"
            color="primary"
            variant="solid"
            to="/upload-center"
            label="Upload NID"
          />
        </div>
      </UModal>
    </UContainer>
    {{ form }}
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
const country = ref([]);
const state = ref([]);
const city = ref([]);
const checkSubmit = ref(false);

const form = ref({
  price: 0,
  instructions: "",
  title: "",
  medias: [],
  category: "",
  country: "",
  state: "",
  city: "",
  location: "",
  negotiable: false,
  accepted_privacy: false,
});
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
      (typeof value === "boolean" && !value) || // Check false booleans
      (Array.isArray(value) && value.length === 0) // Check empty arrays
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
  const { medias, ...rest } = form.value;
  rest.service_status = "pending";

  const res = await (router.query.id
    ? put(`/update-user-classified-post/${router.query.id}/`, rest)
    : post("/classified-categories-post/", submitValues.value));
  if (res.data) {
    navigateTo("/");
    toast.add({ title: "Classified Service Added" });
  }
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
  fetchServices();
});

const ApiUrl = "https://api.countrystatecity.in/v1/countries";
const headerOptions = {
  method: "GET",
  headers: {
    "X-CSCAPI-KEY": "NHhvOEcyWk50N2Vna3VFTE00bFp3MjFKR0ZEOUhkZlg4RTk1MlJlaA==",
  },
  redirect: "follow",
};

// async function getCountry() {
//   const res = await $fetch(ApiUrl, headerOptions);
//   country.value = res;
//   console.log(res);
// }
onMounted(() => {
  country.value.push({ name: "BD", iso2: "BD" });
  form.value.country = "BD";
});

watch(
  () => form.value.country,
  async (newValue, oldValue) => {
    if (newValue) {
      const res = await $fetch(
        `${ApiUrl}/${form.value.country}/states/`,
        headerOptions
      );
      state.value = res;
    }
  }
);
watch(
  () => form.value.state,
  async (newValue, oldValue) => {
    if (newValue) {
      const res = await $fetch(
        `${ApiUrl}/${form.value.country}/states/${form.value.state}/cities`,
        headerOptions
      );
      city.value = res;
    }
  }
);
</script>

<style scoped></style>
