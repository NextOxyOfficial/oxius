<template>
  <div class="mx-auto px-1 sm:px-6 lg:px-8 max-w-7xl mt-16 flex-1">
    <!-- Add the event listener here -->
    <BusinessNetworkPost :posts="posts" :id="user?.user?.id" />

    <!-- Add the create post component with event listener -->
    <BusinessNetworkCreatePost @post-created="handleNewPost" />

    <!-- Search Overlay -->
    <Teleport to="body">
      <div
        v-if="isSearchOpen"
        class="fixed inset-0 bg-black/50 z-[9999] flex items-center justify-center p-4"
        @click="isSearchOpen = false"
      >
        <div
          class="bg-white rounded-lg w-full max-w-2xl max-h-[90vh] overflow-hidden"
          @click.stop
        >
          <div class="p-4 border-b border-gray-200 sticky top-0 bg-white">
            <div class="flex items-center gap-3">
              <div class="relative flex-1">
                <div
                  class="absolute inset-y-0 left-3 flex items-center pointer-events-none"
                >
                  <Search class="h-5 w-5 text-gray-400" />
                </div>
                <input
                  ref="searchInputRef"
                  type="text"
                  placeholder="Search business network..."
                  class="w-full pl-10 pr-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-600 focus:border-transparent"
                  v-model="searchQuery"
                />
              </div>
              <button
                class="p-2 rounded-full hover:bg-gray-100"
                @click="isSearchOpen = false"
              >
                <X class="h-5 w-5" />
              </button>
            </div>
          </div>

          <div class="p-3 border-b border-gray-200">
            <h3 class="text-sm font-medium text-gray-500 mb-2">
              Filter by Category
            </h3>
            <div class="flex flex-wrap gap-2">
              <button
                v-for="category in availableCategories"
                :key="category"
                class="text-xs px-3 py-1 rounded-full transition-colors"
                :class="
                  selectedCategories.includes(category)
                    ? 'bg-blue-600 text-white'
                    : 'bg-gray-100 text-gray-800 hover:bg-gray-200'
                "
                @click="toggleCategory(category)"
              >
                {{ category }}
              </button>
            </div>
          </div>

          <div class="overflow-y-auto max-h-[calc(90vh-142px)]">
            <div v-if="searchResults.length > 0" class="p-4">
              <ul class="space-y-3">
                <li v-for="(result, index) in searchResults" :key="index">
                  <button
                    class="flex items-center gap-3 w-full p-3 hover:bg-gray-50 rounded-lg transition-colors"
                    @click="handleSearch(result)"
                  >
                    <div class="bg-gray-100 rounded-full p-2">
                      <Search class="h-4 w-4 text-gray-500" />
                    </div>
                    <span class="text-gray-800">{{ result }}</span>
                  </button>
                </li>
                <li>
                  <button
                    class="flex items-center justify-between w-full p-3 bg-gray-50 hover:bg-gray-100 rounded-lg transition-colors mt-2"
                    @click="handleSeeAllResults"
                  >
                    <span class="font-medium text-blue-600">
                      {{
                        selectedCategories.length > 0
                          ? `Search "${searchQuery}" in ${selectedCategories.length} categories`
                          : `See all results for "${searchQuery}"`
                      }}
                    </span>
                    <ArrowRight class="h-4 w-4 text-blue-600" />
                  </button>
                </li>
              </ul>
            </div>

            <div v-if="searchQuery.length === 0" class="p-4">
              <h3 class="text-sm font-medium text-gray-500 mb-2">
                Recent Searches
              </h3>
              <ul class="space-y-3">
                <li v-for="(term, index) in recentSearches" :key="index">
                  <button
                    class="flex items-center gap-3 w-full p-3 hover:bg-gray-50 rounded-lg transition-colors"
                    @click="handleSearch(term)"
                  >
                    <div class="bg-gray-100 rounded-full p-2">
                      <Clock class="h-4 w-4 text-gray-500" />
                    </div>
                    <span class="text-gray-800">{{ term }}</span>
                  </button>
                </li>
              </ul>
            </div>
          </div>
        </div>
      </div>
    </Teleport>
  </div>
