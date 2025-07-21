<template>
  <div class="bg-slate-100 mt-2 dark:bg-slate-900">
    <!-- Categories Sidebar Component -->
    <CommonEshopCategoriesSidebar
      :isOpen="isSidebarOpen"
      :displayedCategories="displayedCategories"
      :selectedCategory="null"
      :hasMoreCategoriesToLoad="hasMoreCategoriesToLoad"
      :isLoadingMore="isLoadingMoreCategories"
      @close="toggleSidebar"
      @categorySelect="navigateToCategory"
      @loadMore="loadMoreCategories"
      @sellerRegistration="goToSellerRegistration"
      @contactSupport="contactSupport"
      @eshopManager="navigateToEshopManager"
    />

    <UContainer>
      <!-- 1. Banner Section -->
      <div
        v-if="!storeDetails"
        class="flex items-center justify-center min-h-[300px] p-6"
      >
        <div
          class="bg-white rounded-2xl shadow-sm p-8 max-w-md w-full text-center"
        >
          <h1 class="text-xl font-semibold text-gray-800 mb-2">
            Store Not Set Up Yet
          </h1>
          <p class="text-gray-500">
            This store has not completed its setup. Please complete your store
            setup and come again.
          </p>
        </div>
      </div>
      <div
        class="w-full h-48 md:h-64 bg-gradient-to-r from-purple-600 via-blue-600 to-cyan-600 rounded-t-xl md:rounded-t-2xl overflow-hidden relative"
        v-else
      >
        <img
          v-if="storeDetails?.store_banner"
          :src="storeDetails?.store_banner"
          alt="Vendor banner"
          class="absolute inset-0 w-full h-full object-cover opacity-50"
        />
        <img
          v-else
          src="/images/placeholder.jpg"
          alt="Vendor banner"
          class="absolute inset-0 w-full h-full object-cover opacity-50"
        />
      </div>

      <!-- 2. Info Section (Logo + Details) -->
      <div
        class="bg-white dark:bg-slate-800 border border-slate-200 dark:border-slate-700 shadow-sm rounded-b-xl md:rounded-b-2xl"
        v-if="storeDetails"
      >
        <div
          class="flex flex-col md:flex-row items-center md:items-start py-6 gap-6 px-4 sm:px-6 lg:px-8"
        >
          <!-- Vendor Logo -->
          <div class="flex-shrink-0 -mt-16 md:-mt-20">
            <div
              class="relative w-32 h-32 md:w-40 md:h-40 rounded-full bg-white dark:bg-slate-900 p-2 shadow-lg ring-4 ring-white dark:ring-slate-800"
            >
              <img
                v-if="storeDetails?.image"
                :src="storeDetails?.image"
                :alt="`${storeDetails?.store_name || 'Store'} Logo`"
                class="w-full h-full rounded-full object-cover"
              />
              <div
                v-else
                class="w-full h-full rounded-full bg-gradient-to-br from-indigo-500 to-blue-600 flex items-center justify-center text-white font-bold text-2xl md:text-3xl"
              >
                {{ getInitials(storeDetails?.store_name || "Store") }}
              </div>
              <div
                class="absolute bottom-1 right-1 md:bottom-2 md:right-2 w-8 h-8 bg-green-500 rounded-full border-2 border-white dark:border-slate-900 flex items-center justify-center"
              >
                <UIcon
                  name="i-heroicons-check-circle"
                  class="w-5 h-5 text-white"
                />
              </div>
            </div>
          </div>

          <!-- Store Details & Actions -->
          <div
            class="flex-1 flex flex-col md:flex-row items-center md:items-start gap-6 w-full"
          >
            <!-- Text Details -->
            <div class="flex-1 text-center md:text-left">
              <div
                class="flex items-center justify-center md:justify-start gap-3 mb-1"
              >
                <h1
                  class="text-xl md:text-2xl font-semibold text-slate-900 dark:text-white"
                >
                  {{ storeDetails?.store_name || "Store Name" }}
                </h1>
                <span
                  class="bg-emerald-100 text-emerald-800 dark:bg-emerald-900 dark:text-emerald-200 border border-emerald-300 dark:border-emerald-700 text-xs font-medium px-2.5 py-0.5 rounded-full"
                >
                  Verified
                </span>
              </div>
              <p
                class="text-slate-500 dark:text-slate-400 mb-3 max-w-xl mx-auto md:mx-0"
              >
                {{
                  storeDetails?.store_description ||
                  "Your premium destination for quality products and excellent service."
                }}
              </p>
              <div
                class="flex flex-wrap items-center justify-center md:justify-start gap-x-4 gap-y-1 text-sm text-slate-600 dark:text-slate-300"
              >
                <div class="flex items-center gap-1">
                  <UIcon
                    name="i-heroicons-star"
                    class="w-4 h-4 text-yellow-500"
                  />
                  <b>{{ storeDetails?.rating || 0 }}</b>
                  <span v-if="!isLoadingReviews"
                    >({{ reviewsCount }} reviews)</span
                  >
                  <span v-else class="text-slate-400">(Loading...)</span>
                </div>
                <div class="flex items-center gap-1">
                  <UIcon name="i-heroicons-cube" class="w-4 h-4" />
                  <b>{{ activeProductsCount }}</b>
                  <span>Products</span>
                </div>
                <div
                  v-if="storeDetails?.store_address"
                  class="flex items-center gap-1"
                >
                  <UIcon name="i-heroicons-map-pin" class="w-4 h-4" />
                  <span>{{ storeDetails.store_address }}</span>
                </div>
              </div>
            </div>
            <!-- Action Buttons -->
            <div class="flex items-center gap-3 flex-shrink-0">
              <UButton
                v-if="isOwner"
                icon="i-heroicons-adjustments-horizontal"
                color="indigo"
                @click="$router.push('/shop-manager')"
              >
                Manage Store
              </UButton>
              <UButton
                v-if="storeDetails?.phone || storeDetails?.email"
                :color="storeDetails?.phone ? 'blue' : 'gray'"
                variant="solid"
                :icon="
                  storeDetails?.phone
                    ? 'i-heroicons-phone'
                    : 'i-heroicons-envelope'
                "
                @click="handleContactClick"
              >
                {{ storeDetails?.phone ? "Call" : "Email" }}
              </UButton>
              <UButton
                variant="outline"
                icon="i-heroicons-share"
                square
                @click="handleShareClick"
              />
            </div>
          </div>
        </div>
      </div>
    </UContainer>
  </div>

  <!-- Rest of the page content -->
  <UContainer class="py-4 md:py-6 page-eshop" v-if="storeDetails">
    <div class="min-h-screen">
      <!-- Products Section with Improved Layout -->
      <div class="grid grid-cols-12 gap-x-0 gap-y-3 md:gap-3">
        <!-- Mobile Search Bar - Visible only on small screens -->
        <div class="col-span-12 md:hidden">
          <div class="relative">
            <input
              type="text"
              v-model="searchValue"
              class="w-full bg-white border border-gray-200 rounded-lg py-2.5 pl-10 pr-3 text-sm shadow-sm focus:outline-none focus:ring-2 focus:ring-indigo-100 focus:border-indigo-300"
              placeholder="Search products..."
            />
            <Search class="absolute left-3 top-3 w-4 h-4 text-gray-400" />
            <button
              v-if="searchValue"
              @click="searchValue = ''"
              class="absolute right-3 top-3 text-gray-400 hover:text-gray-600"
            >
              <X class="w-4 h-4" />
            </button>
          </div>
        </div>

        <!-- Mobile Categories Horizontal Scroll - Visible only on small screens -->
        <div class="col-span-12 md:hidden mt-2">
          <div class="flex overflow-x-auto gap-2 pb-1.5 hide-scrollbar">
            <button
              @click="selectedCategory = null"
              class="flex-shrink-0 px-3 py-1.5 rounded-lg transition-colors whitespace-nowrap text-sm"
              :class="
                selectedCategory === null
                  ? 'bg-indigo-100 text-indigo-800 font-medium'
                  : 'bg-gray-100 text-gray-800 hover:bg-gray-200'
              "
            >
              All Products ({{ activeProductsCount }})
            </button>
            <button
              v-for="category in uniqueCategories"
              :key="category.id"
              @click="selectedCategory = category.id"
              class="flex-shrink-0 px-3 py-1.5 rounded-lg transition-colors whitespace-nowrap text-sm flex items-center"
              :class="
                selectedCategory === category.id
                  ? 'bg-indigo-100 text-indigo-800 font-medium'
                  : 'bg-gray-100 text-gray-800 hover:bg-gray-200'
              "
            >
              <div class="flex-shrink-0 mr-1.5">
                <img
                  v-if="category.image"
                  :src="category.image"
                  :alt="category.name"
                  class="size-10 rounded object-contain border border-gray-200"
                  @error="
                    $event.target.style.display = 'none';
                    $event.target.nextElementSibling.style.display =
                      'inline-block';
                  "
                />
                <UIcon
                  name="i-heroicons-tag"
                  class="h-4 w-4 opacity-75"
                  :class="category.image ? 'hidden' : 'inline-block'"
                />
              </div>
              {{ category.name }} ({{ getProductCountByCategory(category.id) }})
            </button>
          </div>
        </div>

        <!-- Desktop Sidebar: Search and Filters - Hidden on mobile -->
        <div class="hidden md:block md:col-span-4 lg:col-span-3">
          <div class="space-y-4">
            <!-- Search Card -->
            <div class="bg-white rounded-xl shadow-sm overflow-hidden">
              <div class="px-5 py-4 border-b border-gray-100">
                <h3 class="font-medium text-gray-800">Search Products</h3>
              </div>
              <div class="p-5">
                <div class="relative">
                  <input
                    type="text"
                    v-model="searchValue"
                    class="w-full bg-gray-50 border border-gray-200 rounded-md py-2.5 pl-9 pr-3 text-sm focus:ring-2 focus:ring-indigo-100 focus:border-indigo-300 focus:outline-none transition-all"
                    placeholder="Find products..."
                  />
                  <Search class="absolute left-3 top-3 w-4 h-4 text-gray-400" />

                  <button
                    v-if="searchValue"
                    @click="searchValue = ''"
                    class="absolute right-3 top-3 text-gray-400 hover:text-gray-600"
                  >
                    <X class="w-3.5 h-3.5" />
                  </button>
                </div>
              </div>
            </div>

            <!-- Categories Card -->
            <div class="bg-white rounded-xl shadow-sm overflow-hidden">
              <div
                class="px-5 py-4 border-b border-gray-100 flex justify-between items-center"
              >
                <h3 class="font-medium text-gray-800 flex items-center">
                  <UIcon
                    name="i-heroicons-rectangle-stack"
                    class="h-4 w-4 mr-1.5 text-indigo-500"
                  />
                  Categories
                </h3>
                <button
                  v-if="selectedCategory"
                  @click="selectedCategory = null"
                  class="text-xs font-medium text-indigo-600 hover:text-indigo-800 flex items-center group"
                >
                  <span>Reset</span>
                  <UIcon
                    name="i-heroicons-arrow-path"
                    class="h-3 w-3 ml-1 group-hover:rotate-90 transition-transform duration-200"
                  />
                </button>
              </div>
              <div class="p-4">
                <div
                  class="space-y-1.5 max-h-60 overflow-y-auto pr-2 hide-scrollbar"
                >
                  <button
                    @click="selectedCategory = null"
                    class="flex items-center justify-between w-full py-2.5 px-3.5 rounded-lg text-sm transition-all duration-200"
                    :class="
                      selectedCategory === null
                        ? 'bg-gradient-to-r from-indigo-50 to-indigo-100 text-indigo-700 font-medium shadow-sm'
                        : 'text-gray-600 hover:bg-gray-50'
                    "
                  >
                    <span class="flex items-center">
                      <UIcon
                        name="i-heroicons-squares-2x2"
                        class="h-4 w-4 mr-2 opacity-75"
                      />
                      All Products
                    </span>
                    <span
                      class="px-2 py-0.5 rounded-md text-xs bg-white shadow-sm border border-gray-100"
                    >
                      {{ activeProductsCount }}
                    </span>
                  </button>

                  <button
                    v-for="category in uniqueCategories"
                    :key="category.id"
                    @click="selectedCategory = category.id"
                    class="flex items-center justify-between w-full py-2.5 px-3.5 rounded-lg text-sm transition-all duration-200"
                    :class="
                      selectedCategory === category.id
                        ? 'bg-gradient-to-r from-indigo-50 to-indigo-100 text-indigo-700 font-medium shadow-sm'
                        : 'text-gray-600 hover:bg-gray-50'
                    "
                  >
                    <span class="truncate mr-1 flex items-center">
                      <div class="flex-shrink-0 mr-2">
                        <img
                          v-if="category.image"
                          :src="category.image"
                          :alt="category.name"
                          class="h-4 w-4 rounded object-cover border border-gray-200"
                          @error="
                            $event.target.style.display = 'none';
                            $event.target.nextElementSibling.style.display =
                              'inline-block';
                          "
                        />
                        <UIcon
                          name="i-heroicons-tag"
                          class="h-4 w-4 opacity-75"
                          :class="category.image ? 'hidden' : 'inline-block'"
                        />
                      </div>
                      {{ category.name }}
                    </span>
                    <span
                      class="px-2 py-0.5 rounded-md text-xs"
                      :class="
                        selectedCategory === category.id
                          ? 'bg-white shadow-sm border border-gray-100'
                          : 'bg-gray-100'
                      "
                    >
                      {{ getProductCountByCategory(category.id) }}
                    </span>
                  </button>
                </div>

                <div
                  v-if="uniqueCategories.length === 0"
                  class="py-4 text-center"
                >
                  <div
                    class="inline-flex items-center justify-center bg-gray-100 p-2.5 rounded-full mb-2"
                  >
                    <UIcon
                      name="i-heroicons-tag"
                      class="h-5 w-5 text-gray-400"
                    />
                  </div>
                  <p class="text-sm text-gray-600">No categories available</p>
                </div>
              </div>
            </div>

            <!-- Contact Seller Card -->
            <div class="bg-white rounded-xl shadow-sm overflow-hidden">
              <div class="px-5 py-4 border-b border-gray-100 flex items-center">
                <UIcon
                  name="i-heroicons-building-office-2"
                  class="h-4 w-4 mr-1.5 text-indigo-500"
                />
                <h3 class="font-medium text-gray-800">Business Inquiries</h3>
              </div>

              <div class="px-5 py-4">
                <div
                  class="bg-gradient-to-br from-indigo-50 to-blue-50 p-3.5 rounded-lg mb-4"
                >
                  <p class="text-sm text-gray-800">
                    Need large quantities or custom orders? Contact the seller
                    directly for corporate deals and special pricing.
                  </p>
                </div>

                <div class="space-y-3">
                  <!-- Phone Contact -->
                  <a
                    v-if="storeDetails.phone"
                    :href="`tel:${storeDetails.phone}`"
                    class="flex items-center p-3.5 border border-gray-100 rounded-lg transition-all duration-200 group hover:bg-gray-50 hover:border-gray-200 hover:-translate-y-0.5"
                  >
                    <div
                      class="h-10 w-10 bg-indigo-100 rounded-full flex items-center justify-center mr-3.5 group-hover:bg-indigo-200 transition-colors"
                    >
                      <UIcon
                        name="i-heroicons-phone-arrow-up-right"
                        class="h-5 w-5 text-indigo-600"
                      />
                    </div>
                    <div class="flex-grow">
                      <p class="font-medium text-sm text-gray-800">
                        Call Business Support
                      </p>
                      <p class="text-xs text-gray-600 mt-0.5">
                        {{ storeDetails.phone }}
                      </p>
                    </div>
                    <UIcon
                      name="i-heroicons-chevron-right"
                      class="h-4 w-4 text-gray-400 group-hover:text-indigo-500 group-hover:translate-x-0.5 transition-all"
                    />
                  </a>

                  <!-- WhatsApp Contact -->
                  <a
                    v-if="storeDetails.phone"
                    :href="`https://wa.me/${cleanPhoneNumber(
                      storeDetails.phone
                    )}`"
                    target="_blank"
                    rel="noopener noreferrer"
                    class="flex items-center p-3.5 border border-gray-100 rounded-lg transition-all duration-200 group hover:bg-gray-50 hover:border-gray-200 hover:-translate-y-0.5"
                  >
                    <div
                      class="h-10 w-10 bg-green-100 rounded-full flex items-center justify-center mr-3.5 group-hover:bg-green-200 transition-colors"
                    >
                      <svg
                        xmlns="http://www.w3.org/2000/svg"
                        class="h-5 w-5 text-green-600"
                        viewBox="0 0 24 24"
                        fill="currentColor"
                      >
                        <path
                          fill-rule="evenodd"
                          clip-rule="evenodd"
                          d="M19.3929 4.63599C17.2799 2.51199 14.4219 1.33999 11.4069 1.33999C5.24294 1.33999 0.248932 6.33399 0.248932 12.5C0.248932 14.547 0.791943 16.5373 1.80994 18.291L0.166992 24L6.00594 22.38C7.69794 23.303 9.53094 23.79 11.4029 23.79H11.4069C17.5689 23.79 22.5629 18.796 22.5629 12.63C22.5629 9.60399 21.5059 6.75999 19.3929 4.63599ZM11.4069 21.85C9.74394 21.85 8.11694 21.383 6.70894 20.51L6.37894 20.315L2.92794 21.209L3.83194 17.836L3.61694 17.493C2.65894 16.028 2.15094 14.292 2.15094 12.5C2.15094 7.40199 6.30994 3.23999 11.4089 3.23999C13.9009 3.23999 16.2729 4.21299 18.0419 5.98999C19.8109 7.76699 20.6629 10.14 20.6609 12.63C20.6609 17.73 16.5039 21.85 11.4069 21.85ZM16.2789 14.98C16.0149 14.847 14.8229 14.262 14.5789 14.173C14.3349 14.085 14.1599 14.041 13.9829 14.304C13.8079 14.568 13.3429 15.107 13.1879 15.284C13.0329 15.46 12.8789 15.482 12.6149 15.349C11.2389 14.661 10.3169 14.115 9.39294 12.513C9.13994 12.083 9.71594 12.116 10.2539 11.039C10.3419 10.863 10.2979 10.708 10.2349 10.574C10.1729 10.44 9.61294 9.24799 9.39394 8.71999C9.17994 8.20399 8.96194 8.26799 8.79694 8.25899C8.64194 8.24999 8.46694 8.24999 8.29194 8.24999C8.11694 8.24999 7.82994 8.31199 7.58594 8.57599C7.34194 8.83999 6.70894 9.42599 6.70894 10.618C6.70894 11.809 7.60294 12.964 7.73494 13.139C7.86694 13.315 9.60694 16.0233 12.2949 17.063C14.2819 17.8109 14.9819 17.8359 15.8929 17.69C16.4399 17.6 17.3999 17.086 17.6189 16.47C17.8389 15.854 17.8389 15.326 17.7769 15.284C17.7149 15.242 17.5399 15.173 17.2759 15.041C17.0119 14.909 15.8199 14.324 15.5759 14.236C15.3319 14.147 15.1569 14.103 14.9819 14.368C14.8249 14.622 14.3819 15.112 14.2259 15.284C14.0709 15.455 13.9169 15.477 13.6539 15.349C13.3909 15.222 12.5739 14.95 11.6149 14.093C10.8659 13.429 10.3569 12.611 10.2019 12.347C10.0469 12.083 10.1859 11.941 10.3189 11.809C10.4379 11.69 10.5839 11.5 10.7389 11.345C10.8939 11.191 10.9379 11.08 11.0259 10.904C11.1139 10.728 11.0699 10.574 11.0069 10.44C10.9439 10.306 10.4509 9.11299 10.1879 8.57599L10.1879 8.57599Z"
                        />
                      </svg>
                    </div>
                    <div class="flex-grow">
                      <p class="font-medium text-sm text-gray-800">WhatsApp</p>
                      <p class="text-xs text-gray-600 mt-0.5">
                        Message for quick response
                      </p>
                    </div>
                    <UIcon
                      name="i-heroicons-chevron-right"
                      class="h-4 w-4 text-gray-400 group-hover:text-green-500 group-hover:translate-x-0.5 transition-all"
                    />
                  </a>

                  <!-- Email Contact -->
                  <a
                    v-if="storeDetails.email"
                    :href="`mailto:${
                      storeDetails.email
                    }?subject=Business%20Inquiry%20for%20${encodeURIComponent(
                      storeDetails.store_name || ''
                    )}`"
                    class="flex items-center p-3.5 border border-gray-100 rounded-lg transition-all duration-200 group hover:bg-gray-50 hover:border-gray-200 hover:-translate-y-0.5"
                  >
                    <div
                      class="h-10 w-10 bg-blue-100 rounded-full flex items-center justify-center mr-3.5 group-hover:bg-blue-200 transition-colors"
                    >
                      <UIcon
                        name="i-heroicons-envelope"
                        class="h-5 w-5 text-blue-600"
                      />
                    </div>
                    <div class="flex-grow">
                      <p class="font-medium text-sm text-gray-800">
                        Email Support
                      </p>
                      <p
                        class="text-xs text-gray-600 mt-0.5 truncate max-w-[140px]"
                      >
                        {{ storeDetails.email }}
                      </p>
                    </div>
                    <UIcon
                      name="i-heroicons-chevron-right"
                      class="h-4 w-4 text-gray-400 group-hover:text-blue-500 group-hover:translate-x-0.5 transition-all"
                    />
                  </a>

                  <!-- No Contact Info Available -->
                  <div
                    v-if="!storeDetails.phone && !storeDetails.email"
                    class="flex items-center justify-center p-5 bg-gray-50 rounded-lg"
                  >
                    <div class="text-center">
                      <div
                        class="bg-gray-100 rounded-full p-3 inline-flex mb-3"
                      >
                        <UIcon
                          name="i-heroicons-information-circle"
                          class="h-6 w-6 text-gray-400"
                        />
                      </div>
                      <p class="text-sm text-gray-600 mb-1">
                        No contact information available
                      </p>
                      <p class="text-xs text-gray-600">
                        The store owner hasn't provided contact details yet
                      </p>
                    </div>
                  </div>
                </div>
              </div>
            </div>

            <!-- Store Info Card -->
            <div
              v-if="
                storeDetails.store_description || storeDetails.store_address
              "
              class="bg-white rounded-xl shadow-sm overflow-hidden"
            >
              <div class="px-5 py-4 border-b border-gray-100 flex items-center">
                <UIcon
                  name="i-heroicons-information-circle"
                  class="h-4 w-4 mr-1.5 text-indigo-500"
                />
                <h3 class="font-medium text-gray-800">About This Store</h3>
              </div>
              <div class="px-5 py-4">
                <div v-if="storeDetails.store_description" class="mb-4">
                  <h4
                    class="text-xs font-medium uppercase tracking-wider text-gray-600 mb-2"
                  >
                    Description
                  </h4>
                  <p class="text-sm text-gray-800 leading-relaxed">
                    {{ storeDetails.store_description }}
                  </p>
                </div>

                <div v-if="storeDetails.store_address" class="flex items-start">
                  <UIcon
                    name="i-heroicons-map-pin"
                    class="h-4 w-4 mt-0.5 mr-2 text-gray-400 flex-shrink-0"
                  />
                  <div>
                    <h4
                      class="text-xs font-medium uppercase tracking-wider text-gray-600 mb-1"
                    >
                      Location
                    </h4>
                    <p class="text-sm text-gray-800">
                      {{ storeDetails.store_address }}
                    </p>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>

        <!-- Main Content: Product Grid -->
        <div class="col-span-12 md:col-span-8 lg:col-span-9">
          <!-- Products Header -->
          <div class="flex items-center justify-between mb-4 md:mb-6">
            <div>
              <h2 class="text-lg md:text-xl font-bold text-gray-800">
                {{ getCategoryName(selectedCategory) }}
                <span class="text-sm font-normal text-gray-600 ml-2"
                  >({{ filteredProducts.length
                  }}{{ searchValue ? " found" : "" }})</span
                >
              </h2>
              <p v-if="searchValue" class="text-sm text-gray-500 mt-1">
                Searching for "<span class="font-medium">{{ searchValue }}</span
                >"
              </p>
            </div>

            <!-- Clear Filters Button -->
            <UButton
              v-if="searchValue || selectedCategory"
              size="xs"
              color="gray"
              variant="soft"
              @click="clearFilters"
              icon="i-heroicons-x-mark"
            >
              Clear Filters
            </UButton>
          </div>

          <!-- Products Grid with Responsive Layout -->
          <div v-if="isLoading" class="flex justify-center py-16">
            <UIcon
              name="i-heroicons-arrow-path"
              class="animate-spin h-8 w-8 text-gray-300"
            />
          </div>

          <div
            v-else-if="filteredProducts.length > 0"
            class="grid grid-cols-2 sm:grid-cols-2 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-2"
          >
            <CommonProductCard
              v-for="product in filteredProducts"
              :key="product.id"
              :product="product"
              class="bg-white rounded-xl shadow-sm border border-gray-100 overflow-hidden transition-all duration-300 hover:-translate-y-0.5 hover:shadow-sm"
            />
          </div>

          <!-- Empty State -->
          <div
            v-else
            class="bg-white rounded-xl border border-gray-100 shadow-sm py-12 md:py-16 px-6 md:px-8 text-center"
          >
            <div class="flex justify-center">
              <div class="bg-gray-100 rounded-full p-4">
                <UIcon
                  name="i-heroicons-rectangle-stack"
                  class="h-6 w-6 md:h-8 md:w-8 text-gray-400"
                />
              </div>
            </div>
            <h3 class="mt-4 text-base md:text-lg font-medium text-gray-800">
              {{ searchValue ? "No Search Results" : "No Products Found" }}
            </h3>
            <p class="mt-2 text-sm md:text-base text-gray-600 max-w-md mx-auto">
              {{
                searchValue
                  ? `We couldn't find any products matching "${searchValue}". Try a different search term or browse categories.`
                  : "We couldn't find any products matching your current selection. Try changing your search or selecting a different category."
              }}
            </p>
            <UButton
              v-if="searchValue || selectedCategory"
              color="gray"
              variant="soft"
              class="mt-5 md:mt-6"
              @click="clearFilters"
            >
              Clear Filters
            </UButton>
          </div>
        </div>
      </div>
    </div>
    <!-- Close min-h-screen div -->
  </UContainer>
