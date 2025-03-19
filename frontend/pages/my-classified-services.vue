<template>
  <PublicSection>
    <UContainer>
      <!-- Professional Header with Refined Animation -->
      <div class="relative mb-6 text-center overflow-hidden">
        <div
          class="absolute inset-0 bg-gradient-to-r from-primary-50/20 via-white/0 to-primary-50/20 dark:from-primary-900/10 dark:via-transparent dark:to-primary-900/10 filter blur-2xl animate-gradient"
        ></div>
        <h2
          class="text-2xl md:text-3xl font-bold py-4 relative z-10 animate-title"
        >
          <span class="inline-block">My Services & Products</span>
        </h2>
      </div>

      <!-- Refined Tab System -->
      <div
        class="custom-tabs relative mb-5 rounded-lg overflow-hidden shadow-sm bg-white dark:bg-slate-800"
      >
        <!-- Active Tab Indicator -->
        <div
          class="absolute bottom-0 h-0.5 bg-gradient-to-r from-primary-500 to-primary-400 transition-all duration-300 ease-out-cubic"
          :style="{
            left: activeTab === 'classified' ? '4%' : '54%',
            width: '42%',
            transform: 'translateY(0)',
          }"
        ></div>

        <div class="grid grid-cols-2 relative">
          <button
            @click="activeTab = 'classified'"
            class="tab-button relative py-3 px-4 font-medium transition-all duration-300 overflow-hidden"
            :class="
              activeTab === 'classified'
                ? 'text-primary-600 dark:text-primary-400'
                : 'text-slate-600 dark:text-slate-400'
            "
          >
            <span class="relative z-10 flex items-center justify-center gap-2">
              <UIcon
                name="i-heroicons-megaphone"
                class="w-5 h-5 transition-transform"
                :class="
                  activeTab === 'classified' ? 'text-primary' : 'text-slate-400'
                "
              />
              <span>Classified Services</span>
            </span>

            <!-- Tab hover effect -->
            <div
              class="absolute inset-0 bg-primary-50 dark:bg-primary-900/10 scale-y-0 origin-bottom transition-transform duration-300"
              :class="{ 'scale-y-100': activeTab === 'classified' }"
            ></div>
          </button>

          <button
            @click="activeTab = 'store'"
            class="tab-button relative py-3 px-4 font-medium transition-all duration-300 overflow-hidden"
            :class="
              activeTab === 'store'
                ? 'text-primary-600 dark:text-primary-400'
                : 'text-slate-600 dark:text-slate-400'
            "
          >
            <span class="relative z-10 flex items-center justify-center gap-2">
              <UIcon
                name="i-heroicons-shopping-bag"
                class="w-5 h-5 transition-transform"
                :class="
                  activeTab === 'store' ? 'text-primary' : 'text-slate-400'
                "
              />
              <span>Store Products</span>
            </span>

            <!-- Tab hover effect -->
            <div
              class="absolute inset-0 bg-primary-50 dark:bg-primary-900/10 scale-y-0 origin-bottom transition-transform duration-300"
              :class="{ 'scale-y-100': activeTab === 'store' }"
            ></div>
          </button>
        </div>
      </div>

      <!-- Tab Content with Professional Transitions -->
      <div class="relative">
        <!-- Classified Services Tab -->
        <div
          v-show="activeTab === 'classified'"
          class="tab-content"
          :class="{ 'tab-enter': activeTab === 'classified' }"
        >
          <div class="flex justify-between items-center mb-4">
            <UButton
              size="md"
              color="primary"
              to="/classified-categories/post/"
              class="btn-primary-effect"
            >
              <span class="flex items-center gap-1.5">
                <UIcon name="i-heroicons-plus" class="w-4 h-4" />
                <span>Post New Ad</span>
              </span>
            </UButton>

            <div class="flex items-center gap-3">
              <span class="text-sm text-slate-500 dark:text-slate-400"
                >{{ services.length }} ads</span
              >
              <UBadge color="primary">
                {{
                  services.filter(
                    (s) => s.active_service && s.service_status === "approved"
                  ).length
                }}
                active
              </UBadge>
            </div>
          </div>

          <!-- Services List with Staggered Animation -->
          <div v-if="services.length" class="space-y-2.5">
            <TransitionGroup name="service-list">
              <UCard
                v-for="service in services"
                :key="`classified-${service.id}`"
                class="service-card bg-white dark:bg-slate-800 border-0 hover:shadow-md transition-all duration-200 overflow-hidden"
                :ui="{
                  body: { padding: 'p-0' },
                  base: 'ring-1 ring-slate-200 dark:ring-slate-700',
                  rounded: 'rounded-lg',
                }"
              >
                <NuxtLink
                  :to="`/classified-categories/details/${service.id}`"
                  class="block"
                >
                  <div
                    class="flex flex-col sm:flex-row sm:items-center px-3 py-3"
                  >
                    <div
                      class="flex flex-row gap-3 items-start text-sm sm:text-base"
                    >
                      <!-- Service Image -->
                      <div
                        class="service-image-container relative overflow-hidden rounded-md"
                      >
                        <div
                          class="w-12 h-12 sm:w-14 sm:h-14 relative flex-shrink-0 bg-slate-100 dark:bg-slate-700/50 rounded-md overflow-hidden"
                        >
                          <NuxtImg
                            v-if="service.medias[0]?.image"
                            :src="service.medias[0].image"
                            class="w-full h-full object-cover transition-transform duration-300 hover:scale-105"
                          />
                          <img
                            v-else
                            :src="service.category_details.image"
                            class="w-full h-full object-cover transition-transform duration-300 hover:scale-105"
                          />
                        </div>
                      </div>

                      <!-- Service Info -->
                      <div class="flex-1 min-w-0">
                        <!-- Title with Status -->
                        <div class="flex items-baseline flex-wrap gap-1.5 mb-1">
                          <div class="flex items-center">
                            <span
                              class="inline-block w-1.5 h-1.5 rounded-full mr-1 flex-shrink-0"
                              :class="{
                                'bg-green-500 animate-pulse-dot':
                                  service.service_status === 'approved' &&
                                  service.active_service,
                                'bg-yellow-500':
                                  service.service_status.toLowerCase() ===
                                    'pending' || !service.active_service,
                                'bg-red-500':
                                  service.service_status.toLowerCase() ===
                                  'rejected',
                                'bg-blue-500':
                                  service.service_status === 'completed',
                              }"
                            ></span>
                            <span
                              class="text-xs px-1.5 py-0.5 rounded-sm font-medium"
                              :class="{
                                'bg-green-100 text-green-700 dark:bg-green-900/30 dark:text-green-400':
                                  service.service_status === 'approved' &&
                                  service.active_service,
                                'bg-yellow-100 text-yellow-700 dark:bg-yellow-900/30 dark:text-yellow-400':
                                  service.service_status.toLowerCase() ===
                                    'pending' || !service.active_service,
                                'bg-red-100 text-red-700 dark:bg-red-900/30 dark:text-red-400':
                                  service.service_status.toLowerCase() ===
                                  'rejected',
                                'bg-blue-100 text-blue-700 dark:bg-blue-900/30 dark:text-blue-400':
                                  service.service_status === 'completed',
                              }"
                            >
                              {{
                                service.service_status === "approved" &&
                                service.active_service
                                  ? "Live"
                                  : service.service_status === "completed"
                                  ? "Completed"
                                  : service.service_status.toLowerCase() ===
                                    "pending"
                                  ? "Pending"
                                  : service.service_status.toLowerCase() ===
                                    "rejected"
                                  ? "Rejected"
                                  : "Paused"
                              }}
                            </span>
                          </div>
                          <h3
                            class="text-sm sm:text-base font-medium text-slate-800 dark:text-white truncate"
                          >
                            {{ service?.title }}
                          </h3>
                        </div>

                        <!-- Service Meta -->
                        <div
                          class="flex flex-wrap items-center text-xs sm:text-xs gap-x-3 gap-y-1 text-slate-600 dark:text-slate-400"
                        >
                          <span
                            class="flex items-center gap-1"
                            v-if="!service.negotiable"
                          >
                            <UIcon
                              name="i-mdi:currency-bdt"
                              class="text-slate-500"
                            />
                            <span class="font-medium">{{ service.price }}</span>
                          </span>
                          <span class="flex items-center gap-1" v-else>
                            <UIcon
                              name="i-heroicons-currency-dollar"
                              class="text-slate-500"
                            />
                            <span>Negotiable</span>
                          </span>

                          <span class="flex items-center gap-1">
                            <UIcon
                              name="i-tabler:category"
                              class="text-primary-500 w-3.5 h-3.5"
                            />
                            <span>{{ service?.category_details.title }}</span>
                          </span>

                          <span class="flex items-center gap-1">
                            <UIcon
                              name="i-heroicons-clock"
                              class="text-slate-500 w-3.5 h-3.5"
                            />
                            <span>{{ formatDate(service?.created_at) }}</span>
                          </span>

                          <span class="flex items-center gap-1">
                            <UIcon
                              name="i-heroicons-map-pin"
                              class="text-slate-500 w-3.5 h-3.5"
                            />
                            <span>{{ service?.location }}</span>
                          </span>
                        </div>
                      </div>

                      <!-- Actions - Float Right -->
                      <div
                        class="flex sm:flex-col gap-1 sm:gap-2 mt-2 sm:mt-0 ml-auto"
                        v-if="
                          service.service_status.toLowerCase() !== 'rejected' ||
                          service.service_status.toLowerCase() !== 'completed'
                        "
                      >
                        <UButtonGroup size="xs" class="service-actions">
                          <UButton
                            color="primary"
                            variant="soft"
                            :icon="
                              service.active_service
                                ? 'i-heroicons-pause'
                                : 'i-heroicons-play'
                            "
                            :loading="isLoading"
                            v-if="
                              service.active_service &&
                              service.service_status !== 'completed'
                            "
                            @click.prevent.stop="
                              handleAction(service.id, 'pause', false)
                            "
                          />
                          <UButton
                            color="green"
                            variant="soft"
                            icon="i-heroicons-play"
                            :loading="isLoading"
                            v-if="!service.active_service"
                            @click.prevent.stop="
                              handleAction(service.id, 'active', true)
                            "
                          />

                          <UButton
                            color="primary"
                            variant="soft"
                            icon="i-heroicons-pencil"
                            v-if="service.service_status !== 'completed'"
                            @click.prevent.stop="
                              navigateToEdit(service.id, $event)
                            "
                          />

                          <UButton
                            color="red"
                            variant="soft"
                            icon="i-heroicons-trash"
                            :loading="isLoading"
                            :disabled="service.service_status === 'completed'"
                            @click.prevent.stop="handlePop(service.id)"
                          />
                        </UButtonGroup>
                      </div>
                    </div>
                  </div>
                </NuxtLink>
              </UCard>
            </TransitionGroup>
          </div>

          <!-- Polished Empty State -->
          <div
            v-else
            class="empty-state flex flex-col items-center justify-center py-16 px-4 bg-slate-50/50 dark:bg-slate-800/20 rounded-lg text-center"
          >
            <div class="relative mb-4 w-20 h-20">
              <UIcon
                name="i-heroicons-document"
                class="w-full h-full text-slate-200 dark:text-slate-700"
              />
              <div
                class="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 transform animate-float"
              >
                <UIcon
                  name="i-heroicons-plus"
                  class="w-10 h-10 text-primary-500/60 dark:text-primary-400/60"
                />
              </div>
            </div>
            <h3
              class="text-xl font-medium text-slate-700 dark:text-slate-300 mb-2"
            >
              No Classified Ads
            </h3>
            <p class="text-slate-500 dark:text-slate-400 mb-6 max-w-md">
              Create your first classified ad to promote your services to
              potential customers
            </p>
            <UButton
              color="primary"
              to="/classified-categories/post/"
              class="btn-primary-effect"
            >
              <span class="flex items-center gap-1.5">
                <UIcon name="i-heroicons-plus-circle" class="w-4 h-4" />
                <span>Post Your First Ad</span>
              </span>
            </UButton>
          </div>
        </div>

        <!-- Store Products Tab -->
        <div
          v-show="activeTab === 'store'"
          class="tab-content"
          :class="{ 'tab-enter': activeTab === 'store' }"
        >
          <!-- Debug information - For troubleshooting -->
          <div
            v-if="debug"
            class="bg-yellow-50 border border-yellow-200 p-2 mb-3 rounded text-xs"
          >
            <p>
              Status:
              {{ storeProducts.length ? "Products loaded" : "No products" }}
            </p>
            <p>Filter: {{ productStatusFilter }}</p>
            <p>Total products: {{ storeProducts.length }}</p>
            <p>Filtered products: {{ filteredProducts.length }}</p>
            <p>Active tab: {{ activeTab }}</p>
          </div>

          <!-- Header Actions -->
          <div class="flex flex-wrap items-center mb-4 gap-6">
            <UButton
              size="md"
              color="primary"
              to="/user/orders"
              class="order-btn group relative overflow-hidden px-5 py-2.5 rounded-xl border border-primary-600 bg-gradient-to-br from-primary-500 to-primary-600 hover:from-primary-600 hover:to-primary-700 shadow-md hover:shadow-lg transition-all duration-300 transform hover:-translate-y-0.5"
            >
              <div
                class="absolute inset-0 w-full h-full bg-gradient-to-r from-transparent via-white/10 to-transparent -translate-x-full group-hover:animate-shimmer"
              ></div>

              <span class="flex items-center gap-2 relative z-10">
                <UIcon
                  name="i-heroicons-shopping-bag"
                  class="w-5 h-5 text-white/90 group-hover:scale-110 transition-transform"
                />
                <span class="text-white font-medium tracking-wide"
                  >My Orders</span
                >
              </span>
            </UButton>
            <UButton
              size="md"
              color="primary"
              to="/test"
              class="order-btn group relative overflow-hidden px-5 py-2.5 rounded-xl border border-primary-600 bg-gradient-to-br from-primary-500 to-primary-600 hover:from-primary-600 hover:to-primary-700 shadow-md hover:shadow-lg transition-all duration-300 transform hover:-translate-y-0.5"
            >
              <div
                class="absolute inset-0 w-full h-full bg-gradient-to-r from-transparent via-white/10 to-transparent -translate-x-full group-hover:animate-shimmer"
              ></div>

              <span class="flex items-center gap-2 relative z-10">
                <UIcon
                  name="i-heroicons-shopping-bag"
                  class="w-5 h-5 text-white/90 group-hover:scale-110 transition-transform"
                />
                <span class="text-white font-medium tracking-wide"
                  >Add New Products</span
                >
                <UIcon
                  name="i-heroicons-chevron-right"
                  class="w-4 h-4 text-white/70 group-hover:translate-x-0.5 transition-transform"
                />
              </span>
            </UButton>

            <div class="sort-dropdown group relative justify-end">
              <!-- Dropdown Trigger Button -->
              <button
                @click="isSortDropdownOpen = !isSortDropdownOpen"
                type="button"
                class="flex items-center gap-3 w-64 px-4 py-1.5 bg-white dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-xl shadow-sm hover:shadow transition-all duration-300 group-hover:border-primary-300 dark:group-hover:border-primary-700/70 overflow-hidden"
              >
                <!-- Shine effect animation -->
                <div
                  class="absolute inset-0 w-full h-full bg-gradient-to-r from-transparent via-white/20 dark:via-white/5 to-transparent -translate-x-full group-hover:animate-shine"
                ></div>

                <!-- Sort icon with gradient background -->
                <div
                  class="flex-shrink-0 w-10 h-4 rounded-lg bg-gradient-to-br from-primary-50 to-primary-100 dark:from-primary-900/30 dark:to-primary-800/20 flex items-center justify-center shadow-sm"
                >
                  <svg
                    xmlns="http://www.w3.org/2000/svg"
                    class="h-5 w-5 text-primary-500 dark:text-primary-400 transition-transform duration-300 group-hover:scale-110"
                    viewBox="0 0 20 20"
                    fill="currentColor"
                  >
                    <path
                      d="M5 12a1 1 0 102 0V6.414l1.293 1.293a1 1 0 001.414-1.414l-3-3a1 1 0 00-1.414 0l-3 3a1 1 0 001.414 1.414L5 6.414V12zM15 8a1 1 0 10-2 0v5.586l-1.293-1.293a1 1 0 00-1.414 1.414l3 3a1 1 0 001.414 0l3-3a1 1 0 00-1.414-1.414L15 13.586V8z"
                    />
                  </svg>
                </div>

                <div class="flex flex-col items-start overflow-hidden">
                  <span
                    class="text-xs text-slate-500 dark:text-slate-400 font-medium"
                    >Sort by</span
                  >
                  <span
                    class="text-sm text-slate-800 dark:text-slate-200 font-medium truncate"
                    >{{ productSortLabels[productSort] }}</span
                  >
                </div>

                <!-- Arrow indicator with animation -->
                <svg
                  xmlns="http://www.w3.org/2000/svg"
                  class="h-5 w-5 text-slate-400 dark:text-slate-500 ml-auto transform transition-transform duration-300"
                  :class="{ 'rotate-180': isSortDropdownOpen }"
                  fill="none"
                  viewBox="0 0 24 24"
                  stroke="currentColor"
                >
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="2"
                    d="M19 9l-7 7-7-7"
                  />
                </svg>
              </button>

              <!-- Dropdown Menu -->
              <div
                v-show="isSortDropdownOpen"
                class="absolute left-0 right-0 mt-2 bg-white dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-xl shadow-lg overflow-hidden z-50 transform origin-top transition-all duration-200"
                :class="{
                  'opacity-100 scale-100': isSortDropdownOpen,
                  'opacity-0 scale-95 pointer-events-none': !isSortDropdownOpen,
                }"
                @click="handleClickOutside($event)"
              >
                <div class="max-h-80 overflow-y-auto py-2">
                  <button
                    v-for="option in sortOptions"
                    :key="option.value"
                    @click="selectOption(option.value)"
                    class="w-full px-4 py-3 flex items-center gap-3 hover:bg-slate-50 dark:hover:bg-slate-700/50 transition-colors duration-150"
                    :class="{
                      'bg-primary-50 dark:bg-primary-900/30':
                        productSort === option.value,
                    }"
                  >
                    <div
                      class="w-8 h-8 rounded-lg flex items-center justify-center"
                      :class="
                        productSort === option.value
                          ? 'bg-gradient-to-br from-primary-50 to-primary-100 dark:from-primary-900/30 dark:to-primary-800/20'
                          : 'bg-slate-100 dark:bg-slate-700/30'
                      "
                    >
                      <component
                        :is="getSortIcon(option.value)"
                        class="w-4 h-4"
                        :class="
                          productSort === option.value
                            ? 'text-primary-500 dark:text-primary-400'
                            : 'text-slate-500 dark:text-slate-400'
                        "
                      />
                    </div>

                    <div class="flex flex-col items-start">
                      <span
                        class="font-medium text-sm"
                        :class="
                          productSort === option.value
                            ? 'text-primary-600 dark:text-primary-400'
                            : 'text-slate-800 dark:text-slate-200'
                        "
                        >{{ option.label }}</span
                      >
                      <span
                        class="text-xs text-slate-500 dark:text-slate-400"
                        >{{ option.description }}</span
                      >
                    </div>

                    <!-- Checkmark for selected item -->
                    <svg
                      v-if="productSort === option.value"
                      xmlns="http://www.w3.org/2000/svg"
                      class="h-5 w-5 text-primary-500 dark:text-primary-400 ml-auto"
                      viewBox="0 0 20 20"
                      fill="currentColor"
                    >
                      <path
                        fill-rule="evenodd"
                        d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z"
                        clip-rule="evenodd"
                      />
                    </svg>
                  </button>
                </div>
              </div>
            </div>
          </div>

          <!-- Status Filters -->
          <div class="flex flex-wrap items-center gap-2 mb-6">
            <UButton
              v-for="filter in statusFilters"
              :key="filter.value"
              size="xs"
              :color="
                filter.value === productStatusFilter ? filter.color : 'gray'
              "
              :variant="filter.value === productStatusFilter ? 'soft' : 'ghost'"
              @click="productStatusFilter = filter.value"
              class="transition-all duration-200"
            >
              <span class="flex items-center gap-1.5">
                <UIcon :name="filter.icon" class="w-3.5 h-3.5" />
                <span>{{ filter.label }}</span>
                <UBadge
                  v-if="filter.value !== 'all'"
                  :color="filter.color"
                  variant="subtle"
                  size="xs"
                  class="ml-1"
                >
                  {{ getFilteredCount(filter.value) }}
                </UBadge>
              </span>
            </UButton>
          </div>

          <!-- Force the products to display by using data() approach -->
          <div v-if="storeProducts && storeProducts.length > 0">
            <!-- Products List -->
            <div v-if="filteredProducts.length > 0" class="space-y-3">
              <TransitionGroup name="product-list">
                <div
                  v-for="product in filteredProducts"
                  :key="`product-${product.id}`"
                  class="product-item relative group bg-white dark:bg-slate-800 rounded-xl overflow-hidden shadow-sm hover:shadow-md transition-all duration-300"
                >
                  <!-- Animated highlight effect on hover -->
                  <div
                    class="absolute inset-0 bg-primary-50/0 dark:bg-primary-900/0 group-hover:bg-primary-50/50 dark:group-hover:bg-primary-900/20 transition-colors duration-300"
                  ></div>

                  <!-- Subtle side accent -->
                  <div
                    class="absolute left-0 top-0 h-full w-1 bg-gradient-to-b transition-opacity duration-300"
                    :class="{
                      'from-green-400 to-emerald-500 opacity-60':
                        product.status === 'active',
                      'from-red-400 to-rose-500 opacity-60':
                        product.status === 'inactive',
                      'from-amber-400 to-orange-500 opacity-60':
                        product.status === 'out_of_stock',
                    }"
                  ></div>

                  <!-- Main Content -->
                  <div
                    class="flex flex-col sm:flex-row items-stretch relative z-10"
                  >
                    <!-- Product Image (Left) -->
                    <div
                      class="relative w-full sm:w-36 h-28 sm:h-auto sm:aspect-square bg-slate-100 dark:bg-slate-800/80 flex-shrink-0"
                    >
                      <img
                        :src="product.image"
                        :alt="product.name"
                        class="w-full h-full object-cover transition-transform duration-500 group-hover:scale-105"
                      />

                      <!-- Status Badge -->
                      <div class="absolute top-2 right-2">
                        <UBadge
                          :color="getStatusColor(product.status)"
                          variant="solid"
                          size="xs"
                          class="shadow-sm"
                        >
                          {{ getStatusLabel(product.status) }}
                        </UBadge>
                      </div>

                      <!-- Discount Badge -->
                      <div
                        v-if="product.discount"
                        class="absolute bottom-2 left-2"
                      >
                        <div
                          class="bg-red-500 text-white text-xs font-medium px-1.5 py-0.5 rounded-sm"
                        >
                          -{{ product.discount }}%
                        </div>
                      </div>

                      <!-- Bestseller Tag -->
                      <div
                        v-if="product.isBestSeller"
                        class="absolute -top-1 -left-1 transform rotate-0 group-hover:-rotate-3 transition-transform duration-300"
                      >
                        <div
                          class="bg-amber-500 text-white text-[10px] tracking-tight font-bold px-2 py-1 shadow-sm"
                        >
                          BEST SELLER
                        </div>
                        <div
                          class="w-0 h-0 border-t-4 border-t-amber-500 border-r-4 border-r-transparent"
                        ></div>
                      </div>
                    </div>

                    <!-- Product Info (Middle) -->
                    <div class="p-4 flex-1 flex flex-col justify-between">
                      <div>
                        <!-- Title & Rating -->
                        <div
                          class="flex flex-wrap justify-between items-start mb-1.5 gap-2"
                        >
                          <h3
                            class="font-medium text-slate-800 dark:text-white text-base"
                          >
                            {{ product.name }}
                          </h3>

                          <div class="flex items-center gap-1">
                            <div class="flex">
                              <UIcon
                                v-for="i in 5"
                                :key="i"
                                :name="
                                  i <= Math.round(product.rating)
                                    ? 'i-heroicons-star-solid'
                                    : 'i-heroicons-star'
                                "
                                class="w-3.5 h-3.5"
                                :class="
                                  i <= Math.round(product.rating)
                                    ? 'text-amber-400'
                                    : 'text-slate-300 dark:text-slate-600'
                                "
                              />
                            </div>
                            <span
                              class="text-xs text-slate-500 dark:text-slate-400"
                              >({{ product.reviews }})</span
                            >
                          </div>
                        </div>

                        <!-- Category & Meta -->
                        <div
                          class="flex flex-wrap items-center gap-x-3 gap-y-1.5 mb-2 text-xs text-slate-500 dark:text-slate-400"
                        >
                          <div class="flex items-center gap-1">
                            <UIcon
                              name="i-heroicons-tag"
                              class="w-3.5 h-3.5 text-primary-500"
                            />
                            <span>{{ product.category }}</span>
                          </div>

                          <div class="flex items-center gap-1">
                            <UIcon
                              name="i-heroicons-cube"
                              class="w-3.5 h-3.5 text-slate-500"
                            />
                            <UBadge
                              :color="
                                product.stock > 5
                                  ? 'green'
                                  : product.stock > 0
                                  ? 'amber'
                                  : 'red'
                              "
                              variant="subtle"
                              size="xs"
                            >
                              {{
                                product.stock > 5
                                  ? "In Stock"
                                  : product.stock > 0
                                  ? `Only ${product.stock} left`
                                  : "Out of Stock"
                              }}
                            </UBadge>
                          </div>

                          <div class="flex items-center gap-1">
                            <UIcon
                              name="i-heroicons-calendar"
                              class="w-3.5 h-3.5 text-slate-500"
                            />
                            <span>Listed: {{ product.listedDate }}</span>
                          </div>
                        </div>

                        <!-- Description preview -->
                        <p
                          class="text-xs text-slate-600 dark:text-slate-400 line-clamp-2 mb-2"
                        >
                          {{ product.description }}
                        </p>
                      </div>

                      <!-- Price & Actions Footer -->
                      <div
                        class="flex flex-wrap items-center justify-between mt-2 gap-2"
                      >
                        <!-- Price -->
                        <div class="flex items-baseline gap-1">
                          <span
                            class="text-base font-semibold text-slate-800 dark:text-white"
                            >৳{{ product.price }}</span
                          >
                          <span
                            v-if="product.oldPrice"
                            class="text-xs text-slate-400 line-through"
                            >৳{{ product.oldPrice }}</span
                          >
                        </div>

                        <!-- Quick Actions -->
                        <div class="flex items-center gap-1.5">
                          <UTooltip text="View details">
                            <UButton
                              size="xs"
                              color="primary"
                              variant="soft"
                              icon="i-heroicons-eye"
                              class="h-8 w-8"
                              @click.stop.prevent="previewProduct(product)"
                            />
                          </UTooltip>

                          <UTooltip text="Edit product">
                            <UButton
                              size="xs"
                              color="gray"
                              variant="soft"
                              icon="i-heroicons-pencil-square"
                              class="h-8 w-8"
                              @click.stop.prevent="editProduct(product)"
                            />
                          </UTooltip>

                          <UTooltip text="Delete product">
                            <UButton
                              size="xs"
                              color="red"
                              variant="soft"
                              icon="i-heroicons-trash"
                              class="h-8 w-8"
                              @click.stop.prevent="deleteProduct(product)"
                            />
                          </UTooltip>

                          <UButton
                            size="xs"
                            :color="
                              product.status === 'active' ? 'red' : 'green'
                            "
                            :variant="
                              product.status === 'active' ? 'soft' : 'solid'
                            "
                            class="h-8 min-w-[88px]"
                            :loading="product.isLoading"
                            @click.stop.prevent="toggleProductStatus(product)"
                          >
                            {{
                              product.status === "active"
                                ? "Deactivate"
                                : "Activate"
                            }}
                          </UButton>
                        </div>
                      </div>
                    </div>

                    <!-- Status indicator pill -->
                    <div
                      class="hidden sm:block w-1.5 absolute right-0 top-0 bottom-0"
                    >
                      <div
                        class="h-full w-full transition-all duration-500"
                        :class="{
                          'bg-green-500/30 dark:bg-green-500/20':
                            product.status === 'active',
                          'bg-red-500/30 dark:bg-red-500/20':
                            product.status === 'inactive',
                          'bg-amber-500/30 dark:bg-amber-500/20':
                            product.status === 'out_of_stock',
                        }"
                      ></div>
                    </div>
                  </div>
                </div>
              </TransitionGroup>
            </div>

            <!-- No matching results state (keep as is) -->
            <div
              v-else
              class="empty-state flex flex-col items-center justify-center py-12 px-4 bg-slate-50/50 dark:bg-slate-800/20 rounded-lg text-center"
            >
              <UIcon
                name="i-heroicons-magnifying-glass"
                class="w-16 h-16 text-slate-300 dark:text-slate-600 mb-3"
              />
              <h3
                class="text-lg font-medium text-slate-700 dark:text-slate-300 mb-2"
              >
                No Products Found
              </h3>
              <p class="text-slate-500 dark:text-slate-400 mb-4">
                No products match your current filter selection
              </p>
              <UButton
                color="gray"
                variant="soft"
                @click="productStatusFilter = 'all'"
              >
                <span class="flex items-center gap-1.5">
                  <UIcon name="i-heroicons-x-mark" class="w-4 h-4" />
                  <span>Clear Filters</span>
                </span>
              </UButton>
            </div>
          </div>

          <!-- No products state -->
          <div
            v-else
            class="empty-state flex flex-col items-center justify-center py-16 px-4 bg-slate-50/50 dark:bg-slate-800/20 rounded-lg text-center"
          >
            <div class="relative mb-4 w-20 h-20">
              <UIcon
                name="i-heroicons-shopping-bag"
                class="w-full h-full text-slate-200 dark:text-slate-700"
              />
              <div
                class="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 transform animate-float"
              >
                <UIcon
                  name="i-heroicons-plus"
                  class="w-10 h-10 text-primary-500/60 dark:text-primary-400/60"
                />
              </div>
            </div>
            <h3
              class="text-xl font-medium text-slate-700 dark:text-slate-300 mb-2"
            >
              No Products Yet
            </h3>
            <p class="text-slate-500 dark:text-slate-400 mb-6 max-w-md">
              Start selling on your store by adding your first product
            </p>
            <UButton
              color="primary"
              to="/store/add-product"
              class="btn-primary-effect"
            >
              <span class="flex items-center gap-1.5">
                <UIcon name="i-heroicons-plus-circle" class="w-4 h-4" />
                <span>Add Your First Product</span>
              </span>
            </UButton>
          </div>

          <!-- Product Preview Modal -->
          <UModal
            v-model="isProductPreviewOpen"
            :ui="{ width: 'sm:max-w-3xl' }"
          >
            <UCard v-if="selectedProduct" class="p-0 border-0">
              <div class="grid grid-cols-1 md:grid-cols-2 gap-0">
                <!-- Product Image -->
                <div
                  class="relative aspect-square bg-slate-100 dark:bg-slate-800/80"
                >
                  <img
                    :src="selectedProduct.image"
                    :alt="selectedProduct.name"
                    class="w-full h-full object-cover"
                  />
                  <div
                    v-if="selectedProduct.discount"
                    class="absolute top-3 left-3 px-2 py-1 bg-red-500 text-white text-xs font-medium rounded-md"
                  >
                    -{{ selectedProduct.discount }}% OFF
                  </div>
                  <button
                    class="absolute top-3 right-3 w-8 h-8 bg-white/90 dark:bg-slate-800/90 rounded-full flex items-center justify-center text-slate-500 hover:text-slate-700 dark:hover:text-slate-300"
                    @click="isProductPreviewOpen = false"
                  >
                    <UIcon name="i-heroicons-x-mark" class="w-5 h-5" />
                  </button>
                </div>

                <!-- Product Details -->
                <div class="p-5 flex flex-col h-full">
                  <div class="flex-1">
                    <div class="flex items-center gap-2 mb-1">
                      <UBadge
                        :color="getStatusColor(selectedProduct.status)"
                        size="sm"
                      >
                        {{ getStatusLabel(selectedProduct.status) }}
                      </UBadge>
                      <span
                        class="text-sm text-slate-500 dark:text-slate-400"
                        >{{ selectedProduct.category }}</span
                      >
                    </div>

                    <h2
                      class="text-xl font-medium text-slate-800 dark:text-white mb-2"
                    >
                      {{ selectedProduct.name }}
                    </h2>

                    <!-- Rating -->
                    <div class="flex items-center gap-2 mb-4">
                      <div class="flex">
                        <UIcon
                          v-for="i in 5"
                          :key="i"
                          :name="
                            i <= Math.round(selectedProduct.rating)
                              ? 'i-heroicons-star-solid'
                              : 'i-heroicons-star'
                          "
                          class="w-4 h-4"
                          :class="
                            i <= Math.round(selectedProduct.rating)
                              ? 'text-amber-400'
                              : 'text-slate-300 dark:text-slate-600'
                          "
                        />
                      </div>
                      <span class="text-sm text-slate-500 dark:text-slate-400"
                        >({{ selectedProduct.reviews }} reviews)</span
                      >
                    </div>

                    <!-- Description -->
                    <p class="text-slate-600 dark:text-slate-300 text-sm mb-4">
                      {{ selectedProduct.description }}
                    </p>

                    <!-- Details List -->
                    <div class="space-y-2 mb-6">
                      <div class="flex items-center gap-2 text-sm">
                        <UIcon
                          name="i-heroicons-currency-bangladeshi"
                          class="w-4 h-4 text-slate-500"
                        />
                        <span
                          class="text-slate-700 dark:text-slate-300 font-medium"
                          >Price:</span
                        >
                        <div class="flex items-baseline gap-1.5">
                          <span
                            class="font-semibold text-slate-800 dark:text-white"
                            >৳{{ selectedProduct.price }}</span
                          >
                          <span
                            v-if="selectedProduct.oldPrice"
                            class="text-xs text-slate-400 line-through"
                            >৳{{ selectedProduct.oldPrice }}</span
                          >
                        </div>
                      </div>

                      <div class="flex items-center gap-2 text-sm">
                        <UIcon
                          name="i-heroicons-cube"
                          class="w-4 h-4 text-slate-500"
                        />
                        <span
                          class="text-slate-700 dark:text-slate-300 font-medium"
                          >Stock:</span
                        >
                        <UBadge
                          :color="
                            selectedProduct.stock > 5
                              ? 'green'
                              : selectedProduct.stock > 0
                              ? 'amber'
                              : 'red'
                          "
                          variant="subtle"
                        >
                          {{
                            selectedProduct.stock > 5
                              ? "In Stock"
                              : selectedProduct.stock > 0
                              ? `Only ${selectedProduct.stock} left`
                              : "Out of Stock"
                          }}
                        </UBadge>
                      </div>

                      <div class="flex items-center gap-2 text-sm">
                        <UIcon
                          name="i-heroicons-calendar"
                          class="w-4 h-4 text-slate-500"
                        />
                        <span
                          class="text-slate-700 dark:text-slate-300 font-medium"
                          >Listed:</span
                        >
                        <span class="text-slate-600 dark:text-slate-400">{{
                          selectedProduct.listedDate
                        }}</span>
                      </div>
                    </div>
                  </div>

                  <!-- Action Buttons -->
                  <div
                    class="flex gap-2 pt-3 border-t border-slate-100 dark:border-slate-700"
                  >
                    <UButton
                      color="primary"
                      @click="editProduct(selectedProduct)"
                      icon="i-heroicons-pencil-square"
                      block
                      class="flex-1"
                      >Edit Product</UButton
                    >

                    <UButton
                      :color="
                        selectedProduct.status === 'active' ? 'red' : 'green'
                      "
                      :variant="
                        selectedProduct.status === 'active' ? 'soft' : 'solid'
                      "
                      @click="toggleProductStatus(selectedProduct, true)"
                      :icon="
                        selectedProduct.status === 'active'
                          ? 'i-heroicons-pause'
                          : 'i-heroicons-play'
                      "
                      block
                      class="flex-1"
                      :loading="selectedProduct.isLoading"
                      >{{
                        selectedProduct.status === "active"
                          ? "Deactivate"
                          : "Activate"
                      }}</UButton
                    >
                  </div>
                </div>
              </div>
            </UCard>
          </UModal>
        </div>
      </div>

      <!-- Refined Modal with Enhanced Animation -->
      <UModal
        v-model="isOpen"
        :ui="{
          width: 'sm:max-w-sm',
          overlay: { background: 'bg-slate-900/30 backdrop-blur-sm' },
        }"
      >
        <UCard
          class="p-0 overflow-hidden border-0"
          :ui="{ divide: 'divide-y divide-slate-100 dark:divide-slate-800' }"
        >
          <div
            class="modal-header-animation flex items-center justify-center py-4 bg-gradient-to-r from-amber-50 to-orange-50 dark:from-amber-900/20 dark:to-orange-900/10"
          >
            <div class="relative w-16 h-16 mx-auto">
              <div
                class="absolute inset-0 rounded-full bg-white dark:bg-slate-800 shadow-sm flex items-center justify-center"
              >
                <UIcon
                  name="i-heroicons-exclamation-triangle"
                  class="w-8 h-8 text-amber-500"
                />
              </div>
              <div
                class="absolute -inset-2 rounded-full border-2 border-amber-300/20 dark:border-amber-600/10 animate-ripple"
              ></div>
            </div>
          </div>

          <div class="p-5 text-center">
            <h4 class="text-lg font-medium text-slate-800 dark:text-white mb-2">
              Stop Post Permanently
            </h4>
            <p class="text-slate-600 dark:text-slate-400 text-sm mb-5">
              This post will be marked as completed and will no longer be
              visible to users. This action cannot be undone.
            </p>
            <div class="flex justify-center gap-2">
              <UButton
                size="sm"
                color="gray"
                variant="light"
                label="Cancel"
                @click="isOpen = false"
              />
              <UButton
                size="sm"
                color="red"
                variant="solid"
                label="Confirm"
                :loading="isLoading"
                @click="handleAction(currentId, 'complete')"
                class="confirm-btn"
              />
            </div>
          </div>
        </UCard>
      </UModal>
    </UContainer>
  </PublicSection>
