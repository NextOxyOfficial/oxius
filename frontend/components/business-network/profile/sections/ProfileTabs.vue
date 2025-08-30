<template>
  <div
    class="bg-white/95 backdrop-blur-md rounded-xl shadow-sm border border-gray-200/50 overflow-hidden animate-fadeIn-delayed"
  >
    <!-- Scrollable Tabs for Mobile -->
    <div class="overflow-x-auto scrollbar-hide">
      <div
        class="flex items-center border-b border-gray-200 min-w-max relative"
      >
        <!-- Tab buttons with enhanced styling -->
        <button
          v-for="tab in tabs"
          :key="tab.value"
          class="px-5 py-3.5 text-sm font-medium border-b-2 transition-all duration-300 whitespace-nowrap relative overflow-hidden group"
          :class="[
            activeTab === tab.value
              ? 'text-blue-600 border-blue-600'
              : 'text-gray-600 border-transparent hover:text-gray-800 hover:border-gray-300',
          ]"
          @click="$emit('switch-tab', tab.value)"
        >
          <span class="relative z-10">{{ tab.label }}</span>

          <!-- Animated underline effect -->
          <div
            v-if="activeTab === tab.value"
            class="absolute bottom-0 left-0 h-0.5 w-full bg-gradient-to-r from-blue-500 to-indigo-500 animate-fadeIn"
          ></div>

          <!-- Tab hover effect -->
          <div
            class="absolute inset-0 bg-gradient-to-r from-blue-50 to-indigo-50 opacity-0 group-hover:opacity-100 transition-opacity -z-10"
          ></div>
        </button>
      </div>
    </div>

    <div class="py-2 px-1">
      <transition name="tab-transition" mode="out-in">
        <!-- Posts Tab Content -->
        <div v-if="activeTab === 'posts'" class="tab-content">
          <ProfilePostsTab 
            :isLoadingPosts="isLoadingPosts"
            :loadingMorePosts="loadingMorePosts"
            :posts="posts" 
            :currentUser="currentUser"
            @scroll-to-top="$emit('scroll-to-top')"
          />
        </div>

        <!-- Media Tab Content -->
        <div v-else-if="activeTab === 'media'" class="tab-content">
          <ProfileMediaTab
            :isLoadingMedia="isLoadingMedia"
            :allMedia="allMedia"
          />
        </div>

        <!-- Saved Tab Content -->
        <div v-else-if="activeTab === 'saved'" class="tab-content">
          <ProfileSavedTab
            :isLoadingSaved="isLoadingSaved"
            :savedPosts="savedPosts"
            :currentUser="currentUser"
          />
        </div>

        <!-- Workspace Tab Content -->
        <div v-else-if="activeTab === 'workspace'" class="tab-content">
          <WorkspaceTab
            :isLoadingWorkspace="isLoadingWorkspace"
            :userGigs="userGigs"
            :currentUser="currentUser"
            :profileUser="profileUser"
            @edit-gig="$emit('edit-gig', $event)"
            @toggle-gig-status="$emit('toggle-gig-status', $event)"
            @create-gig="$emit('create-gig')"
            @open-gig-details="$emit('open-gig-details', $event)"
          />
        </div>

        <!-- My Products Tab Content -->
        <div v-else-if="activeTab === 'products'" class="tab-content">
          <MyProductsTab
            :isLoadingProducts="isLoadingProducts"
            :userProducts="userProducts"
            :currentUser="currentUser"
            :profileUser="profileUser"
            @edit-product="$emit('edit-product', $event)"
            @toggle-product-status="$emit('toggle-product-status', $event)"
            @create-product="$emit('create-product')"
          />
        </div>
      </transition>
    </div>
  </div>
</template>

<script setup>
import ProfilePostsTab from './tabs/ProfilePostsTab.vue';
import ProfileMediaTab from './tabs/ProfileMediaTab.vue';
import ProfileSavedTab from './tabs/ProfileSavedTab.vue';
import WorkspaceTab from './tabs/WorkspaceTab.vue';
import MyProductsTab from './tabs/MyProductsTab.vue';

const props = defineProps({
  tabs: {
    type: Array,
    required: true
  },
  activeTab: {
    type: String,
    required: true
  },
  isLoadingPosts: {
    type: Boolean,
    default: false
  },
  isLoadingMedia: {
    type: Boolean,
    default: false
  },
  isLoadingSaved: {
    type: Boolean,
    default: false
  },
  isLoadingWorkspace: {
    type: Boolean,
    default: false
  },
  isLoadingProducts: {
    type: Boolean,
    default: false
  },
  loadingMorePosts: {
    type: Boolean,
    default: false
  },
  posts: {
    type: Object,
    default: () => ({})
  },
  allMedia: {
    type: Array,
    default: () => []
  },
  savedPosts: {
    type: Array,
    default: () => []
  },
  userGigs: {
    type: Array,
    default: () => []
  },
  userProducts: {
    type: Array,
    default: () => []
  },
  currentUser: {
    type: Object,
    default: null
  },
  profileUser: {
    type: Object,
    default: null
  }
});

// Define emits
defineEmits([
  'switch-tab',
  'scroll-to-top',
  'edit-gig',
  'toggle-gig-status', 
  'create-gig',
  'open-gig-details',
  'edit-product',
  'toggle-product-status',
  'create-product'
]);
</script>

<style scoped>
.tab-transition-enter-active,
.tab-transition-leave-active {
  transition: opacity 0.3s, transform 0.3s;
}
.tab-transition-enter-from,
.tab-transition-leave-to {
  opacity: 0;
  transform: translateY(10px);
}
</style>
