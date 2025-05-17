<template>
  <div
    class="mx-auto px-1 sm:px-6 lg:px-8 max-w-7xl mt-16 pt-3 flex-1 bg-gradient"
  >
    <!-- Skeleton loader for the entire profile page -->
    <template v-if="isLoading">
      <div class="max-w-3xl mx-auto relative z-10 sm:px-0">
        <!-- Skeleton for Profile Card -->
        <div
          class="bg-white/90 backdrop-blur-sm rounded-xl shadow-sm border border-gray-200/50 mb-6 animate-pulse"
        >
          <div class="p-4 sm:p-5">
            <!-- Desktop Layout Skeleton -->
            <div
              class="flex flex-col sm:flex-row sm:items-start gap-1 sm:gap-7"
            >
              <!-- Profile Picture Skeleton -->
              <div class="flex flex-col items-center sm:items-start">
                <div
                  class="size-36 rounded-full border-2 border-white shadow-sm bg-gray-200"
                ></div>

                <!-- User Stats Skeleton (Mobile) -->
                <div
                  class="flex w-full justify-center sm:hidden mt-4 space-x-6"
                >
                  <div class="text-center">
                    <div class="h-5 w-8 bg-gray-200 rounded mb-1 mx-auto"></div>
                    <div class="h-4 w-12 bg-gray-200 rounded mx-auto"></div>
                  </div>
                  <div class="text-center">
                    <div class="h-5 w-8 bg-gray-200 rounded mb-1 mx-auto"></div>
                    <div class="h-4 w-12 bg-gray-200 rounded mx-auto"></div>
                  </div>
                  <div class="text-center">
                    <div class="h-5 w-8 bg-gray-200 rounded mb-1 mx-auto"></div>
                    <div class="h-4 w-12 bg-gray-200 rounded mx-auto"></div>
                  </div>
                </div>
              </div>

              <!-- User Info Skeleton -->
              <div class="flex-1">
                <!-- Header Skeleton -->
                <div
                  class="hidden sm:flex sm:flex-row sm:items-start sm:justify-between"
                >
                  <div class="flex-1">
                    <div class="h-7 bg-gray-200 rounded w-1/4 mb-2"></div>
                    <div class="h-5 bg-gray-200 rounded w-1/3 mb-1"></div>
                    <div class="h-4 bg-gray-200 rounded w-1/5"></div>
                  </div>

                  <!-- Action buttons Skeleton -->
                  <div class="hidden sm:flex space-x-2">
                    <div class="h-8 w-24 bg-gray-200 rounded"></div>
                    <div class="h-8 w-10 bg-gray-200 rounded"></div>
                  </div>
                </div>

                <!-- User Stats Skeleton (Desktop) -->
                <div
                  class="hidden sm:flex items-center mt-3 mb-3 border-b border-gray-100 pb-3"
                >
                  <div class="flex items-center gap-6">
                    <div class="h-5 w-20 bg-gray-200 rounded"></div>
                    <div class="h-5 w-24 bg-gray-200 rounded"></div>
                    <div class="h-5 w-24 bg-gray-200 rounded"></div>
                  </div>
                </div>

                <!-- Bio Skeleton -->
                <div
                  class="mt-3 sm:mt-0 border-t sm:border-t-0 pt-3 sm:pt-0 border-gray-100"
                >
                  <div class="h-4 bg-gray-200 rounded w-full mb-2"></div>
                  <div class="h-4 bg-gray-200 rounded w-5/6"></div>
                </div>

                <!-- Contact Info Skeleton -->
                <div
                  class="grid grid-cols-1 sm:grid-cols-2 gap-x-4 gap-y-2 mt-3"
                >
                  <div class="flex items-center gap-1.5">
                    <div class="h-4 w-4 bg-gray-200 rounded-full"></div>
                    <div class="h-4 bg-gray-200 rounded w-3/4"></div>
                  </div>
                  <div class="flex items-center gap-1.5">
                    <div class="h-4 w-4 bg-gray-200 rounded-full"></div>
                    <div class="h-4 bg-gray-200 rounded w-3/4"></div>
                  </div>
                  <div class="flex items-center gap-1.5">
                    <div class="h-4 w-4 bg-gray-200 rounded-full"></div>
                    <div class="h-4 bg-gray-200 rounded w-3/4"></div>
                  </div>
                  <div class="flex items-center gap-1.5">
                    <div class="h-4 w-4 bg-gray-200 rounded-full"></div>
                    <div class="h-4 bg-gray-200 rounded w-3/4"></div>
                  </div>
                </div>

                <!-- Social Media Skeleton -->
                <div class="mt-3 pt-3 border-t border-gray-100">
                  <div
                    class="grid grid-cols-2 sm:flex sm:flex-wrap gap-2 sm:gap-3"
                  >
                    <div class="flex items-center gap-1.5">
                      <div class="h-4 w-4 bg-gray-200 rounded"></div>
                      <div class="h-4 bg-gray-200 rounded w-20"></div>
                    </div>
                    <div class="flex items-center gap-1.5">
                      <div class="h-4 w-4 bg-gray-200 rounded"></div>
                      <div class="h-4 bg-gray-200 rounded w-20"></div>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>

        <!-- Skeleton for Tabs Section -->
        <div
          class="bg-white/90 backdrop-blur-sm rounded-xl shadow-sm border border-gray-200/50 overflow-hidden"
        >
          <!-- Tabs Skeleton -->
          <div class="border-b border-gray-200">
            <div class="flex items-center">
              <div class="h-10 w-20 bg-gray-200 rounded m-2"></div>
              <div class="h-10 w-20 bg-gray-200 rounded m-2"></div>
              <div class="h-10 w-20 bg-gray-200 rounded m-2"></div>
            </div>
          </div>

          <!-- Tab Content Skeleton -->
          <div class="py-4">
            <div class="px-2">
              <!-- Skeleton loaders for posts -->
              <div
                v-for="i in 2"
                :key="i"
                class="bg-white rounded-xl border border-gray-200 overflow-hidden mb-4 p-4"
              >
                <div class="flex items-center space-x-3 mb-4">
                  <div
                    class="w-12 h-12 rounded-full bg-gray-200 animate-pulse"
                  ></div>
                  <div class="flex-1 space-y-2">
                    <div
                      class="h-4 bg-gray-200 rounded animate-pulse w-1/4"
                    ></div>
                    <div
                      class="h-3 bg-gray-200 rounded animate-pulse w-1/5"
                    ></div>
                  </div>
                </div>
                <div class="space-y-2 mb-4">
                  <div
                    class="h-4 bg-gray-200 rounded animate-pulse w-3/4"
                  ></div>
                  <div
                    class="h-3 bg-gray-200 rounded animate-pulse w-full"
                  ></div>
                  <div
                    class="h-3 bg-gray-200 rounded animate-pulse w-5/6"
                  ></div>
                </div>
                <div class="h-40 bg-gray-200 rounded animate-pulse mb-4"></div>
                <div class="flex justify-between">
                  <div
                    class="h-8 bg-gray-200 rounded animate-pulse w-1/4"
                  ></div>
                  <div
                    class="h-8 bg-gray-200 rounded animate-pulse w-1/4"
                  ></div>
                  <div
                    class="h-8 bg-gray-200 rounded animate-pulse w-1/4"
                  ></div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </template>

    <!-- Actual profile content -->
    <div v-else class="max-w-3xl mx-auto relative z-10 sm:px-0">
      <!-- Professional Profile Card with Premium Design -->
      <div
        class="bg-white/95 backdrop-blur-md rounded-xl shadow-sm border border-gray-200/50 mb-6 animate-fadeIn overflow-hidden relative"
      >
        <!-- Background gradient pattern for added premium feel -->
        <div
          class="absolute inset-0 bg-gradient-to-br from-blue-50/30 to-indigo-50/30 pointer-events-none"
        ></div>
        <div class="absolute inset-0 opacity-5 bg-pattern"></div>

        <div class="p-2 py-5 sm:p-8 relative">
          <!-- Mobile Profile Header (Mobile Only) -->
          <div class="flex sm:hidden items-center justify-between mb-4">
            <div>
              <h1 class="text-xl font-semibold flex items-center gap-1.5">
                {{ user?.name }}
                <div class="relative inline-flex tooltip-container">
                  <UIcon
                    v-if="user?.kyc"
                    name="i-mdi-check-decagram"
                    class="w-4 h-4 text-blue-600 animate-pulse-subtle"
                  />
                  <div class="tooltip-content">Verified</div>
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
                <!-- Verified badge for mobile -->
              </h1>
              <p class="text-sm font-medium text-gray-500 mb-0.5">
                {{ user?.profession }}
              </p>
            </div>

            <div class="flex gap-2">
              <!-- Action buttons for mobile -->
              <button
                v-if="user?.id !== currentUser?.user?.id && currentUser"
                :class="[
                  'px-3 py-1 rounded text-xs font-medium flex items-center gap-1 transition-all duration-300',
                  isFollowing
                    ? 'border border-gray-200 hover:bg-gray-50 hover:shadow-sm text-gray-700'
                    : 'bg-gradient-to-r from-blue-600 to-indigo-600 hover:from-blue-700 hover:to-indigo-700 hover:shadow-sm text-white',
                ]"
                :disabled="followLoading"
                @click="toggleFollow"
              >
                <div
                  v-if="followLoading"
                  class="h-3 w-3 border-2 border-t-transparent border-white rounded-full animate-spin"
                ></div>

                <template v-else-if="isFollowing">
                  <Check class="h-3 w-3 animate-scaleIn" />
                  Unfollow
                </template>

                <template v-else>
                  <UserPlus class="h-3 w-3 animate-scaleIn" />
                  Follow
                </template>
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
                    class="size-44 rounded-full border-4 border-white shadow-sm bg-white overflow-hidden relative z-10"
                  >
                    <img
                      :src="
                        user?.image || '/static/frontend/images/placeholder.jpg'
                      "
                      :alt="user?.name"
                      class="w-full h-full object-cover transition-all duration-500 group-hover:scale-105"
                      loading="lazy"
                    />
                  </div>
                </div>
              </div>

              <!-- User Stats for Mobile -->
              <div class="flex w-full justify-center sm:hidden mt-4 space-x-6">
                <div
                  class="text-center hover:scale-105 transition-transform cursor-pointer"
                >
                  <div class="text-base font-semibold">
                    {{ user?.post_count || 0 }}
                  </div>
                  <div class="text-sm font-medium text-gray-500">Posts</div>
                </div>
                <div
                  class="text-center hover:scale-105 transition-transform cursor-pointer"
                >
                  <div class="text-base font-semibold">
                    {{ user?.followers_count || 0 }}
                  </div>
                  <div class="text-sm font-medium text-gray-500">Followers</div>
                </div>
                <div
                  class="text-center hover:scale-105 transition-transform cursor-pointer"
                >
                  <div class="text-base font-semibold">
                    {{ user?.following_count || 0 }}
                  </div>
                  <div class="text-sm font-medium text-gray-500">Following</div>
                </div>
              </div>

              <!-- Diamond count and top-up button for mobile -->
              <div
                v-if="currentUser?.user?.id === user?.id"
                class="flex items-center gap-3 mt-4 sm:hidden"
              >
                <div class="flex items-center space-x-2 py-1.5">
                  <UIcon name="i-mdi-diamond" class="text-pink-500 w-4 h-4" />
                  <span class="font-semibold text-md"
                    >{{ user?.diamond_balance }} Diamonds</span
                  >
                </div>
                <button
                  @click="showDiamondModal = true"
                  class="text-xs bg-gradient-to-r from-pink-500 to-purple-500 text-white rounded-full px-4 py-1.5 hover:from-pink-600 hover:to-purple-600 flex items-center gap-1.5 transition-all shadow-sm hover:shadow"
                >
                  <UIcon name="i-heroicons-plus" class="w-3 h-3" />
                  <span>Top Up</span>
                </button>
              </div>
            </div>

            <!-- User Info -->
            <div class="flex-1">
              <!-- Desktop Header (Hidden on Mobile) -->
              <div
                class="hidden sm:flex sm:flex-row sm:items-start sm:justify-between"
              >
                <div>
                  <div class="flex items-center flex-wrap gap-1.5">
                    <h1 class="text-xl font-semibold">{{ user?.name }}</h1>
                    <!-- Verified badge -->
                    <div class="relative inline-flex tooltip-container">
                      <UIcon
                        v-if="user?.kyc"
                        name="i-mdi-check-decagram"
                        class="w-4 h-4 text-blue-600 animate-pulse-subtle"
                        data-tooltip="Verified"
                      />
                      <div class="tooltip-content">Verified</div>
                    </div>

                    <!-- Pro badge -->
                    <span
                      v-if="user?.is_pro"
                      class="px-1.5 py-0.5 bg-gradient-to-r from-indigo-600 to-blue-600 text-white rounded-full text-xs font-medium shadow-sm"
                    >
                      <div class="flex items-center gap-1">
                        <UIcon name="i-heroicons-shield-check" class="size-3" />
                        <span class="text-2xs">Pro</span>
                      </div>
                    </span>

                    <!-- Top contributor badge -->
                    <span
                      v-if="user?.is_topcontributor"
                      class="px-1.5 py-0.5 bg-gradient-to-r from-amber-500 to-yellow-500 text-white rounded-full text-xs font-medium shadow-sm"
                    >
                      <div class="flex items-center gap-1">
                        <Trophy class="size-3" />
                        <span class="text-2xs">Top Contributor</span>
                      </div>
                    </span>
                  </div>
                  <p class="text-sm font-medium text-gray-500 mb-0.5">
                    {{ user?.profession }}
                  </p>
                </div>

                <!-- Action buttons (Desktop) -->
                <div class="hidden sm:flex">
                  <button
                    v-if="user?.id !== currentUser?.user?.id && currentUser"
                    :class="[
                      'px-3 py-1.5 rounded text-xs font-medium flex items-center gap-1.5 transition-all duration-300',
                      isFollowing
                        ? 'border border-gray-200 hover:bg-gray-50 hover:shadow-sm text-gray-700'
                        : 'bg-gradient-to-r from-blue-600 to-indigo-600 hover:from-blue-700 hover:to-indigo-700 hover:shadow-sm text-white',
                    ]"
                    :disabled="followLoading"
                    @click="toggleFollow"
                  >
                    <div
                      v-if="followLoading"
                      class="h-3 w-3 border-2 border-t-transparent border-white rounded-full animate-spin"
                    ></div>
                    <template v-else-if="isFollowing">
                      <Check class="h-3 w-3 animate-scaleIn" />
                      Unfollow
                    </template>
                    <template v-else>
                      <UserPlus class="h-3 w-3 animate-scaleIn" />
                      Follow
                    </template>
                  </button>
                </div>
              </div>

              <!-- User Stats (Desktop) -->
              <div
                class="hidden sm:flex sm:flex-col items-start mt-3 mb-3 gap-1 border-b border-gray-100 pb-3"
              >
                <div class="flex items-center gap-3 text-sm">
                  <div
                    class="flex items-center hover:scale-105 transition-transform cursor-pointer"
                  >
                    <span class="font-semibold">{{
                      user?.post_count || 0
                    }}</span>
                    <span class="text-gray-500 ml-1.5">Posts</span>
                  </div>
                  <div
                    class="flex items-center hover:scale-105 transition-transform cursor-pointer"
                  >
                    <span class="font-semibold">{{
                      user?.followers_count || 0
                    }}</span>
                    <span class="text-gray-500 ml-1.5">Followers</span>
                  </div>
                  <div
                    class="flex items-center hover:scale-105 transition-transform cursor-pointer"
                  >
                    <span class="font-semibold">{{
                      user?.following_count || 0
                    }}</span>
                    <span class="text-gray-500 ml-1.5">Following</span>
                  </div>
                </div>
                <div
                  v-if="currentUser?.user?.id === user?.id"
                  class="flex items-center space-x-2"
                >
                  <div
                    class="flex items-center hover:scale-105 transition-transform cursor-pointer gap-1"
                  >
                    <UIcon name="i-mdi-diamond" class="text-pink-500 w-4 h-4" />
                    <span class="font-semibold">{{
                      user?.diamond_balance
                    }}</span>
                    <span>Diamonds</span>
                  </div>
                  <button
                    @click="showDiamondModal = true"
                    class="text-xs bg-gradient-to-r from-pink-500 to-purple-500 text-white rounded-full px-4 py-1.5 hover:from-pink-600 hover:to-purple-600 flex items-center gap-1.5 transition-all shadow-sm hover:shadow"
                  >
                    <UIcon name="i-heroicons-plus" class="w-3 h-3" />
                    <span>Top Up</span>
                  </button>
                </div>
              </div>
              <!-- Diamond count and top-up button for desktop -->

              <!-- Bio -->
              <div
                class="mt-3 sm:mt-0 border-t sm:border-t-0 pt-3 sm:pt-0 border-gray-100"
              >
                <p
                  v-if="user?.about"
                  class="text-sm font-medium text-gray-500 mb-3 leading-relaxed"
                >
                  {{ user?.about }}
                </p>
                <p v-else class="text-sm text-gray-500 italic mb-3">
                  No bio provided
                </p>
              </div>

              <!-- Contact Info & Social Media -->
              <div
                class="grid grid-cols-1 sm:grid-cols-2 gap-x-4 gap-y-2 text-sm"
              >
                <!-- Location info -->
                <div
                  v-if="user?.city || user?.state"
                  class="flex items-center gap-1.5 group"
                >
                  <div
                    class="p-1 rounded-md text-blue-500 group-hover:bg-blue-50 transition-colors"
                  >
                    <MapPin class="h-3.5 w-3.5" />
                  </div>
                  <span
                    class="text-gray-500 text-sm font medium truncate group-hover:text-gray-700 transition-colors"
                  >
                    {{
                      [user?.city || "", user?.state || ""]
                        .filter((item) => item !== "")
                        .join(", ")
                    }}
                  </span>
                </div>

                <!-- Company info -->
                <div
                  v-if="user?.company"
                  class="flex items-center gap-1.5 group"
                >
                  <div
                    class="p-1 rounded-md text-purple-500 group-hover:bg-purple-50 transition-colors"
                  >
                    <Briefcase class="h-3.5 w-3.5" />
                  </div>
                  <span
                    class="text-gray-500 text-sm font medium truncate group-hover:text-gray-700 transition-colors"
                  >
                    {{ user?.company }}
                  </span>
                </div>

                <!-- Joined date -->
                <div class="flex items-center gap-1.5 group">
                  <div
                    class="p-1 rounded-md text-emerald-500 group-hover:bg-emerald-50 transition-colors"
                  >
                    <Calendar class="h-3.5 w-3.5" />
                  </div>
                  <span
                    class="text-gray-500 text-sm group-hover:text-gray-700 transition-colors"
                  >
                    Joined {{ formatTimeAgo(user?.date_joined) }}
                  </span>
                </div>

                <!-- Email (if allowed to show) -->
                <div
                  v-if="
                    user?.email &&
                    (currentUser?.user?.id === user?.id || user?.show_email)
                  "
                  class="flex items-center gap-1.5 group"
                >
                  <div
                    class="p-1 rounded-md text-amber-500 group-hover:bg-amber-50 transition-colors"
                  >
                    <Mail class="h-3.5 w-3.5" />
                  </div>
                  <span
                    class="text-gray-500 text-sm font medium truncate group-hover:text-gray-700 transition-colors"
                  >
                    {{ user?.email }}
                  </span>
                </div>

                <!-- Phone (if allowed to show) -->
                <div
                  v-if="
                    user?.phone &&
                    (currentUser?.user?.id === user?.id || user?.show_phone)
                  "
                  class="flex items-center gap-1.5 group"
                >
                  <div
                    class="p-1 rounded-md text-rose-500 group-hover:bg-rose-50 transition-colors"
                  >
                    <Phone class="h-3.5 w-3.5" />
                  </div>
                  <span
                    class="text-gray-500 text-sm font medium truncate group-hover:text-gray-700 transition-colors"
                  >
                    {{ user?.phone }}
                  </span>
                </div>
              </div>

              <!-- Social Media Links -->
              <div class="mt-3 pt-3 border-t border-gray-100">
                <div class="grid grid-cols-2 sm:flex sm:flex-wrap gap-3">
                  <!-- Website -->
                  <a
                    v-if="user?.website"
                    :href="
                      user?.website.startsWith('http')
                        ? user.website
                        : 'https://' + user.website
                    "
                    target="_blank"
                    rel="noopener noreferrer"
                    class="flex items-center gap-1.5 text-blue-600 hover:text-blue-700 text-sm font-medium truncate transform transition-all duration-300 hover:translate-y-[-2px] hover:shadow-sm p-1.5 rounded-md bg-gradient-to-br from-blue-50/80 to-blue-50/30 hover:from-blue-50 hover:to-blue-100/50 border border-blue-100/50"
                  >
                    <LinkIcon class="h-4 w-4 flex-shrink-0" />
                    <span class="truncate">{{
                      typeof user?.website === "string"
                        ? user.website.replace(/^https?:\/\//, "")
                        : ""
                    }}</span>
                  </a>

                  <!-- Facebook -->
                  <a
                    v-if="user?.face_link"
                    :href="
                      user.face_link.startsWith('http')
                        ? user.face_link
                        : 'https://' + user.face_link
                    "
                    target="_blank"
                    rel="noopener noreferrer"
                    class="flex items-center gap-1.5 text-blue-600 hover:text-blue-700 transform transition-all duration-300 hover:translate-y-[-2px] hover:shadow-sm p-1.5 rounded-md bg-gradient-to-br from-blue-50/80 to-blue-50/30 hover:from-blue-50 hover:to-blue-100/50 border border-blue-100/50"
                  >
                    <UIcon name="i-mdi-facebook" class="size-4 flex-shrink-0" />
                    <span class="text-sm font-medium">Facebook</span>
                  </a>

                  <!-- Instagram -->
                  <a
                    v-if="user?.instagram_link"
                    :href="
                      user.instagram_link.startsWith('http')
                        ? user.instagram_link
                        : 'https://' + user.instagram_link
                    "
                    target="_blank"
                    rel="noopener noreferrer"
                    class="flex items-center gap-1.5 text-pink-600 hover:text-pink-700 transform transition-all duration-300 hover:translate-y-[-2px] hover:shadow-sm p-1.5 rounded-md bg-gradient-to-br from-pink-50/80 to-pink-50/30 hover:from-pink-50 hover:to-pink-100/50 border border-pink-100/50"
                  >
                    <UIcon
                      name="i-mdi-instagram"
                      class="size-4 flex-shrink-0"
                    />
                    <span class="text-sm font-medium">Instagram</span>
                  </a>

                  <!-- WhatsApp -->
                  <a
                    v-if="user?.whatsapp_link"
                    :href="`https://wa.me/${user.whatsapp_link.replace(
                      /[^0-9]/g,
                      ''
                    )}`"
                    target="_blank"
                    rel="noopener noreferrer"
                    class="flex items-center gap-1.5 text-green-600 hover:text-green-700 transform transition-all duration-300 hover:translate-y-[-2px] hover:shadow-sm p-1.5 rounded-md bg-gradient-to-br from-green-50/80 to-green-50/30 hover:from-green-50 hover:to-green-100/50 border border-green-100/50"
                  >
                    <UIcon name="i-mdi-whatsapp" class="size-4 flex-shrink-0" />
                    <span class="text-sm font-medium">WhatsApp</span>
                  </a>

                  <!-- Gmail/Email -->
                  <a
                    v-if="user?.gmail_link"
                    :href="`mailto:${user.gmail_link}`"
                    target="_blank"
                    rel="noopener noreferrer"
                    class="flex items-center gap-1.5 text-red-500 hover:text-red-600 transform transition-all duration-300 hover:translate-y-[-2px] hover:shadow-sm p-1.5 rounded-md bg-gradient-to-br from-red-50/80 to-red-50/30 hover:from-red-50 hover:to-red-100/50 border border-red-100/50"
                  >
                    <UIcon name="i-mdi-gmail" class="size-4 flex-shrink-0" />
                    <span class="text-sm font-medium">Email</span>
                  </a>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- Tabs Section with Premium Styling -->
      <div
        class="bg-white/95 backdrop-blur-md rounded-xl shadow-sm border border-gray-200/50 overflow-hidden animate-fadeIn-delayed"
      >
        <!-- Scrollable Tabs for Mobile -->
        <div class="overflow-x-auto scrollbar-hide">
          <div
            class="flex items-center border-b border-gray-200 min-w-max relative"
          >
            <!-- Tab buttons with enhanced styling -->
            <button
              v-for="tab in tabs"
              :key="tab.value"
              class="px-5 py-3.5 text-sm font-medium border-b-2 transition-all duration-300 whitespace-nowrap relative overflow-hidden group"
              :class="[
                activeTab === tab.value
                  ? 'text-blue-600 border-blue-600'
                  : 'text-gray-500 border-transparent hover:text-gray-700 hover:border-gray-300',
              ]"
              @click="switchTab(tab.value)"
            >
              <span class="relative z-10">{{ tab.label }}</span>

              <!-- Animated underline effect -->
              <div
                v-if="activeTab === tab.value"
                class="absolute bottom-0 left-0 h-0.5 w-full bg-gradient-to-r from-blue-500 to-indigo-500 animate-fadeIn"
              ></div>

              <!-- Tab hover effect -->
              <div
                class="absolute inset-0 bg-gradient-to-r from-blue-50 to-indigo-50 opacity-0 group-hover:opacity-100 transition-opacity -z-10"
              ></div>
            </button>
          </div>
        </div>

        <div class="py-4 px-1">
          <transition name="tab-transition" mode="out-in">
            <!-- Tab content sections here -->
            <div v-if="activeTab === 'posts'" class="tab-content">
              <!-- Lazyloader for posts -->
              <div v-if="isLoadingPosts" class="p-4">
                <div class="flex justify-center items-center mb-6">
                  <Loader2 class="h-10 w-10 text-blue-600 animate-spin" />
                </div>
                <!-- Skeleton loaders for posts -->
                <div
                  v-for="i in 2"
                  :key="i"
                  class="bg-white rounded-xl border border-gray-200 overflow-hidden mb-4 p-4 animate-pulse-staggered"
                >
                  <div class="flex items-center space-x-3 mb-4">
                    <div
                      class="w-12 h-12 rounded-full bg-gray-200 animate-pulse"
                    ></div>
                    <div class="flex-1 space-y-2">
                      <div
                        class="h-4 bg-gray-200 rounded animate-pulse w-1/4"
                      ></div>
                      <div
                        class="h-3 bg-gray-200 rounded animate-pulse w-1/5"
                      ></div>
                    </div>
                  </div>
                  <div class="space-y-2 mb-4">
                    <div
                      class="h-4 bg-gray-200 rounded animate-pulse w-3/4"
                    ></div>
                    <div
                      class="h-3 bg-gray-200 rounded animate-pulse w-full"
                    ></div>
                    <div
                      class="h-3 bg-gray-200 rounded animate-pulse w-5/6"
                    ></div>
                  </div>
                  <div
                    class="h-40 bg-gray-200 rounded animate-pulse mb-4"
                  ></div>
                  <div class="flex justify-between">
                    <div
                      class="h-8 bg-gray-200 rounded animate-pulse w-1/4"
                    ></div>
                    <div
                      class="h-8 bg-gray-200 rounded animate-pulse w-1/4"
                    ></div>
                    <div
                      class="h-8 bg-gray-200 rounded animate-pulse w-1/4"
                    ></div>
                  </div>
                </div>
              </div>

              <!-- Load more posts indicator at the bottom -->
              <div v-if="loadingMorePosts && !isLoadingPosts" class="pb-6">
                <div class="flex justify-center items-center py-4">
                  <Loader2 class="h-8 w-8 text-blue-600 animate-spin" />
                </div>
              </div>

              <!-- Display actual posts when loaded -->
              <BusinessNetworkPost
                v-if="!isLoadingPosts"
                :posts="posts.results"
                :id="currentUser?.user?.id"
              />

              <!-- No posts indicator -->
              <div
                v-if="!isLoadingPosts && posts?.results?.length === 0"
                class="flex flex-col items-center justify-center py-8 text-center"
              >
                <div
                  class="w-16 h-16 rounded-full bg-gray-100 flex items-center justify-center mb-4"
                >
                  <ChevronUp class="h-8 w-8 text-gray-500" />
                </div>
                <h3 class="text-lg font-medium text-gray-700 mb-1">
                  No posts yet
                </h3>
                <p class="text-gray-500 mb-4 max-w-md">
                  This profile hasn't posted anything yet
                </p>
              </div>

              <!-- NEW: Static End of feed indicator - Always shows at the bottom of the page -->
              <div
                class="end-of-feed-indicator bg-white rounded-xl border border-gray-200/50 overflow-hidden mt-8 mb-4"
                v-if="!isLoadingPosts && !posts?.results?.length === 0"
              >
                <div
                  class="flex flex-col items-center justify-center py-8 text-center"
                >
                  <div
                    class="w-16 h-16 rounded-full bg-gray-100 flex items-center justify-center mb-4"
                  >
                    <Check class="h-8 w-8 text-blue-600" />
                  </div>
                  <h3 class="text-lg font-medium text-gray-700 mb-1">
                    You're all caught up!
                  </h3>
                  <p class="text-gray-500 mb-8 max-w-md">
                    You've reached the end of the feed
                  </p>
                  <button
                    @click="scrollToTop"
                    class="flex items-center gap-2 px-4 py-2 text-sm bg-blue-50 text-blue-600 rounded-full hover:bg-blue-100 transition-colors"
                  >
                    <ChevronUp class="h-4 w-4" />
                    <span>Back to top</span>
                  </button>
                </div>
              </div>
            </div>

            <div v-else-if="activeTab === 'media'" class="tab-content">
              <!-- Lazyloader for media tab -->
              <div v-if="isLoadingMedia" class="p-4">
                <div class="flex justify-center items-center mb-6">
                  <Loader2 class="h-10 w-10 text-blue-600 animate-spin" />
                </div>
                <div
                  class="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 gap-2 px-2"
                >
                  <div
                    v-for="i in 8"
                    :key="i"
                    class="aspect-square bg-gray-200 rounded animate-pulse"
                  ></div>
                </div>
              </div>

              <!-- Display actual media when loaded -->
              <div
                v-if="!isLoadingMedia"
                class="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 gap-2 px-2 animate-fadeIn"
              >
                <div
                  v-for="(media, index) in allMedia"
                  :key="index"
                  class="aspect-square bg-gray-100 rounded-lg overflow-hidden group cursor-pointer hover:shadow-sm transition-all duration-300"
                >
                  <img
                    :src="media.thumbnail"
                    :alt="`Media ${index + 1}`"
                    class="w-full h-full object-cover group-hover:scale-105 transition-all duration-500"
                  />
                </div>
              </div>
            </div>

            <div v-else-if="activeTab === 'saved'" class="tab-content">
              <!-- Lazyloader for saved posts -->
              <div v-if="isLoadingSaved" class="p-4">
                <div class="flex justify-center items-center mb-6">
                  <Loader2 class="h-10 w-10 text-blue-600 animate-spin" />
                </div>
                <div
                  v-for="i in 2"
                  :key="i"
                  class="bg-white rounded-xl border border-gray-200 overflow-hidden mb-4 p-4 animate-pulse-staggered"
                >
                  <div class="flex items-center space-x-3 mb-4">
                    <div
                      class="w-12 h-12 rounded-full bg-gray-200 animate-pulse"
                    ></div>
                    <div class="flex-1 space-y-2">
                      <div
                        class="h-4 bg-gray-200 rounded animate-pulse w-1/4"
                      ></div>
                      <div
                        class="h-3 bg-gray-200 rounded animate-pulse w-1/5"
                      ></div>
                    </div>
                  </div>
                  <div class="space-y-2 mb-4">
                    <div
                      class="h-4 bg-gray-200 rounded animate-pulse w-3/4"
                    ></div>
                    <div
                      class="h-3 bg-gray-200 rounded animate-pulse w-full"
                    ></div>
                  </div>
                  <div
                    class="h-40 bg-gray-200 rounded animate-pulse mb-4"
                  ></div>
                </div>
              </div>

              <div v-if="!isLoadingSaved" class="animate-fadeIn">
                <div v-if="savedPosts?.length === 0" class="text-center py-10">
                  <h3 class="text-base font-medium text-gray-700 mb-2">
                    No saved posts yet
                  </h3>
                  <p class="text-gray-500 text-sm">
                    Posts you save will appear here
                  </p>
                </div>
                <BusinessNetworkPost
                  :posts="savedPosts"
                  :id="currentUser?.user?.id"
                />
              </div>
            </div>
          </transition>
        </div>
      </div>
    </div>
    <BusinessNetworkDiamondPurchaseModal
      :modelValue="showDiamondModal"
      @close="showDiamondModal = false"
    />
  </div>
</template>

<script setup>
definePageMeta({
  layout: "adsy-business-network",
});

import BusinessNetworkDiamondPurchaseModal from "~/components/business-network/DiamondPurchaseModal.vue";
import {
  Camera,
  Edit,
  MapPin,
  Briefcase,
  Calendar,
  LinkIcon,
  Grid,
  List,
  Settings,
  UserPlus,
  Check,
  BadgeCheck,
  Mail,
  Phone,
  Upload,
  Trash2,
  X,
  Home,
  Bell,
  User,
  BarChart2,
  Bookmark,
  Heart,
  MessageCircle,
  Share2,
  MoreHorizontal,
  Link2,
  Flag,
  Send,
  Download,
  ChevronLeft,
  ChevronRight,
  Loader2,
  ChevronUp,
  Trophy,
} from "lucide-vue-next";

const route = useRoute();
const router = useRouter();

const { user: currentUser } = useAuth();
const { get, post, del } = useApi();
const eventBus = useEventBus();

// Always start with loading state to show skeleton immediately
const isLoading = ref(true);
const isLoadingPosts = ref(true);
const isLoadingMedia = ref(true);
const isLoadingSaved = ref(true);
const loadingMorePosts = ref(false);
const hasMorePosts = ref(true);
const currentPage = ref(1);
const postsPerPage = ref(10);
const loadedPostIds = ref(new Set()); // Track loaded post IDs to prevent duplicates

// Initialize other reactive state
const user = ref({});
const posts = ref({});
const toast = useToast();
const savedPosts = ref([]);
const allMedia = ref([]);
const followLoading = ref(false);
const isFollowing = ref(false);
const showDiamondModal = ref(false);

// Set up event listener for navigation events
onMounted(() => {
  // Listen for loading events from footer and sidebar
  eventBus.on("start-loading-profile", () => {
    // Special case: If we're already on the profile page and the ID matches the current route
    if (route.path.includes("/profile/") && !isLoading.value) {
      // Just reload the data without showing skeleton if we're already on this profile
      const currentId = route.params.id;
      const alreadyOnPage = currentId === route.params.id;

      if (alreadyOnPage) {
        // Don't show skeleton, just refresh data in the background
        fetchUser();
        fetchUserPosts();
        if (currentUser.value) {
          fetchUserSavedPosts();
        }
        return;
      }
    }

    // Standard behavior when navigating to a different profile
    // Reset loading states
    isLoading.value = true;
    isLoadingPosts.value = true;
    isLoadingMedia.value = true;
    isLoadingSaved.value = true;
  });
});

// Define data loading functions
async function checkFollowing() {
  if (!currentUser.value) return;
  try {
    const { data } = await get(
      `/bn/check-follow-status/${currentUser.value?.user?.id}/${route.params.id}/`
    );
    console.log(data, "check-follow-status");
    isFollowing.value = data.is_following;
  } catch (error) {
    console.error(error);
  }
}

async function fetchUser() {
  try {
    const { data } = await get(`/user/${route.params.id}/`);
    user.value = {
      ...data,
      // Standardize the follower/following count properties
      followers_count: data.followers_count || data.follower_count || 0,
      following_count: data.following_count || data.follow_count || 0,
      post_count: data.post_count || 0,
      // Social media fields
      facebook_url: data.facebook_url || null,
      whatsapp: data.whatsapp || null,
      linkedin_url: data.linkedin_url || null,
      twitter_url: data.twitter_url || null,
      // Other properties are preserved
    };
    console.log(user.value);
  } catch (error) {
    console.error(error);
  } finally {
    // Add a minimum loading time for better UX
    setTimeout(() => {
      isLoading.value = false;
    }, 800);
  }
}

async function fetchUserPosts(loadMore = false) {
  try {
    if (loadMore) {
      loadingMorePosts.value = true;
    } else {
      isLoadingPosts.value = true;
      currentPage.value = 1;
      loadedPostIds.value.clear(); // Clear tracked IDs on initial load
    }

    // Build params for pagination
    const params = {
      page: currentPage.value,
      page_size: postsPerPage.value,
    };

    const res = await get(`/bn/user/${route.params.id}/posts/`, { params });

    if (loadMore) {
      // Append new posts to existing ones
      if (
        posts.value?.results &&
        Array.isArray(posts.value.results) &&
        res.data?.results &&
        Array.isArray(res.data.results)
      ) {
        // Filter out any duplicates based on post ID
        const newPosts = res.data.results.filter(
          (post) => !loadedPostIds.value.has(post.id)
        );

        // Add new post IDs to our tracking Set
        newPosts.forEach((post) => loadedPostIds.value.add(post.id));

        // Update posts with combined unique results
        posts.value = {
          ...res.data,
          results: [...posts.value.results, ...newPosts],
        };

        // If we filtered out all posts as duplicates, show end of feed
        if (newPosts.length === 0 && res.data.results.length > 0) {
          hasMorePosts.value = false;
        }
      } else {
        // Initial set of posts when loading more
        if (res.data?.results) {
          res.data.results.forEach((post) => loadedPostIds.value.add(post.id));
        }
        posts.value = res.data;
      }
    } else {
      // Initial load - replace existing posts
      if (res.data?.results) {
        // Clear tracking and add all new posts
        loadedPostIds.value.clear();
        res.data.results.forEach((post) => loadedPostIds.value.add(post.id));
      }
      posts.value = res.data;
    }

    // Check if we have more posts to load
    hasMorePosts.value = !!res.data.next;

    // If we didn't get any posts in a load more request, we're at the end
    if (loadMore && (!res.data.results || res.data.results.length === 0)) {
      hasMorePosts.value = false;
    }

    console.log(
      `Loaded ${loadMore ? "more" : "initial"} posts for user. Has more: ${
        hasMorePosts.value
      }, Total unique posts: ${loadedPostIds.value.size}`
    );
  } catch (error) {
    console.error("Error fetching user posts:", error);

    toast.add({
      title: "Error",
      description: "Failed to load posts",
      color: "red",
      timeout: 3000,
    });
  } finally {
    isLoadingPosts.value = false;
    loadingMorePosts.value = false;
  }
}

// Load more posts
function loadMorePosts() {
  if (!hasMorePosts.value || loadingMorePosts.value || isLoadingPosts.value)
    return;

  currentPage.value++;
  fetchUserPosts(true);
}

// Setup scroll detection for infinite scroll
function setupInfiniteScroll() {
  // Create a global flag to track if we've reached the end of feed
  // Using a ref ensures this state persists properly
  const endOfFeedReached = ref(false);

  const handleScroll = () => {
    if (activeTab.value !== "posts") return;
    if (endOfFeedReached.value) {
      // If we already know we're at the end, don't do anything
      return;
    }

    // Check if we're at or near the bottom of the page
    if (
      window.innerHeight + window.scrollY >=
      document.body.offsetHeight - 200
    ) {
      // Stop further API calls if we're already at the end (no more posts OR we've already seen the "all caught up" message)
      if (!hasMorePosts.value) {
        console.log("End of feed reached - disabling infinite scroll");
        endOfFeedReached.value = true;
        return;
      }

      // Otherwise, try loading more posts if not currently loading
      if (!loadingMorePosts.value && !isLoadingPosts.value) {
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

async function fetchUserSavedPosts() {
  try {
    const res = await get(`/bn/posts/save/`);
    console.log(res.data, "saved posts");
    savedPosts.value = res.data;
  } catch (error) {
    console.error(error);
  } finally {
    isLoadingSaved.value = false;
  }
}

// Load data when component is created
function loadAllData() {
  // Start with loading states set to true
  isLoading.value = true;
  isLoadingPosts.value = true;
  isLoadingMedia.value = true;
  isLoadingSaved.value = true;
  loadingMorePosts.value = false;
  hasMorePosts.value = true;
  currentPage.value = 1;

  // Fetch all data in parallel
  Promise.all([
    fetchUser(),
    fetchUserPosts(),
    currentUser.value ? fetchUserSavedPosts() : Promise.resolve(),
    currentUser.value && route.params.id ? checkFollowing() : Promise.resolve(),
  ]);

  // Simulate loading media items
  setTimeout(() => {
    allMedia.value = Array(16)
      .fill()
      .map((_, i) => ({
        thumbnail: `https://picsum.photos/500/500?random=${i + 1}`,
        url: `https://picsum.photos/1200/900?random=${i + 1}`,
      }));
    isLoadingMedia.value = false;
  }, 1500);
}

