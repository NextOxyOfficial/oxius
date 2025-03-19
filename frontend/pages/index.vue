<template>
  <div class="pb-2">
    <PublicSection id="classified-services">
      <UContainer
        :ui="{
          padding: 'px-2',
        }"
        class="relative"
      >
        <div class="flex items-center justify-between mb-6 md:mb-8">
          <h2 class="text-2xl md:text-4xl max-sm:text-center">
            {{ $t("classified_service") }}
          </h2>
          <UButton
            v-if="user?.user"
            size="md"
            icon="i-material-symbols-light-lists-rounded"
            color="primary"
            variant="solid"
            label="My Services"
            to="/my-classified-services/"
          />
        </div>
        <form
          @submit.prevent="handleSearch"
          class="w-full max-w-xl mx-auto relative z-10"
        >
          <!-- Decorative elements with reduced blur for better performance -->
          <div
            class="absolute -top-4 -left-8 w-20 h-20 bg-emerald-400/10 rounded-full blur-xl -z-10 opacity-70"
          ></div>
          <div
            class="absolute -bottom-4 -right-8 w-24 h-24 bg-blue-400/10 rounded-full blur-xl -z-10 opacity-70"
          ></div>

          <!-- Search container with enhanced styling -->

          <div
            class="bg-white dark:bg-slate-800 rounded-2xl h-10 sm:h-14 shadow-sm border border-slate-200/70 dark:border-slate-700/50 overflow-hidden transition-all duration-300 hover:shadow-md group"
          >
            <!-- Accent line animation - only shows on hover, not on focus -->
            <div
              class="absolute top-0 left-0 right-0 h-0.5 bg-gradient-to-r from-emerald-500 via-blue-500 to-purple-500 transform scale-x-0 group-hover:scale-x-100 transition-transform origin-left duration-500"
            ></div>

            <div class="flex items-center">
              <!-- Search icon with animation -->
              <div class="pl-3 sm:pl-4 inline-flex items-center">
                <UIcon
                  name="i-heroicons-magnifying-glass"
                  class="w-4 h-4 sm:w-5 sm:h-5 text-slate-400 dark:text-slate-500 group-hover:text-emerald-500 dark:group-hover:text-emerald-400 transition-colors duration-300"
                />
              </div>

              <!-- Input with typing animation - completely removed focus styles -->
              <div class="relative flex-1">
                <input
                  ref="searchInput"
                  type="search"
                  v-model="title"
                  class="w-full py-2.5 sm:py-3.5 px-2 sm:px-3 bg-transparent border-0 focus:ring-0 focus:outline-none text-slate-800 dark:text-white placeholder-transparent text-sm sm:text-base"
                  :class="isLoading ? 'opacity-70' : 'opacity-100'"
                  @focus="stopTyping"
                  @blur="restartTypingIfEmpty"
                  style="-webkit-appearance: none; appearance: none"
                />

                <!-- Animated placeholder with cursor - adjusted for smaller mobile size -->
                <div
                  v-if="!title && showPlaceholder"
                  class="absolute left-2 sm:left-3 top-1/2 -translate-y-1/2 pointer-events-none flex items-center"
                >
                  <span
                    class="text-slate-400 dark:text-slate-500 text-sm sm:text-base"
                  >
                    <span>{{ displayedPlaceholder }}</span>
                    <span
                      class="inline-block w-0.5 h-4 sm:h-5 bg-emerald-500 dark:bg-emerald-400 ml-0.5 animate-blink"
                      :class="{ 'opacity-0': !cursorVisible }"
                    ></span>
                  </span>
                </div>
              </div>

              <!-- Enhanced search button - smaller on mobile -->
              <button
                type="submit"
                text="Search"
                class="relative overflow-hidden bg-gradient-to-r from-emerald-500 to-blue-500 hover:from-emerald-600 hover:to-blue-600 text-white py-2 sm:py-2.5 px-4 sm:px-6 rounded-lg font-medium transition-all duration-300 flex items-center gap-1 sm:gap-2 h-full -mt-[2px] sm:mt-0 mr-1.5"
                :disabled="isLoading"
              >
                <!-- Button background animation -->
                <span
                  class="absolute inset-0 w-full h-full bg-white/20 transform scale-x-0 group-hover:scale-x-100 transition-transform origin-left duration-500"
                ></span>

                <!-- Button content -->
                <span v-if="!isLoading" class="relative hidden sm:block"
                  >খুঁজুন</span
                >
                <UIcon
                  v-if="!isLoading"
                  name="i-heroicons-magnifying-glass"
                  class="w-4 h-4 sm:w-5 sm:h-5 relative"
                />
                <UIcon
                  v-else
                  name="i-heroicons-arrow-path"
                  class="w-4 h-4 sm:w-5 sm:h-5 animate-spin relative"
                />
              </button>
            </div>
          </div>
        </form>

        <div
          class="border bg-white w-full max-w-lg mx-auto rounded-md p-2 space-y-3 mb-5 relative z-50"
          v-if="
            searchServices?.results?.length || classifiedPosts.results?.length
          "
        >
          <ul
            class="flex flex-wrap gap-1"
            v-if="searchServices?.results?.length"
          >
            <li v-for="service in searchServices?.results" :key="service.id">
              <NuxtLink
                class="p-2 border border-dashed border-green-400 flex gap-1 items-center rounded-md bg-green-50"
                :to="`/classified-categories/${service.id}?business_type=${service.business_type}`"
              >
                <NuxtImg
                  :src="service?.image"
                  :title="service.title"
                  class="size-4"
                />
                <span class="truncate">{{ service.title }}</span></NuxtLink
              >
            </li>
          </ul>
          <UDivider
            label=""
            v-if="
              searchServices?.results?.length && classifiedPosts.results?.length
            "
          />
          <ul v-if="classifiedPosts.results?.length">
            <li v-for="service of classifiedPosts.results" :key="service.id">
              <NuxtLink
                :to="`/classified-categories/details/${service.id}?business_type=${service.business_type}`"
                class="capitalize p-2 hover:bg-green-50 flex gap-1 items-center"
              >
                <NuxtImg
                  v-if="service?.medias[0]?.image"
                  :src="service?.medias[0]?.image"
                  :title="service.title"
                  class="size-4"
                />
                <NuxtImg
                  v-else
                  :src="service?.category_details?.image"
                  :title="service.title"
                  class="size-4"
                />
                <span class="truncate">{{ service.title }}</span>
              </NuxtLink>
            </li>
          </ul>
        </div>
        <div
          class="grid grid-cols-2 sm:grid-cols-3 lg:flex justify-center lg:flex-wrap gap-3 mt-6"
        >
          <UCard
            class="text-center border border-dashed border-green-500 lg:w-[150px]"
            v-for="service in services?.results.filter(
              (item) => item.is_featured
            )"
            :key="service.id"
            :ui="{
              body: {
                padding: 'px-3 py-3 sm:p-2.5',
              },
              ring: '',
              background: 'bg-green-50',
              shadow: 'shadow-lg',
            }"
          >
            <ULink
              :to="`/classified-categories/${service.id}?business_type=${service.business_type}`"
              active-class="text-primary"
              inactive-class="text-gray-500 dark:text-gray-400"
            >
              <NuxtImg
                :src="service?.image"
                :title="service.title"
                class="size-9 mx-auto"
              />
              <h3 class="text-md mt-2">{{ service.title }}</h3>
            </ULink>
          </UCard>

          <UCard
            v-if="services && !services.count"
            class="py-16 text-center w-full col-span-2 sm:col-span-3"
          >
            <p>No categories have been found!</p>
          </UCard>
        </div>
        <div
          class="grid grid-cols-2 sm:grid-cols-3 lg:flex justify-center lg:flex-wrap gap-3 mt-6"
        >
          <UCard
            class="text-center border border-dashed border-green-500 lg:w-[150px]"
            v-for="service in services?.results.filter(
              (item) => !item.is_featured
            )"
            :key="service.id"
            :ui="{
              body: {
                padding: 'px-3 py-3 sm:p-2.5',
              },
              ring: '',
              background: 'bg-green-50',
              shadow: 'shadow-md',
            }"
          >
            <ULink
              :to="`/classified-categories/${service.id}?business_type=${service.business_type}`"
              active-class="text-primary"
              inactive-class="text-gray-500 dark:text-gray-400"
            >
              <NuxtImg
                :src="service?.image"
                :title="service.title"
                class="size-9 mx-auto"
              />
              <h3 class="text-md mt-2">{{ service.title }}</h3>
            </ULink>
          </UCard>

          <UCard
            v-if="services && !services.count"
            class="py-16 text-center w-full col-span-2 sm:col-span-3"
          >
            <p>No categories have been found!</p>
          </UCard>
        </div>
        <div class="text-center mt-8" v-if="services.next">
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

    <AdsScroll :ads="classifiedLatestPosts" sectionTitle="সাম্প্রতিক পোষ্ট" />
    <CommonProductSlider />
    <PublicSection id="micro-gigs">
      <UContainer>
        <h2 class="text-2xl md:text-4xl mb-6 md:mb-6 text-center">
          {{ $t("micro_gigs") }} ({{ $t("quick_earn") }})
        </h2>
        <AccountBalance v-if="user" :user="user" :isUser="true" />
        <NuxtLink
          to="/mobile-recharge"
          class="mb-6 bg-gray-100 shadow-md border border-gray-500 block py-2 px-4 max-w-fit mx-auto rounded-2xl"
        >
          <div class="flex gap-2">
            <h2 class="text-base text-gray-900 sm:text-xl text-center">
              Mobile Recharge
            </h2>
            <div class="flex justify-center gap-2">
              <NuxtImg
                v-for="operator in operators"
                :key="operator.id"
                :src="operator.icon"
                :title="operator.title"
                class="size-6"
              />
            </div>
          </div>
        </NuxtLink>
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

                <li v-for="category in categoryArray" :key="category?.id">
                  <UButton
                    :ui="{
                      rounded: '',
                    }"
                    size="md"
                    variant="ghost"
                    color="white"
                    class="w-full text-base px-4 py-0 font-normal text-blue-950 capitalize"
                    @click.prevent="selectCategory(category)"
                    >{{ category.category }} ({{ category.active }})
                  </UButton>
                </li>
              </ul>
            </div>
            <div
              class="space-y-[0.5px] flex-1 max-sm:border max-sm:pt-2 max-sm:mt-4 max-sm:rounded-md min-h-40"
            >
              <div class="flex justify-between">
                <p class="px-2 font-semibold pb-3.5">
                  {{ $t("available_gigs") }}
                </p>
                <USelectMenu
                  color="white"
                  size="sm"
                  class="w-40"
                  :options="microGigsFilter"
                  v-model="microGigsStatus"
                  @change="getMicroGigsByAvailability($event)"
                  placeholder="Filter"
                  value-attribute="value"
                  option-attribute="title"
                />
              </div>

              <UCard
                v-for="(gig, i) in microGigs"
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
                <div
                  class="flex flex-col sm:flex-row sm:justify-between"
                  v-if="gig.user"
                >
                  <div class="flex gap-4">
                    <div>
                      <!-- <NuxtImg
                        v-if="gig.medias[0]?.image && errorIndex.includes(i)"
                        :src="
                          errorIndex.includes(i)
                            ? gig.category_details?.image
                            : gig.medias[0]?.image
                        "
                        class="size-14 rounded-full"
                        @error="handleImageError(i)"
                      /> -->

                      <NuxtImg
                        v-if="!errorIndex.includes(i)"
                        :src="gig.category_details?.image"
                        class="w-12 rounded-full object-contain"
                        @error="handleImageError(i)"
                      />
                      <img
                        v-else
                        src="/static/frontend/images/no-image.jpg"
                        alt="No Image"
                        class="w-12 rounded-full"
                      />
                    </div>
                    <div class="flex-1">
                      <h3
                        class="text-[15px] leading-tight font-semibold mb-1.5 capitalize"
                      >
                        {{ gig.title }}
                      </h3>
                      <div class="flex gap-0.5 gap-x-4 md:gap-4 flex-wrap">
                        <div class="flex gap-1 items-center">
                          <UIcon name="i-heroicons-bell-solid" />
                          <p class="text-sm">
                            <span class="">{{ gig.filled_quantity }}</span> /
                            <span class="text-green-600">{{
                              gig.required_quantity
                            }}</span>
                          </p>
                        </div>
                        <p class="text-sm">
                          {{ formatDate(gig.created_at) }}
                        </p>
                        <p
                          class="font-bold text-base text-green-900 inline-flex items-center max-sm:ml-auto sm:hidden"
                        >
                          <UIcon
                            name="i-mdi:currency-bdt"
                            class="text-base"
                          />{{ gig.price }}
                        </p>
                        <div class="flex gap-1 items-center text-sm">
                          Posted By:
                          <p class="text-sm">
                            <span class="text-green-600"
                              >{{ gig.user.name.slice(0, 6) }}***</span
                            >
                          </p>
                        </div>
                        <UButton
                          v-if="user?.user && user?.user?.id !== gig.user.id"
                          :disabled="user?.user?.id === gig.user.id"
                          size="sm"
                          class="ml-auto sm:hidden w-[70px] justify-center"
                          color="primary"
                          variant="outline"
                          :to="`/order/${gig.id}/`"
                        >
                          Earn
                        </UButton>
                        <UButton
                          v-if="user?.user?.id === gig.user.id"
                          :disabled="user?.user?.id === gig.user.id"
                          size="sm"
                          class="ml-auto sm:hidden w-[70px] justify-center"
                          color="primary"
                          variant="outline"
                        >
                          Ineligible
                        </UButton>
                        <UButton
                          v-if="!user?.user"
                          size="sm"
                          class="ml-auto sm:hidden w-[70px] justify-center"
                          color="primary"
                          variant="outline"
                          :to="`/auth/login/`"
                        >
                          Earn
                        </UButton>
                      </div>
                    </div>
                  </div>
                  <div
                    class="hidden sm:flex gap-16 items-center justify-end md:justify-between max-sm:mt-2"
                  >
                    <p
                      class="font-bold text-base text-green-900 sm:inline-flex items-center hidden"
                    >
                      <UIcon name="i-mdi:currency-bdt" class="text-base" />{{
                        gig.price
                      }}
                    </p>

                    <UButton
                      v-if="user?.user && user?.user?.id !== gig.user.id"
                      :disabled="user?.user?.id === gig.user.id"
                      size="sm"
                      color="primary"
                      variant="outline"
                      class="w-[70px] justify-center"
                      :to="`/order/${gig.id}/`"
                    >
                      Earn
                    </UButton>
                    <UButton
                      v-if="user?.user?.id === gig.user.id"
                      :disabled="user?.user?.id === gig.user.id"
                      size="sm"
                      color="primary"
                      variant="outline"
                      class="w-[70px] justify-center"
                    >
                      Ineligible
                    </UButton>
                    <UButton
                      v-if="!user?.user"
                      size="sm"
                      color="primary"
                      variant="outline"
                      :to="`/auth/login/`"
                      class="w-[70px] justify-center"
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
const { formatDate } = useUtils();
const isOpen = ref(false);
const { get, baseURL } = useApi();
const { user } = useAuth();
const services = ref([]);
const searchServices = ref([]);
const microGigs = ref([]);
const categoryArray = ref([]);
const selectedCategory = ref(null);
const title = ref(null);
const isLoading = ref(false);
const { data } = await get("/micro-gigs/");
microGigs.value = data;
const res = await get("/classified-categories/");
services.value = res.data;
const classifiedLatestPosts = ref([]);
const res2 = await get("/classified-posts/");
classifiedLatestPosts.value = res2.data;

