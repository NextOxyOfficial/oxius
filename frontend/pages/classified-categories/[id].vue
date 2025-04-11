<template>
  <PublicSection>
    <UContainer>
      <h2
        class="text-center text-3xl sm:text-4xl my-3 sm:my-6 max-sm:hidden"
        v-if="categoryDetails?.title"
      >
        {{ categoryDetails?.title }}
      </h2>
      <CommonGeoSelector />
      <div>
        <p class="mb-3">
          <ULink
            to="/"
            active-class="text-primary"
            inactive-class="text-gray-500 dark:text-gray-400"
            >{{ $t("home") }}</ULink
          >
          <span v-if="categoryDetails?.title">&#8658;</span>
          {{ categoryDetails?.title }}
        </p>
      </div>
      <div class="flex items-center mb-3">
        <p class="text-base md:text-lg font-semibold">
          {{ $t("select_location") }}
        </p>
        <div class="block sm:hidden ml-auto w-max">
          <UButton
            class="px-8"
            size="lg"
            color="primary"
            variant="solid"
            label="+ Post Ads"
            to="/classified-categories/post/"
          />
        </div>
      </div>

      <div class="location-breadcrumb relative my-3 overflow-hidden">
        <!-- Subtle background effect -->
        <div
          class="absolute inset-0 bg-gradient-to-r from-gray-50 to-primary-50 opacity-70 rounded-lg"
        ></div>

        <!-- Decorative map pin -->
        <div class="absolute -left-3 top-1/2 -translate-y-1/2 text-primary-400">
          <UIcon name="i-heroicons-map-pin" class="w-16 h-16" />
        </div>

        <div
          class="relative z-10 flex items-center justify-between p-3 ps-12 rounded-lg border border-primary-100"
        >
          <!-- Location path with icons -->
          <div class="flex items-center flex-wrap location-path">
            <div
              class="location-segment flex items-center"
              data-location="state"
            >
              <UIcon
                name="i-heroicons-map"
                class="text-primary-600 mr-1.5 animate-pulse-slow"
              />
              <span class="font-medium text-gray-800">{{
                location?.state
              }}</span>
              <UIcon
                name="i-heroicons-chevron-right"
                class="mx-1.5 text-gray-400"
              />
            </div>

            <div
              class="location-segment flex items-center"
              data-location="city"
            >
              <UIcon
                name="i-heroicons-building-office-2"
                class="text-primary-600 mr-1.5 location-icon"
              />
              <span class="font-medium text-gray-800">{{
                location?.city
              }}</span>
              <UIcon
                name="i-heroicons-chevron-right"
                class="mx-1.5 text-gray-400"
              />
            </div>

            <div
              class="location-segment flex items-center"
              data-location="upazila"
            >
              <UIcon
                name="i-heroicons-home-modern"
                class="text-primary-600 mr-1.5 location-icon"
              />
              <span class="font-medium text-gray-800">{{
                location?.upazila
              }}</span>
            </div>
          </div>
          <UTooltip text="Change Location" class="me-auto">
            <UButton
              icon="i-heroicons-map-pin"
              size="md"
              color="primary"
              variant="ghost"
              trailing-icon="i-heroicons-pencil-square"
              class="edit-location-btn ml-2 relative overflow-hidden"
              @click="clearLocation"
            >
              <span class="sr-only">Edit Location</span>
            </UButton>
          </UTooltip>
          <UButtonGroup size="md" class="flex-1 hidden md:flex md:w-2/4">
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
                  md: 'sm:py-2.5',
                },
              }"
            />

            <UButton
              size="md"
              :loading="isLoading"
              color="primary"
              variant="solid"
              :label="t('search')"
              @click="filterSearch"
              class="sm:h-10 max-sm:!text-base w-24 justify-center"
              :ui="{
                padding: {
                  md: 'sm:py-2.5',
                },
              }"
            />
          </UButtonGroup>
        </div>
      </div>
      <UButtonGroup size="md" class="flex-1 flex md:hidden md:w-2/4">
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
              md: 'sm:py-2.5',
            },
          }"
        />

        <UButton
          size="md"
          :loading="isLoading"
          color="primary"
          variant="solid"
          label="Search"
          @click="filterSearch"
          class="sm:h-10 max-sm:!text-base w-24 justify-center"
          :ui="{
            padding: {
              md: 'sm:py-2.5',
            },
          }"
        />
      </UButtonGroup>
      <div
        class="flex flex-col md:flex-row justify-between md:items-end gap-1.5 sm:gap-4"
      >
        <UFormGroup class="md:w-1/4" v-if="searchLocationOption">
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
            option-attribute="name_eng"
            value-attribute="name_eng"
          />
        </UFormGroup>
        <UFormGroup class="md:w-1/4" v-if="searchLocationOption">
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
            option-attribute="name_eng"
            value-attribute="name_eng"
          />
        </UFormGroup>
        <UFormGroup class="md:w-1/4" v-if="searchLocationOption">
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
            }"
            option-attribute="name_eng"
            value-attribute="name_eng"
          />
        </UFormGroup>
      </div>

      <div class="mt-5 hidden sm:block">
        <div>
          <UButton
            color="primary"
            variant="outline"
            :label="t('post_classified')"
            icon="i-heroicons-plus"
            to="/classified-categories/post/"
            class="pulse-effect"
          />
        </div>
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
          class="service-card border even:border-t-0 even:border-b-0 bg-white rounded-md"
          v-for="(service, i) in search.filter(
            (service) => service.service_status.toLowerCase() === 'approved'
          )"
          :key="{ i }"
          data-aos="zoom-out-right"
        >
          <NuxtLink :to="`/classified-categories/details/${service.id}`">
            <div
              class="flex flex-col pl-3 pr-3 py-2.5 sm:flex-row sm:items-center w-full"
            >
              <div
                class="flex flex-col sm:flex-row sm:items-center justify-between w-full max-sm:relative"
              >
                <div class="flex flex-row gap-2">
                  <div class="mt-2">
                    <NuxtImg
                      v-if="service.medias[0]?.image"
                      :src="service.medias[0].image"
                      class="size-24 rounded-md"
                    />
                    <img
                      v-else
                      :src="service.category_details.image"
                      class="size-24 rounded-md"
                    />
                  </div>
                  <div class="flex-1 text-sm sm:text-base">
                    <h3
                      class="text-base font-semibold sm:mb-1.5 text-left line-clamp-2 first-letter:uppercase"
                    >
                      {{ service?.title }}
                    </h3>

                    <div
                      class="grid grid-cols-2 sm:flex flex-wrap items-center sm:items-start gap-y-1 gap-x-4 sm:gap-1 text-gray-600"
                    >
                      <div class="flex gap-2 col-span-2">
                        <p
                          class="text-sm md:text-base sm:hidden font-semibold text-green-950"
                        >
                          <UIcon name="i-mdi:currency-bdt" />
                          {{
                            service.negotiable ? "Negotiable" : service.price
                          }}
                        </p>

                        <p class="inline-flex gap-1 items-center">
                          <UIcon name="i-tabler:category-filled" />
                          <span class="text-sm">{{
                            service?.category_details.title
                          }}</span>
                        </p>
                      </div>
                      <p class="inline-flex gap-1 col-span-2">
                        <UIcon
                          name="i-heroicons-map-pin-solid"
                          class="mt-0.5"
                        />
                        <span class="text-sm first-letter:uppercase flex-1">{{
                          service?.location
                        }}</span>
                      </p>
                      <div class="flex col-span-2">
                        <div class="flex gap-1 items-center flex-1">
                          <UIcon name="i-heroicons-clock-solid" />
                          <div class="flex-1">
                            <span class="text-sm"
                              >Posted: {{ formatDate(service?.created_at) }},
                              By:
                              <span class="text-green-600"
                                >{{ service.user?.name.slice(0, 6) }}***</span
                              ></span
                            >
                          </div>
                        </div>
                      </div>
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
        <UDivider label="" class="mt-2 sm:mt-5" />
        <h3 class="text-xl font-semibold mt-6 text-green-900">
          Nearby location's ads
        </h3>
      </div>
      <div v-if="isLoading">
        <CommonPreloader text="Searching for ads in your city..." />
      </div>
      <TransitionGroup
        name="empty-state"
        tag="div"
        appear
        v-if="searchError"
        class="mt-3 mb-2 sm:mt-6 sm:mb-8"
      >
        <UCard
          key="empty-state"
          class="py-0 sm:py-12 px-4 text-center relative overflow-hidden"
          :ui="{
            background: 'bg-gradient-to-br from-white to-slate-50',
            ring: 'ring-1 ring-slate-200',
            shadow: 'shadow-sm hover:shadow-md transition-shadow duration-300',
          }"
        >
          <!-- Decorative elements -->
          <div
            class="absolute top-0 right-0 w-32 h-32 bg-primary-50 rounded-full translate-x-16 -translate-y-16 opacity-70 blur-2xl"
          ></div>
          <div
            class="absolute bottom-0 left-0 w-24 h-24 bg-amber-50 rounded-full -translate-x-12 translate-y-12 opacity-70 blur-2xl"
          ></div>

          <!-- Animated search illustration -->
          <div class="mb-6 relative z-10">
            <div class="search-animation mx-auto">
              <UIcon name="i-heroicons-magnifying-glass" class="search-icon" />
              <div class="search-pulse"></div>
              <div class="search-location">
                <UIcon name="i-heroicons-map-pin" class="location-pin" />
              </div>
            </div>
          </div>

          <!-- Message -->

          <p class="text-gray-600 max-w-md mx-auto mb-6 fade-in-up-delay">
            আপনার লোকেশনে এই ক্যাটাগরিতে এখনো কোনো পোস্ট পড়েনি, পার্শবর্তী
            এলাকা সিলেক্ট করুন
          </p>

          <!-- Action buttons -->
          <div class="flex flex-wrap justify-center gap-3 fade-in-up-delay-2">
            <UButton
              color="gray"
              variant="ghost"
              :label="t('change_location')"
              icon="i-heroicons-map"
              @click="clearLocation"
            />
            <UButton
              color="primary"
              variant="outline"
              :label="t('post_classified')"
              icon="i-heroicons-plus"
              to="/classified-categories/post/"
              class="pulse-effect"
            />
          </div>
        </UCard>
      </TransitionGroup>
      <UDivider v-if="searchError" label="" class="mt-3 sm:mt-5" />
      <h3 v-if="searchError" class="text-xl font-semibold mt-6 text-green-900">
        {{ $t("nearby_location") }}
      </h3>

      <div class="services mt-3" v-if="nearby_services?.length">
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
          v-for="(service, i) in nearby_services.filter(
            (service) => service.service_status.toLowerCase() === 'approved'
          )"
          :key="{ i }"
        >
          <NuxtLink :to="`/classified-categories/details/${service.id}`">
            <div
              class="flex flex-col pl-3 pr-3 py-2.5 sm:flex-row sm:items-center w-full"
            >
              <div
                class="flex flex-col sm:flex-row sm:items-center justify-between w-full max-sm:relative"
              >
                <div class="flex flex-row gap-2 items-start">
                  <div class="size-24 mt-2">
                    <NuxtImg
                      v-if="service.medias[0]?.image"
                      :src="service.medias[0].image"
                      class="object-cover rounded-md"
                    />
                    <img
                      v-else
                      :src="service.category_details.image"
                      class="size-10 sm:size-14 rounded-md"
                    />
                  </div>
                  <div class="flex-1 text-sm sm:text-base">
                    <h3
                      class="text-sm sm:text-base font-semibold mb-1.5 text-left line-clamp-2 first-letter:uppercase"
                    >
                      {{ service?.title }}
                    </h3>

                    <div
                      class="grid grid-cols-2 sm:flex flex-wrap items-center sm:items-start gap-y-1 gap-x-4 sm:gap-1 text-gray-600"
                    >
                      <div class="flex gap-2 col-span-2">
                        <p
                          class="text-sm md:text-base sm:hidden font-semibold text-green-950"
                        >
                          <UIcon name="i-mdi:currency-bdt" />
                          {{
                            service.negotiable ? "Negotiable" : service.price
                          }}
                        </p>

                        <p class="inline-flex gap-1 items-center">
                          <UIcon name="i-tabler:category-filled" />
                          <span class="text-sm">{{
                            service?.category_details.title
                          }}</span>
                        </p>
                      </div>
                      <p class="inline-flex gap-1 col-span-2">
                        <UIcon
                          name="i-heroicons-map-pin-solid"
                          class="mt-0.5"
                        />
                        <span class="text-sm first-letter:uppercase flex-1">{{
                          service?.location
                        }}</span>
                      </p>
                      <div class="flex col-span-2">
                        <div class="flex gap-1 items-center flex-1">
                          <UIcon name="i-heroicons-clock-solid" />
                          <div class="flex-1">
                            <span class="text-sm"
                              >Posted: {{ formatDate(service?.created_at) }},
                              By:
                              <span class="text-green-600"
                                >{{ service.user?.name.slice(0, 6) }}***</span
                              ></span
                            >
                          </div>
                        </div>
                      </div>
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
      <UCard
        v-else-if="!isNearByLoading && !nearby_services.length"
        class="py-16 text-center mt-6"
      >
        <p>
          দুঃখিত, আপনার আশেপাশের উপজেলাতেও এই ক্যাটাগরিতে কোনো পোস্ট পড়েনি,
          পার্শবর্তী জেলা সিলেক্ট করুন
        </p>
      </UCard>
      <h3 class="mt-3 mb-2 sm:my-6 text-lg font-bold text-green-950">
        AdsyAI Bot
        <UIcon class="text-2xl" name="i-carbon:bot" />
      </h3>
      <UCard
        v-if="form.city"
        class="text-center border border-green-900/30 border-dashed"
        :ui="{
          background: 'bg-slate-50 dark:bg-gray-900',
          ring: 'ring-0 ring-gray-200 dark:ring-gray-800',
        }"
      >
        <AiResults
          :country="form.country"
          :state="form.state"
          :city="form.city"
          :upazila="form.upazila"
          :business_type="categoryDetails?.business_type"
        />
      </UCard>
    </UContainer>
  </PublicSection>