// Existing view mode and tab states
const viewMode = ref("list");
const activeTab = ref("posts");
const isEditProfileOpen = ref(false);
const isEditPhotoOpen = ref(false);
const isEditCoverOpen = ref(false);
const profileForm = ref({
  name: user.value.name,
  bio: user.value.bio,
  location: user.value.location,
  company: user.value.company,
  website: user.value.website,
  email: user.value.email,
  phone: user.value.phone,
});
const profilePhotoInputRef = ref(null);
const coverPhotoInputRef = ref(null);
const activeMedia = ref(null);
const activePost = ref(null);
const activeMediaIndex = ref(0);

const tabs =
  currentUser.value?.user?.id && currentUser.value?.user?.id === route.params.id
    ? [
        { label: "Posts", value: "posts" },
        // { label: "Media", value: "media" },
        { label: "Saved", value: "saved" },
      ]
    : [
        { label: "Posts", value: "posts" },
        // { label: "Media", value: "media" },
        // { label: "Saved", value: "saved" },
      ];

// Rest of your existing functions
// Toggle follow action
const toggleFollow = async () => {
  if (followLoading.value) return;
  followLoading.value = true;
  isFollowing.value = !isFollowing.value;

  if (isFollowing.value) {
    try {
      const { data } = await post(`/bn/users/${route.params.id}/follow/`);

      if (data) {
        // Update followers count accordingly
        user.value.followers_count = (user.value.followers_count || 0) + 1;

        toast.add({
          title: "Followed",
          description: "You have successfully followed this user.",
          icon: "i-heroicons-check-circle",
          color: "green",
        });
      }
    } catch (error) {
      console.error("Error toggling follow:", error);
      isFollowing.value = !isFollowing.value; // Revert state on error
    } finally {
      followLoading.value = false;
    }
  } else {
    try {
      const res = await del(`/bn/users/${route.params.id}/unfollow/`);
      if (res.data === undefined) {
        // Update followers count accordingly
        user.value.followers_count = Math.max(
          0,
          (user.value.followers_count || 0) - 1
        );

        toast.add({
          title: "Unfollowed",
          description: "You have successfully unfollowed this user.",
          icon: "i-heroicons-information-circle",
          color: "gray",
        });
      }
    } catch (error) {
      console.error("Error toggling follow:", error);
      isFollowing.value = !isFollowing.value; // Revert state on error
    } finally {
      followLoading.value = false;
    }
  }
};