const classifiedPosts = ref([]);
const toast = useToast();

const microGigsFilter = [
  { title: "All", value: "" },
  { title: "Available", value: "approved" },
  { title: "Completed", value: "completed" },
];

const microGigsStatus = ref(microGigsFilter[1]);

const errorIndex = ref([]);
function handleImageError(index) {
  console.log(`Broken image detected at index: ${index}`);
  if (!errorIndex.value.includes(index)) {
    errorIndex.value.push(index); // Add index to errorIndex
  }
}

async function getMicroGigsCategories() {
  const categoryCounts = microGigs.value.reduce((acc, gig) => {
    const category = gig.category_details.title;
    const id = gig.category_details.id;
    const isActiveAndApproved =
      gig.active_gig && gig.gig_status === "approved" && gig.user?.id;

    if (!acc[category]) {
      acc[category] = { total: 0, active: 0, id: id };
    }

    acc[category].total++;
    if (isActiveAndApproved) {
      acc[category].active++;
    }

    return acc;
  }, {});

  categoryArray.value = Object.entries(categoryCounts).map(
    ([category, { total, active, id }]) => ({
      category,
      total,
      active,
      id,
    })
  );
}

setTimeout(() => {
  getMicroGigsCategories();
}, 20);

async function getMicroGigsByAvailability(e) {
  if (e === "completed") {
    const { data, error } = await get(`/micro-gigs/?show_submitted=true`);
    microGigs.value = data;
  } else if (e === "approved") {
    const { data, error } = await get(`/micro-gigs/?show_submitted=false`);
    microGigs.value = data;
  } else {
    const { data, error } = await get(`/micro-gigs/`);
    microGigs.value = data;
  }
}

