<template>
  <PublicSection>
    <UContainer>
      <h2
        class="text-center text-2xl sm:text-2xl my-3 sm:my-6 max-sm:hidden"
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
            inactive-class="text-gray-600 dark:text-gray-600"
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
          class="relative z-10 flex items-center justify-between px-3 pl-12 rounded-lg border border-primary-100 py-5"
        >
          <!-- Location path with icons -->
          <div class="flex items-center flex-wrap location-path">
            <!-- Show country if allOverBangladesh is true or only country is set -->
            <div
              v-if="
                location?.allOverBangladesh ||
                (location?.country && !location?.state)
              "
              class="location-segment flex items-center"
              data-location="country"
            >
              <UIcon
                name="i-heroicons-globe-asia-australia"
                class="text-primary-600 mr-1.5 animate-pulse-slow"
              />
              <span class="font-medium text-gray-800">{{
                location?.country || "Bangladesh"
              }}</span>
              <span
                v-if="location?.allOverBangladesh"
                class="ml-2 text-xs bg-primary-100 text-primary-700 px-2 py-0.5 rounded-full"
              >
                All over {{ location?.country || "Bangladesh" }}
              </span>
            </div>

            <!-- Show state, city, upazila only if not allOverBangladesh -->
            <template v-if="!location?.allOverBangladesh">
              <div
                v-if="location?.state"
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
                  v-if="location?.city"
                  name="i-heroicons-chevron-right"
                  class="mx-1.5 text-gray-600"
                />
              </div>

              <div
                v-if="location?.city"
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
                  v-if="location?.upazila"
                  name="i-heroicons-chevron-right"
                  class="mx-1.5 text-gray-600"
                />
              </div>

              <div
                v-if="location?.upazila"
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
            </template>
          </div>
          <UTooltip text="Change Location" class="me-auto">
            <UButton
              icon="i-heroicons-map-pin"
              size="md"
              color="primary"
              variant="ghost"
              trailing-icon="i-heroicons-pencil-square"
              class="edit-location-btn ml-2 relative overflow-hidden"
              @click="handleClearLocation"
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
              :label="$t('search')"
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
            :label="$t('post_classified')"
            icon="i-heroicons-plus"
            to="/classified-categories/post/"
            class="pulse-effect"
          />
        </div>
      </div>
      <div class="search mt-4" v-if="search?.length">
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
          <NuxtLink :to="`/classified-categories/details/${service.slug}`">
            <div
              class="flex flex-col pl-3 pr-3 py-2.5 sm:flex-row sm:items-center w-full"
            >
              <div
                class="flex flex-col sm:flex-row sm:items-center justify-between w-full max-sm:relative"
              >
                <div class="flex flex-row gap-2">
                  <div class="mt-2">
                    <img
                      :src="service.medias?.[0]?.image 
                        ? getImageUrl(service.medias[0].image) 
                        : getImageUrl(service.category_details?.image)"
                      :alt="service.title"
                      class="object-contain size-24 rounded-md"
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
                      <div class="flex gap-2 col-span-2 flex-wrap">
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
                    </div>
                    <div class="flex col-span-2 mt-1 sm:mt-2">
                      <div class="flex-1">
                        <div class="">
                          <span
                            class="text-sm inline-flex gap-1 items-center flex-wrap"
                          >
                            <UIcon name="i-heroicons-clock-solid" />Posted:
                            {{ formatDate(service?.created_at) }}, By:
                            <span class="text-green-600"
                              >{{ service.user?.name.slice(0, 6) }}***</span
                            ></span
                          >
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
        <!-- Simple Pagination Section -->
        <div
          v-if="search?.length && pagination && totalPages > 1"
          class="mt-6 mb-4"
        >
          <div class="flex items-center justify-center gap-2 text-sm">
            <span>Page {{ currentPage }} of {{ totalPages }}</span>

            <!-- Previous button -->
            <button
              :disabled="currentPage === 1"
              @click="goToPage(currentPage - 1)"
              class="px-3 py-1 border border-gray-300 rounded disabled:opacity-50 disabled:cursor-not-allowed hover:bg-gray-50"
            >
              Previous
            </button>

            <!-- Page numbers -->
            <button
              v-for="page in getVisiblePages()"
              :key="page"
              @click="goToPage(page)"
              class="px-3 py-1 border border-gray-300 rounded hover:bg-gray-50"
              :class="
                page === currentPage
                  ? 'bg-blue-500 text-white border-blue-500'
                  : ''
              "
            >
              {{ page }}
            </button>

            <!-- Next button -->
            <button
              :disabled="currentPage === totalPages"
              @click="goToPage(currentPage + 1)"
              class="px-3 py-1 border border-gray-300 rounded disabled:opacity-50 disabled:cursor-not-allowed hover:bg-gray-50"
            >
              Next
            </button>
          </div>
        </div>

        <UDivider label="" class="mt-2 sm:mt-5" />
        <h3
          v-if="!location?.allOverBangladesh"
          class="text-xl font-semibold mt-6 text-green-900"
        >
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
            shadow: 'shadow-sm hover:shadow-sm transition-shadow duration-300',
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
              :label="$t('change_location')"
              icon="i-heroicons-map"
              @click="handleClearLocation"
            />
            <UButton
              color="primary"
              variant="outline"
              :label="$t('post_classified')"
              icon="i-heroicons-plus"
              to="/classified-categories/post/"
              class="pulse-effect"
            />
          </div>
        </UCard>
      </TransitionGroup>
      <UDivider v-if="searchError" label="" class="mt-3 sm:mt-5" />
      <h3
        v-if="searchError && !location?.allOverBangladesh"
        class="text-xl font-semibold mt-6 text-green-900"
      >
        {{ $t("nearby_location") }}
      </h3>

      <div
        class="services mt-3"
        v-if="filteredNearbyServices?.length && !location?.allOverBangladesh"
      >
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
          v-for="service in filteredNearbyServices"
          :key="service.id || service.slug"
        >
          <NuxtLink :to="`/classified-categories/details/${service.slug}`">
            <div
              class="flex flex-col pl-3 pr-3 py-2.5 sm:flex-row sm:items-center w-full"
            >
              <div
                class="flex flex-col sm:flex-row sm:items-center justify-between w-full max-sm:relative"
              >
                <div class="flex flex-row gap-2 items-start">
                  <div class="mt-2">
                    <img
                      :src="service.medias?.[0]?.image 
                        ? getImageUrl(service.medias[0].image) 
                        : getImageUrl(service.category_details?.image)"
                      :alt="service.title"
                      class="object-contain size-24 rounded-md"
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
                      <div class="flex gap-2 col-span-2 flex-wrap">
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
                    </div>
                    <div class="flex col-span-2 mt-1 sm:mt-2">
                      <div class="flex-1">
                        <div class="">
                          <span
                            class="text-sm inline-flex gap-1 items-center flex-wrap"
                            ><UIcon name="i-heroicons-clock-solid" />Posted:
                            {{ formatDate(service?.created_at) }}, By:
                            <span class="text-green-600"
                              >{{ service.user?.name.slice(0, 6) }}***</span
                            ></span
                          >
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
        v-if="
          !isNearByLoading &&
          !filteredNearbyServices?.length &&
          !location?.allOverBangladesh &&
          searchError
        "
        class="py-8 text-center mt-4"
        :ui="{
          background: 'bg-slate-50',
          ring: 'ring-1 ring-slate-200',
        }"
      >
        <div class="flex flex-col items-center gap-2">
          <UIcon name="i-heroicons-map-pin" class="text-3xl text-gray-400" />
          <p class="text-gray-600 text-sm">
            দুঃখিত, আপনার আশেপাশের এলাকাতেও এই ক্যাটাগরিতে কোনো পোস্ট পাওয়া যায়নি।
            পার্শবর্তী জেলা সিলেক্ট করুন।
          </p>
        </div>
      </UCard>
      <h3 class="mt-3 mb-2 sm:my-6 text-lg font-semibold text-green-950">
        AdsyAI Bot
        <UIcon class="text-xl" name="i-carbon:bot" />
      </h3>
      <UCard
        v-if="form.city || location?.allOverBangladesh"
        class="text-center border border-green-900/30 border-dashed"
        :ui="{
          background: 'bg-slate-50 dark:bg-gray-900',
          ring: 'ring-0 ring-gray-200 dark:ring-gray-800',
        }"
      >
        <AiResults
          :country="form.country"
          :state="location?.allOverBangladesh ? 'All Bangladesh' : form.state"
          :city="location?.allOverBangladesh ? 'All Cities' : form.city"
          :upazila="location?.allOverBangladesh ? 'All Areas' : form.upazila"
          :business_type="categoryDetails?.business_type"
        />
      </UCard>
    </UContainer>
  </PublicSection>