// Animation when switching tabs
const switchTab = (tabValue) => {
  if (activeTab.value === tabValue) return;

  // Apply animation class and change tab
  activeTab.value = tabValue;
};

// Format time ago function
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

// Watch for route changes
watch(
  () => route.params.id,
  (newId, oldId) => {
    if (newId !== oldId) {
      // Always reset loading states when route changes
      isLoading.value = true;
      isLoadingPosts.value = true;
      isLoadingMedia.value = true;
      isLoadingSaved.value = true;

      // Load fresh data
      loadAllData();
    }
  },
  { immediate: false }
);

// Lifecycle hooks
onMounted(() => {
  // Register event listeners
  const eventBus = useEventBus();

  eventBus.on("post-created", (newPost) => {
    // Only update if this is the author's profile
    if (newPost.author?.id === route.params.id) {
      // Add the new post to the beginning of the array
      if (posts.value?.results && Array.isArray(posts.value.results)) {
        posts.value.results.unshift(newPost);
      }

      // Update post count
      user.value.post_count = (user.value.post_count || 0) + 1;

      // Scroll to the new post after it renders
      nextTick(() => {
        setTimeout(() => {
          const newPostElement = document.getElementById(`post-${newPost.id}`);
          if (newPostElement) {
            newPostElement.scrollIntoView({
              behavior: "smooth",
              block: "center",
            });
            // Add highlight animation
            newPostElement.classList.add("highlight-new-post");
          }
        }, 500);
      });
    }
  });

  // Load data on mount (with skeleton already showing)
  loadAllData();

  // Setup infinite scroll
  setupInfiniteScroll();

  // Clean up event listener on unmount
  onUnmounted(() => {
    eventBus.off("post-created");
    eventBus.off("start-loading-profile");
  });
});

