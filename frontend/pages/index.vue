<template>
  <div class="pb-2">
    <PublicSection id="classified-services">
      <UContainer
        :ui="{
          padding: 'px-2',
        }"
        class="relative"
      >
        <!-- Premium decorative elements -->
        <div
          class="absolute top-0 left-0 w-64 h-64 bg-gradient-to-br from-emerald-500/10 to-transparent rounded-full blur-3xl -z-10"
        ></div>
        <div
          class="absolute bottom-0 right-0 w-80 h-80 bg-gradient-to-tl from-blue-500/10 to-transparent rounded-full blur-3xl -z-10"
        ></div>

        <PublicTitle />

        <!-- Enhanced search form with premium styling -->
        <form
          @submit.prevent="handleSearch"
          class="w-full max-w-xl mx-auto relative z-10 transition-all duration-500 hover:scale-[1.01]"
        >
          <!-- Decorative elements with reduced blur for better performance -->
          <div
            class="absolute -top-6 -left-10 w-24 h-24 bg-emerald-400/10 rounded-full blur-xl -z-10 opacity-70 animate-pulse"
          ></div>
          <div
            class="absolute -bottom-6 -right-10 w-28 h-28 bg-blue-400/10 rounded-full blur-xl -z-10 opacity-70 animate-pulse"
            style="animation-delay: 1s"
          ></div>

          <!-- Premium search container with glass effect -->
          <div
            class="bg-white/90 dark:bg-slate-800/90 backdrop-blur-sm rounded-2xl h-12 sm:h-16 shadow-lg border border-slate-200/50 dark:border-slate-700/30 overflow-hidden transition-all duration-300 hover:shadow-xl group"
          >
            <!-- Accent line animation -->
            <div
              class="absolute top-0 left-0 right-0 h-0.5 bg-gradient-to-r from-emerald-500 via-blue-500 to-purple-500 transform scale-x-0 group-hover:scale-x-100 transition-transform origin-left duration-500"
            ></div>

            <div class="flex items-center h-full">
              <!-- Search icon with animation -->
              <div class="pl-4 sm:pl-5 inline-flex items-center">
                <UIcon
                  name="i-heroicons-magnifying-glass"
                  class="w-5 h-5 sm:w-6 sm:h-6 text-slate-400 dark:text-slate-500 group-hover:text-emerald-500 dark:group-hover:text-emerald-400 transition-colors duration-300"
                />
              </div>

              <!-- Input with typing animation -->
              <div class="relative flex-1 h-full">
                <input
                  ref="searchInput"
                  type="search"
                  v-model="title"
                  class="w-full h-full py-3 sm:py-4 px-3 sm:px-4 bg-transparent border-0 focus:ring-0 focus:outline-none text-slate-800 dark:text-white placeholder-transparent text-base sm:text-lg"
                  :class="isLoading ? 'opacity-70' : 'opacity-100'"
                  @focus="stopTyping"
                  @blur="restartTypingIfEmpty"
                  style="-webkit-appearance: none; appearance: none"
                />

                <!-- Animated placeholder with cursor -->
                <div
                  v-if="!title && showPlaceholder"
                  class="absolute left-3 sm:left-4 top-1/2 -translate-y-1/2 pointer-events-none flex items-center"
                >
                  <span
                    class="text-slate-400 dark:text-slate-500 text-base sm:text-lg"
                  >
                    <span>{{ displayedPlaceholder }}</span>
                    <span
                      class="inline-block w-0.5 h-5 sm:h-6 bg-emerald-500 dark:bg-emerald-400 ml-0.5 animate-cursor-blink"
                      :class="{ 'opacity-0': !cursorVisible }"
                    ></span>
                  </span>
                </div>
              </div>

              <!-- Enhanced search button -->
              <button
                type="submit"
                text="Search"
                class="relative overflow-hidden bg-gradient-to-r from-emerald-500 to-blue-500 hover:from-emerald-600 hover:to-blue-600 text-white py-2 sm:py-3 px-4 sm:px-6 rounded-xl font-medium transition-all duration-300 flex items-center gap-2 h-10 sm:h-12 mr-2 shadow-md hover:shadow-lg"
                :disabled="isLoading"
              >
                <!-- Button background animation -->
                <span
                  class="absolute inset-0 w-full h-full bg-white/20 transform scale-x-0 group-hover:scale-x-100 transition-transform origin-left duration-500"
                ></span>

                <!-- Button content -->
                <span v-if="!isLoading" class="relative hidden sm:block">{{
                  $t("search")
                }}</span>
                <UIcon
                  v-if="!isLoading"
                  name="i-heroicons-magnifying-glass"
                  class="w-4 h-4 sm:w-5 sm:h-5 relative"
                />
                <UIcon
                  v-else
                  name="i-heroicons-arrow-path"
                  class="w-4 h-4 sm:w-5 sm:h-5 animate-spin relative"
                />
              </button>
            </div>
          </div>
        </form>

        <!-- Search results with premium styling -->
        <div
          v-if="
            searchServices?.results?.length || classifiedPosts.results?.length
          "
          class="border bg-white/90 dark:bg-slate-800/90 backdrop-blur-sm w-full max-w-lg mx-auto rounded-xl p-4 space-y-4 my-6 relative z-50 shadow-lg transition-all duration-300"
        >
          <h3
            v-if="searchServices?.results?.length"
            class="text-lg font-semibold flex items-center gap-2"
          >
            <UIcon name="i-heroicons-tag" class="text-emerald-500" />
            Categories
          </h3>
          <ul
            class="flex flex-wrap gap-2"
            v-if="searchServices?.results?.length"
          >
            <li
              v-for="service in searchServices?.results"
              :key="service.id"
              class="transition-transform duration-300 hover:scale-105"
            >
              <NuxtLink
                class="p-2.5 border border-emerald-200 hover:border-emerald-400 flex gap-2 items-center rounded-lg bg-emerald-50/80 hover:bg-emerald-50 shadow-sm hover:shadow transition-all duration-300"
                :to="`/classified-categories/${service.id}?business_type=${service.business_type}`"
              >
                <NuxtImg
                  :src="service?.image"
                  :title="service.title"
                  class="size-5 object-contain"
                />
                <span class="truncate font-medium">{{ service.title }}</span>
              </NuxtLink>
            </li>
          </ul>
          <UDivider
            label=""
            v-if="
              searchServices?.results?.length && classifiedPosts.results?.length
            "
            class="my-3"
          />
          <h3
            v-if="classifiedPosts.results?.length"
            class="text-lg font-semibold flex items-center gap-2"
          >
            <UIcon name="i-heroicons-newspaper" class="text-blue-500" />
            Ad Posts
          </h3>
          <ul v-if="classifiedPosts.results?.length" class="space-y-1.5">
            <li
              v-for="service of classifiedPosts.results"
              :key="service.id"
              class="transition-all duration-300 hover:translate-x-1"
            >
              <NuxtLink
                :to="`/classified-categories/details/${service.id}?business_type=${service.business_type}`"
                class="capitalize p-2.5 hover:bg-blue-50/80 flex gap-2 items-center rounded-lg transition-colors duration-300"
              >
                <div
                  class="flex-shrink-0 size-8 bg-slate-100 rounded-full flex items-center justify-center overflow-hidden"
                >
                  <NuxtImg
                    v-if="service?.medias[0]?.image"
                    :src="service?.medias[0]?.image"
                    :title="service.title"
                    class="size-8 object-cover"
                  />
                  <NuxtImg
                    v-else
                    :src="service?.category_details?.image"
                    :title="service.title"
                    class="size-6 object-contain"
                  />
                </div>
                <span class="truncate font-medium">{{ service.title }}</span>
              </NuxtLink>
            </li>
          </ul>
        </div>

        <!-- Service categories with premium styling -->
        <PublicServiceCategory :services="services" />

        <!-- Premium load more button -->
        <div class="text-center mt-8" v-if="services.next">
          <button
            @click="loadMore(services.next)"
            class="group relative inline-flex items-center justify-center gap-2 px-7 py-3.5 font-medium text-white bg-gradient-to-r from-emerald-500 to-blue-500 rounded-full overflow-hidden shadow-lg hover:shadow-xl transition-all duration-300 transform hover:scale-105"
            :disabled="isLoadingMore"
          >
            <!-- Background hover effect -->
            <span
              class="absolute inset-0 w-full h-full bg-gradient-to-r from-emerald-600 to-blue-600 opacity-0 group-hover:opacity-100 transition-opacity duration-300"
            ></span>

            <!-- Button content -->
            <span class="relative z-10 text-md font-semibold">{{
              $t("see_more")
            }}</span>
            <UIcon
              v-if="!isLoadingMore"
              name="i-heroicons-arrow-down"
              class="relative z-10 size-4 group-hover:translate-y-0.5 transition-transform duration-300"
            />

            <!-- Loading spinner (shown when loading) -->
            <UIcon
              v-if="isLoadingMore"
              name="i-heroicons-arrow-path"
              class="relative z-10 size-4 animate-spin"
            />
          </button>
        </div>
      </UContainer>
    </PublicSection>

    <!-- Ads scroll section with premium styling -->
    <AdsScroll :ads="classifiedLatestPosts" :sectionTitle="t('recent_post')" />
    <CommonProductSlider />

    <!-- Premium divider -->
    <div class="my-8 sm:my-16 mx-auto max-w-[80%] relative">
      <UDivider />
      <div
        class="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 bg-white dark:bg-slate-900 px-4 py-1"
      >
        <div class="w-2 h-2 bg-emerald-500 rounded-full"></div>
      </div>
    </div>

    <!-- Micro gigs section with premium styling -->
    <PublicSection
      id="micro-gigs"
      class="bg-gradient-to-b from-white to-slate-50/50 dark:from-slate-900 dark:to-slate-900/90 py-8"
    >
      <UContainer>
        <h2
          class="text-2xl md:text-4xl mb-8 text-center font-bold bg-gradient-to-r from-emerald-600 to-blue-600 bg-clip-text text-transparent"
        >
          {{ $t("micro_gigs") }}
          <span class="text-slate-700 dark:text-slate-300"
            >({{ $t("quick_earn") }})</span
          >
        </h2>

        <AccountBalance v-if="user" :user="user" :isUser="true" class="mb-8" />

        <!-- Mobile recharge link with premium styling -->
        <NuxtLink
          to="/mobile-recharge"
          class="mb-8 bg-white dark:bg-slate-800 shadow-lg hover:shadow-xl border border-slate-200 dark:border-slate-700 block py-3 px-6 max-w-fit mx-auto rounded-xl transition-all duration-300 hover:scale-105 group"
        >
          <div class="flex items-center gap-3">
            <UIcon
              name="i-heroicons-device-phone-mobile"
              class="text-emerald-500 size-6"
            />
            <h2
              class="text-base text-gray-900 dark:text-gray-100 sm:text-xl font-medium"
            >
              {{ $t("mobile_recharge") }}
            </h2>
            <div class="flex justify-center gap-2">
              <NuxtImg
                v-for="operator in operators"
                :key="operator.id"
                :src="operator.icon"
                :title="operator.title"
                class="size-6 transition-transform duration-300 group-hover:scale-110"
                :style="`transition-delay: ${operator.id * 50}ms`"
              />
            </div>
          </div>
        </NuxtLink>

        <!-- Micro gigs card with premium styling -->
        <UCard
          :ui="{
            body: { padding: 'p-0' },
            header: { padding: 'p-0' },
            rounded: 'rounded-xl overflow-hidden',
            ring: 'max-sm:ring-0',
            shadow: 'shadow-xl',
          }"
          class="bg-white/90 dark:bg-slate-800/90 backdrop-blur-sm border border-slate-200/70 dark:border-slate-700/50"
        >
          <div class="flex flex-col md:flex-row w-full">
            <!-- Categories sidebar with premium styling -->
            <div
              class="w-full md:w-64 bg-slate-50/90 dark:bg-slate-800/90 border-r border-slate-200 dark:border-slate-700 max-sm:rounded-lg max-sm:overflow-hidden"
            >
              <div class="py-4 px-2">
                <div class="flex items-center gap-2 px-3 mb-3">
                  <UIcon
                    name="i-heroicons-squares-2x2"
                    class="text-emerald-500 size-5"
                  />
                  <h3 class="font-semibold text-lg">Categories</h3>
                </div>

                <div
                  class="px-2 py-2.5 mb-2 rounded-lg bg-gradient-to-r from-emerald-50 to-blue-50 dark:from-emerald-900/20 dark:to-blue-900/20 cursor-pointer transition-colors duration-300 hover:from-emerald-100 hover:to-blue-100 dark:hover:from-emerald-900/30 dark:hover:to-blue-900/30"
                  @click.prevent="selectedCategory = null"
                >
                  <p class="px-2 font-medium flex items-center gap-2">
                    <UIcon
                      name="i-heroicons-home"
                      class="size-4 text-emerald-500"
                    />
                    {{ $t("all_category") }}
                  </p>
                </div>

                <UDivider label="" class="my-3" />

                <div
                  class="max-h-[400px] overflow-y-auto pr-1 space-y-1 scrollbar-thin"
                >
                  <div
                    v-for="category in categoryArray"
                    :key="category?.id"
                    class="rounded-lg transition-colors duration-300 hover:bg-slate-100 dark:hover:bg-slate-700/50"
                    :class="
                      selectedCategory?.id === category.id
                        ? 'bg-slate-100 dark:bg-slate-700/50'
                        : ''
                    "
                  >
                    <button
                      class="w-full text-left px-4 py-2.5 flex items-center justify-between group"
                      @click.prevent="selectCategory(category)"
                    >
                      <span
                        class="text-base font-medium text-slate-800 dark:text-slate-200 capitalize truncate"
                      >
                        {{ category.category }}
                      </span>
                      <span
                        class="text-sm font-medium px-2 py-0.5 rounded-full bg-emerald-100 dark:bg-emerald-900/30 text-emerald-700 dark:text-emerald-400 group-hover:bg-emerald-200 dark:group-hover:bg-emerald-800/30 transition-colors duration-300"
                      >
                        {{ category.active }}
                      </span>
                    </button>
                  </div>
                </div>
              </div>
            </div>

            <!-- Gigs content with premium styling -->
            <div
              class="flex-1 max-sm:border max-sm:mt-4 max-sm:rounded-xl min-h-[500px] flex flex-col"
            >
              <div
                class="flex justify-between items-center p-4 border-b border-slate-200 dark:border-slate-700"
              >
                <div class="flex items-center gap-2">
                  <UIcon
                    name="i-heroicons-briefcase"
                    class="text-emerald-500 size-5"
                  />
                  <p class="font-semibold text-lg">
                    {{ $t("available_gigs") }}
                  </p>
                </div>

                <div class="flex items-center gap-2">
                  <!-- Post gig button with premium styling -->
                  <UButton
                    to="/post-a-gig"
                    class="relative overflow-hidden bg-white hover:bg-slate-50 text-emerald-600 font-medium rounded-lg shadow-lg hover:shadow-xl transition-all duration-300 transform hover:scale-105 border border-emerald-200 hover:border-emerald-300"
                    :ui="{
                      size: {
                        sm: 'text-sm',
                      },
                      padding: {
                        sm: 'px-3 py-2 md:px-4 md:py-2',
                      },
                      icon: {
                        size: {
                          sm: 'w-4 h-4 md:w-4 md:h-4',
                        },
                      },
                    }"
                  >
                    <!-- Ripple Effect Background -->
                    <span class="absolute inset-0 overflow-hidden">
                      <span
                        class="absolute inset-0 scale-0 rounded-full bg-emerald-100 group-hover:animate-ripple"
                      ></span>
                    </span>

                    <!-- Button Content with Icon -->
                    <div
                      class="relative z-10 flex items-center justify-center space-x-2"
                    >
                      <UIcon
                        name="i-heroicons-plus-circle"
                        class="text-emerald-600"
                      />
                      <span class="font-medium">{{ $t("post_gigs") }}</span>
                    </div>
                  </UButton>

                  <!-- Filter dropdown with premium styling -->
                  <USelectMenu
                    color="emerald"
                    size="md"
                    class="w-32 md:w-40"
                    :options="microGigsFilter"
                    v-model="microGigsStatus"
                    @change="getMicroGigsByAvailability($event)"
                    placeholder="Filter"
                    value-attribute="value"
                    option-attribute="title"
                    variant="outline"
                    :ui="{
                      option: {
                        color: 'text-emerald-600',
                      },
                      base: 'shadow-md hover:shadow-lg transition-shadow duration-300',
                    }"
                  />
                </div>
              </div>

              <!-- Gigs list with premium styling -->
              <div
                class="flex-1 p-4 space-y-3 overflow-y-auto max-h-[600px] scrollbar-thin"
              >
                <div
                  v-for="(gig, i) in microGigs"
                  :key="i"
                  class="bg-white dark:bg-slate-800 rounded-xl shadow-md hover:shadow-lg transition-all duration-300 border border-slate-200/70 dark:border-slate-700/50 overflow-hidden group hover:border-emerald-200 dark:hover:border-emerald-700/50"
                >
                  <div
                    class="flex flex-col sm:flex-row sm:items-center w-full p-4"
                    v-if="gig.user"
                  >
                    <div
                      class="flex flex-col sm:flex-row sm:justify-between w-full"
                    >
                      <div class="flex gap-4">
                        <!-- Gig image with premium styling -->
                        <div class="flex-shrink-0">
                          <div
                            class="size-14 rounded-lg bg-slate-100 dark:bg-slate-700 overflow-hidden shadow-md flex items-center justify-center"
                          >
                            <NuxtImg
                              v-if="!errorIndex.includes(i)"
                              :src="gig.category_details?.image"
                              class="w-10 h-10 object-contain"
                              @error="handleImageError(i)"
                            />
                            <img
                              v-else
                              src="/static/frontend/images/no-image.jpg"
                              alt="No Image"
                              class="w-10 h-10 object-contain"
                            />
                          </div>
                        </div>

                        <!-- Gig details with premium styling -->
                        <div class="flex-1">
                          <h3
                            class="text-base sm:text-lg leading-tight font-semibold mb-2 capitalize group-hover:text-emerald-600 dark:group-hover:text-emerald-400 transition-colors duration-300"
                          >
                            {{ gig.title }}
                          </h3>
                          <div class="flex gap-1 gap-x-4 md:gap-4 flex-wrap">
                            <div
                              class="flex gap-1.5 items-center px-2 py-1 rounded-full bg-slate-100 dark:bg-slate-700"
                            >
                              <UIcon
                                name="i-heroicons-bell-solid"
                                class="text-emerald-500 size-4"
                              />
                              <p class="text-sm font-medium">
                                <span class="">{{ gig.filled_quantity }}</span>
                                /
                                <span
                                  class="text-emerald-600 dark:text-emerald-400"
                                  >{{ gig.required_quantity }}</span
                                >
                              </p>
                            </div>
                            <div
                              class="flex gap-1.5 items-center px-2 py-1 rounded-full bg-slate-100 dark:bg-slate-700"
                            >
                              <UIcon
                                name="i-heroicons-calendar"
                                class="text-blue-500 size-4"
                              />
                              <p class="text-sm font-medium">
                                {{ formatDate(gig.created_at) }}
                              </p>
                            </div>
                            <div
                              class="flex gap-1.5 items-center px-2 py-1 rounded-full bg-slate-100 dark:bg-slate-700"
                            >
                              <UIcon
                                name="i-heroicons-user"
                                class="text-purple-500 size-4"
                              />
                              <p class="text-sm font-medium">
                                <span class="text-slate-600 dark:text-slate-300"
                                  >By:</span
                                >
                                <span
                                  class="text-emerald-600 dark:text-emerald-400"
                                  >{{ gig.user.name.slice(0, 6) }}***</span
                                >
                              </p>
                            </div>
                            <p
                              class="font-bold text-base text-emerald-700 dark:text-emerald-400 inline-flex items-center max-sm:ml-auto sm:hidden px-2 py-1 rounded-full bg-emerald-50 dark:bg-emerald-900/30"
                            >
                              <UIcon
                                name="i-mdi:currency-bdt"
                                class="text-base mr-1"
                              />{{ gig.price }}
                            </p>
                          </div>
                        </div>
                      </div>

                      <!-- Gig actions with premium styling -->
                      <div
                        class="hidden sm:flex gap-4 items-center justify-end md:justify-between max-sm:mt-3 flex-shrink-0"
                      >
                        <p
                          class="font-bold text-lg text-emerald-700 dark:text-emerald-400 sm:inline-flex items-center hidden px-3 py-1.5 rounded-full bg-emerald-50 dark:bg-emerald-900/30"
                        >
                          <UIcon
                            name="i-mdi:currency-bdt"
                            class="text-lg mr-1"
                          />{{ gig.price }}
                        </p>

                        <UButton
                          v-if="user?.user && user?.user?.id !== gig.user.id"
                          :disabled="user?.user?.id === gig.user.id"
                          size="md"
                          color="emerald"
                          variant="solid"
                          class="w-24 justify-center shadow-md hover:shadow-lg transition-all duration-300 transform hover:scale-105"
                          :to="`/order/${gig.id}/`"
                        >
                          <UIcon
                            name="i-heroicons-currency-dollar"
                            class="mr-1"
                          />
                          Earn
                        </UButton>
                        <UButton
                          v-if="user?.user?.id === gig.user.id"
                          :disabled="user?.user?.id === gig.user.id"
                          size="md"
                          color="slate"
                          variant="outline"
                          class="w-24 justify-center"
                        >
                          Ineligible
                        </UButton>
                        <UButton
                          v-if="!user?.user"
                          size="md"
                          color="emerald"
                          variant="solid"
                          :to="`/auth/login/`"
                          class="w-24 justify-center shadow-md hover:shadow-lg transition-all duration-300 transform hover:scale-105"
                        >
                          <UIcon
                            name="i-heroicons-currency-dollar"
                            class="mr-1"
                          />
                          Earn
                        </UButton>
                      </div>

                      <!-- Mobile actions -->
                      <div class="flex justify-end mt-3 sm:hidden">
                        <UButton
                          v-if="user?.user && user?.user?.id !== gig.user.id"
                          :disabled="user?.user?.id === gig.user.id"
                          size="md"
                          color="emerald"
                          variant="solid"
                          class="w-24 justify-center shadow-md hover:shadow-lg transition-all duration-300 transform hover:scale-105"
                          :to="`/order/${gig.id}/`"
                        >
                          <UIcon
                            name="i-heroicons-currency-dollar"
                            class="mr-1"
                          />
                          Earn
                        </UButton>
                        <UButton
                          v-if="user?.user?.id === gig.user.id"
                          :disabled="user?.user?.id === gig.user.id"
                          size="md"
                          color="slate"
                          variant="outline"
                          class="w-24 justify-center"
                        >
                          Ineligible
                        </UButton>
                        <UButton
                          v-if="!user?.user"
                          size="md"
                          color="emerald"
                          variant="solid"
                          :to="`/auth/login/`"
                          class="w-24 justify-center shadow-md hover:shadow-lg transition-all duration-300 transform hover:scale-105"
                        >
                          <UIcon
                            name="i-heroicons-currency-dollar"
                            class="mr-1"
                          />
                          Earn
                        </UButton>
                      </div>
                    </div>
                  </div>
                </div>

                <!-- Empty state -->
                <div
                  v-if="microGigs.length === 0"
                  class="flex flex-col items-center justify-center py-12"
                >
                  <UIcon
                    name="i-heroicons-briefcase"
                    class="size-16 text-slate-300 dark:text-slate-600 mb-4"
                  />
                  <p class="text-lg text-slate-500 dark:text-slate-400">
                    No gigs available in this category
                  </p>
                </div>
              </div>
            </div>
          </div>
        </UCard>
      </UContainer>
    </PublicSection>

    <!-- Modal with premium styling -->
    <UModal
      v-model="isOpen"
      prevent-close
      :ui="{
        width: 'w-full sm:max-w-4xl',
        container:
          'bg-white dark:bg-slate-800 rounded-xl shadow-2xl border border-slate-200 dark:border-slate-700',
        overlay: 'backdrop-blur-sm',
      }"
    >
      <GigsViewer @close="isOpen = false" :gid="previewGid" />
    </UModal>
  </div>