const selectCategory = async (category) => {
  selectedCategory.value = category || null;
  try {
    const { data, error } = await get(
      `/micro-gigs/?category=${category.id}&show_submitted=${false}`
    );
    microGigs.value = data;
  } catch (error) {
    console.log(error);
    toast.add({ title: "error" });
  }
};

const loadMore = async (url) => {
  const getRecentNext = async (url) => {
    const res = await $fetch(`${url}`);
    services.value.next = res.next;
    services.value.results = [...services.value.results, ...res.results];
    // recents.value.next = data?.value?.next;
  };
  url = url.split("/api/");
  url = baseURL + "/" + url[1];
  // getRecentsNext(url);
  // url = url.replace("http://", "https://");
  getRecentNext(url);
};

async function handleSearch() {
  if (!title.value?.trim()) {
    toast.add({
      title: "Please enter a search term",
      color: "orange",
    });
    return;
  }

  isLoading.value = true;

  try {
    const [categoriesRes, postsRes] = await Promise.all([
      get(
        `/classified-categories/?title=${encodeURIComponent(
          title.value.trim()
        )}`
      ),
      get(`/classified-posts/?title=${encodeURIComponent(title.value.trim())}`),
    ]);

    services.value = categoriesRes.data;
    classifiedPosts.value = postsRes.data;
  } catch (error) {
    console.error("Search error:", error);
    toast.add({
      title: error?.message || "An error occurred while searching",
      color: "red",
    });
  } finally {
    isLoading.value = false;
  }
}