</template>

<script setup>
definePageMeta({
  layout: "adsy-business-network",
});

import {
  Search,
  X,
  Clock,
  ArrowRight,
  Heart,
  MessageCircle,
  Share2,
  Bookmark,
  Check,
  UserPlus,
  MoreHorizontal,
  Link2,
  Flag,
  Send,
  Plus,
  Home,
  Bell,
  User,
  BarChart2,
  Download,
  ChevronLeft,
  ChevronRight,
  Loader2,
  ImageIcon,
  Smile,
  Paperclip,
  Tag,
  UserX,
} from "lucide-vue-next";

// State
const posts = ref([]);
const loading = ref(false);
const { get } = useApi();
const { user } = useAuth();

async function getPosts() {
  loading.value = true;
  try {
    const response = await get("/bn/posts/");
    posts.value = response.data.results;
    console.log(posts.value);
  } catch (error) {
    console.log(error);
  } finally {
    loading.value = false;
  }
}

await getPosts();

const page = ref(1);
const isSearchOpen = ref(false);
const searchQuery = ref("");
const recentSearches = ref([
  "Marketing Strategy",
  "Business Development",
  "Networking Events",
  "Leadership Training",
]);
const selectedCategories = ref([]);
const availableCategories = [
  "Marketing",
  "Finance",
  "Operations",
  "Leadership",
  "Technology",
  "HR",
  "Sales",
  "Strategy",
];
const searchInputRef = ref(null);
const activeMedia = ref(null);
const activePost = ref(null);
const activeMediaIndex = ref(0);
const mediaCommentText = ref("");
const isCreatePostOpen = ref(false);
const createPostTitle = ref("");
const createPostContent = ref("");
const createPostCategories = ref([]);
const categoryInput = ref("");
const showEmojiPicker = ref(false);
const selectedMedia = ref([]);
const fileInputRef = ref(null);
const isSubmitting = ref(false);
const activeLikesPost = ref(null);
const activeCommentsPost = ref(null);
const activeMediaLikes = ref(null);
const mediaLikedUsers = ref([]);

// Common emojis for quick access
const commonEmojis = [
  "😀",
  "😃",
  "😄",
  "😁",
  "😆",
  "😅",
  "🤣",
  "😂",
  "🙂",
  "🙃",
  "😉",
  "😊",
  "😇",
  "🥰",
  "😍",
  "🤩",
  "😘",
  "😗",
  "😚",
  "😙",
  "👍",
  "👎",
  "👏",
  "🙌",
  "🤝",
  "👊",
  "✌️",
  "🤞",
  "🤟",
  "🤘",
  "❤️",
  "🧡",
  "💛",
  "💚",
  "💙",
  "💜",
  "🖤",
  "💔",
  "❣️",
  "💕",
];

// Sample user data with full names
const users = Array.from({ length: 20 }, (_, i) => ({
  id: `user-${i + 1}`,
  fullName: [
    "Emma Johnson",
    "Liam Smith",
    "Olivia Williams",
    "Noah Brown",
    "Ava Jones",
    "Elijah Davis",
    "Sophia Miller",
    "James Wilson",
    "Charlotte Moore",
    "Benjamin Taylor",
    "Amelia Anderson",
    "Lucas Thomas",
    "Mia Jackson",
    "Mason White",
    "Harper Harris",
    "Ethan Martin",
    "Evelyn Thompson",
    "Alexander Garcia",
    "Abigail Martinez",
    "Michael Robinson",
  ][i],
  avatar: `/images/placeholder.jpg?height=40&width=40`,
  isFollowing: Math.random() > 0.5,
}));

