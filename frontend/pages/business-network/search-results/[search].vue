<template>
  <div class="mx-auto px-1 sm:px-6 lg:px-8 max-w-7xl mt-16 flex-1">    <!-- Enhanced Search Results Header -->
    <div
      class="relative bg-white rounded-lg shadow-sm mb-6 border-0"
    >
      <div
        class="flex flex-col md:flex-row md:items-center justify-between px-6 py-5 bg-gradient-to-r from-blue-50 to-blue-100/50 rounded-t-lg border-b border-blue-200/50"
      >
        <div class="mb-4 md:mb-0">
          <h1 class="text-xl font-semibold text-gray-800 flex items-center">
            <span class="bg-blue-200/70 rounded-full p-2 mr-3 shadow-sm">
              <Search class="h-4 w-4 text-blue-700" />
            </span>
            Search Results
          </h1>          <p class="text-gray-500 text-sm mt-2 flex items-center">
            <span class="font-medium text-blue-700 flex items-center">
              <span v-if="$route.params.search && $route.params.search.startsWith('#')" 
                class="mr-1.5 inline-flex items-center px-1.5 py-0.5 rounded-full text-xs font-medium bg-blue-100 text-blue-700"
              >
                <Hash class="h-3 w-3 mr-1" />
                Hashtag
              </span>
              {{ $route.params.search }}
            </span>
            <span class="mx-2 text-blue-200">•</span>
            <span v-if="!loading && !usersLoading && (allPosts.length > 0 || userResults.length > 0)"
              class="flex items-center gap-1"
            >
              <span class="font-medium text-gray-700">{{ userResults.length + allPosts.length }}</span>
              <span>{{ userResults.length + allPosts.length === 1 ? "result" : "results" }}</span>
              <span v-if="userResults.length > 0 && allPosts.length > 0" class="flex items-center gap-1 ml-1">
                <span class="text-gray-400 text-xs">(</span>
                <UsersRound class="h-3 w-3 text-gray-500" />
                <span class="text-gray-600">{{ userResults.length }}</span>
                <span class="mr-1 text-gray-400">,</span>
                <MessageSquare class="h-3 w-3 text-gray-500" />
                <span class="text-gray-600">{{ allPosts.length }}</span>
                <span class="text-gray-400 text-xs">)</span>
              </span>
            </span>
            <span v-else-if="!loading && !usersLoading && allPosts.length === 0 && userResults.length === 0"
              class="text-gray-600"
              >No results found</span
            >
            <span v-else class="text-blue-600 flex items-center">
              <Loader2 class="h-3 w-3 animate-spin mr-1" />
              Searching...
            </span>
          </p>
        </div>        <div class="flex items-center">
          <NuxtLink
            :to="`/business-network`"
            class="flex items-center gap-1.5 px-4 py-1.5 bg-white text-blue-600 rounded-md border border-blue-200 shadow-sm transition-colors text-sm font-medium"
          >
            <ArrowLeft class="h-3.5 w-3.5" />
            <span>Back to feed</span>
          </NuxtLink>
        </div>
      </div>
    </div>

    <!-- Enhanced skeleton loaders -->
    <template v-if="(loading || usersLoading) && !loadingMore && allPosts.length === 0 && userResults.length === 0">
      <div class="p-4">
        <div class="relative mb-8">
          <!-- Pulse loading animation -->
          <div class="flex justify-center items-center">
            <div class="relative">
              <Loader2 class="h-10 w-10 text-blue-600 animate-spin" />
              <div
                class="absolute inset-0 -m-2 rounded-full animate-ping opacity-30 bg-blue-400"
              ></div>
            </div>
          </div>          <p class="text-center text-blue-600 text-sm font-medium mt-4">
            Searching for "{{ $route.params.search }}"...
          </p>
        </div>

        <!-- Enhanced skeleton loaders for posts -->
        <div
          v-for="i in 3"
          :key="i"
          class="bg-white rounded-xl border border-gray-100 shadow-sm overflow-hidden mb-6 relative"
        >
          <!-- Header -->
          <div class="p-4 border-b border-gray-50">
            <div class="flex items-center space-x-3">
              <div
                class="w-10 h-10 rounded-full bg-gradient-to-r from-gray-200 to-gray-100 animate-pulse relative overflow-hidden"
              >
                <div
                  class="absolute inset-0 bg-gray-100 animate-pulse-wave"
                ></div>
              </div>
              <div class="flex-1 space-y-2">
                <div
                  class="h-3.5 bg-gradient-to-r from-gray-200 to-gray-100 rounded animate-pulse w-1/4"
                ></div>
                <div
                  class="h-2.5 bg-gradient-to-r from-gray-200 to-gray-100 rounded animate-pulse w-1/6"
                ></div>
              </div>
              <div
                class="h-7 w-7 rounded-md bg-gradient-to-r from-gray-200 to-gray-100 animate-pulse"
              ></div>
            </div>
          </div>

          <!-- Content -->
          <div class="p-4">
            <!-- Content lines -->
            <div class="space-y-3 mb-4">
              <div
                class="h-3.5 bg-gradient-to-r from-gray-200 to-gray-100 rounded animate-pulse w-3/4"
              ></div>
              <div
                class="h-3 bg-gradient-to-r from-gray-200 to-gray-100 rounded animate-pulse w-full"
              ></div>
              <div
                class="h-3 bg-gradient-to-r from-gray-200 to-gray-100 rounded animate-pulse w-5/6"
              ></div>
              <div
                class="h-3 bg-gradient-to-r from-gray-200 to-gray-100 rounded animate-pulse w-4/6"
              ></div>
            </div>

            <!-- Media placeholder -->
            <div
              class="h-40 bg-gradient-to-r from-gray-200 to-gray-100 rounded-lg animate-pulse mb-4 overflow-hidden relative"
            >
              <div
                class="absolute inset-0 bg-gray-100 animate-pulse-slower opacity-50"
              ></div>
              <div class="absolute inset-0 flex items-center justify-center">
                <div
                  class="w-10 h-10 rounded-full bg-white/30 flex items-center justify-center"
                >
                  <Image class="w-5 h-5 text-white/50" />
                </div>
              </div>
            </div>

            <!-- Action buttons -->
            <div
              class="flex justify-between items-center pt-2 border-t border-gray-50"
            >
              <div
                class="h-8 bg-gradient-to-r from-gray-200 to-gray-100 rounded-full animate-pulse w-20"
              ></div>
              <div
                class="h-8 bg-gradient-to-r from-gray-200 to-gray-100 rounded-full animate-pulse w-20"
              ></div>
              <div
                class="h-8 bg-gradient-to-r from-gray-200 to-gray-100 rounded-full animate-pulse w-20"
              ></div>
            </div>
          </div>

          <!-- Tag indicators at bottom -->
          <div class="px-4 pb-4 flex gap-2">
            <div
              class="h-5 bg-gradient-to-r from-gray-200 to-gray-100 rounded-full animate-pulse w-16"
            ></div>
            <div
              class="h-5 bg-gradient-to-r from-gray-200 to-gray-100 rounded-full animate-pulse w-20"
            ></div>
          </div>
        </div>
      </div>
    </template>    <!-- Search Results Section -->
    <div class="relative" v-if="!loading || !usersLoading || userResults.length > 0 || allPosts.length > 0">        <!-- No Results Message - Professionally styled -->
      <div 
        v-if="!loading && !usersLoading && userResults.length === 0 && allPosts.length === 0" 
        class="flex flex-col items-center justify-center py-10 text-center bg-white rounded-lg border border-gray-200/80 shadow-sm"
      >
        <div class="mb-4">
          <div class="w-16 h-16 rounded-full bg-blue-50 border border-blue-100 flex items-center justify-center">
            <Search v-if="!$route.params.search.startsWith('#')" class="h-7 w-7 text-blue-500" />
            <Hash v-else class="h-7 w-7 text-blue-500" />
          </div>
        </div>
        <h3 class="text-xl font-semibold text-gray-800 mb-2">
          {{ $route.params.search.startsWith('#') ? 'No Results for this Hashtag' : 'No Results Found' }}
        </h3>
        <p class="text-gray-600 max-w-md mx-auto mb-6 px-4">
          <template v-if="$route.params.search.startsWith('#')">
            We couldn't find any posts or people using the hashtag "<span class="text-blue-600 font-medium">{{ $route.params.search }}</span>". Try a different hashtag or check the spelling.
          </template>
          <template v-else>
            We couldn't find any matches for "<span class="text-blue-600 font-medium">{{ $route.params.search }}</span>". Try using different keywords or checking for typos.
          </template>
        </p>
        <div class="mt-2">
          <NuxtLink
            to="/business-network"
            class="flex items-center gap-2 px-5 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700 transition-colors shadow-sm"
          >
            <Home class="h-4 w-4" />
            <span>Return to feed</span>
          </NuxtLink>
        </div>
      </div>
        <!-- Search match explanation section -->      <div v-if="!loading && !usersLoading && (userResults.length > 0 || allPosts.length > 0)" class="mb-6 bg-white p-4 rounded-lg border border-blue-100/80">
        <div class="flex items-start gap-3">
          <div class="p-2 bg-blue-50 rounded-full mt-1">
            <Search class="h-4 w-4 text-blue-600" />
          </div>
          <div>
            <h3 class="font-medium text-gray-800 mb-1.5">Search Results For: "<span class="text-blue-600">{{ $route.params.search }}</span>"</h3>
            <p class="text-sm text-gray-600 mb-2">
              We search through user names, usernames, post titles, content and hashtags to find the best matches. Results are ranked by relevance.
            </p>
            <div class="flex flex-wrap gap-2 mt-2">
              <div class="flex items-center text-xs bg-blue-50 text-blue-700 px-2 py-1 rounded-full">
                <svg class="h-3 w-3 mr-1" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                  <path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2"></path>
                  <circle cx="12" cy="7" r="4"></circle>
                </svg>
                <span class="mr-1 font-medium">Name Match:</span>
                <span>First/last name or username</span>
              </div>
              <div class="flex items-center text-xs bg-green-50 text-green-700 px-2 py-1 rounded-full">
                <svg class="h-3 w-3 mr-1" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                  <path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"></path>
                  <path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"></path>
                </svg>
                <span class="mr-1 font-medium">Title match:</span>
                <span>Post title</span>
              </div>
              <div class="flex items-center text-xs bg-yellow-50 text-yellow-700 px-2 py-1 rounded-full">
                <svg class="h-3 w-3 mr-1" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                  <path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"></path>
                  <polyline points="14 2 14 8 20 8"></polyline>
                  <line x1="16" y1="13" x2="8" y2="13"></line>
                  <line x1="16" y1="17" x2="8" y2="17"></line>
                  <polyline points="10 9 9 9 8 9"></polyline>
                </svg>
                <span class="mr-1 font-medium">Content match:</span> 
                <span>Post body</span>
              </div>
              <div class="flex items-center text-xs bg-purple-50 text-purple-700 px-2 py-1 rounded-full">
                <svg class="h-3 w-3 mr-1" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                  <line x1="4" y1="9" x2="20" y2="9"></line>
                  <line x1="4" y1="15" x2="20" y2="15"></line>
                  <line x1="10" y1="3" x2="8" y2="21"></line>
                  <line x1="16" y1="3" x2="14" y2="21"></line>
                </svg>
                <span class="mr-1 font-medium">Hashtag match:</span>
                <span>Post hashtags</span>
              </div>
            </div>
            <div class="mt-2 pt-2 border-t border-gray-100">
              <p class="text-xs text-gray-500">
                <span class="font-medium">Exact matches and hashtag matches are weighted highest</span> in search results. Content matching your search term will be highlighted.
              </p>
            </div>
          </div>
        </div>
      </div>
      
      <!-- Users Section - Always displayed first when available -->      <div v-if="!usersLoading && userResults.length > 0" class="mb-8">
        <div class="flex justify-between items-center mb-4 px-1">
          <h2 class="text-lg font-semibold text-gray-800 flex items-center">
            <UsersRound class="h-4 w-4 text-blue-600 mr-2" />
            People
          </h2>
          <div class="text-sm text-gray-500">
            Found {{ userResults.length }} {{ userResults.length === 1 ? 'person' : 'people' }} matching "<span class="text-blue-600 font-medium">{{ $route.params.search }}</span>"
          </div>
        </div>
        
        <div class="bg-white rounded-lg overflow-hidden border border-gray-200/70">
          <div class="divide-y divide-gray-100">            <BusinessNetworkUserCard
              v-for="user in displayedUsers"
              :key="user.id"
              :user="user"
              :search-query="$route.params.search"
              class="bg-white hover:bg-blue-50/40 transition-colors"
            />
          </div>
        </div>        <!-- Load more people button -->
        <div v-if="userResults.length > initialUserCount" class="flex justify-center bg-gray-50/70 py-3 border-t border-gray-100">
          <button 
            v-if="!showAllUsers" 
            @click="showAllUsers = true"
            class="flex items-center gap-2 px-5 py-2 bg-white border border-blue-200 rounded text-blue-700 text-sm font-medium hover:bg-blue-50 transition-colors"
          >
            <UsersRound class="h-4 w-4" />
            <span>View All {{ userResults.length }} People</span>
          </button>
        </div>
        
        <div class="border-b border-gray-100 my-6"></div>
      </div>      <!-- Posts Section -->
      <div>
        <!-- Post header with improved styling -->
        <div class="flex justify-between items-center mb-4 px-1" v-if="allPosts.length > 0">
          <h2 class="text-lg font-semibold text-gray-800 flex items-center">
            <MessageSquare class="h-4 w-4 text-blue-600 mr-2" />
            Posts
          </h2>
          
          <!-- Search result count when posts are loaded -->
          <div
            v-if="!loading && displayedPosts.length > 0"
            class="text-sm text-gray-500"
          >
            Found {{ allPosts.length }}
            {{ allPosts.length === 1 ? "post" : "posts" }} matching "<span
              class="text-blue-600 font-medium"
              >{{ $route.params.search }}</span
            >"
          </div>
        </div>        <!-- Empty state for posts when users are found but no posts -->
        <div
          v-if="!loading && displayedPosts.length === 0 && allPosts.length === 0 && userResults.length > 0"
          class="bg-white rounded-lg border border-gray-200 p-6 text-center mb-6"
        >
          <div class="mx-auto w-fit mb-3">
            <MessageSquare v-if="!$route.params.search.startsWith('#')" class="h-10 w-10 text-gray-300" />
            <Hash v-else class="h-10 w-10 text-blue-200" />
          </div>
          <p class="text-gray-600 font-medium mb-1">
            {{ $route.params.search.startsWith('#') ? 'No posts with this hashtag' : 'No posts found' }}
          </p>
          <p class="text-gray-500 text-sm">
            <template v-if="$route.params.search.startsWith('#')">
              No posts with the hashtag "{{ $route.params.search }}" were found, but we did find people.
            </template>
            <template v-else>
              No posts matching "{{ $route.params.search }}" were found, but we did find people.
            </template>
          </p>
        </div>
          <!-- Posts container with improved styling -->
        <div class="bg-white rounded-lg overflow-hidden border border-gray-200/70" v-if="displayedPosts.length > 0">
          <BusinessNetworkPost
            :posts="displayedPosts"
            :id="user?.user?.id"
            :search-query="route.params.search"
            class="result-card"
            @gift-sent="handleGiftSent"
          />
        </div>
      </div>
    </div>    <!-- Enhanced load more indicator with improved styling -->
    <div v-if="loadingMore && !loading" class="pb-6">
      <div class="flex justify-center items-center py-5 bg-white rounded-lg border border-gray-200/70 mb-6">
        <div class="flex items-center">
          <Loader2 class="h-5 w-5 text-blue-600 animate-spin mr-3" />
          <span class="text-blue-700 font-medium">Loading more results...</span>
        </div>
      </div>

      <!-- Enhanced skeleton loader for loading more posts -->
      <div
        class="bg-white rounded-xl border border-gray-100 shadow-sm overflow-hidden mb-6 relative"
      >
        <!-- Header -->
        <div class="p-4 border-b border-gray-50">
          <div class="flex items-center space-x-3">
            <div
              class="w-10 h-10 rounded-full bg-gradient-to-r from-gray-200 to-gray-100 animate-pulse relative overflow-hidden"
            >
              <div
                class="absolute inset-0 bg-gray-100 animate-pulse-wave"
              ></div>
            </div>
            <div class="flex-1 space-y-2">
              <div
                class="h-3.5 bg-gradient-to-r from-gray-200 to-gray-100 rounded animate-pulse w-1/4"
              ></div>
              <div
                class="h-2.5 bg-gradient-to-r from-gray-200 to-gray-100 rounded animate-pulse w-1/6"
              ></div>
            </div>
            <div
              class="h-7 w-7 rounded-md bg-gradient-to-r from-gray-200 to-gray-100 animate-pulse"
            ></div>
          </div>
        </div>

        <!-- Content -->
        <div class="p-4">
          <!-- Content lines -->
          <div class="space-y-3 mb-4">
            <div
              class="h-3.5 bg-gradient-to-r from-gray-200 to-gray-100 rounded animate-pulse w-3/4"
            ></div>
            <div
              class="h-3 bg-gradient-to-r from-gray-200 to-gray-100 rounded animate-pulse w-full"
            ></div>
            <div
              class="h-3 bg-gradient-to-r from-gray-200 to-gray-100 rounded animate-pulse w-5/6"
            ></div>
          </div>

          <!-- Action buttons -->
          <div
            class="flex justify-between items-center pt-2 border-t border-gray-50"
          >
            <div
              class="h-8 bg-gradient-to-r from-gray-200 to-gray-100 rounded-full animate-pulse w-20"
            ></div>
            <div
              class="h-8 bg-gradient-to-r from-gray-200 to-gray-100 rounded-full animate-pulse w-20"
            ></div>
            <div
              class="h-8 bg-gradient-to-r from-gray-200 to-gray-100 rounded-full animate-pulse w-20"
            ></div>
          </div>
        </div>
      </div>
    </div>    <!-- Enhanced end of results indicator with professional styling -->
    <div
      v-if="!loading && !loadingMore && !hasMore && allPosts.length > 0"
      class="flex flex-col items-center justify-center py-8 text-center bg-white rounded-lg border border-gray-200/70 mb-6"
    >
      <div class="mb-4">
        <div
          class="w-12 h-12 rounded-full bg-blue-100 flex items-center justify-center"
        >
          <Check class="h-6 w-6 text-blue-600" />
        </div>
      </div>

      <h3 class="text-lg font-semibold text-gray-800 mb-1">
        End of Search Results
      </h3>
      <p class="text-gray-500 mb-4 max-w-md">
        You've seen all posts matching your search for "{{
          $route.params.search
        }}".
      </p>

      <div class="flex flex-col sm:flex-row gap-3 mb-8">
        <button
          @click="scrollToTop"
          class="flex items-center justify-center gap-2 px-5 py-2 text-sm bg-blue-50 text-blue-600 rounded-lg hover:bg-blue-100 transition-colors border border-blue-100 shadow-sm"
        >
          <ChevronUp class="h-4 w-4" />
          <span>Back to top</span>
        </button>

        <NuxtLink
          to="/business-network"
          class="flex items-center justify-center gap-2 px-5 py-2 text-sm bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors shadow-sm"
        >
          <Home class="h-4 w-4" />
          <span>Return to feed</span>
        </NuxtLink>
      </div>

      <div class="bg-gray-50 rounded-lg p-4 border border-gray-100 max-w-md">
        <h4 class="font-medium text-gray-700 mb-2">
          Looking for something else?
        </h4>
        <div class="relative">
          <input
            type="text"
            placeholder="Try another search..."
            v-model="newSearchQuery"
            class="w-full border border-gray-300 rounded-lg py-2 px-4 pr-10 text-sm focus:outline-none focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500"
            @keyup.enter="handleNewSearch"
          />
          <button
            @click="handleNewSearch"
            class="absolute right-2 top-1/2 -translate-y-1/2 p-1 bg-blue-500 hover:bg-blue-600 text-white rounded-md transition-colors"
          >
            <Search class="h-4 w-4" />
          </button>
        </div>
      </div>
    </div>

    <!-- Enhanced no results message -->
    <div
      v-if="!loading && !usersLoading && !loadingMore && allPosts.length === 0 && userResults.length === 0"
      class="flex flex-col items-center justify-center py-12 text-center bg-white rounded-xl shadow-sm border border-gray-100 px-4"
    >
      <div
        class="w-16 h-16 rounded-full bg-gray-50 flex items-center justify-center mb-6 border border-gray-200"
      >
        <Search class="h-8 w-8 text-gray-500" />
      </div>

      <h3 class="text-lg font-semibold text-gray-700 mb-2">No results found</h3>
      <p class="text-gray-500 mb-6 max-w-md">
        We couldn't find any posts matching "{{ $route.params.search }}". Try
        adjusting your search terms or filters.
      </p>

      <div class="w-full max-w-md">
        <div class="bg-gray-50 rounded-lg p-4 mb-6 border border-gray-100">
          <h4 class="font-medium text-gray-700 mb-3">Suggestions:</h4>
          <ul class="text-sm text-gray-500 space-y-2">
            <li class="flex items-start">
              <div class="min-w-4 mr-2 mt-0.5">•</div>
              <span>Check your spelling</span>
            </li>
            <li class="flex items-start">
              <div class="min-w-4 mr-2 mt-0.5">•</div>
              <span>Try more general keywords</span>
            </li>
            <li class="flex items-start">
              <div class="min-w-4 mr-2 mt-0.5">•</div>
              <span>Use different keywords</span>
            </li>
            <li class="flex items-start">
              <div class="min-w-4 mr-2 mt-0.5">•</div>
              <span>Reset the search filters</span>
            </li>
          </ul>
        </div>

        <div class="relative">
          <input
            type="text"
            placeholder="Try another search..."
            v-model="newSearchQuery"
            class="w-full border border-gray-300 rounded-lg py-2.5 px-4 pr-12 text-sm focus:outline-none focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500"
            @keyup.enter="handleNewSearch"
          />
          <button
            @click="handleNewSearch"
            class="absolute right-2 top-1/2 -translate-y-1/2 p-1.5 bg-blue-500 hover:bg-blue-600 text-white rounded-md transition-colors"
          >
            <Search class="h-4 w-4" />
          </button>
        </div>

        <div class="my-8">
          <NuxtLink
            to="/business-network"
            class="flex items-center justify-center gap-2 px-5 py-2.5 text-sm bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors shadow-sm"
          >
            <ArrowLeft class="h-4 w-4" />
            <span>Return to feed</span>
          </NuxtLink>
        </div>
      </div>
    </div>

    <!-- Add the create post component with event listener -->
    <BusinessNetworkCreatePost @post-created="handleNewPost" />
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
  ArrowLeft,
  Loader2,
  Check,
  ChevronUp,
  Home,
  Image,
  UsersRound,
  MessageSquare
} from "lucide-vue-next";
const route = useRoute();