</template>

<script setup>
definePageMeta({
  layout: "dashboard",
});

// Common state
const isLoading = ref(false);
const { get, put } = useApi();
const { formatDate } = useUtils();
const isOpen = ref(false); // KEEP THIS DECLARATION
const currentId = ref();
const router = useRouter();
const debug = ref(false); // Debug flag - set to true to show debugging info

// Tab state
const activeTab = ref("classified");
const tabs = [
  {
    label: "Classified Services",
    slot: "classified",
    icon: "i-heroicons-megaphone",
  },
  {
    label: "Store Products",
    slot: "store",
    icon: "i-heroicons-shopping-bag",
  },
];

// Classified services state
const categoryTitle = ref("");
const services = ref([]);

// Store products state
const storeProducts = ref([]);
const productSort = ref("newest");
const productStatusFilter = ref("all");
const isProductPreviewOpen = ref(false);
const selectedProduct = ref(null);

// Mock data for testing when API fails
const mockProducts = [
  {
    id: 1,
    name: "Sample Product 1",
    price: 1200,
    oldPrice: 1500,
    discount: 20,
    stock: 12,
    status: "active",
    category: "Electronics",
    image: "https://placehold.co/300x300/e2e8f0/1e293b?text=Product+Image",
    rating: 4.5,
    reviews: 24,
    description: "This is a sample product description",
    listedDate: new Date().toISOString().split("T")[0],
    isBestSeller: true,
    sales: 42,
    isLoading: false,
  },
  {
    id: 2,
    name: "Sample Product 2",
    price: 800,
    oldPrice: null,
    discount: null,
    stock: 3,
    status: "active",
    category: "Clothing",
    image: "https://placehold.co/300x300/e2e8f0/1e293b?text=Product+Image",
    rating: 3.5,
    reviews: 12,
    description: "Another sample product description",
    listedDate: new Date().toISOString().split("T")[0],
    isBestSeller: false,
    sales: 18,
    isLoading: false,
  },
  {
    id: 1,
    name: "Sample Product 1",
    price: 1200,
    oldPrice: 1500,
    discount: 20,
    stock: 12,
    status: "active",
    category: "Electronics",
    image: "https://placehold.co/300x300/e2e8f0/1e293b?text=Product+Image",
    rating: 4.5,
    reviews: 24,
    description: "This is a sample product description",
    listedDate: new Date().toISOString().split("T")[0],
    isBestSeller: true,
    sales: 42,
    isLoading: false,
  },
  {
    id: 2,
    name: "Sample Product 2",
    price: 800,
    oldPrice: null,
    discount: null,
    stock: 3,
    status: "active",
    category: "Clothing",
    image: "https://placehold.co/300x300/e2e8f0/1e293b?text=Product+Image",
    rating: 3.5,
    reviews: 12,
    description: "Another sample product description",
    listedDate: new Date().toISOString().split("T")[0],
    isBestSeller: false,
    sales: 18,
    isLoading: false,
  },
  {
    id: 1,
    name: "Sample Product 1",
    price: 1200,
    oldPrice: 1500,
    discount: 20,
    stock: 12,
    status: "active",
    category: "Electronics",
    image: "https://placehold.co/300x300/e2e8f0/1e293b?text=Product+Image",
    rating: 4.5,
    reviews: 24,
    description: "This is a sample product description",
    listedDate: new Date().toISOString().split("T")[0],
    isBestSeller: true,
    sales: 42,
    isLoading: false,
  },
  {
    id: 2,
    name: "Sample Product 2",
    price: 800,
    oldPrice: null,
    discount: null,
    stock: 3,
    status: "active",
    category: "Clothing",
    image: "https://placehold.co/300x300/e2e8f0/1e293b?text=Product+Image",
    rating: 3.5,
    reviews: 12,
    description: "Another sample product description",
    listedDate: new Date().toISOString().split("T")[0],
    isBestSeller: false,
    sales: 18,
    isLoading: false,
  },
];

