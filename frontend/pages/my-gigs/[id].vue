<template>
  <PublicSection>
    <h1 class="text-center text-4xl my-8">My Gigs</h1>
    <AccountBalance v-if="user?.user" :user="user" :isUser="true" />
    <UContainer v-if="gigs && gigs.length">
      <UCard
        v-for="(gig, i) in gigs"
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
                :src="staticURL + gig.medias[0].image"
                class="size-14 rounded-full"
              />
            </div>
            <div>
              <div class="relative">
                <h3 class="text-base font-semibold mb-1.5 ml-5 capitalize">
                  {{ gig.title }}
                </h3>
                <UIcon
                  name="i-ci:dot-05-xl"
                  class="text-lg absolute top-1 left-0"
                  :class="gig.active_gig ? 'text-green-500' : 'text-red-500'"
                />
              </div>
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
          <div class="flex gap-1 items-center">
            <UButton
              size="md"
              color="primary"
              variant="solid"
              label="Pause"
              v-if="gig.active_gig"
              @click="handleAction(gig.id, 'pause', false)"
            />
            <UButton
              size="md"
              color="primary"
              variant="solid"
              label="Activate"
              v-if="!gig.active_gig"
              @click="handleAction(gig.id, 'active', true)"
            />
            <UButton
              size="md"
              color="primary"
              variant="solid"
              label="Edit"
              :to="`/edit-a-gig/${gig.id}`"
            />
            <UButton
              size="md"
              color="primary"
              variant="solid"
              label="Delete"
              @click="handleAction(gig.id, 'delete')"
            />
            <UButton
              size="md"
              color="primary"
              variant="solid"
              label="Details"
              :to="`/my-gigs/details/${gig.id}/`"
            />
          </div>
        </div>
      </UCard>
    </UContainer>
    <div v-else>
      <UContainer>
        <UCard class="py-20">
          <p class="text-center text-sm text-gray-500">No gigs found.</p>
        </UCard>
      </UContainer>
    </div>
  </PublicSection>
</template>
<script setup>
const { user } = useAuth();
const gigs = ref([]);
const route = useRoute();
const { get, staticURL, del, put } = useApi();

async function handleAction(id, action, val) {
  const res = await (action === "delete"
    ? del("/delete-user-micro-gig/" + id + "/")
    : put("/update-user-micro-gig/" + id + "/", {
        active_gig: val,
      }));
  console.log(res);
  if (res.data) {
    getUserGigs();
  }
}

async function getUserGigs() {
  try {
    const res = await get(`/user-micro-gigs/${route.params.id}/`);
    console.log(res);
    gigs.value = res.data;
  } catch (error) {
    console.log(error);
  }
}
getUserGigs();
</script>