</template>

<script setup>
const { t } = useI18n();
const { formatDate } = useUtils();
const isOpen = ref(false);
const { get, baseURL } = useApi();
const { user } = useAuth();
const services = ref([]);
const searchServices = ref([]);
const microGigs = ref([]);
const categoryArray = ref([]);
const selectedCategory = ref(null);
const title = ref(null);
const isLoading = ref(false);
const previewGid = ref(null);
const { data } = await get("/micro-gigs/");
microGigs.value = data;
const res = await get("/classified-categories/");
services.value = res.data;
const classifiedLatestPosts = ref([]);
const res2 = await get("/classified-posts/");
classifiedLatestPosts.value = res2.data;

const classifiedPosts = ref([]);
const toast = useToast();

const microGigsFilter = [
  { title: "All", value: "" },
  { title: "Available", value: "approved" },
  { title: "Completed", value: "completed" },
];

const microGigsStatus = ref(microGigsFilter[1]);

const errorIndex = ref([]);
function handleImageError(index) {
  console.log(`Broken image detected at index: ${index}`);
  if (!errorIndex.value.includes(index)) {
    errorIndex.value.push(index); // Add index to errorIndex
  }
}

async function getMicroGigsCategories() {
  const categoryCounts = microGigs.value.reduce((acc, gig) => {
    const category = gig.category_details.title;
    const id = gig.category_details.id;
    const isActiveAndApproved =
      gig.active_gig && gig.gig_status === "approved" && gig.user?.id;

    if (!acc[category]) {
      acc[category] = { total: 0, active: 0, id: id };
    }

    acc[category].total++;
    if (isActiveAndApproved) {
      acc[category].active++;
    }

    return acc;
  }, {});

  categoryArray.value = Object.entries(categoryCounts).map(
    ([category, { total, active, id }]) => ({
      category,
      total,
      active,
      id,
    })
  );
}