// Status filters
const statusFilters = [
  {
    label: "All",
    value: "all",
    color: "gray",
    icon: "i-heroicons-rectangle-stack",
  },
  {
    label: "Active",
    value: "active",
    color: "green",
    icon: "i-heroicons-check-circle",
  },
  {
    label: "Inactive",
    value: "inactive",
    color: "red",
    icon: "i-heroicons-x-circle",
  },
  {
    label: "Out of Stock",
    value: "out_of_stock",
    color: "amber",
    icon: "i-heroicons-exclamation-circle",
  },
];

// Product sort labels
const productSortLabels = {
  newest: "Newest First",
  oldest: "Oldest First",
  price_asc: "Price: Low to High",
  price_desc: "Price: High to Low",
  best_selling: "Best Selling",
};

// Navigate to edit while preventing the link click
function navigateToEdit(id, event) {
  event.preventDefault();
  event.stopPropagation();
  router.push(`/classified-categories/post/?id=${id}`);
}

// Fetch classified services
async function fetchServices() {
  try {
    const response = await get(`/user-classified-categories-post/`);
    services.value = response.data;
    categoryTitle.value = response.data[0]?.category_details.title;
  } catch (error) {
    console.error("Error fetching classified services:", error);
  }
}

// Fetch store products with mock data fallback
async function fetchStoreProducts() {
  try {
    const response = await get(`/user-store-products/`);
    console.log("API response:", response);

    if (response && Array.isArray(response.data) && response.data.length > 0) {
      storeProducts.value = response.data;
      console.log("Using API data, products:", storeProducts.value.length);
    } else {
      console.warn("API returned no products, using mock data");
      storeProducts.value = [...mockProducts]; // Use spread to ensure proper reactivity
      console.log("Using mock data, products:", storeProducts.value.length);
    }
  } catch (error) {
    console.error("Error fetching store products, using mock data:", error);
    storeProducts.value = [...mockProducts]; // Use spread to ensure proper reactivity
    console.log(
      "Using mock data after error, products:",
      storeProducts.value.length
    );
  }
}

