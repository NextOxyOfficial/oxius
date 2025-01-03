<template>
  <PublicSection>
    <UContainer>
      <h2 class="text-center text-4xl my-6">
        {{ categoryTitle }}
      </h2>
      <CommonGeoSelector />
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
      </div>
      <p class="text-base md:text-lg mb-3 font-semibold">
        {{ $t("select_location") }}
      </p>
      <div class="flex flex-col md:flex-row justify-between md:items-end gap-4">
        <UFormGroup class="md:w-1/4">
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
            }"
            option-attribute="name"
            value-attribute="name"
          />
        </UFormGroup>
        <UFormGroup class="md:w-1/4">
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
      <div class="search mt-4" v-if="search.length">
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
          v-for="(service, i) in search.filter(
            (service) => service.service_status.toLowerCase() === 'approved'
          )"
          :key="{ i }"
          data-aos="zoom-out-right"
        >
          <NuxtLink :to="`/classified-categories/details/${service.id}`">
            <div
              class="flex flex-col pl-3 pr-5 py-2.5 sm:flex-row sm:items-center w-full"
            >
              <div
                class="flex flex-col sm:flex-row items-center justify-between w-full max-sm:relative"
              >
                <div class="flex flex-row gap-4 items-center sm:items-start">
                  <div>
                    <NuxtImg
                      :src="staticURL + service.medias[0].image"
                      class="size-14 rounded-md"
                    />
                  </div>
                  <div class="flex-1 text-sm sm:text-base">
                    <h3
                      class="text-base font-semibold sm:mb-1.5 text-left line-clamp-2 first-letter:uppercase"
                    >
                      {{ service?.title }}
                    </h3>

                    <div
                      class="flex flex-wrap items-center sm:items-start gap-y-1 gap-x-4 sm:gap-4 text-gray-600"
                    >
                      <p
                        class="text-sm md:text-base sm:hidden font-semibold text-green-950"
                      >
                        <UIcon name="i-mdi:currency-bdt" />
                        {{ service.negotiable ? "Negotiable" : service.price }}
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
                          >Posted: {{ formatDate(service?.created_at) }}</span
                        >
                      </p>

                      <div class="flex gap-1 items-center text-sm">
                        Posted By:
                        <p class="text-sm">
                          <span class="text-green-600"
                            >{{ service.user?.name.slice(0, 6) }}***</span
                          >
                        </p>
                      </div>
                      <p class="inline-flex gap-1 items-center">
                        <UIcon name="i-heroicons-map-pin-solid" />
                        <span class="text-sm first-letter:uppercase">{{
                          service?.location
                        }}</span>
                      </p>
                    </div>
                  </div>
                </div>
                <div>
                  <p
                    class="hidden text-sm md:text-base sm:flex sm:items-center sm:justify-end sm:my-3 font-semibold text-green-950"
                  >
                    <UIcon name="i-mdi:currency-bdt" />
                    {{ service.negotiable ? "Negotiable" : service.price }}
                  </p>
                </div>
              </div>
            </div>
          </NuxtLink>
        </UCard>
        <h3 class="text-xl font-semibold mt-6">Nearby location ads</h3>
      </div>
      <div v-if="isLoading">
        <CommonPreloader text="Searching for ads in your city..." />
      </div>
      <UCard v-if="searchError" class="py-16 text-center mt-6">
        <p>No offers have been found!</p>
      </UCard>
      <h3 v-if="searchError" class="text-xl font-semibold mt-6">
        Nearby location ads
      </h3>
      <div class="services mt-3" v-if="services?.length">
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
            (service) => service.service_status.toLowerCase() === 'approved'
          )"
          :key="{ i }"
        >
          <NuxtLink :to="`/classified-categories/details/${service.id}`">
            <div
              class="flex flex-col pl-3 pr-5 py-2.5 sm:flex-row sm:items-center w-full"
            >
              <div
                class="flex flex-col sm:flex-row items-center justify-between w-full max-sm:relative"
              >
                <div class="flex flex-row gap-4 items-start">
                  <div>
                    <NuxtImg
                      :src="staticURL + service.medias[0].image"
                      class="size-9 sm:size-14 object-cover rounded-md"
                    />
                  </div>
                  <div class="flex-1 text-sm sm:text-base">
                    <h3
                      class="text-sm sm:text-base font-semibold mb-1.5 text-left line-clamp-2 first-letter:uppercase"
                    >
                      {{ service?.title }}
                    </h3>

                    <div
                      class="flex flex-wrap items-center sm:items-start gap-y-1 gap-x-4 sm:gap-4 text-gray-600"
                    >
                      <p
                        class="text-sm md:text-base sm:hidden font-semibold text-green-950"
                      >
                        <UIcon name="i-mdi:currency-bdt" />
                        {{ service.negotiable ? "Negotiable" : service.price }}
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
                          >Posted: {{ formatDate(service?.created_at) }}</span
                        >
                      </p>

                      <div class="flex gap-1 items-center text-sm">
                        Posted By:
                        <p class="text-sm">
                          <span class="text-green-600"
                            >{{ service.user?.name.slice(0, 6) }}***</span
                          >
                        </p>
                      </div>
                      <p class="inline-flex gap-1 items-center">
                        <UIcon name="i-heroicons-map-pin-solid" />
                        <span class="text-sm first-letter:uppercase">{{
                          service?.location
                        }}</span>
                      </p>
                    </div>
                  </div>
                </div>
                <div>
                  <p
                    class="hidden text-sm md:text-base sm:flex sm:items-center sm:justify-end sm:my-3 font-semibold text-green-950"
                  >
                    <UIcon name="i-mdi:currency-bdt" />
                    {{ service.negotiable ? "Negotiable" : service.price }}
                  </p>
                </div>
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
const location = useCookie("location");
const { formatDate } = useUtils();
const isLoading = ref(false);

const form = ref({
  country: "Bangladesh",
  state: location.value?.state || "",
  city: location.value?.city || "",
  title: "",
  category: "",
});

const categoryTitle = ref("");
const services = ref([]);
const search = ref([]);
const searchError = ref(false);
const router = useRoute();

// geo filter

const regions = ref([]);
const cities = ref();

const regions_response = await get(
  `/cities-light/regions/?country=${form.value.country}`
);
regions.value = regions_response.data;
if (form.value.state) {
  const cities_response = await get(
    `/cities-light/cities/?region=${form.value.state}`
  );
  cities.value = cities_response.data;
}
watch(
  () => form.value.state,
  async (newState) => {
    if (newState) {
      const cities_response = await get(
        `/cities-light/cities/?region=${newState}`
      );
      cities.value = cities_response.data;
    }
  },
  { immediate: true }
);

// geo filter

async function fetchServices() {
  const response = await get(`/classified-categories/${router.params.id}/`);
  services.value = response.data?.filter(
    (service) =>
      service.service_status.toLowerCase() === "approved" &&
      service.active_service
  );
  categoryTitle.value = response.data[0]?.category_details.title;
}
fetchServices();

async function filterSearch() {
  const { title, category, ...rest } = form.value;
  location.value = rest;
  search.value = [];
  isLoading.value = true;
  const res = await get(
    `/classified-posts/filter/?category=${router.params.id}&title=${form.value.title}&country=${form.value.country}&state=${form.value.state}&city=${form.value.city}`
  );

  setTimeout(() => {
    if (res.data.length > 0) {
      search.value = res.data;
    } else {
      searchError.value = true;
    }
    isLoading.value = false;
  }, 2000);
}
if (location.value) {
  filterSearch();
}
</script>