</template>

<script setup>
import { CommonEshopCategoriesSidebar } from "#components";
import { Search, X } from "lucide-vue-next";
import { onMounted, onUnmounted, ref } from "vue";

definePageMeta({
  layout: "eshop",
});

const { get, patch } = useApi();
const router = useRoute();
const navigate = useRouter();
const toast = useToast();
const products = ref([]);
const storeDetails = ref({});
const { user, token } = useAuth();
const isLoading = ref(false);
const isSeeMore = ref(false);

// Sidebar state
const isSidebarOpen = ref(false);
const displayedCategories = ref([]);
const hasMoreCategoriesToLoad = ref(false);
const isLoadingMoreCategories = ref(false);
const categories = ref([]);

// Data fetching
async function fetchCategories() {
  try {
    const res = await get("/product-categories/");
    categories.value = res.data;
    displayedCategories.value = res.data.slice(0, 10);
    hasMoreCategoriesToLoad.value = res.data.length > 10;
  } catch (error) {
    console.error("Error fetching categories:", error);
  }
}

// Sidebar functions
function toggleSidebar() {
  isSidebarOpen.value = !isSidebarOpen.value;
}

function navigateToCategory(categoryId) {
  // Find category to get its slug
  const category = categories.value.find((cat) => cat.id === categoryId);
  if (category && category.slug) {
    navigate.push(`/eshop?category=${category.slug}`);
  } else {
    navigate.push("/eshop");
  }
  toggleSidebar();
}