// Scroll to top function
const scrollToTop = () => {
  window.scrollTo({
    top: 0,
    behavior: "smooth",
  });
};
</script>

<style scoped>
/* Enhanced background and styling */
.bg-gradient {
  background: linear-gradient(
    135deg,
    rgba(241, 245, 249, 0.8),
    rgba(248, 250, 252, 0.8),
    rgba(241, 245, 249, 0.8)
  );
  background-size: 200% 200%;
  animation: gradientBackground 15s ease infinite;
}

@keyframes gradientBackground {
  0% {
    background-position: 0% 50%;
  }
  50% {
    background-position: 100% 50%;
  }
  100% {
    background-position: 0% 50%;
  }
}

/* Premium Animations */
@keyframes gradient-slow {
  0% {
    background-position: 0% 50%;
  }
  50% {
    background-position: 100% 50%;
  }
  100% {
    background-position: 0% 50%;
  }
}

@keyframes float {
  0% {
    transform: translateY(0px);
  }
  50% {
    transform: translateY(-5px);
  }
  100% {
    transform: translateY(0px);
  }
}

@keyframes shimmer {
  0% {
    background-position: -200% 0;
  }
  100% {
    background-position: 200% 0;
  }
}

.animate-float {
  animation: float 3s ease-in-out infinite;
}

