<template>
  <UContainer class="mt-3">
    <div class="min-h-screen bg-gray-50">
      <!-- Top Navigation -->
      <div class="bg-white border-b border-gray-200 shadow-sm rounded-md">
        <div class="mx-auto px-4">
          <div class="flex items-center justify-between h-16">
            <div class="flex items-center space-x-4">
              <div class="text-lg font-medium text-emerald-500">
                ABN Ads Panel
              </div>
              <div class="hidden md:flex space-x-3">
                <button
                  class="px-4 py-1.5 text-sm font-medium transition-colors border rounded-md"
                  :class="
                    activeTab === 'my-ads'
                      ? 'border-emerald-500 text-emerald-500'
                      : 'border-gray-300 text-gray-800 hover:border-gray-400'
                  "
                  @click="activeTab = 'my-ads'"
                >
                  My Ads
                </button>
                <button
                  class="px-4 py-1.5 text-sm font-medium transition-colors border rounded-md"
                  :class="
                    activeTab === 'abn-ads'
                      ? 'border-emerald-500 text-emerald-500'
                      : 'border-gray-300 text-gray-800 hover:border-gray-400'
                  "
                  @click="activeTab = 'abn-ads'"
                >
                  ABN Ads Support
                </button>
              </div>
            </div>
            <div class="flex items-center space-x-3">
              <!-- Account Balance -->
              <div
                class="hidden md:flex items-center px-3 py-1.5 bg-gray-100 text-sm rounded-md"
              >
                <span class="text-gray-600 mr-1">Balance:</span>
                <span
                  class="font-semibold"
                  :class="
                    user?.user?.balance < 200
                      ? 'text-red-500'
                      : 'text-emerald-500'
                  "
                >
                  ৳{{ user?.user?.balance }}
                </span>
                <span
                  v-if="user?.user?.balance < 200"
                  class="ml-1 text-sm text-red-500 font-medium"
                  >Low!</span
                >
              </div>
            </div>
          </div>
        </div>
      </div>

      <div class="mx-auto mt-3">
        <!-- Low Balance Alert -->
        <div
          v-if="user?.user?.balance < 200"
          class="mb-4 bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded-md flex items-center justify-between"
        >
          <div class="flex items-center">
            <svg
              xmlns="http://www.w3.org/2000/svg"
              class="h-5 w-5 mr-2 text-red-500"
              fill="none"
              viewBox="0 0 24 24"
              stroke="currentColor"
            >
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                stroke-width="2"
                d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"
              />
            </svg>
            <span class="text-sm">
              Your account balance is low (৳{{ user?.user?.balance }}). Please
              recharge to continue posting ads.
            </span>
          </div>
          <button
            class="text-sm font-medium bg-red-100 hover:bg-red-200 text-red-700 px-3 py-1 rounded-md transition-colors"
          >
            Recharge Now
          </button>
        </div>

        <div class="flex flex-col lg:flex-row gap-6">
          <!-- Main Content - Ads List -->
          <div class="w-full lg:w-2/3 space-y-5">
            <!-- Date Filter - Moved here from top navigation -->
            <div class="bg-white rounded-md shadow-sm p-4 mb-2">
              <h2
                class="text-sm font-medium text-gray-800 mb-3 flex items-center"
              >
                <svg
                  xmlns="http://www.w3.org/2000/svg"
                  class="h-4 w-4 mr-2 text-emerald-500"
                  fill="none"
                  viewBox="0 0 24 24"
                  stroke="currentColor"
                >
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="2"
                    d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z"
                  />
                </svg>
                Date Range Filter
              </h2>
              <div class="flex items-center space-x-2">
                <div class="relative">
                  <input
                    type="date"
                    v-model="dateFilter.from"
                    class="px-3 py-1.5 text-sm border border-gray-300 focus:ring-emerald-500 focus:border-emerald-500 rounded-md"
                  />
                </div>
                <span class="text-sm text-gray-600">to</span>
                <div class="relative">
                  <input
                    type="date"
                    v-model="dateFilter.to"
                    class="px-3 py-1.5 text-sm border border-gray-300 focus:ring-emerald-500 focus:border-emerald-500 rounded-md"
                  />
                </div>
                <button
                  @click="applyDateFilter"
                  class="px-3 py-1.5 text-sm border border-gray-300 hover:bg-gray-100 transition-colors rounded-md"
                >
                  Apply
                </button>
              </div>
            </div>

            <!-- Performance Report -->
            <div class="bg-white rounded-md shadow-sm p-4 mb-5">
              <h2
                class="text-sm font-medium text-gray-800 mb-3 flex items-center"
              >
                <svg
                  xmlns="http://www.w3.org/2000/svg"
                  class="h-4 w-4 mr-2 text-emerald-500"
                  fill="none"
                  viewBox="0 0 24 24"
                  stroke="currentColor"
                >
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="2"
                    d="M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z"
                  />
                </svg>
                Overall Performance
              </h2>

              <div class="grid grid-cols-2 sm:grid-cols-3 gap-3">
                <div class="bg-blue-50 rounded-md p-2 text-center">
                  <div class="text-lg font-semibold text-blue-600">
                    {{ totalViews }}
                  </div>
                  <div class="text-sm text-gray-600">Total Views</div>
                </div>
                <!-- <div class="bg-green-50 rounded-md p-2 text-center">
                  <div class="text-lg font-semibold text-green-600">
                    {{ totalClicks }}
                  </div>
                  <div class="text-sm text-gray-600">Total Clicks</div>
                </div> -->
                <div class="bg-amber-50 rounded-md p-2 text-center">
                  <div class="text-lg font-semibold text-amber-600">
                    {{ postedAds.length }}
                  </div>
                  <div class="text-sm text-gray-600">Active Ads</div>
                </div>
              </div>
            </div>
            <div class="flex gap-4 justify-between items-center mb-4">
              <!-- Create Ad Button - Moved below performance report -->
              <div class="flex justify-center pl-4">
                <button
                  @click="showCreateAdModal = true"
                  class="flex items-center text-emerald-500 font-medium hover:text-emerald-600 transition-colors rounded-md px-3 py-2 border border-emerald-500 text-sm"
                  :disabled="isLoading"
                >
                  <svg
                    xmlns="http://www.w3.org/2000/svg"
                    class="h-4 w-4 mr-1"
                    fill="none"
                    viewBox="0 0 24 24"
                    stroke="currentColor"
                  >
                    <path
                      stroke-linecap="round"
                      stroke-linejoin="round"
                      stroke-width="2"
                      d="M12 4v16m8-8H4"
                    />
                  </svg>
                  <svg
                    v-if="isLoading"
                    class="animate-spin h-3 w-3 mr-1 text-current"
                    xmlns="http://www.w3.org/2000/svg"
                    fill="none"
                    viewBox="0 0 24 24"
                  >
                    <circle
                      class="opacity-25"
                      cx="12"
                      cy="12"
                      r="10"
                      stroke="currentColor"
                      stroke-width="4"
                    ></circle>
                    <path
                      class="opacity-75"
                      fill="currentColor"
                      d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"
                    ></path>
                  </svg>
                  Create New Ad
                </button>
              </div>

              <!-- Mobile Account Balance -->
              <div
                class="md:hidden flex items-center justify-center px-3 py-1.5 bg-gray-100 text-sm rounded-md w-fit mx-auto"
              >
                <span class="text-gray-600 mr-1">Balance:</span>
                <span
                  class="font-semibold"
                  :class="isLowBalance ? 'text-red-500' : 'text-emerald-500'"
                >
                  ৳{{ accountBalance }}
                </span>
                <span
                  v-if="isLowBalance"
                  class="ml-1 text-sm text-red-500 font-medium"
                  >Low!</span
                >
              </div>
            </div>

            <!-- Empty State -->
            <div
              v-if="postedAds.length === 0"
              class="text-center py-12 bg-white rounded-md shadow-sm"
            >
              <svg
                xmlns="http://www.w3.org/2000/svg"
                class="h-12 w-12 mx-auto text-gray-600 mb-3"
                fill="none"
                viewBox="0 0 24 24"
                stroke="currentColor"
              >
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M19 11H5m14 0a2 2 0 012 2v6a2 2 0 01-2 2H5a2 2 0 01-2-2v-6a2 2 0 012-2m14 0V9a2 2 0 00-2-2M5 11V9a2 2 0 012-2m0 0V5a2 2 0 012-2h6a2 2 0 012 2v2M7 7h10"
                />
              </svg>
              <p class="text-gray-600 text-sm">No ads posted yet</p>
              <button
                @click="showCreateAdModal = true"
                class="mt-3 flex items-center mx-auto text-emerald-500 font-medium hover:text-emerald-600 transition-colors rounded-md px-3 py-1 border border-emerald-500 text-sm"
              >
                <svg
                  xmlns="http://www.w3.org/2000/svg"
                  class="h-4 w-4 mr-1"
                  fill="none"
                  viewBox="0 0 24 24"
                  stroke="currentColor"
                >
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="2"
                    d="M12 4v16m8-8H4"
                  />
                </svg>
                Post Your First Ad
              </button>
            </div>

            <!-- List of Ads -->
            <div
              v-for="(ad, index) in postedAds"
              :key="index"
              class="bg-white rounded-md shadow-sm overflow-hidden hover:shadow-sm transition-shadow"
            >
              <div class="flex flex-col md:flex-row">
                <!-- Ad Image -->
                <div class="md:w-1/3 h-40 md:h-auto relative">
                  <!-- Main image -->
                  <img
                    v-if="ad.media && ad.media?.length > 0"
                    :src="ad.media[0].image"
                    alt="Ad image"
                    class="h-full w-full object-cover"
                  />
                  <div
                    v-else
                    class="h-full w-full bg-gray-200 flex items-center justify-center"
                  >
                    <p class="text-gray-600 text-sm">No image</p>
                  </div>

                  <!-- Image count indicator -->
                  <div
                    v-if="ad.media && ad.media?.length > 1"
                    class="absolute bottom-2 right-2 bg-black bg-opacity-60 text-white text-sm px-2 py-1 rounded-md"
                  >
                    {{ ad.media?.length }} images
                  </div>
                </div>

                <!-- Ad Content -->
                <div class="md:w-2/3 p-3">
                  <div class="flex justify-between items-start">
                    <div>
                      <h3 class="font-medium text-base mb-1 line-clamp-2">
                        {{ ad.title }}
                      </h3>
                      <div class="flex flex-wrap items-center gap-2 mb-2">
                        <span
                          v-if="ad.category_details && ad.category !== 'none'"
                          class="bg-emerald-100 text-emerald-600 px-2 py-0.5 rounded-md text-sm"
                        >
                          {{ ad.category_details?.name }}
                        </span>
                        <span class="text-gray-600 text-sm">Bangladesh</span>
                        <span
                          class="px-2 py-0.5 rounded-md text-sm"
                          :class="getStatusClass(ad.status)"
                        >
                          {{ getStatusText(ad.status) }}
                        </span>
                        <div class="flex flex-wrap gap-1">
                          <span
                            v-if="ad.male"
                            class="bg-gray-100 text-gray-600 px-2 py-0.5 rounded-md text-sm"
                          >
                            {{ ad.male ? "Male" : "" }}
                          </span>
                          <span
                            v-if="ad.female"
                            class="bg-gray-100 text-gray-600 px-2 py-0.5 rounded-md text-sm"
                          >
                            {{ ad.female ? "Female" : "" }}
                          </span>
                          <span
                            v-if="ad.other"
                            class="bg-gray-100 text-gray-600 px-2 py-0.5 rounded-md text-sm"
                          >
                            {{ ad.other ? "Other" : "" }}
                          </span>
                          <span
                            class="bg-gray-100 text-gray-600 px-2 py-0.5 rounded-md text-sm"
                          >
                            Age: {{ ad.min_age }}-{{ ad.max_age }}
                          </span>
                        </div>
                      </div>
                    </div>
                  </div>

                  <p class="text-gray-800 mb-3 text-sm line-clamp-3">
                    {{ ad.description }}
                  </p>

                  <!-- Ad Metrics -->
                  <div
                    class="flex flex-wrap items-center gap-4 mb-2 text-sm text-gray-600"
                  >
                    <div class="flex items-center">
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
                          d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"
                        />
                        <path
                          stroke-linecap="round"
                          stroke-linejoin="round"
                          stroke-width="2"
                          d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z"
                        />
                      </svg>
                      <span>{{ ad.views }} views</span>
                    </div>
                    <!-- <div class="flex items-center">
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
                          d="M15 15l-2 5L9 9l11 4-5 2zm0 0l5 5M7.188 2.239l.777 2.897M5.136 7.965l-2.898-.777M13.95 4.05l-2.122 2.122m-5.657 5.656l-2.12 2.122"
                        />
                      </svg>
                      <span>{{ ad.metrics.clicks }} clicks</span>
                    </div> -->
                    <div class="flex items-center">
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
                          d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z"
                        />
                      </svg>
                      <span>{{ formatTimeAgo(ad.created_at) }}</span>
                    </div>
                    <div class="flex items-center">
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
                          d="M12 8c-1.657 0-3 .895-3 2s1.343 2 3 2 3 .895 3 2-1.343 2-3 2m0-8c1.11 0 2.08.402 2.599 1M12 8V7m0 1v8m0 0v1m0-1c-1.11 0-2.08-.402-2.599-1M21 12a9 9 0 11-18 0 9 9 0 0118 0z"
                        />
                      </svg>
                      <span>Budget: ৳{{ ad.budget }}</span>
                    </div>
                  </div>

                  <div
                    class="flex justify-between items-center pt-2 border-t border-gray-100"
                  >
                    <div class="flex items-center">
                      <span class="text-sm text-gray-600 mr-2">Contact:</span>
                      <div
                        v-if="ad.ad_type && ad.ad_type !== 'none'"
                        class="flex items-center"
                      >
                        <!-- Website -->
                        <template v-if="ad.ad_type === 'click_to_website'">
                          <a
                            :href="ad.ad_type_details"
                            target="_blank"
                            class="text-sm text-blue-600 flex items-center hover:underline"
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
                                d="M13.828 10.172a4 4 0 00-5.656 0l-4 4a4 4 0 105.656 5.656l1.102-1.101m-.758-4.899a4 4 0 005.656 0l4-4a4 4 0 00-5.656-5.656l-1.1 1.1"
                              />
                            </svg>
                            {{ ad.ad_type_details }}
                          </a>
                          <a
                            :href="ad.ad_type_details"
                            target="_blank"
                            class="ml-2 text-sm bg-blue-100 text-blue-700 px-2 py-0.5 rounded-md hover:bg-blue-200 transition-colors"
                          >
                            Visit
                          </a>
                        </template>

                        <!-- WhatsApp -->
                        <template v-else-if="ad.ad_type === 'call_on_whatsapp'">
                          <a
                            :href="`https://wa.me/${ad.ad_type_details.replace(
                              /[^0-9]/g,
                              ''
                            )}`"
                            target="_blank"
                            class="text-sm text-green-600 flex items-center hover:underline"
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
                                d="M3 5a2 2 0 012-2h3.28a1 1 0 01.948.684l1.498 4.493a1 1 0 01-.502 1.21l-2.257 1.13a11.042 11.042 0 005.516 5.516l1.13-2.257a1 1 0 011.21-.502l4.493 1.498a1 1 0 01.684.949V19a2 2 0 01-2 2h-1C9.716 21 3 14.284 3 6V5z"
                              />
                            </svg>
                            {{ ad.ad_type_details }}
                          </a>
                          <a
                            :href="`https://wa.me/${ad.ad_type_details?.replace(
                              /[^0-9]/g,
                              ''
                            )}`"
                            target="_blank"
                            class="ml-2 text-sm bg-green-100 text-green-700 px-2 py-0.5 rounded-md hover:bg-green-200 transition-colors"
                          >
                            WhatsApp
                          </a>
                        </template>

                        <!-- Phone -->
                        <template v-else-if="ad.ad_type === 'call_on_phone'">
                          <a
                            :href="`tel:${ad.ad_type_details}`"
                            class="text-sm text-gray-600 flex items-center hover:underline"
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
                                d="M3 5a2 2 0 012-2h3.28a1 1 0 01.948.684l1.498 4.493a1 1 0 01-.502 1.21l-2.257 1.13a11.042 11.042 0 005.516 5.516l1.13-2.257a1 1 0 011.21-.502l4.493 1.498a1 1 0 01.684.949V19a2 2 0 01-2 2h-1C9.716 21 3 14.284 3 6V5z"
                              />
                            </svg>
                            {{ ad.ad_type_details }}
                          </a>
                          <a
                            :href="`tel:${ad.ad_type_details}`"
                            class="ml-2 text-sm bg-gray-100 text-gray-800 px-2 py-0.5 rounded-md hover:bg-gray-200 transition-colors"
                          >
                            Call
                          </a>
                        </template>

                        <!-- Email -->
                        <template v-else-if="ad.ad_type === 'email_us'">
                          <a
                            :href="`mailto:${ad.ad_type_details}`"
                            class="text-sm text-purple-600 flex items-center hover:underline"
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
                                d="M3 8l7.89 5.26a2 2 0 002.22 0L21 8M5 19h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z"
                              />
                            </svg>
                            {{ ad.ad_type_details }}
                          </a>
                          <a
                            :href="`mailto:${ad.ad_type_details}`"
                            class="ml-2 text-sm bg-purple-100 text-purple-700 px-2 py-0.5 rounded-md hover:bg-purple-200 transition-colors"
                          >
                            Email
                          </a>
                        </template>
                      </div>
                      <span v-else class="text-sm text-gray-600">None</span>
                    </div>

                    <div class="flex space-x-1">
                      <button
                        @click="previewAd(ad)"
                        class="p-1 text-emerald-600 hover:bg-emerald-50 border border-gray-200 rounded-md"
                        title="Preview Ad"
                      >
                        <svg
                          xmlns="http://www.w3.org/2000/svg"
                          class="h-4 w-4"
                          fill="none"
                          viewBox="0 0 24 24"
                          stroke="currentColor"
                        >
                          <path
                            stroke-linecap="round"
                            stroke-linejoin="round"
                            stroke-width="2"
                            d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"
                          />
                          <path
                            stroke-linecap="round"
                            stroke-linejoin="round"
                            stroke-width="2"
                            d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z"
                          />
                        </svg>
                      </button>
                      <button
                        @click="toggleAdStatus(index)"
                        class="p-1 text-gray-600 hover:bg-gray-100 border border-gray-200 rounded-md"
                        :title="
                          ad.status === 'active' ? 'Pause Ad' : 'Activate Ad'
                        "
                        :disabled="ad.status === 'review'"
                      >
                        <svg
                          v-if="ad.status === 'active'"
                          xmlns="http://www.w3.org/2000/svg"
                          class="h-4 w-4"
                          fill="none"
                          viewBox="0 0 24 24"
                          stroke="currentColor"
                        >
                          <path
                            stroke-linecap="round"
                            stroke-linejoin="round"
                            stroke-width="2"
                            d="M10 9v6m4-6v6m7-3a9 9 0 11-18 0 9 9 0 0118 0z"
                          />
                        </svg>
                        <svg
                          v-else-if="ad.status === 'stopped'"
                          xmlns="http://www.w3.org/2000/svg"
                          class="h-4 w-4"
                          fill="none"
                          viewBox="0 0 24 24"
                          stroke="currentColor"
                        >
                          <path
                            stroke-linecap="round"
                            stroke-linejoin="round"
                            stroke-width="2"
                            d="M14.752 11.168l-3.197-2.132A1 1 0 0010 9.87v4.263a1 1 0 001.555.832l3.197-2.132a1 1 0 000-1.664z"
                          />
                          <path
                            stroke-linecap="round"
                            stroke-linejoin="round"
                            stroke-width="2"
                            d="M21 12a9 9 0 11-18 0 9 9 0 0118 0z"
                          />
                        </svg>
                        <svg
                          v-else
                          xmlns="http://www.w3.org/2000/svg"
                          class="h-4 w-4"
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
                      </button>
                      <button
                        @click="editAd(index)"
                        class="p-1 text-blue-600 hover:bg-blue-50 border border-gray-200 rounded-md"
                        title="Edit Ad"
                      >
                        <svg
                          xmlns="http://www.w3.org/2000/svg"
                          class="h-4 w-4"
                          fill="none"
                          viewBox="0 0 24 24"
                          stroke="currentColor"
                        >
                          <path
                            stroke-linecap="round"
                            stroke-linejoin="round"
                            stroke-width="2"
                            d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z"
                          />
                        </svg>
                      </button>
                      <button
                        @click="showDeleteConfirmation(index)"
                        class="p-1 text-red-600 hover:bg-red-50 border border-gray-200 rounded-md"
                        title="Delete Ad"
                      >
                        <svg
                          xmlns="http://www.w3.org/2000/svg"
                          class="h-4 w-4"
                          fill="none"
                          viewBox="0 0 24 24"
                          stroke="currentColor"
                        >
                          <path
                            stroke-linecap="round"
                            stroke-linejoin="round"
                            stroke-width="2"
                            d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16"
                          />
                        </svg>
                      </button>
                    </div>
                  </div>
                </div>
              </div>
            </div>

            <!-- Pagination -->
            <div class="flex justify-center mt-6">
              <nav class="flex items-center space-x-1">
                <button
                  class="px-2 py-1 text-sm border border-gray-300 text-gray-600 hover:bg-gray-50 rounded-md"
                >
                  Previous
                </button>
                <button
                  class="px-2 py-1 text-sm bg-emerald-500 text-white rounded-md"
                >
                  1
                </button>
                <button
                  class="px-2 py-1 text-sm border border-gray-300 text-gray-800 hover:bg-gray-50 rounded-md"
                >
                  2
                </button>
                <button
                  class="px-2 py-1 text-sm border border-gray-300 text-gray-800 hover:bg-gray-50 rounded-md"
                >
                  3
                </button>
                <button
                  class="px-2 py-1 text-sm border border-gray-300 text-gray-600 hover:bg-gray-50 rounded-md"
                >
                  Next
                </button>
              </nav>
            </div>
          </div>

          <!-- Right Sidebar - Tutorials and Tips -->
          <div class="w-full lg:w-1/3 space-y-5">
            <!-- Tutorial Videos Section -->
            <div class="bg-white rounded-md shadow-sm p-4">
              <h2
                class="text-sm font-medium text-gray-800 mb-3 flex items-center"
              >
                <svg
                  xmlns="http://www.w3.org/2000/svg"
                  class="h-4 w-4 mr-2 text-emerald-500"
                  fill="none"
                  viewBox="0 0 24 24"
                  stroke="currentColor"
                >
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="2"
                    d="M15 10l4.553-2.276A1 1 0 0121 8.618v6.764a1 1 0 01-1.447.894L15 14M5 18h8a2 2 0 002-2V8a2 2 0 00-2-2H5a2 2 0 00-2 2v8a2 2 0 002 2z"
                  />
                </svg>
                Tutorial Videos
              </h2>

              <div class="space-y-3">
                <!-- YouTube Embedded Videos -->
                <div
                  v-for="(video, idx) in tutorialVideos"
                  :key="idx"
                  class="border border-gray-100 rounded-md overflow-hidden"
                >
                  <div class="relative pb-[56.25%] bg-gray-100">
                    <iframe
                      class="absolute inset-0 w-full h-full"
                      :src="video.url"
                      :title="video.title"
                      allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture"
                      allowfullscreen
                    ></iframe>
                  </div>
                  <div class="p-2">
                    <h3 class="text-sm font-medium text-gray-800">
                      {{ video.title }}
                    </h3>
                    <p class="text-sm text-gray-600">{{ video.duration }}</p>
                  </div>
                </div>
              </div>

              <button
                class="w-full mt-3 px-4 py-1.5 text-sm border border-emerald-500 text-emerald-500 font-medium hover:bg-emerald-500 hover:text-white transition-colors flex justify-center items-center rounded-md"
              >
                <span class="mr-1">View All Tutorials</span>
                <svg
                  xmlns="http://www.w3.org/2000/svg"
                  class="h-3 w-3"
                  fill="none"
                  viewBox="0 0 24 24"
                  stroke="currentColor"
                >
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="2"
                    d="M9 5l7 7-7 7"
                  />
                </svg>
              </button>
            </div>

            <!-- Tips Section -->
            <div class="bg-white rounded-md shadow-sm p-4">
              <h2
                class="text-sm font-medium text-gray-800 mb-3 flex items-center"
              >
                <svg
                  xmlns="http://www.w3.org/2000/svg"
                  class="h-4 w-4 mr-2 text-emerald-500"
                  fill="none"
                  viewBox="0 0 24 24"
                  stroke="currentColor"
                >
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="2"
                    d="M9.663 17h4.673M12 3v1m6.364 1.636l-.707.707M21 12h-1M4 12H3m3.343-5.657l-.707-.707m2.828 9.9a5 5 0 117.072 0l-.548.547A3.374 3.374 0 0014 18.469V19a2 2 0 11-4 0v-.531c0-.895-.356-1.754-.988-2.386l-.548-.547z"
                  />
                </svg>
                Tips for Better Ads
              </h2>

              <div class="space-y-2">
                <div
                  v-for="(tip, idx) in adTips"
                  :key="idx"
                  class="border-l-[3px] border-emerald-100 pl-2 py-1"
                >
                  <h3 class="text-sm font-medium text-gray-800">
                    {{ tip.title }}
                  </h3>
                  <p class="text-sm text-gray-600">{{ tip.description }}</p>
                </div>
              </div>
            </div>

            <!-- Useful Steps Section -->
            <div class="bg-white rounded-md shadow-sm p-4">
              <h2
                class="text-sm font-medium text-gray-800 mb-3 flex items-center"
              >
                <svg
                  xmlns="http://www.w3.org/2000/svg"
                  class="h-4 w-4 mr-2 text-emerald-500"
                  fill="none"
                  viewBox="0 0 24 24"
                  stroke="currentColor"
                >
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="2"
                    d="M13 10V3L4 14h7v7l9-11h-7z"
                  />
                </svg>
                Useful Steps
              </h2>

              <div class="space-y-2">
                <button
                  class="w-full border border-gray-200 rounded-md p-2 hover:border-emerald-500 transition-colors text-left"
                >
                  <div class="flex justify-between items-center">
                    <div class="flex items-center">
                      <div
                        class="h-8 w-8 bg-emerald-100 rounded-md flex items-center justify-center mr-2"
                      >
                        <svg
                          xmlns="http://www.w3.org/2000/svg"
                          class="h-4 w-4 text-emerald-500"
                          fill="none"
                          viewBox="0 0 24 24"
                          stroke="currentColor"
                        >
                          <path
                            stroke-linecap="round"
                            stroke-linejoin="round"
                            stroke-width="2"
                            d="M9 12l2 2 4-4m5.618-4.016A11.955 11.955 0 0112 2.944a11.955 11.955 0 01-8.618 3.04A12.02 12.02 0 003 9c0 5.591 3.824 10.29 9 11.622 5.176-1.332 9-6.03 9-11.622 0-1.042-.133-2.052-.382-3.016z"
                          />
                        </svg>
                      </div>
                      <div>
                        <div class="text-sm font-medium">Pro Package</div>
                        <div class="text-sm text-gray-600">
                          ৳149/month or ৳1499/year
                        </div>
                      </div>
                    </div>
                    <svg
                      xmlns="http://www.w3.org/2000/svg"
                      class="h-4 w-4 text-gray-600"
                      fill="none"
                      viewBox="0 0 24 24"
                      stroke="currentColor"
                    >
                      <path
                        stroke-linecap="round"
                        stroke-linejoin="round"
                        stroke-width="2"
                        d="M9 5l7 7-7 7"
                      />
                    </svg>
                  </div>
                </button>

                <button
                  class="w-full border border-gray-200 rounded-md p-2 hover:border-emerald-500 transition-colors text-left"
                >
                  <div class="flex justify-between items-center">
                    <div class="flex items-center">
                      <div
                        class="h-8 w-8 bg-blue-100 rounded-md flex items-center justify-center mr-2"
                      >
                        <svg
                          xmlns="http://www.w3.org/2000/svg"
                          class="h-4 w-4 text-blue-600"
                          fill="none"
                          viewBox="0 0 24 24"
                          stroke="currentColor"
                        >
                          <path
                            stroke-linecap="round"
                            stroke-linejoin="round"
                            stroke-width="2"
                            d="M16 11V7a4 4 0 00-8 0v4M5 9h14l1 12H4L5 9z"
                          />
                        </svg>
                      </div>
                      <div>
                        <div class="text-sm font-medium">
                          Sell Products on eShop
                        </div>
                        <div class="text-sm text-gray-600">
                          Expand your business online
                        </div>
                      </div>
                    </div>
                    <svg
                      xmlns="http://www.w3.org/2000/svg"
                      class="h-4 w-4 text-gray-600"
                      fill="none"
                      viewBox="0 0 24 24"
                      stroke="currentColor"
                    >
                      <path
                        stroke-linecap="round"
                        stroke-linejoin="round"
                        stroke-width="2"
                        d="M9 5l7 7-7 7"
                      />
                    </svg>
                  </div>
                </button>

                <button
                  class="w-full border border-gray-200 rounded-md p-2 hover:border-emerald-500 transition-colors text-left"
                >
                  <div class="flex justify-between items-center">
                    <div class="flex items-center">
                      <div
                        class="h-8 w-8 bg-green-100 rounded-md flex items-center justify-center mr-2"
                      >
                        <svg
                          xmlns="http://www.w3.org/2000/svg"
                          class="h-4 w-4 text-green-600"
                          fill="none"
                          viewBox="0 0 24 24"
                          stroke="currentColor"
                        >
                          <path
                            stroke-linecap="round"
                            stroke-linejoin="round"
                            stroke-width="2"
                            d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0zm6 0a3 3 0 11-6 0 3 3 0 016 0z"
                          />
                        </svg>
                      </div>
                      <div>
                        <div class="text-sm font-medium">
                          Create Community Workspace
                        </div>
                        <div class="text-sm text-gray-600">
                          Connect with others on ABN
                        </div>
                      </div>
                    </div>
                    <svg
                      xmlns="http://www.w3.org/2000/svg"
                      class="h-4 w-4 text-gray-600"
                      fill="none"
                      viewBox="0 0 24 24"
                      stroke="currentColor"
                    >
                      <path
                        stroke-linecap="round"
                        stroke-linejoin="round"
                        stroke-width="2"
                        d="M9 5l7 7-7 7"
                      />
                    </svg>
                  </div>
                </button>
              </div>
            </div>
          </div>
        </div>

        <!-- Create Ad Modal -->
        <div
          v-if="showCreateAdModal"
          class="fixed inset-0 bg-black bg-opacity-50 z-50 flex items-center justify-center p-4"
        >
          <div
            class="bg-white rounded-md shadow-sm w-full max-w-4xl p-5 max-h-[80vh] overflow-y-auto"
          >
            <div class="flex justify-between items-center mb-4">
              <h3 class="text-sm font-medium text-gray-800">
                {{ editingAdIndex !== null ? "Edit Ad" : "Create New Ad" }}
              </h3>
              <button
                @click="closeCreateAdModal"
                class="text-gray-600 hover:text-gray-600 rounded-md"
              >
                <svg
                  xmlns="http://www.w3.org/2000/svg"
                  class="h-5 w-5"
                  fill="none"
                  viewBox="0 0 24 24"
                  stroke="currentColor"
                >
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="2"
                    d="M6 18L18 6M6 6l12 12"
                  />
                </svg>
              </button>
            </div>

            <div class="flex flex-col md:flex-row gap-5">
              <!-- Left side - Form -->
              <div class="w-full md:w-1/2">
                <form @submit.prevent="handleAdSubmit" class="space-y-4">
                  <!-- Ad Title -->
                  <div>
                    <label
                      for="title"
                      class="block text-sm font-medium text-gray-800"
                    >
                      Ad Title
                    </label>
                    <input
                      type="text"
                      id="title"
                      v-model="adForm.title"
                      class="mt-1 block w-full px-3 py-2 text-sm border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-emerald-500 focus:border-emerald-500"
                      placeholder="Enter a descriptive title"
                      required
                    />
                  </div>

                  <!-- Category -->
                  <div>
                    <label
                      for="category"
                      class="block text-sm font-medium text-gray-800"
                    >
                      Category
                    </label>
                    <select
                      id="category"
                      v-model="adForm.category"
                      class="mt-1 block w-full px-3 py-0.5 text-sm border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-emerald-500 focus:border-emerald-500"
                    >
                      <option value="">Select Category</option>
                      <option
                        v-for="category in abnAdsCategories"
                        :value="category.id"
                      >
                        {{ category.name }}
                      </option>
                    </select>
                  </div>

                  <!-- Gender -->
                  <div>
                    <label class="block text-sm font-medium text-gray-800"
                      >Targeted Audience</label
                    >
                    <div class="mt-1 flex space-x-4">
                      <label class="inline-flex items-center space-x-2">
                        <input
                          type="checkbox"
                          v-model="adForm.male"
                          class="form-checkbox h-5 w-5 text-emerald-500 focus:ring-emerald-400 rounded"
                        />
                        <span class="text-sm text-gray-800">Male</span>
                      </label>
                      <label class="inline-flex items-center space-x-2">
                        <input
                          type="checkbox"
                          v-model="adForm.female"
                          class="form-checkbox h-5 w-5 text-emerald-500 focus:ring-emerald-400 rounded"
                        />
                        <span class="text-sm text-gray-800">Female</span>
                      </label>
                      <label class="inline-flex items-center space-x-2">
                        <input
                          type="checkbox"
                          v-model="adForm.other"
                          value="other"
                          class="form-checkbox h-5 w-5 text-emerald-500 focus:ring-emerald-400 rounded"
                        />
                        <span class="text-sm text-gray-800">Other</span>
                      </label>
                    </div>
                  </div>

                  <!-- Age Range -->
                  <div>
                    <label class="block text-sm font-medium text-gray-800">
                      Age Range
                    </label>
                    <div class="mt-2 px-2">
                      <div class="flex justify-between mb-1">
                        <span class="text-sm text-gray-600"
                          >{{ adForm.min_age }} years</span
                        >
                        <span class="text-sm text-gray-600"
                          >{{ adForm.max_age }} years</span
                        >
                      </div>
                      <div class="relative h-1 bg-gray-200 rounded-md">
                        <!-- Track -->
                        <div
                          class="absolute h-1 bg-emerald-500 rounded-md"
                          :style="{
                            left: ((adForm.min_age - 13) / 87) * 100 + '%',
                            right:
                              100 - ((adForm.max_age - 13) / 87) * 100 + '%',
                          }"
                        ></div>

                        <!-- Min handle -->
                        <button
                          type="button"
                          class="absolute top-1/2 -translate-y-1/2 w-4 h-4 bg-white border border-emerald-500 rounded-md shadow focus:outline-none focus:ring-2 focus:ring-emerald-500"
                          :style="{
                            left: ((adForm.min_age - 13) / 87) * 100 + '%',
                          }"
                          @mousedown="startDrag('min')"
                          @touchstart="startDrag('min')"
                        ></button>

                        <!-- Max handle -->
                        <button
                          type="button"
                          class="absolute top-1/2 -translate-y-1/2 w-4 h-4 bg-white border border-emerald-500 rounded-md shadow focus:outline-none focus:ring-2 focus:ring-emerald-500"
                          :style="{
                            left: ((adForm.max_age - 13) / 87) * 100 + '%',
                          }"
                          @mousedown="startDrag('max')"
                          @touchstart="startDrag('max')"
                        ></button>
                      </div>

                      <!-- Click track for quick adjustment -->
                      <div
                        class="relative h-6 mt-1 cursor-pointer"
                        @click="clickTrack"
                      >
                        <div class="absolute inset-0 flex justify-between px-1">
                          <span class="text-xs text-gray-600">13</span>
                          <span class="text-xs text-gray-600">100</span>
                        </div>
                      </div>
                    </div>
                  </div>

                  <!-- Country -->
                  <div>
                    <label
                      for="country"
                      class="block text-sm font-medium text-gray-800"
                    >
                      Country
                    </label>
                    <select
                      id="country"
                      v-model="adForm.country"
                      class="mt-1 block w-full px-3 py-0.5 text-sm border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-emerald-500 focus:border-emerald-500"
                      disabled
                    >
                      <option value="bangladesh">Bangladesh</option>
                    </select>
                    <p class="mt-1 text-sm text-gray-600">
                      Currently only available in Bangladesh
                    </p>
                  </div>

                  <!-- Ad Type -->
                  <div>
                    <label
                      for="adType"
                      class="block text-sm font-medium text-gray-800"
                    >
                      Ad Type
                    </label>
                    <select
                      id="adType"
                      v-model="adForm.ad_type"
                      class="mt-1 block w-full px-3 py-0.5 text-sm border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-emerald-500 focus:border-emerald-500"
                    >
                      <option value="">Select Ad Type</option>
                      <option value="click_to_website">Click to Website</option>
                      <option value="call_on_whatsapp">Call on WhatsApp</option>
                      <option value="call_on_phone">Call on Phone</option>
                      <option value="email_us">Email Us</option>
                    </select>
                  </div>

                  <!-- Contact Info based on Ad Type -->
                  <div v-if="adForm.ad_type && adForm.ad_type !== 'none'">
                    <label
                      :for="`${adForm.ad_type}Contact`"
                      class="block text-sm font-medium text-gray-800"
                    >
                      {{ adTypeLabels[adForm.ad_type] }}
                    </label>
                    <input
                      :type="adTypeInputTypes[adForm.ad_type]"
                      :id="`${adForm.ad_type}Contact`"
                      v-model="adForm.ad_type_details"
                      class="mt-1 block w-full px-3 py-2 text-sm border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-emerald-500 focus:border-emerald-500"
                      :placeholder="adTypePlaceholders[adForm.ad_type]"
                      required
                    />
                  </div>

                  <!-- Description -->
                  <div>
                    <label
                      for="description"
                      class="block text-sm font-medium text-gray-800"
                    >
                      Description
                    </label>
                    <textarea
                      id="description"
                      v-model="adForm.description"
                      rows="3"
                      maxlength="150"
                      class="mt-1 block w-full px-3 py-0.5 text-sm border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-emerald-500 focus:border-emerald-500"
                      placeholder="Describe your product or service in detail (max 150 characters)"
                      required
                    ></textarea>
                    <p class="mt-1 text-sm text-gray-600">
                      {{ adForm.description.length }}/150 characters
                    </p>
                  </div>

                  <!-- Multiple Image Upload -->
                  <div>
                    <label class="block text-sm font-medium text-gray-800"
                      >Images (up to 4)</label
                    >
                    <div class="mt-1">
                      <!-- Image preview grid -->
                      <div
                        v-if="adForm.images && adForm.images.length > 0"
                        class="grid grid-cols-2 gap-2 mb-2"
                      >
                        <div
                          v-for="(image, idx) in adForm.images"
                          :key="idx"
                          class="relative rounded-md overflow-hidden bg-gray-100 h-32"
                        >
                          <img
                            :src="image"
                            alt="Ad preview"
                            class="w-full h-full object-cover"
                          />
                          <button
                            type="button"
                            @click="removeImage(idx)"
                            class="absolute top-1 right-1 bg-white rounded-md p-1 shadow-sm"
                          >
                            <svg
                              xmlns="http://www.w3.org/2000/svg"
                              class="h-4 w-4 text-gray-600"
                              fill="none"
                              viewBox="0 0 24 24"
                              stroke="currentColor"
                            >
                              <path
                                stroke-linecap="round"
                                stroke-linejoin="round"
                                stroke-width="2"
                                d="M6 18L18 6M6 6l12 12"
                              />
                            </svg>
                          </button>
                        </div>
                      </div>

                      <!-- Upload button -->
                      <label
                        v-if="adForm.images.length < 4"
                        class="flex flex-col items-center justify-center w-full h-32 border-2 border-dashed border-gray-300 rounded-md cursor-pointer hover:bg-gray-50 transition-colors"
                      >
                        <div
                          class="flex flex-col items-center justify-center pt-5 pb-6"
                        >
                          <svg
                            xmlns="http://www.w3.org/2000/svg"
                            class="h-8 w-8 text-gray-600"
                            fill="none"
                            viewBox="0 0 24 24"
                            stroke="currentColor"
                          >
                            <path
                              stroke-linecap="round"
                              stroke-linejoin="round"
                              stroke-width="2"
                              d="M4 16l4.586-4.586a2 2 0 012.828 0L16 16m-2-2l1.586-1.586a2 2 0 012.828 0L20 14m-6-6h.01M6 20h12a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v12a2 2 0 002 2z"
                            />
                          </svg>
                          <p class="mt-1 text-sm text-gray-600">
                            Click to upload image
                          </p>
                          <p class="text-sm text-gray-600">
                            PNG, JPG up to 5MB ({{ adForm.images.length }}/4)
                          </p>
                        </div>
                        <input
                          type="file"
                          class="hidden"
                          accept="image/*"
                          @change="handleImageUpload"
                        />
                      </label>

                      <!-- Max images message -->
                      <p v-else class="text-sm text-amber-600 mt-1">
                        Maximum of 4 images reached
                      </p>
                    </div>
                  </div>

                  <!-- Ad Budget -->
                  <div>
                    <label
                      for="budget"
                      class="block text-sm font-medium text-gray-800"
                    >
                      Ad Budget (৳)
                    </label>
                    <div class="mt-1 relative">
                      <input
                        type="number"
                        id="budget"
                        v-model.number="adForm.budget"
                        class="block w-full px-3 py-2 text-sm border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-emerald-500 focus:border-emerald-500"
                        placeholder="Enter ad budget"
                        min="200"
                        required
                      />
                      <div class="mt-1 flex justify-between">
                        <p class="text-sm text-gray-600">
                          Your account balance:
                          <span class="font-medium"
                            >৳{{ user?.user?.balance }}</span
                          >
                        </p>
                        <p class="text-sm text-amber-600">
                          Minimum budget: ৳200
                        </p>
                      </div>
                      <div class="mt-2 p-2 bg-blue-50 rounded-md">
                        <div
                          v-if="isCalculatingViews"
                          class="flex items-center justify-center py-1"
                        >
                          <svg
                            class="animate-spin h-4 w-4 text-blue-700"
                            xmlns="http://www.w3.org/2000/svg"
                            fill="none"
                            viewBox="0 0 24 24"
                          >
                            <circle
                              class="opacity-25"
                              cx="12"
                              cy="12"
                              r="10"
                              stroke="currentColor"
                              stroke-width="4"
                            ></circle>
                            <path
                              class="opacity-75"
                              fill="currentColor"
                              d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"
                            ></path>
                          </svg>
                          <span class="ml-2 text-sm text-blue-700 font-medium"
                            >Calculating...</span
                          >
                        </div>
                        <p v-else class="text-sm text-blue-700 font-medium">
                          Estimated Views: {{ adForm.estimated_views }}
                        </p>
                      </div>
                    </div>
                  </div>

                  <div class="pt-4 flex justify-end space-x-3">
                    <button
                      type="button"
                      @click="previewAdFromForm"
                      class="px-3 py-1.5 text-sm border border-gray-300 rounded-md shadow-sm font-medium text-gray-800 bg-white hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-emerald-500"
                    >
                      Preview
                    </button>
                    <button
                      type="button"
                      @click="closeCreateAdModal"
                      class="px-3 py-1.5 text-sm border border-gray-300 rounded-md shadow-sm font-medium text-gray-800 bg-white hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-emerald-500"
                    >
                      Cancel
                    </button>
                    <button
                      type="submit"
                      class="px-3 py-1.5 text-sm border border-transparent rounded-md shadow-sm font-medium text-white bg-emerald-500 hover:bg-emerald-600 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-emerald-500 flex items-center"
                      :disabled="isSubmitting"
                    >
                      <svg
                        v-if="isSubmitting"
                        class="animate-spin -ml-1 mr-2 h-3 w-3 text-white"
                        xmlns="http://www.w3.org/2000/svg"
                        fill="none"
                        viewBox="0 0 24 24"
                      >
                        <circle
                          class="opacity-25"
                          cx="12"
                          cy="12"
                          r="10"
                          stroke="currentColor"
                          stroke-width="4"
                        ></circle>
                        <path
                          class="opacity-75"
                          fill="currentColor"
                          d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"
                        ></path>
                      </svg>
                      {{
                        isSubmitting
                          ? "Saving..."
                          : editingAdIndex !== null
                          ? "Update Ad"
                          : "Post Ad"
                      }}
                    </button>
                  </div>
                </form>
              </div>

              <!-- Right side - Ad Preview -->
              <div class="w-full md:w-1/2 mt-5 md:mt-0">
                <div class="border rounded-md p-4 bg-gray-50">
                  <h4 class="text-sm font-medium text-gray-800 mb-2">
                    Ad Preview
                  </h4>
                  <div class="bg-white rounded-md shadow-sm overflow-hidden">
                    <!-- Ad Image Preview -->
                    <div class="h-48 bg-gray-200 relative">
                      <!-- Show first image if available -->
                      <img
                        v-if="adForm.images && adForm.images.length > 0"
                        :src="adForm.images[0]"
                        alt="Ad preview"
                        class="h-full w-full object-cover"
                      />
                      <div
                        v-else
                        class="h-full w-full flex items-center justify-center"
                      >
                        <p class="text-sm text-gray-600">No image uploaded</p>
                      </div>

                      <!-- Image count indicator -->
                      <div
                        v-if="adForm.images && adForm.images.length > 1"
                        class="absolute bottom-2 right-2 bg-black bg-opacity-60 text-white text-sm px-2 py-1 rounded-md"
                      >
                        {{ adForm.images.length }} images
                      </div>
                    </div>

                    <!-- Ad Content Preview -->
                    <div class="p-3">
                      <h3 class="font-medium text-sm mb-1 line-clamp-2">
                        {{ adForm.title || "Ad Title" }}
                      </h3>
                      <div class="flex flex-wrap items-center gap-2 mb-2">
                        <span
                          v-if="adForm.category && adForm.category !== 'none'"
                          class="bg-emerald-100 text-emerald-600 px-2 py-0.5 rounded-md text-sm"
                        >
                          {{
                            abnAdsCategories.find(
                              (cat) => cat.id === adForm.category
                            ).name
                          }}
                        </span>
                        <span class="text-gray-600 text-sm">Bangladesh</span>
                        <div class="flex flex-wrap gap-2">
                          <span
                            v-if="adForm.gender"
                            class="bg-gray-100 text-gray-600 px-2 py-0.5 rounded-md text-sm"
                          >
                            {{ adForm.gender === "male" ? "Male" : "Female" }}
                          </span>
                          <span
                            class="bg-gray-100 text-gray-600 px-2 py-0.5 rounded-md text-sm"
                          >
                            Age: {{ adForm.min_age }}-{{ adForm.max_age }}
                          </span>
                        </div>
                      </div>

                      <p class="text-gray-800 mb-3 text-sm line-clamp-3">
                        {{
                          adForm.description ||
                          "Your ad description will appear here. Make sure it is clear and concise."
                        }}
                      </p>

                      <!-- Ad Type Preview -->
                      <div class="mt-2">
                        <div
                          v-if="adForm.ad_type === 'website'"
                          class="flex items-center text-sm text-blue-600"
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
                              d="M13.828 10.172a4 4 0 00-5.656 0l-4 4a4 4 0 105.656 5.656l1.102-1.101m-.758-4.899a4 4 0 005.656 0l4-4a4 4 0 00-5.656-5.656l-1.1 1.1"
                            />
                          </svg>
                          <span>{{
                            adForm.contactInfo || "https://adsyclub.com"
                          }}</span>
                          <a
                            v-if="adForm.contactInfo"
                            :href="adForm.contactInfo"
                            target="_blank"
                            class="ml-2 text-sm bg-blue-100 text-blue-700 px-2 py-0.5 rounded-md hover:bg-blue-200 transition-colors"
                          >
                            Visit
                          </a>
                        </div>
                        <div
                          v-else-if="adForm.ad_type === 'whatsapp'"
                          class="flex items-center text-sm text-green-600"
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
                              d="M3 5a2 2 0 012-2h3.28a1 1 0 01.948.684l1.498 4.493a1 1 0 01-.502 1.21l-2.257 1.13a11.042 11.042 0 005.516 5.516l1.13-2.257a1 1 0 011.21-.502l4.493 1.498a1 1 0 01.684.949V19a2 2 0 01-2 2h-1C9.716 21 3 14.284 3 6V5z"
                            />
                          </svg>
                          <span>{{
                            adForm.contactInfo || "+8801896144067"
                          }}</span>
                          <a
                            v-if="adForm.contactInfo"
                            :href="`https://wa.me/${adForm.contactInfo.replace(
                              /[^0-9]/g,
                              ''
                            )}`"
                            target="_blank"
                            class="ml-2 text-sm bg-green-100 text-green-700 px-2 py-0.5 rounded-md hover:bg-green-200 transition-colors"
                          >
                            WhatsApp
                          </a>
                        </div>
                        <div
                          v-else-if="adForm.ad_type === 'phone'"
                          class="flex items-center text-sm text-gray-600"
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
                              d="M3 5a2 2 0 012-2h3.28a1 1 0 01.948.684l1.498 4.493a1 1 0 01-.502 1.21l-2.257 1.13a11.042 11.042 0 005.516 5.516l1.13-2.257a1 1 0 011.21-.502l4.493 1.498a1 1 0 01.684.949V19a2 2 0 01-2 2h-1C9.716 21 3 14.284 3 6V5z"
                            />
                          </svg>
                          <span>{{
                            adForm.contactInfo || "+8801896144067"
                          }}</span>
                          <a
                            v-if="adForm.contactInfo"
                            :href="`tel:${adForm.contactInfo}`"
                            class="ml-2 text-sm bg-gray-100 text-gray-800 px-2 py-0.5 rounded-md hover:bg-gray-200 transition-colors"
                          >
                            Call
                          </a>
                        </div>
                        <div
                          v-else-if="adForm.ad_type === 'email'"
                          class="flex items-center text-sm text-purple-600"
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
                              d="M3 8l7.89 5.26a2 2 0 002.22 0L21 8M5 19h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z"
                            />
                          </svg>
                          <span>{{
                            adForm.contactInfo || "example@email.com"
                          }}</span>
                          <a
                            v-if="adForm.contactInfo"
                            :href="`mailto:${adForm.contactInfo}`"
                            target="_blank"
                            class="ml-2 text-sm bg-purple-100 text-purple-700 px-2 py-0.5 rounded-md hover:bg-purple-200 transition-colors"
                          >
                            Email
                          </a>
                        </div>
                      </div>

                      <!-- Budget and Views -->
                      <div
                        class="mt-3 pt-2 border-t border-gray-100 flex justify-between items-center"
                      >
                        <span class="text-sm text-gray-600"
                          >Budget: ৳{{ adForm.budget || "0" }}</span
                        >
                        <span class="text-sm text-emerald-500">
                          Est. Views: {{ adForm.estimated_views }}
                        </span>
                      </div>
                    </div>
                  </div>

                  <div class="mt-4">
                    <h5 class="text-sm font-medium text-gray-800 mb-2">
                      Tips for Better Performance
                    </h5>
                    <ul class="text-sm text-gray-600 space-y-1 pl-4 list-disc">
                      <li>
                        Use high-quality images that clearly show your
                        product/service
                      </li>
                      <li>Keep your title concise and include keywords</li>
                      <li>Highlight key benefits in your description</li>
                      <li>Include a clear call to action</li>
                    </ul>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>

        <!-- Delete Confirmation Modal -->
        <div
          v-if="showDeleteModal"
          class="fixed inset-0 bg-black bg-opacity-50 z-50 flex items-center justify-center p-4"
        >
          <div class="bg-white rounded-md shadow-sm w-full max-w-md p-6">
            <div class="text-center mb-4">
              <svg
                xmlns="http://www.w3.org/2000/svg"
                class="h-12 w-12 mx-auto text-red-500 mb-4"
                fill="none"
                viewBox="0 0 24 24"
                stroke="currentColor"
              >
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16"
                />
              </svg>
              <h3 class="text-base font-medium text-gray-800">Delete Ad</h3>
              <p class="text-sm text-gray-600 mt-1">
                Are you sure you want to delete this ad? This action cannot be
                undone.
              </p>
            </div>
            <div class="flex justify-center space-x-3">
              <button
                @click="confirmDelete"
                class="px-4 py-1.5 text-sm border border-red-600 bg-red-600 text-white font-medium hover:bg-red-700 transition-colors flex items-center rounded-md"
                :disabled="isDeleting"
              >
                <svg
                  v-if="isDeleting"
                  class="animate-spin -ml-1 mr-2 h-3 w-3 text-white"
                  xmlns="http://www.w3.org/2000/svg"
                  fill="none"
                  viewBox="0 0 24 24"
                >
                  <circle
                    class="opacity-25"
                    cx="12"
                    cy="12"
                    r="10"
                    stroke="currentColor"
                    stroke-width="4"
                  ></circle>
                  <path
                    class="opacity-75"
                    fill="currentColor"
                    d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"
                  ></path>
                </svg>
                Delete
              </button>
              <button
                @click="cancelDelete"
                class="px-4 py-1.5 text-sm border border-gray-300 text-gray-800 font-medium hover:bg-gray-100 transition-colors rounded-md"
                :disabled="isDeleting"
              >
                Cancel
              </button>
            </div>
          </div>
        </div>

        <!-- Ad Preview Modal -->
        <div
          v-if="showPreviewModal"
          class="fixed inset-0 bg-black bg-opacity-50 z-50 flex items-center justify-center p-4"
        >
          <div
            class="bg-white rounded-md shadow-sm w-full max-w-md p-5 max-h-[80vh] overflow-y-auto"
          >
            <div class="flex justify-between items-center mb-4">
              <h3 class="text-sm font-medium text-gray-800">Ad Preview</h3>
              <button
                @click="showPreviewModal = false"
                class="text-gray-600 hover:text-gray-600 rounded-md"
              >
                <svg
                  xmlns="http://www.w3.org/2000/svg"
                  class="h-5 w-5"
                  fill="none"
                  viewBox="0 0 24 24"
                  stroke="currentColor"
                >
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="2"
                    d="M6 18L18 6M6 6l12 12"
                  />
                </svg>
              </button>
            </div>

            <div class="bg-white rounded-md shadow-sm overflow-hidden">
              <!-- Image Carousel -->
              <div class="h-56 bg-gray-200 relative">
                <div
                  v-if="previewAdData.images && previewAdData.images.length > 0"
                  class="h-full"
                >
                  <!-- Main image -->
                  <img
                    :src="previewAdData.images[currentImageIndex]"
                    alt="Ad preview"
                    class="h-full w-full object-cover"
                  />

                  <!-- Navigation arrows -->
                  <button
                    v-if="previewAdData.images.length > 1"
                    @click="prevImage"
                    class="absolute left-2 top-1/2 -translate-y-1/2 bg-black bg-opacity-50 text-white rounded-md p-1"
                  >
                    <svg
                      xmlns="http://www.w3.org/2000/svg"
                      class="h-5 w-5"
                      fill="none"
                      viewBox="0 0 24 24"
                      stroke="currentColor"
                    >
                      <path
                        stroke-linecap="round"
                        stroke-linejoin="round"
                        stroke-width="2"
                        d="M15 19l-7-7 7-7"
                      />
                    </svg>
                  </button>
                  <button
                    v-if="previewAdData.images.length > 1"
                    @click="nextImage"
                    class="absolute right-2 top-1/2 -translate-y-1/2 bg-black bg-opacity-50 text-white rounded-md p-1"
                  >
                    <svg
                      xmlns="http://www.w3.org/2000/svg"
                      class="h-5 w-5"
                      fill="none"
                      viewBox="0 0 24 24"
                      stroke="currentColor"
                    >
                      <path
                        stroke-linecap="round"
                        stroke-linejoin="round"
                        stroke-width="2"
                        d="M9 5l7 7-7 7"
                      />
                    </svg>
                  </button>

                  <!-- Image counter -->
                  <div
                    v-if="previewAdData.images.length > 1"
                    class="absolute bottom-2 right-2 bg-black bg-opacity-60 text-white text-sm px-2 py-1 rounded-md"
                  >
                    {{ currentImageIndex + 1 }}/{{
                      previewAdData.images.length
                    }}
                  </div>
                </div>
                <div
                  v-else
                  class="h-full w-full flex items-center justify-center"
                >
                  <p class="text-gray-600 text-sm">No image uploaded</p>
                </div>
              </div>

              <!-- Ad Content Preview -->
              <div class="p-4">
                <h3 class="font-medium text-sm mb-2">
                  {{ previewAdData.title || "Ad Title" }}
                </h3>
                <div class="flex flex-wrap items-center gap-2 mb-2">
                  <span
                    v-if="
                      previewAdData.category &&
                      previewAdData.category !== 'none'
                    "
                    class="bg-emerald-100 text-emerald-600 px-2 py-0.5 rounded-md text-sm"
                  >
                    {{
                      abnAdsCategories.find((cat) => cat.id === adForm.category)
                        .name
                    }}
                  </span>
                  <span class="text-gray-600 text-sm">Bangladesh</span>
                  <span
                    class="px-2 py-0.5 rounded-md text-sm"
                    :class="getStatusClass(previewAdData.status)"
                  >
                    {{ getStatusText(previewAdData.status) }}
                  </span>
                  <div class="flex flex-wrap gap-2">
                    <span
                      v-if="previewAdData.gender"
                      class="bg-gray-100 text-gray-600 px-2 py-0.5 rounded-md text-sm"
                    >
                      {{ previewAdData.gender === "male" ? "Male" : "Female" }}
                    </span>
                    <span
                      class="bg-gray-100 text-gray-600 px-2 py-0.5 rounded-md text-sm"
                    >
                      Age: {{ previewAdData.min_age }}-{{
                        previewAdData.max_age
                      }}
                    </span>
                  </div>
                </div>

                <p class="text-gray-800 mb-4 text-sm">
                  {{
                    previewAdData.description ||
                    "Your ad description will appear here. Make sure it is clear and concise."
                  }}
                </p>

                <!-- Ad Type Preview with Icons -->
                <div class="mt-3">
                  <div
                    v-if="previewAdData.ad_type === 'website'"
                    class="flex items-center"
                  >
                    <a
                      :href="previewAdData.contactInfo"
                      target="_blank"
                      class="text-sm text-blue-600 hover:underline mr-2"
                    >
                      {{ previewAdData.contactInfo }}
                    </a>
                    <a
                      :href="previewAdData.contactInfo"
                      target="_blank"
                      class="rounded-md bg-blue-100 text-blue-700 p-2 hover:bg-blue-200 transition-colors"
                    >
                      <svg
                        xmlns="http://www.w3.org/2000/svg"
                        class="h-4 w-4"
                        fill="none"
                        viewBox="0 0 24 24"
                        stroke="currentColor"
                      >
                        <path
                          stroke-linecap="round"
                          stroke-linejoin="round"
                          stroke-width="2"
                          d="M10 6H6a2 2 0 00-2 2v10a2 2 0 002 2h10a2 2 0 002-2v-4M14 4h6m0 0v6m0-6L10 14"
                        />
                      </svg>
                    </a>
                  </div>
                  <div
                    v-else-if="previewAdData.ad_type === 'whatsapp'"
                    class="flex items-center"
                  >
                    <span class="text-sm text-green-600 mr-2">{{
                      previewAdData.contactInfo
                    }}</span>
                    <a
                      :href="`https://wa.me/${previewAdData.contactInfo.replace(
                        /[^0-9]/g,
                        ''
                      )}`"
                      target="_blank"
                      class="rounded-md bg-green-100 text-green-700 p-2 hover:bg-green-200 transition-colors"
                    >
                      <svg
                        xmlns="http://www.w3.org/2000/svg"
                        class="h-4 w-4"
                        fill="none"
                        viewBox="0 0 24 24"
                        stroke="currentColor"
                      >
                        <path
                          stroke-linecap="round"
                          stroke-linejoin="round"
                          stroke-width="2"
                          d="M8 12h.01M12 12h.01M16 12h.01M21 12c0 4.418-4.03 8-9 8a9.863 9.863 0 01-4.255-.949L3 20l1.395-3.72C3.512 15.042 3 13.574 3 12c0-4.418 4.03-8 9-8s9 3.582 9 8z"
                        />
                      </svg>
                    </a>
                  </div>
                  <div
                    v-else-if="previewAdData.ad_type === 'phone'"
                    class="flex items-center"
                  >
                    <span class="text-sm text-gray-600 mr-2">{{
                      previewAdData.contactInfo
                    }}</span>
                    <a
                      :href="`tel:${previewAdData.contactInfo}`"
                      class="rounded-md bg-gray-100 text-gray-800 p-2 hover:bg-gray-200 transition-colors"
                    >
                      <svg
                        xmlns="http://www.w3.org/2000/svg"
                        class="h-4 w-4"
                        fill="none"
                        viewBox="0 0 24 24"
                        stroke="currentColor"
                      >
                        <path
                          stroke-linecap="round"
                          stroke-linejoin="round"
                          stroke-width="2"
                          d="M3 5a2 2 0 012-2h3.28a1 1 0 01.948.684l1.498 4.493a1 1 0 01-.502 1.21l-2.257 1.13a11.042 11.042 0 005.516 5.516l1.13-2.257a1 1 0 011.21-.502l4.493 1.498a1 1 0 01.684.949V19a2 2 0 01-2 2h-1C9.716 21 3 14.284 3 6V5z"
                        />
                      </svg>
                    </a>
                  </div>
                  <div
                    v-else-if="previewAdData.ad_type === 'email'"
                    class="flex items-center"
                  >
                    <span class="text-sm text-purple-600 mr-2">{{
                      previewAdData.contactInfo
                    }}</span>
                    <a
                      :href="`mailto:${previewAdData.contactInfo}`"
                      class="rounded-md bg-purple-100 text-purple-700 p-2 hover:bg-purple-200 transition-colors"
                    >
                      <svg
                        xmlns="http://www.w3.org/2000/svg"
                        class="h-4 w-4"
                        fill="none"
                        viewBox="0 0 24 24"
                        stroke="currentColor"
                      >
                        <path
                          stroke-linecap="round"
                          stroke-linejoin="round"
                          stroke-width="2"
                          d="M3 8l7.89 5.26a2 2 0 002.22 0L21 8M5 19h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z"
                        />
                      </svg>
                    </a>
                  </div>
                  <div v-else class="text-sm text-gray-600">
                    No contact information provided
                  </div>
                </div>
              </div>
            </div>

            <div class="mt-4 flex justify-end">
              <button
                @click="showPreviewModal = false"
                class="px-4 py-2 text-sm border border-gray-300 rounded-md shadow-sm font-medium text-gray-800 bg-white hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-emerald-500"
              >
                Close Preview
              </button>
            </div>
          </div>
        </div>
      </div>
    </div>
  </UContainer>
</template>

<script setup>
const { get, post } = useApi();
const { user } = useAuth();

const abnAds = ref([]);
// State
const activeTab = ref("my-ads");
const showCreateAdModal = ref(false);
const editingAdIndex = ref(null);
const isLoading = ref(false);
const isDeleting = ref(false);
const isToggling = ref(false);
const isSubmitting = ref(false);
const showDeleteModal = ref(false);
const showStopModal = ref(false);
const showPreviewModal = ref(false);
const deleteAdIndex = ref(null);
const stopAdIndex = ref(null);
const accountBalance = ref(200); // Set to 200 to show low balance alert
const dateFilter = reactive({
  from: "",
  to: "",
});

const abnAdsCategories = ref([]);
async function fetchAbnAdsCategories() {
  try {
    const response = await get("/bn/abn-ads-categories/");
    abnAdsCategories.value = response.data;
  } catch (error) {
    console.error("Error fetching categories:", error);
  }
}

await fetchAbnAdsCategories();

// Image carousel state
const currentImageIndex = ref(0);

const previewAdData = reactive({
  title: "",
  category: "",
  description: "",
  images: [],
  budget: 0,
  country: "bangladesh",
  ad_type: "",
  contactInfo: "",
  gender: "",
  min_age: 18,
  max_age: 65,
  estimated_views: 501, // Default age range
  status: "active",
});

// Ad form data
const adForm = ref({
  title: "",
  category: "",
  description: "",
  images: [],
  budget: 200, // Minimum budget is now 200
  country: "bangladesh",
  ad_type: "",
  contactInfo: "",
  male: false,
  female: false,
  other: false,
  min_age: 18,
  max_age: 65,
  estimated_views: 501,
  ad_type_details: "", // Default age range
});

// Estimated views calculation with spinner
const isCalculatingViews = ref(false);

// Watch for budget changes to trigger the spinner and calculation
watch(
  () => adForm.value.budget,
  (newValue) => {
    isCalculatingViews.value = true;

    // Set a timeout to simulate calculation (2 seconds)
    setTimeout(() => {
      const baseRate = Math.random() * (6.2 - 7.1) + 3.5;
      adForm.value.estimated_views = Math.round(newValue * baseRate);
      isCalculatingViews.value = false;
    }, 2000);
  },
  { immediate: true }
);

// Ad type configurations
const adTypeLabels = {
  website: "Website URL",
  whatsapp: "WhatsApp Number",
  phone: "Phone Number",
  email: "Email Address",
};

const adTypeInputTypes = {
  website: "url",
  whatsapp: "tel",
  phone: "tel",
  email: "email",
};

const adTypePlaceholders = {
  website: "https://adsyclub.com",
  whatsapp: "+8801896144067",
  phone: "+8801896144067",
  email: "support@adsyclub.com",
};

// Computed property to check if balance is low (under 250)
const isLowBalance = computed(() => {
  return accountBalance.value < 250;
});

const postedAds = ref([]);

async function fetchPostedAds() {
  try {
    const response = await get("/bn/abn-ads-panels/");
    postedAds.value = response.data;
  } catch (error) {
    console.error("Error fetching posted ads:", error);
  }
}

await fetchPostedAds();

// Drag handle state
const dragHandle = ref(null);

// Start drag
const startDrag = (handle) => {
  dragHandle.value = handle;
  document.addEventListener("mousemove", drag);
  document.addEventListener("mouseup", stopDrag);
  document.addEventListener("touchmove", drag);
  document.addEventListener("touchend", stopDrag);
};

// Drag function
const drag = (event) => {
  if (!dragHandle.value) return;

  let clientX = event.clientX || event.touches[0].clientX;
  let trackWidth = event.target.parentElement.offsetWidth;
  let offset = event.target.parentElement.offsetLeft;
  let position = (clientX - offset) / trackWidth;

  if (dragHandle.value === "min") {
    adForm.value.min_age = Math.max(
      13,
      Math.min(adForm.value.max_age, Math.round(position * 87 + 13))
    );
  } else if (dragHandle.value === "max") {
    adForm.value.max_age = Math.min(
      100,
      Math.max(adForm.value.min_age, Math.round(position * 87 + 13))
    );
  }
};

// Stop drag
const stopDrag = () => {
  dragHandle.value = null;
  document.removeEventListener("mousemove", drag);
  document.removeEventListener("mouseup", stopDrag);
  document.removeEventListener("touchmove", drag);
  document.removeEventListener("touchend", stopDrag);
};

// Click track
const clickTrack = (event) => {
  let trackWidth = event.target.offsetWidth;
  let offset = event.target.offsetLeft;
  let position = (event.clientX - offset) / trackWidth;
  let age = Math.round(position * 87 + 13);

  if (age < adForm.value.min_age) {
    adForm.value.min_age = age;
  } else {
    adForm.value.max_age = age;
  }
};

// Toggle ad status
const toggleAdStatus = (index) => {
  // Don't toggle if ad is in review
  if (postedAds.value[index].status === "review") return;

  // Toggle between active and stopped
  postedAds.value[index].status =
    postedAds.value[index].status === "active" ? "stopped" : "active";
};

// Apply date filter
const applyDateFilter = () => {
  console.log("Applying date filter:", dateFilter.from, dateFilter.to);
  // Implement your date filtering logic here
};

// Handle ad submission
const handleAdSubmit = async () => {
  isSubmitting.value = true;
  try {
    const res = await post("/bn/abn-ads-panels/", adForm.value);
    if (res.data) {
      adForm.value = {
        title: "",
        category: "",
        description: "",
        images: [],
        budget: 200,
        country: "bangladesh",
        ad_type: "",
        contactInfo: "",
        male: false,
        female: false,
        other: false,
        min_age: 18,
        max_age: 65,
        estimated_views: 501,
        ad_type_details: "",
      };
      closeCreateAdModal();
      await fetchPostedAds();
    }
  } catch (error) {
    console.error("Error submitting ad:", error);
    // Handle error appropriately
  } finally {
    isSubmitting.value = false;
  }
};

// Edit ad
const editAd = (index) => {
  editingAdIndex.value = index;
  Object.assign(adForm, postedAds.value[index]);
  showCreateAdModal.value = true;
};

// Preview ad
const previewAd = (ad) => {
  Object.assign(previewAdData, ad);
  currentImageIndex.value = 0; // Reset to the first image
  showPreviewModal.value = true;
};

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

// Preview ad from form
const previewAdFromForm = () => {
  Object.assign(previewAdData, adForm);
  currentImageIndex.value = 0; // Reset to the first image
  showPreviewModal.value = true;
};

// Show delete confirmation
const showDeleteConfirmation = (index) => {
  deleteAdIndex.value = index;
  showDeleteModal.value = true;
};

// Confirm delete
const confirmDelete = async () => {
  isDeleting.value = true;
  try {
    // Simulate API call
    await new Promise((resolve) => setTimeout(resolve, 1000));

    // Delete ad
    postedAds.value?.splice(deleteAdIndex.value, 1);
    cancelDelete();
  } catch (error) {
    console.error("Error deleting ad:", error);
    // Handle error appropriately
  } finally {
    isDeleting.value = false;
  }
};

// Cancel delete
const cancelDelete = () => {
  deleteAdIndex.value = null;
  showDeleteModal.value = false;
};

// Close create ad modal
const closeCreateAdModal = () => {
  showCreateAdModal.value = false;
  editingAdIndex.value = null;
  resetAdForm();
};

// Reset ad form
const resetAdForm = () => {
  Object.assign(adForm, {
    title: "",
    category: "",
    description: "",
    images: [],
    budget: 200,
    country: "bangladesh",
    ad_type: "",
    contactInfo: "",
    gender: "",
    min_age: 18,
    max_age: 65,
    estimated_views: 501,
  });
};

// Handle image upload
const handleImageUpload = (event) => {
  const files = event.target.files;
  if (files && files.length > 0) {
    for (let i = 0; i < files.length; i++) {
      const file = files[i];
      if (file.size > 12 * 1024 * 1024) {
        alert("Image size should be less than 12MB");
        continue;
      }
      if (adForm.value.images?.length < 4) {
        const reader = new FileReader();
        reader.onload = (e) => {
          adForm.value?.images.push(e.target.result);
        };
        reader.readAsDataURL(file);
      } else {
        alert("You can upload maximum 4 images");
        break;
      }
    }
  }
};

// Remove image
const removeImage = (index) => {
  adForm.value.images.splice(index, 1);
};

// Get status class
const getStatusClass = (status) => {
  switch (status) {
    case "active":
      return "bg-green-100 text-green-600";
    case "stopped":
      return "bg-red-100 text-red-600";
    case "pending":
      return "bg-amber-100 text-amber-600";
    default:
      return "bg-gray-100 text-gray-600";
  }
};

// Get status text
const getStatusText = (status) => {
  switch (status) {
    case "active":
      return "Active";
    case "stopped":
      return "Stopped";
    case "review":
      return "Under Review";
    default:
      return "Unknown";
  }
};

// Image carousel navigation
const nextImage = () => {
  currentImageIndex.value =
    (currentImageIndex.value + 1) % previewAdData.images.length;
};

const prevImage = () => {
  currentImageIndex.value =
    (currentImageIndex.value - 1 + previewAdData.images.length) %
    previewAdData.images.length;
};

// Sample tutorial videos
const tutorialVideos = ref([
  {
    title: "How to Create an Effective Ad",
    url: "https://www.youtube.com/embed/your_video_id_1",
    duration: "5:30",
  },
  {
    title: "Tips for Targeting the Right Audience",
    url: "https://www.youtube.com/embed/your_video_id_2",
    duration: "7:15",
  },
]);

// Sample ad tips
const adTips = ref([
  {
    title: "Use High-Quality Images",
    description:
      "Eye-catching visuals can significantly increase ad engagement.",
  },
  {
    title: "Write a Clear and Concise Description",
    description:
      "Highlight the key benefits of your product or service in a few words.",
  },
  {
    title: "Target the Right Audience",
    description:
      "Ensure your ad reaches the people who are most likely to be interested.",
  },
]);
//calculate total views using computed
const totalViews = computed(() => {
  return postedAds.value?.reduce((total, ad) => total + ad.views, 0);
});
</script>
