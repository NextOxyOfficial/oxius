<template>
  <div class="relative search-button-container">
    <button
      class="flex items-center justify-center h-9 w-9 rounded-full hover:bg-gray-100 dark:hover:bg-gray-800 transition-colors group"
      @click="toggleSearchDropdown"
      aria-label="Search"
    >
      <SearchIcon
        class="h-[18px] w-[18px] text-gray-500 dark:text-gray-400 group-hover:text-blue-600 dark:group-hover:text-blue-400 transition-colors"
      />
    </button>

    <!-- Enhanced Search Dropdown with Improved Animation -->
    <Transition
      enter-active-class="transition-all duration-300 ease-out"
      enter-from-class="opacity-0 scale-95 -translate-y-2"
      enter-to-class="opacity-100 scale-100 translate-y-0"
      leave-active-class="transition-all duration-200 ease-in"
      leave-from-class="opacity-100 scale-100 translate-y-0"
      leave-to-class="opacity-0 scale-95 -translate-y-2"
    >
      <div
        v-if="showSearchDropdown"
        class="absolute top-full right-0 mt-2 w-72 sm:w-96 bg-white dark:bg-gray-800 rounded-xl shadow-professional border border-gray-200 dark:border-gray-700 overflow-hidden z-50 search-dropdown-container"
        role="dialog"
        aria-modal="true"
        aria-label="Search dialog"
      >
        <!-- Enhanced Search Header with Spelling Suggestion -->
        <div
          class="p-3 bg-gray-50 dark:bg-gray-800/80 border-b border-gray-200 dark:border-gray-700 backdrop-blur-sm"
        >
          <h4
            class="text-xs uppercase tracking-wider text-gray-500 dark:text-gray-500 font-medium mb-2 px-1"
          >
            Search
          </h4>
          <div class="relative">
            <input
              type="text"
              placeholder="Type to search..."
              v-model="searchQuery"
              class="w-full pl-10 pr-10 py-2.5 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-blue-500/50 dark:focus:ring-blue-500/70 border border-gray-200 dark:border-gray-700 bg-white dark:bg-gray-900 text-gray-700 dark:text-gray-300 transition-all duration-300 shadow-sm search-input"
              ref="searchInput"
            />
            <div
              class="absolute left-3 top-2.5 text-gray-500 dark:text-gray-500"
            >
              <SearchIcon class="h-4.5 w-4.5" />
            </div>

            <div class="absolute right-3 top-2.5 flex items-center gap-2">
              <span v-if="isLoading" class="loading-spinner"></span>
              <button
                v-if="searchQuery"
                @click="clearSearch"
                class="rounded-full hover:bg-gray-200 dark:hover:bg-gray-700 p-1 transition-colors"
              >
                <XIcon class="h-3.5 w-3.5 text-gray-500 dark:text-gray-500" />
              </button>
            </div>
          </div>

          <!-- Spelling suggestion banner -->
          <div v-if="spellingSuggestion && searchQuery" class="mt-2 px-1">
            <button
              @click="applySpellingSuggestion"
              class="text-xs flex items-center text-left w-full rounded-md bg-blue-50 dark:bg-blue-900/20 border border-blue-100 dark:border-blue-800/30 px-2.5 py-1.5 text-blue-700 dark:text-blue-300 hover:bg-blue-100 dark:hover:bg-blue-900/30 transition-colors"
            >
              <span class="mr-1.5">
                <AnnotationIcon class="h-3.5 w-3.5" />
              </span>
              <span>
                Did you mean:
                <span class="font-medium underline">{{
                  spellingSuggestion
                }}</span
                >?
              </span>
            </button>
          </div>
        </div>

        <!-- Search Tabs for Content Types -->
        <div
          v-if="searchQuery && (posts.length > 0 || people.length > 0)"
          class="flex border-b border-gray-200 dark:border-gray-700 bg-white dark:bg-gray-800"
        >
          <button
            class="flex-1 py-2 text-base font-medium transition-colors"
            :class="
              activeTab === 'all'
                ? 'text-blue-600 dark:text-blue-400 border-b-2 border-blue-600 dark:border-blue-400'
                : 'text-gray-500 dark:text-gray-500 hover:text-gray-700 dark:hover:text-gray-300'
            "
            @click="activeTab = 'all'"
          >
            All
          </button>

          <button
            class="flex-1 py-2 text-base font-medium transition-colors"
            :class="
              activeTab === 'posts'
                ? 'text-blue-600 dark:text-blue-400 border-b-2 border-blue-600 dark:border-blue-400'
                : 'text-gray-500 dark:text-gray-500 hover:text-gray-700 dark:hover:text-gray-300'
            "
            @click="activeTab = 'posts'"
          >
            Posts
            <span
              v-if="posts.length"
              class="ml-1 text-xs bg-gray-100 dark:bg-gray-700 px-1.5 py-0.5 rounded-full"
            >
              {{ posts.length }}
            </span>
          </button>

          <button
            class="flex-1 py-2 text-base font-medium transition-colors"
            :class="
              activeTab === 'people'
                ? 'text-blue-600 dark:text-blue-400 border-b-2 border-blue-600 dark:border-blue-400'
                : 'text-gray-500 dark:text-gray-500 hover:text-gray-700 dark:hover:text-gray-300'
            "
            @click="activeTab = 'people'"
          >
            People
            <span
              v-if="people.length"
              class="ml-1 text-xs bg-gray-100 dark:bg-gray-700 px-1.5 py-0.5 rounded-full"
            >
              {{ people.length }}
            </span>
          </button>
        </div>

        <!-- Enhanced Search Results with Improved Rendering and Keyword Highlighting -->
        <div
          v-if="searchQuery && filteredResults.length > 0"
          class="max-h-80 overflow-y-auto search-results-container"
        >
          <div class="py-2 px-1">
            <p class="text-xs text-gray-500 dark:text-gray-500 mb-1.5 px-3">
              Results for "<span
                class="font-medium text-blue-600 dark:text-blue-400"
                >{{ searchQuery }}</span
              >"
              <span
                v-if="usingFuzzySearch"
                class="text-xs ml-1 text-gray-500 dark:text-gray-500"
                >(including similar words)</span
              >
            </p>

            <!-- Posts section -->
            <template v-if="showPosts">
              <div
                v-if="filteredPosts.length > 0 && activeTab === 'all'"
                class="px-3 pt-1 pb-2"
              >
                <h4
                  class="text-xs uppercase tracking-wider text-gray-500 dark:text-gray-500 font-medium"
                >
                  Posts ({{ filteredPosts.length }})
                </h4>
              </div>

              <div
                v-for="(result, index) in limitedFilteredPosts"
                :key="'post-' + result.id"
                class="p-3 hover:bg-gray-50 dark:hover:bg-gray-700/50 cursor-pointer transition-colors duration-150 rounded-lg mx-1 mb-0.5 group"
                @click="navigateToPost(result)"
                :class="{
                  'border-b border-gray-100 dark:border-gray-800':
                    index < limitedFilteredPosts.length - 1,
                }"
              >
                <!-- Post content -->
                <div class="flex items-start justify-between">
                  <div class="flex-1 min-w-0">
                    <!-- Highlighted title with keyword matches -->
                    <p
                      class="text-sm font-medium text-gray-700 dark:text-gray-200 group-hover:text-blue-600 dark:group-hover:text-blue-400 transition-colors line-clamp-2"
                    >
                      <span
                        v-html="highlightMatches(result.title, searchQuery)"
                      ></span>
                    </p>

                    <!-- Content preview with highlighted matches (if available) -->
                    <p
                      v-if="result.post_text"
                      class="text-xs text-gray-500 dark:text-gray-500 mt-1 line-clamp-2"
                    >
                      <span
                        v-html="
                          getContentPreview(result.post_text, searchQuery)
                        "
                      ></span>
                    </p>

                    <div class="flex flex-wrap gap-1 mt-1.5">
                      <span
                        v-for="tag in result.post_tags"
                        :key="tag.id"
                        class="inline-flex items-center px-2 py-0.5 rounded-full text-xs font-medium"
                        :class="
                          isTagMatched(tag.tag, searchQuery)
                            ? 'bg-blue-100 dark:bg-blue-900/50 text-blue-700 dark:text-blue-300'
                            : 'bg-gray-100 dark:bg-gray-800/80 text-gray-500 dark:text-gray-500'
                        "
                      >
                        #<span
                          v-html="highlightMatches(tag.tag, searchQuery)"
                        ></span>
                      </span>
                    </div>
                  </div>

                  <div class="flex-shrink-0 ml-3">
                    <div
                      class="h-6 w-6 rounded-full bg-gray-100 dark:bg-gray-700 flex items-center justify-center group-hover:bg-blue-100 dark:group-hover:bg-blue-800/30 transition-colors"
                    >
                      <ArrowRight
                        class="h-3.5 w-3.5 text-gray-500 dark:text-gray-500 group-hover:text-blue-600 dark:group-hover:text-blue-400 transition-colors"
                      />
                    </div>
                  </div>
                </div>
              </div>
            </template>

            <!-- People section -->
            <template v-if="showPeople">
              <div
                v-if="filteredPeople.length > 0 && activeTab === 'all'"
                class="px-3 pt-3 pb-2"
              >
                <h4
                  class="text-xs uppercase tracking-wider text-gray-500 dark:text-gray-500 font-medium"
                >
                  People ({{ filteredPeople.length }})
                </h4>
              </div>

              <div
                v-for="(person, index) in limitedFilteredPeople"
                :key="'person-' + (person.id || index)"
                class="p-3 hover:bg-gray-50 dark:hover:bg-gray-700/50 cursor-pointer transition-colors duration-150 rounded-lg mx-1 mb-0.5 group"
                @click="navigateToProfile(person)"
                :class="{
                  'border-b border-gray-100 dark:border-gray-800':
                    index < limitedFilteredPeople.length - 1,
                }"
              >
                <!-- Person card with avatar and details -->
                <div class="flex items-center">
                  <!-- Avatar with fallback -->
                  <div class="flex-shrink-0 relative">
                    <img
                      :src="person.image || '/static/frontend/avatar.png'"
                      :alt="person.name || 'User'"
                      class="h-10 w-10 rounded-full object-cover border border-gray-200 dark:border-gray-700"
                    />
                  </div>

                  <!-- User info with more detailed display -->
                  <div class="ml-3 flex-1 min-w-0">
                    <p
                      class="text-sm font-medium text-gray-700 dark:text-gray-200 group-hover:text-blue-600 dark:group-hover:text-blue-400 transition-colors"
                    >
                      <span
                        v-html="
                          highlightMatches(
                            person.name || 'Unknown User',
                            searchQuery
                          )
                        "
                      ></span>
                    </p>
                    <div
                      class="flex flex-wrap items-center text-xs text-gray-500 dark:text-gray-500"
                    >
                      <span v-if="person.followers !== undefined">
                        {{ person.followers }}
                        {{ person.followers === 1 ? "follower" : "followers" }}
                      </span>
                      <span v-if="person.title" class="flex items-center">
                        <span class="mx-1.5">•</span>
                        <span
                          class="truncate"
                          v-html="highlightMatches(person.title, searchQuery)"
                        ></span>
                      </span>
                    </div>
                  </div>

                  <!-- Action button -->
                  <div
                    class="flex-shrink-0"
                    v-if="person?.id !== user?.user?.id && user"
                    :ref="(el) => registerObserver(el, person.id)"
                  >
                    <div
                      class="h-6 w-6 rounded-full bg-gray-100 dark:bg-gray-700 flex items-center justify-center group-hover:bg-blue-100 dark:group-hover:bg-blue-800/30 transition-colors"
                      @click="toggleFollow(person.id)"
                    >
                      <UserPlus
                        v-if="!followingStatus[person.id]"
                        class="h-3.5 w-3.5 text-gray-500 dark:text-gray-500 group-hover:text-blue-600 dark:group-hover:text-blue-400 transition-colors"
                      />
                      <User
                        v-else
                        class="h-3.5 w-3.5 text-gray-500 dark:text-gray-500 group-hover:text-blue-600 dark:group-hover:text-blue-400 transition-colors"
                      />
                    </div>
                  </div>
                </div>
              </div>
            </template>
          </div>

          <div
            class="flex justify-center p-3 border-t border-gray-100 dark:border-gray-800 bg-gray-50/50 dark:bg-gray-800/50"
          >
            <button
              @click="viewAllResults"
              class="inline-flex items-center justify-center gap-1.5 py-2 px-4 text-base font-medium text-blue-600 dark:text-blue-400 hover:text-blue-700 dark:hover:text-blue-300 rounded-md hover:bg-blue-50 dark:hover:bg-blue-900/20 transition-colors w-full"
            >
              View all results
              <ArrowRight class="h-3 w-3" />
            </button>
          </div>
        </div>

        <!-- Enhanced No Results Message -->
        <div
          v-if="searchQuery && !isLoading && filteredResults.length === 0"
          class="p-6 text-center"
        >
          <div
            class="w-12 h-12 rounded-full bg-gray-100 dark:bg-gray-800 mx-auto mb-3 flex items-center justify-center"
          >
            <SearchOffIcon class="h-6 w-6 text-gray-500 dark:text-gray-500" />
          </div>
          <p class="text-sm font-medium text-gray-700 dark:text-gray-400 mb-1">
            No results found
          </p>
          <p class="text-xs text-gray-500 dark:text-gray-500 mb-3">
            We couldn't find anything for "{{ searchQuery }}"
          </p>
          <div
            class="text-xs text-gray-500 dark:text-gray-500 bg-gray-50 dark:bg-gray-800/80 rounded-lg p-3 max-w-xs mx-auto border border-gray-100 dark:border-gray-700"
          >
            <p class="font-medium mb-1">Suggestions:</p>
            <ul
              class="text-gray-500 dark:text-gray-500 text-left space-y-1 pl-4 list-disc"
            >
              <li>Try different keywords</li>
              <li>Check for typos</li>
              <li>Use more general terms</li>
            </ul>
          </div>
        </div>

        <!-- Enhanced Empty State -->
        <div v-if="!searchQuery" class="p-6 text-center">
          <div
            class="w-16 h-16 rounded-full bg-blue-50 dark:bg-blue-900/20 mx-auto mb-3 flex items-center justify-center"
          >
            <SearchIcon class="h-7 w-7 text-blue-500 dark:text-blue-400" />
          </div>
          <p class="text-sm font-medium text-gray-700 dark:text-gray-400 mb-1">
            Search the platform
          </p>
          <p class="text-xs text-gray-500 dark:text-gray-500 mb-4">
            Find posts, topics, and more
          </p>

          <div
            class="mt-4 space-y-2 text-xs text-gray-500 dark:text-gray-500 bg-gray-50 dark:bg-gray-800/80 rounded-lg p-3 border border-gray-100 dark:border-gray-700"
          >
            <p class="font-medium">Try searching for:</p>
            <div class="flex flex-wrap gap-1.5 justify-center mt-2">
              <button
                v-for="(suggestion, i) in searchSuggestions"
                :key="i"
                @click="setSearchQuery(suggestion)"
                class="px-2.5 py-1.5 bg-white dark:bg-gray-900 rounded-md border border-gray-200 dark:border-gray-700 hover:border-blue-200 dark:hover:border-blue-800 hover:bg-blue-50 dark:hover:bg-blue-900/20 transition-colors text-gray-700 dark:text-gray-400"
              >
                {{ suggestion }}
              </button>
            </div>
          </div>

          <div
            class="mt-4 text-xs text-gray-500 dark:text-gray-500 flex justify-center items-center gap-1.5"
          >
            <kbd
              class="px-2 py-1 bg-gray-100 dark:bg-gray-800 rounded-md text-gray-500 dark:text-gray-500 font-mono"
              >ESC</kbd
            >
            to close
          </div>
        </div>

        <!-- Loading State -->
        <div
          v-if="searchQuery && isLoading && filteredResults.length === 0"
          class="p-8 text-center"
        >
          <div class="loading-spinner mx-auto mb-3"></div>
          <p class="text-sm text-gray-500 dark:text-gray-500">Searching...</p>
        </div>
      </div>
    </Transition>
  </div>
