<template>
  <div class="py-10">
    <PublicSection id="classified-services">
      <UContainer>
        <h2 class="text-2xl md:text-4xl mb-12">Classified Services</h2>
        <div class="grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-6 gap-3">
          <UCard
            class="text-center"
            v-for="service in services"
            :key="service.id"
            :ui="{
              body: {
                padding: 'px-3 py-3 sm:p-5',
              },
            }"
          >
            <ULink
              :to="`/classified-categories/${service.id}`"
              active-class="text-primary"
              inactive-class="text-gray-500 dark:text-gray-400"
            >
              <NuxtImg
                :src="service.image"
                :title="service.title"
                class="size-10 mx-auto"
              />
              <h3 class="text-xl mt-4">{{ service.title }}</h3>
            </ULink>
          </UCard>
        </div>
      </UContainer>
    </PublicSection>
    <PublicSection id="micro-gigs">
      <UContainer>
        <h2 class="text-2xl md:text-4xl mb-12 text-center">
          Micro Gigs (Quick Earn)
        </h2>
        <AccountBalance v-if="user" :user="user" :isUser="true" />
        <UCard
          :ui="{
            body: 'p-0',
            rounded: 'rounded-md overflow-hidden',
          }"
        >
          <div class="flex">
            <div class="w-60 bg-slate-50/70">
              <ul class="py-2">
                <li>
                  <p
                    class="px-2 font-semibold pb-2"
                    @click.prevent="selectedCategory = null"
                  >
                    All Categories
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
                    class="w-full text-base px-4 py-0 font-normal"
                    @click.prevent="selectCategory(category.category)"
                    >{{ category.category }} ({{ category.count }})
                  </UButton>
                </li>
              </ul>
            </div>
            <div class="space-y-[0.5px] flex-1">
              <UCard
                v-for="(gig, i) in filteredMicroGigs"
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
                }"
                class="flex flex-col px-3 py-2.5 sm:flex-row sm:items-center w-full bg-slate-50/70"
              >
                <div class="flex justify-between">
                  <div class="flex gap-4">
                    <div>
                      <NuxtImg
                        :src="gig.medias[0].image"
                        class="size-14 rounded-full"
                      />
                    </div>
                    <div>
                      <h3 class="text-base font-semibold mb-1.5">
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
                  <div class="flex gap-16 items-center">
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
const isOpen = ref(false);
const { get, staticURL } = useApi();
const { user } = useAuth();
const services = ref([]);
const microGigs = ref([]);
const categoryArray = ref([]);
const selectedCategory = ref(null);
const categoryCounts = microGigs.value.reduce((acc, gig) => {
  const category = gig.category;
  if (!acc[category]) {
    acc[category] = 1;
  } else {
    acc[category]++;
  }
  return acc;
}, {});
// Convert the result into an array of objects
categoryArray.value = Object.entries(categoryCounts).map(
  ([category, count]) => ({ category, count })
);
async function getClassifiedCategories() {
  const [serviceResponse, gigResponse] = await Promise.all([
    get("/classified-categories/"),
    get("/micro-gigs/"),
  ]);
  services.value = serviceResponse.data;
  microGigs.value = gigResponse.data;
  const categoryCounts = microGigs.value.reduce((acc, gig) => {
    const category = gig.category_details.title;
    if (!acc[category]) {
      acc[category] = 1;
    } else {
      acc[category]++;
    }
    return acc;
  }, {});
  categoryArray.value = Object.entries(categoryCounts).map(
    ([category, count]) => ({ category, count })
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
</script>