// Generate replies for comments
const generateReplies = (commentId, count) => {
  return Array.from({ length: count }, (_, i) => {
    return {
      id: `reply-${commentId}-${i}`,
      user: users[Math.floor(Math.random() * users.length)],
      text: [
        "Thanks for your insight!",
        "I agree with your point.",
        "Let's discuss this further in our next meeting.",
        "Great observation!",
        "I've been thinking the same thing.",
        "This is exactly what we need to focus on.",
      ][Math.floor(Math.random() * 6)],
      timestamp: new Date(
        Date.now() - Math.floor(Math.random() * 86400000 * 3)
      ).toISOString(),
    };
  });
};

// Sample comments with replies
const generateComments = (postId, count) => {
  return Array.from({ length: count }, (_, i) => {
    const comment = {
      id: `comment-${postId}-${i}`,
      user: users[Math.floor(Math.random() * users.length)],
      text: [
        "Great insight! Thanks for sharing.",
        "I completely agree with your analysis.",
        "This is exactly what our team needed to hear.",
        "Looking forward to discussing this further in our next meeting.",
        "Could you elaborate more on the second point?",
        "I've been thinking about this approach as well.",
        "Have you considered the impact on our Q4 strategy?",
        "This aligns perfectly with our company vision.",
      ][Math.floor(Math.random() * 8)],
      timestamp: new Date(
        Date.now() - Math.floor(Math.random() * 86400000 * 7)
      ).toISOString(),
    };

    // Add replies to some comments
    if (Math.random() > 0.7) {
      comment.replies = generateReplies(
        comment.id,
        Math.floor(Math.random() * 3) + 1
      );
    }

    return comment;
  });
};

// Generate posts
const generatePosts = (start, count) => {
  const categories = [
    "Marketing",
    "Finance",
    "Operations",
    "Leadership",
    "Technology",
    "HR",
    "Sales",
    "Strategy",
  ];

  return Array.from({ length: count }, (_, i) => {
    const postId = start + i;
    const likeCount = Math.floor(Math.random() * 30);
    const commentCount = Math.floor(Math.random() * 15);
    const mediaCount = Math.floor(Math.random() * 14) + 1;

    // Assign 1-2 random categories to each post
    const numCategories = Math.floor(Math.random() * 2) + 1;
    const postCategories = Array.from(
      { length: numCategories },
      () => categories[Math.floor(Math.random() * categories.length)]
    ).filter((value, index, self) => self.indexOf(value) === index); // Remove duplicates

    // Generate random likes
    const likedBy = Array.from({ length: likeCount }, () => {
      const user = { ...users[Math.floor(Math.random() * users.length)] };
      user.isFollowing = Math.random() > 0.5;
      return user;
    });

    // Generate random comments
    const comments = generateComments(postId, commentCount);

    // Generate media with likes and comments
    const media = Array.from({ length: mediaCount }, (_, j) => {
      const mediaLikeCount = Math.floor(Math.random() * 20);
      const mediaCommentCount = Math.floor(Math.random() * 10);

      // Generate liked users for media
      const mediaLikedBy = Array.from({ length: mediaLikeCount }, () => {
        const user = { ...users[Math.floor(Math.random() * users.length)] };
        user.isFollowing = Math.random() > 0.5;
        return user;
      });

      return {
        id: `${postId}-${j}`,
        type: j < 12 ? "image" : "video",
        url:
          j < 12
            ? `/images/placeholder.jpg?height=300&width=400`
            : "https://example.com/video.mp4",
        thumbnail: `/images/placeholder.jpg?height=150&width=200`,
        likeCount: mediaLikeCount,
        isLiked: false,
        comments: generateComments(`${postId}-${j}`, mediaCommentCount),
        likedBy: mediaLikedBy,
      };
    }).slice(0, 14);

    return {
      id: postId,
      title: `Business Strategy Update ${postId}: ${
        [
          "Market Analysis",
          "Quarterly Report",
          "Team Building",
          "Product Launch",
          "Industry Trends",
        ][Math.floor(Math.random() * 5)]
      }`,
      author: users[Math.floor(Math.random() * users.length)],
      timestamp: new Date(Date.now() - postId * 3600000).toISOString(),
      content: [
        "Our latest market analysis shows significant growth opportunities in the APAC region. The consumer behavior data indicates a shift towards sustainable products, with a 27% increase in eco-friendly purchases over the last quarter. This trend is particularly strong among the 25-34 demographic, suggesting we should adjust our marketing strategy accordingly.",
        "The Q3 financial results exceeded expectations with a 15% revenue increase year-over-year. Our cost-cutting initiatives have resulted in a 7% reduction in operational expenses, improving our overall profit margins. The board has approved the expansion plan for the European market, with implementation scheduled to begin next month.",
        "I'm excited to share that our team building workshop last week was a tremendous success. The cross-departmental collaboration exercises resulted in three innovative product ideas that we're now exploring further. The feedback from participants was overwhelmingly positive, with 92% reporting improved communication with colleagues from other departments.",
        "We're thrilled to announce that our new product line will launch on November 15th. The marketing campaign will begin next week, focusing on digital channels and influencer partnerships. Early focus group testing shows a 85% positive response rate, significantly higher than our previous launches.",
        "The latest industry report highlights a shift towards AI-powered solutions in our sector. Our R&D team has prepared a comprehensive analysis of how we can leverage these technologies to enhance our product offerings. I've attached the full report for those interested in the technical details.",
      ][Math.floor(Math.random() * 5)],
      likeCount,
      likedBy,
      comments,
      media,
      categories: postCategories,
      isFollowing: Math.random() > 0.5,
      isLiked: false,
      isSaved: false,
      showDropdown: false,
      showFullDescription: false,
      showLikes: false,
      showComments: false,
      commentText: "",
    };
  });
};

