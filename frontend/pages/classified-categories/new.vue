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
        <UFormGroup label="Title">
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
        <UFormGroup label="Instruction">
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
          <UFormGroup label="Category">
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
          <UFormGroup label="Price">
            <div class="flex gap-2 items-center">
              <UInput
                icon="i-mdi:currency-bdt"
                type="text"
                size="md"
                color="white"
                :disabled="negotiate"
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
                v-model="negotiate"
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
            <img :src="img" :alt="`Uploaded file ${i}`" class="object-cover" />
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
          <UFormGroup label="State">
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
          <UFormGroup label="City">
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
          <UFormGroup label="Address">
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
          name="notifications"
          label="Accept Terms"
          v-model="form.accepted_terms"
        />
        <UCheckbox
          name="notifications"
          label="Accept Privacy"
          v-model="form.accepted_privacy"
        />
        <div class="text-center">
          <UButton
            class="px-8"
            size="lg"
            color="primary"
            variant="solid"
            label="Post"
            type="submit"
          />
        </div>
      </form>
    </UContainer>
  </PublicSection>
</template>

<script setup>
const { get, post } = useApi();
const toast = useToast();
const categories = ref([]);
const country = ref([]);
const state = ref([]);
const city = ref([]);

const mediaPreview = ref([]);
const negotiate = ref(false);

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
  accepted_terms: false,
  accepted_privacy: false,
});

function validateForm() {
  for (const key in form.value) {
    const value = form.value[key];
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
  if (!validateForm()) {
    toast.add({ title: "Please fill in all required fields." });
    return;
  }
  const res = await post("/classified-categories-post/", form.value);
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