</template>

<script setup>
import {
  SearchIcon,
  XIcon,
  ArrowRightIcon as ArrowRight,
  UserIcon as User,
  UserPlusIcon as UserPlus,
} from "lucide-vue-next";
const { get, post, del } = useApi();
const { user } = useAuth();
const toast = useToast();
const router = useRouter();
const showSearchDropdown = ref(false);
const isFollowing = ref(false);
const followLoading = ref(false);
const searchQuery = ref("");
const isLoading = ref(false);
const spellingSuggestion = ref("");
const usingFuzzySearch = ref(false);
const followingStatus = ref({});
// Separate arrays for posts and people
const posts = ref([]);
const people = ref([]);
const activeTab = ref("all"); // 'all', 'posts', or 'people'

// Add the annotation icon for suggestions
const AnnotationIcon = {
  name: "AnnotationIcon",
  props: {
    size: {
      type: String,
      default: "24",
    },
    color: {
      type: String,
      default: "currentColor",
    },
  },
  setup(props) {
    return () =>
      h(
        "svg",
        {
          xmlns: "http://www.w3.org/2000/svg",
          width: props.size,
          height: props.size,
          viewBox: "0 0 24 24",
          fill: "none",
          stroke: props.color,
          strokeWidth: "2",
          strokeLinecap: "round",
          strokeLinejoin: "round",
        },
        [
          h("path", {
            d: "M7 8h10M7 12h4m1 8l4-4H5a2 2 0 01-2-2V6a2 2 0 012-2h14a2 2 0 012 2v8a2 2 0 01-2 2h-3l-4 4z",
          }),
        ]
      );
  },
};

