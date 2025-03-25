<template>
  <PublicSection>
    <UContainer class="max-w-7xl mx-auto">
      <!-- Header Section with Animated Background -->
      <div
        class="relative overflow-hidden bg-gradient-to-r from-emerald-600 to-teal-500 rounded-xl py-6 mb-8"
      >
        <!-- Animated Particles -->
        <div class="absolute inset-0 overflow-hidden">
          <div
            v-for="n in 10"
            :key="`particle-${n}`"
            class="absolute rounded-full bg-white/10"
            :style="{
              width: `${10 + Math.random() * 20}px`,
              height: `${10 + Math.random() * 20}px`,
              top: `${Math.random() * 100}%`,
              left: `${Math.random() * 100}%`,
              animation: `float-particle ${
                3 + Math.random() * 5
              }s infinite ease-in-out ${Math.random() * 5}s`,
            }"
          ></div>
        </div>

        <div class="relative z-10 px-4">
          <h2
            class="text-center text-2xl md:text-4xl font-bold text-white mb-4"
          >
            My Classified Posts
          </h2>

          <!-- Improved Post Ads Button -->
          <div class="flex justify-center mt-2 mb-2">
            <UButton
              to="/classified-categories/post/"
              class="relative overflow-hidden bg-white hover:bg-gray-50 text-emerald-600 font-medium rounded-lg px-6 py-2.5 shadow-lg hover:shadow-xl transition-all duration-300 transform hover:scale-105 border-2 border-white"
            >
              <!-- Button Shimmer Effect -->
              <div
                class="absolute inset-0 opacity-0 hover:opacity-30 z-0"
                :style="{
                  background:
                    'linear-gradient(115deg, transparent 25%, rgba(16, 185, 129, 0.2) 45%, rgba(16, 185, 129, 0.3) 55%, transparent 70%)',
                  backgroundSize: '200% 100%',
                  animation: 'shimmer 3s infinite linear',
                }"
              ></div>

              <!-- Button Content with Icon -->
              <div class="relative z-10 flex items-center">
                <UIcon name="i-heroicons-plus-circle" class="mr-2 text-lg" />
                <span class="text-base">Post Free Ads</span>
                <UIcon
                  name="i-heroicons-arrow-right"
                  class="ml-2 text-lg transform group-hover:translate-x-1 transition-transform duration-300"
                />
              </div>
            </UButton>
          </div>
        </div>
      </div>

      <!-- Services List -->
      <div class="services mt-4" v-if="services.length">
        <div
          v-for="(service, i) in paginatedServices"
          :key="i"
          class="service-card mb-4 transform transition-all duration-300 hover:-translate-y-1 hover:shadow-xl"
        >
          <UCard
            :ui="{
              background: 'bg-white',
              ring: '',
              shadow: 'shadow-md',
              rounded: 'rounded-xl',
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
            class="border border-slate-100 overflow-hidden relative"
          >
            <!-- Status Badge -->
            <div
              class="absolute top-5 right-5 z-20 px-3 py-1 rounded-full text-xs font-semibold shadow-sm"
              :class="{
                'bg-emerald-100 text-emerald-700':
                  service.service_status === 'approved' &&
                  service.active_service,
                'bg-yellow-100 text-yellow-700':
                  service.service_status.toLowerCase() === 'pending' ||
                  !service.active_service,
                'bg-red-100 text-red-700':
                  service.service_status.toLowerCase() === 'rejected',
                'bg-blue-100 text-blue-700':
                  service.service_status === 'completed',
              }"
            >
              <div class="flex items-center">
                <span
                  v-if="
                    service.service_status === 'approved' &&
                    service.active_service
                  "
                  class="w-2 h-2 bg-emerald-500 rounded-full mr-1.5 animate-pulse"
                ></span>
                <span
                  v-if="
                    service.service_status === 'approved' &&
                    service.active_service
                  "
                  >Live</span
                >
                <span v-else-if="service.service_status === 'completed'"
                  >Completed</span
                >
                <span
                  v-else-if="service.service_status.toLowerCase() === 'pending'"
                  >Pending</span
                >
                <span v-else-if="!service.active_service">Paused</span>
                <span
                  v-else-if="
                    service.service_status.toLowerCase() === 'rejected'
                  "
                  >Rejected</span
                >
              </div>
            </div>
            <div
              class="absolute top-12 right-5 z-20 rounded-full text-xs font-semibold shadow-sm"
            >
              <div class="">
                <span
                  class="inline-flex items-center px-3 py-1 rounded-full text-xs font-medium bg-slate-200 text-slate-800"
                >
                  <span v-if="!service.negotiable">
                    <UIcon name="i-mdi:currency-bdt" class="mr-1" />
                    {{ service.price }}
                  </span>
                  <span v-else>Negotiable</span>
                </span>
              </div>
            </div>

            <!-- Card Content -->
            <NuxtLink :to="`/classified-categories/details/${service.id}`">
              <div class="flex flex-col md:flex-row p-4">
                <!-- Image Section - Decreased Size -->
                <div class="md:w-[120px] mb-4 md:mb-0 md:mr-6 flex-shrink-0">
                  <div
                    class="w-full h-48 md:h-24 rounded-lg overflow-hidden bg-slate-100 shadow-sm"
                  >
                    <NuxtImg
                      v-if="service.medias && service.medias[0]?.image"
                      :src="service.medias[0].image"
                      class="w-full h-full object-cover transition-transform duration-500 hover:scale-110"
                      alt="Post image"
                    />
                    <img
                      v-else
                      :src="service.category_details.image"
                      class="w-full h-full object-cover transition-transform duration-500 hover:scale-110"
                      alt="Category image"
                    />
                  </div>
                </div>

                <!-- Content Section -->
                <div class="flex-1">
                  <h3
                    class="text-sm sm:text-base font-semibold mb-2 text-left line-clamp-2 capitalize"
                  >
                    {{ service?.title }}
                  </h3>

                  <!-- Price Badge -->
                  <!-- <div class="mb-3">
                    <span
                      class="inline-flex items-center px-3 py-1 rounded-full text-sm font-medium bg-slate-100 text-slate-800"
                    >
                      <span v-if="!service.negotiable">
                        <UIcon name="i-mdi:currency-bdt" class="mr-1" />
                        {{ service.price }}
                      </span>
                      <span v-else>Negotiable</span>
                    </span>
                  </div> -->

                  <!-- Details Section -->
                  <div
                    class="flex flex-wrap items-center sm:items-start gap-4 gap-y-1"
                  >
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

                    <p class="inline-flex gap-1 items-center">
                      <UIcon name="i-heroicons-map-pin-solid" />
                      <span class="text-sm">{{ service?.location }}</span>
                    </p>
                  </div>
                </div>
              </div>
            </NuxtLink>

            <!-- Action Buttons with Icons and Effects -->
            <div
              class="flex justify-center md:justify-end p-4 bg-slate-50 border-t border-slate-100"
            >
              <div class="flex gap-2 items-center max-md:justify-center">
                <UButton
                  size="md"
                  color="primary"
                  variant="outline"
                  :loading="
                    isLoading &&
                    actionTarget === service.id &&
                    actionType === 'pause'
                  "
                  v-if="
                    service.active_service &&
                    service.service_status !== 'completed'
                  "
                  @click.prevent="handleAction(service.id, 'pause', false)"
                  class="group relative overflow-hidden"
                >
                  <!-- Button Shimmer Effect -->
                  <div
                    class="absolute inset-0 opacity-0 group-hover:opacity-20 z-0"
                    :style="{
                      background:
                        'linear-gradient(115deg, transparent 25%, rgba(16, 185, 129, 0.3) 45%, rgba(16, 185, 129, 0.4) 55%, transparent 70%)',
                      backgroundSize: '200% 100%',
                      animation: 'shimmer 3s infinite linear',
                    }"
                  ></div>

                  <div class="relative z-10 flex items-center">
                    <UIcon name="i-heroicons-pause-circle" class="mr-1.5" />
                    <span>Pause</span>
                  </div>
                </UButton>

                <UButton
                  size="md"
                  color="primary"
                  variant="outline"
                  :loading="
                    isLoading &&
                    actionTarget === service.id &&
                    actionType === 'active'
                  "
                  v-if="!service.active_service"
                  @click.prevent="handleAction(service.id, 'active', true)"
                  class="group relative overflow-hidden"
                >
                  <!-- Button Shimmer Effect -->
                  <div
                    class="absolute inset-0 opacity-0 group-hover:opacity-20 z-0"
                    :style="{
                      background:
                        'linear-gradient(115deg, transparent 25%, rgba(16, 185, 129, 0.3) 45%, rgba(16, 185, 129, 0.4) 55%, transparent 70%)',
                      backgroundSize: '200% 100%',
                      animation: 'shimmer 3s infinite linear',
                    }"
                  ></div>

                  <div class="relative z-10 flex items-center">
                    <UIcon name="i-heroicons-play-circle" class="mr-1.5" />
                    <span>Activate</span>
                  </div>
                </UButton>

                <UButton
                  size="md"
                  color="primary"
                  variant="outline"
                  v-if="service.service_status !== 'completed'"
                  :to="`/classified-categories/post/?id=${service.id}`"
                  class="group relative overflow-hidden"
                >
                  <!-- Button Shimmer Effect -->
                  <div
                    class="absolute inset-0 opacity-0 group-hover:opacity-20 z-0"
                    :style="{
                      background:
                        'linear-gradient(115deg, transparent 25%, rgba(16, 185, 129, 0.3) 45%, rgba(16, 185, 129, 0.4) 55%, transparent 70%)',
                      backgroundSize: '200% 100%',
                      animation: 'shimmer 3s infinite linear',
                    }"
                  ></div>

                  <div class="relative z-10 flex items-center">
                    <UIcon name="i-heroicons-pencil-square" class="mr-1.5" />
                    <span>Edit</span>
                  </div>
                </UButton>

                <UButton
                  size="md"
                  color="primary"
                  variant="outline"
                  :loading="
                    isLoading &&
                    actionTarget === service.id &&
                    actionType === 'complete'
                  "
                  :disabled="service.service_status === 'completed'"
                  @click.prevent="handlePop(service.id)"
                  class="group relative overflow-hidden"
                >
                  <!-- Button Shimmer Effect -->
                  <div
                    class="absolute inset-0 opacity-0 group-hover:opacity-20 z-0"
                    :style="{
                      background:
                        'linear-gradient(115deg, transparent 25%, rgba(16, 185, 129, 0.3) 45%, rgba(16, 185, 129, 0.4) 55%, transparent 70%)',
                      backgroundSize: '200% 100%',
                      animation: 'shimmer 3s infinite linear',
                    }"
                  ></div>

                  <div class="relative z-10 flex items-center">
                    <UIcon name="i-heroicons-stop-circle" class="mr-1.5" />
                    <span>{{
                      service.service_status === "completed"
                        ? "Stopped"
                        : "Stop"
                    }}</span>
                  </div>
                </UButton>
              </div>
            </div>
          </UCard>
        </div>

        <!-- Pagination -->
        <div class="flex justify-center mt-8 mb-4">
          <UPagination
            v-model="currentPage"
            :page-count="totalPages"
            :total="services.length"
            :ui="{
              wrapper: 'flex items-center gap-1',
              rounded: 'rounded-md',
              default: {
                size: 'h-10 w-10',
                active: 'bg-emerald-500 text-white hover:bg-emerald-600',
                inactive: 'bg-white text-gray-700 hover:bg-gray-100',
              },
            }"
            @update:model-value="handlePageChange"
          />
        </div>
      </div>

      <!-- Empty State -->
      <UCard v-else class="py-16 text-center mt-6">
        <div class="flex flex-col items-center">
          <UIcon
            name="i-heroicons-document-text"
            class="h-16 w-16 text-slate-300 mb-4"
          />
          <p>You haven't made any post yet!</p>
          <UButton
            class="mt-6 relative overflow-hidden bg-emerald-600 hover:bg-emerald-700 text-white font-medium rounded-lg px-6 py-2.5 shadow-lg hover:shadow-xl transition-all duration-300 transform hover:scale-105"
            to="/classified-categories/post/"
          >
            <!-- Button Shimmer Effect -->
            <div
              class="absolute inset-0 opacity-0 hover:opacity-30 z-0"
              :style="{
                background:
                  'linear-gradient(115deg, transparent 25%, rgba(255, 255, 255, 0.3) 45%, rgba(255, 255, 255, 0.4) 55%, transparent 70%)',
                backgroundSize: '200% 100%',
                animation: 'shimmer 3s infinite linear',
              }"
            ></div>

            <div class="relative z-10 flex items-center">
              <UIcon name="i-heroicons-plus-circle" class="mr-2" />
              <span>Create Your First Post</span>
            </div>
          </UButton>
        </div>
      </UCard>

      <!-- Enhanced Premium Modal -->
      <UModal
        v-model="isOpen"
        :ui="{
          container: 'flex min-h-full items-center justify-center text-center',
          overlay: 'fixed inset-0 bg-gray-900/50 backdrop-blur-sm',
          base: 'relative text-left bg-white dark:bg-gray-900 rounded-xl shadow-xl max-w-lg w-full max-h-[90vh] overflow-hidden',
          padding: 'p-0',
          width: 'w-full max-w-md',
        }"
      >
        <div
          class="bg-gradient-to-b from-emerald-600 to-emerald-700 p-6 text-white"
        >
          <div class="flex items-center justify-center">
            <div class="bg-white/20 p-3 rounded-full">
              <UIcon name="i-heroicons-exclamation-triangle" class="h-8 w-8" />
            </div>
          </div>
          <h3 class="text-xl font-semibold mt-4 text-center">Complete Post</h3>
        </div>

        <div class="p-6">
          <p class="text-gray-600 mb-6 text-center">
            This action will mark your post as completed and it will no longer
            be active. This action cannot be undone.
          </p>

          <div class="flex justify-center gap-3">
            <UButton
              color="white"
              variant="solid"
              @click="isOpen = false"
              class="px-4 py-2 border border-gray-300"
            >
              <div class="flex items-center">
                <UIcon name="i-heroicons-x-mark" class="mr-1.5" />
                <span>Cancel</span>
              </div>
            </UButton>

            <UButton
              color="primary"
              variant="solid"
              :loading="isLoading && actionType === 'complete'"
              @click="handleAction(currentId, 'complete')"
              class="px-4 py-2 relative overflow-hidden group"
            >
              <!-- Button Shimmer Effect -->
              <div
                class="absolute inset-0 opacity-0 group-hover:opacity-30 z-0"
                :style="{
                  background:
                    'linear-gradient(115deg, transparent 25%, rgba(255, 255, 255, 0.3) 45%, rgba(255, 255, 255, 0.4) 55%, transparent 70%)',
                  backgroundSize: '200% 100%',
                  animation: 'shimmer 3s infinite linear',
                }"
              ></div>

              <div class="relative z-10 flex items-center">
                <UIcon name="i-heroicons-check-circle" class="mr-1.5" />
                <span>Confirm Complete</span>
              </div>
            </UButton>
          </div>
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
const toast = useToast();
const actionTarget = ref(null);
const actionType = ref(null);