</template>

<script setup>
useHead({
  title:
    "AdsyClub – Bangladesh’s 1st Social Business Network: Earn Money, Connect with Society, and Find the Services You Need!",
});
const { t } = useI18n();
const { get } = useApi();
const location = useCookie("location");
const { formatDate } = useUtils();
const isLoading = ref(false);
const isNearByLoading = ref(false);
const searchLocationOption = ref(false);
const router = useRoute();
const form = ref({
  country: "Bangladesh",
  state: location.value?.state || "",
  city: location.value?.city || "",
  upazila: location.value?.upazila || "",
  title: "",
  category: "",
});

const categoryTitle = ref("");
const services = ref([]);
const search = ref([]);
const searchError = ref(false);

const categoryDetails = ref({});
async function getCategoryDetails() {
  try {
    const { data } = await get(
      `/details/classified-categories/${router.params.id}/`
    );

    categoryDetails.value = data;
  } catch (error) {
    console.error(error);
  }
}
await getCategoryDetails();

// geo filter

const regions = ref([]);
const cities = ref();
const upazilas = ref();

const regions_response = await get(
  `/geo/regions/?country_name_eng=${form.value.country}`
);
regions.value = regions_response.data;

if (form.value.state) {
  const cities_response = await get(
    `/geo/cities/?region_name_eng=${form.value.state}`
  );
  cities.value = cities_response.data;
  console.log(cities_response.data);
}
if (form.value.city) {
  const thana_response = await get(
    `/geo/upazila/?city_name_eng=${form.value.city}`
  );
  upazilas.value = thana_response.data;
  console.log(thana_response.data);
}

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
    `/classified-posts/filter/?category=${router.params.id}&title=${form.value.title}&country=${form.value.country}&state=${form.value.state}&city=${form.value.city}&upazila=${form.value.upazila}`
  );

  setTimeout(() => {
    if (res.data.length > 0) {
      search.value = res.data;
      searchError.value = false;
    } else {
      searchError.value = true;
    }
    isLoading.value = false;
  }, 2000);
}
if (location.value) {
  filterSearch();
}
const nearby_services = ref([]);
// Add this function to your script setup
async function fetchNearbyAds() {
  if (!location.value) return;

  isNearByLoading.value = true;

  // First try: search in the same city, any upazila
  const citySearchRes = await get(
    `/classified-posts/filter/?category=${router.params.id}&country=${form.value.country}&state=${form.value.state}&city=${form.value.city}`
  );

  // If city search has results, use those
  console.log("near by", citySearchRes.data);
  if (citySearchRes.data.length > 0) {
    nearby_services.value = citySearchRes.data.filter(
      (service) =>
        service.service_status.toLowerCase() === "approved" &&
        service.active_service
    );
    isNearByLoading.value = false;
    return;
  }

  // Second try: search in the same state, any city
  const stateSearchRes = await get(
    `/classified-posts/filter/?category=${router.params.id}&country=${form.value.country}&state=${form.value.state}`
  );

  nearby_services.value = stateSearchRes.data.filter(
    (service) =>
      service.service_status.toLowerCase() === "approved" &&
      service.active_service
  );

  isNearByLoading.value = false;
}

