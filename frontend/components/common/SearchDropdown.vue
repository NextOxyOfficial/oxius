<template>
  <div class="relative search-button-container">
    <button
      class="flex items-center justify-center h-9 w-9 rounded-full hover:bg-gray-100 dark:hover:bg-gray-800 transition-colors group relative overflow-hidden"
      @click="toggleSearchDropdown"
      aria-label="Search"
    >
      <SearchIcon
        class="h-[18px] w-[18px] text-gray-500 dark:text-gray-400 group-hover:text-blue-600 dark:group-hover:text-blue-400 transition-colors z-10 relative"
      />
      <!-- Ripple effect -->
      <span
        class="absolute inset-0 bg-blue-50 dark:bg-blue-900/20 transform scale-0 group-hover:scale-100 transition-transform duration-300 rounded-full"
      ></span>
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
        class="absolute top-full right-0 -mt-10 md:mt-2 w-72 sm:w-96 bg-white dark:bg-gray-800 rounded-xl shadow-professional border border-gray-200 dark:border-gray-700 overflow-hidden z-50 search-dropdown-container"
        role="dialog"
        aria-modal="true"
        aria-label="Search dialog"
        @keydown.esc="showSearchDropdown = false"
      >
        <!-- Enhanced Modern Search Header with Spelling Suggestion -->
        <div
          class="p-3 bg-gradient-to-b from-gray-50 to-white dark:from-gray-800/90 dark:to-gray-800/70 border-b border-gray-200 dark:border-gray-700 backdrop-blur-sm"
        >
          <div class="flex items-center justify-between mb-2 px-1">
            <h4
              class="text-xs uppercase tracking-wider text-gray-500 dark:text-gray-400 font-medium flex items-center"
            >
              <SearchIcon
                class="h-3 w-3 mr-1.5 text-blue-500 dark:text-blue-400"
              />
              Advanced Search
            </h4>
            <div
              class="text-xs text-gray-400 dark:text-gray-500 flex items-center"
            >
              <kbd
                class="px-1.5 py-0.5 bg-gray-100 dark:bg-gray-800 rounded text-gray-500 dark:text-gray-400 font-mono text-xs"
                >Enter</kbd
              >
              <span class="mx-1">to search</span>
            </div>
          </div>
          <div class="relative group">
            <input
              type="text"
              placeholder="Type to search people, posts, tags..."
              v-model="searchQuery"
              @keydown.enter="handleEnterKey"
              @keydown.down="focusFirstResult"
              @keydown.up="focusViewAllButton"
              class="w-full pl-10 pr-10 py-3 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-blue-500/50 dark:focus:ring-blue-500/70 border border-gray-200 dark:border-gray-700 bg-white dark:bg-gray-900 text-gray-700 dark:text-gray-300 transition-all duration-300 shadow-sm search-input"
              ref="searchInput"
              aria-label="Search query"
            />
            <div
              class="absolute left-3 top-3 text-gray-400 dark:text-gray-500 transition-colors group-focus-within:text-blue-500 dark:group-focus-within:text-blue-400"
            >
              <SearchIcon class="h-[18px] w-[18px]" />
            </div>

            <div class="absolute right-3 top-3 flex items-center gap-2">
              <span v-if="isLoading" class="loading-spinner"></span>
              <button
                v-if="searchQuery"
                @click="clearSearch"
                class="rounded-full hover:bg-gray-100 dark:hover:bg-gray-700 p-1 transition-colors group"
              >
                <XIcon
                  class="h-4 w-4 text-gray-400 dark:text-gray-500 group-hover:text-gray-600 dark:group-hover:text-gray-300"
                />
              </button>
            </div>
          </div>

          <!-- Enhanced Spelling suggestion banner with animation -->
          <div
            v-if="spellingSuggestion && searchQuery"
            class="mt-2 px-1 animate-fadeIn"
          >
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
          class="max-h-[57vh] overflow-y-auto search-results-container"
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
                class="p-3 hover:bg-blue-50/40 dark:hover:bg-blue-900/10 cursor-pointer transition-all duration-200 rounded-lg mx-1 mb-1 group border border-transparent hover:border-blue-100 dark:hover:border-blue-800/30"
                @click="navigateToPost(result)"
              >
                <!-- Post content with enhanced styling -->
                <div class="flex items-start justify-between gap-3">
                  <!-- Left side icon container -->
                  <div class="flex-shrink-0 mt-1">
                    <div
                      class="w-8 h-8 rounded-md bg-gradient-to-br from-blue-50 to-blue-100 dark:from-blue-900/20 dark:to-blue-800/20 border border-blue-200/50 dark:border-blue-800/30 flex items-center justify-center group-hover:from-blue-100 group-hover:to-blue-200/70 dark:group-hover:from-blue-800/30 dark:group-hover:to-blue-700/20 transition-colors"
                    >
                      <svg
                        xmlns="http://www.w3.org/2000/svg"
                        class="w-4 h-4 text-blue-500 dark:text-blue-400"
                        fill="none"
                        viewBox="0 0 24 24"
                        stroke="currentColor"
                      >
                        <path
                          stroke-linecap="round"
                          stroke-linejoin="round"
                          stroke-width="2"
                          d="M19 20H5a2 2 0 01-2-2V6a2 2 0 012-2h10a2 2 0 012 2v1m2 13a2 2 0 01-2-2V7m2 13a2 2 0 002-2V9a2 2 0 00-2-2h-2m-4-3H9M7 16h6M7 8h6v4H7V8z"
                        />
                      </svg>
                    </div>
                  </div>

                  <div class="flex-1 min-w-0">
                    <!-- Highlighted title with keyword matches and improved styling -->
                    <p
                      class="text-sm font-medium text-gray-800 dark:text-gray-200 group-hover:text-blue-600 dark:group-hover:text-blue-400 transition-colors line-clamp-2"
                    >
                      <span
                        v-html="highlightMatches(result.title, searchQuery)"
                      ></span>
                    </p>

                    <!-- Content preview with highlighted matches and improved styling -->
                    <p
                      v-if="result.post_text || result.content"
                      class="text-xs text-gray-500 dark:text-gray-400 mt-1 line-clamp-2"
                    >
                      <span
                        v-html="
                          getContentPreview(
                            result.post_text || result.content,
                            searchQuery
                          )
                        "
                      ></span>
                    </p>
                    <!-- Enhanced tag section with animation on hover -->
                    <div class="flex flex-wrap gap-1.5 mt-2">
                      <span
                        v-for="tag in result.post_tags"
                        :key="tag.id"
                        class="inline-flex items-center px-2 py-0.5 rounded-full text-xs font-medium transition-all duration-200"
                        :class="
                          isTagMatched(tag.tag, searchQuery)
                            ? 'bg-blue-100 dark:bg-blue-900/50 text-blue-700 dark:text-blue-300 border border-blue-200 dark:border-blue-800/50 group-hover:bg-blue-200 dark:group-hover:bg-blue-800/40'
                            : 'bg-gray-100 dark:bg-gray-800/80 text-gray-500 dark:text-gray-400 border border-gray-200/60 dark:border-gray-700/50 group-hover:bg-gray-200/80 dark:group-hover:bg-gray-700/50'
                        "
                      >
                        <span class="mr-0.5 opacity-60">#</span
                        ><span
                          v-html="highlightMatches(tag.tag, searchQuery)"
                        ></span>
                      </span>
                    </div>

                    <!-- Post date if available -->
                    <div
                      v-if="result.created_at"
                      class="flex items-center mt-1.5"
                    >
                      <span
                        class="text-xs text-gray-400 dark:text-gray-500 flex items-center"
                      >
                        <svg
                          xmlns="http://www.w3.org/2000/svg"
                          class="h-3 w-3 mr-1"
                          fill="none"
                          viewBox="0 0 24 24"
                          stroke="currentColor"
                        >
                          <path
                            stroke-linecap="round"
                            stroke-linejoin="round"
                            stroke-width="2"
                            d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z"
                          />
                        </svg>
                        {{ formatTimeAgo(result.created_at) }}
                      </span>
                    </div>
                  </div>

                  <div class="flex-shrink-0 self-center">
                    <div
                      class="h-7 w-7 rounded-full bg-gray-100 dark:bg-gray-800 flex items-center justify-center group-hover:bg-blue-100 dark:group-hover:bg-blue-900/30 transition-all shadow-sm"
                    >
                      <ArrowRight
                        class="h-3.5 w-3.5 text-gray-500 dark:text-gray-500 group-hover:text-blue-600 dark:group-hover:text-blue-400 transition-all transform group-hover:translate-x-0.5"
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
                class="p-3 hover:bg-blue-50/40 dark:hover:bg-blue-900/10 cursor-pointer transition-all duration-200 rounded-lg mx-1 mb-1 group border border-transparent hover:border-blue-100 dark:hover:border-blue-800/30"
                @click="navigateToProfile(person)"
              >
                <!-- Person card with avatar and details -->
                <div class="flex items-center">
                  <!-- Avatar with enhanced styling and fallback -->
                  <div class="flex-shrink-0 relative">
                    <div
                      class="w-10 h-10 rounded-full overflow-hidden bg-gradient-to-br from-gray-100 to-gray-200 dark:from-gray-700 dark:to-gray-800 p-[2px] group-hover:from-blue-100 group-hover:to-blue-50 dark:group-hover:from-blue-900/30 dark:group-hover:to-blue-800/30 transition-all"
                    >
                      <img
                        v-if="
                          person.image ||
                          person.avatar_url ||
                          person.profile_image
                        "
                        :src="
                          person.image ||
                          person.avatar_url ||
                          person.profile_image
                        "
                        :alt="person.name || 'User'"
                        class="h-full w-full rounded-full object-contain border-2 border-white dark:border-gray-800"
                      />
                      <div
                        v-else
                        class="h-full w-full rounded-full bg-blue-500/10 dark:bg-blue-500/20 flex items-center justify-center text-blue-600 dark:text-blue-400 font-semibold"
                      >
                        {{ (person.name?.charAt(0) || "U").toUpperCase() }}
                      </div>
                    </div>

                    <!-- Status indicators - Online, Pro, Verified -->
                    <div class="absolute -bottom-1 -right-1 flex space-x-0.5">
                      <!-- Online status indicator (green dot) -->
                      <div
                        v-if="person.is_online"
                        class="w-3 h-3 rounded-full bg-green-400 border-2 border-white dark:border-gray-800 animate-pulse"
                      ></div>

                      <!-- Pro badge if user is a pro member -->
                      <div
                        v-if="person.is_pro || person.pro_badge"
                        class="w-4 h-4 rounded-full bg-gradient-to-r from-amber-500 to-yellow-400 border border-amber-200 dark:border-amber-900/40 flex items-center justify-center shadow-sm"
                        title="Pro Member"
                      >
                        <span class="text-xs text-white font-bold">PRO</span>
                      </div>
                    </div>
                  </div>

                  <!-- User info with more detailed display -->
                  <div class="ml-3 flex-1 min-w-0">
                    <div class="flex items-center gap-1">
                      <p
                        class="text-sm font-medium text-gray-700 dark:text-gray-200 group-hover:text-blue-600 dark:group-hover:text-blue-400 transition-colors inline-flex items-center"
                      >
                        <span
                          v-html="
                            highlightMatches(
                              person.name || 'Unknown User',
                              searchQuery
                            )
                          "
                        ></span>
                        <!-- Verification badge -->
                        <span
                          v-if="person.is_verified || person.verified_badge"
                          class="inline-block ml-1"
                          title="Verified Account"
                        >
                          <span
                            class="flex items-center justify-center w-4 h-4 bg-blue-500 dark:bg-blue-600 rounded-full"
                          >
                            <svg
                              xmlns="http://www.w3.org/2000/svg"
                              viewBox="0 0 24 24"
                              class="w-2.5 h-2.5 text-white fill-current"
                            >
                              <path
                                d="M9 16.17L4.83 12l-1.42 1.41L9 19 21 7l-1.41-1.41L9 16.17z"
                              ></path>
                            </svg>
                          </span>
                        </span>
                      </p>
                    </div>
                    <div
                      class="flex flex-wrap items-center text-xs text-gray-500 dark:text-gray-500"
                    >
                      <!-- Professional information with icon -->
                      <span
                        v-if="
                          person.title ||
                          person.profession ||
                          person.position ||
                          person.headline
                        "
                        class="flex items-center"
                      >
                        <svg
                          xmlns="http://www.w3.org/2000/svg"
                          class="h-3 w-3 mr-0.5 opacity-70"
                          fill="none"
                          viewBox="0 0 24 24"
                          stroke="currentColor"
                        >
                          <path
                            strokeLinecap="round"
                            strokeLinejoin="round"
                            strokeWidth="{2}"
                            d="M21 13.255A23.931 23.931 0 0112 15c-3.183 0-6.22-.62-9-1.745M16 6V4a2 2 0 00-2-2h-4a2 2 0 00-2 2v2m4 6h.01M5 20h14a2 2 0 002-2V8a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z"
                          />
                        </svg>
                        <span
                          class="truncate max-w-[120px]"
                          v-html="
                            highlightMatches(
                              person.title ||
                                person.profession ||
                                person.position ||
                                person.headline,
                              searchQuery
                            )
                          "
                        ></span>
                      </span>

                      <!-- Followers count -->
                      <span
                        v-if="person.followers !== undefined"
                        class="flex items-center"
                      >
                        <span
                          v-if="
                            person.title ||
                            person.profession ||
                            person.position ||
                            person.headline
                          "
                          class="mx-1.5 opacity-40"
                          >•</span
                        >
                        <User class="h-3 w-3 mr-0.5 opacity-70" />
                        <span>
                          {{ person.followers }}
                          <span class="opacity-80">{{
                            person.followers === 1 ? "follower" : "followers"
                          }}</span>
                        </span>
                      </span>

                      <!-- Location information if available -->
                      <span v-if="person.location" class="flex items-center">
                        <span class="mx-1.5 opacity-40">•</span>
                        <svg
                          xmlns="http://www.w3.org/2000/svg"
                          class="h-3 w-3 mr-0.5 opacity-70"
                          fill="none"
                          viewBox="0 0 24 24"
                          stroke="currentColor"
                        >
                          <path
                            stroke-linecap="round"
                            stroke-linejoin="round"
                            stroke-width="2"
                            d="M17.657 16.657L13.414 20.9a1.998 1.998 0 01-2.827 0l-4.244-4.243a8 8 0 1111.314 0z"
                          />
                          <path
                            stroke-linecap="round"
                            stroke-linejoin="round"
                            stroke-width="2"
                            d="M15 11a3 3 0 11-6 0 3 3 0 016 0z"
                          />
                        </svg>
                        <span>{{ person.location }}</span>
                      </span>
                    </div>
                  </div>

                  <!-- Action button with enhanced styling -->
                  <div
                    class="flex-shrink-0"
                    v-if="person?.id !== user?.user?.id && user"
                    :ref="(el) => registerObserver(el, person.id)"
                    @click.stop
                  >
                    <button
                      class="h-7 w-7 rounded-full bg-gray-100 dark:bg-gray-800 flex items-center justify-center group-hover:bg-blue-100 dark:group-hover:bg-blue-900/30 transition-all shadow-sm hover:shadow"
                      @click="toggleFollow(person.id)"
                    >
                      <UserPlus
                        v-if="!followingStatus[person.id]"
                        class="h-3.5 w-3.5 text-gray-600 dark:text-gray-400 group-hover:text-blue-600 dark:group-hover:text-blue-400 transition-colors"
                      />
                      <User
                        v-else
                        class="h-3.5 w-3.5 text-blue-600 dark:text-blue-400 transition-colors"
                      />
                    </button>
                  </div>
                </div>
              </div>
            </template>
          </div>
        </div>
        <div
          class="flex justify-center p-3 border-t border-gray-100 dark:border-gray-800 bg-gradient-to-b from-gray-50/80 to-gray-50 dark:from-gray-800/50 dark:to-gray-800/80"
        >
          <button
            @click="viewAllResults"
            class="view-all-button inline-flex items-center justify-center gap-1.5 py-2.5 px-4 text-sm font-medium text-white dark:text-gray-900 bg-gradient-to-r from-blue-500 to-blue-600 dark:from-blue-400 dark:to-blue-500 hover:from-blue-600 hover:to-blue-700 dark:hover:from-blue-500 dark:hover:to-blue-600 rounded-md transition-all duration-300 w-full shadow-sm hover:shadow relative overflow-hidden group"
            tabindex="0"
            ref="viewAllButton"
          >
            <span class="relative z-10 flex items-center">
              View all results
              <ArrowRight
                class="h-3.5 w-3.5 ml-1.5 transform group-hover:translate-x-0.5 transition-transform"
              />
            </span>
            <span
              class="absolute inset-0 bg-white/10 dark:bg-black/10 transform -translate-x-full group-hover:translate-x-0 transition-transform duration-300"
            ></span>
          </button>
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

