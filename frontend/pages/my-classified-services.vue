<template>
  <PublicSection>
    <UContainer class="max-w-7xl mx-auto py-4 sm:py-6">
      <!-- Header -->
      <div
        class="bg-gradient-to-r from-emerald-600 to-teal-500 rounded-xl px-5 py-5 mb-5 flex flex-col sm:flex-row items-center justify-between gap-4"
      >
        <div class="text-center sm:text-left">
          <h1 class="text-lg sm:text-xl font-semibold text-white">
            My Classified Posts
          </h1>
          <p class="text-emerald-50/90 text-sm mt-0.5">
            Manage your free service ads in one place
          </p>
        </div>
        <UButton
          to="/classified-categories/post/"
          color="white"
          class="font-medium rounded-lg px-5 py-2.5 text-emerald-700"
        >
          <UIcon name="i-heroicons-plus-circle" class="mr-1.5 text-lg" />
          <span>Post Free Ads</span>
        </UButton>
      </div>

      <!-- Empty state (user has no posts at all) -->
      <UCard v-if="!services.length" class="py-16 text-center">
        <div class="flex flex-col items-center">
          <div class="h-20 w-20 rounded-full bg-emerald-50 flex items-center justify-center mb-4">
            <UIcon name="i-heroicons-document-text" class="h-9 w-9 text-emerald-500" />
          </div>
          <p class="text-slate-700 font-medium">You haven't posted any ad yet</p>
          <p class="text-slate-400 text-sm mt-1">Create your first free service ad to get started.</p>
          <UButton
            class="mt-6 font-medium rounded-lg px-6 py-2.5"
            color="primary"
            to="/classified-categories/post/"
          >
            <UIcon name="i-heroicons-plus-circle" class="mr-2" />
            <span>Create Your First Post</span>
          </UButton>
        </div>
      </UCard>

      <!-- Two-column layout -->
      <div v-else class="grid grid-cols-1 lg:grid-cols-[256px_minmax(0,1fr)] gap-5">
        <!-- Sidebar: categories -->
        <aside class="lg:sticky lg:top-4 h-max">
          <div class="bg-white rounded-xl border border-slate-200 overflow-hidden">
            <div class="px-4 py-3 border-b border-slate-100">
              <h2 class="text-sm font-semibold text-slate-700 flex items-center gap-1.5">
                <UIcon name="i-heroicons-squares-2x2" class="text-emerald-600" />
                Categories
              </h2>
            </div>
            <nav class="p-2 space-y-0.5 max-h-[60vh] overflow-y-auto">
              <button :class="categoryBtnClass('all')" @click="selectCategory('all')">
                <span class="flex items-center gap-2 truncate">
                  <UIcon name="i-heroicons-square-3-stack-3d" class="shrink-0" />
                  <span class="truncate">All Categories</span>
                </span>
                <span :class="countBadgeClass('all')">{{ services.length }}</span>
              </button>
              <button
                v-for="cat in categories"
                :key="cat.id"
                :class="categoryBtnClass(cat.id)"
                @click="selectCategory(cat.id)"
              >
                <span class="flex items-center gap-2 truncate">
                  <UIcon name="i-tabler:category-filled" class="shrink-0" />
                  <span class="truncate capitalize">{{ cat.title }}</span>
                </span>
                <span :class="countBadgeClass(cat.id)">{{ cat.count }}</span>
              </button>
            </nav>
          </div>
        </aside>

        <!-- Main content -->
        <div class="min-w-0">
          <!-- Status filter tabs -->
          <div class="flex gap-1.5 overflow-x-auto pb-2 mb-3">
            <button
              v-for="tab in statusTabs"
              :key="tab.key"
              :class="tabClass(tab.key)"
              @click="selectStatus(tab.key)"
            >
              <span>{{ tab.label }}</span>
              <span :class="tabCountClass(tab.key)">{{ statusCount(tab.key) }}</span>
            </button>
          </div>

          <!-- Striped post list -->
          <div v-if="paginatedServices.length" class="space-y-2.5">
            <div
              v-for="service in paginatedServices"
              :key="service.id"
              class="bg-white rounded-xl border border-slate-200 hover:border-emerald-300 hover:shadow-sm transition-all overflow-hidden"
            >
              <div class="flex items-stretch">
                <!-- Thumbnail -->
                <NuxtLink
                  :to="detailLink(service)"
                  class="shrink-0 w-24 sm:w-28 bg-slate-50 flex items-center justify-center p-2"
                >
                  <img
                    :src="thumbUrl(service)"
                    :alt="service.title || 'Post image'"
                    class="w-full h-full max-h-24 object-contain"
                  />
                </NuxtLink>

                <!-- Body -->
                <div class="flex-1 min-w-0 py-3 px-3 sm:px-4">
                  <div class="flex items-start justify-between gap-2">
                    <NuxtLink :to="detailLink(service)" class="min-w-0">
                      <h3 class="text-sm sm:text-[15px] font-semibold text-slate-800 line-clamp-1 capitalize hover:text-emerald-600">
                        {{ service.title }}
                      </h3>
                    </NuxtLink>
                    <span :class="statusBadgeClass(service)">
                      <span v-if="statusMeta(service).dot" class="w-1.5 h-1.5 rounded-full bg-emerald-500 animate-pulse"></span>
                      {{ statusMeta(service).label }}
                    </span>
                  </div>

                  <!-- Meta -->
                  <div class="mt-1.5 flex flex-wrap items-center gap-x-3 gap-y-1 text-xs text-slate-500">
                    <span class="inline-flex items-center gap-1">
                      <UIcon name="i-tabler:category-filled" />
                      <span class="capitalize">{{ service.category_details?.title }}</span>
                    </span>
                    <span class="inline-flex items-center gap-1">
                      <UIcon name="i-heroicons-clock" />
                      {{ formatDate(service.created_at) }}
                    </span>
                    <span v-if="service.location" class="inline-flex items-center gap-1">
                      <UIcon name="i-heroicons-map-pin" />
                      <span class="line-clamp-1">{{ service.location }}</span>
                    </span>
                    <span class="inline-flex items-center gap-1 font-medium text-slate-700">
                      <template v-if="!service.negotiable">
                        <UIcon name="i-mdi:currency-bdt" />{{ service.price }}
                      </template>
                      <template v-else>Negotiable</template>
                    </span>
                  </div>

                  <!-- Actions -->
                  <div class="mt-2.5 flex flex-wrap gap-1.5">
                    <UButton
                      v-if="service.active_service && service.service_status !== 'completed'"
                      size="xs"
                      color="gray"
                      variant="soft"
                      :loading="isLoading && actionTarget === service.id && actionType === 'pause'"
                      @click.prevent="handleAction(service.id, 'pause', false)"
                    >
                      <UIcon name="i-heroicons-pause" class="mr-1" /> Pause
                    </UButton>

                    <UButton
                      v-if="!service.active_service"
                      size="xs"
                      color="primary"
                      variant="soft"
                      :loading="isLoading && actionTarget === service.id && actionType === 'active'"
                      @click.prevent="handleAction(service.id, 'active', true)"
                    >
                      <UIcon name="i-heroicons-play" class="mr-1" /> Activate
                    </UButton>

                    <UButton
                      v-if="service.service_status !== 'completed'"
                      size="xs"
                      color="gray"
                      variant="soft"
                      :to="`/classified-categories/post/?slug=${service.slug || service.id}`"
                    >
                      <UIcon name="i-heroicons-pencil-square" class="mr-1" /> Edit
                    </UButton>

                    <UButton
                      size="xs"
                      color="red"
                      variant="soft"
                      :loading="isLoading && actionTarget === service.id && actionType === 'complete'"
                      :disabled="service.service_status === 'completed'"
                      @click.prevent="handlePop(service.id)"
                    >
                      <UIcon name="i-heroicons-stop-circle" class="mr-1" />
                      {{ service.service_status === 'completed' ? 'Stopped' : 'Stop' }}
                    </UButton>
                  </div>
                </div>
              </div>
            </div>
          </div>

          <!-- No results for current filter -->
          <div v-else class="bg-white rounded-xl border border-slate-200 py-14 text-center">
            <UIcon name="i-heroicons-funnel" class="h-10 w-10 text-slate-300 mx-auto mb-3" />
            <p class="text-slate-600 font-medium">No {{ activeStatusLabel }} posts</p>
            <p class="text-slate-400 text-sm mt-1">Try a different filter or category.</p>
          </div>

          <!-- Pagination -->
          <div v-if="totalPages > 1" class="flex justify-center mt-5">
            <UPagination
              v-model="currentPage"
              :page-count="itemsPerPage"
              :total="filteredServices.length"
              :ui="{
                wrapper: 'flex items-center gap-1',
                rounded: 'rounded-md',
                default: {
                  size: 'sm',
                  activeButton: { variant: 'solid', color: 'primary' },
                  inactiveButton: { color: 'gray' },
                },
              }"
              @update:model-value="handlePageChange"
            />
          </div>
        </div>
      </div>

      <!-- Complete confirmation modal -->
      <UModal v-model="isOpen">
        <div class="bg-gradient-to-b from-emerald-600 to-emerald-700 p-6 text-white">
          <div class="flex items-center justify-center">
            <div class="bg-white/20 p-3 rounded-full">
              <UIcon name="i-heroicons-exclamation-triangle" class="h-8 w-8" />
            </div>
          </div>
          <h3 class="text-xl font-semibold mt-4 text-center">Complete Post</h3>
        </div>

        <div class="p-6">
          <p class="text-gray-600 mb-6 text-center">
            This will mark your post as completed and it will no longer be
            active. This action cannot be undone.
          </p>

          <div class="flex justify-center gap-3">
            <UButton
              color="white"
              variant="solid"
              class="px-4 py-2 border border-gray-300"
              @click="isOpen = false"
            >
              <UIcon name="i-heroicons-x-mark" class="mr-1.5" />
              <span>Cancel</span>
            </UButton>

            <UButton
              color="primary"
              variant="solid"
              class="px-4 py-2"
              :loading="isLoading && actionType === 'complete'"
              @click="handleAction(currentId, 'complete')"
            >
              <UIcon name="i-heroicons-check-circle" class="mr-1.5" />
              <span>Confirm Complete</span>
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