// Classified service actions
function handlePop(id) {
  isOpen.value = true;
  currentId.value = id;
}

async function handleAction(id, action, val) {
  isLoading.value = true;
  try {
    const res = await (action === "complete"
      ? put("/update-user-classified-post/" + id + "/", {
          service_status: "completed",
        })
      : put("/update-user-classified-post/" + id + "/", {
          active_service: val,
        }));
    isOpen.value = false;
    if (res.data) {
      fetchServices();
    }
  } catch (error) {
    console.error(`Error ${action} service:`, error);
  } finally {
    isLoading.value = false;
  }
}

// Store product actions
function previewProduct(product) {
  selectedProduct.value = product;
  isProductPreviewOpen.value = true;
}

function editProduct(product) {
  router.push(`/store/edit-product/${product.id}`);
}

function deleteProduct(product) {
  // Implement delete product logic
}

function toggleProductStatus(product, fromPreview = false) {
  product.isLoading = true;
  setTimeout(() => {
    product.status = product.status === "active" ? "inactive" : "active";
    product.isLoading = false;
    if (fromPreview) {
      isProductPreviewOpen.value = false;
    }
  }, 1000);
}

// Get filtered product count
function getFilteredCount(status) {
  return storeProducts.value.filter((p) => p.status === status).length;
}