// State
const allPosts = ref([]); // All loaded posts
const displayedPosts = ref([]); // Currently displayed posts
const loading = ref(true);
const loadingMore = ref(false);
const { get } = useApi();
const { user } = useAuth();
const eventBus = useEventBus();
const loadedPostIds = ref(new Set()); // Track loaded post IDs to prevent duplicates

// User search state
const userResults = ref([]); // User search results
const displayedUsers = ref([]); // Currently displayed users
const usersLoading = ref(true);
const initialUserCount = 10; // Initial number of users to display
const showAllUsers = ref(false); // Whether to show all users

// Search state
const newSearchQuery = ref("");

// Batch size and pagination
const POSTS_PER_BATCH = 10; // Load 10 posts initially
const page = ref(1);
const hasMore = ref(true);
const lastCreatedAt = ref(null); // For pagination cursor
const newestCreatedAt = ref(null); // For refresh/newer posts

// Listen for loading events from footer and sidebar
eventBus.on("start-loading-posts", () => {
  // Set loading to true immediately
  loading.value = true;
});

// Calculate the relevance score of a search result with improved weighting
function calculateRelevanceScore(post, searchQuery) {
  if (!post || !searchQuery) return 0;
  
  let score = 0;
  let matchWeight = 0;
  const normalizedQuery = searchQuery.startsWith('#') ? searchQuery.substring(1) : searchQuery;
  const lowerQuery = normalizedQuery.toLowerCase();
  
  // Check if this is a hashtag search
  const isHashtagSearch = searchQuery.startsWith('#');
  
  // Check for exact hashtag match (highest weight)
  if (post.post_tags && post.post_tags.some(tag => tag.tag.toLowerCase() === lowerQuery)) {
    score += 150; // Increased weight for exact tag matches
    matchWeight += 5;
  }
  // Check for hashtag contains match
  else if (post.matchFields?.includes('hashtag') || 
          (post.post_tags && post.post_tags.some(tag => tag.tag.toLowerCase().includes(lowerQuery)))) {
    score += 100;
    matchWeight += 4;
  }
  
  // Title exact match (very high weight)
  if (post.title && post.title.toLowerCase() === lowerQuery) {
    score += 110;
    matchWeight += 5;
  }
  // Title contains match (high weight)
  else if (post.matchFields?.includes('title') || 
          (post.title && post.title.toLowerCase().includes(lowerQuery))) {
    score += 75;
    matchWeight += 3;
  }
  
  // Author exact match (high weight)
  if (post.author_details) {
    const authorFullName = `${post.author_details.first_name || ''} ${post.author_details.last_name || ''}`.toLowerCase();
    const authorUsername = (post.author_details.username || '').toLowerCase();
    
    // Exact name or username match
    if (authorFullName === lowerQuery || authorUsername === lowerQuery) {
      score += 90;
      matchWeight += 4;
    }
    // Contains match in name or username
    else if (post.matchFields?.includes('author') || 
            authorFullName.includes(lowerQuery) || 
            authorUsername.includes(lowerQuery)) {
      score += 50;
      matchWeight += 2;
    }
  }
  
  // Content exact match (happens when the full search query appears in content)
  if (post.content && post.content.toLowerCase().includes(` ${lowerQuery} `)) {
    score += 60;
    matchWeight += 3;
  }
  // Content contains match
  else if (post.matchFields?.includes('content') || 
          (post.content && post.content.toLowerCase().includes(lowerQuery))) {
    score += 25;
    matchWeight += 1;
  }
  
  // Boosting for hashtag searches - give more weight to hashtag matches in hashtag searches
  if (isHashtagSearch && post.hasMatchingHashtag) {
    score = score * 1.5; // 50% boost for matching hashtag in hashtag search
  }
  
  // Boost score based on number of different fields matching (multiplicative)
  if (matchWeight > 0) {
    score = score * (1 + (matchWeight / 8));
  }
  
  // Recency bonus (newer posts get priority, more significant for newer posts)
  if (post.created_at) {
    const postDate = new Date(post.created_at);
    const now = new Date();
    const daysDifference = Math.floor((now - postDate) / (1000 * 60 * 60 * 24));
    
    // Add recency bonus with exponential decay
    if (daysDifference === 0) {
      // Posts from today get a big boost
      score += 20;
    } else if (daysDifference <= 7) {
      // Posts from the past week get a moderate boost
      score += 15 - daysDifference;
    } else {
      // Older posts get a smaller boost with diminishing returns
      score += Math.max(0, 8 - Math.log2(daysDifference));
    }
  }
  
  return score;
}