const { get, put, staticURL } = useApi();
const { formatDate } = useUtils();
const toast = useToast();

const services = ref([]);
const isLoading = ref(false);
const actionTarget = ref(null);
const actionType = ref(null);

// Complete modal
const isOpen = ref(false);
const currentId = ref();

// Filters + pagination
const statusFilter = ref("all");
const categoryFilter = ref("all");
const currentPage = ref(1);
const itemsPerPage = ref(6);

const statusTabs = [
  { key: "all", label: "All" },
  { key: "active", label: "Active" },
  { key: "pending", label: "Pending" },
  { key: "paused", label: "Paused" },
  { key: "completed", label: "Completed" },
];

// Map a post to one of the tab statuses
function statusOf(s) {
  const st = (s.service_status || "").toLowerCase();
  if (st === "completed") return "completed";
  if (!s.active_service) return "paused";
  if (st === "pending") return "pending";
  if (st === "rejected") return "rejected";
  if (st === "approved") return "active";
  return "other";
}

function catId(s) {
  return s.category_details?.id ?? s.category_details?.title ?? "unknown";
}

// Categories the user has posted in, with counts
const categories = computed(() => {
  const map = new Map();
  for (const s of services.value) {
    if (!s.category_details) continue;
    const id = catId(s);
    if (!map.has(id)) {
      map.set(id, { id, title: s.category_details.title, count: 0 });
    }
    map.get(id).count++;
  }
  return [...map.values()].sort((a, b) => b.count - a.count);
});