// Get filtered products
const filteredProducts = computed(() => {
  console.log("Computing filtered products");

  if (!storeProducts.value || storeProducts.value.length === 0) {
    console.log("No products to filter");
    return [];
  }

  let products = [...storeProducts.value];

  if (productStatusFilter.value !== "all") {
    products = products.filter((p) => p.status === productStatusFilter.value);
  }

  // Sort products based on selected sort option
  switch (productSort.value) {
    case "newest":
      products = products.sort(
        (a, b) => new Date(b.listedDate) - new Date(a.listedDate)
      );
      break;
    case "oldest":
      products = products.sort(
        (a, b) => new Date(a.listedDate) - new Date(b.listedDate)
      );
      break;
    case "price_asc":
      products = products.sort((a, b) => a.price - b.price);
      break;
    case "price_desc":
      products = products.sort((a, b) => b.price - a.price);
      break;
    case "best_selling":
      products = products.sort((a, b) => b.sales - a.sales);
      break;
  }

  console.log("Filtered products:", products.length);
  return products;
});

// Get status label
function getStatusLabel(status) {
  switch (status) {
    case "active":
      return "Active";
    case "inactive":
      return "Inactive";
    case "out_of_stock":
      return "Out of Stock";
    default:
      return "Unknown";
  }
}

