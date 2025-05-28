<template>
  <UContainer class="py-4 md:py-6">
    <div class="min-h-screen">
      <!-- Modern Hero Banner with Layered Design -->
      <div
        class="relative bg-white rounded-xl md:rounded-2xl shadow-sm mb-8 md:mb-10 overflow-hidden"
      >
        <div class="absolute inset-0 z-0">
          <!-- Banner Background with Blurred Bottom Edge -->
          <div
            class="h-40 sm:h-48 md:h-60 w-full bg-cover bg-center relative after:absolute after:bottom-0 after:left-0 after:w-full after:h-16 sm:after:h-24 after:bg-gradient-to-t after:from-white after:to-transparent"
            :style="{
              backgroundImage: storeDetails?.store_banner
                ? `url(${storeDetails?.store_banner})`
                : 'url(\'/images/placeholder.jpg?height=800&width=1600\')',
            }"
          >
            <!-- Color Overlay -->
            <div
              class="absolute inset-0 bg-indigo-900/40 mix-blend-multiply"
            ></div>
          </div>
        </div>

        <!-- Store Content Section -->
        <div
          class="relative z-10 pt-20 sm:pt-32 md:pt-32 px-4 sm:px-6 md:px-8 pb-5 md:pb-6"
        >
          <!-- Store Info Flex Container -->
          <div
            class="flex flex-col md:flex-row md:items-end gap-4 md:gap-6 lg:gap-8 md:flex-none mt-20"
          >
            <!-- Store Logo with Border -->
            <div
              class="flex-shrink-0 -mt-20 pt-2 md:-mt-24 lg:-mt-28 relative mx-auto md:mx-0"
            >
              <div
                class="h-24 w-24 md:h-28 md:w-28 lg:h-32 lg:w-32 rounded-xl bg-white p-1.5 shadow-sm"
              >
                <div
                  class="w-full h-full rounded-lg overflow-hidden bg-gray-100"
                >
                  <img
                    v-if="storeDetails?.image"
                    :src="storeDetails?.image"
                    alt="Store Logo"
                    class="w-full h-full object-contain"
                  />
                  <div
                    v-else
                    class="w-full h-full bg-gradient-to-br from-indigo-500 to-blue-600 flex items-center justify-center text-white font-bold text-2xl md:text-3xl"
                  >
                    {{ getInitials(storeDetails?.store_name || "Store") }}
                  </div>
                </div>
              </div>
            </div>

            <!-- Store Actions -->
            <div class="mt-3 md:mt-0 flex-shrink-0 text-center md:text-left">
              <UButton
                v-if="isOwner"
                icon="i-heroicons-adjustments-horizontal"
                size="sm"
                color="indigo"
                @click="$router.push('/shop-manager')"
              >
                Manage Store
              </UButton>
            </div>
          </div>

          <!-- Store Name and Description -->
          <div class="flex-grow text-center md:text-left">
            <h1 class="text-xl sm:text-2xl md:text-3xl font-bold text-gray-900">
              {{ storeDetails?.store_name || "Store Name" }}
            </h1>
            <p
              class="text-gray-600 text-sm md:text-base mt-1.5 md:mt-2 max-w-2xl"
              :class="isSeeMore ? '' : 'line-clamp-2'"
            >
              {{
                storeDetails?.store_description ||
                "Store description will appear here."
              }}
            </p>
            <UButton
              v-if="storeDetails?.store_description"
              @click="isSeeMore = !isSeeMore"
              :label="isSeeMore ? 'Read Less' : 'Read More'"
              variant="link"
              size="xs"
              color="gray"
              class="ml-0 pl-0 mt-1"
            />
          </div>
          <!-- Store Info Badges -->

          <div
            class="flex flex-wrap justify-center md:justify-start gap-2 mt-3 md:mt-4"
          >
            <span
              v-if="storeDetails?.store_address"
              class="inline-flex items-center bg-gray-100 text-gray-800 rounded-full px-3 py-1 text-xs"
            >
              <MapPin class="w-3 h-3 mr-1" />
              {{ storeDetails?.store_address }}
            </span>
            <span
              v-if="storeDetails?.phone"
              class="inline-flex items-center bg-gray-100 text-gray-800 rounded-full px-3 py-1 text-xs"
            >
              <Phone class="w-3 h-3 mr-1" />
              {{ storeDetails?.phone }}
            </span>
            <span
              class="inline-flex items-center bg-indigo-100 text-indigo-800 rounded-full px-3 py-1 text-xs"
            >
              <UIcon name="i-heroicons-shopping-bag" class="w-3 h-3 mr-1" />
              {{ products?.length }} Products
            </span>
          </div>
        </div>
      </div>

      <!-- Products Section with Improved Layout -->
      <div class="grid grid-cols-12 gap-x-0 gap-y-3 md:gap-3">
        <!-- Mobile Search Bar - Visible only on small screens -->
        <div class="col-span-12 md:hidden">
          <div class="relative">
            <input
              type="text"
              v-model="searchValue"
              @keyup.enter="handleSearch"
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
              All Products ({{ products.length }})
            </button>

            <button
              v-for="category in uniqueCategories"
              :key="category.id"
              @click="selectedCategory = category.id"
              class="flex-shrink-0 px-3 py-1.5 rounded-lg transition-colors whitespace-nowrap text-sm"
              :class="
                selectedCategory === category.id
                  ? 'bg-indigo-100 text-indigo-800 font-medium'
                  : 'bg-gray-100 text-gray-800 hover:bg-gray-200'
              "
            >
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
                    @keyup.enter="handleSearch"
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
                      {{ products.length }}
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
                      <UIcon
                        name="i-heroicons-tag"
                        class="h-4 w-4 mr-2 opacity-75"
                      />
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
                  <p class="text-sm text-gray-500">No categories available</p>
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
                      <p class="text-xs text-gray-500 mt-0.5">
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
                      <p class="text-xs text-gray-500 mt-0.5">
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
                        class="text-xs text-gray-500 mt-0.5 truncate max-w-[140px]"
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
                      <p class="text-xs text-gray-500">
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
                    class="text-xs font-medium uppercase tracking-wider text-gray-500 mb-2"
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
                      class="text-xs font-medium uppercase tracking-wider text-gray-500 mb-1"
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
                <span class="text-sm font-normal text-gray-500 ml-2"
                  >({{ filteredProducts.length }})</span
                >
              </h2>
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
              No Products Found
            </h3>
            <p class="mt-2 text-sm md:text-base text-gray-500 max-w-md mx-auto">
              We couldn't find any products matching your current selection. Try
              changing your search or selecting a different category.
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

    <!-- Modals remain unchanged -->
    <!-- ...existing code... -->
  </UContainer>