setTimeout(() => {
  getMicroGigsCategories();
}, 20);

async function getMicroGigsByAvailability(e) {
  if (e === "completed") {
    const { data, error } = await get(`/micro-gigs/?show_submitted=true`);
    microGigs.value = data;
  } else if (e === "approved") {
    const { data, error } = await get(`/micro-gigs/?show_submitted=false`);
    microGigs.value = data;
  } else {
    const { data, error } = await get(`/micro-gigs/`);
    microGigs.value = data;
  }
}

const selectCategory = async (category) => {
  selectedCategory.value = category || null;
  try {
    const { data, error } = await get(
      `/micro-gigs/?category=${category.id}&show_submitted=${false}`
    );
    microGigs.value = data;
  } catch (error) {
    console.log(error);
    toast.add({ title: "error" });
  }
};

const isLoadingMore = ref(false);

const loadMore = async (url) => {
  isLoadingMore.value = true;

  try {
    const getRecentNext = async (url) => {
      const res = await $fetch(`${url}`);
      services.value.next = res.next;
      services.value.results = [...services.value.results, ...res.results];
    };

    url = url.split("/api/");
    url = baseURL + "/" + url[1];
    await getRecentNext(url);
  } catch (error) {
    console.error("Error loading more items:", error);
    toast.add({
      title: "Failed to load more items",
      color: "red",
    });
  } finally {
    isLoadingMore.value = false;
  }
};