// watch(
//   () => (title.value ? title.value.trim() : ""),
//   async (newValue) => {
//     if (!newValue) {
//       isLoading.value = true;
//       try {
//         const res = await get("/classified-categories/");
//         services.value = res.data;
//         classifiedPosts.value = [];
//       } catch (error) {
//         console.error("Error fetching categories:", error);
//         toast.add({
//           title: "Failed to refresh categories",
//           color: "red",
//         });
//       } finally {
//         isLoading.value = false;
//       }
//     }
//   },
//   {
//     debounce: 300,
//     immediate: false,
//   }
// );
// Replace the existing watch function with this:
watch(
  () => title.value,
  async (newValue) => {
    // Don't trigger search if value is empty
    if (!newValue?.trim()) {
      isLoading.value = true;
      try {
        const res = await get("/classified-categories/");
        services.value = res.data;
        searchServices.value = [];
        classifiedPosts.value = [];
      } catch (error) {
        console.error("Error fetching categories:", error);
        toast.add({
          title: "Failed to refresh categories",
          color: "red",
        });
      } finally {
        isLoading.value = false;
      }
      return;
    }

    // Perform search
    isLoading.value = true;
    try {
      const [categoriesRes, postsRes] = await Promise.all([
        get(
          `/classified-categories/?title=${encodeURIComponent(newValue.trim())}`
        ),
        get(`/classified-posts/?title=${encodeURIComponent(newValue.trim())}`),
      ]);

      services.value = categoriesRes.data;
      searchServices.value = categoriesRes.data;
      classifiedPosts.value = postsRes.data;
    } catch (error) {
      console.error("Search error:", error);
      toast.add({
        title: error?.message || "An error occurred while searching",
        color: "red",
      });
    } finally {
      isLoading.value = false;
    }
  },
  {
    // Add debounce to prevent too many API calls while typing
    debounce: 500,
    // Don't run on component mount
    immediate: false,
  }
);