</template>

<script setup>
const { get, patch } = useApi();
const router = useRoute();
const toast = useToast();
const products = ref([]);
const storeDetails = ref({});
const { user, token } = useAuth();
const isLoading = ref(false);
const isSeeMore = ref(false);

// Check if current user is store owner
const isOwner = computed(() => {
  return (
    user.value?.user?.store_username === storeDetails.value?.store_username
  );
});

import {
  Search,
  MapPin,
  Clock,
  Mail,
  ChevronRight,
  X,
  Phone,
  LocateIcon,
} from "lucide-vue-next";

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
    console.log("Products loaded:", products.value.length);
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
    console.log("Store details loaded successfully");
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

  products.value.forEach((product) => {
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

// Filter products by selected category
const filteredProducts = computed(() => {
  let result = products.value;

  // Filter by category if selected
  if (selectedCategory.value) {
    result = result.filter(
      (product) => product.category === selectedCategory.value
    );
  }

  // Filter by search term if present
  if (searchValue.value.trim()) {
    const searchTerm = searchValue.value.toLowerCase().trim();
    result = result.filter(
      (product) =>
        product.name?.toLowerCase().includes(searchTerm) ||
        product.description?.toLowerCase().includes(searchTerm) ||
        product.price?.toString().includes(searchTerm)
    );
  }

  return result;
});

// Add a function to handle search submission (for Enter key or button click)
function handleSearch() {
  // Trigger filtering by setting the search value
  console.log("Searching for:", searchValue.value);
  // You could add additional logic here if needed
}

// Helper function to get product count by category
function getProductCountByCategory(categoryId) {
  if (!products.value || products.value.length === 0) return 0;

  return products.value.filter((product) => {
    // Check if category is a direct property or inside category_details
    if (product.category === categoryId) return true;
    if (product.category_details && product.category_details.id === categoryId)
      return true;
    return false;
  }).length;
}

// Helper function to get category name
function getCategoryName(categoryId) {
  if (!categoryId) return "All Products";

  const category = uniqueCategories.value.find((c) => c.id === categoryId);
  return category ? category.name : "All Products";
}

// Add function to clear filters
function clearFilters() {
  searchValue.value = "";
  selectedCategory.value = null;
}

// Refs
const categoriesRef = ref(null);
const detailsRef = ref(null);
const ctaRef = ref(null);

// Helper function to clean phone number for WhatsApp
function cleanPhoneNumber(phone) {
  if (!phone) return "";
  // Remove spaces, dashes, parentheses and other non-numeric characters
  return phone.replace(/[^\d+]/g, "");
}

// Initialize component
onMounted(async () => {
  // Get initial data
  await Promise.all([getStoreDetails(), getMyProducts()]);

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

  // Clean up observers
  onUnmounted(() => {
    sectionObserver.disconnect();
  });
});
</script>

<style>
/* Remove any unnecessary animations to keep the design clean */
.line-clamp-2 {
  display: -webkit-box;
  -webkit-line-clamp: 2;
  -webkit-box-orient: vertical;
  overflow: hidden;
  transition: all 0.2s ease;
  line-clamp: 2; /* Standard property for compatibility */
}

/* Add new style for hiding scrollbars while allowing scrolling */
.hide-scrollbar {
  -ms-overflow-style: none; /* IE and Edge */
  scrollbar-width: none; /* Firefox */
}

.hide-scrollbar::-webkit-scrollbar {
  display: none; /* Chrome, Safari and Opera */
}
</style>
