<template>
  <PublicSection>
    <UContainer>
      <h2 class="text-center text-4xl my-6">
        {{ categoryTitle }}
      </h2>
      <div class="flex justify-between items-end">
        <div>
          <p class="mb-3">
            <ULink
              to="/"
              active-class="text-primary"
              inactive-class="text-gray-500 dark:text-gray-400"
              >Home</ULink
            >
            > {{ categoryTitle }}
          </p>
          <USelect
            icon="i-heroicons-bell-solid"
            color="white"
            size="md"
            :options="['United States', 'Canada']"
            placeholder="Category"
          />
        </div>
        <UButtonGroup size="md" class="w-96">
          <UInput
            icon="i-heroicons-magnifying-glass-20-solid"
            size="sm"
            color="white"
            :trailing="false"
            placeholder="Search..."
            class="w-full"
          />
          <UButton
            icon="i-heroicons-bell-solid"
            size="md"
            color="primary"
            variant="solid"
            label="Search"
          />
        </UButtonGroup>
      </div>
      <div class="grid md:grid-cols-4 gap-4">
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
        <div class="pt-6">
          <UButton
            icon="i-heroicons-magnifying-glass-20-solid"
            size="md"
            color="primary"
            variant="solid"
            label="Search"
            @click="filterSearch"
          />
        </div>
      </div>

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
          v-for="(service, i) in services"
          :key="{ i }"
        >
          <NuxtLink :to="`/classified-categories/details/${service.id}`">
            <div
              class="flex flex-col px-3 py-2.5 sm:flex-row sm:items-center w-full"
            >
              <div class="flex items-center justify-between w-full">
                <div class="flex gap-4">
                  <div>
                    <NuxtImg
                      :src="staticURL + service.medias[0].image"
                      class="size-14 rounded-md"
                    />
                  </div>
                  <div>
                    <h3 class="text-base font-bold mb-1.5">
                      {{ service?.title }}
                    </h3>

                    <div class="flex gap-4">
                      <p class="inline-flex gap-1 items-center">
                        <UIcon name="i-heroicons-map-pin-solid" />
                        <span class="text-sm">{{ service?.location }}</span>
                      </p>
                      <p class="inline-flex gap-1 items-center">
                        <UIcon name="i-tabler:category-filled" />
                        <span class="text-sm">{{
                          service?.category.title
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
                <p class="inline-flex items-center">
                  Price: <UIcon name="i-mdi:currency-bdt" />
                  {{ service.price }}
                </p>
              </div>
            </div>
          </NuxtLink>
        </UCard>
      </div>
    </UContainer>
  </PublicSection>
</template>

<script setup>
const { get, staticURL } = useApi();
const categoryTitle = ref("");
const services = ref([]);
const router = useRoute();
const country = ref([]);
const state = ref([]);
const city = ref([]);
const form = ref({
  country: "",
  state: "",
  city: "",
});

console.log(router.params.id);

async function fetchServices() {
  const response = await get(`/classified-categories/${router.params.id}/`);
  console.log(response);

  services.value = response.data;
  categoryTitle.value = response.data[0]?.category_details.title;
}
fetchServices();

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

async function filterSearch() {
  const res = await get(
    `/classified-posts/filter/?country=${form.value.country}&state=${form.value.state}&city=${form.value.city}`
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
