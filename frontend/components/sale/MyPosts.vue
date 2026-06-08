<template>
  <div>
    <!-- Empty state (no posts at all) -->
    <UCard v-if="!posts.length && !isLoading" class="py-16 text-center">
      <div class="flex flex-col items-center">
        <div class="h-20 w-20 rounded-full bg-emerald-50 flex items-center justify-center mb-4">
          <UIcon name="i-heroicons-clipboard-document-list" class="h-9 w-9 text-emerald-500" />
        </div>
        <p class="text-slate-700 font-medium">No posts yet</p>
        <p class="text-slate-400 text-sm mt-1">Create your first listing to start selling in the marketplace.</p>
        <UButton class="mt-6 font-medium rounded-lg px-6 py-2.5" color="primary" @click="$emit('create-post')">
          <UIcon name="i-heroicons-plus-circle" class="mr-2" />
          <span>Create Your First Post</span>
        </UButton>
      </div>
    </UCard>

    <!-- Loading skeleton -->
    <div v-else-if="isLoading" class="grid grid-cols-1 lg:grid-cols-[256px_minmax(0,1fr)] gap-5">
      <div class="hidden lg:block h-64 bg-white rounded-xl border border-slate-200 animate-pulse"></div>
      <div class="space-y-2.5">
        <div v-for="i in 4" :key="i" class="h-28 bg-white rounded-xl border border-slate-200 animate-pulse"></div>
      </div>
    </div>

    <!-- Two-column layout -->
    <div v-else class="grid grid-cols-1 lg:grid-cols-[256px_minmax(0,1fr)] gap-5">
      <!-- Sidebar: categories -->
      <aside class="lg:sticky lg:top-4 h-max">
        <div class="bg-white rounded-xl border border-slate-200 overflow-hidden">
          <div class="px-4 py-3 border-b border-slate-100 flex items-center justify-between">
            <h2 class="text-sm font-semibold text-slate-700 flex items-center gap-1.5">
              <UIcon name="i-heroicons-squares-2x2" class="text-emerald-600" />
              Categories
            </h2>
            <button
              class="text-slate-400 hover:text-emerald-600 transition-colors"
              title="Refresh posts"
              @click="refreshPosts"
            >
              <UIcon name="i-heroicons-arrow-path" :class="{ 'animate-spin': isRefreshing }" />
            </button>
          </div>
          <nav class="p-2 space-y-0.5 max-h-[60vh] overflow-y-auto">
            <button :class="categoryBtnClass('all')" @click="selectCategory('all')">
              <span class="flex items-center gap-2 truncate">
                <UIcon name="i-heroicons-square-3-stack-3d" class="shrink-0" />
                <span class="truncate">All Categories</span>
              </span>
              <span :class="countBadgeClass('all')">{{ posts.length }}</span>
            </button>
            <button
              v-for="cat in categories"
              :key="cat.id"
              :class="categoryBtnClass(cat.id)"
              @click="selectCategory(cat.id)"
            >
              <span class="flex items-center gap-2 truncate">
                <UIcon name="i-heroicons-tag" class="shrink-0" />
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
        <div v-if="paginatedPosts.length" class="space-y-2.5">
          <div
            v-for="post in paginatedPosts"
            :key="post.id"
            class="bg-white rounded-xl border border-slate-200 hover:border-emerald-300 hover:shadow-sm transition-all overflow-hidden"
          >
            <div class="flex items-stretch">
              <!-- Thumbnail -->
              <NuxtLink
                :to="`/sale/${post.slug}`"
                class="shrink-0 w-24 sm:w-28 bg-slate-50 flex items-center justify-center p-2 relative"
              >
                <img
                  v-if="post.main_image"
                  :src="post.main_image"
                  :alt="post.title"
                  class="w-full h-full max-h-24 object-contain"
                />
                <UIcon v-else name="i-heroicons-photo" class="h-9 w-9 text-slate-300" />
              </NuxtLink>

              <!-- Body -->
              <div class="flex-1 min-w-0 py-3 px-3 sm:px-4">
                <div class="flex items-start justify-between gap-2">
                  <NuxtLink :to="`/sale/${post.slug}`" class="min-w-0">
                    <h3 class="text-sm sm:text-[15px] font-semibold text-slate-800 line-clamp-1 capitalize hover:text-emerald-600">
                      {{ post.title }}
                    </h3>
                  </NuxtLink>
                  <span :class="statusBadgeClass(post)">
                    <span v-if="statusMeta(post).dot" class="w-1.5 h-1.5 rounded-full bg-emerald-500 animate-pulse"></span>
                    {{ statusMeta(post).label }}
                  </span>
                </div>

                <!-- Meta -->
                <div class="mt-1.5 flex flex-wrap items-center gap-x-3 gap-y-1 text-xs text-slate-500">
                  <span v-if="post.category_name" class="inline-flex items-center gap-1">
                    <UIcon name="i-heroicons-tag" />
                    <span class="capitalize">{{ post.category_name }}</span>
                  </span>
                  <span class="inline-flex items-center gap-1">
                    <UIcon name="i-heroicons-calendar" />
                    {{ formatDate(post.created_at) }}
                  </span>
                  <span class="inline-flex items-center gap-1">
                    <UIcon name="i-heroicons-map-pin" />
                    <span class="line-clamp-1">{{ locationOf(post) }}</span>
                  </span>
                  <span class="inline-flex items-center gap-1">
                    <UIcon name="i-heroicons-eye" />{{ post.view_count }}
                  </span>
                  <span class="inline-flex items-center gap-1 font-medium text-slate-700">
                    <UIcon name="i-heroicons-currency-bangladeshi" class="h-4 w-4" />
                    {{ post.price ? `৳${Number(post.price).toLocaleString()}` : "Negotiable" }}
                  </span>
                </div>

                <!-- Actions -->
                <div class="mt-2.5 flex flex-wrap items-center gap-1.5">
                  <UButton
                    v-if="post.status !== 'sold' && post.status !== 'pending'"
                    size="xs"
                    color="primary"
                    variant="soft"
                    :loading="markingSold === post.id"
                    @click="markAsSold(post.id)"
                  >
                    <UIcon name="i-heroicons-tag" class="mr-1" /> Mark as Sold
                  </UButton>

                  <span
                    v-else-if="post.status === 'pending'"
                    class="inline-flex items-center gap-1 px-2.5 py-1 rounded-md text-xs font-medium bg-amber-50 text-amber-700 ring-1 ring-inset ring-amber-200"
                  >
                    <UIcon name="i-heroicons-clock" /> Awaiting Approval
                  </span>

                  <UButton
                    size="xs"
                    color="gray"
                    variant="soft"
                    @click="$emit('edit-post', post)"
                  >
                    <UIcon name="i-heroicons-pencil-square" class="mr-1" /> Edit
                  </UButton>

                  <UButton
                    size="xs"
                    color="red"
                    variant="soft"
                    @click="confirmDelete(post.id, post.title)"
                  >
                    <UIcon name="i-heroicons-trash" class="mr-1" /> Delete
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
            :total="filteredPosts.length"
            :ui="{
              wrapper: 'flex items-center gap-1',
              rounded: 'rounded-md',
              default: {
                size: 'sm',
                activeButton: { variant: 'solid', color: 'primary' },
                inactiveButton: { color: 'gray' },
              },
            }"
            @update:model-value="scrollTop"
          />
        </div>
      </div>
    </div>

    <!-- Delete confirmation modal -->
    <UModal v-model="showDeleteModal">
      <div class="p-6">
        <div class="flex items-start gap-4">
          <div class="shrink-0 h-12 w-12 rounded-full bg-red-50 flex items-center justify-center">
            <UIcon name="i-heroicons-exclamation-triangle" class="h-6 w-6 text-red-500" />
          </div>
          <div class="min-w-0">
            <h3 class="text-lg font-semibold text-slate-800">Delete Post</h3>
            <p class="text-slate-600 text-sm mt-1">
              Are you sure you want to delete
              "<span class="font-medium text-slate-800">{{ postToDeleteTitle }}</span>"?
              This action cannot be undone.
            </p>
          </div>
        </div>
        <div class="flex justify-end gap-3 mt-6">
          <UButton color="white" variant="solid" class="border border-gray-300" @click="showDeleteModal = false">
            Cancel
          </UButton>
          <UButton color="red" variant="solid" :loading="isDeleting" @click="deletePost">
            <UIcon name="i-heroicons-trash" class="mr-1.5" /> Delete Post
          </UButton>
        </div>
      </div>
    </UModal>
  </div>
