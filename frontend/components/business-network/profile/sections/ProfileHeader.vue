<template>
  <div
    class="bg-white/95 backdrop-blur-md rounded-xl shadow-sm border border-gray-200/50 mb-6 animate-fadeIn overflow-hidden relative"
  >
    <!-- Background gradient pattern for added premium feel -->
    <div
      class="absolute inset-0 bg-gradient-to-br from-blue-50/30 to-indigo-50/30 pointer-events-none"
    ></div>
    <div class="absolute inset-0 opacity-5 bg-pattern"></div>

    <div class="p-2 py-5 sm:p-4 relative">
      <!-- Mobile Profile Header (Mobile Only) -->
      <div class="flex sm:hidden justify-between mb-4">
        <div>
          <h1 class="text-xl font-semibold flex items-center gap-1">
            {{ user?.name }}
            <div class="relative inline-flex tooltip-container">
              <UIcon
                v-if="user?.kyc"
                name="i-mdi-check-decagram"
                class="w-4 h-4 text-blue-600 animate-pulse-subtle"
              />
            </div>
            <!-- Pro badge for mobile -->
            <div class="inline-flex" v-if="user?.is_pro">
              <span
                class="px-1.5 py-0.5 bg-gradient-to-r from-indigo-600 to-blue-600 text-white rounded-full text-xs font-medium shadow-sm"
              >
                <div class="flex items-center gap-1">
                  <UIcon name="i-heroicons-shield-check" class="size-3" />
                  <span class="text-2xs">Pro</span>
                </div>
              </span>
            </div>
            <span
              v-if="user?.is_topcontributor"
              class="px-1.5 py-0.5 bg-gradient-to-r from-amber-500 to-yellow-500 text-white rounded-full text-xs font-medium shadow-sm"
            >
              <div class="flex items-center gap-1">
                <Trophy class="size-3" />
                <span class="text-2xs">Top Contributor</span>
              </div>
            </span>
          </h1>
          <p class="text-sm font-medium text-gray-600 mb-0.5">
            {{ user?.profession }}
          </p>
        </div>

        <!-- Mobile Action Buttons -->
        <div class="flex gap-2">              
          <!-- QR Code Button for mobile with enhanced styling -->
          <button
            @click="$emit('open-qr-modal')"
            class="p-1.5 size-9 rounded-full text-xs font-medium flex items-center justify-center gap-1.5 border border-gray-200 bg-white text-gray-700 hover:bg-gray-50 transition-all shadow-sm relative overflow-hidden group"
            title="View QR Code"
          >
            <span class="absolute inset-0 bg-gradient-to-r from-blue-50 to-indigo-50 opacity-0 group-hover:opacity-100 transition-opacity"></span>
            <UIcon name="i-mdi:qrcode" class="size-5 relative z-10" />
          </button>
          
          <!-- Action buttons for mobile -->              
          <button
            v-if="user?.id !== currentUser?.user?.id && currentUser"
            :class="[
              'px-3 py-1.5 rounded-full text-xs font-medium flex items-center gap-1.5 transition-all duration-300 relative overflow-hidden group/follow min-w-[90px] text-center',
              isFollowing
                ? 'border border-gray-200 hover:bg-gray-50 hover:shadow-sm text-gray-800'
                : 'bg-gradient-to-r from-blue-500 via-indigo-500 to-blue-600 text-white'
            ]"
            :disabled="followLoading"
            @click="$emit('toggle-follow')"
          >
            <span class="relative z-10 flex items-center justify-center gap-1.5">
              <div
                v-if="followLoading"
                class="h-3 w-3 border-2 border-t-transparent border-white rounded-full animate-spin"
              ></div>

              <template v-else-if="isFollowing">
                <Check class="h-3 w-3 animate-scaleIn" />
                Following
              </template>

              <template v-else>
                <UserPlus class="h-3 w-3 animate-scaleIn" />
                Follow
              </template>
            </span>
            <span 
              class="absolute inset-0 bg-gradient-to-r from-indigo-600 via-blue-600 to-indigo-700 opacity-0 group-hover/follow:opacity-100 transition-opacity duration-300"
              v-if="!isFollowing"
            ></span>
          </button>
        </div>
      </div>

      <div class="flex flex-col sm:flex-row sm:items-start gap-1 sm:gap-7">
        <!-- Profile Picture and Mobile Stats -->
        <div class="flex flex-col items-center sm:items-start">
          <div class="relative group">
            <div class="relative">
              <!-- Professional border for profile picture -->
              <div
                class="absolute inset-0 rounded-full bg-gradient-to-r from-blue-300 to-indigo-400 p-1 -m-1"
              ></div>
              <!-- Profile image container -->
              <div
                class="size-44 rounded-full overflow-hidden border-4 border-white shadow-sm bg-white relative cursor-pointer"
                @click="$emit('open-profile-photo-modal')"
              >
                <img
                  :src="user?.image || '/static/frontend/images/placeholder.jpg'"
                  :alt="user?.name"
                  class="w-full h-full object-cover transition-all duration-500 group-hover:scale-105"
                  loading="lazy"
                />
                <!-- Change profile picture button - only visible for own profile -->
                <div
                  v-if="user?.id === currentUser?.user?.id"
                  class="absolute bottom-0 left-1/2 transform -translate-x-1/2 z-50"
                >
                  <button
                    @click.stop="$emit('toggle-profile-photo-menu')"
                    class="rounded-full shadow-sm hover:shadow-sm transition-all duration-300"
                  >
                    <UIcon
                      name="i-heroicons-camera"
                      class="size-5 text-blue-600"
                    />
                  </button>
                  <!-- Profile Photo Menu -->
                  <div
                    v-if="showProfilePhotoMenu"
                    class="absolute bottom-12 left-1/2 transform -translate-x-1/2 bg-white rounded-md shadow-sm p-2 w-40 border border-gray-200 z-50 profile-photo-menu"
                  >
                    <NuxtLink
                      to="/settings"
                      class="flex items-center gap-2 p-2 text-gray-800 hover:bg-blue-50 rounded-md transition-colors"
                    >
                      <UIcon
                        name="i-heroicons-pencil-square"
                        class="size-4"
                      />
                      <span class="text-sm">Change Photo</span>
                    </NuxtLink>
                    <button
                      @click.stop="$emit('open-profile-photo-modal')"
                      class="flex items-center gap-2 p-2 text-gray-800 hover:bg-blue-50 rounded-md transition-colors w-full text-left"
                    >
                      <UIcon name="i-heroicons-eye" class="size-4" />
                      <span class="text-sm">View Photo</span>
                    </button>
                  </div>
                </div>
              </div>
            </div>
          </div>

          <!-- User Stats for Mobile -->              
          <div class="flex w-full justify-center sm:hidden mt-4 space-x-6">
            <div
              class="text-center hover:scale-105 transition-transform cursor-pointer"
            >
              <p class="font-semibold">{{ user?.post_count || 0 }}</p>
              <p class="text-sm text-gray-600">Posts</p>
            </div>
            <div
              @click="$emit('open-followers-modal', 'followers')"
              class="text-center hover:scale-105 transition-transform cursor-pointer"
            >
              <p class="font-semibold">{{ user?.followers_count || 0 }}</p>
              <p class="text-sm text-gray-600">Followers</p>
            </div>
            <div
              @click="$emit('open-followers-modal', 'following')"
              class="text-center hover:scale-105 transition-transform cursor-pointer"
            >
              <p class="font-semibold">{{ user?.following_count || 0 }}</p>
              <p class="text-sm text-gray-600">Following</p>
            </div>
          </div>

          <!-- Diamond count and top-up button for mobile -->
          <div
            v-if="currentUser?.user?.id === user?.id"
            class="flex items-center gap-3 mt-4 sm:hidden"
          >
            <div class="flex items-center space-x-2 py-1.5">
              <UIcon name="i-mdi-diamond" class="text-pink-500 w-4 h-4" />
              <span class="font-semibold text-md">{{ user?.diamond_balance }} Diamonds</span>
            </div>
            <button
              @click="$emit('show-diamond-modal')"
              class="text-xs bg-gradient-to-r from-pink-500 to-purple-500 text-white rounded-full px-4 py-1.5 hover:from-pink-600 hover:to-purple-600 flex items-center gap-1.5 transition-all shadow-sm hover:shadow"
            >
              <UIcon name="i-heroicons-plus" class="w-3 h-3" />
              <span>Top Up</span>
            </button>
          </div>
        </div>

        <ProfileInfo 
          :user="user" 
          :currentUser="currentUser" 
          :isFollowing="isFollowing"
          :followLoading="followLoading"
          @open-followers-modal="$emit('open-followers-modal', $event)"
          @open-qr-modal="$emit('open-qr-modal')"
          @toggle-follow="$emit('toggle-follow')"
          @show-diamond-modal="$emit('show-diamond-modal')"
          @format-time-ago="$emit('format-time-ago', $event)"
        />
      </div>
    </div>
  </div>
</template>

<script setup>
import { Trophy, Check, UserPlus } from "lucide-vue-next";
import ProfileInfo from './ProfileInfo.vue';

const props = defineProps({
  user: {
    type: Object,
    required: true
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
  }
});

const emit = defineEmits([
  'open-qr-modal',
  'toggle-follow',
  'open-profile-photo-modal',
  'toggle-profile-photo-menu',
  'open-followers-modal',
  'show-diamond-modal',
  'format-time-ago'
]);
</script>