// Get initial posts or more posts based on pagination
async function getPosts(isLoadingMore = false, page = 1) {
  try {
    if (isLoadingMore) {
      loadingMore.value = true;
    } else {
      loading.value = true;
    }

    // Build query parameters based on action type
    let params = {
      page_size: isLoadingMore ? 1 : POSTS_PER_BATCH, // Load 1 post at a time when scrolling
    };

    if (isLoadingMore && lastCreatedAt.value) {
      // Get older posts (for pagination)
      params.older_than = lastCreatedAt.value;
    }    // Extract the search query
    const searchQuery = route.params.search;
      // If the search query starts with #, it's a hashtag search
    const isHashtagSearch = searchQuery.startsWith('#');
    const normalizedQuery = isHashtagSearch ? searchQuery.substring(1) : searchQuery;
    
    // Debug hashtag search information
    console.debug('Search info:', {
      originalQuery: searchQuery,
      isHashtagSearch,
      normalizedQuery
    });
    
    // Build complete params object for the search
    const searchParams = new URLSearchParams();
    
    // Always include these parameters
    searchParams.append('page', page.toString());
    searchParams.append('page_size', params.page_size.toString());
    
    // Add pagination cursor if available
    if (params.older_than) {
      searchParams.append('older_than', params.older_than);
    }
      // Always include the search term in the main query for searching in name, title and content
    searchParams.append('q', normalizedQuery);
    
    // For hashtag searches, also specifically search in tags
    if (isHashtagSearch) {
      searchParams.append('tag', normalizedQuery);
    } else {
      // For regular searches, we want to look in tags as well for better results
      searchParams.append('tag', normalizedQuery);
    }
    
    const queryString = searchParams.toString();
    console.log("Fetching posts with params:", Object.fromEntries(searchParams));

    const [response] = await Promise.all([
      get(`/bn/posts/search/?${queryString}`),
      // Add a minimum delay for UX, shorter for subsequent loads
      new Promise((resolve) => setTimeout(resolve, isLoadingMore ? 300 : 800)),
    ]);    if (response.data && response.data.results) {
      const newPosts = response.data.results;
      
      console.log("Search results for:", route.params.search, {
        totalResults: newPosts.length,
        firstPost: newPosts.length > 0 ? {
          content: newPosts[0].content?.substring(0, 50) + "...",
          tags: newPosts[0].tags,
        } : 'No posts found'
      });      // Process posts to ensure they have necessary UI properties
      const processedPosts = newPosts.map((post) => {
        // Check if this post has matching hashtags when doing a hashtag search
        const hasMatchingHashtag = isHashtagSearch && 
          post.post_tags && 
          post.post_tags.some(tag => 
            tag.tag.toLowerCase() === normalizedQuery.toLowerCase()
          );
        
        // Check where the search term appears (for better highlighting)
        const matchFields = [];
        
        // Check author name match
        if (post.author_details) {
          const authorName = `${post.author_details.first_name || ''} ${post.author_details.last_name || ''}`.toLowerCase();
          const username = (post.author_details.username || '').toLowerCase();
          if (authorName.includes(normalizedQuery.toLowerCase()) || username.includes(normalizedQuery.toLowerCase())) {
            matchFields.push('author');
          }
        }
        
        // Check title match
        if (post.title && post.title.toLowerCase().includes(normalizedQuery.toLowerCase())) {
          matchFields.push('title');
        }
        
        // Check content match
        if (post.content && post.content.toLowerCase().includes(normalizedQuery.toLowerCase())) {
          matchFields.push('content');
        }
        
        // Check hashtag match
        if (hasMatchingHashtag) {
          matchFields.push('hashtag');
        }
        
        return {
          ...post,
          showFullDescription: false,
          showDropdown: false,
          commentText: "",
          isCommentLoading: false,
          isLikeLoading: false,
          hasMatchingHashtag: hasMatchingHashtag,
          matchFields: matchFields,
        };
      });

      // Filter out duplicate posts based on their IDs
      const uniquePosts = processedPosts.filter((post) => {
        if (loadedPostIds.value.has(post.id)) {
          console.log(`Filtered out duplicate post ID: ${post.id}`);
          return false;
        }
        loadedPostIds.value.add(post.id);
        return true;
      });

      console.log(
        `Found ${processedPosts.length} posts, ${uniquePosts.length} are unique`
      );

      // Sort results by relevance (weighted by match type)
      const sortedUniquePosts = [...uniquePosts].sort((a, b) => {
        // Calculate relevance scores
        const scoreA = calculateRelevanceScore(a, searchQuery);
        const scoreB = calculateRelevanceScore(b, searchQuery);
        
        // Sort by relevance score (higher is better)
        return scoreB - scoreA;
      });

      // On initial load or load more, append to the end
      allPosts.value = isLoadingMore
        ? [...allPosts.value, ...sortedUniquePosts]
        : sortedUniquePosts;

      // Update pagination cursor if we got any unique posts
      if (uniquePosts.length > 0) {
        const lastPost = uniquePosts[uniquePosts.length - 1];
        lastCreatedAt.value = lastPost.created_at;

        // Set initial newest timestamp if first load
        if (!newestCreatedAt.value && uniquePosts.length > 0) {
          newestCreatedAt.value = uniquePosts[0].created_at;
          console.log("Initial newest timestamp set:", newestCreatedAt.value);
        }
      }

      if (processedPosts.length > 0 && uniquePosts.length === 0) {
        hasMore.value = false;
      } else {
        // If we got some unique posts, assume there might be more
        hasMore.value = processedPosts.length > 0;

        // If we got no posts at all, we've definitely reached the end
        if (processedPosts.length === 0) {
          hasMore.value = false;
        }
      }

      // Update displayed posts
      updateDisplayedPosts();
    } else {
      console.log("No posts returned from API");
      if (!isLoadingMore) {
        // Only clear on initial load failure
        allPosts.value = [];
        displayedPosts.value = [];
      }
      hasMore.value = false;
    }
  } catch (error) {
    console.error("Failed to load posts:", error);
    useToast().add({
      title: "Error",
      description: "Failed to load posts",
      color: "red",
      timeout: 3000,
    });

    if (!isLoadingMore) {
      allPosts.value = [];
      displayedPosts.value = [];
    }
    hasMore.value = false;
  } finally {
    loading.value = false;
    loadingMore.value = false;
  }
}

