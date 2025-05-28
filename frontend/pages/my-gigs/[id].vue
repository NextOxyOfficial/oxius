<template>
  <PublicSection>
    <h1 class="text-center text-2xl my-8">My Gigs</h1>
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
          <div class="flex gap-2 sm:gap-4 flex-1">
            <div>
              <NuxtImg
                :src="gig?.category_details.image"
                class="size-12 rounded-full object-contain"
              />
            </div>
            <div class="flex-1">
              <div class="relative flex">
                <span
                  class="font-semibold capitalize text-sm ml-4 mr-1"
                  v-if="gig.gig_status === 'approved'"
                >
                  Live
                </span>
                <span
                  class="font-semibold capitalize text-sm ml-4 mr-1"
                  v-if="gig.gig_status === 'completed'"
                >
                  {{ gig.gig_status }}
                </span>
                <span
                  class="font-semibold capitalize text-sm ml-4 mr-1"
                  v-if="gig.gig_status === 'pending'"
                >
                  {{ gig.gig_status }}
                </span>
                <span
                  class="font-semibold capitalize text-sm ml-4 mr-1"
                  v-if="gig.gig_status === 'rejected'"
                >
                  {{ gig.gig_status }}
                </span>
                <span>|</span>
                <span class="text-base font-semibold ml-1 capitalize">{{
                  gig.title
                }}</span>

                <UIcon
                  v-if="gig.gig_status === 'completed'"
                  name="i-ci:dot-05-xl"
                  class="text-lg absolute top-[3px] left-0 hidden"
                />
                <UIcon
                  v-else
                  name="i-ci:dot-05-xl"
                  class="text-lg absolute top-[3px] left-0"
                  :class="
                    gig.gig_status === 'approved' && gig.active_gig
                      ? 'text-green-500'
                      : 'text-red-500'
                  "
                />
              </div>
              <div class="flex gap-1 sm:gap-4">
                <div class="flex gap-1 items-center">
                  <UIcon
                    name="i-heroicons-bell-solid"
                    class="text-sm sm:text-sm"
                  />
                  <p class="text-sm sm:text-sm">
                    <span class="">{{ gig.filled_quantity }}</span> /
                    <span class="text-green-600">{{
                      gig.required_quantity
                    }}</span>
                  </p>
                </div>
                <p class="text-sm sm:text-sm">
                  {{ gig.balance }} /{{ gig.total_cost }}
                </p>
                <p class="text-sm sm:text-sm">
                  {{ formatDate(gig.created_at) }}
                </p>
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
              label="Stop"
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
          <p class="text-center text-sm text-gray-600">No gigs found.</p>
        </UCard>
      </UContainer>
    </div>
    <UModal v-model="isOpen" class="confirmation-modal">
      <div class="px-2 py-4 sm:p-6 flex flex-col items-center">
        <!-- Warning Icon -->
        <div
          class="mb-6 p-4 rounded-full bg-amber-50 text-amber-500 border border-amber-200"
        >
          <svg
            xmlns="http://www.w3.org/2000/svg"
            fill="none"
            viewBox="0 0 24 24"
            stroke="currentColor"
            class="w-10 h-10"
          >
            <path
              stroke-linecap="round"
              stroke-linejoin="round"
              stroke-width="2"
              d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z"
            />
          </svg>
        </div>

        <!-- Title and Description -->
        <div class="text-center mb-8">
          <h3 class="text-xl font-semibold text-gray-800 mb-2">Stop this gig?</h3>
          <p class="text-gray-600 max-w-sm">
            This action will permanently stop the current gig and cannot be
            undone.
          </p>
        </div>

        <!-- Divider -->
        <div class="w-full h-px bg-gray-200 mb-8"></div>

        <!-- Action Buttons -->
        <div class="flex gap-4 w-full">
          <button
            class="flex-1 py-2 px-3 bg-gray-100 hover:bg-gray-200 text-gray-800 font-semibold rounded-lg transition-all duration-200 ease-in-out transform hover:scale-105 focus:outline-none focus:ring-2 focus:ring-gray-400 focus:ring-opacity-50 shadow-sm"
            @click="isOpen = false"
          >
            <div class="flex items-center justify-center">
              <svg
                xmlns="http://www.w3.org/2000/svg"
                fill="none"
                viewBox="0 0 24 24"
                stroke="currentColor"
                class="w-5 h-5 mr-2"
              >
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M6 18L18 6M6 6l12 12"
                />
              </svg>
              <span>Cancel</span>
            </div>
          </button>

          <button
            class="flex-1 py-2 px-3 bg-red-600 hover:bg-red-700 text-white font-semibold rounded-lg transition-all duration-200 ease-in-out transform hover:scale-105 focus:outline-none focus:ring-2 focus:ring-red-500 focus:ring-opacity-50 shadow-sm"
            :class="{ 'opacity-75 cursor-not-allowed': isLoading }"
            :disabled="isLoading"
            @click="handleAction(currentId, 'completed')"
          >
            <div class="flex items-center justify-center">
              <template v-if="!isLoading">
                <svg
                  xmlns="http://www.w3.org/2000/svg"
                  fill="none"
                  viewBox="0 0 24 24"
                  stroke="currentColor"
                  class="w-5 h-5 mr-2"
                >
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="2"
                    d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"
                  />
                </svg>
                <span>Yes, stop</span>
              </template>
              <template v-else>
                <svg
                  xmlns="http://www.w3.org/2000/svg"
                  fill="none"
                  viewBox="0 0 24 24"
                  stroke="currentColor"
                  class="w-5 h-5 mr-2 animate-spin"
                >
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="2"
                    d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15"
                  />
                </svg>
                <span>Processing...</span>
              </template>
            </div>
          </button>
        </div>
      </div>
    </UModal>
  </PublicSection>
</template>
<script setup>
const toast = useToast();
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
const { get, put } = useApi();
const isLoading = ref(false);

async function handleAction(id, action, val) {
  isLoading.value = true;
  try {
    const res = await (action === "completed"
      ? put("/update-user-micro-gig/" + id + "/", {
          stop_gig: true,
          active_gig: false,
        })
      : put("/update-user-micro-gig/" + id + "/", {
          active_gig: val,
        }));

    // Only close modal and refresh data on success
    isOpen.value = false;
    if (res.data) {
      jwtLogin();
      getUserGigs();
      // Show success message
      toast.add({
        title:
          action === "completed"
            ? "Gig stopped successfully"
            : val
            ? "Gig activated successfully"
            : "Gig paused successfully",
        color: "green",
        timeout: 3000,
      });
    } else {
      toast.add({
        title: "Action failed",
        description: res.error?.data?.error,
        color: "red",
        timeout: 5000,
      });
    }
  } catch (error) {
    // Handle validation error from backend
    console.error("Error updating gig:", error);
    const errorMessage =
      error.response?.data?.error ||
      error.response?.data?.detail ||
      "Failed to update gig. Try again later.";

    // Show error message
    toast.add({
      title: "Action failed",
      description: errorMessage,
      color: "red",
      timeout: 5000,
    });

    // Don't close modal if it was a stop action that failed
    if (action !== "completed") {
      isOpen.value = false;
    }
  } finally {
    isLoading.value = false;
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