// Added search suggestions
const searchSuggestions = [
  "Marketing",
  "Finance",
  "Leadership",
  "Technology",
  "Innovation",
  "Business",
  "Development",
  "Strategy",
  "Management",
  "Analytics",
];

// Custom icon for no results state
const SearchOffIcon = {
  name: "SearchOffIcon",
  props: {
    size: {
      type: String,
      default: "24",
    },
    color: {
      type: String,
      default: "currentColor",
    },
  },
  setup(props) {
    return () =>
      h(
        "svg",
        {
          xmlns: "http://www.w3.org/2000/svg",
          width: props.size,
          height: props.size,
          viewBox: "0 0 24 24",
          fill: "none",
          stroke: props.color,
          strokeWidth: "2",
          strokeLinecap: "round",
          strokeLinejoin: "round",
        },
        [
          h("path", { d: "M10 10m-7 0a7 7 0 1 0 14 0a7 7 0 1 0 -14 0" }),
          h("path", { d: "M21 21l-6 -6" }),
          h("path", { d: "M3 3l18 18" }),
        ]
      );
  },
};

// Dictionary of common words for spell checking
const commonBusinessTerms = [
  "marketing",
  "finance",
  "leadership",
  "technology",
  "innovation",
  "business",
  "development",
  "strategy",
  "management",
  "sales",
  "analytics",
  "digital",
  "transformation",
  "project",
  "customer",
  "service",
  "product",
  "operations",
  "human",
  "resources",
  "investment",
  "revenue",
  "profit",
  "market",
  "brand",
  "advertising",
  "social",
  "media",
  "email",
  "content",
  "data",
  "analysis",
  "performance",
  "growth",
  "sustainability",
  "corporate",
  "entrepreneur",
  "startup",
  "global",
  "local",
  "team",
  "collaboration",
  "communication",
  "leadership",
  "executive",
  "director",
  "manager",
  "consultant",
  "advisor",
  "professional",
];