// Load more posts
const loadMorePosts = () => {
  if (loading.value) return;

  loading.value = true;

  // Simulate API call with timeout
  setTimeout(() => {
    const newPosts = generatePosts(page.value * 25 + 1, 25);
    posts.value = [...posts.value, ...newPosts];
    page.value++;
    loading.value = false;
  }, 1000);
};

// Format time ago
const formatTimeAgo = (dateString) => {
  const date = new Date(dateString);
  const now = new Date();
  const diffInSeconds = Math.floor((now.getTime() - date.getTime()) / 1000);

  if (diffInSeconds < 60) {
    return `${diffInSeconds} ${diffInSeconds === 1 ? "second" : "seconds"} ago`;
  }

  const diffInMinutes = Math.floor(diffInSeconds / 60);
  if (diffInMinutes < 60) {
    return `${diffInMinutes} ${diffInMinutes === 1 ? "minute" : "minutes"} ago`;
  }

  const diffInHours = Math.floor(diffInMinutes / 60);
  if (diffInHours < 24) {
    return `${diffInHours} ${diffInHours === 1 ? "hour" : "hours"} ago`;
  }

  const diffInDays = Math.floor(diffInHours / 24);
  if (diffInDays < 30) {
    return `${diffInDays} ${diffInDays === 1 ? "day" : "days"} ago`;
  }

  const diffInMonths = Math.floor(diffInDays / 30);
  return `${diffInMonths} ${diffInMonths === 1 ? "month" : "months"} ago`;
};

// Toggle follow
const toggleFollow = (post) => {
  post.isFollowing = !post.isFollowing;
};

// Toggle user follow
const toggleUserFollow = (user) => {
  user.isFollowing = !user.isFollowing;
};

// Toggle like
const toggleLike = (post) => {
  post.isLiked = !post.isLiked;
  post.likeCount += post.isLiked ? 1 : -1;

  if (post.isLiked) {
    post.likedBy.unshift({
      id: "current-user",
      fullName: "You",
      avatar: "/images/placeholder.jpg?height=40&width=40",
      isFollowing: false,
    });
  } else {
    post.likedBy = post.likedBy.filter((user) => user.id !== "current-user");
  }
};