</template>

<script setup>
import { ref, computed, watch, onMounted } from "vue";

const { get, post, del } = useApi();
const { user } = useAuth();
const { showNotification } = useNotifications();

const emit = defineEmits(["edit-post", "delete-post", "posts-updated", "create-post"]);

// State
const posts = ref([]);
const isLoading = ref(true);
const isRefreshing = ref(false);
const markingSold = ref(null);

// Filters + pagination
const statusFilter = ref("all");
const categoryFilter = ref("all");
const currentPage = ref(1);
const itemsPerPage = ref(8);

// Delete state
const showDeleteModal = ref(false);
const isDeleting = ref(false);
const postToDeleteId = ref(null);
const postToDeleteTitle = ref("");

const statusTabs = [
  { key: "all", label: "All" },
  { key: "active", label: "Active" },
  { key: "pending", label: "Pending" },
  { key: "sold", label: "Sold" },
  { key: "expired", label: "Expired" },
];

function catKey(p) {
  return p.category ?? p.category_name ?? "other";
}

// Categories the user has posted in, with counts
const categories = computed(() => {
  const map = new Map();
  for (const p of posts.value) {
    const id = catKey(p);
    if (!map.has(id)) {
      map.set(id, { id, title: p.category_name || "Other", count: 0 });
    }
    map.get(id).count++;
  }
  return [...map.values()].sort((a, b) => b.count - a.count);
});