.animate-gradient-slow {
  animation: gradient-slow 6s ease infinite;
  background-size: 200% 200%;
}

/* Enhanced tooltip styling */
.tooltip-container {
  position: relative;
}

.tooltip-content {
  position: absolute;
  top: calc(100% + 5px);
  left: 50%;
  transform: translateX(-50%) translateY(-10px);
  background-color: #333;
  color: white;
  padding: 0.25rem 0.5rem;
  border-radius: 0.25rem;
  font-size: 0.75rem;
  z-index: 10;
  white-space: nowrap;
  opacity: 0;
  visibility: hidden;
  transition: opacity 0.2s ease-out, visibility 0.2s ease-out,
    transform 0.3s ease-out;
  pointer-events: none;
  width: max-content;
  box-shadow: 0 4px 6px -1px rgb(0 0 0 / 10%), 0 2px 4px -1px rgb(0 0 0 / 6%);
}

.tooltip-container:hover .tooltip-content {
  opacity: 1;
  visibility: visible;
  transform: translateX(-50%) translateY(0);
}

.tooltip-content::after {
  content: "";
  position: absolute;
  bottom: 100%;
  left: 50%;
  margin-left: -5px;
  border-width: 5px;
  border-style: solid;
  border-color: transparent transparent #333 transparent;
}