function loadMoreCategories() {
  if (isLoadingMoreCategories.value || !hasMoreCategoriesToLoad.value) return;

  isLoadingMoreCategories.value = true;
  const currentCount = displayedCategories.value.length;
  const nextBatch = categories.value.slice(currentCount, currentCount + 10);
  displayedCategories.value.push(...nextBatch);
  hasMoreCategoriesToLoad.value =
    displayedCategories.value.length < categories.value.length;
  isLoadingMoreCategories.value = false;
}

function goToSellerRegistration() {
  navigate.push("/shop-manager");
  toggleSidebar();
}

function contactSupport() {
  navigate.push("/contact-us");
  toggleSidebar();
}

function navigateToEshopManager() {
  navigate.push("/shop-manager");
}

// Listen for sidebar toggle from header
const handleHeaderSidebarToggle = (event) => {
  isSidebarOpen.value = event.detail.isOpen;
};

// Review functionality
const reviewsCount = ref(0);
const isLoadingReviews = ref(false);

// Check if current user is store owner
const isOwner = computed(() => {
  return (
    user.value?.user?.store_username === storeDetails.value?.store_username
  );
});

// Helper to get initials from name
const getInitials = (name) => {
  if (!name) return "";
  return name
    .split(" ")
    .map((word) => word[0])
    .join("")
    .toUpperCase()
    .slice(0, 2);
};

