<template>
  <PublicSection>
    <UContainer class="mb-16">
      <div class="mx-auto" v-if="service">
        <div
          class="flex sm:items-center sm:justify-between flex-col-reverse sm:flex-row"
        >
          <p class="mb-3 mt-4 sm:mt-16 text-sm md:text-base italic">
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
            > <u>{{ service.title }}</u>
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
        <div class="w-full flex flex-col justify-center" v-if="service.id">
          <h2
            class="text-xl sm:text-3xl font-semibold first-letter:uppercase text-green-900"
          >
            {{ service.title }}
          </h2>
          <p class="text-sm sm:text-base first-letter:capitalize">
            {{ service?.location }}
          </p>
          <h4
            v-if="!service.negotiable"
            class="text-base sm:text-xl font-semibold inline-flex items-center"
          >
            <UIcon name="i-mdi:currency-bdt" class="text-xl" />{{
              service.price
            }}
          </h4>
          <h4 v-else class="text-base sm:text-xl font-semibold">Negotiable</h4>

          <div
            v-if="service?.medias"
            class="text-center my-10 flex gap-4 flex-wrap justify-center"
          >
            <NuxtImg
              v-for="({ image }, index) in service?.medias"
              :key="index"
              :src="image"
              class="max-w-32 w-full rounded-md hidden"
            />
            <UCarousel
              v-slot="{ item }"
              :items="service?.medias"
              :ui="{ item: 'basis-full' }"
              class="rounded-lg overflow-hidden"
              indicators
            >
              <NuxtImg
                :src="item.image"
                class="w-full rounded-md max-w-40 sm:max-w-52 mx-auto"
              />
            </UCarousel>
          </div>
          <NuxtImg
            v-if="!service?.medias.length && service?.category_details.image"
            :src="service?.category_details.image"
            class="max-w-32 w-full rounded-md self-center my-10 hidden sm:block"
          />

          <div
            class="text-sm md:text-base first-letter:uppercase my-8"
            v-html="service.instructions"
          ></div>
          <UDivider class="my-1 px-6" />
          <div class="my-3 flex flex-col sm:flex-row gap-3 md:gap-8 mt-8">
            <div class="pt-3">
              <NuxtImg
                v-if="service.user?.image"
                :src="service.user?.image"
                class="h-16 w-16 mx-auto md:ml-0 md:h-24 md:w-24 rounded-full"
              />
              <img
                v-else
                src="/static/frontend/avatar.png"
                class="h-16 w-16 mx-auto md:ml-0 md:h-24 md:w-24 rounded-full"
                alt="Avatar"
              />
            </div>

            <div class="flex-1 max-w-md w-full">
              <div class="flex flex-col gap-1 w-full mb-3">
                <div
                  class="flex items-center justify-center sm:justify-normal gap-1"
                >
                  <h3
                    class="text-lg md:text-xl"
                    v-if="service.user?.first_name"
                  >
                    {{ service.user?.first_name }} {{ service.user?.last_name }}
                  </h3>
                  <h3 class="text-xl md:text-2xl" v-else>No Name Provided</h3>

                  <UIcon
                    v-if="service.user?.kyc"
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
              <div class="px-2">
                <div class="w-full" v-html="service.user?.about"></div>

                <div class="flex flex-col gap-3 my-3">
                  <div
                    class="flex gap-2 items-center"
                    v-if="service.user?.face_link"
                  >
                    <UIcon name="logos:facebook" class="w-5 h-5" />
                    <a :href="service.user?.face_link">{{
                      service.user?.face_link
                    }}</a>
                  </div>
                  <div
                    class="flex gap-2 items-center"
                    v-if="service.user?.instagram_link"
                  >
                    <UIcon name="skill-icons:instagram" class="w-5 h-5" />
                    <a :href="service.user?.instagram_link">{{
                      service.user?.instagram_link
                    }}</a>
                  </div>
                  <div
                    class="flex gap-2 items-center"
                    v-if="service.user?.whatsapp_link"
                  >
                    <UIcon name="logos:whatsapp-icon" class="w-5 h-5" />
                    <a :href="service.user?.whatsapp_link">{{
                      service.user?.whatsapp_link
                    }}</a>
                  </div>
                  <div
                    class="flex gap-2 items-center"
                    v-if="service.user?.email"
                  >
                    <UIcon name="skill-icons:gmail-light" class="w-5 h-5" />
                    <a :href="'mailto:' + service.user?.email">{{
                      service.user?.email
                    }}</a>
                  </div>
                  <div
                    class="flex gap-2 items-center"
                    v-if="service.user?.phone"
                  >
                    <UIcon name="material-symbols:call" class="w-5 h-5" />
                    <a :href="'tel:' + service.user?.phone">{{
                      service.user?.phone
                    }}</a>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
      <p class="text-center font-medium text-sm sm:text-base">
        Share with social medias
      </p>
      <div class="share-buttons-container">
        <div class="share-list">
          <!-- FACEBOOK -->
          <a class="fb-h" @click.prevent="fbs_click" target="_blank">
            <img
              src="https://img.icons8.com/material-rounded/96/000000/facebook-f.png"
            />
          </a>

          <!-- TWITTER -->
          <a class="tw-h" @click.prevent="tbs_click" target="_blank">
            <img
              src="https://img.icons8.com/material-rounded/96/000000/twitter-squared.png"
            />
          </a>

          <!-- LINKEDIN -->
          <a class="li-h" @click.prevent="lbs_click" target="_blank">
            <img
              src="https://img.icons8.com/material-rounded/96/000000/linkedin.png"
            />
          </a>

          <!-- REDDIT -->
          <a class="re-h" @click.prevent="rbs_click" target="_blank">
            <img src="https://img.icons8.com/ios-glyphs/90/000000/reddit.png" />
          </a>

          <!-- PINTEREST -->
          <a
            data-pin-do="buttonPin"
            data-pin-config="none"
            class="pi-h"
            @click.prevent="pbs_click"
            target="_blank"
          >
            <img
              src="https://img.icons8.com/ios-glyphs/90/000000/pinterest.png"
            />
          </a>
        </div>
      </div>
    </UContainer>
  </PublicSection>
