<template>
  <div class="p-2 flex items-center hover:bg-gray-50">
    <!-- User Avatar -->
    <div class="mr-3">
      <img
        :src="user.image || '/static/frontend/avatar.png'"
        :alt="user.first_name + ' ' + user.last_name"
        class="w-10 h-10 rounded-full object-cover"
      />
    </div>

    <!-- User Info - More compact with enhanced match highlighting -->
    <div class="flex-1">
      <!-- Display which fields matched the search query -->
      <div
        v-if="searchQuery && searchQuery.trim() !== ''"
        class="flex flex-wrap gap-1 mb-1.5"
      >
        <span
          v-for="field in detectMatchedFields(user)"
          :key="field"
          class="text-xs px-1.5 py-0.5 rounded-full"
          :class="{
            'bg-blue-100 text-blue-700 border border-blue-200':
              field === 'name',
            'bg-green-100 text-green-700 border border-green-200':
              field === 'username',
          }"
        >
          <span v-if="field === 'name'">Matched name</span>
          <span v-else-if="field === 'username'">Matched username</span>
        </span>
      </div>

      <NuxtLink :to="`/business-network/profile/${user.id}`" class="block">
        <h3
          class="font-semibold text-gray-800 hover:text-blue-600 transition-colors"
          v-html="
            highlightMatchedText(
              user.first_name && user.last_name
                ? `${user.first_name} ${user.last_name}`
                : user.username,
              'name'
            )
          "
        ></h3>
      </NuxtLink>
      <div class="flex flex-wrap items-center text-xs text-gray-500">
        <span
          v-if="user.username"
          class="mr-3"
          v-html="'- ' + highlightMatchedText(user.username, 'username')"
        ></span>
        <span class="mr-2"
          ><span class="font-medium text-gray-700">{{ user.post_count }}</span>
          Posts</span
        >
        <span
          ><span class="font-medium text-gray-700">{{
            user.follower_count
          }}</span>
          Followers</span
        >
      </div>
    </div>
  </div>
</template>

<script setup>
const props = defineProps({
  user: {
    type: Object,
    required: true,
  },
  searchQuery: {
    type: String,
    default: "",
  },
});

// Highlight matching text in username or name
const highlightMatchedText = (text, fieldType = "name") => {
  if (!text || !props.searchQuery) return text;

  let searchText = props.searchQuery;
  if (searchText.startsWith("#")) {
    searchText = searchText.substring(1);
  }

  if (searchText.length < 2) return text;

  try {
    const escapedSearchText = searchText.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
    const regex = new RegExp(`(${escapedSearchText})`, "gi");

    // Use different highlight styles based on field type
    let highlightClass = "";
    if (fieldType === "username") {
      highlightClass = "bg-green-100 text-green-800 px-0.5 rounded";
    } else {
      highlightClass = "bg-blue-100 text-blue-800 px-0.5 rounded";
    }

    return text.replace(regex, `<span class="${highlightClass}">$1</span>`);
  } catch (e) {
    console.error("Error highlighting text:", e);
    return text;
  }
};

// Detect which fields match the search query
const detectMatchedFields = (user) => {
  if (!props.searchQuery || props.searchQuery.trim() === "") return [];

  let searchText = props.searchQuery;

  // Handle hashtag searches
  if (searchText.startsWith("#")) {
    searchText = searchText.substring(1);
  }

  // Don't check if search term is too short
  if (searchText.length < 2) return [];

  const matches = [];
  try {
    const regex = new RegExp(
      searchText.replace(/[.*+?^${}()|[\]\\]/g, "\\$&"),
      "i"
    );

    // Check user's name
    const fullName =
      user.first_name && user.last_name
        ? `${user.first_name} ${user.last_name}`
        : "";
    if (fullName && regex.test(fullName)) {
      matches.push("name");
    }

    // Check username
    if (user.username && regex.test(user.username)) {
      matches.push("username");
    }

    return matches;
  } catch (e) {
    console.error("Error detecting matched fields:", e);
    return [];
  }
};
</script>
