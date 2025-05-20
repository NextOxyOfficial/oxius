<template>
  <div class="bg-white rounded-xl border border-gray-100 shadow-sm hover:shadow-md transition-shadow p-4 flex flex-col">
    <div class="flex items-start space-x-4">
      <!-- User Avatar -->
      <div class="relative">
        <img 
          v-if="user.profile_image" 
          :src="user.profile_image" 
          :alt="user.first_name + ' ' + user.last_name" 
          class="w-16 h-16 rounded-full object-cover border-2 border-blue-100"
        />
        <div v-else class="w-16 h-16 rounded-full bg-blue-100 flex items-center justify-center border-2 border-blue-50">
          <span class="text-blue-500 font-medium text-xl">{{ user.first_name ? user.first_name.charAt(0).toUpperCase() : user.username.charAt(0).toUpperCase() }}</span>
        </div>
      </div>

      <!-- User Info -->
      <div class="flex-1">
        <div class="flex justify-between items-start">
          <div>
            <h3 class="font-medium text-gray-800">
              {{ user.first_name && user.last_name ? `${user.first_name} ${user.last_name}` : user.username }}
            </h3>
            <p v-if="user.username" class="text-sm text-gray-500">@{{ user.username }}</p>
          </div>
          <NuxtLink 
            :to="`/business-network/profile/${user.id}`" 
            class="text-sm bg-blue-50 hover:bg-blue-100 text-blue-600 px-3 py-1 rounded-full transition-colors"
          >
            View Profile
          </NuxtLink>
        </div>

        <!-- User bio/description (if available) -->
        <p v-if="user.bio" class="text-sm text-gray-600 mt-2 line-clamp-2">{{ user.bio }}</p>

        <!-- Stats section -->
        <div class="flex space-x-4 mt-3">
          <div class="text-xs text-gray-500">
            <span class="font-medium text-gray-700">{{ user.post_count }}</span> Posts
          </div>
          <div class="text-xs text-gray-500">
            <span class="font-medium text-gray-700">{{ user.follower_count }}</span> Followers
          </div>
          <div class="text-xs text-gray-500">
            <span class="font-medium text-gray-700">{{ user.follow_count }}</span> Following
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
defineProps({
  user: {
    type: Object,
    required: true
  }
})
</script>
