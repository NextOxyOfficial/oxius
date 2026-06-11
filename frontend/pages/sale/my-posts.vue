<template>
  <div>
    <!-- Sale Search Bar -->
    <SaleSearchBar
      :initial-search-term="''"
      :is-searching="false"
      @search="handleSearch"
      @clear-location="handleClearLocation"
    />

    <PublicSection>
      <UContainer class="max-w-7xl mx-auto py-4 sm:py-6">
        <!-- Header -->
        <div
          class="rounded-xl border border-slate-200 bg-gradient-to-r from-slate-50 via-white to-emerald-50/60 px-4 py-4 sm:px-5 mb-5 flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4"
        >
          <div class="flex items-center gap-3">
            <div class="flex h-10 w-10 shrink-0 items-center justify-center rounded-lg bg-emerald-50 text-emerald-600 ring-1 ring-emerald-100">
              <UIcon name="i-heroicons-clipboard-document-list" class="h-5 w-5" />
            </div>
            <div>
              <h1 class="text-base sm:text-lg font-bold text-slate-900">
                {{ t("sale_manage_title") }}
              </h1>
              <p class="text-slate-500 text-xs sm:text-sm mt-0.5">
                {{ t("sale_manage_subtitle") }}
              </p>
            </div>
          </div>
          <UButton
            color="emerald"
            variant="soft"
            class="font-medium rounded-lg px-4 py-2 shrink-0"
            @click="navigateToMarketplace"
          >
            <template #leading>
              <div
                v-if="loadingButtons.has('go-to-marketplace')"
                class="dotted-spinner emerald"
              ></div>
              <UIcon v-else name="i-heroicons-shopping-bag" class="text-lg" />
            </template>
            <span>{{ t("sale_go_marketplace") }}</span>
          </UButton>
        </div>

        <!-- Tabs: My Posts / Post a Sale -->
        <div class="flex gap-1.5 mb-4">
          <button
            v-for="tab in tabs"
            :key="tab.id"
            :class="tabBtnClass(tab.id)"
            @click="activeTab = tab.id"
          >
            <UIcon :name="tab.icon" class="w-4 h-4" />
            <span>{{ t(tab.labelKey) }}</span>
            <span
              v-if="tab.id === 'my-posts' && myPostsCount > 0"
              :class="tabBadgeClass(tab.id)"
            >
              {{ myPostsCount }}
            </span>
          </button>
        </div>

        <!-- My Posts -->
        <div v-if="activeTab === 'my-posts'">
          <MyPosts
            @create-post="activeTab = 'post-sale'"
            @edit-post="handleEditPost"
            @delete-post="handleDeletePost"
            @posts-updated="updatePostsCount"
          />
        </div>

        <!-- Post a Sale -->
        <div v-else>
          <SalePostForm @post-created="handlePostCreated" />
        </div>
      </UContainer>
    </PublicSection>
  </div>
</template>

<script setup>
import MyPosts from "~/components/sale/MyPosts.vue";
import SalePostForm from "~/components/sale/SalePostForm.vue";
import SaleSearchBar from "~/components/sale/SaleSearchBar.vue";

definePageMeta({
  middleware: "auth",
});

const { t } = useI18n();

// Loading state for buttons
const loadingButtons = ref(new Set());

const handleButtonClick = (buttonId) => {
  loadingButtons.value.add(buttonId);
  setTimeout(() => {
    loadingButtons.value.delete(buttonId);
  }, 3000);
};

// State
const activeTab = ref("my-posts");
const myPostsCount = ref(0);

const tabs = [
  { id: "my-posts", labelKey: "sale_tab_my_posts", icon: "i-heroicons-document-text" },
  { id: "post-sale", labelKey: "sale_tab_post_sale", icon: "i-heroicons-plus-circle" },
];

// Tab styling
const tabBtnClass = (id) => [
  "inline-flex items-center gap-2 px-4 py-2 rounded-lg text-sm font-medium border transition-colors",
  activeTab.value === id
    ? "bg-emerald-600 border-emerald-600 text-white"
    : "bg-white border-slate-200 text-slate-600 hover:bg-slate-50",
];

const tabBadgeClass = (id) => [
  "inline-flex items-center justify-center min-w-[20px] h-[18px] px-1 rounded-full text-[11px] font-semibold",
  activeTab.value === id ? "bg-white/25 text-white" : "bg-emerald-100 text-emerald-700",
];

// Initial tab from URL
const route = useRoute();
if (route.query.tab) {
  const tabExists = tabs.find((tab) => tab.id === route.query.tab);
  if (tabExists) activeTab.value = route.query.tab;
}

watch(
  () => route.path,
  () => loadingButtons.value.clear()
);

// Methods
const handleEditPost = (post) => {
  navigateTo(`/sale/edit/${post.slug}`);
};

const handleDeletePost = () => {
  // Count is refreshed via posts-updated
};

const handlePostCreated = () => {
  activeTab.value = "my-posts";
  const toast = useToast();
  toast.add({
    title: t("sale_post_success_title"),
    description: t("sale_post_success_desc"),
    color: "green",
  });
};

const updatePostsCount = (data) => {
  if (data?.posts) {
    myPostsCount.value = data.pagination?.count ?? data.posts.length;
  }
};

const navigateToMarketplace = () => {
  handleButtonClick("go-to-marketplace");
  navigateTo("/sale");
};

const handleSearch = (searchTerm) => {
  navigateTo(`/sale?search=${encodeURIComponent(searchTerm)}`);
};

const handleClearLocation = () => {
  window.location.reload();
};

// Keep URL in sync with active tab
watch(activeTab, (newTab) => {
  useRouter().push({ query: { tab: newTab } });
});

// SEO
useHead({
  title: "My Sale Posts - Manage Your Listings",
  meta: [
    {
      name: "description",
      content:
        "Manage your sale listings, post new items, and track your selling activity.",
    },
  ],
});
</script>

<style scoped>
/* Dotted spinner for the marketplace button */
.dotted-spinner {
  width: 1rem;
  height: 1rem;
  border: 2px dotted #059669;
  border-radius: 50%;
  animation: spin 1s linear infinite;
  flex-shrink: 0;
}

@keyframes spin {
  from {
    transform: rotate(0deg);
  }
  to {
    transform: rotate(360deg);
  }
}
</style>
