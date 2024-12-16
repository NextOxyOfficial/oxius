<template>
  <PublicSection>
    <UContainer>
      <h1 class="text-center text-4xl my-8">Add A Classified Post</h1>
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
            <UInput
              icon="i-mdi:currency-bdt"
              type="text"
              size="md"
              color="white"
              :ui="{
                size: {
                  md: 'text-base',
                },
              }"
              placeholder="2.0"
              class="max-w-40"
              v-model="form.price"
            />
          </UFormGroup>
        </div>

        <UFormGroup label="Upload Photo/Video">
          <input
            type="file"
            name=""
            id=""
            @change="handleFileUpload($event, 'image')"
          />
        </UFormGroup>
        <div class="flex flex-wrap gap-5">
          <div
            class="relative max-w-[200px] max-h-[200px]"
            v-for="(img, i) in form.medias"
            :key="i"
          >
            <img :src="img" :alt="`Uploaded file ${i}`" />
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
          <UFormGroup label="Country">
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
          </UFormGroup>
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
        </div>

        <div class="grid md:grid-cols-2 gap-4">
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
        <div>
          <UFormGroup label="Address">
            <UTextarea
              v-model="form.location"
              color="white"
              variant="outline"
              class="w-full"
              resize
              placeholder="Chewriya, Kushtia"
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

async function handlePostGig() {
  console.log(form.value);
  const formData = new FormData();
  formData.append("title", form.value.title);
  formData.append("price", form.value.price);
  formData.append("instructions", form.value.instructions);
  formData.append("image", form.value.image);
  formData.append("category", form.value.category);
  formData.append("accepted_terms", form.value.accepted_terms);
  formData.append("accepted_privacy", form.value.accepted_privacy);
  formData.append("medias", form.value.medias); // Not needed as we are sending the image separately
  formData.append("location", form.value.location); // Not needed as we are sending the image separately
  formData.append("country", form.value.country);
  formData.append("state", form.value.state);
  formData.append("city", form.value.city);

  const res = await post("/classified-categories-post/", form.value);
  if (res.data) {
    navigateTo("/");
    toast.add({ title: "Classified Service Added" });
  }
}

async function getMicroGigsCategory() {
  try {
    const [categoriesResponse] = await Promise.all([
      get("/classified-categories/"),
    ]);

    categories.value = categoriesResponse.data;
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

async function getCountry() {
  const res = await $fetch(ApiUrl, headerOptions);
  country.value = res;
  console.log(res);
}
onMounted(() => {
  setTimeout(() => {
    getCountry();
  }, 100);
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