/* Tab transitions */
.tab-transition-enter-active,
.tab-transition-leave-active {
  transition: opacity 0.4s, transform 0.4s;
}

.tab-transition-enter-from,
.tab-transition-leave-to {
  opacity: 0;
  transform: translateY(10px);
}

.tab-content {
  min-height: 300px;
}

/* Animations */
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

@keyframes scaleIn {
  from {
    transform: scale(0);
  }
  to {
    transform: scale(1);
  }
}

@keyframes highlightPost {
  0% {
    box-shadow: 0 0 0 rgba(59, 130, 246, 0);
    transform: scale(1);
  }
  50% {
    box-shadow: 0 0 20px rgba(59, 130, 246, 0.6);
    transform: scale(1.02);
  }
  100% {
    box-shadow: 0 0 5px rgba(59, 130, 246, 0.3);
    transform: scale(1);
  }
}

@keyframes pulse-subtle {
  0% {
    opacity: 0.9;
  }
  50% {
    opacity: 1;
  }
  100% {
    opacity: 0.9;
  }
}

@keyframes shine {
  to {
    background-position: 200% center;
  }
}

.animate-fadeIn {
  animation: fadeIn 0.5s ease forwards;
}

.animate-fadeIn-delayed {
  animation: fadeIn 0.5s 0.2s ease forwards;
  opacity: 0;
}

