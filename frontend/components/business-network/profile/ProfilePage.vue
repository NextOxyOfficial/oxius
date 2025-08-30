<template>
  <div class="max-w-3xl mx-auto relative z-10 sm:px-0">
    <!-- Profile Header Component -->
    <ProfileHeader
      :user="user"
      :currentUser="currentUser"
      :isFollowing="isFollowing"
      :followLoading="followLoading"
      :showProfilePhotoMenu="showProfilePhotoMenu"
      @open-qr-modal="$emit('open-qr-modal')"
      @toggle-follow="$emit('toggle-follow')"
      @open-profile-photo-modal="$emit('open-profile-photo-modal')"
      @toggle-profile-photo-menu="$emit('toggle-profile-photo-menu')"
      @open-followers-modal="$emit('open-followers-modal', $event)"
      @show-diamond-modal="$emit('show-diamond-modal')"
    />

    <!-- Tabs Section with ProfileTabs component -->
    <ProfileTabs 
      :tabs="tabs"
      :activeTab="activeTab"
      :isLoadingPosts="isLoadingPosts"
      :loadingMorePosts="loadingMorePosts"
      :posts="posts"
      :isLoadingMedia="isLoadingMedia"
      :allMedia="allMedia"
      :isLoadingSaved="isLoadingSaved"
      :savedPosts="savedPosts"
      :isLoadingWorkspace="isLoadingWorkspace"
      :userGigs="userGigs"
      :isLoadingProducts="isLoadingProducts"
      :userProducts="userProducts"
      :loadingMoreProducts="loadingMoreProducts"
      :hasMoreProducts="hasMoreProducts"
      :profileUser="user"
      :currentUser="currentUser"
      @switch-tab="$emit('switch-tab', $event)"
      @scroll-to-top="$emit('scroll-to-top')"
      @edit-gig="$emit('edit-gig', $event)"
      @toggle-gig-status="$emit('toggle-gig-status', $event)"
      @create-gig="$emit('create-gig')"
      @open-gig-details="$emit('open-gig-details', $event)"
      @edit-product="$emit('edit-product', $event)"
      @toggle-product-status="$emit('toggle-product-status', $event)"
      @create-product="$emit('create-product')"
      @load-more-products="$emit('load-more-products')"
    />
  </div>
</template>

<script setup>
import ProfileHeader from './sections/ProfileHeader.vue';
import ProfileTabs from './sections/ProfileTabs.vue';

// Props
const props = defineProps({
  user: {
    type: Object,
    default: () => ({})
  },
  currentUser: {
    type: Object,
    default: null
  },
  isFollowing: {
    type: Boolean,
    default: false
  },
  followLoading: {
    type: Boolean,
    default: false
  },
  showProfilePhotoMenu: {
    type: Boolean,
    default: false
  },
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
  loadingMorePosts: {
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
  isLoadingWorkspace: {
    type: Boolean,
    default: false
  },
  userGigs: {
    type: Array,
    default: () => []
  },
  isLoadingProducts: {
    type: Boolean,
    default: false
  },
  userProducts: {
    type: Array,
    default: () => []
  },
  loadingMoreProducts: {
    type: Boolean,
    default: false
  },
  hasMoreProducts: {
    type: Boolean,
    default: true
  }
});

// Define emits
defineEmits([
  'open-qr-modal',
  'toggle-follow',
  'open-profile-photo-modal',
  'toggle-profile-photo-menu',
  'open-followers-modal',
  'show-diamond-modal',
  'switch-tab',
  'scroll-to-top',
  'edit-gig',
  'toggle-gig-status',
  'create-gig',
  'open-gig-details',
  'edit-product',
  'toggle-product-status',
  'create-product',
  'load-more-products'
]);
</script>