async function getMyProducts() {
  isLoading.value = true;
  try {
    const response = await get(`/store/${router.params.id}/products/`);
    products.value = response.data;
  } catch (error) {
    console.error("Error fetching products:", error);
    toast.add({
      title: "Error loading products",
      description: "Could not load products. Please try again later.",
      color: "red",
    });
    products.value = [];
  } finally {
    isLoading.value = false;
  }
}

async function getStoreDetails() {
  isLoading.value = true;
  try {
    const { data } = await get(`/store/${router.params.id}/`);
    storeDetails.value = data;
  } catch (error) {
    console.error("Error fetching store details:", error);
    toast.add({
      title: "Error loading store",
      description: "Could not load store details. Please try again later.",
      color: "red",
    });
  } finally {
    isLoading.value = false;
  }
}

// Get store reviews count for the specific store
async function getStoreReviewsCount() {
  try {
    isLoadingReviews.value = true;
    // Use the new public endpoint that accepts store_username
    const res = await get(`/reviews/store/${router.params.id}/reviews/count/`);
    if (res && res.data) {
      reviewsCount.value = res.data.count || 0;
      isLoadingReviews.value = false;
      return;
    }
  } catch (error) {
    console.error("Error fetching store reviews count:", error);
    reviewsCount.value = 0;
    isLoadingReviews.value = false;
  }
}