</template>

<script setup>
useHead({
  title:
    "AdsyClub – Social Business Network: Earn Money, Connect with Society & Find the Services You Need!",
});
const { t } = useI18n();
const { get, staticURL } = useApi();
const { location, clearLocation } = useLocation(); // Use enhanced location composable
const { formatDate } = useUtils();

// Helper function to get full image URL
const getImageUrl = (url) => {
  if (!url) return '';
  if (url.startsWith('http://') || url.startsWith('https://')) return url;
  if (url.startsWith('/')) return staticURL + url;
  return staticURL + '/' + url;
};
const isLoading = ref(false);
const isNearByLoading = ref(false);
const searchLocationOption = ref(false);

// Pagination variables
const currentPage = ref(1);
const totalPages = ref(1);
const totalCount = ref(0);
const isLoadingMore = ref(false);
const hasMore = ref(false);
const pagination = ref(null);

// Handle scroll events for header compensation
const isScrolled = ref(false);
const handleScroll = () => {
  isScrolled.value = window.scrollY > 80;
};

import { useRoute } from "vue-router";
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

async function fetchServices() {
  const response = await get(
    `/classified-categories/${categoryDetails.value.id}/`
  );
  services.value = response.data?.filter(
    (service) =>
      service.service_status.toLowerCase() === "approved" &&
      service.active_service
  );
  // categoryTitle.value = response.data[0]?.category_details.title;
}
async function getCategoryDetails() {
  try {
    const { data } = await get(
      `/details/classified-categories/${router.params.id}/`
    );
    if (data) {
      categoryDetails.value = data;
      await fetchServices();
    }
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
}
if (form.value.city) {
  const thana_response = await get(
    `/geo/upazila/?city_name_eng=${form.value.city}`
  );
  upazilas.value = thana_response.data;
}

watch(
  () => form.value.state,
  async (newState) => {
    if (newState) {
      const cities_response = await get(
        `/geo/cities/?region_name_eng=${newState}`
      );
      cities.value = cities_response.data;
    }
  }
);

watch(
  () => form.value.city,
  async (newCity) => {
    if (newCity) {
      const thana_response = await get(
        `/geo/upazila/?city_name_eng=${newCity}`
      );
      upazilas.value = thana_response.data;
    }
  }
);

// geo filter

async function filterSearch(page = 1) {
  // Preserve allOverBangladesh flag if it exists in the current location
  const { title, category, ...rest } = form.value;
  const locationData = {
    ...rest,
    allOverBangladesh: location.value?.allOverBangladesh || false,
  };
  location.value = locationData;

  if (page === 1) {
    search.value = [];
    currentPage.value = 1;
    isLoading.value = true;
  } else {
    isLoadingMore.value = true;
  }

  // Build the API request URL with pagination
  let apiUrl = `/classified-posts/filter/?category=${categoryDetails.value.id}&title=${form.value.title}&country=${form.value.country}&page=${page}&page_size=20`;

  // Only add state, city, and upazila params if not showing all over Bangladesh
  if (!location.value?.allOverBangladesh) {
    apiUrl += `&state=${form.value.state}&city=${form.value.city}&upazila=${form.value.upazila}`;
  }

  const res = await get(apiUrl);

  setTimeout(() => {
    if (res.data) {
      if (res.data.results && res.data.results.length > 0) {
        if (page === 1) {
          search.value = res.data.results;
        } else {
          search.value = [...search.value, ...res.data.results];
        }

        // Update pagination info
        pagination.value = res.data;
        totalCount.value = res.data.count || 0;
        totalPages.value = Math.ceil(totalCount.value / 20);
        hasMore.value = !!res.data.next;
        currentPage.value = page;
        searchError.value = false;
      } else if (Array.isArray(res.data) && res.data.length > 0) {
        // Handle non-paginated response (fallback)
        if (page === 1) {
          search.value = res.data;
        } else {
          search.value = [...search.value, ...res.data];
        }
        searchError.value = false;
      } else {
        if (page === 1) {
          searchError.value = true;
        }
      }
    } else {
      if (page === 1) {
        searchError.value = true;
      }
    }

    isLoading.value = false;
    isLoadingMore.value = false;
  }, 2000);
}
if (location.value) {
  filterSearch();
}

// Function to load more posts
async function loadMorePosts() {
  if (!hasMore.value || isLoadingMore.value) return;
  await filterSearch(currentPage.value + 1);
}

// Function to go to specific page
async function goToPage(page) {
  if (page < 1 || page > totalPages.value || page === currentPage.value) return;
  await filterSearch(page);
}

// Helper function to get visible page numbers
function getVisiblePages() {
  const pages = [];
  const start = Math.max(1, currentPage.value - 2);
  const end = Math.min(totalPages.value, currentPage.value + 2);

  for (let i = start; i <= end; i++) {
    pages.push(i);
  }

  return pages;
}

const nearby_services = ref([]);

// Computed property to get unique nearby ads that are not in main search results
const filteredNearbyServices = computed(() => {
  if (!nearby_services.value?.length) return [];
  
  // Get IDs of services already shown in main search results
  const mainSearchIds = new Set(
    (search.value || []).map(s => s.id || s.slug)
  );
  
  // Filter out duplicates and already shown services
  const seen = new Set();
  return nearby_services.value
    .filter((service) => {
      // Must be approved and active
      if (service.service_status?.toLowerCase() !== 'approved' || !service.active_service) {
        return false;
      }
      
      // Skip if already in main search results
      const serviceId = service.id || service.slug;
      if (mainSearchIds.has(serviceId)) {
        return false;
      }
      
      // Skip duplicates within nearby services
      if (seen.has(serviceId)) {
        return false;
      }
      seen.add(serviceId);
      
      return true;
    })
    .slice(0, 10); // Limit to 10 nearby ads for cleaner display
});

// Add this function to your script setup
async function fetchNearbyAds() {
  if (!location.value) return;

  isNearByLoading.value = true;

  // If showing all over Bangladesh, skip nearby ads (main search handles it)
  if (location.value.allOverBangladesh) {
    nearby_services.value = [];
    isNearByLoading.value = false;
    return;
  }

  // First try: search in the same city, different upazila
  const citySearchRes = await get(
    `/classified-posts/filter/?category=${categoryDetails.value.id}&country=${form.value.country}&state=${form.value.state}&city=${form.value.city}&page=1&page_size=15`
  );

  let nearbyData = [];

  if (citySearchRes.data?.results) {
    nearbyData = citySearchRes.data.results;
  } else if (Array.isArray(citySearchRes.data)) {
    nearbyData = citySearchRes.data;
  }

  // Filter to only approved and active services
  nearbyData = nearbyData.filter(
    (service) =>
      service.service_status?.toLowerCase() === "approved" &&
      service.active_service
  );

  if (nearbyData.length >= 3) {
    nearby_services.value = nearbyData;
    isNearByLoading.value = false;
    return;
  }

  // Second try: search in the same state (broader area)
  const stateSearchRes = await get(
    `/classified-posts/filter/?category=${categoryDetails.value.id}&country=${form.value.country}&state=${form.value.state}&page=1&page_size=15`
  );

  let stateData = [];
  if (stateSearchRes.data?.results) {
    stateData = stateSearchRes.data.results;
  } else if (Array.isArray(stateSearchRes.data)) {
    stateData = stateSearchRes.data;
  }

  nearby_services.value = stateData.filter(
    (service) =>
      service.service_status?.toLowerCase() === "approved" &&
      service.active_service
  );

  isNearByLoading.value = false;
}

await fetchNearbyAds();

const handleClearLocation = () => {
  clearLocation();
  window.location.reload();
};

// Add scroll event listeners
onMounted(() => {
  window.addEventListener("scroll", handleScroll);
});

onUnmounted(() => {
  window.removeEventListener("scroll", handleScroll);
});

watch(
  [
    () => form.value.country,
    () => form.value.state,
    () => form.value.city,
    () => form.value.upazila,
    () => form.value.title,
  ],
  () => {
    currentPage.value = 1;
    filterSearch(1);
  }
);
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

/* Pagination specific animations - removed advanced animations */
</style>