async function handleSearch() {
  if (!title.value?.trim()) {
    toast.add({
      title: "Please enter a search term",
      color: "orange",
    });
    return;
  }

  isLoading.value = true;

  try {
    const [categoriesRes, postsRes] = await Promise.all([
      get(
        `/classified-categories/?title=${encodeURIComponent(
          title.value.trim()
        )}`
      ),
      get(`/classified-posts/?title=${encodeURIComponent(title.value.trim())}`),
    ]);

    services.value = categoriesRes.data;
    classifiedPosts.value = postsRes.data;
  } catch (error) {
    console.error("Search error:", error);
    toast.add({
      title: error?.message || "An error occurred while searching",
      color: "red",
    });
  } finally {
    isLoading.value = false;
  }
}

// Replace the existing watch function with this:
watch(
  () => title.value,
  async (newValue) => {
    // Don't trigger search if value is empty
    if (!newValue?.trim()) {
      isLoading.value = true;
      try {
        const res = await get("/classified-categories/");
        services.value = res.data;
        searchServices.value = [];
        classifiedPosts.value = [];
      } catch (error) {
        console.error("Error fetching categories:", error);
        toast.add({
          title: "Failed to refresh categories",
          color: "red",
        });
      } finally {
        isLoading.value = false;
      }
      return;
    }

    // Perform search
    isLoading.value = true;
    try {
      const [categoriesRes, postsRes] = await Promise.all([
        get(
          `/classified-categories/?title=${encodeURIComponent(newValue.trim())}`
        ),
        get(`/classified-posts/?title=${encodeURIComponent(newValue.trim())}`),
      ]);

      services.value = categoriesRes.data;
      searchServices.value = categoriesRes.data;
      classifiedPosts.value = postsRes.data;
    } catch (error) {
      console.error("Search error:", error);
      toast.add({
        title: error?.message || "An error occurred while searching",
        color: "red",
      });
    } finally {
      isLoading.value = false;
    }
  },
  {
    // Add debounce to prevent too many API calls while typing
    debounce: 500,
    // Don't run on component mount
    immediate: false,
  }
);