// Pagination
const currentPage = ref(1);
const itemsPerPage = ref(5);

// Computed property for paginated services
const paginatedServices = computed(() => {
  const startIndex = (currentPage.value - 1) * itemsPerPage.value;
  const endIndex = startIndex + itemsPerPage.value;
  return services.value.slice(startIndex, endIndex);
});

// Computed property for total pages
const totalPages = computed(() => {
  return Math.ceil(services.value.length / itemsPerPage.value);
});

// Handle page change
function handlePageChange(page) {
  currentPage.value = page;
  // Scroll to top of the list
  window.scrollTo({ top: 0, behavior: "smooth" });
}

function handlePop(id) {
  isOpen.value = true;
  currentId.value = id;
}

async function fetchServices() {
  try {
    const response = await get(`/user-classified-categories-post/`);
    services.value = response.data;
    categoryTitle.value = response.data[0]?.category_details.title;
    // Reset to first page when data is refreshed
    currentPage.value = 1;
  } catch (error) {
    console.error("Failed to fetch services:", error);
    toast.add({
      title: "Error",
      description: "Failed to fetch your posts. Please try again.",
      icon: "i-heroicons-x-circle",
      color: "red",
    });
  }
}

async function handleAction(id, action, val) {
  isLoading.value = true;
  actionTarget.value = id;
  actionType.value = action;

  try {
    const res = await (action === "complete"
      ? put("/update-user-classified-post/" + id + "/", {
          service_status: "completed",
        })
      : put("/update-user-classified-post/" + id + "/", {
          active_service: val,
        }));

    isOpen.value = false;

    if (res.data) {
      await fetchServices();

      // Show success toast based on action
      if (action === "complete") {
        toast.add({
          title: "Post Completed",
          description: "Your post has been marked as completed successfully.",
          icon: "i-heroicons-check-circle",
          color: "blue",
          timeout: 3000,
        });
      } else if (action === "pause") {
        toast.add({
          title: "Post Paused",
          description: "Your post has been paused successfully.",
          icon: "i-heroicons-pause-circle",
          color: "yellow",
          timeout: 3000,
        });
      } else if (action === "active") {
        toast.add({
          title: "Post Activated",
          description: "Your post has been activated successfully.",
          icon: "i-heroicons-play-circle",
          color: "green",
          timeout: 3000,
        });
      }
    }
  } catch (error) {
    console.error(`Failed to ${action} post:`, error);
    toast.add({
      title: "Action Failed",
      description: `Failed to ${action} your post. Please try again.`,
      icon: "i-heroicons-x-circle",
      color: "red",
      timeout: 3000,
    });
  } finally {
    isLoading.value = false;
    actionTarget.value = null;
    actionType.value = null;
  }
}

// Fetch services on component mount
fetchServices();
</script>

<style>
@keyframes shimmer {
  0% {
    background-position: 200% 0;
  }
  100% {
    background-position: -200% 0;
  }
}

@keyframes float-particle {
  0%,
  100% {
    transform: translateY(0) translateX(0);
    opacity: 0.5;
  }
  50% {
    transform: translateY(-20px) translateX(10px);
    opacity: 1;
  }
}

/* Service card hover effect */
.service-card:hover {
  transform: translateY(-4px);
  transition: all 0.3s ease;
}

/* Image hover effect */
.service-card img {
  transition: transform 0.5s ease;
}

.service-card:hover img {
  transform: scale(1.05);
}

/* Button hover effects */
.group:hover .group-hover\:translate-x-1 {
  transform: translateX(4px);
}
</style>