// Helper to clean phone number for WhatsApp
const cleanPhoneNumber = (phone) => {
  if (!phone) return "";
  // Remove all non-digit characters and ensure it starts with country code
  const cleaned = phone.replace(/\D/g, "");
  // If it doesn't start with a country code, assume Bangladesh (+880)
  if (cleaned.startsWith("0")) {
    return "880" + cleaned.substring(1);
  }
  if (cleaned.startsWith("880")) {
    return cleaned;
  }
  // Default to Bangladesh if no country code
  return "880" + cleaned;
};

// Handle contact button click
const handleContactClick = () => {
  if (storeDetails.value?.phone) {
    // Call phone number
    window.location.href = `tel:${storeDetails.value.phone}`;
  } else if (storeDetails.value?.email) {
    // Send email
    const subject = encodeURIComponent(
      `Business Inquiry for ${storeDetails.value.store_name || "Store"}`
    );
    window.location.href = `mailto:${storeDetails.value.email}?subject=${subject}`;
  }
};

// Handle share button click
const handleShareClick = async () => {
  const shareData = {
    title: storeDetails.value?.store_name || "Check out this store",
    text: `Visit ${
      storeDetails.value?.store_name || "this amazing store"
    } on our platform!`,
    url: window.location.href,
  };

  try {
    // Check if Web Share API is supported
    if (navigator.share && navigator.canShare(shareData)) {
      await navigator.share(shareData);
    } else {
      // Fallback to clipboard
      await navigator.clipboard.writeText(window.location.href);
      toast.add({
        title: "Link copied!",
        description: "Store link has been copied to clipboard",
        color: "green",
      });
    }
  } catch (error) {
    if (error.name !== "AbortError") {
      // Try clipboard as final fallback
      try {
        await navigator.clipboard.writeText(window.location.href);
        toast.add({
          title: "Link copied!",
          description: "Store link has been copied to clipboard",
          color: "green",
        });
      } catch (clipboardError) {
        toast.add({
          title: "Sharing failed",
          description: "Unable to share or copy link",
          color: "red",
        });
      }
    }
  }
};