// Computed properties for filtered results based on active tab
const filteredPosts = computed(() => {
  if (activeTab.value === "all" || activeTab.value === "posts") {
    return posts.value;
  }
  return [];
});

const filteredPeople = computed(() => {
  if (activeTab.value === "all" || activeTab.value === "people") {
    return people.value;
  }
  return [];
});

// Updated limits: 4 posts and 6 people
const limitedFilteredPosts = computed(() => {
  // In "all" mode, limit to 4 posts
  if (activeTab.value === "all") {
    return filteredPosts.value.slice(0, 4);
  }
  // In "posts" mode, show up to 8 posts
  return filteredPosts.value.slice(0, 8);
});

const limitedFilteredPeople = computed(() => {
  // In "all" mode, limit to 6 people
  if (activeTab.value === "all") {
    return filteredPeople.value.slice(0, 6);
  }
  // In "people" mode, show up to 8 people
  return filteredPeople.value.slice(0, 8);
});

const filteredResults = computed(() => {
  if (activeTab.value === "all") {
    return [...filteredPosts.value, ...filteredPeople.value];
  } else if (activeTab.value === "posts") {
    return filteredPosts.value;
  } else {
    return filteredPeople.value;
  }
});

// Show sections based on available results
const showPosts = computed(() => {
  return filteredPosts.value.length > 0;
});

