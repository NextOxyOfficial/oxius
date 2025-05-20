<template>
  <div class="p-2 flex items-center hover:bg-gray-50">
    <!-- User Avatar -->
    <div class="mr-3">
      <img 
        v-if="user.profile_image" 
        :src="user.profile_image" 
        :alt="user.first_name + ' ' + user.last_name" 
        class="w-10 h-10 rounded-full object-cover"
      />
      <div v-else class="w-10 h-10 rounded-full bg-blue-50 flex items-center justify-center">
        <span class="text-blue-600 font-semibold">{{ user.first_name ? user.first_name.charAt(0).toUpperCase() : user.username.charAt(0).toUpperCase() }}</span>
      </div>
    </div>

    <!-- User Info - More compact -->
    <div class="flex-1">      <NuxtLink :to="`/business-network/profile/${user.id}`" class="block">
        <h3 class="font-semibold text-gray-800 hover:text-blue-600 transition-colors" v-html="highlightMatchedText(user.first_name && user.last_name ? `${user.first_name} ${user.last_name}` : user.username)">
        </h3>
      </NuxtLink>
      <div class="flex flex-wrap items-center text-xs text-gray-500">
        <span v-if="user.username" class="mr-3" v-html="'@' + highlightMatchedText(user.username)"></span>
        <span class="mr-2"><span class="font-medium text-gray-700">{{ user.post_count }}</span> Posts</span>
        <span><span class="font-medium text-gray-700">{{ user.follower_count }}</span> Followers</span>
      </div>
    </div>
  </div>
</template>

<script setup>
const props = defineProps({
  user: {
    type: Object,
    required: true
  },
  searchQuery: {
    type: String,
    default: ""
  }
})

// Highlight matching text in username or name
const highlightMatchedText = (text) => {
  if (!text || !props.searchQuery) return text;
  
  let searchText = props.searchQuery;
  if (searchText.startsWith('#')) {
    searchText = searchText.substring(1);
  }
  
  if (searchText.length < 2) return text;
  
  try {
    const escapedSearchText = searchText.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
    const regex = new RegExp(`(${escapedSearchText})`, 'gi');
    return text.replace(regex, '<span class="bg-blue-100 text-blue-800 px-0.5 rounded">$1</span>');
  } catch (e) {
    return text;
  }
}
</script>