// Get user search results
async function getUsers() {
  try {
    usersLoading.value = true;

    // Extract the search query
    const searchQuery = route.params.search;
    
    // Build search params for user search
    const searchParams = new URLSearchParams();
    
    // If search starts with #, remove it for user search
    if (searchQuery.startsWith('#')) {
      searchParams.append('q', searchQuery.substring(1));
    } else {
      searchParams.append('q', searchQuery);
    }
    
    const queryString = searchParams.toString();
    console.log("Fetching users with params:", Object.fromEntries(searchParams));

    const [response] = await Promise.all([
      get(`/bn/user-search/?${queryString}`),
      // Add a minimum delay for UX
      new Promise((resolve) => setTimeout(resolve, 800)),
    ]);

    if (response.data && response.data.results) {
      userResults.value = response.data.results;
      updateDisplayedUsers();
    } else {
      userResults.value = [];
      displayedUsers.value = [];
    }
  } catch (error) {
    console.error("Failed to load users:", error);
    useToast().add({
      title: "Error",
      description: "Failed to load users",
      color: "red",
      timeout: 3000,
    });
    userResults.value = [];
    displayedUsers.value = [];
  } finally {
    usersLoading.value = false;
  }
}

// Function to update displayed posts with proper grouping
function updateDisplayedPosts() {
  // Create a new array to avoid reactivity issues
  displayedPosts.value = [...allPosts.value];
}