const showPeople = computed(() => {
  return filteredPeople.value.length > 0;
});

// Navigation functions for results
const navigateToPost = (post) => {
  if (post && post.id) {
    router.push(`/business-network/posts/${post.id}`);
    showSearchDropdown.value = false;
  }
};

// Updated navigation function with more robust error handling
const navigateToProfile = (person) => {
  if (person) {
    let profileUrl;

    // Determine the correct profile URL based on available data
    if (person.id) {
      profileUrl = `/business-network/profile/${person.id}`;
    } else {
      console.error("Cannot navigate to profile: Missing ID", person);
      return;
    }

    console.log("Navigating to profile:", profileUrl, person);
    router.push(profileUrl);
    showSearchDropdown.value = false;
  }
};

// Levenshtein Distance algorithm to calculate the edit distance between two strings
const levenshteinDistance = (str1, str2) => {
  const m = str1.length;
  const n = str2.length;

  // Create a matrix of size (m+1) x (n+1)
  const dp = Array(m + 1)
    .fill()
    .map(() => Array(n + 1).fill(0));

  // Initialize first row and column
  for (let i = 0; i <= m; i++) dp[i][0] = i;
  for (let j = 0; j <= n; j++) dp[0][j] = j;

  // Fill the matrix
  for (let i = 1; i <= m; i++) {
    for (let j = 1; j <= n; j++) {
      if (str1[i - 1] === str2[j - 1]) {
        dp[i][j] = dp[i - 1][j - 1];
      } else {
        dp[i][j] =
          1 +
          Math.min(
            dp[i - 1][j], // deletion
            dp[i][j - 1], // insertion
            dp[i - 1][j - 1] // substitution
          );
      }
    }
  }

  return dp[m][n];
};

// Observer reference
let observer;

// Register a new element to observe
function registerObserver(el, personId) {
  if (!el) return;
  if (!observer) return; // initialized onMounted

  observer.observe(el);
  el.dataset.personId = personId; // attach ID for lookup inside callback
}

// API call to check following status
async function checkFollowing(personId) {
  if (!user.value) return;
  try {
    const { data } = await get(
      `/bn/check-follow-status/${user.value?.user?.id}/${personId}/`
    );
    console.log(data, "check-follow-status");
    followingStatus.value[personId] = data.is_following;
  } catch (error) {
    console.error(error);
  }
}

// Setup observer once
onMounted(() => {
  observer = new IntersectionObserver(
    (entries) => {
      entries.forEach((entry) => {
        if (entry.isIntersecting) {
          const personId = entry.target.dataset.personId;
          if (personId) {
            checkFollowing(personId);
            observer.unobserve(entry.target);
          }
        }
      });
    },
    {
      threshold: 0.1, // how much of the element is visible (10% here)
    }
  );
});

