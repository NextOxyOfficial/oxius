<template>
  <PublicSection>
    <UContainer>
      <h2
        v-if="categoryTitle"
        class="text-center text-3xl sm:text-4xl my-3 sm:my-6"
      >
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
            label="Post Ads"
            to="/classified-categories/post/"
          />
        </div>
      </div>
      <div
        class="flex flex-col md:flex-row justify-between md:items-end gap-1.5 sm:gap-4"
      >
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
            option-attribute="name_eng"
            value-attribute="name_eng"
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
            option-attribute="name_eng"
            value-attribute="name_eng"
          />
        </UFormGroup>
        <UFormGroup class="md:w-1/4">
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
        <UButtonGroup size="md" class="flex-1 md:flex-none md:w-2/4">
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
      </div>

      <div class="mt-5 hidden sm:block">
        <UButton
          class="px-8"
          size="lg"
          color="primary"
          variant="solid"
          label="Post Ads"
          to="/classified-categories/post/"
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
          class="service-card border even:border-t-0 even:border-b-0 bg-white rounded-md"
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
                class="flex flex-col sm:flex-row sm:items-center justify-between w-full max-sm:relative"
              >
                <div class="flex flex-row gap-4">
                  <div>
                    <NuxtImg
                      v-if="service.medias[0]?.image"
                      :src="service.medias[0].image"
                      class="size-10 sm:size-14 rounded-md"
                    />
                    <img
                      v-else
                      :src="service.category_details.image"
                      class="size-10 sm:size-14 rounded-md"
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
        <!-- <h3 class="text-xl font-semibold mt-6 text-green-900">
          Nearby location's ads
        </h3> -->
      </div>
      <div v-if="isLoading">
        <CommonPreloader text="Searching for ads in your city..." />
      </div>
      <UCard v-if="searchError" class="py-4 sm:py-16 text-center mt-3 sm:mt-6">
        <p>No offers have been found!</p>
      </UCard>
      <UDivider v-if="searchError" label="" class="mt-3 sm:mt-5" />
      <!-- <h3
				v-if="searchError"
				class="text-xl font-semibold mt-6 text-green-900"
			>
				Nearby location's ads
			</h3>

			<div
				class="services mt-3"
				v-if="services?.length"
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
								class="flex flex-col sm:flex-row sm:items-center justify-between w-full max-sm:relative"
							>
								<div class="flex flex-row gap-4 items-start">
									<div class="w-10 sm:w-14">
										<NuxtImg
											v-if="service.medias[0]?.image"
											:src="service.medias[0].image"
											class="size-10 sm:size-14 object-cover rounded-md"
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
				v-else
				class="py-16 text-center mt-6"
			>
				<p>No offers have been found!</p>
			</UCard> -->
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
          :business_type="router.query.business_type"
        />
      </UCard>
    </UContainer>
  </PublicSection>
</template>

<script setup>
const { get } = useApi();
const location = useCookie("location");
const { formatDate } = useUtils();
const isLoading = ref(false);

useHead({
  title:
    "AdsyClub | Earn Money, Connect with Society & Find the services you need!",
});

const form = ref({
  country: "Bangladesh",
  state: location.value?.state || "",
  city: location.value?.city || "",
  upazila: location.value?.upazila || "",
  title: "",
  category: "",
});
console.log(location.value);

const categoryTitle = ref("");
const services = ref([]);
const search = ref([]);
const searchError = ref(false);
const router = useRoute();

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
</script>