// Posts narrowed by the selected category (used for status counts)
const categoryServices = computed(() =>
  categoryFilter.value === "all"
    ? services.value
    : services.value.filter((s) => catId(s) === categoryFilter.value)
);

function statusCount(key) {
  if (key === "all") return categoryServices.value.length;
  return categoryServices.value.filter((s) => statusOf(s) === key).length;
}

// Final list after both filters
const filteredServices = computed(() =>
  statusFilter.value === "all"
    ? categoryServices.value
    : categoryServices.value.filter((s) => statusOf(s) === statusFilter.value)
);

const totalPages = computed(() =>
  Math.ceil(filteredServices.value.length / itemsPerPage.value)
);

const paginatedServices = computed(() => {
  const start = (currentPage.value - 1) * itemsPerPage.value;
  return filteredServices.value.slice(start, start + itemsPerPage.value);
});

const activeStatusLabel = computed(
  () => statusTabs.find((t) => t.key === statusFilter.value)?.label.toLowerCase() || ""
);

// Keep current page in range when filters shrink the list
watch(totalPages, (tp) => {
  if (currentPage.value > tp) currentPage.value = Math.max(1, tp);
});

function selectStatus(key) {
  statusFilter.value = key;
  currentPage.value = 1;
}

function selectCategory(id) {
  categoryFilter.value = id;
  // Drop a status filter that has no posts in the new category
  if (statusFilter.value !== "all" && statusCount(statusFilter.value) === 0) {
    statusFilter.value = "all";
  }
  currentPage.value = 1;
}