// Get status color
function getStatusColor(status) {
  switch (status) {
    case "active":
      return "green";
    case "inactive":
      return "red";
    case "out_of_stock":
      return "amber";
    default:
      return "gray";
  }
}

// Watch for tab changes to ensure data is loaded
watch(activeTab, (newTab) => {
  console.log(`Tab changed to: ${newTab}`);
  if (newTab === "store") {
    console.log("Loading store products...");
    // Always fetch store products on tab change
    fetchStoreProducts();
  }
});

// Initial data loading
onMounted(() => {
  fetchServices();

  // Load store products if that's the initial tab
  if (activeTab.value === "store") {
    fetchStoreProducts();
  }

  // Force the products to load in a delayed manner if they don't load immediately
  setTimeout(() => {
    if (activeTab.value === "store" && storeProducts.value.length === 0) {
      console.log("Delayed loading of store products");
      storeProducts.value = [...mockProducts];
    }
  }, 1000);
});

// Add these to your existing script
const sortOptions = [
  {
    label: "Newest First",
    value: "newest",
    description: "Show most recently added products",
  },
  {
    label: "Oldest First",
    value: "oldest",
    description: "Show oldest added products first",
  },
  {
    label: "Price: Low to High",
    value: "price_asc",
    description: "Sort by lowest price first",
  },
  {
    label: "Price: High to Low",
    value: "price_desc",
    description: "Sort by highest price first",
  },
  {
    label: "Best Selling",
    value: "best_selling",
    description: "Show products with most sales first",
  },
];

