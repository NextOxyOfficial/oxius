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
        <div class="flex flex-col gap-4 md:flex-row justify-between">
          <div class="flex gap-4">
            <div>
              <NuxtImg
                :src="staticURL + gig?.category_details.image"
                class="size-12 rounded-full"
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
                  :class="
                    gig.gig_status === 'approved' && gig.active_gig
                      ? 'text-green-500'
                      : 'text-red-500'
                  "
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
                <p class="text-sm">{{ gig.balance }} /{{ gig.total_cost }}</p>
                <p class="text-sm">
                  {{ formatDate(gig.created_at) }}
                </p>

                <div class="text-sm">
                  <p
                    class="font-semibold capitalize"
                    v-if="gig.gig_status === 'approved'"
                  >
                    Live
                  </p>
                  <p
                    class="font-semibold capitalize"
                    v-if="gig.gig_status === 'completed'"
                  >
                    {{ gig.gig_status }}
                  </p>
                  <p
                    class="font-semibold capitalize"
                    v-if="gig.gig_status === 'pending'"
                  >
                    {{ gig.gig_status }}
                  </p>
                  <p
                    class="font-semibold capitalize"
                    v-if="gig.gig_status === 'rejected'"
                  >
                    {{ gig.gig_status }}
                  </p>
                </div>
              </div>
            </div>
          </div>
          <div class="flex gap-1 items-center max-md:justify-center">
            <UButton
              size="md"
              color="primary"
              variant="outline"
              label="Pause"
              v-if="gig.active_gig && gig.gig_status !== 'completed'"
              @click="handleAction(gig.id, 'pause', false)"
            />
            <UButton
              size="md"
              color="primary"
              variant="outline"
              label="Activate"
              v-if="!gig.active_gig && gig.gig_status !== 'completed'"
              @click="handleAction(gig.id, 'active', true)"
            />
            <UButton
              v-if="gig.gig_status !== 'completed'"
              size="md"
              color="primary"
              variant="outline"
              label="Edit"
              :to="`/edit-a-gig/${gig.id}`"
            />
            <UButton
              v-if="gig.gig_status !== 'completed'"
              size="md"
              color="primary"
              variant="outline"
              label="Complete"
              @click="handlePop(gig.id)"
            />
            <UButton
              size="md"
              color="primary"
              variant="outline"
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
    <UModal v-model="isOpen">
      <div class="py-10 px-6 text-center">
        <h4 class="text-2xl font-medium mb-4">
          It will stop the gig for forever?
        </h4>

        <UButton
          size="md"
          color="primary"
          variant="solid"
          label="Stop"
          @click="handleAction(currentId, 'completed')"
        />
      </div>
    </UModal>
  </PublicSection>
</template>
<script setup>
const { formatDate } = useUtils();
const isOpen = ref(false);
const currentId = ref();
function handlePop(id) {
  isOpen.value = true;
  currentId.value = id;
}

const { user, jwtLogin } = useAuth();
const gigs = ref([]);
const route = useRoute();
const { get, staticURL, put } = useApi();

async function handleAction(id, action, val) {
  const res = await (action === "completed"
    ? put("/update-user-micro-gig/" + id + "/", {
        stop_gig: true,
        active_gig: false,
      })
    : put("/update-user-micro-gig/" + id + "/", {
        active_gig: val,
      }));
  isOpen.value = false;
  if (res.data) {
    jwtLogin();
    getUserGigs();
  }
}

async function getUserGigs() {
  try {
    const res = await get(`/user-micro-gigs/${route.params.id}/`);

    gigs.value = res.data;
    console.log(res.data);
  } catch (error) {
    console.log(error);
  }
}
getUserGigs();
</script>
