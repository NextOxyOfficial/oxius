<template>
  <PublicSection>
    <UContainer>
      <h2 class="text-center text-4xl my-6">
        {{ categoryTitle }}
      </h2>
      <div>
        <p class="mb-3">
          <ULink
            to="/"
            active-class="text-primary"
            inactive-class="text-gray-500 dark:text-gray-400"
            >Home</ULink
          >
          <span v-if="services?.length">></span> {{ categoryTitle }}
        </p>
        <!-- <USelect
            icon="i-heroicons-bell-solid"
            color="white"
            size="md"
            :options="categories"
            v-model="form.category"
            placeholder="Category"
            option-attribute="title"
            value-attribute="id"
          /> -->
      </div>
      <p class="text-base md:text-lg mb-3 font-semibold">
        Select Your Location
      </p>
      <div class="flex flex-col md:flex-row justify-between md:items-end gap-4">
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
        <UFormGroup class="md:w-1/4">
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
        <UFormGroup class="md:w-1/4">
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
        <UButtonGroup size="md" class="md:w-96 md:flex-1">
          <UInput
            icon="i-heroicons-magnifying-glass-20-solid"
            size="md"
            color="white"
            :trailing="false"
            placeholder="Search..."
            v-model="form.title"
            class="w-full"
            :ui="{
              padding: {
                md: 'py-2.5',
              },
            }"
          />

          <UButton
            icon="i-heroicons-magnifying-glass-20-solid"
            size="md"
            color="primary"
            variant="solid"
            label="Search"
            @click="filterSearch"
            class="h-10"
          />
        </UButtonGroup>
      </div>
      <!-- <div class="grid md:grid-cols-4 gap-4">
        <div class="pt-6"></div>
      </div> -->

      <div class="mt-5">
        <UButton
          class="px-8"
          size="lg"
          color="primary"
          variant="solid"
          label="Post Ads"
          to="/classified-categories/new/"
        />
      </div>
      <div class="services mt-4" v-if="services.length">
        <UCard
          :ui="{
            background: '',
            ring: '',
            shadow: '',
            rounded: '',
            body: {
              padding: 'p-0 sm:p-0 flex-1 w-full',
            },
            header: {
              padding: 'p-0',
            },
            footer: {
              padding: 'p-0',
            },
          }"
          class="service-card border even:border-t-0 even:border-b-0 bg-slate-50/70"
          v-for="(service, i) in services.filter(
            (service) => service.gig_status.toLowerCase() === 'approved'
          )"
          :key="{ i }"
        >
          <NuxtLink :to="`/classified-categories/details/${service.id}`">
            <div
              class="flex flex-col px-3 py-2.5 sm:flex-row sm:items-center w-full"
            >
              <div
                class="flex flex-col sm:flex-row items-center justify-between w-full"
              >
                <div class="flex flex-row gap-4 items-center sm:items-start">
                  <div>
                    <NuxtImg
                      :src="staticURL + service.medias[0].image"
                      class="size-14 rounded-md"
                    />
                  </div>
                  <div>
                    <h3
                      class="text-base font-semibold mb-1.5 text-left line-clamp-2"
                    >
                      {{ service?.title }}
                    </h3>

                    <div
                      class="flex flex-wrap items-center sm:items-start gap-4"
                    >
                      <p class="inline-flex gap-1 items-center">
                        <UIcon name="i-heroicons-map-pin-solid" />
                        <span class="text-sm">{{ service?.location }}</span>
                      </p>
                      <p class="inline-flex gap-1 items-center">
                        <UIcon name="i-tabler:category-filled" />
                        <span class="text-sm">{{
                          service?.category_details.title
                        }}</span>
                      </p>
                      <p class="inline-flex gap-1 items-center">
                        <UIcon name="i-heroicons-clock-solid" />
                        <span class="text-sm"
                          >Posted: {{ service?.created_at }}</span
                        >
                      </p>
                    </div>
                  </div>
                </div>
                <p class="inline-flex items-center my-3">
                  Price: <UIcon name="i-mdi:currency-bdt" />
                  {{ service.price }}
                </p>
              </div>
            </div>
          </NuxtLink>
        </UCard>
      </div>
      <UCard v-else class="py-16 text-center mt-6">
        <p>No offers have been found!</p>
      </UCard>
    </UContainer>
  </PublicSection>
</template>

<script setup>
const { get, staticURL } = useApi();
const categoryTitle = ref("");
const services = ref([]);
const router = useRoute();
const country = ref(["BD"]);
const state = ref([]);
const city = ref([]);
const form = ref({
  country: "",
  state: "",
  city: "",
  title: "",
  category: "",
});
const categories = ref([]);

async function fetchServices() {
  const response = await get(`/classified-categories/${router.params.id}/`);
  console.log(response);

  services.value = response.data;
  categoryTitle.value = response.data[0]?.category_details.title;
}
fetchServices();

async function getClassifiedGigsCategory() {
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
  form.value.country = "BD";
  getClassifiedGigsCategory();
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
// onMounted(() => {
//   setTimeout(() => {
//     getCountry();
//   }, 100);
// });

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

async function filterSearch() {
  const res = await get(
    `/classified-posts/filter/?category=${router.params.id}&title=${form.value.title}&country=${form.value.country}&state=${form.value.state}&city=${form.value.city}`
  );
  console.log(res);
  services.value = res.data;
}
</script>

<style scoped>
/* .service-card:nth-child(odd) {
  background-color: rgb(235, 232, 232);
} */
</style>
