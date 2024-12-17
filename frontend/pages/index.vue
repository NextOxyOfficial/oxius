<template>
  <div class="py-10">
    <PublicSection id="classified-services">
      <UContainer
        :ui="{
          padding: 'px-2',
        }"
      >
        <div class="flex items-center justify-between gap-6 mb-12">
          <h2 class="text-2xl md:text-4xl">Classified Services</h2>
        </div>
        <div
          class="grid grid-cols-2 sm:grid-cols-3 lg:flex justify-center gap-3"
        >
          <UCard
            class="text-center border border-dashed border-green-500 lg:w-[190px]"
            v-for="service in services"
            :key="service.id"
            :ui="{
              body: {
                padding: 'px-3 py-1 sm:p-2.5',
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
                :src="service.image"
                :title="service.title"
                class="size-10 mx-auto"
              />
              <h3 class="text-md mt-2">{{ service.title }}</h3>
            </ULink>
          </UCard>
        </div>
        <div class="text-center mt-8">
          <UButton
            size="md"
            color="primary"
            variant="outline"
            label="Load More"
          />
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
            body: { padding: 'p-0' },
            header: { padding: 'p-0' },
            rounded: 'rounded-md overflow-hidden',
          }"
        >
          <div class="flex flex-col md:flex-row w-full">
            <div class="w-full md:w-60 bg-slate-50/70">
              <ul class="py-2 text-center">
                <li>
                  <p
                    class="px-2 font-semibold pb-2 text-center"
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
                    class="w-full text-base px-4 py-0 font-normal text-blue-950"
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
                <div class="flex flex-col sm:flex-row sm:justify-between">
                  <div class="flex gap-4">
                    <div>
                      <NuxtImg
                        :src="gig.medias[0].image"
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