const operators = ref([]);
const operatorsRes = await get("/mobile-recharge/operators/");

operators.value = operatorsRes.data;

// Add these variables for the typing animation
const searchInput = ref(null);
const showPlaceholder = ref(true);
const displayedPlaceholder = ref("");
const cursorVisible = ref(true);
const typingInterval = ref(null);
const cursorInterval = ref(null);
const currentIndex = ref(0);
const placeholder = t("search_placeholder");

// Typing animation functions
const typeNextChar = () => {
  if (currentIndex.value < placeholder.length) {
    displayedPlaceholder.value += placeholder[currentIndex.value];
    currentIndex.value++;

    // Variable typing speed for human-like effect
    const nextSpeed = Math.floor(Math.random() * 130) + 70;

    // Add slight pauses at certain points
    if (placeholder[currentIndex.value - 1] === " ") {
      typingInterval.value = setTimeout(typeNextChar, 300); // Longer pause after space
    } else {
      typingInterval.value = setTimeout(typeNextChar, nextSpeed);
    }
  } else {
    // When typing completes, wait and then start over
    setTimeout(resetTyping, 2000);
  }
};

// Reset typing animation
const resetTyping = () => {
  displayedPlaceholder.value = "";
  currentIndex.value = 0;
  typingInterval.value = setTimeout(typeNextChar, 500);
};