const toggleFollow = async (personId) => {
  if (followLoading.value) return;
  followLoading.value = true;
  isFollowing.value = !isFollowing.value;

  if (!followingStatus.value[personId]) {
    try {
      const { data } = await post(`/bn/users/${personId}/follow/`);

      if (data) {
        // Update followers count accordingly

        toast.add({
          title: "Followed",
          description: "You have successfully followed this user.",
          icon: "i-heroicons-check-circle",
          color: "green",
        });
      }
    } catch (error) {
      console.error("Error toggling follow:", error);
      followingStatus.value[personId] = !followingStatus.value[personId]; // Revert state on error
    } finally {
      followLoading.value = false;
    }
  } else {
    try {
      const res = await del(`/bn/users/${personId}/unfollow/`);
      if (res.data === undefined) {
        // Update followers count accordingly

        toast.add({
          title: "Unfollowed",
          description: "You have successfully unfollowed this user.",
          icon: "i-heroicons-information-circle",
          color: "gray",
        });
      }
    } catch (error) {
      console.error("Error toggling follow:", error);
      followingStatus.value[personId] = !followingStatus.value[personId]; // Revert state on error
    } finally {
      followLoading.value = false;
    }
  }
};
// Find closest match for a word from dictionary
const findClosestMatch = (word) => {
  if (!word || word.length < 3) return null;

  // Normalize the word
  const normalizedWord = word.toLowerCase().trim();

  // Check if the word is already in the dictionary
  if (commonBusinessTerms.includes(normalizedWord)) {
    return null; // No correction needed
  }

  // Find the closest match
  let closestMatch = null;
  let minDistance = Infinity;

  // Set threshold based on word length
  const threshold = Math.max(2, Math.floor(normalizedWord.length * 0.4));

  for (const term of commonBusinessTerms) {
    // Skip very different length words for efficiency
    if (Math.abs(term.length - normalizedWord.length) > threshold) continue;

    const distance = levenshteinDistance(normalizedWord, term);

    // Update closest match if this is closer
    if (distance < minDistance && distance <= threshold) {
      minDistance = distance;
      closestMatch = term;
    }
  }

  return closestMatch;
};

// Generate spelling suggestion for the entire query
const generateSpellingSuggestion = (query) => {
  if (!query) return null;

  const words = query.split(/\s+/);
  let hasCorrection = false;
  const correctedWords = words.map((word) => {
    const closestMatch = findClosestMatch(word);
    if (closestMatch && closestMatch !== word.toLowerCase()) {
      hasCorrection = true;
      return closestMatch;
    }
    return word;
  });

  return hasCorrection ? correctedWords.join(" ") : null;
};

// Apply the spelling suggestion
const applySpellingSuggestion = () => {
  if (spellingSuggestion.value) {
    searchQuery.value = spellingSuggestion.value;
    spellingSuggestion.value = "";
  }
};

// Highlight search term matches in text
const highlightMatches = (text, query) => {
  if (!query || !text) return text;

  // Get both the original query terms and possible corrections
  const queryTerms = query.toLowerCase().split(/\s+/);

  // Create a combined pattern that includes both original terms and corrections
  let termPatterns = queryTerms
    .map((term) => {
      const escaped = term.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");

      // Find potential corrections for this term
      const correction = findClosestMatch(term);
      if (correction && correction !== term) {
        const escapedCorrection = correction.replace(
          /[.*+?^${}()|[\]\\]/g,
          "\\$&"
        );
        return `(${escaped}|${escapedCorrection})`;
      }
      return `(${escaped})`;
    })
    .join("|");

  // Create regex pattern from all terms
  const pattern = new RegExp(`(${termPatterns})`, "gi");

  return text.replace(
    pattern,
    '<span class="bg-yellow-100 dark:bg-yellow-900/30 text-yellow-800 dark:text-yellow-300 px-0.5 rounded">$1</span>'
  );
};

// Get a content preview with highlighted keywords
const getContentPreview = (content, query) => {
  if (!content) return "";
  if (!query) return content.substring(0, 100) + "...";

  // Extract a relevant portion of the content containing the search term
  const escapedQuery = query.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
  const pattern = new RegExp(`(${escapedQuery.split(/\s+/).join("|")})`, "i");
  const matchIndex = content.search(pattern);

  if (matchIndex >= 0) {
    // Get text around the match
    const start = Math.max(0, matchIndex - 40);
    const end = Math.min(content.length, matchIndex + 60);
    let preview = content.substring(start, end);

    // Add ellipsis if we're not starting from the beginning
    if (start > 0) preview = "..." + preview;
    // Add ellipsis if we're not ending at the end
    if (end < content.length) preview = preview + "...";

    return highlightMatches(preview, query);
  }

  // If no match found, just show the beginning
  return content.substring(0, 100) + "...";
};

// Check if a tag matches the search query
const isTagMatched = (tag, query) => {
  if (!tag || !query) return false;

  const normalizedTag = tag.toLowerCase();
  const words = query.toLowerCase().split(/\s+/);

  // Check for direct matches first
  if (words.some((word) => normalizedTag.includes(word))) {
    return true;
  }

  // If no direct match, check for fuzzy matches
  return words.some((word) => {
    const correction = findClosestMatch(word);
    return correction && normalizedTag.includes(correction);
  });
};

