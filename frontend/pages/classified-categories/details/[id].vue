<template>
  <UContainer class="mb-16">
    <div class="mx-auto" v-if="service">
      <div class="flex items-center justify-between">
        <p class="mb-3 mt-16">
          <ULink
            to="/"
            active-class="text-primary"
            inactive-class="text-gray-500 dark:text-gray-400"
            >Home</ULink
          >
          >
          <ULink
            :to="`/classified-categories/${service.category_details?.id}`"
            active-class="text-primary"
            inactive-class="text-gray-500 dark:text-gray-400"
            >{{ service.category_details?.title }}</ULink
          >
          > {{ service.title }}
        </p>

        <UButton
          :to="`/classified-categories/${service.category_details?.id}`"
          label="Go Back"
          color="gray"
          class="self-end"
        >
          <template #trailing>
            <UIcon name="i-heroicons-arrow-left-20-solid" class="w-5 h-5" />
          </template>
        </UButton>
      </div>

      <div class="w-full flex flex-col justify-center">
        <h2 class="text-3xl font-bold">{{ service.title }}</h2>
        <NuxtImg
          :src="'http://127.0.0.1:8000' + service.image"
          class="max-w-[60%] w-full rounded-md self-center my-10"
        />

        <p class="">
          {{ service.instructions }}
        </p>
        <div class="my-3 flex items-center gap-4 mt-8">
          <div>
            <NuxtImg src="/avatar.png" class="h-56 w-56 rounded-full" />
          </div>
          <div class="flex-1 max-w-md w-full">
            <div class="flex flex-col gap-1 w-full my-3">
              <div class="flex items-center">
                <h3 class="text-2xl" v-if="service.user?.first_name">
                  {{ service.user?.first_name }} {{ service.user?.last_name }}
                </h3>
                <h3 class="text-2xl" v-else>No Name Provided</h3>
                <UIcon
                  name="mdi:check-decagram"
                  class="w-5 h-5 text-blue-600 mt-1"
                />
              </div>
              <!-- <div class="flex items-center gap-1">
                <UBadge class="" color="gray" variant="solid"
                  >Badge hfghfhgfh</UBadge
                >
                <UBadge class="" color="gray" variant="solid"
                  >Badge hfghfhgfh</UBadge
                >
              </div> -->
            </div>
            <p class="w-full">
              {{ service.user?.about }}
            </p>

            <div class="flex flex-col gap-3 my-3">
              <div
                class="flex gap-2 items-center"
                v-if="service.user.face_link"
              >
                <UIcon name="logos:facebook" class="w-5 h-5" />
                <a :href="service.user.face_link">{{
                  service.user.face_link
                }}</a>
              </div>
              <div
                class="flex gap-2 items-center"
                v-if="service.user.instagram_link"
              >
                <UIcon name="skill-icons:instagram" class="w-5 h-5" />
                <a :href="service.user.instagram_link">{{
                  service.user.instagram_link
                }}</a>
              </div>
              <div
                class="flex gap-2 items-center"
                v-if="service.user.whatsapp_link"
              >
                <UIcon name="skill-icons:gmail-light" class="w-5 h-5" />
                <a :href="service.user.whatsapp_link">{{
                  service.user.whatsapp_link
                }}</a>
              </div>
              <div
                class="flex gap-2 items-center"
                v-if="service.user.gmail_link"
              >
                <UIcon name="logos:whatsapp-icon" class="w-5 h-5" />
                <a :href="service.user.gmail_link">{{
                  service.user.gmail_link
                }}</a>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  </UContainer>
</template>

<script setup>
const { get } = useApi();
const service = ref({});
const router = useRoute();

async function fetchServices() {
  const response = await get(
    `/classified-categories/post/${router.params.id}/`
  );
  console.log(response);

  service.value = response.data;
}
fetchServices();
</script>