// Function to update displayed users
function updateDisplayedUsers() {
  displayedUsers.value = showAllUsers.value
    ? [...userResults.value]
    : [...userResults.value.slice(0, initialUserCount)];
}

// Watch for changes to showAllUsers
watch(showAllUsers, () => {
  updateDisplayedUsers();
});

// Handle gift sent event from child components
function handleGiftSent(giftData) {
  console.log("Gift sent event received:", giftData);

  // Display a toast notification
  useToast().add({
    title: "Gift Sent!",
    description: `${giftData.giftAmount} diamonds sent successfully`,
    color: "green",
    timeout: 3000,
  });

  // Reload posts after a short delay to ensure backend is updated
  setTimeout(() => {
    // Reset state and reload posts
    loadData();
  }, 20);
}

// Load data when component is created
function loadData() {
  // Reset state
  loading.value = true;
  usersLoading.value = true;
  page.value = 1;
  hasMore.value = true;
  lastCreatedAt.value = null;
  showAllUsers.value = false; // Reset user display to show initial count only
  loadedPostIds.value.clear(); // Reset tracked post IDs when reloading
  allPosts.value = []; // Clear all posts
  userResults.value = []; // Clear all user results
  displayedPosts.value = []; // Clear displayed posts
  displayedUsers.value = []; // Clear displayed users

  // Get initial posts and users with a slight delay
  setTimeout(() => {
    // Fetch users first then posts to prioritize showing people results first
    const fetchData = async () => {
      await getUsers(); // Get users first
      await getPosts(); // Then get posts
    };
    
    fetchData();
  }, 100); // Small delay to ensure navigation completes first
}