// Toggle search dropdown visibility
const toggleSearchDropdown = () => {
  showSearchDropdown.value = !showSearchDropdown.value;
  if (showSearchDropdown.value) {
    nextTick(() => {
      const searchInput = document.querySelector(".search-input");
      if (searchInput) {
        searchInput.focus();
      }
    });
  }
};

// Clear search input
const clearSearch = () => {
  searchQuery.value = "";
  posts.value = [];
  people.value = [];
  activeTab.value = "all";
  nextTick(() => {
    const searchInput = document.querySelector(".search-input");
    if (searchInput) {
      searchInput.focus();
    }
  });
};

// Set search query from suggestions
const setSearchQuery = (query) => {
  searchQuery.value = query;
};

// Navigate to all results page
const viewAllResults = () => {
  if (searchQuery.value) {
    // Navigate to all results page
    // Add the active tab as a query parameter if it's not 'all'
    let path = `/business-network/search-results/${encodeURIComponent(
      searchQuery.value
    )}`;
    if (activeTab.value !== "all") {
      path += `?tab=${activeTab.value}`;
    }

    router.push(path);
    showSearchDropdown.value = false;
  }
};

// Handle clicks outside of search dropdown to close it
const handleClickOutside = (event) => {
  const searchDropdown = document.querySelector(".search-dropdown-container");
  const searchButton = document.querySelector(".search-button-container");

  if (
    showSearchDropdown.value &&
    searchDropdown &&
    !searchDropdown.contains(event.target) &&
    searchButton &&
    !searchButton.contains(event.target)
  ) {
    showSearchDropdown.value = false;
  }
};

// Use lifecycle hooks to add and remove the global listener
onMounted(() => {
  nextTick(() => {
    document.addEventListener("click", handleClickOutside, true);

    // Add keyboard event listener for ESC key
    document.addEventListener("keydown", (e) => {
      if (e.key === "Escape" && showSearchDropdown.value) {
        showSearchDropdown.value = false;
      }
    });
  });
});

onUnmounted(() => {
  document.removeEventListener("click", handleClickOutside, true);
  document.removeEventListener("keydown", (e) => {
    if (e.key === "Escape" && showSearchDropdown.value) {
      showSearchDropdown.value = false;
    }
  });
});

// Expose methods and reactive state for parent components
defineExpose({
  toggleSearchDropdown,
  showSearchDropdown,
  searchQuery,
  posts,
  people,
});

// Debounce function to limit API calls
const debounce = (fn, wait) => {
  let timeout;
  return function (...args) {
    clearTimeout(timeout);
    timeout = setTimeout(() => fn.apply(this, args), wait);
  };
};

// Enhanced search function with better error handling and logging
const performSearch = async (query, useFuzzySearch = false) => {
  isLoading.value = true;
  usingFuzzySearch.value = useFuzzySearch;

  try {
    // Search for posts
    let postsEndpoint = `/bn/posts/search/?q=${encodeURIComponent(
      query
    )}&page=1`;
    let peopleEndpoint = `/bn/user-search/?q=${encodeURIComponent(query)}`;

    if (useFuzzySearch) {
      postsEndpoint += "&fuzzy=true";
      peopleEndpoint += "&fuzzy=true";
    }

    console.log(`Searching posts: ${postsEndpoint}`);
    console.log(`Searching users: ${peopleEndpoint}`);

    // Make parallel requests for posts and people
    const [postsRes, peopleRes] = await Promise.all([
      get(postsEndpoint),
      get(peopleEndpoint),
    ]);

    // Log response data to help debug
    console.log("Posts search response:", postsRes);
    console.log("People search response:", peopleRes);

    const postResults = postsRes.data?.results || [];

    // Process people results to ensure we have the required fields
    let peopleResults = [];
    if (peopleRes.data?.results && Array.isArray(peopleRes.data.results)) {
      peopleResults = peopleRes.data.results.map((person) => {
        // Add default values for missing fields
        return {
          id: person.id,
          name: person.name || "Unknown User",
          avatar_url: person.image || null,
          followers: person.follower_count || person.followers || 0,
          title: person.profession || person.position || person.bio || "",

          is_following: !!person.is_following,

          // Add any additional fields your backend provides
          ...person,
        };
      });
    }

    // If no results and not already using fuzzy search, generate spelling suggestion
    if (
      postResults.length === 0 &&
      peopleResults.length === 0 &&
      !useFuzzySearch
    ) {
      const suggestion = generateSpellingSuggestion(query);

      if (suggestion && suggestion !== query) {
        spellingSuggestion.value = suggestion;

        // Optionally, automatically perform search with the suggestion
        const [fuzzyPostsRes, fuzzyPeopleRes] = await Promise.all([
          get(
            `/bn/posts/search/?q=${encodeURIComponent(
              suggestion
            )}&page=1&fuzzy=true`
          ),
          get(
            `/bn/users/search/?q=${encodeURIComponent(suggestion)}&fuzzy=true`
          ),
        ]);

        const fuzzyPostResults = fuzzyPostsRes.data?.results || [];
        let fuzzyPeopleResults = [];

        if (
          fuzzyPeopleRes.data?.results &&
          Array.isArray(fuzzyPeopleRes.data.results)
        ) {
          fuzzyPeopleResults = fuzzyPeopleRes.data.results.map((person) => ({
            id: person.id,
            name: person.name || "Unknown User",
            avatar_url: person.image || null,
            followers: person.followers_count || person.followers || 0,
            title: person.title || person.position || person.bio || "",

            is_following: !!person.is_following,

            ...person,
          }));
        }

        return {
          posts: fuzzyPostResults,
          people: fuzzyPeopleResults,
        };
      }
    } else {
      spellingSuggestion.value = "";
    }

    return {
      posts: postResults,
      people: peopleResults,
    };
  } catch (error) {
    console.error("Search error:", error);
    return { posts: [], people: [] };
  } finally {
    isLoading.value = false;
  }
};