// Stop typing animation when input receives focus
const stopTyping = () => {
  showPlaceholder.value = false;
  clearTimeout(typingInterval.value);
};

// Restart typing animation if field is empty when blurred
const restartTypingIfEmpty = () => {
  if (!title.value) {
    showPlaceholder.value = true;
    resetTyping();
  }
};

// Start cursor blinking
const startCursorBlink = () => {
  cursorInterval.value = setInterval(() => {
    cursorVisible.value = !cursorVisible.value;
  }, 530); // Blink interval
};

// Initialize animations on mount
onMounted(() => {
  // Start after a brief delay to ensure reactivity is set up
  setTimeout(() => {
    typeNextChar();
    startCursorBlink();
  }, 100);
});

// Clean up intervals when component is unmounted
onBeforeUnmount(() => {
  clearTimeout(typingInterval.value);
  clearInterval(cursorInterval.value);
});
</script>

<style scoped>
/* Premium animations and effects */
@keyframes cursor-blink {
  0%,
  100% {
    opacity: 1;
  }
  50% {
    opacity: 0;
  }
}

.animate-cursor-blink {
  animation: cursor-blink 1s infinite;
  will-change: opacity;
}

@keyframes pulse {
  0%,
  100% {
    opacity: 0.7;
    transform: scale(1);
  }
  50% {
    opacity: 0.5;
    transform: scale(1.05);
  }
}