// You can now remove the handleSearch function and update the template:

const operators = ref([]);
const operatorsRes = await get("/mobile-recharge/operators/");

operators.value = operatorsRes.data;

// Existing code remains unchanged

// Add these variables for the typing animation
const searchInput = ref(null);
const showPlaceholder = ref(true);
const displayedPlaceholder = ref("");
const cursorVisible = ref(true);
const typingInterval = ref(null);
const cursorInterval = ref(null);
const currentIndex = ref(0);
const placeholder = "খুঁজে নিন যা প্রয়োজন....";

// Typing animation functions
const typeNextChar = () => {
  if (currentIndex.value < placeholder.length) {
    displayedPlaceholder.value += placeholder[currentIndex.value];
    currentIndex.value++;

    // Variable typing speed for human-like effect
    const nextSpeed = Math.floor(Math.random() * 130) + 70;

    // Add slight pauses at certain points
    if (placeholder[currentIndex.value - 1] === " ") {
      typingInterval.value = setTimeout(typeNextChar, 300); // Longer pause after space
    } else {
      typingInterval.value = setTimeout(typeNextChar, nextSpeed);
    }
  } else {
    // When typing completes, wait and then start over
    setTimeout(resetTyping, 2000);
  }
};

// Reset typing animation
const resetTyping = () => {
  displayedPlaceholder.value = "";
  currentIndex.value = 0;
  typingInterval.value = setTimeout(typeNextChar, 500);
};