function getSortIcon(sortValue) {
  // You can replace these with your own icon components or imports
  if (sortValue === "newest") {
    return h(
      "svg",
      {
        xmlns: "http://www.w3.org/2000/svg",
        class: "h-4 w-4",
        viewBox: "0 0 20 20",
        fill: "currentColor",
      },
      [
        h("path", {
          d: "M10 2a8 8 0 100 16 8 8 0 000-16zm0 2a6 6 0 110 12 6 6 0 010-12zm1 1a1 1 0 10-2 0v4H7a1 1 0 100 2h2v.5a1 1 0 102 0V11h2a1 1 0 100-2h-2V5z",
        }),
      ]
    );
  }

  if (sortValue === "oldest") {
    return h(
      "svg",
      {
        xmlns: "http://www.w3.org/2000/svg",
        class: "h-4 w-4",
        viewBox: "0 0 20 20",
        fill: "currentColor",
      },
      [
        h("path", {
          d: "M10 18a8 8 0 100-16 8 8 0 000 16zm0-2a6 6 0 110-12 6 6 0 010 12zm-1-5a1 1 0 102 0v-4h2a1 1 0 100-2h-2V4.5a1 1 0 10-2 0V5H7a1 1 0 000 2h2v4z",
        }),
      ]
    );
  }

  if (sortValue === "price_asc") {
    return h(
      "svg",
      {
        xmlns: "http://www.w3.org/2000/svg",
        class: "h-4 w-4",
        viewBox: "0 0 20 20",
        fill: "currentColor",
      },
      [
        h("path", {
          d: "M3 3a1 1 0 000 2h11a1 1 0 100-2H3zM3 7a1 1 0 000 2h7a1 1 0 100-2H3zM3 11a1 1 0 100 2h4a1 1 0 100-2H3z",
        }),
      ]
    );
  }

  if (sortValue === "price_desc") {
    return h(
      "svg",
      {
        xmlns: "http://www.w3.org/2000/svg",
        class: "h-4 w-4",
        viewBox: "0 0 20 20",
        fill: "currentColor",
      },
      [
        h("path", {
          d: "M3 3a1 1 0 000 2h4a1 1 0 100-2H3zM3 7a1 1 0 000 2h7a1 1 0 100-2H3zM3 11a1 1 0 100 2h11a1 1 0 100-2H3z",
        }),
      ]
    );
  }

  if (sortValue === "best_selling") {
    return h(
      "svg",
      {
        xmlns: "http://www.w3.org/2000/svg",
        class: "h-4 w-4",
        viewBox: "0 0 20 20",
        fill: "currentColor",
      },
      [
        h("path", {
          d: "M12.395 2.553a1 1 0 00-1.45-.385c-.345.23-.614.558-.822.88-.214.33-.403.713-.57 1.116-.334.804-.614 1.768-.84 2.734a31.365 31.365 0 00-.613 3.58 2.64 2.64 0 01-.945-1.067c-.328-.68-.398-1.534-.398-2.654A1 1 0 005.05 6.05 6.981 6.981 0 003 11a7 7 0 1011.95-4.95c-.592-.591-.98-.985-1.348-1.467-.363-.476-.724-1.063-1.207-2.03zM12.12 15.12A3 3 0 017 13s.879.5 2.5.5c0-1 .5-4 1.25-4.5.5 1 .786 1.293 1.371 1.879A2.99 2.99 0 0113 13a2.99 2.99 0 01-.879 2.121z",
        }),
      ]
    );
  }

  // Default icon
  return h(
    "svg",
    {
      xmlns: "http://www.w3.org/2000/svg",
      class: "h-4 w-4",
      viewBox: "0 0 20 20",
      fill: "currentColor",
    },
    [
      h("path", {
        d: "M5 4a1 1 0 00-2 0v7.268a2 2 0 000 3.464V16a1 1 0 102 0v-1.268a2 2 0 000-3.464V4zM11 4a1 1 0 10-2 0v1.268a2 2 0 000 3.464V16a1 1 0 102 0V8.732a2 2 0 000-3.464V4zM16 3a1 1 0 011 1v7.268a2 2 0 010 3.464V16a1 1 0 11-2 0v-1.268a2 2 0 010-3.464V4a1 1 0 011-1z",
      }),
    ]
  );
}