.animate-scaleIn {
  animation: scaleIn 0.3s cubic-bezier(0.175, 0.885, 0.32, 1.275) forwards;
}

.animate-pulse-subtle {
  animation: pulse-subtle 2s infinite;
}

.animate-pulse-staggered:nth-child(2) {
  animation-delay: 0.2s;
}

.highlight-new-post {
  animation: highlightPost 1.5s ease-out;
}

/* Premium shimmer effect on profile badge */
.shimmer {
  background: linear-gradient(
    90deg,
    rgba(255, 255, 255, 0) 0%,
    rgba(255, 255, 255, 0.8) 50%,
    rgba(255, 255, 255, 0) 100%
  );
  background-size: 200% 100%;
  animation: shimmer 2s infinite;
}

/* Premium glass card effect */
.glass-card {
  backdrop-filter: blur(10px);
  -webkit-backdrop-filter: blur(10px);
  background: rgba(255, 255, 255, 0.65);
  border: 1px solid rgba(255, 255, 255, 0.3);
  box-shadow: 0 8px 32px rgba(31, 38, 135, 0.1);
}

/* 3D button hover effect */
button.btn-3d {
  transition: all 0.2s cubic-bezier(0.175, 0.885, 0.32, 1.275);
  transform: translateY(0) scale(1);
}

