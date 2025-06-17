<template>
  <UContainer>
    <div>
      <!-- Premium Hero Section -->
      <div
        class="relative bg-gradient-to-br from-amber-50 via-yellow-50 to-orange-50 dark:from-amber-950/30 dark:via-yellow-950/20 dark:to-orange-950/30 overflow-hidden"
      >
        <!-- Floating Elements -->
        <div class="absolute inset-0 overflow-hidden">
          <div
            class="absolute top-20 left-10 w-4 h-4 bg-amber-400/20 rounded-full animate-pulse"
          ></div>
          <div
            class="absolute top-40 right-20 w-6 h-6 bg-yellow-400/30 rounded-full animate-pulse"
            style="animation-delay: 0.5s"
          ></div>
          <div
            class="absolute bottom-20 left-1/4 w-3 h-3 bg-orange-400/25 rounded-full animate-pulse"
            style="animation-delay: 1s"
          ></div>
          <div
            class="absolute top-60 right-1/3 w-5 h-5 bg-amber-300/20 rounded-full animate-pulse"
            style="animation-delay: 1.5s"
          ></div>
        </div>

        <!-- Premium Pattern Overlay -->
        <div class="absolute inset-0 opacity-5">
          <div
            class="h-full w-full"
            style="
              background-image: radial-gradient(
                circle at 1px 1px,
                rgba(251, 191, 36, 0.3) 1px,
                transparent 0
              );
              background-size: 50px 50px;
            "
          ></div>
        </div>

        <div class="container mx-auto py-6 px-4 relative">
          <div class="text-center max-w-4xl mx-auto">
            <!-- Premium Badge -->
            <div
              class="inline-flex items-center gap-2 bg-gradient-to-r from-amber-500 to-yellow-500 text-white px-4 py-2 rounded-full text-sm font-medium mb-6 shadow-sm"
            >
              <UIcon name="i-heroicons-sparkles" class="w-4 h-4" />
              <span>Premium Gold Sponsors</span>
              <UIcon name="i-heroicons-sparkles" class="w-4 h-4" />
            </div>

            <!-- Main Heading -->
            <h1
              class="text-4xl md:text-5xl lg:text-6xl font-bold mb-6 leading-tight"
            >
              <span
                class="text-gold-gradient-enhanced bg-clip-text text-transparent"
              >
                {{ $t("gold_sponsors") }}
              </span>
            </h1>

            <!-- Subtitle -->
            <p
              class="text-xl md:text-2xl text-gray-600 dark:text-gray-300 mb-4 font-light"
            >
              Meet our prestigious partners who power our business network
            </p>

            <!-- Description -->
            <p
              class="text-gray-600 dark:text-gray-400 max-w-2xl mx-auto mb-8 text-lg leading-relaxed"
            >
              Discover exceptional businesses that support and contribute to our
              thriving community. These gold sponsors represent excellence,
              innovation, and commitment to business growth.
            </p>

            <!-- Stats Bar -->
            <div class="flex flex-wrap justify-center gap-8 text-center">
              <div
                class="bg-white/60 dark:bg-slate-800/60 backdrop-blur-sm rounded-xl px-6 py-4 border border-amber-200/50 dark:border-amber-800/50"
              >
                <div
                  class="text-2xl font-bold text-amber-600 dark:text-amber-400"
                >
                  {{ sponsors.length }}
                </div>
                <div class="text-sm text-gray-600 dark:text-gray-400">
                  Active Sponsors
                </div>
              </div>
              <div
                class="bg-white/60 dark:bg-slate-800/60 backdrop-blur-sm rounded-xl px-6 py-4 border border-amber-200/50 dark:border-amber-800/50"
              >
                <div
                  class="text-2xl font-bold text-amber-600 dark:text-amber-400"
                >
                  {{ totalViews }}
                </div>
                <div class="text-sm text-gray-600 dark:text-gray-400">
                  Total Views
                </div>
              </div>
              <div
                class="bg-white/60 dark:bg-slate-800/60 backdrop-blur-sm rounded-xl px-6 py-4 border border-amber-200/50 dark:border-amber-800/50"
              >
                <div
                  class="text-2xl font-bold text-amber-600 dark:text-amber-400"
                >
                  Premium
                </div>
                <div class="text-sm text-gray-600 dark:text-gray-400">
                  Partnership
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- Main Content -->
      <div class="container mx-auto py-8 px-4">
        <!-- Filter and View Options -->
        <div
          class="flex flex-col sm:flex-row justify-between items-center mb-8 gap-4"
        >
          <div class="flex items-center gap-4">
            <div class="relative">
              <UIcon
                name="i-heroicons-magnifying-glass"
                class="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400 w-5 h-5"
              />
              <input
                v-model="searchQuery"
                type="text"
                placeholder="Search sponsors..."
                class="pl-10 pr-4 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-amber-500 focus:border-amber-500 dark:bg-slate-700 dark:text-white"
              />
            </div>
          </div>

          <div class="flex items-center gap-3">
            <span class="text-sm text-gray-600 dark:text-gray-400">View:</span>
            <button
              @click="viewMode = 'grid'"
              :class="
                viewMode === 'grid'
                  ? 'bg-amber-500 text-white'
                  : 'bg-gray-100 dark:bg-gray-700 text-gray-600 dark:text-gray-400 flex items-center justify-center'
              "
              class="p-2 rounded-lg transition-all duration-200"
            >
              <UIcon name="i-heroicons-squares-2x2" class="w-5 h-5" />
            </button>
            <button
              @click="viewMode = 'list'"
              :class="
                viewMode === 'list'
                  ? 'bg-amber-500 text-white'
                  : 'bg-gray-100 dark:bg-gray-700 text-gray-600 dark:text-gray-400 flex items-center'
              "
              class="p-2 rounded-lg transition-all duration-200"
            >
              <UIcon name="i-heroicons-list-bullet" class="w-5 h-5" />
            </button>
          </div>
        </div>

        <!-- Loading State -->
        <template v-if="isLoading">
          <div
            :class="
              viewMode === 'grid'
                ? 'grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-8'
                : 'space-y-6'
            "
          >
            <div v-for="i in 6" :key="i" class="animate-pulse">
              <div
                v-if="viewMode === 'grid'"
                class="bg-white dark:bg-slate-800 rounded-2xl border border-gray-200 dark:border-gray-700 overflow-hidden"
              >
                <div
                  class="h-48 bg-gradient-to-r from-amber-100 to-yellow-100 dark:from-amber-900/30 dark:to-yellow-900/30"
                ></div>
                <div class="p-6">
                  <div class="flex items-center gap-4 mb-4">
                    <div
                      class="w-16 h-16 bg-amber-200 dark:bg-amber-800 rounded-full"
                    ></div>
                    <div class="flex-1">
                      <div
                        class="h-5 bg-amber-200 dark:bg-amber-800 rounded w-3/4 mb-2"
                      ></div>
                      <div
                        class="h-4 bg-amber-100 dark:bg-amber-900 rounded w-1/2"
                      ></div>
                    </div>
                  </div>
                  <div class="space-y-2">
                    <div class="h-4 bg-gray-200 dark:bg-gray-700 rounded"></div>
                    <div
                      class="h-4 bg-gray-200 dark:bg-gray-700 rounded w-5/6"
                    ></div>
                  </div>
                </div>
              </div>
              <div
                v-else
                class="bg-white dark:bg-slate-800 rounded-2xl border border-gray-200 dark:border-gray-700 p-6"
              >
                <div class="flex gap-6">
                  <div
                    class="w-24 h-24 bg-amber-200 dark:bg-amber-800 rounded-xl"
                  ></div>
                  <div class="flex-1 space-y-3">
                    <div
                      class="h-6 bg-amber-200 dark:bg-amber-800 rounded w-1/3"
                    ></div>
                    <div class="h-4 bg-gray-200 dark:bg-gray-700 rounded"></div>
                    <div
                      class="h-4 bg-gray-200 dark:bg-gray-700 rounded w-4/5"
                    ></div>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </template>

        <!-- Error State -->
        <template v-else-if="error">
          <div class="text-center py-16">
            <div
              class="bg-white dark:bg-slate-800 rounded-2xl border border-red-200 dark:border-red-800 p-8 max-w-md mx-auto"
            >
              <UIcon
                name="i-heroicons-exclamation-triangle"
                class="w-16 h-16 mx-auto mb-4 text-red-500"
              />
              <h3
                class="text-xl font-semibold text-red-600 dark:text-red-400 mb-2"
              >
                {{ error }}
              </h3>
              <p class="text-gray-600 dark:text-gray-400 mb-6">
                Please try again later or contact support if the problem
                persists.
              </p>
              <button
                @click="fetchGoldSponsors"
                class="px-6 py-3 bg-gradient-to-r from-red-500 to-red-600 text-white rounded-xl hover:from-red-600 hover:to-red-700 transition-all duration-300 flex items-center gap-2 mx-auto"
              >
                <UIcon name="i-heroicons-arrow-path" class="w-5 h-5" />
                Retry
              </button>
            </div>
          </div>
        </template>

        <!-- Empty State -->
        <template v-else-if="filteredSponsors.length === 0">
          <div class="text-center py-16">
            <div
              class="bg-gradient-to-br from-amber-50 to-yellow-50 dark:from-amber-950/20 dark:to-yellow-950/20 rounded-2xl border border-amber-200 dark:border-amber-800 p-12 max-w-lg mx-auto"
            >
              <div class="relative mb-6">
                <UIcon
                  name="i-heroicons-star"
                  class="w-20 h-20 mx-auto text-amber-400"
                />
                <div class="absolute inset-0 animate-ping">
                  <UIcon
                    name="i-heroicons-star"
                    class="w-20 h-20 mx-auto text-amber-300 opacity-75"
                  />
                </div>
              </div>
              <h3
                class="text-2xl font-bold text-amber-600 dark:text-amber-400 mb-4"
              >
                {{ searchQuery ? "No sponsors found" : "No gold sponsors yet" }}
              </h3>
              <p class="text-gray-600 dark:text-gray-400 mb-8 text-lg">
                {{
                  searchQuery
                    ? "Try adjusting your search terms."
                    : "Be the first to become a gold sponsor and get featured prominently!"
                }}
              </p>
              <NuxtLink
                v-if="!searchQuery"
                to="/contact"
                class="inline-flex items-center gap-2 px-8 py-4 bg-gradient-to-r from-amber-500 to-yellow-500 text-white rounded-xl hover:from-amber-600 hover:to-yellow-600 transition-all duration-300 font-semibold text-lg shadow-sm hover:shadow-sm transform hover:-translate-y-1"
              >
                <UIcon name="i-heroicons-sparkles" class="w-5 h-5" />
                Become a Sponsor
              </NuxtLink>
            </div>
          </div>
        </template>

        <!-- Gold Sponsors Content -->
        <template v-else>
          <!-- Grid View -->
          <div
            v-if="viewMode === 'grid'"
            class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-8"
          >
            <div
              v-for="(sponsor, index) in filteredSponsors"
              :key="sponsor.id"
              class="group transform transition-all duration-500 hover:-translate-y-2"
            >
              <div
                class="bg-white dark:bg-slate-800 rounded-2xl border border-gray-200 dark:border-gray-700 overflow-hidden shadow-sm hover:shadow-sm transition-all duration-500 group-hover:border-amber-300 dark:group-hover:border-amber-600"
              >
                <!-- Banner Section -->
                <div
                  class="relative h-48 bg-gradient-to-br from-amber-50 to-yellow-100 dark:from-amber-900/20 dark:to-yellow-900/30 overflow-hidden"
                >
                  <div
                    v-if="sponsor.banners && sponsor.banners.length > 0"
                    class="relative h-full"
                  >
                    <img
                      :src="sponsor.banners[0].image"
                      :alt="sponsor.banners[0].title || sponsor.name"
                      class="w-full h-full object-cover transition-transform duration-700 group-hover:scale-110"
                    />
                    <div
                      class="absolute inset-0 bg-gradient-to-t from-black/20 to-transparent"
                    ></div>
                  </div>
                  <div v-else class="flex items-center justify-center h-full">
                    <div
                      class="text-center text-amber-600/50 dark:text-amber-400/50"
                    >
                      <UIcon
                        name="i-heroicons-building-office"
                        class="w-16 h-16 mx-auto mb-2"
                      />
                      <p class="text-sm font-medium">{{ sponsor.name }}</p>
                    </div>
                  </div>

                  <!-- Premium Badge -->
                  <div
                    class="absolute top-4 right-4 bg-gradient-to-r from-amber-500 to-yellow-500 text-white px-3 py-1 rounded-full text-xs font-bold shadow-sm"
                  >
                    <UIcon
                      name="i-heroicons-star"
                      class="w-3 h-3 inline mr-1"
                    />
                    GOLD
                  </div>
                </div>

                <!-- Content Section -->
                <div class="p-6">
                  <!-- Profile Header -->
                  <div class="flex items-center gap-4 mb-4">
                    <div class="relative">
                      <div
                        class="absolute inset-0 rounded-full golden-border opacity-75 group-hover:opacity-100 transition-opacity duration-300"
                      ></div>
                      <img
                        :src="
                          sponsor.image ||
                          '/static/frontend/images/placeholder.jpg'
                        "
                        :alt="sponsor.name"
                        class="w-16 h-16 rounded-full object-cover border-2 border-white dark:border-slate-700 relative z-10 transition-transform duration-300 group-hover:scale-105"
                      />
                      <div
                        class="absolute -bottom-1 -right-1 bg-gradient-to-r from-amber-500 to-yellow-500 text-white rounded-full w-6 h-6 flex items-center justify-center shadow-sm z-20"
                      >
                        <UIcon name="i-heroicons-star" class="w-3 h-3" />
                      </div>
                    </div>

                    <div class="flex-1 min-w-0">
                      <h3
                        class="text-xl font-bold text-gray-900 dark:text-white group-hover:text-amber-600 dark:group-hover:text-amber-400 transition-colors duration-300 truncate"
                      >
                        {{ sponsor.name }}
                      </h3>
                      <p
                        class="text-sm text-amber-600 dark:text-amber-400 font-medium"
                      >
                        Gold Sponsor
                      </p>
                    </div>
                  </div>
                  <!-- Description -->
                  <div class="mb-6">
                    <div
                      v-html="
                        sponsor.business_description ||
                        `${sponsor.name} is a prestigious gold sponsor contributing to our business network community.`
                      "
                      class="text-gray-600 dark:text-gray-300 text-sm leading-relaxed line-clamp-3"
                    ></div>
                  </div>
                  <!-- Contact Info -->
                  <div class="space-y-2 mb-6">
                    <div
                      v-if="sponsor.contact_email"
                      class="flex items-center gap-2 text-sm text-gray-600 dark:text-gray-400"
                    >
                      <UIcon
                        name="i-heroicons-envelope"
                        class="w-4 h-4 text-amber-500"
                      />
                      <span class="truncate">{{ sponsor.contact_email }}</span>
                    </div>
                    <div
                      v-if="sponsor.phone_number"
                      class="flex items-center gap-2 text-sm text-gray-600 dark:text-gray-400"
                    >
                      <UIcon
                        name="i-heroicons-phone"
                        class="w-4 h-4 text-amber-500"
                      />
                      <span>{{ sponsor.phone_number }}</span>
                    </div>
                    <div
                      v-if="sponsor.website"
                      class="flex items-center gap-2 text-sm text-gray-600 dark:text-gray-400"
                    >
                      <UIcon
                        name="i-heroicons-globe-alt"
                        class="w-4 h-4 text-amber-500"
                      />
                      <span class="truncate">{{
                        sponsor.website.replace(/^https?:\/\//, "")
                      }}</span>
                    </div>
                  </div>

                  <!-- Action Buttons -->
                  <div class="flex flex-col sm:flex-row gap-3">
                    <NuxtLink
                      v-if="sponsor.profile_url"
                      :to="sponsor.profile_url"
                      :target="
                        sponsor.profile_url.startsWith('http')
                          ? '_blank'
                          : '_self'
                      "
                      class="flex-1 bg-gradient-to-r from-amber-500 to-yellow-500 hover:from-amber-600 hover:to-yellow-600 text-white py-3 px-4 rounded-xl font-semibold transition-all duration-300 text-center text-sm flex items-center justify-center gap-2"
                    >
                      <UIcon
                        name="i-heroicons-arrow-top-right-on-square"
                        class="w-4 h-4"
                      />
                      Visit Website
                    </NuxtLink>
                    <a
                      v-if="sponsor.contact_email"
                      :href="`mailto:${sponsor.contact_email}`"
                      class="flex-1 border-2 border-amber-300 dark:border-amber-600 text-amber-600 dark:text-amber-400 hover:bg-amber-50 dark:hover:bg-amber-900/20 py-3 px-4 rounded-xl font-semibold transition-all duration-300 text-center text-sm flex items-center justify-center gap-2"
                    >
                      <UIcon name="i-heroicons-envelope" class="w-4 h-4" />
                      Contact
                    </a>
                  </div>
                </div>
              </div>
            </div>
          </div>
          <!-- List View -->
          <div v-else class="space-y-6">
            <div
              v-for="(sponsor, index) in filteredSponsors"
              :key="sponsor.id"
              class="group"
            >
              <div
                class="bg-white dark:bg-slate-800 rounded-2xl border border-gray-200 dark:border-gray-700 p-6 hover:shadow-sm transition-all duration-500 group-hover:border-amber-300 dark:group-hover:border-amber-600"
              >
                <div class="flex flex-col md:flex-row gap-6">
                  <!-- Profile Section -->
                  <div class="flex items-center gap-4 md:w-80 flex-shrink-0">
                    <div class="relative">
                      <div
                        class="absolute inset-0 rounded-xl golden-border opacity-75 group-hover:opacity-100 transition-opacity duration-300"
                      ></div>
                      <img
                        :src="
                          sponsor.image ||
                          '/static/frontend/images/placeholder.jpg'
                        "
                        :alt="sponsor.name"
                        class="w-20 h-20 rounded-xl object-cover border-2 border-white dark:border-slate-700 relative z-10"
                      />
                      <div
                        class="absolute -bottom-2 -right-2 bg-gradient-to-r from-amber-500 to-yellow-500 text-white rounded-full w-8 h-8 flex items-center justify-center shadow-sm z-20"
                      >
                        <UIcon name="i-heroicons-star" class="w-4 h-4" />
                      </div>
                    </div>

                    <div class="flex-1 min-w-0">
                      <h3
                        class="text-xl font-bold text-gray-900 dark:text-white group-hover:text-amber-600 dark:group-hover:text-amber-400 transition-colors duration-300"
                      >
                        {{ sponsor.name }}
                      </h3>
                      <p
                        class="text-sm text-amber-600 dark:text-amber-400 font-medium mb-2"
                      >
                        Gold Sponsor
                      </p>
                      <div
                        class="flex items-center gap-4 text-xs text-gray-600 dark:text-gray-400"
                      >
                        <span
                          v-if="sponsor.package"
                          class="flex items-center gap-1"
                        >
                          <UIcon name="i-heroicons-tag" class="w-3 h-3" />
                          {{ sponsor.package.name }}
                        </span>
                        <span class="flex items-center gap-1">
                          <UIcon name="i-heroicons-eye" class="w-3 h-3" />
                          {{ sponsor.views || 0 }} views
                        </span>
                      </div>
                    </div>
                  </div>
                  <!-- Content Section -->
                  <div class="flex-1 min-w-0">
                    <!-- Description -->
                    <div
                      v-html="
                        sponsor.business_description ||
                        `${sponsor.name} is a prestigious gold sponsor contributing to our business network community.`
                      "
                      class="text-gray-600 dark:text-gray-300 mb-4 leading-relaxed line-clamp-2"
                    ></div>

                    <!-- Contact Grid -->
                    <div class="grid grid-cols-1 sm:grid-cols-2 gap-3 mb-4">
                      <div
                        v-if="sponsor.contact_email"
                        class="flex items-center gap-2 text-sm text-gray-600 dark:text-gray-400"
                      >
                        <UIcon
                          name="i-heroicons-envelope"
                          class="w-4 h-4 text-amber-500 flex-shrink-0"
                        />
                        <span class="truncate">{{
                          sponsor.contact_email
                        }}</span>
                      </div>
                      <div
                        v-if="sponsor.phone_number"
                        class="flex items-center gap-2 text-sm text-gray-600 dark:text-gray-400"
                      >
                        <UIcon
                          name="i-heroicons-phone"
                          class="w-4 h-4 text-amber-500 flex-shrink-0"
                        />
                        <span>{{ sponsor.phone_number }}</span>
                      </div>
                      <div
                        v-if="sponsor.website"
                        class="flex items-center gap-2 text-sm text-gray-600 dark:text-gray-400"
                      >
                        <UIcon
                          name="i-heroicons-globe-alt"
                          class="w-4 h-4 text-amber-500 flex-shrink-0"
                        />
                        <span class="truncate">{{
                          sponsor.website.replace(/^https?:\/\//, "")
                        }}</span>
                      </div>
                      <div
                        class="flex items-center gap-2 text-sm text-gray-600 dark:text-gray-400"
                      >
                        <UIcon
                          name="i-heroicons-calendar"
                          class="w-4 h-4 text-amber-500 flex-shrink-0"
                        />
                        <span
                          >Since
                          {{ new Date(sponsor.start_date).getFullYear() }}</span
                        >
                      </div>
                    </div>

                    <!-- Banners Preview -->
                    <div
                      v-if="sponsor.banners && sponsor.banners.length > 0"
                      class="flex gap-2 mb-4"
                    >
                      <div
                        v-for="(banner, bannerIndex) in sponsor.banners.slice(
                          0,
                          3
                        )"
                        :key="bannerIndex"
                        class="w-16 h-10 rounded border border-gray-200 dark:border-gray-600 overflow-hidden"
                      >
                        <img
                          :src="banner.image"
                          :alt="banner.title"
                          class="w-full h-full object-cover"
                        />
                      </div>
                      <div
                        v-if="sponsor.banners.length > 3"
                        class="w-16 h-10 rounded border border-gray-200 dark:border-gray-600 bg-gray-100 dark:bg-gray-700 flex items-center justify-center text-xs text-gray-600"
                      >
                        +{{ sponsor.banners.length - 3 }}
                      </div>
                    </div>
                  </div>
                  <!-- Action Section -->
                  <div
                    class="flex flex-col justify-center gap-3 md:w-32 flex-shrink-0"
                  >
                    <NuxtLink
                      v-if="sponsor.website"
                      :to="sponsor.website"
                      :target="
                        sponsor.website.startsWith('http') ? '_blank' : '_self'
                      "
                      class="px-4 py-2 bg-gradient-to-r from-amber-500 to-yellow-500 hover:from-amber-600 hover:to-yellow-600 text-white rounded-lg font-medium transition-all duration-300 text-sm text-center"
                    >
                      Visit Website
                    </NuxtLink>
                    <a
                      v-if="sponsor.contact_email"
                      :href="`mailto:${sponsor.contact_email}`"
                      class="px-4 py-2 border border-amber-300 dark:border-amber-600 text-amber-600 dark:text-amber-400 hover:bg-amber-50 dark:hover:bg-amber-900/20 rounded-lg font-medium transition-all duration-300 text-sm text-center"
                    >
                      Contact
                    </a>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </template>
      </div>
    </div>
  </UContainer>
</template>

<script setup>
import { ref, onMounted, computed } from "vue";
import { useApi } from "~/composables/useApi";

const { get } = useApi();

// Data
const sponsors = ref([]);
const isLoading = ref(true);
const error = ref(null);

// UI State
const searchQuery = ref("");
const viewMode = ref("list");

// Computed properties
const filteredSponsors = computed(() => {
  if (!searchQuery.value) {
    return sponsors.value;
  }

  const query = searchQuery.value.toLowerCase();
  return sponsors.value.filter(
    (sponsor) =>
      sponsor.name.toLowerCase().includes(query) ||
      (sponsor.business_description &&
        sponsor.business_description.toLowerCase().includes(query)) ||
      (sponsor.contact_email &&
        sponsor.contact_email.toLowerCase().includes(query))
  );
});

const totalViews = computed(() => {
  return sponsors.value.reduce(
    (total, sponsor) => total + (sponsor.views || 0),
    0
  );
});

// Fetch gold sponsors
async function fetchGoldSponsors() {
  try {
    isLoading.value = true;
    error.value = null;

    // Fetch active/featured gold sponsors from API
    const result = await get("/bn/gold-sponsors/list/");

    // Check if the API call was successful
    if (result.error) {
      console.error("API Error:", result.error);
      error.value = "Failed to load gold sponsors";
      sponsors.value = [];
    } else if (result.data && Array.isArray(result.data)) {
      // Map API response to component format
      sponsors.value = result.data.map((sponsor) => ({
        id: sponsor.id,
        name: sponsor.business_name,
        image: sponsor.logo
          ? sponsor.logo
          : "/static/frontend/images/placeholder.jpg",
        business_description: sponsor.business_description,
        contact_email: sponsor.contact_email,
        phone_number: sponsor.phone_number,
        website: sponsor.website,
        profile_url: sponsor.profile_url,
        package: sponsor.package,
        start_date: sponsor.start_date,
        end_date: sponsor.end_date,
        status: sponsor.status,
        is_featured: sponsor.is_featured,
        views: sponsor.views || 0,
        banners: sponsor.banners || [],
      }));
    } else {
      sponsors.value = [];
    }

    isLoading.value = false;
  } catch (err) {
    console.error("Error fetching gold sponsors:", err);
    error.value = "Failed to load gold sponsors";
    isLoading.value = false;

    // Fallback to empty array instead of dummy data
    sponsors.value = [];
  }
}

onMounted(() => {
  fetchGoldSponsors();
});
</script>

<style scoped>
/* Golden border animation */
.golden-border {
  background: linear-gradient(
    45deg,
    #f59e0b,
    #f59e0b 25%,
    #eab308 50%,
    #f59e0b 75%,
    #f59e0b
  );
  opacity: 0.7;
  border-radius: inherit;
  transform: scale(1.1);
  z-index: -1;
  animation: spin 12s linear infinite;
}

@keyframes spin {
  100% {
    transform: scale(1.1) rotate(360deg);
  }
}

/* Enhanced gradient text effects */
.text-gold-gradient {
  background: linear-gradient(to right, #d97706, #fbbf24, #d97706);
  -webkit-background-clip: text;
  background-clip: text;
  color: transparent;
}

.text-gold-gradient-premium {
  background: linear-gradient(
    135deg,
    #f59e0b,
    #fbbf24,
    #eab308,
    #fbbf24,
    #f59e0b
  );
  background-size: 400% 400%;
  -webkit-background-clip: text;
  background-clip: text;
  color: transparent;
  animation: gradientShift 4s ease-in-out infinite;
}

.text-gold-gradient-enhanced {
  background: linear-gradient(
    135deg,
    #d97706,
    #f59e0b,
    #fbbf24,
    #eab308,
    #f59e0b,
    #d97706
  );
  background-size: 400% 400%;
  -webkit-background-clip: text;
  background-clip: text;
  color: transparent;
  animation: gradientShift 6s ease-in-out infinite;
}

@keyframes gradientShift {
  0%,
  100% {
    background-position: 0% 50%;
  }
  50% {
    background-position: 100% 50%;
  }
}

/* Line clamp utility */
.line-clamp-2 {
  display: -webkit-box;
  -webkit-line-clamp: 2;
  line-clamp: 2;
  -webkit-box-orient: vertical;
  overflow: hidden;
}

.line-clamp-3 {
  display: -webkit-box;
  -webkit-line-clamp: 3;
  line-clamp: 3;
  -webkit-box-orient: vertical;
  overflow: hidden;
}

/* Professional hover effects */
.group:hover .golden-border {
  opacity: 1;
  animation-duration: 8s;
}

/* Premium card shadows */
.hover\:shadow-sm:hover {
  box-shadow: 0 25px 50px -12px rgba(0, 0, 0, 0.25),
    0 0 0 1px rgba(245, 158, 11, 0.1);
}

/* Enhanced backdrop blur */
.backdrop-blur-sm {
  backdrop-filter: blur(4px);
}

/* Floating elements animation refinement */
@keyframes float {
  0%,
  100% {
    transform: translateY(0px);
  }
  50% {
    transform: translateY(-4px);
  }
}

.animate-float {
  animation: float 3s ease-in-out infinite;
}

.animate-float-delayed {
  animation: float 3s ease-in-out infinite;
  animation-delay: 1s;
}

/* Professional transitions */
.transition-all {
  transition-property: all;
  transition-timing-function: cubic-bezier(0.4, 0, 0.2, 1);
  transition-duration: 300ms;
}

/* Enhanced focus states */
input:focus {
  outline: none;
  box-shadow: 0 0 0 3px rgba(245, 158, 11, 0.1);
}

/* Professional button hover states */
button:hover {
  transform: translateY(-1px);
}

button:active {
  transform: translateY(0);
}
</style>