// Debounced search function with fuzzy fallback
const debouncedSearch = debounce(async (query) => {
  // First try exact search
  const results = await performSearch(query, false);

  // Update posts and people arrays
  posts.value = results.posts || [];
  people.value = results.people || [];

  // If no results, try fuzzy search with corrections
  if (posts.value.length === 0 && people.value.length === 0) {
    const fuzzyResults = await performSearch(query, true);
    posts.value = fuzzyResults.posts || [];
    people.value = fuzzyResults.people || [];
  }

  // Set appropriate tab if one result type is empty
  if (posts.value.length === 0 && people.value.length > 0) {
    activeTab.value = "people";
  } else if (people.value.length === 0 && posts.value.length > 0) {
    activeTab.value = "posts";
  } else {
    activeTab.value = "all";
  }
}, 300);

watch(searchQuery, (newValue) => {
  // Reset results when query is empty
  if (!newValue) {
    posts.value = [];
    people.value = [];
    isLoading.value = false;
    spellingSuggestion.value = "";
    usingFuzzySearch.value = false;
    return;
  }

  // Only search if query is at least 2 characters
  if (newValue.length >= 2) {
    debouncedSearch(newValue);
  } else {
    posts.value = [];
    people.value = [];
    spellingSuggestion.value = "";
  }
});
</script>

<style scoped>
/* Glass effect for header */
.backdrop-blur-sm {
  backdrop-filter: blur(8px);
}

/* Professional shadow for dropdown */
.shadow-professional {
  box-shadow: 0 10px 15px -3px rgba(0, 0, 0, 0.1),
    0 4px 6px -2px rgba(0, 0, 0, 0.05), 0 0 0 1px rgba(0, 0, 0, 0.05);
}

/* Loading spinner animation */
.loading-spinner {
  display: inline-block;
  width: 16px;
  height: 16px;
  border: 2px solid rgba(59, 130, 246, 0.3);
  border-radius: 50%;
  border-top-color: rgba(59, 130, 246, 0.8);
  animation: spin 0.8s linear infinite;
}

@keyframes spin {
  to {
    transform: rotate(360deg);
  }
}

/* Improved search input focus styles */
.search-input:focus {
  box-shadow: 0 0 0 2px rgba(59, 130, 246, 0.3);
}

/* Enhanced scrollbar for search results */
.search-results-container {
  scrollbar-width: thin;
  scrollbar-color: rgba(156, 163, 175, 0.5) transparent;
}

.search-results-container::-webkit-scrollbar {
  width: 4px;
}

.search-results-container::-webkit-scrollbar-track {
  background: transparent;
}

.search-results-container::-webkit-scrollbar-thumb {
  background-color: rgba(156, 163, 175, 0.5);
  border-radius: 9999px;
}

/* Mobile adjustments - FIXED POSITIONING */
@media (max-width: 640px) {
  .search-dropdown-container {
    position: fixed;
    width: calc(100% - 2rem);
    max-width: 400px;
    left: 50%;
    transform: translateX(-50%);
    top: 5rem;
    margin: 0 auto;
    z-index: 1000;
  }
}

/* Keyword highlight animation */
:deep(.bg-yellow-100) {
  position: relative;
  animation: highlight-pulse 2s infinite;
}

@keyframes highlight-pulse {
  0%,
  100% {
    opacity: 1;
  }
  50% {
    opacity: 0.8;
  }
}

/* Improve line clamp for multi-line text */
.line-clamp-2 {
  display: -webkit-box;
  -webkit-line-clamp: 2;
  -webkit-box-orient: vertical;
  overflow: hidden;
  word-break: break-word;
}

/* Fix for v-html content styling */
:deep(span) {
  vertical-align: middle;
}
</style>