// Handle Enter key press in search input
const handleEnterKey = (event) => {
  // If search query exists, navigate to search results
  if (searchQuery.value.trim()) {
    viewAllResults();
    event.preventDefault();
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

// Focus the first search result for keyboard navigation
const focusFirstResult = () => {
  nextTick(() => {
    // Find the first result element based on the active tab
    let firstResultElement = null;
    if (activeTab.value === "all" || activeTab.value === "posts") {
      if (filteredPosts.value.length > 0) {
        firstResultElement = document.querySelector(
          '.search-results-container [key^="post-"]'
        );
      } else if (filteredPeople.value.length > 0) {
        firstResultElement = document.querySelector(
          '.search-results-container [key^="person-"]'
        );
      }
    } else if (
      activeTab.value === "people" &&
      filteredPeople.value.length > 0
    ) {
      firstResultElement = document.querySelector(
        '.search-results-container [key^="person-"]'
      );
    } else if (activeTab.value === "posts" && filteredPosts.value.length > 0) {
      firstResultElement = document.querySelector(
        '.search-results-container [key^="post-"]'
      );
    }

    if (firstResultElement) {
      firstResultElement.focus();
      firstResultElement.setAttribute("tabindex", "0");
    }
  });
};

// Focus the "View all results" button
const focusViewAllButton = () => {
  nextTick(() => {
    const viewAllButton = document.querySelector(".view-all-button");
    if (viewAllButton) {
      viewAllButton.focus();
    }
  });
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

// Format date to relative time ago
const formatTimeAgo = (dateString) => {
  const date = new Date(dateString);
  const now = new Date();
  const diffInSeconds = Math.floor((now - date) / 1000);

  if (diffInSeconds < 60) {
    return `${diffInSeconds} second${diffInSeconds !== 1 ? "s" : ""} ago`;
  }

  const diffInMinutes = Math.floor(diffInSeconds / 60);
  if (diffInMinutes < 60) {
    return `${diffInMinutes} minute${diffInMinutes !== 1 ? "s" : ""} ago`;
  }

  const diffInHours = Math.floor(diffInMinutes / 60);
  if (diffInHours < 24) {
    return `${diffInHours} hour${diffInHours !== 1 ? "s" : ""} ago`;
  }

  const diffInDays = Math.floor(diffInHours / 24);
  if (diffInDays < 30) {
    return `${diffInDays} day${diffInDays !== 1 ? "s" : ""} ago`;
  }

  const diffInMonths = Math.floor(diffInDays / 30);
  if (diffInMonths < 12) {
    return `${diffInMonths} month${diffInMonths !== 1 ? "s" : ""} ago`;
  }

  const diffInYears = Math.floor(diffInMonths / 12);
  return `${diffInYears} year${diffInYears !== 1 ? "s" : ""} ago`;
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

    const postResults = postsRes.data?.results || []; // Process people results to ensure we have the required fields
    let peopleResults = [];
    if (peopleRes.data?.results && Array.isArray(peopleRes.data.results)) {
      peopleResults = peopleRes.data.results.map((person) => {
        // Add default values for missing fields
        return {
          id: person.id,
          name: person.name || "Unknown User",
          // Support multiple avatar/image field names from API
          avatar_url:
            person.image || person.avatar_url || person.profile_image || null,
          // Get followers count from various possible API fields
          followers: person.follower_count || person.followers || 0,
          // Professional information from various possible API fields
          title:
            person.profession ||
            person.position ||
            person.headline ||
            person.bio ||
            "",
          // Location info if available
          location: person.location || person.city || "",

          // User status and badges
          is_following: !!person.is_following,
          is_verified:
            !!person.is_verified ||
            !!person.verified ||
            !!person.verified_badge,
          is_pro: !!person.is_pro || !!person.pro_user || !!person.pro_badge,
          is_online: !!person.is_online || !!person.online_status,

          // Preserve all original fields from the API
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
  -webkit-backdrop-filter: blur(8px);
}

/* Professional shadow for dropdown */
.shadow-professional {
  box-shadow: 0 10px 25px -5px rgba(0, 0, 0, 0.1),
    0 8px 10px -6px rgba(0, 0, 0, 0.05), 0 0 0 1px rgba(0, 0, 0, 0.05);
}

/* Loading spinner animation with enhanced design */
.loading-spinner {
  display: inline-block;
  width: 18px;
  height: 18px;
  border: 2px solid rgba(59, 130, 246, 0.2);
  border-radius: 50%;
  border-top-color: rgba(59, 130, 246, 0.8);
  box-shadow: 0 0 0 1px rgba(59, 130, 246, 0.1);
  animation: spin 0.8s linear infinite;
}

@keyframes spin {
  to {
    transform: rotate(360deg);
  }
}

/* Enhanced search input focus styles */
.search-input:focus {
  box-shadow: 0 0 0 3px rgba(59, 130, 246, 0.25);
  border-color: rgba(59, 130, 246, 0.4);
}

/* Enhanced scrollbar for search results with smoother appearance */
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
  transition: background-color 0.3s;
}

.search-results-container::-webkit-scrollbar-thumb:hover {
  background-color: rgba(156, 163, 175, 0.8);
}

/* Mobile adjustments with improved fixed positioning */
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
    max-height: 80vh;
  }
}

/* Keyword highlight animation with subtle pulse */
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
    opacity: 0.85;
  }
}

/* Fade in animation for new elements */
@keyframes fadeIn {
  from {
    opacity: 0;
    transform: translateY(5px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}

.animate-fadeIn {
  animation: fadeIn 0.3s ease-out forwards;
}

/* View all button hover effect */
.view-all-button:hover {
  transform: translateY(-1px);
  box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.1),
    0 2px 4px -1px rgba(0, 0, 0, 0.06);
}

.view-all-button:active {
  transform: translateY(0);
}

/* Improve line clamp for multi-line text */
.line-clamp-2 {
  display: -webkit-box;
  -webkit-line-clamp: 2;
  line-clamp: 2;
  -webkit-box-orient: vertical;
  overflow: hidden;
  word-break: break-word;
}

/* Fix for v-html content styling */
:deep(span) {
  vertical-align: middle;
}

/* Improve focus handling for keyboard navigation */
.view-all-button:focus,
.search-input:focus {
  outline: none;
  box-shadow: 0 0 0 3px rgba(59, 130, 246, 0.3);
}

/* Modern keyboard styles */
kbd {
  box-shadow: 0 1px 1px rgba(0, 0, 0, 0.1);
}

/* Badge animations and effects */
@keyframes gentle-pulse {
  0%,
  100% {
    opacity: 0.9;
    transform: scale(1);
  }
  50% {
    opacity: 1;
    transform: scale(1.05);
  }
}

.animate-pulse {
  animation: gentle-pulse 2s infinite;
}

/* Pro badge glow effect */
[title="Pro Member"] {
  box-shadow: 0 0 0 rgba(245, 158, 11, 0.4);
  animation: pro-pulse 2s infinite;
}

@keyframes pro-pulse {
  0% {
    box-shadow: 0 0 0 0 rgba(245, 158, 11, 0.4);
  }
  70% {
    box-shadow: 0 0 0 4px rgba(245, 158, 11, 0);
  }
  100% {
    box-shadow: 0 0 0 0 rgba(245, 158, 11, 0);
  }
}

/* Verification badge subtle animation */
[title="Verified Account"] svg {
  animation: verified-rotate 10s infinite linear;
  transform-origin: center;
}

@keyframes verified-rotate {
  0% {
    transform: rotateY(0deg);
  }
  25% {
    transform: rotateY(90deg);
  }
  50% {
    transform: rotateY(180deg);
  }
  75% {
    transform: rotateY(270deg);
  }
  100% {
    transform: rotateY(360deg);
  }
}
</style>