// Posts narrowed by category (used for status counts)
const categoryPosts = computed(() =>
  categoryFilter.value === "all"
    ? posts.value
    : posts.value.filter((p) => catKey(p) === categoryFilter.value)
);

function statusCount(key) {
  if (key === "all") return categoryPosts.value.length;
  return categoryPosts.value.filter((p) => p.status === key).length;
}

const filteredPosts = computed(() =>
  statusFilter.value === "all"
    ? categoryPosts.value
    : categoryPosts.value.filter((p) => p.status === statusFilter.value)
);

const totalPages = computed(() =>
  Math.ceil(filteredPosts.value.length / itemsPerPage.value)
);

const paginatedPosts = computed(() => {
  const start = (currentPage.value - 1) * itemsPerPage.value;
  return filteredPosts.value.slice(start, start + itemsPerPage.value);
});

const activeStatusLabel = computed(
  () => statusTabs.find((t) => t.key === statusFilter.value)?.label.toLowerCase() || ""
);

watch(totalPages, (tp) => {
  if (currentPage.value > tp) currentPage.value = Math.max(1, tp);
});

function selectStatus(key) {
  statusFilter.value = key;
  currentPage.value = 1;
}

function selectCategory(id) {
  categoryFilter.value = id;
  if (statusFilter.value !== "all" && statusCount(statusFilter.value) === 0) {
    statusFilter.value = "all";
  }
  currentPage.value = 1;
}

function scrollTop() {
  if (process.client) window.scrollTo({ top: 0, behavior: "smooth" });
}

// ---- Presentation helpers ----
function locationOf(p) {
  return p.division && p.district && p.area
    ? `${p.division}, ${p.district}, ${p.area}`
    : "All Over Bangladesh";
}

function formatDate(dateString) {
  if (!dateString) return "";
  const date = new Date(dateString);
  const diffDays = Math.ceil(Math.abs(Date.now() - date) / (1000 * 60 * 60 * 24));
  if (diffDays <= 1) return "Today";
  if (diffDays <= 2) return "Yesterday";
  if (diffDays <= 7) return `${diffDays} days ago`;
  return date.toLocaleDateString("en-US", { month: "short", day: "numeric" });
}

function statusMeta(p) {
  switch (p.status) {
    case "active":
      return { label: "Active", dot: true };
    case "pending":
      return { label: "Pending" };
    case "sold":
      return { label: "Sold" };
    case "expired":
      return { label: "Expired" };
    default:
      return { label: p.status || "—" };
  }
}

