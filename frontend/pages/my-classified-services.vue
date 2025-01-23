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
          to="/classified-categories/post/"
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
            <div class="flex flex-col px-3 py-2.5 sm:flex-row sm:items-center w-full">
              <div class="flex flex-col sm:flex-row items-center justify-between w-full relative">
                <div class="flex flex-row gap-4 items-start text-sm sm:text-base">
                  <div>
                    <NuxtImg
                      v-if="service.medias[0]?.image"
                      :src="service.medias[0].image"
                      class="size-9 sm:size-14 rounded-md object-cover"
                    />
                    <img v-else :src="service.category_details.image" class="size-14 rounded-md" />
                  </div>
                  <div class="flex-1">
                    <h3
                      class="text-sm sm:text-base font-semibold mb-1.5 text-left line-clamp-2 capitalize"
                    >
                      <UIcon
                        name="i-icon-park-outline:dot"
                        class="text-green-500 text-lg"
                        v-if="service.service_status === 'approved' && service.active_service"
                      />
                      <span v-if="service.service_status === 'approved' && service.active_service"
                        >Live</span
                      >
                      <span
                        class="text-green-700"
                        v-if="service.service_status === 'completed' && service.active_service"
                        >Completed</span
                      >

                      <span
                        class="text-yellow-600"
                        v-if="
                          service.service_status.toLowerCase() === 'pending' ||
                          !service.active_service
                        "
                        >{{
                          service.service_status.toLowerCase() === "pending" ? "Pending" : "Paused"
                        }}</span
                      >
                      <span
                        class="text-red-600"
                        v-if="
                          service.service_status.toLowerCase() === 'rejected' &&
                          service.active_service
                        "
                        >Rejected</span
                      >

                      |
                      {{ service?.title }}
                    </h3>

                    <div class="flex flex-wrap items-center sm:items-start gap-4 gap-y-1">
                      <p class="inline-flex sm:hidden items-center" v-if="!service.negotiable">
                        <UIcon name="i-mdi:currency-bdt" />
                        {{ service.price }}
                      </p>
                      <p v-else class="sm:hidden">Negotiable</p>

                      <p class="inline-flex gap-1 items-center">
                        <UIcon name="i-tabler:category-filled" />
                        <span class="text-sm">{{ service?.category_details.title }}</span>
                      </p>

                      <p class="inline-flex gap-1 items-center">
                        <UIcon name="i-heroicons-clock-solid" />
                        <span class="text-sm">Posted: {{ formatDate(service?.created_at) }}</span>
                      </p>
                      <p class="inline-flex gap-1 items-center">
                        <UIcon name="i-heroicons-map-pin-solid" />
                        <span class="text-sm">{{ service?.location }}</span>
                      </p>
                    </div>
                  </div>
                </div>
                <div
                  class="flex gap-16 items-center justify-between md:pr-2 font-semibold text-sm sm:text-base"
                  v-if="
                    service.service_status.toLowerCase() !== 'rejected' ||
                    service.service_status.toLowerCase() !== 'completed'
                  "
                >
                  <p class="sm:inline-flex items-center my-3 hidden" v-if="!service.negotiable">
                    <UIcon name="i-mdi:currency-bdt" />
                    {{ service.price }}
                  </p>
                  <p v-else class="hidden sm:block">Negotiable</p>
                  <div class="flex gap-1 items-center max-md:justify-center max-sm:mt-4">
                    <UButton
                      size="md"
                      color="primary"
                      variant="outline"
                      label="Pause"
                      :loading="isLoading"
                      v-if="service.active_service"
                      @click.prevent="handleAction(service.id, 'pause', false)"
                    />
                    <UButton
                      size="md"
                      color="primary"
                      variant="outline"
                      label="Activate"
                      :loading="isLoading"
                      v-if="!service.active_service"
                      @click.prevent="handleAction(service.id, 'active', true)"
                    />
                    <UButton
                      size="md"
                      color="primary"
                      variant="outline"
                      label="Edit"
                      :to="`/classified-categories/post/?id=${service.id}`"
                    />
                    <UButton
                      size="md"
                      color="primary"
                      variant="outline"
                      label="Stop"
                      :loading="isLoading"
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
          <h4 class="text-2xl font-medium mb-4">It will stop the post forever</h4>

          <UButton
            size="md"
            color="primary"
            variant="solid"
            label="Confirm Complete"
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
const isLoading = ref(false);
const { get, put } = useApi();
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
  isLoading.value = true;
  const res = await (action === "complete"
    ? put("/update-user-classified-post/" + id + "/", {
        service_status: "completed",
      })
    : put("/update-user-classified-post/" + id + "/", {
        active_service: val,
      }));
  isOpen.value = false;
  if (res.data) {
    fetchServices();
  }
  isLoading.value = false;
}
</script>

<style scoped>
/* .service-card:nth-child(odd) {
  background-color: rgb(235, 232, 232);
} */
</style>
