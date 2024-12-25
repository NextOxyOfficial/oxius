<template>
  <div class="pb-10">
    <PublicSection id="classified-services">
      <UContainer
        :ui="{
          padding: 'px-2',
        }"
        class="relative"
      >
        <h2 class="text-2xl md:text-4xl max-sm:text-center mb-6 md:mb-8">
          {{ $t("classified_service") }}
        </h2>
        <UButtonGroup
          label="Search Category"
          class="my-5 md:my-8 justify-center flex !shadow-none"
          orientation="horizontal"
          size="md"
        >
          <UInput
            icon="i-heroicons-magnifying-glass-solid"
            type="search"
            size="md"
            color="white"
            placeholder="Search Category"
            v-model="title"
          />
          <UButton
            @click="handleSearch"
            size="md"
            color="primary"
            variant="solid"
            :label="t('search')"
          />
        </UButtonGroup>
        <UButton
          v-if="user?.user"
          class="absolute max-md:left-2 md:right-20 top-32 md:top-[72px]"
          size="md"
          color="primary"
          variant="solid"
          :label="t('my_post')"
          to="/my-classified-services/"
        />
        <div
          class="grid grid-cols-2 sm:grid-cols-3 lg:flex justify-center lg:flex-wrap gap-3 max-md:mt-[92px]"
        >
          <UCard
            class="text-center border border-dashed border-green-500 lg:w-[150px]"
            v-for="service in services?.results"
            :key="service.id"
            :ui="{
              body: {
                padding: 'px-3 py-3 sm:p-2.5',
              },
              ring: '',
              background: 'bg-green-50/70',
              shadow: 'shadow-md',
            }"
          >
            <ULink
              :to="`/classified-categories/${service.id}`"
              active-class="text-primary"
              inactive-class="text-gray-500 dark:text-gray-400"
            >
              <NuxtImg
                :src="service?.image"
                :title="service.title"
                class="size-10 mx-auto"
              />
              <h3 class="text-md mt-2">{{ service.title }}</h3>
            </ULink>
          </UCard>

          <UCard
            v-if="services && !services.count"
            class="py-16 text-center w-full"
          >
            <p>No Categories have been found!</p>
          </UCard>
        </div>
        <div class="text-center mt-8">
          <UButton
            size="md"
            color="primary"
            variant="outline"
            label="Load More"
            @click="loadMore(services.next)"
            v-if="services && services.results && services.next"
          />
        </div>
      </UContainer>
    </PublicSection>
    <PublicSection id="micro-gigs">
      <UContainer>
        <h2 class="text-2xl md:text-4xl mb-6 md:mb-12 text-center">
          {{ $t("micro_gigs") }} ({{ $t("quick_earn") }})
        </h2>
        <AccountBalance v-if="user" :user="user" :isUser="true" />
        <UCard
          :ui="{
            body: { padding: 'p-0' },
            header: { padding: 'p-0' },
            rounded: 'rounded-md overflow-hidden',
            ring: 'max-sm:ring-0',
            shadow: '',
          }"
        >
          <div class="flex flex-col md:flex-row w-full">
            <div
              class="w-full md:w-60 bg-slate-50/70 border-dashed border max-sm:rounded-lg max-sm:overflow-hidden"
            >
              <ul class="py-2 text-center">
                <li>
                  <p
                    class="px-2 font-semibold pb-2 text-left"
                    @click.prevent="selectedCategory = null"
                  >
                    {{ $t("all_category") }}
                  </p>
                  <UDivider label="" class="mb-2 px-4" />
                </li>

                <li v-for="category in categoryArray" :key="category.id">
                  <UButton
                    :ui="{
                      rounded: '',
                    }"
                    size="md"
                    variant="ghost"
                    color="white"
                    class="w-full text-base px-4 py-0 font-normal text-blue-950"
                    @click.prevent="selectCategory(category.category)"
                    >{{ category.category }} ({{ category.active }})
                  </UButton>
                </li>
              </ul>
            </div>
            <div
              class="space-y-[0.5px] flex-1 max-sm:border max-sm:pt-2 max-sm:mt-4 max-sm:rounded-md"
            >
              <p class="px-2 font-semibold pb-3.5">
                {{ $t("available_gigs") }}
              </p>
              <UCard
                v-for="(gig, i) in filteredMicroGigs.filter(
                  (gig) =>
                    gig.gig_status.toLowerCase() === 'approved' &&
                    gig.active_gig
                )"
                :key="i"
                :ui="{
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
                  ring: 'max-sm:ring-1',
                }"
                class="flex flex-col px-3 py-2.5 sm:flex-row sm:items-center w-full bg-slate-50/70"
              >
                <div class="flex flex-col sm:flex-row sm:justify-between">
                  <div class="flex gap-4">
                    <div>
                      <NuxtImg
                        v-if="gig.medias[0]?.image && errorIndex.includes(i)"
                        :src="
                          errorIndex.includes(i)
                            ? gig.category_details?.image
                            : gig.medias[0]?.image
                        "
                        class="size-14 rounded-full"
                        @error="handleImageError(i)"
                      />
                      <NuxtImg
                        v-else-if="
                          gig.medias[0]?.image && !errorIndex.includes(i)
                        "
                        :src="gig.medias[0]?.image"
                        class="size-14 rounded-full"
                        @error="handleImageError(i)"
                      />
                      <NuxtImg
                        v-else
                        :src="gig.category_details?.image"
                        alt="No Image"
                        class="size-14 rounded-full"
                      />
                    </div>
                    <div>
                      <h3 class="text-base font-semibold mb-1.5 capitalize">
                        {{ gig.title }}
                      </h3>
                      <div class="flex gap-4">
                        <div class="flex gap-1 items-center">
                          <UIcon name="i-heroicons-bell-solid" />
                          <p class="text-sm">
                            <span class="">{{ gig.filled_quantity }}</span> /
                            <span class="text-green-600">{{
                              gig.required_quantity
                            }}</span>
                          </p>
                        </div>
                      </div>
                    </div>
                  </div>
                  <div
                    class="flex gap-16 items-center justify-between max-sm:pl-[70px]"
                  >
                    <p
                      class="font-bold text-base text-green-900 inline-flex items-center"
                    >
                      <UIcon name="i-mdi:currency-bdt" class="text-base" />{{
                        gig.price
                      }}
                    </p>

                    <UButton
                      :disabled="user?.user?.id === gig.user"
                      size="sm"
                      color="primary"
                      variant="outline"
                      :to="`/order/${gig.id}/`"
                    >
                      Earn
                    </UButton>
                  </div>
                </div>
              </UCard>
            </div>
          </div>
        </UCard>
      </UContainer>
    </PublicSection>
    <UModal
      v-model="isOpen"
      prevent-close
      :ui="{
        width: 'w-full sm:max-w-4xl',
      }"
    >
      <GigsViewer @close="isOpen = false" :gid="previewGid" />
    </UModal>
  </div>