function handlePageChange(page) {
  currentPage.value = page;
  window.scrollTo({ top: 0, behavior: "smooth" });
}

// ---- Presentation helpers ----
function thumbUrl(service) {
  const url = service.medias?.[0]?.image || service.category_details?.image;
  if (!url) return "";
  if (url.startsWith("http://") || url.startsWith("https://")) return url;
  return staticURL + (url.startsWith("/") ? url : "/" + url);
}

function detailLink(service) {
  return `/classified-categories/details/${service.slug || service.id}`;
}

function statusMeta(s) {
  switch (statusOf(s)) {
    case "active":
      return { label: "Live", dot: true };
    case "pending":
      return { label: "Pending" };
    case "paused":
      return { label: "Paused" };
    case "completed":
      return { label: "Completed" };
    case "rejected":
      return { label: "Rejected" };
    default:
      return { label: "Active" };
  }
}

function statusBadgeClass(s) {
  const base =
    "shrink-0 inline-flex items-center gap-1 px-2.5 py-0.5 rounded-full text-[11px] font-semibold ring-1 ring-inset";
  const map = {
    active: "bg-emerald-50 text-emerald-700 ring-emerald-200",
    pending: "bg-amber-50 text-amber-700 ring-amber-200",
    paused: "bg-slate-100 text-slate-600 ring-slate-200",
    completed: "bg-blue-50 text-blue-700 ring-blue-200",
    rejected: "bg-red-50 text-red-700 ring-red-200",
    other: "bg-slate-100 text-slate-600 ring-slate-200",
  };
  return `${base} ${map[statusOf(s)] || map.other}`;
}

function categoryBtnClass(id) {
  const active = categoryFilter.value === id;
  return [
    "w-full flex items-center justify-between gap-2 px-3 py-2 rounded-lg text-sm transition-colors",
    active
      ? "bg-emerald-50 text-emerald-700 font-medium"
      : "text-slate-600 hover:bg-slate-50",
  ];
}

function countBadgeClass(id) {
  const active = categoryFilter.value === id;
  return [
    "shrink-0 inline-flex items-center justify-center min-w-[22px] h-5 px-1.5 rounded-full text-[11px] font-semibold",
    active ? "bg-emerald-600 text-white" : "bg-slate-100 text-slate-500",
  ];
}

function tabClass(key) {
  const active = statusFilter.value === key;
  return [
    "shrink-0 inline-flex items-center gap-1.5 px-3.5 py-1.5 rounded-full text-sm font-medium border transition-colors",
    active
      ? "bg-emerald-600 border-emerald-600 text-white"
      : "bg-white border-slate-200 text-slate-600 hover:bg-slate-50",
  ];
}

function tabCountClass(key) {
  const active = statusFilter.value === key;
  return [
    "inline-flex items-center justify-center min-w-[20px] h-[18px] px-1 rounded-full text-[11px] font-semibold",
    active ? "bg-white/25 text-white" : "bg-slate-100 text-slate-500",
  ];
}

// ---- Data ----
async function fetchServices() {
  try {
    const response = await get(`/user-classified-categories-post/`);
    services.value = response.data;
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

async function handlePop(id) {
  currentId.value = id;
  await nextTick();
  isOpen.value = true;
}

async function handleAction(id, action, val) {
  isLoading.value = true;
  actionTarget.value = id;
  actionType.value = action;

  try {
    const res = await put("/update-user-classified-post/" + id + "/",
      action === "complete"
        ? { service_status: "completed" }
        : { active_service: val }
    );

    isOpen.value = false;

    if (res.data) {
      await fetchServices();

      const messages = {
        complete: { title: "Post Completed", description: "Your post has been marked as completed.", icon: "i-heroicons-check-circle", color: "blue" },
        pause: { title: "Post Paused", description: "Your post has been paused.", icon: "i-heroicons-pause-circle", color: "yellow" },
        active: { title: "Post Activated", description: "Your post has been activated.", icon: "i-heroicons-play-circle", color: "green" },
      };
      if (messages[action]) toast.add({ ...messages[action], timeout: 3000 });
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

fetchServices();
</script>