// Clear all filters function
const clearFilters = () => {
  searchValue.value = "";
  selectedCategory.value = null;
};

// State for category filtering
const selectedCategory = ref(null);
const searchFocused = ref(false);
const searchValue = ref("");
const visibleSections = reactive({
  categories: false,
  details: false,
  cta: false,
});

// Get unique categories from products
const uniqueCategories = computed(() => {
  if (!products.value || products.value.length === 0) return [];

  const categories = [];
  const map = new Map();

  // Only process active products
  products.value
    .filter((product) => product.is_active)
    .forEach((product) => {
      if (Array.isArray(product.category_details)) {
        product.category_details.forEach((category) => {
          if (category && !map.has(category.id)) {
            map.set(category.id, true);
            categories.push(category);
          }
        });
      } else if (
        product.category_details &&
        !map.has(product.category_details.id)
      ) {
        map.set(product.category_details.id, true);
        categories.push(product.category_details);
      }
    });

  return categories;
});

// Get count of active products
const activeProductsCount = computed(() => {
  if (!products.value || products.value.length === 0) return 0;
  return products.value.filter((product) => product.is_active).length;
});

// Get count of active products by category
const getProductCountByCategory = (categoryId) => {
  if (!products.value || products.value.length === 0) return 0;

  return products.value.filter((product) => {
    // Only count active products
    if (!product.is_active) return false;

    // Handle array of categories
    if (Array.isArray(product.category_details)) {
      return product.category_details.some(
        (category) => category && category.id === categoryId
      );
    }
    // Handle single category object
    else if (
      product.category_details &&
      product.category_details.id === categoryId
    ) {
      return true;
    }
    // Fallback: check if category is a direct property
    else if (product.category === categoryId) {
      return true;
    }

    return false;
  }).length;
};