// Load more posts when user scrolls down
function loadMorePosts() {
  if (!hasMore.value || loadingMore.value || loading.value) return;

  page.value++;
  getPosts(true, page.value);
}

// Setup scroll detection for infinite scroll
function setupInfiniteScroll() {
  const handleScroll = () => {
    if (
      window.innerHeight + window.scrollY >=
      document.body.offsetHeight - 500
    ) {
      if (!loadingMore.value && hasMore.value) {
        loadMorePosts();
      }
    }
  };

  window.addEventListener("scroll", handleScroll);

  // Remove event listener on component unmount
  onUnmounted(() => {
    window.removeEventListener("scroll", handleScroll);
  });
}

// Initialize
onMounted(() => {
  loadData();
  setupInfiniteScroll();
});

// Watch for route changes to reload data when search query changes
watch(
  () => route.params.search,
  (newSearch, oldSearch) => {
    if (newSearch !== oldSearch) {
      loadData();
    }
  }
);

// Event listener setup
onMounted(() => {
  // Listen for events from footer or sidebar
  eventBus.on("start-loading-posts", () => {
    loadData();
  });

  // Clean up event listeners when component is unmounted
  onUnmounted(() => {
    eventBus.off("start-loading-posts");
    eventBus.off("load-recent-posts");
  });
});