.animate-pulse {
  animation: pulse 4s ease-in-out infinite;
}

@keyframes ripple {
  0% {
    transform: scale(0);
    opacity: 0.5;
  }
  100% {
    transform: scale(6);
    opacity: 0;
  }
}

.animate-ripple {
  animation: ripple 1s cubic-bezier(0.4, 0, 0.2, 1) forwards;
}

/* Scrollbar styling */
.scrollbar-thin {
  scrollbar-width: thin;
  scrollbar-color: rgba(156, 163, 175, 0.5) transparent;
}

.scrollbar-thin::-webkit-scrollbar {
  width: 6px;
  height: 6px;
}

.scrollbar-thin::-webkit-scrollbar-track {
  background: transparent;
}

.scrollbar-thin::-webkit-scrollbar-thumb {
  background-color: rgba(156, 163, 175, 0.5);
  border-radius: 20px;
}

.scrollbar-thin::-webkit-scrollbar-thumb:hover {
  background-color: rgba(156, 163, 175, 0.7);
}

/* Transitions */
.fade-enter-active,
.fade-leave-active {
  transition: all 0.3s ease;
}

.fade-enter-from,
.fade-leave-to {
  opacity: 0;
  transform: translateY(10px);
}

/* Glass effect */
.backdrop-blur-sm {
  backdrop-filter: blur(8px);
  -webkit-backdrop-filter: blur(8px);
}
</style>