// Get category name by ID for display
const getCategoryName = (categoryId) => {
  if (!categoryId) return "All Products";

  // Find the category in uniqueCategories
  const category = uniqueCategories.value.find((cat) => cat.id === categoryId);
  return category ? category.name : "Category";
};

// Filter products by selected category
const filteredProducts = computed(() => {
  // Start with only active products
  let result = products.value.filter((product) => product.is_active);

  // Filter by category if selected
  if (selectedCategory.value) {
    result = result.filter((product) => {
      // Handle array of categories
      if (Array.isArray(product.category_details)) {
        return product.category_details.some(
          (category) => category && category.id === selectedCategory.value
        );
      }
      // Handle single category object
      else if (
        product.category_details &&
        product.category_details.id === selectedCategory.value
      ) {
        return true;
      }
      // Fallback: check if category is a direct property
      else if (product.category === selectedCategory.value) {
        return true;
      }

      return false;
    });
  }
  // Filter by search term if present
  if (searchValue.value.trim()) {
    const searchTerm = searchValue.value.toLowerCase().trim();
    result = result.filter(
      (product) =>
        product.name?.toLowerCase().includes(searchTerm) ||
        product.description?.toLowerCase().includes(searchTerm) ||
        product.short_description?.toLowerCase().includes(searchTerm) ||
        product.regular_price?.toString().includes(searchTerm) ||
        product.sale_price?.toString().includes(searchTerm) ||
        // Search in category names
        (Array.isArray(product.category_details)
          ? product.category_details.some((cat) =>
              cat.name?.toLowerCase().includes(searchTerm)
            )
          : product.category_details?.name?.toLowerCase().includes(searchTerm))
    );
  }

  return result;
});