function selectOption(value) {
  productSort.value = value;
  isOpen.value = false;
}
</script>

<style scoped>
/* Tab button animations */
.tab-button:hover::before {
  opacity: 0.05;
}

.tab-button::before {
  content: "";
  position: absolute;
  inset: 0;
  background-color: currentColor;
  opacity: 0;
  transition: opacity 0.2s ease;
}

/* Tab content transitions */
.tab-content {
  opacity: 0;
  transform: translateY(6px);
  transition: all 0.4s cubic-bezier(0.33, 1, 0.68, 1);
  will-change: opacity, transform;
}

.tab-enter {
  opacity: 1;
  transform: translateY(0);
}

/* Service list transitions */
.service-list-move,
.service-list-enter-active,
.service-list-leave-active {
  transition: all 0.4s ease;
}

.service-list-enter-from,
.service-list-leave-to {
  opacity: 0;
  transform: translateY(20px);
}

.service-list-leave-active {
  position: absolute;
}

/* Title animations */
.animate-title span {
  position: relative;
}

.animate-title span::after {
  content: "";
  position: absolute;
  bottom: -2px;
  left: 0;
  width: 100%;
  height: 2px;
  background: linear-gradient(
    to right,
    var(--color-primary-500),
    var(--color-primary-400)
  );
  transform: scaleX(0);
  transform-origin: left;
  animation: slideRight 0.8s forwards 0.2s;
}

@keyframes slideRight {
  to {
    transform: scaleX(1);
  }
}

/* Button animations */
.btn-primary-effect {
  position: relative;
  overflow: hidden;
}

.btn-primary-effect::after {
  content: "";
  position: absolute;
  top: 0;
  left: -100%;
  width: 100%;
  height: 100%;
  background: linear-gradient(to right, rgba(255, 255, 255, 0.2), transparent);
  transform: skewX(-15deg);
  transition: all 0.6s ease;
}

.btn-primary-effect:hover::after {
  left: 100%;
}

/* Service actions hover */
.service-actions {
  transition: transform 0.25s cubic-bezier(0.33, 1, 0.68, 1);
}

.service-card:hover .service-actions {
  transform: translateY(-2px);
}

/* Animated gradient background */
@keyframes gradient {
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

.animate-gradient {
  background-size: 200% 200%;
  animation: gradient 18s ease infinite;
}

/* Floating animation */
@keyframes float {
  0% {
    transform: translate(-50%, -50%) translateY(0px);
  }
  50% {
    transform: translate(-50%, -50%) translateY(-6px);
  }
  100% {
    transform: translate(-50%, -50%) translateY(0px);
  }
}

.animate-float {
  animation: float 3s ease-in-out infinite;
}

/* Pulse dot animation */
@keyframes pulseDot {
  0%,
  100% {
    transform: scale(1);
    opacity: 1;
  }
  50% {
    transform: scale(1.3);
    opacity: 0.7;
  }
}

.animate-pulse-dot {
  animation: pulseDot 2s cubic-bezier(0.4, 0, 0.6, 1) infinite;
}

/* Scale pulse animation */
@keyframes pulseScale {
  0%,
  100% {
    transform: scale(1);
  }
  50% {
    transform: scale(1.05);
  }
}

.animate-pulse-scale {
  animation: pulseScale 3s ease-in-out infinite;
}

/* Modal ripple effect */
@keyframes ripple {
  0% {
    transform: scale(0.9);
    opacity: 0.8;
  }
  100% {
    transform: scale(1.2);
    opacity: 0;
  }
}

.animate-ripple {
  animation: ripple 2s ease-out infinite;
}

/* Modal header animation */
.modal-header-animation {
  background-size: 200% 200%;
  animation: gradient 8s ease infinite;
}

/* Confirm button hover */
.confirm-btn {
  transition: all 0.3s ease;
}

.confirm-btn:hover:not(:disabled) {
  transform: scale(1.03);
  box-shadow: 0 4px 12px rgba(239, 68, 68, 0.2);
}

/* Product list animations */
.product-list-move,
.product-list-enter-active,
.product-list-leave-active {
  transition: all 0.4s ease-out;
}

.product-list-enter-from,
.product-list-leave-to {
  opacity: 0;
  transform: translateX(-30px);
}

.product-list-leave-active {
  position: absolute;
}

/* Subtle hover effect for list items */
.product-item {
  border-left: 3px solid transparent;
  transition: all 0.3s;
  position: relative;
  z-index: 1;
}

.product-item::before {
  content: "";
  position: absolute;
  inset: 0;
  z-index: -1;
  background: linear-gradient(to right, var(--color-primary-50), transparent);
  opacity: 0;
  transition: opacity 0.3s ease;
}

.product-item:hover::before {
  opacity: 0.3;
}

/* Button hover effects */
.product-item .u-button {
  transition: transform 0.2s;
}

.product-item .u-button:hover {
  transform: translateY(-2px);
}
@keyframes shine {
  0% {
    transform: translateX(-100%);
  }
  100% {
    transform: translateX(100%);
  }
}

.group-hover\:animate-shine {
  animation: shine 1.5s ease;
}

.sort-dropdown {
  perspective: 1000px;
}
</style>