function statusBadgeClass(p) {
  const base =
    "shrink-0 inline-flex items-center gap-1 px-2.5 py-0.5 rounded-full text-[11px] font-semibold ring-1 ring-inset";
  const map = {
    active: "bg-emerald-50 text-emerald-700 ring-emerald-200",
    pending: "bg-amber-50 text-amber-700 ring-amber-200",
    sold: "bg-blue-50 text-blue-700 ring-blue-200",
    expired: "bg-red-50 text-red-700 ring-red-200",
  };
  return `${base} ${map[p.status] || "bg-slate-100 text-slate-600 ring-slate-200"}`;
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
async function loadAllPosts({ refresh = false } = {}) {
  if (refresh) isRefreshing.value = true;
  else isLoading.value = true;

  try {
    let page = 1;
    let all = [];
    let hasNext = true;
    while (hasNext && page <= 50) {
      const res = await get(
        `/sale/posts/my_posts/?page=${page}&page_size=100`,
        {},
        { headers: { "Cache-Control": "no-cache", Pragma: "no-cache" } }
      );
      const d = res?.data;
      if (d && "results" in d) {
        all = all.concat(d.results);
        hasNext = !!d.next;
        page++;
      } else if (Array.isArray(d)) {
        all = all.concat(d);
        hasNext = false;
      } else {
        hasNext = false;
      }
    }
    posts.value = all;
    emit("posts-updated", { posts: all, pagination: { count: all.length } });
  } catch (error) {
    console.error("Error fetching posts:", error);
    showNotification({
      title: "Error",
      message: "Failed to load your posts. Please try again later.",
      type: "error",
    });
  } finally {
    isLoading.value = false;
    isRefreshing.value = false;
  }
}

async function refreshPosts() {
  await loadAllPosts({ refresh: true });
}

async function markAsSold(postId) {
  markingSold.value = postId;
  try {
    const target = posts.value.find((p) => p.id === postId);
    if (!target?.slug) throw new Error("Post not found");

    const response = await post(`/sale/posts/${target.slug}/mark_as_sold/`, {});
    if (response?.data) {
      const idx = posts.value.findIndex((p) => p.id === postId);
      if (idx !== -1) posts.value[idx] = { ...posts.value[idx], status: "sold" };
      emit("posts-updated", { posts: posts.value, pagination: { count: posts.value.length } });
      showNotification({
        title: "Success!",
        message: "Your post has been marked as sold.",
        type: "success",
      });
    }
  } catch (error) {
    console.error("Error marking post as sold:", error);
    let message = "Failed to mark post as sold. Please try again later.";
    if (error.response?.status === 403) message = "You don't have permission to do this.";
    else if (error.response?.status === 404) message = "This post no longer exists.";
    else if (error.response?.data?.detail) message = error.response.data.detail;
    showNotification({ title: "Error", message, type: "error" });
  } finally {
    markingSold.value = null;
  }
}

function confirmDelete(id, title) {
  postToDeleteId.value = id;
  postToDeleteTitle.value = title;
  showDeleteModal.value = true;
}

async function deletePost() {
  if (!postToDeleteId.value) return;
  isDeleting.value = true;
  try {
    const target = posts.value.find((p) => p.id === postToDeleteId.value);
    if (!target?.slug) throw new Error("Post not found");

    await del(`/sale/posts/${target.slug}/`);
    posts.value = posts.value.filter((p) => p.id !== postToDeleteId.value);
    emit("delete-post", postToDeleteId.value);
    emit("posts-updated", { posts: posts.value, pagination: { count: posts.value.length } });
    showNotification({ title: "Success", message: "Post deleted successfully!", type: "success" });
  } catch (error) {
    console.error("Error deleting post:", error);
    showNotification({
      title: "Error",
      message: "Failed to delete post. Please try again later.",
      type: "error",
    });
  } finally {
    isDeleting.value = false;
    showDeleteModal.value = false;
    postToDeleteId.value = null;
    postToDeleteTitle.value = "";
  }
}

watch(
  () => user.value?.id,
  (newId, oldId) => {
    if (newId && newId !== oldId) loadAllPosts();
  }
);

onMounted(() => {
  loadAllPosts();
});
</script>