button.btn-3d:hover {
  transform: translateY(-2px) scale(1.02);
  box-shadow: 0 10px 15px -3px rgba(0, 0, 0, 0.1),
    0 4px 6px -2px rgba(0, 0, 0, 0.05);
}

button.btn-3d:active {
  transform: translateY(1px) scale(0.98);
}

/* Hide scrollbar but allow scrolling */
.scrollbar-hide {
  scrollbar-width: none; /* Firefox */
  -ms-overflow-style: none; /* Internet Explorer 10+ */
}

.scrollbar-hide::-webkit-scrollbar {
  display: none; /* Safari and Chrome */
}

/* Additional animation for skeleton loading */
@keyframes pulse {
  0%,
  100% {
    opacity: 0.6;
  }
  50% {
    opacity: 1;
  }
}

.animate-pulse {
  animation: pulse 2s cubic-bezier(0.4, 0, 0.6, 1) infinite;
}

/* Premium shadow effects for cards */
.shadow-soft {
  box-shadow: 0 2px 10px rgba(0, 0, 0, 0.03), 0 6px 15px rgba(0, 0, 0, 0.02),
    0 12px 30px rgba(0, 0, 0, 0.01);
  transition: all 0.3s ease;
}

.shadow-soft:hover {
  box-shadow: 0 5px 15px rgba(0, 0, 0, 0.05), 0 10px 25px rgba(0, 0, 0, 0.04),
    0 15px 35px rgba(0, 0, 0, 0.02);
}
</style>
