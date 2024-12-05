<template>
  <div class="py-10">
    <PublicSection>
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
            <NuxtImg
              :src="service.image"
              :title="service.title"
              class="size-10 mx-auto"
            />
            <h3 class="text-xl mt-4">{{ service.title }}</h3>
          </UCard>
        </div>
      </UContainer>
    </PublicSection>
    <PublicSection>
      <UContainer>
        <h2 class="text-2xl md:text-4xl mb-12">Micro Gigs (Quick Earn)</h2>
        <div class="space-y-[0.5px]">
          <UCard
            :ui="{
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
            class="flex flex-col p-5 sm:flex-row sm:items-center w-full"
          >
            <div class="flex justify-between">
              <div class="flex gap-4">
                <div>
                  <NuxtImg
                    src="https://placehold.co/400"
                    class="size-14 rounded-full"
                  />
                </div>
                <div>
                  <h3 class="text-base font-bold mb-1.5">
                    Lorem ipsum dolor sit amet.
                  </h3>
                  <div class="flex gap-6">
                    <div class="flex gap-1 items-center">
                      <UIcon name="i-heroicons-user-solid" />
                      <p>User</p>
                    </div>
                    <div class="flex gap-1 items-center">
                      <UIcon name="i-tabler:coin-taka-filled" class="text-lg" />
                      <p class="">500</p>
                    </div>
                    <div class="flex gap-1 items-center">
                      <UIcon name="i-heroicons-bell-solid" />
                      <p class="">
                        <span class="">5</span> /
                        <span class="text-green-600">10</span>
                      </p>
                    </div>
                  </div>
                </div>
              </div>
              <div>
                <UButton
                  icon="i-heroicons-bell-solid"
                  size="md"
                  color="primary"
                  variant="solid"
                  label="Apply"
                />
              </div>
            </div>
          </UCard>
          <UCard
            :ui="{
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
            class="flex flex-col p-5 sm:flex-row sm:items-center w-full"
          >
            <div class="flex justify-between">
              <div class="flex gap-4">
                <div>
                  <NuxtImg
                    src="https://placehold.co/400"
                    class="size-14 rounded-full"
                  />
                </div>
                <div>
                  <h3 class="text-base font-bold mb-1.5">
                    Lorem ipsum dolor sit amet.
                  </h3>
                  <div class="flex gap-6">
                    <div class="flex gap-1 items-center">
                      <UIcon name="i-heroicons-user-solid" />
                      <p>User</p>
                    </div>
                    <div class="flex gap-1 items-center">
                      <UIcon name="i-tabler:coin-taka-filled" class="text-lg" />
                      <p class="">500</p>
                    </div>
                    <div class="flex gap-1 items-center">
                      <UIcon name="i-heroicons-bell-solid" />
                      <p class="">
                        <span class="">5</span> /
                        <span class="text-green-600">10</span>
                      </p>
                    </div>
                    <div class="flex gap-1 items-center">
                      <UIcon name="i-heroicons-clock-solid" />
                      <p class="">Posted: 1 Day Ago</p>
                    </div>
                  </div>
                </div>
              </div>
              <div>
                <UButton
                  icon="i-heroicons-bell-solid"
                  size="md"
                  color="primary"
                  variant="solid"
                  label="Apply"
                />
              </div>
            </div>
          </UCard>
        </div>
      </UContainer>
    </PublicSection>
  </div>
</template>

<script setup>
const services = [
  {
    id: 1,
    title: "Service 1",
    image: "https://placehold.co/400",
  },
  {
    id: 2,
    title: "Service 1",
    image: "https://placehold.co/400",
  },
  {
    id: 2,
    title: "Service 1",
    image: "https://placehold.co/400",
  },
  {
    id: 2,
    title: "Service 1",
    image: "https://placehold.co/400",
  },
  {
    id: 2,
    title: "Service 1",
    image: "https://placehold.co/400",
  },
  {
    id: 2,
    title: "Service 1",
    image: "https://placehold.co/400",
  },
  {
    id: 2,
    title: "Service 1",
    image: "https://placehold.co/400",
  },
];
</script>