</template>

<script setup>
const { t } = useI18n();
const isOpen = ref(false);
const { get, staticURL } = useApi();
const { user } = useAuth();
const services = ref([]);
const microGigs = ref([]);
const categoryArray = ref([]);
const selectedCategory = ref(null);
const title = ref(null);

useHead({
  title: "AdsyClub | Earn Quick Money & Simplify Daily Life",
});
// const categoryCounts = microGigs.value.reduce((acc, gig) => {
//   const category = gig.category;
//   if (!acc[category]) {
//     acc[category] = 1;
//   } else {
//     acc[category]++;
//   }
//   return acc;
// }, {});
// Convert the result into an array of objects
// categoryArray.value = Object.entries(categoryCounts).map(
//   ([category, count]) => ({ category, count })
// );
const errorIndex = ref([]);
function handleImageError(index) {
  console.log(`Broken image detected at index: ${index}`);
  if (!errorIndex.value.includes(index)) {
    errorIndex.value.push(index); // Add index to errorIndex
  }
}

async function getClassifiedCategories() {
  const [serviceResponse, gigResponse] = await Promise.all([
    get("/classified-categories/"),
    get("/micro-gigs/"),
  ]);

  services.value = serviceResponse.data;
  microGigs.value = gigResponse.data;
  console.log(gigResponse.data);

  const categoryCounts = microGigs.value.reduce((acc, gig) => {
    const category = gig.category_details.title;
    const isActiveAndApproved = gig.active_gig && gig.gig_status === "approved";

    if (!acc[category]) {
      acc[category] = { total: 0, active: 0 };
    }

    acc[category].total++;
    if (isActiveAndApproved) {
      acc[category].active++;
    }

    return acc;
  }, {});

  categoryArray.value = Object.entries(categoryCounts).map(
    ([category, { total, active }]) => ({ category, total, active })
  );
}
const previewGid = ref();
function showGig(gid) {
  previewGid.value = gid;
  isOpen.value = true;
}
setTimeout(() => {
  getClassifiedCategories();
}, 20); // Filtered microGigs based on selected category
const filteredMicroGigs = computed(() => {
  if (!selectedCategory.value) {
    return microGigs.value; // Show all products if no category is selected
  }
  return microGigs.value.filter(
    (gig) => gig.category_details?.title === selectedCategory.value
  );
}); // Method to select a category
const selectCategory = (category) => {
  selectedCategory.value = category || null;
};

const loadMore = async (url) => {
  const getRecentNext = async (url) => {
    const res = await $fetch(`${url}`);
    console.log(res);
    services.value.next = res.next;
    services.value.results = [...services.value.results, ...res.results];
    // recents.value.next = data?.value?.next;
  };
  // url = url.split("/api/");
  // url = baseURL + "/api/" + url[1];
  // getRecentsNext(url);
  getRecentNext(url);
};

async function handleSearch() {
  try {
    const res = await get(`/classified-categories/?title=${title.value}`);
    console.log(res);
    services.value = res.data;
  } catch (error) {
    console.log(error);
  }
}

watch(
  () => (title.value ? title.value.trim() : ""),
  async (newValue) => {
    if (!newValue) {
      try {
        const res = await get(`/classified-categories/`);
        console.log(res);
        services.value = res.data;
      } catch (error) {
        console.error("Error fetching classified categories:", error);
      }
    }
  }
);
</script>