// Toggle media like
const toggleMediaLike = () => {
  if (!activeMedia.value) return;

  activeMedia.value.isLiked = !activeMedia.value.isLiked;
  activeMedia.value.likeCount += activeMedia.value.isLiked ? 1 : -1;

  // Update likedBy array for the media
  if (activeMedia.value.isLiked) {
    if (!activeMedia.value.likedBy) {
      activeMedia.value.likedBy = [];
    }
    activeMedia.value.likedBy.unshift({
      id: "current-user",
      fullName: "You",
      avatar: "/images/placeholder.jpg?height=40&width=40",
      isFollowing: false,
    });
  } else if (activeMedia.value.likedBy) {
    activeMedia.value.likedBy = activeMedia.value.likedBy.filter(
      (user) => user.id !== "current-user"
    );
  }
};

// Toggle save
const toggleSave = (post) => {
  post.isSaved = !post.isSaved;
  post.showDropdown = false;
};

// Toggle dropdown
const toggleDropdown = (post) => {
  // Close all other dropdowns first
  posts.value.forEach((p) => {
    if (p.id !== post.id) p.showDropdown = false;
  });

  post.showDropdown = !post.showDropdown;
};

// Toggle description
const toggleDescription = (post) => {
  post.showFullDescription = !post.showFullDescription;
};

// Copy link
const copyLink = (post) => {
  const postUrl = `${window.location.origin}/post/${post.id}`;
  navigator.clipboard.writeText(postUrl);
  alert("Link copied to clipboard");
  post.showDropdown = false;
};

// Share post
const sharePost = (post) => {
  const postUrl = `${window.location.origin}/post/${post.id}`;

  if (navigator.share && navigator.canShare) {
    navigator
      .share({
        title: post.title,
        text:
          post.content.substring(0, 100) +
          (post.content.length > 100 ? "..." : ""),
        url: postUrl,
      })
      .catch((error) => console.error("Error sharing:", error));
  } else {
    alert(`Share URL: ${postUrl}`);
  }
};

// Open likes modal
const openLikesModal = (post) => {
  activeLikesPost.value = post;
};

// Open comments modal
const openCommentsModal = (post) => {
  activeCommentsPost.value = post;
};

// Open media likes modal
const openMediaLikesModal = () => {
  if (!activeMedia.value || !activeMedia.value.likedBy) return;

  mediaLikedUsers.value = activeMedia.value.likedBy;
  activeMediaLikes.value = activeMedia.value;
};

// Add comment
const addComment = (post) => {
  if (!post.commentText.trim()) return;

  const newComment = {
    id: `comment-${Date.now()}`,
    user: {
      id: "current-user",
      fullName: "You",
      avatar: "/images/placeholder.jpg?height=40&width=40",
    },
    text: post.commentText,
    timestamp: new Date().toISOString(),
  };

  post.comments.unshift(newComment);
  post.commentText = "";

  if (activeCommentsPost.value === post) {
    activeCommentsPost.value = { ...post };
  }
};

// Add media comment
const addMediaComment = () => {
  if (!mediaCommentText.value.trim() || !activeMedia.value) return;

  const newComment = {
    id: `media-comment-${Date.now()}`,
    user: {
      id: "current-user",
      fullName: "You",
      avatar: "/images/placeholder.jpg?height=40&width=40",
    },
    text: mediaCommentText.value,
    timestamp: new Date().toISOString(),
  };

  if (!activeMedia.value.comments) {
    activeMedia.value.comments = [];
  }

  activeMedia.value.comments.unshift(newComment);
  mediaCommentText.value = "";
};

// Open media
const openMedia = (post, index) => {
  activePost.value = post;
  activeMediaIndex.value = index;
  activeMedia.value = post.media[index];
};

