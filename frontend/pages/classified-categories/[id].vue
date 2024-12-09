<template>
  <PublicSection>
    <UContainer>
      <h2 class="text-center text-4xl my-6">Category Name</h2>
      <div class="flex justify-between items-end">
        <div>
          <p class="mb-3">
            <ULink
              to="/"
              active-class="text-primary"
              inactive-class="text-gray-500 dark:text-gray-400"
              >Home</ULink
            >
            > Category Name
          </p>
          <USelect
            icon="i-heroicons-bell-solid"
            color="white"
            size="md"
            :options="['United States', 'Canada']"
            placeholder="Category"
          />
        </div>
        <UButtonGroup size="md" class="w-96">
          <UInput
            icon="i-heroicons-magnifying-glass-20-solid"
            size="sm"
            color="white"
            :trailing="false"
            placeholder="Search..."
            class="w-full"
          />
          <UButton
            icon="i-heroicons-bell-solid"
            size="md"
            color="primary"
            variant="solid"
            label="Search"
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
      <div class="services mt-4">
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
              <div class="flex justify-between">
                <div class="flex gap-4">
                  <div>
                    <NuxtImg
                      :src="'http://127.0.0.1:8000' + service.image"
                      class="size-14 rounded-md"
                    />
                  </div>
                  <div>
                    <h3 class="text-base font-bold mb-1.5">
                      {{ service.title }}
                    </h3>

                    <div class="flex gap-4">
                      <p class="inline-flex gap-1 items-center">
                        <UIcon name="i-heroicons-map-pin-solid" />
                        <span class="text-sm">{{ service.location }}</span>
                      </p>
                      <p class="inline-flex gap-1 items-center">
                        <UIcon name="i-tabler:category-filled" />
                        <span class="text-sm">{{
                          service.category.title
                        }}</span>
                      </p>
                      <p class="inline-flex gap-1 items-center">
                        <UIcon name="i-heroicons-clock-solid" />
                        <span class="text-sm"
                          >Posted: {{ service.created_at }}</span
                        >
                      </p>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </NuxtLink>
        </UCard>
      </div>
    </UContainer>
  </PublicSection>
</template>

<script setup>
const { get } = useApi();
const services = ref([]);
const router = useRoute();

console.log(router.params.id);

async function fetchServices() {
  const response = await get(`/classified-categories/${router.params.id}/`);
  console.log(response);

  services.value = response.data;
}
fetchServices();
</script>

<style scoped>
/* .service-card:nth-child(odd) {
  background-color: rgb(235, 232, 232);
} */
</style>
