<template>
  <PublicSection>
    <UContainer>
      <h2 class="text-center text-2xl md:text-4xl my-6">My Classified Posts</h2>
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
              <div
                class="flex flex-col sm:flex-row items-start sm:items-center justify-between w-full relative"
              >
                <div
                  class="flex flex-col sm:flex-row gap-2 lg:gap-4 items-center sm:items-start"
                >
                  <div>
                    <NuxtImg
                      :src="staticURL + service.medias[0].image"
                      class="max-md:size-20 md:size-14 rounded-md"
                    />
                  </div>
                  <div>
                    <h3
                      class="text-base font-semibold mb-1.5 text-left line-clamp-2 capitalize"
                    >
                      <UIcon
                        name="i-icon-park-outline:dot"
                        class="text-green-500 text-lg"
                        v-if="
                          service.service_status === 'approved' &&
                          service.active_service
                        "
                      />
                      <span
                        v-if="
                          service.service_status === 'approved' &&
                          service.active_service
                        "
                        >Live</span
                      >

                      <span
                        class="text-yellow-600"
                        v-if="
                          service.service_status.toLowerCase() === 'pending' ||
                          !service.active_service
                        "
                        >Pending</span
                      >
                      <span
                        class="text-red-600"
                        v-if="
                          service.service_status.toLowerCase() === 'rejected' &&
                          !service.active_service
                        "
                        >Rejected</span
                      >

                      |
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
                          >Posted: {{ formatDate(service?.created_at) }}</span
                        >
                      </p>
                    </div>
                  </div>
                </div>
                <div
                  class="flex flex-col sm:flex-row gap-2 sm:gap-5 md:gap-16 items-start sm:items-center justify-normal sm:justify-between md:pr-2 font-semibold text-sm sm:text-base"
                >
                  <p
                    class="inline-flex items-center my-3 justify-start"
                    v-if="!service.negotiable"
                  >
                    <UIcon name="i-mdi:currency-bdt" />
                    {{ service.price }}
                  </p>
                  <p v-else>Negotiable</p>
                  <div
                    class="flex gap-1 items-center max-md:justify-center max-sm:mt-4"
                  >
                    <UButton
                      size="md"
                      color="primary"
                      variant="outline"
                      label="Pause"
                      v-if="service.active_service"
                      @click.prevent="handleAction(service.id, 'pause', false)"
                    />
                    <UButton
                      size="md"
                      color="primary"
                      variant="outline"
                      label="Activate"
                      v-if="!service.active_service"
                      @click.prevent="handleAction(service.id, 'active', true)"
                    />
                    <UButton
                      size="md"
                      color="primary"
                      variant="outline"
                      label="Edit"
                      :to="`/classified-categories/new/?id=${service.id}`"
                    />
                    <UButton
                      size="md"
                      color="primary"
                      variant="outline"
                      label="Complete"
                      @click.prevent="handlePop(service.id)"
                    />
                    <!-- <UButton
                      size="md"
                      color="primary"
                      variant="outline"
                      label="Details"
                      :to="`/my-gigs/details/${service.id}/`"
                    /> -->
                  </div>
                </div>
              </div>
            </div>
          </NuxtLink>
        </UCard>
      </div>
      <UCard v-else class="py-16 text-center mt-6">
        <p>You haven't made any post yet!</p>
      </UCard>
      <UModal v-model="isOpen">
        <div class="py-10 px-6 text-center">
          <h4 class="text-2xl font-medium mb-4">
            It will delete the gig forever?
          </h4>

          <UButton
            size="md"
            color="primary"
            variant="solid"
            label="Confirm Delete"
            @click="handleAction(currentId, 'complete')"
          />
        </div>
      </UModal>
    </UContainer>
  </PublicSection>
</template>

<script setup>
definePageMeta({
  layout: "dashboard",
});
const { get, put, staticURL } = useApi();
const { formatDate } = useUtils();
const isOpen = ref(false);
const categoryTitle = ref("");
const services = ref([]);

const currentId = ref();
function handlePop(id) {
  isOpen.value = true;
  currentId.value = id;
}

async function fetchServices() {
  const response = await get(`/user-classified-categories-post/`);
  services.value = response.data;
  categoryTitle.value = response.data[0]?.category_details.title;
}
fetchServices();

async function handleAction(id, action, val) {
  const res = await (action === "complete"
    ? put("/update-user-classified-post/" + id + "/")
    : put("/update-user-classified-post/" + id + "/", {
        active_service: val,
      }));
  isOpen.value = false;
  if (res.data) {
    fetchServices();
  }
}
</script>

<style scoped>
/* .service-card:nth-child(odd) {
  background-color: rgb(235, 232, 232);
} */
</style>