// Navigate media
const navigateMedia = (direction) => {
  if (!activePost.value || !activeMedia.value) return;

  const currentIndex = activeMediaIndex.value;
  const totalMedia = activePost.value.media.length;

  if (direction === "prev") {
    activeMediaIndex.value = (currentIndex - 1 + totalMedia) % totalMedia;
  } else {
    activeMediaIndex.value = (currentIndex + 1) % totalMedia;
  }

  activeMedia.value = activePost.value.media[activeMediaIndex.value];
};

// Search functions
const toggleCategory = (category) => {
  if (selectedCategories.value.includes(category)) {
    selectedCategories.value = selectedCategories.value.filter(
      (c) => c !== category
    );
  } else {
    selectedCategories.value.push(category);
  }
};

const handleSearch = (term) => {
  searchQuery.value = term;
  // Add to recent searches if not already there
  if (!recentSearches.value.includes(term) && term.trim() !== "") {
    recentSearches.value = [term, ...recentSearches.value.slice(0, 4)];
  }
};

const handleSeeAllResults = () => {
  if (searchQuery.value.trim()) {
    handleSearch(searchQuery.value);
    isSearchOpen.value = false;
  }
};

// Computed search results
const searchResults = computed(() => {
  if (searchQuery.value.length > 0) {
    // Simulate search results
    let mockResults = [
      `${searchQuery.value}`,
      `${searchQuery.value} trends`,
      `${searchQuery.value} examples`,
      `${searchQuery.value} best practices`,
      `${searchQuery.value} tips`,
    ];

    // If categories are selected, add them to the results
    if (selectedCategories.value.length > 0) {
      mockResults = mockResults.map(
        (result) => `${result} in ${selectedCategories.value.join(", ")}`
      );
    }

    return mockResults;
  }
  return [];
});

// Create post functions
const triggerFileInput = () => {
  fileInputRef.value?.click();
};

const handleFileChange = (e) => {
  const files = e.target.files;
  if (!files) return;

  const newFiles = Array.from(files);

  // Check file type and size constraints
  const validFiles = newFiles.filter((file) => {
    const isImage = file.type.startsWith("image/");
    const isVideo = file.type.startsWith("video/");

    if (isImage && file.size > 5 * 1024 * 1024) {
      alert(`Image ${file.name} exceeds 5MB limit`);
      return false;
    }

    if (isVideo && file.size > 250 * 1024 * 1024) {
      alert(`Video ${file.name} exceeds 250MB limit`);
      return false;
    }

    return isImage || isVideo;
  });

  // Check total media count constraints
  const currentImages = selectedMedia.value.filter((file) =>
    file.type.startsWith("image/")
  ).length;
  const currentVideos = selectedMedia.value.filter((file) =>
    file.type.startsWith("video/")
  ).length;

  const newImages = validFiles.filter((file) => file.type.startsWith("image/"));
  const newVideos = validFiles.filter((file) => file.type.startsWith("video/"));

  if (currentImages + newImages.length > 12) {
    alert("Maximum 12 images allowed");
    return;
  }

  if (currentVideos + newVideos.length > 2) {
    alert("Maximum 2 videos allowed");
    return;
  }

  selectedMedia.value = [...selectedMedia.value, ...validFiles];
};

// Add this function to handle the new post
const handleNewPost = (newPost) => {
  // Add the new post to the beginning of the posts array for immediate display
  posts.value = [newPost, ...posts.value];
};

// Initialize
onMounted(() => {
  // Implement infinite scroll
  window.addEventListener("scroll", () => {
    if (
      window.innerHeight + window.scrollY >= document.body.offsetHeight - 500 &&
      !loading.value
    ) {
      loadMorePosts();
    }
  });

  // Focus search input when overlay opens
  watch(isSearchOpen, (newVal) => {
    if (newVal) {
      nextTick(() => {
        searchInputRef.value?.focus();
      });
    }
  });
});
</script>

<style scoped>
.border-l-3 {
  border-left-width: 3px;
}

@keyframes fadeIn {
  from {
    opacity: 0;
    transform: translateY(10px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}
</style>