// Stop typing animation when input receives focus
const stopTyping = () => {
  showPlaceholder.value = false;
  clearTimeout(typingInterval.value);
};

// Restart typing animation if field is empty when blurred
const restartTypingIfEmpty = () => {
  if (!title.value) {
    showPlaceholder.value = true;
    resetTyping();
  }
};

// Start cursor blinking
const startCursorBlink = () => {
  cursorInterval.value = setInterval(() => {
    cursorVisible.value = !cursorVisible.value;
  }, 530); // Blink interval
};

// Initialize animations on mount
onMounted(() => {
  // Start after a brief delay to ensure reactivity is set up
  setTimeout(() => {
    typeNextChar();
    startCursorBlink();
  }, 100);
});

// Clean up intervals when component is unmounted
onBeforeUnmount(() => {
  clearTimeout(typingInterval.value);
  clearInterval(cursorInterval.value);
});
</script>

<style>
/* Add this to your existing styles */
@keyframes blink {
  0%,
  100% {
    opacity: 1;
  }
  50% {
    opacity: 0;
  }
}

.animate-blink {
  animation: blink 1s infinite;
}

.fade-enter-active,
.fade-leave-active {
  transition: all 0.3s ease;
}

.fade-enter-from,
.fade-leave-to {
  opacity: 0;
  transform: translateY(10px);
}
</style>