// Add this function to handle the new post
const handleNewPost = (newPost) => {
  // Process the new post to ensure it has necessary UI properties
  const processedNewPost = {
    ...newPost,
    showFullDescription: false,
    showDropdown: false,
    commentText: "",
    isCommentLoading: false,
    isLikeLoading: false,
  };

  // Track the new post ID to prevent future duplicates
  if (newPost.id) {
    loadedPostIds.value.add(newPost.id);
  }

  // Add the new post to the beginning of the posts array for immediate display
  allPosts.value = [processedNewPost, ...allPosts.value];
  updateDisplayedPosts();

  // Update newest timestamp
  if (processedNewPost.created_at) {
    newestCreatedAt.value = processedNewPost.created_at;
  }
};

// Handle new search from end of results or no results section
const handleNewSearch = () => {
  if (newSearchQuery.value && newSearchQuery.value.trim() !== "") {
    // Preserve hashtag format if present
    const query = newSearchQuery.value.trim();
    
    // Properly encode the search query for URLs, maintaining the # character for hashtags
    const encodedQuery = query.startsWith('#') 
      ? encodeURIComponent('#') + encodeURIComponent(query.substring(1))
      : encodeURIComponent(query);
    
    // Navigate to new search results
    navigateTo(`/business-network/search-results/${encodedQuery}`);
  }
};