await fetchNearbyAds();

function clearLocation() {
  location.value = null;
  window.location.reload();
}
</script>
<style scoped>
/* Empty state transitions */
.empty-state-enter-active,
.empty-state-leave-active {
  transition: all 0.5s ease;
}

.empty-state-enter-from,
.empty-state-leave-to {
  opacity: 0;
  transform: translateY(30px);
}

/* Fade in up animation with delays */
.fade-in-up {
  animation: fadeInUp 0.7s ease forwards;
}

.fade-in-up-delay {
  animation: fadeInUp 0.7s ease forwards;
  animation-delay: 0.2s;
  opacity: 0;
}

.fade-in-up-delay-2 {
  animation: fadeInUp 0.7s ease forwards;
  animation-delay: 0.4s;
  opacity: 0;
}

@keyframes fadeInUp {
  from {
    opacity: 0;
    transform: translateY(20px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}

/* Search animation */
.search-animation {
  position: relative;
  width: 100px;
  height: 100px;
  margin: 0 auto;
}

.search-icon {
  position: absolute;
  width: 60px;
  height: 60px;
  top: 20px;
  left: 20px;
  color: #4f46e5;
  animation: floatIcon 3s ease-in-out infinite;
  z-index: 2;
}

.search-pulse {
  position: absolute;
  width: 100%;
  height: 100%;
  border-radius: 50%;
  background: rgba(79, 70, 229, 0.1);
  animation: pulse 2s infinite;
}

.search-location {
  position: absolute;
  bottom: 10px;
  right: 10px;
}

.location-pin {
  width: 30px;
  height: 30px;
  color: #ef4444;
  animation: bounce 2s ease infinite;
  transform-origin: bottom center;
}

.pulse-effect {
  position: relative;
}

.pulse-effect::after {
  content: "";
  position: absolute;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  border-radius: 0.375rem;
  animation: buttonPulse 2s infinite;
  box-shadow: 0 0 0 0 rgba(79, 70, 229, 0.7);
}

@keyframes floatIcon {
  0%,
  100% {
    transform: translateY(0);
  }
  50% {
    transform: translateY(-10px);
  }
}

@keyframes pulse {
  0% {
    transform: scale(0.8);
    opacity: 0.7;
  }
  50% {
    transform: scale(1);
    opacity: 0.3;
  }
  100% {
    transform: scale(0.8);
    opacity: 0.7;
  }
}

@keyframes bounce {
  0%,
  100% {
    transform: translateY(0);
  }
  50% {
    transform: translateY(-5px);
  }
}

@keyframes buttonPulse {
  0% {
    box-shadow: 0 0 0 0 rgba(79, 70, 229, 0.7);
  }
  70% {
    box-shadow: 0 0 0 10px rgba(79, 70, 229, 0);
  }
  100% {
    box-shadow: 0 0 0 0 rgba(79, 70, 229, 0);
  }
}
</style>
