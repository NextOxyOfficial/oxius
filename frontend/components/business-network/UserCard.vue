<template>
  <div class="bg-white rounded-lg border border-gray-200 p-4 flex flex-col">
    <div class="flex items-start space-x-4">
      <!-- User Avatar with professional styling -->
      <div class="relative">
        <div class="w-16 h-16 rounded-full overflow-hidden border border-gray-200 bg-white shadow-sm">
          <img 
            v-if="user.profile_image" 
            :src="user.profile_image" 
            :alt="user.first_name + ' ' + user.last_name" 
            class="w-full h-full object-cover"
          />
          <div v-else class="w-full h-full bg-gradient-to-br from-blue-50 to-blue-100 flex items-center justify-center">
            <span class="text-blue-600 font-semibold text-xl">{{ user.first_name ? user.first_name.charAt(0).toUpperCase() : user.username.charAt(0).toUpperCase() }}</span>
          </div>
        </div>
      </div>

      <!-- User Info with professional layout -->
      <div class="flex-1">
        <div class="flex justify-between items-start">
          <div>
            <h3 class="font-semibold text-gray-800">
              {{ user.first_name && user.last_name ? `${user.first_name} ${user.last_name}` : user.username }}
            </h3>
            <p v-if="user.username" class="text-sm text-gray-500">@{{ user.username }}</p>
          </div>
          <NuxtLink 
            :to="`/business-network/profile/${user.id}`" 
            class="text-sm bg-white border border-blue-500 text-blue-600 px-4 py-1 rounded font-medium"
          >
            Profile
          </NuxtLink>
        </div>

        <!-- User bio with more professional styling -->
        <p v-if="user.bio" class="text-sm text-gray-600 mt-2 line-clamp-2 border-l-2 border-gray-200 pl-2">{{ user.bio }}</p>

        <!-- Stats section with more professional layout -->
        <div class="flex mt-3 pt-2 border-t border-gray-100">
          <div class="flex-1 text-center">
            <div class="text-sm font-medium text-gray-800">{{ user.post_count }}</div>
            <div class="text-xs text-gray-500">Posts</div>
          </div>
          <div class="flex-1 text-center border-x border-gray-100">
            <div class="text-sm font-medium text-gray-800">{{ user.follower_count }}</div>
            <div class="text-xs text-gray-500">Followers</div>
          </div>
          <div class="flex-1 text-center">
            <div class="text-sm font-medium text-gray-800">{{ user.follow_count }}</div>
            <div class="text-xs text-gray-500">Following</div>
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