// Search functionality
const isSearchOpen = ref(false);
const searchQuery = ref("");
const recentSearches = ref([
  "Marketing Strategy",
  "Business Development",
  "Networking Events",
  "Leadership Training",
]);
const selectedCategories = ref([]);
const searchInputRef = ref(null);

// Format time ago
const formatTimeAgo = (dateString) => {
  const date = new Date(dateString);
  const now = new Date();
  const diffInSeconds = Math.floor((now.getTime() - date.getTime()) / 1000);

  if (diffInSeconds < 60) {
    return `${Math.abs(diffInSeconds)} ${
      diffInSeconds === 1 ? "second" : "seconds"
    } ago`;
  }

  const diffInMinutes = Math.floor(diffInSeconds / 60);
  if (diffInMinutes < 60) {
    return `${Math.abs(diffInMinutes)} ${
      diffInMinutes === 1 ? "minute" : "minutes"
    } ago`;
  }

  const diffInHours = Math.floor(diffInMinutes / 60);
  if (diffInHours < 24) {
    return `${Math.abs(diffInHours)} ${
      diffInHours === 1 ? "hour" : "hours"
    } ago`;
  }

  const diffInDays = Math.floor(diffInHours / 24);
  if (diffInDays < 30) {
    return `${Math.abs(diffInDays)} ${diffInDays === 1 ? "day" : "days"} ago`;
  }

  const diffInMonths = Math.floor(diffInDays / 30);
  return `${Math.abs(diffInMonths)} ${
    diffInMonths === 1 ? "month" : "months"
  } ago`;
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

// Initialize
onMounted(() => {
  // Focus search input when overlay opens
  watch(isSearchOpen, (newVal) => {
    if (newVal) {
      nextTick(() => {
        searchInputRef.value?.focus();
      });
    }
  });
});

// Scroll to top functionality
const scrollToTop = () => {
  window.scrollTo({ top: 0, behavior: "smooth" });
};
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

/* Pull-to-refresh indicator animation */
.ptr-indicator {
  transition: transform 0.2s ease;
}

/* Enhanced pulse animations */
@keyframes pulse-wave {
  0% {
    transform: scale(0.95);
    opacity: 0.7;
  }
  50% {
    transform: scale(1);
    opacity: 1;
  }
  100% {
    transform: scale(0.95);
    opacity: 0.7;
  }
}

@keyframes pulse-slower {
  0% {
    opacity: 0.5;
  }
  50% {
    opacity: 0.3;
  }
  100% {
    opacity: 0.5;
  }
}

@keyframes ping-slow {
  75%,
  100% {
    transform: scale(1.5);
    opacity: 0;
  }
}

.animate-pulse-wave {
  animation: pulse-wave 2s ease-in-out infinite;
}

.animate-pulse-slower {
  animation: pulse-slower 3s ease-in-out infinite;
}

.animate-ping-slow {
  animation: ping-slow 2.5s cubic-bezier(0, 0, 0.2, 1) infinite;
}

/* Enhanced scrollbar for filter dropdowns */
.filter-scrollbar::-webkit-scrollbar {
  width: 4px;
}

.filter-scrollbar::-webkit-scrollbar-track {
  background: #f1f1f1;
  border-radius: 10px;
}

.filter-scrollbar::-webkit-scrollbar-thumb {
  background: #cfcfcf;
  border-radius: 10px;
}

.filter-scrollbar::-webkit-scrollbar-thumb:hover {
  background: #a0a0a0;
}

/* Professional card styling */
.result-card {
  border-radius: 8px;
  border: 1px solid rgba(226, 232, 240, 0.8);
}

.result-card:not(:last-child) {
  margin-bottom: 12px;
}
</style>
