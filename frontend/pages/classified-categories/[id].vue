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
          <div
            class="flex flex-col px-3 py-2.5 sm:flex-row sm:items-center w-full"
          >
            <div class="flex justify-between">
              <div class="flex gap-4">
                <div>
                  <NuxtImg
                    src="https://placehold.co/400"
                    class="size-14 rounded-md"
                  />
                </div>
                <div>
                  <h3 class="text-base font-bold mb-1.5">
                    Lorem ipsum dolor sit amet.
                  </h3>

                  <div class="flex gap-4">
                    <p class="inline-flex gap-1 items-center">
                      <UIcon name="i-heroicons-map-pin-solid" />
                      <span class="text-sm">Chewriya, Kushtia</span>
                    </p>
                    <p class="inline-flex gap-1 items-center">
                      <UIcon name="i-tabler:category-filled" />
                      <span class="text-sm">Category</span>
                    </p>
                    <p class="inline-flex gap-1 items-center">
                      <UIcon name="i-heroicons-clock-solid" />
                      <span class="text-sm">Posted: 1 Day Ago</span>
                    </p>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </UCard>
      </div>
    </UContainer>
  </PublicSection>
</template>

<script setup>
const services = [{}, {}, {}];
</script>

<style scoped>
/* .service-card:nth-child(odd) {
  background-color: rgb(235, 232, 232);
} */
</style>