</template>

<script setup>
const { baseURL } = useApi();
const service = ref({});
const router = useRoute();

async function fetchServices() {
  const response = await $fetch(
    `${baseURL}/classified-categories/post/${router.params.id}/`
  );

  service.value = response;
  useHead({
    title: `AdsyClub | ${
      response?.title
        ? response.title.charAt(0).toUpperCase() + response.title.slice(1)
        : ""
    }`,
  });
}
setTimeout(() => {
  fetchServices();
}, 20);

var pageLink = window.location.href;
var pageTitle = String(document.title).replace(/\&/g, "%26");

function fbs_click() {
  window.open(
    `http://www.facebook.com/sharer.php?u=${pageLink}&quote=${pageTitle}`,
    "sharer",
    "toolbar=0,status=0,width=626,height=436"
  );
  return false;
}

function tbs_click() {
  window.open(
    `https://twitter.com/intent/tweet?text=${pageTitle}&url=${pageLink}`,
    "sharer",
    "toolbar=0,status=0,width=626,height=436"
  );
  return false;
}

function lbs_click() {
  window.open(
    `https://www.linkedin.com/sharing/share-offsite/?url=${pageLink}`,
    "sharer",
    "toolbar=0,status=0,width=626,height=436"
  );
  return false;
}

function rbs_click() {
  window.open(
    `https://www.reddit.com/submit?url=${pageLink}`,
    "sharer",
    "toolbar=0,status=0,width=626,height=436"
  );
  return false;
}

function pbs_click() {
  window.open(
    `https://www.pinterest.com/pin/create/button/?&text=${pageTitle}&url=${pageLink}&description=${pageTitle}`,
    "sharer",
    "toolbar=0,status=0,width=626,height=436"
  );
  return false;
}
</script>

<style scoped>
.share-list {
  display: flex;
  flex-direction: row;
}

.share-list a {
  border-radius: 100px;
  width: 32px;
  height: 32px;
  padding: 7px;
  margin: 10px;
  cursor: pointer;
  overflow: hidden;
}
.share-list a img {
  width: 100%;
  height: 100%;
  filter: invert(100%);
}

a.fb-h {
  background: #3b5998;
}

a.tw-h {
  background: #00acee;
}

a.li-h {
  background: #0077b5;
}

a.re-h {
  background: #ff5700;
}

a.pi-h {
  background: #c8232c;
}

.share-buttons-container {
  display: flex;
  justify-content: center;
  align-items: center;
  width: 100%;
}
</style>