// Add a function to handle search submission (for Enter key or button click)
function handleSearch() {
  // Trigger filtering by setting the search value
  console.log("Searching for:", searchValue.value);
  // The filteredProducts computed property will automatically update
}

// Watch search value for real-time search with debouncing
let searchTimeout = null;
watch(searchValue, (newValue) => {
  // Clear previous timeout
  if (searchTimeout) {
    clearTimeout(searchTimeout);
  }

  // Set new timeout for debounced search
  searchTimeout = setTimeout(() => {
    console.log("Live search for:", newValue);
    // The filteredProducts computed will automatically update
  }, 300); // 300ms delay
});

// Add keyboard shortcut for search (Ctrl/Cmd + K)
const searchInputRef = ref(null);

onMounted(async () => {
  // Keyboard shortcut for search
  const handleKeyboard = (event) => {
    // Ctrl+K or Cmd+K to focus search
    if ((event.ctrlKey || event.metaKey) && event.key === "k") {
      event.preventDefault();
      const searchInput = document.querySelector(
        'input[placeholder*="Search"], input[placeholder*="Find"]'
      );
      if (searchInput) {
        searchInput.focus();
      }
    }
    // Escape to clear search
    if (event.key === "Escape" && searchValue.value) {
      searchValue.value = "";
    }
  };

  document.addEventListener("keydown", handleKeyboard);

  // Clean up
  onUnmounted(() => {
    document.removeEventListener("keydown", handleKeyboard);
  });

  // Existing onMounted code
  // Get initial data
  await Promise.all([
    getStoreDetails(),
    getMyProducts(),
    getStoreReviewsCount(),
  ]);

  // If there's only one category, auto-select it
  if (uniqueCategories.value.length === 1) {
    selectedCategory.value = uniqueCategories.value[0].id;
  }

  // Enhanced scroll effects with IntersectionObserver for better performance
  const observerOptions = {
    root: null,
    rootMargin: "0px",
    threshold: 0.2,
  };
  const sectionObserver = new IntersectionObserver((entries) => {
    entries.forEach((entry) => {
      if (entry.target === categoriesRef.value) {
        visibleSections.categories = entry.isIntersecting;
      } else if (entry.target === detailsRef.value) {
        visibleSections.details = entry.isIntersecting;
      } else if (entry.target === ctaRef.value) {
        visibleSections.cta = entry.isIntersecting;
      }
    });
  }, observerOptions);

  // Observe sections for animations
  if (categoriesRef.value) sectionObserver.observe(categoriesRef.value);
  if (detailsRef.value) sectionObserver.observe(detailsRef.value);
  if (ctaRef.value) sectionObserver.observe(ctaRef.value);

  // Listen for sidebar toggle from header
  if (process.client) {
    window.addEventListener("eshop-sidebar-toggle", handleHeaderSidebarToggle);
  }

  // Fetch categories for sidebar
  await fetchCategories();

  // Clean up observers
  onUnmounted(() => {
    sectionObserver.disconnect();

    // Clean up event listeners
    if (process.client) {
      window.removeEventListener(
        "eshop-sidebar-toggle",
        handleHeaderSidebarToggle
      );
    }
  });
});
</script>
