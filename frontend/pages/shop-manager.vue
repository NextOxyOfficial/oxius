<template>
  <div class="bg-gradient-to-br from-gray-50 to-gray-100 py-2 md:py-4">
    <!-- Main Content -->
    <UContainer>
      <PublicEshopTitle />
      <div v-if="!user?.user?.is_pro" class="my-8">
        <div
          class="transition-all duration-700"
          :class="
            mounted ? 'opacity-100 translate-y-0' : 'opacity-0 translate-y-4'
          "
        >
          <div
            class="relative mx-auto max-w-3xl overflow-hidden rounded-xl border-0 bg-gradient-to-br from-slate-50 to-slate-100 shadow-xl dark:from-slate-900 dark:to-slate-800"
          >
            <!-- Glass effect overlay -->
            <div
              class="absolute inset-0 bg-white/30 backdrop-blur-sm dark:bg-black/30"
            ></div>

            <!-- Decorative elements -->
            <div
              class="absolute -left-6 -top-6 h-24 w-24 rounded-full bg-blue-500/10 blur-2xl"
            ></div>
            <div
              class="absolute -bottom-10 -right-10 h-32 w-32 rounded-full bg-purple-500/20 blur-3xl"
            ></div>

            <!-- Sparkles -->
            <div
              v-for="(sparkle, index) in sparkles"
              :key="index"
              class="sparkle absolute text-yellow-400 opacity-70 animate-pulse"
              :class="sparkle.class"
              :style="{ animationDelay: `${sparkle.delay}s` }"
            >
              <SparklesIcon :size="sparkle.size" />
            </div>

            <div class="relative flex flex-col overflow-hidden md:flex-row">
              <!-- Left premium badge section -->
              <div
                class="flex items-center justify-center bg-gradient-to-br from-blue-600 to-purple-700 p-8 text-white md:w-2/5"
              >
                <div
                  class="flex flex-col items-center justify-center space-y-3"
                >
                  <div class="relative">
                    <div
                      class="absolute -inset-1 animate-spin-slow rounded-full bg-gradient-to-r from-yellow-400 via-white to-yellow-400 opacity-30 blur-sm"
                    ></div>
                    <div
                      class="relative rounded-full bg-gradient-to-br from-blue-600 to-purple-700 p-3"
                    >
                      <CrownIcon class="h-10 w-10 text-yellow-300" />
                    </div>
                  </div>
                  <span
                    class="text-sm font-medium uppercase tracking-wider text-blue-100"
                    >{{ $t("premium_access") }}</span
                  >
                </div>
              </div>

              <!-- Right content section -->
              <div class="relative p-8 md:w-3/5">
                <div class="mb-6">
                  <h3
                    class="mb-3 text-2xl font-bold tracking-tight text-slate-700"
                  >
                    {{ $t("premium_access_required") }}
                  </h3>
                  <p class="text-muted-foreground">
                    {{ $t("premium_access_text") }}
                  </p>
                </div>

                <NuxtLink
                  href="/upgrade-to-pro"
                  class="group relative flex w-full items-center justify-center gap-2 overflow-hidden rounded-lg bg-gradient-to-r from-blue-600 to-purple-700 px-4 py-3 text-white transition-all hover:shadow-lg hover:shadow-blue-500/25"
                >
                  <span>{{ $t("premium_upgrade") }}</span>
                  <span
                    class="inline-block transition-transform duration-300 group-hover:translate-x-1"
                    >→</span
                  >
                  <span
                    class="absolute -right-1 -top-1 h-8 w-8 rotate-12 animate-pulse rounded-full bg-white opacity-30 blur-md transition-all duration-300 group-hover:opacity-40"
                  ></span>
                </NuxtLink>
              </div>
            </div>
          </div>
        </div>
      </div>
      <div v-else>
        <CommonStoreCreateForm
          v-if="user?.user.is_pro && !user?.user.store_username"
        />
        <div v-else>
          <!-- store details -->
          <div
            class="bg-white rounded-lg shadow-sm border border-gray-100 hover:shadow-md transition-all duration-300 w-full mb-3 overflow-hidden transform hover:scale-[1.01]"
          >
            <!-- Compact Header with Shimmer Effect -->
            <div
              class="bg-gradient-to-r from-emerald-600 to-teal-500 px-4 py-3 flex items-center relative overflow-hidden"
            >
              <!-- Shimmer Effect -->
              <div class="absolute inset-0 opacity-20 shimmer-animation"></div>

              <UIcon
                name="i-heroicons-shopping-bag"
                class="h-5 w-5 text-white mr-2 relative z-10"
              />
              <h3
                class="text-base font-semibold text-white relative z-10 truncate"
              >
                My Store Details
              </h3>

              <!-- Edit Button -->
              <button
                @click="isEditing = !isEditing"
                class="ml-auto inline-flex items-center px-3 py-1.5 bg-white/20 rounded text-xs font-medium text-white hover:bg-white/30 focus:outline-none transition-colors duration-300 relative z-10"
              >
                <UIcon
                  :name="
                    isEditing
                      ? 'i-heroicons-check'
                      : 'i-heroicons-pencil-square'
                  "
                  class="h-3.5 w-3.5 mr-1.5"
                />
                {{ isEditing ? "Save" : "Edit" }}
              </button>
            </div>

            <!-- Content Grid with More Height -->
            <div class="p-4 grid grid-cols-1 sm:grid-cols-2 gap-4">
              <!-- Shop Name -->
              <div class="flex items-start group">
                <div class="flex-shrink-0 mt-1">
                  <div
                    class="bg-emerald-100 p-2 rounded-full group-hover:bg-emerald-200 transition-colors duration-300"
                  >
                    <UIcon
                      name="i-heroicons-building-storefront"
                      class="h-4 w-4 text-emerald-600"
                    />
                  </div>
                </div>
                <div class="ml-3 overflow-hidden flex-1">
                  <p class="text-xs font-medium text-gray-500 mb-1">
                    Shop Name
                  </p>
                  <input
                    v-if="isEditing"
                    v-model="editedUser.store_name"
                    class="text-sm font-semibold text-gray-800 w-full border-b border-emerald-200 focus:border-emerald-500 focus:outline-none py-1"
                  />
                  <p
                    v-else
                    class="text-sm font-semibold text-gray-800 truncate"
                  >
                    {{ user.user.store_name || "Not set" }}
                  </p>
                </div>
              </div>

              <!-- Store URL (Non-editable) -->
              <div class="flex items-start group">
                <div class="flex-shrink-0 mt-1">
                  <div
                    class="bg-emerald-100 p-2 rounded-full group-hover:bg-emerald-200 transition-colors duration-300"
                  >
                    <UIcon
                      name="i-heroicons-link"
                      class="h-4 w-4 text-emerald-600"
                    />
                  </div>
                </div>
                <div class="ml-3 overflow-hidden flex-1">
                  <p class="text-xs font-medium text-gray-500 mb-1">
                    Store URL
                  </p>
                  <div class="flex items-center flex-wrap">
                    <div
                      class="flex items-center bg-gray-50 rounded px-2 py-1 max-w-full overflow-hidden"
                    >
                      <p class="text-xs text-gray-500 whitespace-nowrap">
                        adsyclub.com/eshop/
                      </p>
                      <p
                        class="text-sm font-semibold text-emerald-600 truncate"
                      >
                        {{ user.user.store_username || "Not set" }}
                      </p>
                      <button
                        v-if="user.user.store_username"
                        @click="
                          copyToClipboard(
                            `https://adsyclub.com/eshop/${user.user.store_username}`
                          )
                        "
                        class="ml-1.5 text-gray-400 hover:text-emerald-600 transition-colors flex-shrink-0"
                        :class="{ 'text-emerald-600': copied }"
                      >
                        <UIcon
                          :name="
                            copied
                              ? 'i-heroicons-check'
                              : 'i-heroicons-clipboard'
                          "
                          class="h-3.5 w-3.5"
                        />
                      </button>
                    </div>
                  </div>
                  <p class="text-xs text-gray-400 mt-1 italic">
                    URL cannot be changed
                  </p>
                </div>
              </div>

              <!-- Shop Address -->
              <div class="flex items-start group">
                <div class="flex-shrink-0 mt-1">
                  <div
                    class="bg-emerald-100 p-2 rounded-full group-hover:bg-emerald-200 transition-colors duration-300"
                  >
                    <UIcon
                      name="i-heroicons-map-pin"
                      class="h-4 w-4 text-emerald-600"
                    />
                  </div>
                </div>
                <div class="ml-3 overflow-hidden flex-1">
                  <p class="text-xs font-medium text-gray-500 mb-1">
                    Shop Address
                  </p>
                  <input
                    v-if="isEditing"
                    v-model="editedUser.store_address"
                    class="text-sm font-semibold text-gray-800 w-full border-b border-emerald-200 focus:border-emerald-500 focus:outline-none py-1"
                  />
                  <p
                    v-else
                    class="text-sm font-semibold text-gray-800 truncate"
                  >
                    {{ user.user.store_address || "Not set" }}
                  </p>
                </div>
              </div>

              <!-- Shop Description -->
              <div class="flex items-start group">
                <div class="flex-shrink-0 mt-1">
                  <div
                    class="bg-emerald-100 p-2 rounded-full group-hover:bg-emerald-200 transition-colors duration-300"
                  >
                    <UIcon
                      name="i-heroicons-document-text"
                      class="h-4 w-4 text-emerald-600"
                    />
                  </div>
                </div>
                <div class="ml-3 overflow-hidden flex-1">
                  <p class="text-xs font-medium text-gray-500 mb-1">
                    Description
                  </p>
                  <textarea
                    v-if="isEditing"
                    v-model="editedUser.store_description"
                    rows="2"
                    class="text-sm text-gray-800 w-full border border-emerald-200 rounded focus:border-emerald-500 focus:outline-none py-1 px-2 resize-none"
                  ></textarea>
                  <p v-else class="text-sm text-gray-800 line-clamp-2">
                    {{
                      user.user.store_description || "No description available"
                    }}
                  </p>
                </div>
              </div>
            </div>

            <!-- Status Indicator -->
            <div
              class="px-4 py-2 bg-gray-50 border-t border-gray-100 flex flex-col sm:flex-row items-start sm:items-center"
            >
              <div class="flex items-center">
                <div
                  class="h-2 w-2 rounded-full bg-emerald-500 mr-2 animate-pulse"
                ></div>
                <span class="text-xs text-gray-600">Store Active</span>
              </div>
              <div class="mt-1 sm:mt-0 sm:ml-auto text-xs text-gray-500">
                Last updated: {{ formatDate(new Date()) }}
              </div>
            </div>

            <!-- Pulse Effect at Bottom -->
            <div
              class="h-1 bg-gradient-to-r from-emerald-500 via-teal-500 to-emerald-500 bg-[length:200%_100%] animate-gradient-x"
            ></div>
          </div>
          <!-- Premium Tabs -->
          <div class="bg-white rounded-xl shadow-xl overflow-hidden mb-4">
            <div class="flex border-b border-gray-100">
              <button
                v-for="tab in tabs"
                :key="tab.id"
                @click="activeTab = tab.id"
                class="relative flex-1 flex items-center justify-center py-5 px-4 text-sm font-medium transition-all duration-200 overflow-hidden"
                :class="[
                  activeTab === tab.id
                    ? 'text-indigo-600 bg-gray-200'
                    : 'text-gray-500 hover:text-gray-700 hover:bg-gray-50',
                ]"
              >
                <div class="flex items-center space-x-2">
                  <component
                    :is="tab.icon"
                    :class="[
                      'h-5 w-5 transition-transform duration-300',
                      activeTab === tab.id
                        ? 'text-indigo-600 scale-110'
                        : 'text-gray-400',
                    ]"
                  />
                  <span>{{ tab.name }}</span>
                </div>
                <div
                  v-if="activeTab === tab.id"
                  class="absolute bottom-0 left-0 right-0 h-0.5 bg-gradient-to-r from-indigo-400 to-indigo-600 transform origin-left animate-grow"
                ></div>
              </button>
            </div>
          </div>

          <!-- Tab Content -->
          <div
            class="overflow-hidden transition-all duration-300"
            :class="
              activeTab === 'add-product' ? '' : 'bg-white shadow-xl rounded-xl'
            "
          >
            <!-- My Orders Tab -->
            <div v-if="activeTab === 'orders'" class="animate-fade-in">
              <!-- Order Summary Cards -->
              <div
                class="grid grid-cols-2 md:grid-cols-4 gap-4 p-6 bg-gray-50 border-b border-gray-200"
              >
                <!-- Total Orders Card -->
                <div
                  class="bg-white rounded-lg shadow-sm p-4 border border-gray-100 relative overflow-hidden"
                >
                  <div
                    v-if="isOrdersLoading"
                    class="absolute inset-0 bg-white/70 flex items-center justify-center"
                  >
                    <UIcon
                      name="i-heroicons-arrow-path"
                      class="h-6 w-6 animate-spin text-gray-400"
                    />
                  </div>
                  <div class="flex items-center justify-between">
                    <div>
                      <p class="text-sm font-medium text-gray-500">
                        Total Orders
                      </p>
                      <p class="text-2xl font-bold text-gray-900">
                        {{ orders.length }}
                      </p>
                    </div>
                    <div
                      class="h-12 w-12 rounded-full bg-indigo-50 flex items-center justify-center"
                    >
                      <UIcon
                        name="i-heroicons-shopping-bag"
                        class="h-6 w-6 text-indigo-500"
                      />
                    </div>
                  </div>
                  <p class="mt-2 text-sm font-medium text-indigo-600">
                    ৳{{ formatAmount(totalOrdersAmount) }}
                  </p>
                </div>

                <!-- Pending Orders Card -->
                <div
                  class="bg-white rounded-lg shadow-sm p-4 border border-gray-100 relative overflow-hidden"
                >
                  <div
                    v-if="isOrdersLoading"
                    class="absolute inset-0 bg-white/70 flex items-center justify-center"
                  >
                    <UIcon
                      name="i-heroicons-arrow-path"
                      class="h-6 w-6 animate-spin text-gray-400"
                    />
                  </div>
                  <div class="flex items-center justify-between">
                    <div>
                      <p class="text-sm font-medium text-gray-500">
                        Pending Orders
                      </p>
                      <p class="text-2xl font-bold text-gray-900">
                        {{ pendingOrders.length }}
                      </p>
                    </div>
                    <div
                      class="h-12 w-12 rounded-full bg-yellow-50 flex items-center justify-center"
                    >
                      <UIcon
                        name="i-heroicons-clock"
                        class="h-6 w-6 text-yellow-500"
                      />
                    </div>
                  </div>
                  <p class="mt-2 text-sm font-medium text-yellow-600">
                    ৳{{ formatAmount(pendingOrdersAmount) }}
                  </p>
                </div>

                <!-- Processing Orders Card -->
                <div
                  class="bg-white rounded-lg shadow-sm p-4 border border-gray-100 relative overflow-hidden"
                >
                  <div
                    v-if="isOrdersLoading"
                    class="absolute inset-0 bg-white/70 flex items-center justify-center"
                  >
                    <UIcon
                      name="i-heroicons-arrow-path"
                      class="h-6 w-6 animate-spin text-gray-400"
                    />
                  </div>
                  <div class="flex items-center justify-between">
                    <div>
                      <p class="text-sm font-medium text-gray-500">
                        Processing Orders
                      </p>
                      <p class="text-2xl font-bold text-gray-900">
                        {{ processingOrders.length }}
                      </p>
                    </div>
                    <div
                      class="h-12 w-12 rounded-full bg-blue-50 flex items-center justify-center"
                    >
                      <UIcon
                        name="i-heroicons-cog-6-tooth"
                        class="h-6 w-6 text-blue-500"
                      />
                    </div>
                  </div>
                  <p class="mt-2 text-sm font-medium text-blue-600">
                    ৳{{ formatAmount(processingOrdersAmount) }}
                  </p>
                </div>

                <!-- Delivered Orders Card -->
                <div
                  class="bg-white rounded-lg shadow-sm p-4 border border-gray-100 relative overflow-hidden"
                >
                  <div
                    v-if="isOrdersLoading"
                    class="absolute inset-0 bg-white/70 flex items-center justify-center"
                  >
                    <UIcon
                      name="i-heroicons-arrow-path"
                      class="h-6 w-6 animate-spin text-gray-400"
                    />
                  </div>
                  <div class="flex items-center justify-between">
                    <div>
                      <p class="text-sm font-medium text-gray-500">
                        Delivered Orders
                      </p>
                      <p class="text-2xl font-bold text-gray-900">
                        {{ deliveredOrders.length }}
                      </p>
                    </div>
                    <div
                      class="h-12 w-12 rounded-full bg-green-50 flex items-center justify-center"
                    >
                      <UIcon
                        name="i-heroicons-check-circle"
                        class="h-6 w-6 text-green-500"
                      />
                    </div>
                  </div>
                  <p class="mt-2 text-sm font-medium text-green-600">
                    ৳{{ formatAmount(deliveredOrdersAmount) }}
                  </p>
                </div>
              </div>

              <div class="px-6 py-5 border-b border-gray-200 bg-gray-50">
                <div
                  class="flex flex-col md:flex-row md:items-center md:justify-between"
                >
                  <div class="flex items-center space-x-2">
                    <ShoppingBag class="h-5 w-5 text-indigo-600" />
                    <h2 class="text-xl font-semibold text-gray-800">
                      My Orders
                    </h2>
                  </div>
                  <div class="mt-3 md:mt-0 flex items-center space-x-4">
                    <div class="relative">
                      <select
                        v-model="orderFilter"
                        class="block w-full pl-3 pr-10 py-1.5 text-base border-gray-300 focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm rounded-md"
                      >
                        <option value="all">All Orders</option>
                        <option value="pending">Pending</option>
                        <option value="processing">Processing</option>
                        <option value="shipped">Shipped</option>
                        <option value="delivered">Delivered</option>
                        <option value="cancelled">Cancelled</option>
                      </select>
                    </div>
                    <div class="relative rounded-md shadow-sm">
                      <input
                        type="text"
                        v-model="orderSearch"
                        placeholder="Search orders..."
                        class="focus:ring-indigo-500 focus:border-indigo-500 block w-full pr-10 py-2 pl-1.5 sm:text-sm border-gray-300 rounded-md"
                      />
                      <div
                        class="absolute inset-y-0 right-0 pr-3 flex items-center pointer-events-none"
                      >
                        <Search class="h-5 w-5 text-gray-400" />
                      </div>
                    </div>
                  </div>
                </div>
              </div>

              <div class="overflow-x-auto">
                <table class="min-w-full divide-y divide-gray-200">
                  <thead class="bg-gray-50">
                    <tr>
                      <th
                        scope="col"
                        class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider"
                      >
                        Order ID
                      </th>
                      <th
                        scope="col"
                        class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider"
                      >
                        Status
                      </th>
                      <th
                        scope="col"
                        class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider"
                      >
                        Date
                      </th>
                      <th
                        scope="col"
                        class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider"
                      >
                        Customer
                      </th>
                      <th
                        scope="col"
                        class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider"
                      >
                        Total
                      </th>
                      <th
                        scope="col"
                        class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider"
                      >
                        Actions
                      </th>
                    </tr>
                  </thead>
                  <tbody class="bg-white divide-y divide-gray-200">
                    <tr
                      v-for="(order, i) in orders"
                      :key="order.id"
                      class="hover:bg-gray-50 transition-colors duration-150"
                    >
                      <td class="px-6 py-4 whitespace-nowrap">
                        <div class="text-sm font-medium text-indigo-600">
                          #{{ i + 1 }}
                        </div>
                      </td>
                      <td class="px-6 py-4 whitespace-nowrap">
                        <span
                          :class="getStatusClass(order.status)"
                          class="px-2 inline-flex text-xs leading-5 font-semibold rounded-full capitalize"
                        >
                          {{ order.order_status }}
                        </span>
                      </td>
                      <td class="px-6 py-4 whitespace-nowrap">
                        <div class="text-sm text-gray-900">
                          {{ formatDate(order.created_at) }}
                        </div>
                      </td>
                      <td class="px-6 py-4 whitespace-nowrap">
                        <div class="text-sm text-gray-900">
                          {{ order.customer_details.first_name }}
                          {{ order.customer_details.last_name }}
                        </div>
                        <div class="text-sm text-gray-500">
                          {{ order.email }}
                        </div>
                      </td>
                      <td class="px-6 py-4 whitespace-nowrap">
                        <div class="text-sm font-medium text-gray-900">
                          ৳{{ order.total }}
                        </div>
                      </td>
                      <td
                        class="px-6 py-4 whitespace-nowrap text-sm font-medium"
                      >
                        <div class="flex space-x-2">
                          <button
                            @click="viewOrderDetails(order)"
                            class="text-indigo-600 hover:text-indigo-900 transition-colors duration-150 flex items-center"
                          >
                            <Eye class="h-4 w-4 mr-1" />
                            View
                          </button>
                          <button
                            @click="printOrder(order)"
                            class="text-gray-600 hover:text-gray-900 transition-colors duration-150 flex items-center"
                          >
                            <Printer class="h-4 w-4 mr-1" />
                            Print
                          </button>
                        </div>
                      </td>
                    </tr>
                    <tr v-if="paginatedOrders.length === 0">
                      <td
                        colspan="6"
                        class="px-6 py-10 text-center text-gray-500"
                      >
                        <div class="flex flex-col items-center justify-center">
                          <PackageX class="h-10 w-10 text-gray-300 mb-2" />
                          No orders found matching your criteria
                        </div>
                      </td>
                    </tr>
                  </tbody>
                </table>
              </div>

              <!-- Pagination -->
              <div
                class="bg-white px-4 py-3 flex items-center justify-between border-t border-gray-200 sm:px-6"
              >
                <div
                  class="hidden sm:flex-1 sm:flex sm:items-center sm:justify-between"
                >
                  <div>
                    <p class="text-sm text-gray-700">
                      Showing
                      <span class="font-medium">{{ paginationStart }}</span> to
                      <span class="font-medium">{{ paginationEnd }}</span> of
                      <span class="font-medium">{{
                        filteredOrders.length
                      }}</span>
                      results
                    </p>
                  </div>
                  <div>
                    <nav
                      class="relative z-0 inline-flex rounded-md shadow-sm -space-x-px"
                      aria-label="Pagination"
                    >
                      <button
                        @click="prevPage"
                        :disabled="currentPage === 1"
                        class="relative inline-flex items-center px-2 py-2 rounded-l-md border border-gray-300 bg-white text-sm font-medium text-gray-500 hover:bg-gray-50 disabled:opacity-50 disabled:cursor-not-allowed"
                      >
                        <span class="sr-only">Previous</span>
                        <ChevronLeft class="h-5 w-5" />
                      </button>

                      <button
                        v-for="page in displayedPages"
                        :key="page"
                        @click="goToPage(page)"
                        :class="[
                          currentPage === page
                            ? 'bg-indigo-50 text-indigo-600 border-indigo-500'
                            : 'bg-white text-gray-700 hover:bg-gray-50',
                          'relative inline-flex items-center px-4 py-2 border border-gray-300 text-sm font-medium',
                        ]"
                      >
                        {{ page }}
                      </button>

                      <button
                        @click="nextPage"
                        :disabled="currentPage === totalPages"
                        class="relative inline-flex items-center px-2 py-2 rounded-r-md border border-gray-300 bg-white text-sm font-medium text-gray-500 hover:bg-gray-50 disabled:opacity-50 disabled:cursor-not-allowed"
                      >
                        <span class="sr-only">Next</span>
                        <ChevronRight class="h-5 w-5" />
                      </button>
                    </nav>
                  </div>
                </div>
              </div>
            </div>

            <!-- My Products Tab -->
            <div v-if="activeTab === 'products'" class="animate-fade-in">
              <!-- Product Summary Cards -->
              <div
                class="grid grid-cols-2 md:grid-cols-4 gap-2 p-2 bg-gray-50 border-b border-gray-200"
              >
                <div
                  class="bg-white rounded-lg shadow-sm p-4 border border-gray-100"
                >
                  <div class="flex items-center justify-between">
                    <div>
                      <p class="text-sm font-medium text-gray-500">
                        Total Products
                      </p>
                      <p class="text-2xl font-bold text-gray-900">
                        {{ products.length }}
                      </p>
                    </div>
                    <div
                      class="h-12 w-12 rounded-full bg-indigo-50 flex items-center justify-center"
                    >
                      <ShoppingCart class="h-6 w-6 text-indigo-500" />
                    </div>
                  </div>
                  <p class="mt-2 text-sm font-medium text-indigo-600">
                    ৳{{ totalProductsValue }}
                  </p>
                </div>

                <div
                  class="bg-white rounded-lg shadow-sm p-4 border border-gray-100"
                >
                  <div class="flex items-center justify-between">
                    <div>
                      <p class="text-sm font-medium text-gray-500">
                        Active Products
                      </p>
                      <p class="text-2xl font-bold text-gray-900">
                        {{ activeProducts.length }}
                      </p>
                    </div>
                    <div
                      class="h-12 w-12 rounded-full bg-green-50 flex items-center justify-center"
                    >
                      <CircleCheck class="h-6 w-6 text-green-500" />
                    </div>
                  </div>
                  <p class="mt-2 text-sm font-medium text-green-600">
                    ৳{{ activeProductsValue }}
                  </p>
                </div>

                <div
                  class="bg-white rounded-lg shadow-sm p-4 border border-gray-100"
                >
                  <div class="flex items-center justify-between">
                    <div>
                      <p class="text-sm font-medium text-gray-500">
                        Inactive Products
                      </p>
                      <p class="text-2xl font-bold text-gray-900">
                        {{ inactiveProducts.length }}
                      </p>
                    </div>
                    <div
                      class="h-12 w-12 rounded-full bg-gray-50 flex items-center justify-center"
                    >
                      <CirclePause class="h-6 w-6 text-gray-500" />
                    </div>
                  </div>
                  <p class="mt-2 text-sm font-medium text-gray-600">
                    ৳{{ inactiveProductsValue }}
                  </p>
                </div>

                <div
                  class="bg-white rounded-lg shadow-sm p-4 border border-gray-100"
                >
                  <div class="flex items-center justify-between">
                    <div>
                      <p class="text-sm font-medium text-gray-500">
                        Out of Stock
                      </p>
                      <p class="text-2xl font-bold text-gray-900">
                        {{ outOfStockProducts.length }}
                      </p>
                    </div>
                    <div
                      class="h-12 w-12 rounded-full bg-red-50 flex items-center justify-center"
                    >
                      <CircleX class="h-6 w-6 text-red-500" />
                    </div>
                  </div>
                  <p class="mt-2 text-sm font-medium text-red-600">
                    ৳{{ outOfStockProductsValue }}
                  </p>
                </div>
              </div>

              <div class="px-6 py-5 border-b border-gray-200 bg-gray-50">
                <div
                  class="flex flex-col md:flex-row md:items-center md:justify-between"
                >
                  <div class="flex items-center space-x-2">
                    <ShoppingCart class="h-5 w-5 text-indigo-600" />
                    <h2 class="text-xl font-semibold text-gray-800">
                      My Products
                    </h2>
                  </div>
                  <div class="mt-3 md:mt-0 flex items-center space-x-4">
                    <div class="relative">
                      <select
                        v-model="productFilter"
                        class="block w-full pl-3 pr-10 py-1.5 text-base border-gray-300 focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm rounded-md"
                      >
                        <option value="all">All Products</option>
                        <option value="active">Active</option>
                        <option value="inactive">Inactive</option>
                        <option value="out-of-stock">Out of Stock</option>
                      </select>
                    </div>
                    <div class="relative rounded-md shadow-sm">
                      <input
                        type="text"
                        v-model="productSearch"
                        placeholder="Search products..."
                        class="focus:ring-indigo-500 focus:border-indigo-500 block w-full pr-10 py-2 pl-1.5 sm:text-sm border-gray-300 rounded-md"
                      />
                      <div
                        class="absolute inset-y-0 right-0 pr-3 flex items-center pointer-events-none"
                      >
                        <Search class="h-5 w-5 text-gray-400" />
                      </div>
                    </div>
                  </div>
                </div>
              </div>

              <!-- Products Grid -->
              <div
                class="p-6 grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-6"
              >
                <div
                  v-for="product in products"
                  :key="product.id"
                  class="group bg-white border border-gray-200 rounded-lg shadow-sm overflow-hidden hover:shadow-md transition-all duration-300 transform hover:-translate-y-1"
                >
                  <div class="relative">
                    <img
                      v-if="product?.image_details?.length"
                      :src="product.image_details[0].image"
                      :alt="product.name"
                      class="w-full h-48 object-cover transition-transform duration-500 group-hover:scale-105"
                    />
                    <div class="absolute top-2 right-2">
                      <span
                        v-if="product.status === 'active'"
                        class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-green-100 text-green-800"
                      >
                        <CircleCheck class="h-3 w-3 mr-1" />
                        Active
                      </span>
                      <span
                        v-else-if="product.status === 'inactive'"
                        class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-gray-100 text-gray-800"
                      >
                        <CirclePause class="h-3 w-3 mr-1" />
                        Inactive
                      </span>
                      <span
                        v-else
                        class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-red-100 text-red-800"
                      >
                        <CircleX class="h-3 w-3 mr-1" />
                        Out of Stock
                      </span>
                    </div>
                  </div>
                  <div class="p-4">
                    <h3
                      class="text-lg font-medium text-gray-900 mb-1 line-clamp-1"
                    >
                      {{ product.name }}
                    </h3>
                    <div
                      v-html="product.description"
                      class="text-sm text-gray-500 mb-2 line-clamp-2"
                    ></div>
                    <div class="flex justify-between items-center">
                      <div class="text-lg font-bold text-indigo-600">
                        ৳{{ product.sale_price }}
                      </div>
                      <div class="text-sm text-gray-500 flex items-center">
                        <Package class="h-4 w-4 mr-1 text-gray-400" />
                        {{ product.stock }}
                      </div>
                    </div>
                    <div class="flex flex-col sm:flex-row gap-2 mt-4">
                      <!-- Edit Button -->
                      <button
                        @click="editProduct(product)"
                        class="btn-action flex-1 group relative overflow-hidden rounded-lg py-2 px-3 flex items-center justify-center gap-2 bg-gradient-to-r from-indigo-50 to-blue-50 dark:from-indigo-900/30 dark:to-blue-900/30 border border-indigo-100 dark:border-indigo-800/30 text-indigo-600 dark:text-indigo-400 hover:shadow-md transition-all duration-300"
                      >
                        <!-- Hover effect overlay -->
                        <div
                          class="absolute inset-0 bg-gradient-to-r from-indigo-500 to-blue-500 opacity-0 group-hover:opacity-100 transition-opacity duration-300"
                        ></div>

                        <!-- Icon and text -->
                        <Edit2
                          class="h-4 w-4 relative z-10 group-hover:text-white transition-colors duration-300"
                        />
                        <span
                          class="font-medium text-sm relative z-10 group-hover:text-white transition-colors duration-300"
                          >Edit</span
                        >

                        <!-- Subtle glow effect on hover -->
                        <div
                          class="absolute inset-0 rounded-lg opacity-0 group-hover:opacity-100 transition-opacity duration-300 bg-indigo-400/20 blur-sm"
                        ></div>
                      </button>

                      <!-- Activate/Deactivate Button -->
                      <button
                        @click="toggleProductStatus(product)"
                        class="btn-action flex-1 group relative overflow-hidden rounded-lg py-2 px-3 flex items-center justify-center gap-2 bg-gradient-to-r from-slate-50 to-gray-50 dark:from-slate-900/30 dark:to-gray-900/30 border border-slate-200 dark:border-slate-800/30 text-slate-600 dark:text-slate-400 hover:shadow-md transition-all duration-300"
                      >
                        <!-- Hover effect overlay -->
                        <div
                          class="absolute inset-0 bg-gradient-to-r from-slate-600 to-gray-600 opacity-0 group-hover:opacity-100 transition-opacity duration-300"
                        ></div>

                        <!-- Dynamic icon based on product status -->
                        <component
                          :is="product.status === 'active' ? 'EyeOff' : 'Eye'"
                          class="h-4 w-4 relative z-10 group-hover:text-white transition-colors duration-300"
                        />

                        <!-- Dynamic text based on product status -->
                        <span
                          class="font-medium text-sm relative z-10 group-hover:text-white transition-colors duration-300 whitespace-nowrap"
                        >
                          {{
                            product.status === "active"
                              ? "Deactivate"
                              : "Activate"
                          }}
                        </span>

                        <!-- Subtle glow effect on hover -->
                        <div
                          class="absolute inset-0 rounded-lg opacity-0 group-hover:opacity-100 transition-opacity duration-300 bg-slate-400/20 blur-sm"
                        ></div>
                      </button>

                      <!-- Delete Button -->
                      <button
                        @click="confirmDeleteProduct(product)"
                        class="btn-action flex-1 group relative overflow-hidden rounded-lg py-2 px-3 flex items-center justify-center gap-2 bg-gradient-to-r from-red-50 to-rose-50 dark:from-red-900/30 dark:to-rose-900/30 border border-red-100 dark:border-red-800/30 text-red-600 dark:text-red-400 hover:shadow-md transition-all duration-300"
                      >
                        <!-- Hover effect overlay -->
                        <div
                          class="absolute inset-0 bg-gradient-to-r from-red-500 to-rose-500 opacity-0 group-hover:opacity-100 transition-opacity duration-300"
                        ></div>

                        <!-- Icon and text -->
                        <Trash2
                          class="h-4 w-4 relative z-10 group-hover:text-white transition-colors duration-300"
                        />
                        <span
                          class="font-medium text-sm relative z-10 group-hover:text-white transition-colors duration-300"
                          >Delete</span
                        >

                        <!-- Subtle glow effect on hover -->
                        <div
                          class="absolute inset-0 rounded-lg opacity-0 group-hover:opacity-100 transition-opacity duration-300 bg-red-400/20 blur-sm"
                        ></div>
                      </button>
                    </div>
                  </div>
                </div>
                <div
                  v-if="paginatedProducts.length === 0"
                  class="col-span-full py-10 text-center text-gray-500"
                >
                  <div class="flex flex-col items-center justify-center">
                    <PackageX class="h-12 w-12 text-gray-300 mb-2" />
                    No products found matching your criteria
                  </div>
                </div>
              </div>
            </div>
          </div>
          <!-- Add New Product Tab (Empty as requested) -->
          <div
            v-if="activeTab === 'add-product'"
            class="text-center text-gray-500"
          >
            <CommonAddProductTab />
          </div>
        </div>
      </div>
    </UContainer>

    <!-- Order Details Modal -->
    <div
      v-if="showOrderDetailsModal"
      class="fixed inset-0 top-14 z-10 overflow-y-auto md:top-0"
      aria-labelledby="modal-title"
      role="dialog"
      aria-modal="true"
    >
      <div
        class="flex items-end justify-center min-h-screen pt-4 px-4 pb-20 text-center sm:block sm:p-0"
      >
        <div
          class="fixed inset-0 bg-gray-500 bg-opacity-75 transition-opacity backdrop-blur-sm"
          aria-hidden="true"
          @click="showOrderDetailsModal = false"
        ></div>
        <span
          class="hidden sm:inline-block sm:align-middle sm:h-screen"
          aria-hidden="true"
          >&#8203;</span
        >
        <div
          class="inline-block align-bottom bg-white rounded-xl text-left overflow-hidden shadow-2xl transform transition-all sm:my-24 sm:align-middle sm:max-w-3xl sm:w-full animate-slide-up"
        >
          <div
            class="absolute top-0 left-0 right-0 h-1 bg-gradient-to-r from-indigo-400 via-purple-500 to-indigo-600"
          ></div>
          <div
            class="px-6 py-5 border-b border-gray-200 flex justify-between items-center"
          >
            <h3
              class="text-xl font-semibold text-gray-900 flex items-center"
              id="modal-title"
            >
              <ShoppingBag class="h-5 w-5 mr-2 text-indigo-600" />
              Order #{{ selectedOrder?.id }}
            </h3>
            <div class="flex items-center space-x-2">
              <button
                @click="printOrder(selectedOrder)"
                class="text-gray-500 hover:text-gray-700 transition-colors duration-150"
                title="Print Order"
              >
                <Printer class="h-5 w-5" />
              </button>
              <button
                @click="showOrderDetailsModal = false"
                class="text-gray-400 hover:text-gray-500 transition-colors duration-150"
              >
                <X class="h-6 w-6" />
              </button>
            </div>
          </div>
          <div class="px-6 py-4">
            <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
              <div>
                <h4
                  class="text-sm font-medium text-gray-500 uppercase tracking-wider mb-3 flex items-center"
                >
                  <FileText class="h-4 w-4 mr-1 text-indigo-500" />
                  Order Information
                </h4>
                <div class="bg-gray-50 rounded-lg p-4">
                  <div class="grid grid-cols-2 gap-4 text-sm">
                    <div>
                      <p class="text-gray-500">Date</p>
                      <p class="font-medium">{{ selectedOrder?.date }}</p>
                      <p class="text-xs text-gray-500">
                        {{
                          selectedOrder
                            ? getRelativeTime(selectedOrder.timestamp)
                            : ""
                        }}
                      </p>
                    </div>
                    <div>
                      <p class="text-gray-500">Status</p>
                      <div class="flex items-center mt-1">
                        <select
                          v-model="editingOrderStatus"
                          class="block w-full pl-2 pr-8 py-1 text-sm border-gray-300 focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 rounded-md"
                        >
                          <option value="pending">Pending</option>
                          <option value="processing">Processing</option>
                          <option value="shipped">Shipped</option>
                          <option value="delivered">Delivered</option>
                          <option value="cancelled">Cancelled</option>
                        </select>
                      </div>
                    </div>
                    <div>
                      <p class="text-gray-500">Payment Method</p>
                      <p class="font-medium">
                        {{ selectedOrder?.paymentMethod }}
                      </p>
                    </div>
                    <div>
                      <p class="text-gray-500">Payment Status</p>
                      <p class="font-medium">
                        {{ selectedOrder?.paymentStatus }}
                      </p>
                    </div>
                  </div>
                </div>
              </div>
              <div>
                <h4
                  class="text-sm font-medium text-gray-500 uppercase tracking-wider mb-3 flex items-center justify-between"
                >
                  <div class="flex items-center">
                    <User class="h-4 w-4 mr-1 text-indigo-500" />
                    Customer Information
                  </div>
                  <button
                    @click="editCustomerInfo = !editCustomerInfo"
                    class="text-xs text-indigo-600 hover:text-indigo-800 flex items-center"
                  >
                    <Edit2 class="h-3 w-3 mr-1" />
                    {{ editCustomerInfo ? "Cancel" : "Edit" }}
                  </button>
                </h4>
                <div class="bg-gray-50 rounded-lg p-4">
                  <div
                    v-if="!editCustomerInfo"
                    class="grid grid-cols-2 gap-4 text-sm"
                  >
                    <div>
                      <p class="text-gray-500">Name</p>
                      <p class="font-medium">{{ selectedOrder?.customer }}</p>
                    </div>
                    <div>
                      <p class="text-gray-500">Email</p>
                      <p class="font-medium">{{ selectedOrder?.email }}</p>
                    </div>
                    <div>
                      <p class="text-gray-500">Phone</p>
                      <p class="font-medium">{{ selectedOrder?.phone }}</p>
                    </div>
                    <div>
                      <p class="text-gray-500">Address</p>
                      <p class="font-medium">{{ selectedOrder?.address }}</p>
                    </div>
                  </div>
                  <div v-else class="space-y-3">
                    <div>
                      <label
                        class="block text-xs font-medium text-gray-500 mb-1"
                        >Name</label
                      >
                      <input
                        type="text"
                        v-model="editingCustomer.customer"
                        class="block w-full border-gray-300 rounded-md shadow-sm focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm"
                      />
                    </div>
                    <div>
                      <label
                        class="block text-xs font-medium text-gray-500 mb-1"
                        >Email</label
                      >
                      <input
                        type="email"
                        v-model="editingCustomer.email"
                        class="block w-full border-gray-300 rounded-md shadow-sm focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm"
                      />
                    </div>
                    <div>
                      <label
                        class="block text-xs font-medium text-gray-500 mb-1"
                        >Phone</label
                      >
                      <input
                        type="tel"
                        v-model="editingCustomer.phone"
                        class="block w-full border-gray-300 rounded-md shadow-sm focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm"
                      />
                    </div>
                    <div>
                      <label
                        class="block text-xs font-medium text-gray-500 mb-1"
                        >Address</label
                      >
                      <textarea
                        v-model="editingCustomer.address"
                        rows="2"
                        class="block w-full border-gray-300 rounded-md shadow-sm focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm"
                      ></textarea>
                    </div>
                    <div class="flex justify-end">
                      <button
                        @click="saveCustomerChanges"
                        class="inline-flex items-center px-3 py-1.5 border border-transparent text-xs font-medium rounded-md shadow-sm text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
                        :disabled="isProcessing"
                      >
                        <span v-if="!isProcessing">Save Changes</span>
                        <span v-else class="flex items-center">
                          <Loader2 class="h-3 w-3 mr-1.5 animate-spin" />
                          Saving...
                        </span>
                      </button>
                    </div>
                  </div>
                </div>
              </div>
            </div>

            <div class="mt-6">
              <h4
                class="text-sm font-medium text-gray-500 uppercase tracking-wider mb-3 flex items-center justify-between"
              >
                <div class="flex items-center">
                  <ShoppingCart class="h-4 w-4 mr-1 text-indigo-500" />
                  Order Items
                </div>
                <button
                  @click="editOrderItems = !editOrderItems"
                  class="text-xs text-indigo-600 hover:text-indigo-800 flex items-center"
                >
                  <Edit2 class="h-3 w-3 mr-1" />
                  {{ editOrderItems ? "Cancel" : "Edit Items" }}
                </button>
              </h4>

              <!-- Desktop view for order items -->
              <div
                class="hidden md:block bg-white border border-gray-200 rounded-lg overflow-hidden"
              >
                <table class="min-w-full divide-y divide-gray-200">
                  <thead class="bg-gray-50">
                    <tr>
                      <th
                        scope="col"
                        class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider"
                      >
                        Product
                      </th>
                      <th
                        scope="col"
                        class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider"
                      >
                        Price
                      </th>
                      <th
                        scope="col"
                        class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider"
                      >
                        Quantity
                      </th>
                      <th
                        scope="col"
                        class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider"
                      >
                        Total
                      </th>
                      <th
                        v-if="editOrderItems"
                        scope="col"
                        class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider"
                      >
                        Actions
                      </th>
                    </tr>
                  </thead>
                  <tbody class="bg-white divide-y divide-gray-200">
                    <tr
                      v-for="(item, index) in editingOrderItems"
                      :key="index"
                      class="hover:bg-gray-50"
                    >
                      <td class="px-6 py-4 whitespace-nowrap">
                        <div class="flex items-center">
                          <div class="flex-shrink-0 h-10 w-10">
                            <img
                              v-if="
                                item?.product_details?.image_details?.length
                              "
                              class="h-10 w-10 rounded-md object-cover"
                              :src="
                                item?.product_details?.image_details[0].image
                              "
                              alt=""
                            />
                          </div>
                          <div class="ml-4">
                            <div class="text-sm font-medium text-gray-900">
                              {{ item.name }}
                            </div>
                          </div>
                        </div>
                      </td>
                      <td class="px-6 py-4 whitespace-nowrap">
                        <div
                          v-if="!editOrderItems"
                          class="text-sm text-gray-900"
                        >
                          ৳{{ item.price }}
                        </div>
                        <input
                          v-else
                          type="number"
                          v-model.number="item.price"
                          min="0"
                          step="0.01"
                          class="block w-24 border-gray-300 rounded-md shadow-sm focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm"
                        />
                      </td>
                      <td class="px-6 py-4 whitespace-nowrap">
                        <div
                          v-if="!editOrderItems"
                          class="text-sm text-gray-900"
                        >
                          {{ item.quantity }}
                        </div>
                        <div v-else class="flex items-center">
                          <button
                            @click="decrementQuantity(index)"
                            class="p-1 rounded-md bg-gray-100 hover:bg-gray-200"
                            :disabled="item.quantity <= 1"
                          >
                            <Minus class="h-3 w-3 text-gray-600" />
                          </button>
                          <input
                            type="number"
                            v-model.number="item.quantity"
                            min="1"
                            class="mx-1 block w-16 border-gray-300 rounded-md shadow-sm focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm text-center"
                          />
                          <button
                            @click="incrementQuantity(index)"
                            class="p-1 rounded-md bg-gray-100 hover:bg-gray-200"
                          >
                            <Plus class="h-3 w-3 text-gray-600" />
                          </button>
                        </div>
                      </td>
                      <td class="px-6 py-4 whitespace-nowrap">
                        <div class="text-sm font-medium text-gray-900">
                          ৳{{ item.price * item.quantity }}
                        </div>
                      </td>
                      <td
                        v-if="editOrderItems"
                        class="px-6 py-4 whitespace-nowrap"
                      >
                        <button
                          @click="removeOrderItem(index)"
                          class="text-red-600 hover:text-red-900 transition-colors duration-150"
                        >
                          <Trash2 class="h-4 w-4" />
                        </button>
                      </td>
                    </tr>
                    <!-- <tr v-if="editOrderItems">
                      <td colspan="5" class="px-6 py-4">
                        <button
                          @click="showAddItemModal = true"
                          class="inline-flex items-center px-3 py-1.5 border border-gray-300 shadow-sm text-xs font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
                        >
                          <Plus class="h-3 w-3 mr-1.5" />
                          Add Item
                        </button>
                      </td>
                    </tr> -->
                  </tbody>
                </table>
              </div>

              <!-- Mobile view for order items -->
              <div class="md:hidden space-y-4">
                <div
                  v-for="(item, index) in editingOrderItems"
                  :key="index"
                  class="bg-white border border-gray-200 rounded-lg p-4"
                >
                  <div class="flex items-start space-x-3">
                    <img
                      class="h-16 w-16 rounded-md object-cover"
                      :src="item.image"
                      alt=""
                    />
                    <div class="flex-1">
                      <h5 class="font-medium text-gray-900">{{ item.name }}</h5>
                      <div class="mt-2 grid grid-cols-2 gap-2 text-sm">
                        <div>
                          <span class="text-gray-500">Price:</span>
                          <span v-if="!editOrderItems" class="font-medium"
                            >৳{{ item.price }}</span
                          >
                          <input
                            v-else
                            type="number"
                            v-model.number="item.price"
                            min="0"
                            step="0.01"
                            class="mt-1 block w-full border-gray-300 rounded-md shadow-sm focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm"
                          />
                        </div>
                        <div>
                          <span class="text-gray-500">Quantity:</span>
                          <span v-if="!editOrderItems" class="font-medium">{{
                            item.quantity
                          }}</span>
                          <div v-else class="flex items-center mt-1">
                            <button
                              @click="decrementQuantity(index)"
                              class="p-1 rounded-md bg-gray-100 hover:bg-gray-200"
                              :disabled="item.quantity <= 1"
                            >
                              <Minus class="h-3 w-3 text-gray-600" />
                            </button>
                            <input
                              type="number"
                              v-model.number="item.quantity"
                              min="1"
                              class="mx-1 block w-12 border-gray-300 rounded-md shadow-sm focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm text-center"
                            />
                            <button
                              @click="incrementQuantity(index)"
                              class="p-1 rounded-md bg-gray-100 hover:bg-gray-200"
                            >
                              <Plus class="h-3 w-3 text-gray-600" />
                            </button>
                          </div>
                        </div>
                        <div class="col-span-2">
                          <span class="text-gray-500">Total:</span>
                          <span class="font-medium text-indigo-600"
                            >৳{{ item.price * item.quantity }}</span
                          >
                          <button
                            v-if="editOrderItems"
                            @click="removeOrderItem(index)"
                            class="ml-2 text-red-600 hover:text-red-900 transition-colors duration-150"
                          >
                            <Trash2 class="h-4 w-4" />
                          </button>
                        </div>
                      </div>
                    </div>
                  </div>
                </div>
                <button
                  v-if="editOrderItems"
                  @click="showAddItemModal = true"
                  class="inline-flex items-center px-3 py-1.5 border border-gray-300 shadow-sm text-xs font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
                >
                  <Plus class="h-3 w-3 mr-1.5" />
                  Add Item
                </button>
              </div>
            </div>

            <div class="mt-6 bg-gray-50 rounded-lg p-4">
              <div class="flex justify-between items-center mb-2">
                <span class="text-gray-600">Subtotal</span>
                <span class="font-medium">৳{{ calculateSubtotal() }}</span>
              </div>
              <div class="flex justify-between items-center mb-2">
                <span class="text-gray-600">Delivery Fee</span>
                <div v-if="!editOrderItems">
                  <span class="font-medium"
                    >৳{{ selectedOrder?.deliveryFee }}</span
                  >
                </div>
                <div v-else class="flex items-center">
                  <input
                    type="number"
                    v-model.number="editingDeliveryFee"
                    min="0"
                    class="block w-24 border-gray-300 rounded-md shadow-sm focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm"
                  />
                </div>
              </div>
              <div
                class="flex justify-between items-center pt-2 border-t border-gray-200 mt-2"
              >
                <span class="text-gray-800 font-medium">Total</span>
                <span class="text-lg font-bold text-indigo-600"
                  >৳{{ calculateTotal() }}</span
                >
              </div>
            </div>
          </div>
          <div class="bg-gray-50 px-6 py-4 flex flex-wrap justify-end gap-3">
            <button
              v-if="editOrderItems"
              @click="saveOrderItemChanges"
              class="inline-flex justify-center items-center rounded-md border border-transparent shadow-sm px-4 py-2 bg-indigo-600 text-base font-medium text-white hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500 sm:text-sm transition-all duration-200"
              :disabled="isProcessing"
            >
              <span v-if="!isProcessing" class="flex items-center">
                <Save class="h-4 w-4 mr-1.5" />
                Save Items
              </span>
              <span v-else class="flex items-center">
                <Loader2 class="h-4 w-4 mr-1.5 animate-spin" />
                Saving...
              </span>
            </button>
            <button
              @click="cancelOrder"
              v-if="
                selectedOrder?.status !== 'cancelled' &&
                selectedOrder?.status !== 'delivered'
              "
              class="inline-flex justify-center items-center rounded-md border border-red-300 shadow-sm px-4 py-2 bg-white text-base font-medium text-red-700 hover:bg-red-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-red-500 sm:text-sm transition-all duration-200"
              :disabled="isProcessing"
            >
              <XCircle class="h-4 w-4 mr-1.5" />
              <span v-if="!isProcessing">Cancel Order</span>
              <span v-else class="flex items-center">
                <Loader2 class="h-4 w-4 mr-1.5 animate-spin" />
                Processing...
              </span>
            </button>
            <button
              @click="updateOrderStatus(selectedOrder.id)"
              class="inline-flex justify-center items-center rounded-md border border-transparent shadow-sm px-4 py-2 bg-gradient-to-r from-indigo-500 to-indigo-600 text-base font-medium text-white hover:from-indigo-600 hover:to-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500 sm:text-sm transition-all duration-200 transform hover:-translate-y-0.5"
              :disabled="isProcessing"
            >
              <span v-if="!isProcessing" class="flex items-center">
                <RefreshCw class="h-4 w-4 mr-1.5" />
                Update Status
              </span>
              <span v-else class="flex items-center">
                <Loader2 class="h-4 w-4 mr-1.5 animate-spin" />
                Processing...
              </span>
            </button>
            <button
              @click="showOrderDetailsModal = false"
              class="inline-flex justify-center items-center rounded-md border border-gray-300 shadow-sm px-4 py-2 bg-white text-base font-medium text-gray-700 hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500 sm:text-sm transition-colors duration-200"
            >
              <X class="h-4 w-4 mr-1.5" />
              Close
            </button>
          </div>
        </div>
      </div>
    </div>

    <!-- Add Item Modal -->
    <div
      v-if="showAddItemModal"
      class="fixed inset-0 z-20 overflow-y-auto"
      aria-labelledby="modal-title"
      role="dialog"
      aria-modal="true"
    >
      <div
        class="flex items-end justify-center min-h-screen pt-4 px-4 pb-20 text-center sm:block sm:p-0"
      >
        <div
          class="fixed inset-0 bg-gray-500 bg-opacity-75 transition-opacity backdrop-blur-sm"
          aria-hidden="true"
          @click="showAddItemModal = false"
        ></div>
        <span
          class="hidden sm:inline-block sm:align-middle sm:h-screen"
          aria-hidden="true"
          >&#8203;</span
        >
        <div
          class="inline-block align-bottom bg-white rounded-xl text-left overflow-hidden shadow-2xl transform transition-all sm:my-8 sm:align-middle sm:max-w-lg sm:w-full animate-slide-up"
        >
          <div
            class="absolute top-0 left-0 right-0 h-1 bg-gradient-to-r from-indigo-400 via-purple-500 to-indigo-600"
          ></div>
          <div
            class="px-6 py-5 border-b border-gray-200 flex justify-between items-center"
          >
            <h3
              class="text-xl font-semibold text-gray-900 flex items-center"
              id="modal-title"
            >
              <ShoppingCart class="h-5 w-5 mr-2 text-indigo-600" />
              Add Product to Order
            </h3>
            <button
              @click="showAddItemModal = false"
              class="text-gray-400 hover:text-gray-500 transition-colors duration-150"
            >
              <X class="h-6 w-6" />
            </button>
          </div>
          <div class="px-6 py-4">
            <div class="mb-4">
              <label
                for="product-select"
                class="block text-sm font-medium text-gray-700 mb-1"
                >Select Product</label
              >
              <select
                id="product-select"
                v-model="selectedProductToAdd"
                class="block w-full border-gray-300 rounded-md shadow-sm focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm"
              >
                <option value="">Select a product</option>
                <option
                  v-for="product in activeProducts"
                  :key="product.id"
                  :value="product"
                >
                  {{ product.name }} - ৳{{ product.price }}
                </option>
              </select>
            </div>

            <div
              v-if="selectedProductToAdd"
              class="bg-gray-50 rounded-lg p-4 mb-4"
            >
              <div class="flex items-start space-x-3">
                <img
                  :src="selectedProductToAdd.image"
                  :alt="selectedProductToAdd.name"
                  class="h-16 w-16 rounded-md object-cover"
                />
                <div class="flex-1">
                  <h5 class="font-medium text-gray-900">
                    {{ selectedProductToAdd.name }}
                  </h5>
                  <p class="text-sm text-gray-500 mt-1">
                    {{ selectedProductToAdd.description }}
                  </p>
                  <div class="mt-2 grid grid-cols-2 gap-2 text-sm">
                    <div>
                      <span class="text-gray-500">Price:</span>
                      <span class="font-medium"
                        >৳{{ selectedProductToAdd.price }}</span
                      >
                    </div>
                    <div>
                      <span class="text-gray-500">Available:</span>
                      <span class="font-medium">{{
                        selectedProductToAdd.stock
                      }}</span>
                    </div>
                  </div>
                </div>
              </div>
            </div>

            <div v-if="selectedProductToAdd">
              <label
                for="quantity-input"
                class="block text-sm font-medium text-gray-700 mb-1"
                >Quantity</label
              >
              <div class="flex items-center">
                <button
                  @click="newItemQuantity > 1 ? newItemQuantity-- : null"
                  class="p-2 rounded-md bg-gray-100 hover:bg-gray-200"
                  :disabled="newItemQuantity <= 1"
                >
                  <Minus class="h-4 w-4 text-gray-600" />
                </button>
                <input
                  id="quantity-input"
                  type="number"
                  v-model.number="newItemQuantity"
                  min="1"
                  :max="selectedProductToAdd.stock"
                  class="mx-2 block w-20 border-gray-300 rounded-md shadow-sm focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm text-center"
                />
                <button
                  @click="
                    newItemQuantity < selectedProductToAdd.stock
                      ? newItemQuantity++
                      : null
                  "
                  class="p-2 rounded-md bg-gray-100 hover:bg-gray-200"
                  :disabled="newItemQuantity >= selectedProductToAdd.stock"
                >
                  <Plus class="h-4 w-4 text-gray-600" />
                </button>
              </div>
            </div>
          </div>
          <div class="bg-gray-50 px-6 py-4 flex justify-end space-x-3">
            <button
              @click="addItemToOrder"
              class="inline-flex justify-center items-center rounded-md border border-transparent shadow-sm px-4 py-2 bg-indigo-600 text-base font-medium text-white hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500 sm:text-sm transition-all duration-200"
              :disabled="!selectedProductToAdd || newItemQuantity < 1"
            >
              <Plus class="h-4 w-4 mr-1.5" />
              Add to Order
            </button>
            <button
              @click="showAddItemModal = false"
              class="inline-flex justify-center items-center rounded-md border border-gray-300 shadow-sm px-4 py-2 bg-white text-base font-medium text-gray-700 hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500 sm:text-sm transition-colors duration-200"
            >
              <X class="h-4 w-4 mr-1.5" />
              Cancel
            </button>
          </div>
        </div>
      </div>
    </div>

    <!-- Edit Product Modal -->
    <div
      v-if="showEditProductModal"
      class="fixed inset-0 z-10 overflow-y-auto"
      aria-labelledby="modal-title"
      role="dialog"
      aria-modal="true"
    >
      <div
        class="flex items-end justify-center min-h-screen pt-4 px-4 pb-20 text-center sm:block sm:p-0"
      >
        <div
          class="fixed inset-0 bg-gray-500 bg-opacity-75 transition-opacity backdrop-blur-sm"
          aria-hidden="true"
          @click="showEditProductModal = false"
        ></div>
        <span
          class="hidden sm:inline-block sm:align-middle sm:h-screen"
          aria-hidden="true"
          >&#8203;</span
        >
        <div
          class="inline-block align-bottom bg-white rounded-xl text-left overflow-hidden shadow-2xl transform transition-all sm:my-8 sm:align-middle sm:max-w-lg sm:w-full animate-slide-up"
        >
          <div
            class="absolute top-0 left-0 right-0 h-1 bg-gradient-to-r from-indigo-400 via-purple-500 to-indigo-600"
          ></div>
          <div
            class="px-6 py-5 border-b border-gray-200 flex justify-between items-center"
          >
            <h3
              class="text-xl font-semibold text-gray-900 flex items-center"
              id="modal-title"
            >
              <Edit2 class="h-5 w-5 mr-2 text-indigo-600" />
              Edit Product
            </h3>
            <button
              @click="showEditProductModal = false"
              class="text-gray-400 hover:text-gray-500 transition-colors duration-150"
            >
              <X class="h-6 w-6" />
            </button>
          </div>
          <div class="px-6 py-4">
            <form @submit.prevent="saveProductChanges">
              <div class="space-y-4">
                <div>
                  <label
                    for="product-name"
                    class="block text-sm font-medium text-gray-700"
                    >Product Name</label
                  >
                  <input
                    type="text"
                    id="product-name"
                    v-model="editingProduct.name"
                    class="mt-1 block w-full border-gray-300 rounded-md shadow-sm focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm"
                    required
                  />
                </div>
                <div>
                  <label
                    for="product-description"
                    class="block text-sm font-medium text-gray-700"
                    >Description</label
                  >
                  <textarea
                    id="product-description"
                    v-model="editingProduct.description"
                    rows="3"
                    class="mt-1 block w-full border-gray-300 rounded-md shadow-sm focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm"
                  ></textarea>
                </div>
                <div class="grid grid-cols-2 gap-4">
                  <div>
                    <label
                      for="product-price"
                      class="block text-sm font-medium text-gray-700"
                      >Price (৳)</label
                    >
                    <input
                      type="number"
                      id="product-price"
                      v-model.number="editingProduct.price"
                      min="0"
                      step="0.01"
                      class="mt-1 block w-full border-gray-300 rounded-md shadow-sm focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm"
                      required
                    />
                  </div>
                  <div>
                    <label
                      for="product-stock"
                      class="block text-sm font-medium text-gray-700"
                      >Stock</label
                    >
                    <input
                      type="number"
                      id="product-stock"
                      v-model.number="editingProduct.stock"
                      min="0"
                      class="mt-1 block w-full border-gray-300 rounded-md shadow-sm focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm"
                      required
                    />
                  </div>
                </div>
                <div>
                  <label
                    for="product-status"
                    class="block text-sm font-medium text-gray-700"
                    >Status</label
                  >
                  <select
                    id="product-status"
                    v-model="editingProduct.status"
                    class="mt-1 block w-full border-gray-300 rounded-md shadow-sm focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm"
                  >
                    <option value="active">Active</option>
                    <option value="inactive">Inactive</option>
                    <option value="out-of-stock">Out of Stock</option>
                  </select>
                </div>
                <div>
                  <label
                    for="product-image"
                    class="block text-sm font-medium text-gray-700"
                    >Image URL</label
                  >
                  <input
                    type="text"
                    id="product-image"
                    v-model="editingProduct.image"
                    class="mt-1 block w-full border-gray-300 rounded-md shadow-sm focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm"
                  />
                  <div class="mt-2">
                    <img
                      :src="editingProduct.image"
                      alt="Product preview"
                      class="h-32 w-32 object-cover rounded-md border border-gray-200"
                    />
                  </div>
                </div>
              </div>
            </form>
          </div>
          <div class="bg-gray-50 px-6 py-4 flex justify-end space-x-3">
            <button
              @click="saveProductChanges"
              class="inline-flex justify-center items-center rounded-md border border-transparent shadow-sm px-4 py-2 bg-gradient-to-r from-indigo-500 to-indigo-600 text-base font-medium text-white hover:from-indigo-600 hover:to-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500 sm:text-sm transition-all duration-200 transform hover:-translate-y-0.5"
              :disabled="isProcessing"
            >
              <span v-if="!isProcessing" class="flex items-center">
                <Save class="h-4 w-4 mr-1.5" />
                Save Changes
              </span>
              <span v-else class="flex items-center">
                <Loader2 class="h-4 w-4 mr-1.5 animate-spin" />
                Saving...
              </span>
            </button>
            <button
              @click="showEditProductModal = false"
              class="inline-flex justify-center items-center rounded-md border border-gray-300 shadow-sm px-4 py-2 bg-white text-base font-medium text-gray-700 hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500 sm:text-sm transition-colors duration-200"
            >
              <X class="h-4 w-4 mr-1.5" />
              Cancel
            </button>
          </div>
        </div>
      </div>
    </div>

    <!-- Delete Product Confirmation Modal -->
    <div
      v-if="showDeleteConfirmModal"
      class="fixed inset-0 z-10 overflow-y-auto"
      aria-labelledby="modal-title"
      role="dialog"
      aria-modal="true"
    >
      <div
        class="flex items-end justify-center min-h-screen pt-4 px-4 pb-20 text-center sm:block sm:p-0"
      >
        <div
          class="fixed inset-0 bg-gray-500 bg-opacity-75 transition-opacity backdrop-blur-sm"
          aria-hidden="true"
          @click="showDeleteConfirmModal = false"
        ></div>
        <span
          class="hidden sm:inline-block sm:align-middle sm:h-screen"
          aria-hidden="true"
          >&#8203;</span
        >
        <div
          class="inline-block align-bottom bg-white rounded-xl text-left overflow-hidden shadow-2xl transform transition-all sm:my-8 sm:align-middle sm:max-w-lg sm:w-full animate-slide-up"
        >
          <div
            class="absolute top-0 left-0 right-0 h-1 bg-gradient-to-r from-red-400 to-red-600"
          ></div>
          <div
            class="px-6 py-5 border-b border-gray-200 flex justify-between items-center"
          >
            <h3
              class="text-xl font-semibold text-gray-900 flex items-center"
              id="modal-title"
            >
              <AlertTriangle class="h-5 w-5 mr-2 text-red-500" />
              Confirm Deletion
            </h3>
            <button
              @click="showDeleteConfirmModal = false"
              class="text-gray-400 hover:text-gray-500 transition-colors duration-150"
            >
              <X class="h-6 w-6" />
            </button>
          </div>
          <div class="px-6 py-4">
            <p class="text-gray-700">
              Are you sure you want to delete the product
              <span class="font-medium">{{ selectedProduct?.name }}</span
              >? This action cannot be undone.
            </p>
          </div>
          <div class="bg-gray-50 px-6 py-4 flex justify-end space-x-3">
            <button
              @click="deleteProduct"
              class="inline-flex justify-center items-center rounded-md border border-transparent shadow-sm px-4 py-2 bg-gradient-to-r from-red-500 to-red-600 text-base font-medium text-white hover:from-red-600 hover:to-red-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-red-500 sm:text-sm transition-all duration-200 transform hover:-translate-y-0.5"
              :disabled="isProcessing"
            >
              <span v-if="!isProcessing" class="flex items-center">
                <Trash2 class="h-4 w-4 mr-1.5" />
                Delete
              </span>
              <span v-else class="flex items-center">
                <Loader2 class="h-4 w-4 mr-1.5 animate-spin" />
                Deleting...
              </span>
            </button>
            <button
              @click="showDeleteConfirmModal = false"
              class="inline-flex justify-center items-center rounded-md border border-gray-300 shadow-sm px-4 py-2 bg-white text-base font-medium text-gray-700 hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500 sm:text-sm transition-colors duration-200"
            >
              <X class="h-4 w-4 mr-1.5" />
              Cancel
            </button>
          </div>
        </div>
      </div>
    </div>

    <!-- Cancel Order Confirmation Modal -->
    <div
      v-if="showCancelOrderModal"
      class="fixed inset-0 z-10 overflow-y-auto"
      aria-labelledby="modal-title"
      role="dialog"
      aria-modal="true"
    >
      <div
        class="flex items-end justify-center min-h-screen pt-4 px-4 pb-20 text-center sm:block sm:p-0"
      >
        <div
          class="fixed inset-0 bg-gray-500 bg-opacity-75 transition-opacity backdrop-blur-sm"
          aria-hidden="true"
          @click="showCancelOrderModal = false"
        ></div>
        <span
          class="hidden sm:inline-block sm:align-middle sm:h-screen"
          aria-hidden="true"
          >&#8203;</span
        >
        <div
          class="inline-block align-bottom bg-white rounded-xl text-left overflow-hidden shadow-2xl transform transition-all sm:my-8 sm:align-middle sm:max-w-lg sm:w-full animate-slide-up"
        >
          <div
            class="absolute top-0 left-0 right-0 h-1 bg-gradient-to-r from-red-400 to-red-600"
          ></div>
          <div
            class="px-6 py-5 border-b border-gray-200 flex justify-between items-center"
          >
            <h3
              class="text-xl font-semibold text-gray-900 flex items-center"
              id="modal-title"
            >
              <AlertTriangle class="h-5 w-5 mr-2 text-red-500" />
              Confirm Order Cancellation
            </h3>
            <button
              @click="showCancelOrderModal = false"
              class="text-gray-400 hover:text-gray-500 transition-colors duration-150"
            >
              <X class="h-6 w-6" />
            </button>
          </div>
          <div class="px-6 py-4">
            <p class="text-gray-700 mb-4">
              Are you sure you want to cancel order
              <span class="font-medium">#{{ selectedOrder?.id }}</span
              >?
            </p>
            <div
              v-if="
                selectedOrder?.paymentMethod === 'Credit Card' ||
                selectedOrder?.paymentMethod === 'PayPal' ||
                selectedOrder?.paymentMethod === 'Account Funds'
              "
              class="bg-green-50 border border-green-100 rounded-lg p-4 flex items-start"
            >
              <CircleCheck
                class="h-5 w-5 text-green-500 mr-2 mt-0.5 flex-shrink-0"
              />
              <p class="text-sm text-green-800">
                A refund of
                <span class="font-medium">৳{{ selectedOrder?.total }}</span>
                will be processed to the customer's account.
              </p>
            </div>
          </div>
          <div class="bg-gray-50 px-6 py-4 flex justify-end space-x-3">
            <button
              @click="confirmCancelOrder"
              class="inline-flex justify-center items-center rounded-md border border-transparent shadow-sm px-4 py-2 bg-gradient-to-r from-red-500 to-red-600 text-base font-medium text-white hover:from-red-600 hover:to-red-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-red-500 sm:text-sm transition-all duration-200 transform hover:-translate-y-0.5"
              :disabled="isProcessing"
            >
              <span v-if="!isProcessing" class="flex items-center">
                <XCircle class="h-4 w-4 mr-1.5" />
                Cancel Order
              </span>
              <span v-else class="flex items-center">
                <Loader2 class="h-4 w-4 mr-1.5 animate-spin" />
                Processing...
              </span>
            </button>
            <button
              @click="showCancelOrderModal = false"
              class="inline-flex justify-center items-center rounded-md border border-gray-300 shadow-sm px-4 py-2 bg-white text-base font-medium text-gray-700 hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500 sm:text-sm transition-colors duration-200"
            >
              <X class="h-4 w-4 mr-1.5" />
              Go Back
            </button>
          </div>
        </div>
      </div>
    </div>

    <!-- Toast Notifications -->
    <div class="fixed bottom-0 right-0 p-6 z-50">
      <transition-group name="toast">
        <div
          v-for="toast in toasts"
          :key="toast.id"
          class="mb-3 p-4 rounded-lg shadow-lg flex items-start max-w-md transform transition-all duration-300"
          :class="[
            toast.type === 'success'
              ? 'bg-green-50 border-l-4 border-green-500 text-green-800'
              : toast.type === 'error'
              ? 'bg-red-50 border-l-4 border-red-500 text-red-800'
              : 'bg-indigo-50 border-l-4 border-indigo-500 text-indigo-800',
          ]"
        >
          <div class="flex-shrink-0 mr-3">
            <component
              :is="
                toast.type === 'success'
                  ? 'CheckCircle'
                  : toast.type === 'error'
                  ? 'AlertCircle'
                  : 'Info'
              "
              class="h-5 w-5"
              :class="[
                toast.type === 'success'
                  ? 'text-green-500'
                  : toast.type === 'error'
                  ? 'text-red-500'
                  : 'text-indigo-500',
              ]"
            />
          </div>
          <div class="flex-1">
            <p class="font-medium">{{ toast.title }}</p>
            <p class="text-sm mt-1">{{ toast.message }}</p>
          </div>
          <button
            @click="removeToast(toast.id)"
            class="ml-4 text-gray-400 hover:text-gray-600"
          >
            <X class="h-4 w-4" />
          </button>
        </div>
      </transition-group>
    </div>
  </div>
</template>

<script setup>
definePageMeta({
  layout: "dashboard",
});
const { user } = useAuth();
const { get, patch } = useApi();
const { formatDate } = useUtils();
import {
  ShoppingBag,
  ShoppingCart,
  PlusCircle,
  Search,
  ChevronLeft,
  ChevronRight,
  Eye,
  EyeOff,
  Edit2,
  Trash2,
  X,
  Save,
  Package,
  PackageX,
  User,
  FileText,
  RefreshCw,
  AlertTriangle,
  CircleCheck,
  CirclePause,
  CircleX,
  XCircle,
  Loader2,
  CheckCircle,
  AlertCircle,
  Info,
  Clock,
  Loader,
  Printer,
  Plus,
  Minus,
  Crown as CrownIcon,
  Sparkles as SparklesIcon,
} from "lucide-vue-next";
import { jsPDF } from "jspdf";
import "jspdf-autotable";

// Tab state
const activeTab = ref("orders");

// Tabs configuration
const tabs = [
  {
    id: "orders",
    name: "My Orders",
    icon: ShoppingBag,
  },
  {
    id: "products",
    name: "My Products",
    icon: ShoppingCart,
  },
  {
    id: "add-product",
    name: "Add New Product",
    icon: PlusCircle,
  },
];

// UI state
const showOrderDetailsModal = ref(false);
const showEditProductModal = ref(false);
const showDeleteConfirmModal = ref(false);
const showCancelOrderModal = ref(false);
const showAddItemModal = ref(false);
const isProcessing = ref(false);
const editCustomerInfo = ref(false);
const editOrderItems = ref(false);

// Order items editing
const editingOrderItems = ref([]);
const editingDeliveryFee = ref(0);
const selectedProductToAdd = ref(null);
const newItemQuantity = ref(1);

// Filters and search
const orderFilter = ref("all");
const orderSearch = ref("");
const productFilter = ref("all");
const productSearch = ref("");

// Pagination for orders
const itemsPerPage = 5;
const currentPage = ref(1);
const currentProductPage = ref(1);

// Selected items
const selectedOrder = ref(null);
const selectedProduct = ref(null);
const editingProduct = reactive({
  id: "",
  name: "",
  description: "",
  price: 0,
  stock: 0,
  status: "active",
  image: "",
});
const editingOrderStatus = ref("");
const editingCustomer = reactive({
  customer: "",
  email: "",
  phone: "",
  address: "",
});

// Toast notifications
const toasts = ref([]);
let toastId = 0;
// Component state
const mounted = ref(false);

// Sparkles configuration
const sparkles = [
  { class: "left-12 top-6", size: 16, delay: 0 },
  { class: "bottom-12 right-16", size: 12, delay: 0.5 },
  { class: "bottom-24 left-24", size: 20, delay: 1 },
];

// Lifecycle hooks
onMounted(() => {
  mounted.value = true;

  // Randomize sparkle animations
  const interval = setInterval(() => {
    sparkles.forEach((sparkle, index) => {
      sparkle.delay = Math.random() * 2;
    });
  }, 3000);

  // Clean up interval on component unmount
  return () => clearInterval(interval);
});

// Dummy data - Orders with timestamps
const orders = ref([]);
const isOrdersLoading = ref(false);

async function getOrders() {
  isOrdersLoading.value = true;
  try {
    const res = await get("/seller-orders/");
    // Process the data to ensure IDs are strings
    orders.value = res.data.map((order) => ({
      ...order,
      id: Array.isArray(order.id) ? order.id[0] : order.id,
    }));
  } catch (error) {
    console.error("Error fetching orders:", error);
    showToast("error", "Failed to load orders", "Please try again later");
  } finally {
    isOrdersLoading.value = false;
  }
}

// Helper function to format currency amounts
function formatAmount(amount) {
  if (amount === undefined || amount === null) return "0.00";
  return parseFloat(amount).toFixed(2);
}

// Updated computed properties to handle API field structure
const pendingOrders = computed(() => {
  return orders.value.filter((order) => order.order_status === "pending");
});

const processingOrders = computed(() => {
  return orders.value.filter((order) => order.order_status === "processing");
});

const deliveredOrders = computed(() => {
  return orders.value.filter((order) => order.order_status === "delivered");
});

const totalOrdersAmount = computed(() => {
  return orders.value.reduce((total, order) => {
    const orderTotal = parseFloat(order.total || 0);
    return total + orderTotal;
  }, 0);
});

const pendingOrdersAmount = computed(() => {
  return pendingOrders.value.reduce((total, order) => {
    const orderTotal = parseFloat(order.total || 0);
    return total + orderTotal;
  }, 0);
});

const processingOrdersAmount = computed(() => {
  return processingOrders.value.reduce((total, order) => {
    const orderTotal = parseFloat(order.total || 0);
    return total + orderTotal;
  }, 0);
});

const deliveredOrdersAmount = computed(() => {
  return deliveredOrders.value.reduce((total, order) => {
    const orderTotal = parseFloat(order.total || 0);
    return total + orderTotal;
  }, 0);
});

// Add polling for real-time updates (optional)
let orderUpdateInterval;
await getOrders();
onMounted(() => {
  // Initial fetch

  // Set up polling interval (every 2 minutes)
  orderUpdateInterval = setInterval(() => {
    getOrders();
  }, 120000);
});

onBeforeUnmount(() => {
  // Clear interval when component is destroyed
  if (orderUpdateInterval) clearInterval(orderUpdateInterval);
});

// Dummy data - Products
const products = ref([]);

async function getProducts() {
  const res = await get("/my-products/");
  products.value = res.data;
}

await getProducts();

// Product summary computed properties
const activeProducts = computed(() => {
  return products.value.filter((product) => product.status === "active");
});

const inactiveProducts = computed(() => {
  return products.value.filter((product) => product.status === "inactive");
});

const outOfStockProducts = computed(() => {
  return products.value.filter((product) => product.status === "out-of-stock");
});

const totalProductsValue = computed(() => {
  return products.value.reduce(
    (total, product) => total + product.sale_price * product.quantity,
    0
  );
});

const activeProductsValue = computed(() => {
  return activeProducts.value.reduce(
    (total, product) => total + product.sale_price * product.quantity,
    0
  );
});

const inactiveProductsValue = computed(() => {
  return inactiveProducts.value.reduce(
    (total, product) => total + product.sale_price * product.quantity,
    0
  );
});

const outOfStockProductsValue = computed(() => {
  return outOfStockProducts.value.reduce(
    (total, product) => total + product.sale_price * product.quantity,
    0
  );
});

// Computed properties
const filteredOrders = computed(() => {
  let result = orders.value;

  // Apply status filter
  if (orderFilter.value !== "all") {
    result = result.filter((order) => order.status === orderFilter.value);
  }

  // Apply search filter
  if (orderSearch.value) {
    const search = orderSearch.value.toLowerCase();
    result = result.filter(
      (order) =>
        order.id.toLowerCase().includes(search) ||
        order.customer.toLowerCase().includes(search) ||
        order.email.toLowerCase().includes(search)
    );
  }

  return result;
});

const totalPages = computed(() => {
  return Math.ceil(filteredOrders.value.length / itemsPerPage);
});

const paginatedOrders = computed(() => {
  const start = (currentPage.value - 1) * itemsPerPage;
  const end = start + itemsPerPage;
  return filteredOrders.value.slice(start, end);
});

const paginationStart = computed(() => {
  return filteredOrders.value.length === 0
    ? 0
    : (currentPage.value - 1) * itemsPerPage + 1;
});

const paginationEnd = computed(() => {
  return Math.min(
    currentPage.value * itemsPerPage,
    filteredOrders.value.length
  );
});

const displayedPages = computed(() => {
  const pages = [];
  const maxPagesToShow = 5;

  if (totalPages.value <= maxPagesToShow) {
    // Show all pages if there are fewer than maxPagesToShow
    for (let i = 1; i <= totalPages.value; i++) {
      pages.push(i);
    }
  } else {
    // Always show first page
    pages.push(1);

    // Calculate start and end of page range
    let startPage = Math.max(2, currentPage.value - 1);
    let endPage = Math.min(totalPages.value - 1, currentPage.value + 1);

    // Adjust if we're at the beginning or end
    if (currentPage.value <= 2) {
      endPage = 4;
    } else if (currentPage.value >= totalPages.value - 1) {
      startPage = totalPages.value - 3;
    }

    // Add ellipsis if needed
    if (startPage > 2) {
      pages.push("...");
    }

    // Add middle pages
    for (let i = startPage; i <= endPage; i++) {
      pages.push(i);
    }

    // Add ellipsis if needed
    if (endPage < totalPages.value - 1) {
      pages.push("...");
    }

    // Always show last page
    if (totalPages.value > 1) {
      pages.push(totalPages.value);
    }
  }

  return pages;
});

// Product pagination
const filteredProducts = computed(() => {
  let result = products.value;

  // Apply status filter
  if (productFilter.value !== "all") {
    result = result.filter((product) => product.status === productFilter.value);
  }

  // Apply search filter
  if (productSearch.value) {
    const search = productSearch.value.toLowerCase();
    result = result.filter(
      (product) =>
        product.name.toLowerCase().includes(search) ||
        product.description.toLowerCase().includes(search)
    );
  }

  return result;
});

const totalProductPages = computed(() => {
  return Math.ceil(filteredProducts.value.length / itemsPerPage);
});

const paginatedProducts = computed(() => {
  const start = (currentProductPage.value - 1) * itemsPerPage;
  const end = start + itemsPerPage;
  return filteredProducts.value.slice(start, end);
});

// Methods
const getStatusClass = (status) => {
  switch (status) {
    case "pending":
      return "bg-yellow-100 text-yellow-800";
    case "processing":
      return "bg-blue-100 text-blue-800";
    case "shipped":
      return "bg-purple-100 text-purple-800";
    case "delivered":
      return "bg-green-100 text-green-800";
    case "cancelled":
      return "bg-red-100 text-red-800";
    default:
      return "bg-gray-100 text-gray-800";
  }
};

const getRelativeTime = (timestamp) => {
  const now = new Date().getTime();
  const diff = now - timestamp;

  // Convert to seconds
  const seconds = Math.floor(diff / 1000);

  if (seconds < 60) {
    return `${seconds} seconds ago`;
  }

  // Convert to minutes
  const minutes = Math.floor(seconds / 60);

  if (minutes < 60) {
    return `${minutes} minute${minutes > 1 ? "s" : ""} ago`;
  }

  // Convert to hours
  const hours = Math.floor(minutes / 60);

  if (hours < 24) {
    return `${hours} hour${hours > 1 ? "s" : ""} ago`;
  }

  // Convert to days
  const days = Math.floor(hours / 24);

  if (days < 30) {
    return `${days} day${days > 1 ? "s" : ""} ago`;
  }

  // Convert to months
  const months = Math.floor(days / 30);

  if (months < 12) {
    return `${months} month${months > 1 ? "s" : ""} ago`;
  }

  // Convert to years
  const years = Math.floor(months / 12);

  return `${years} year${years > 1 ? "s" : ""} ago`;
};

const viewOrderDetails = (order) => {
  selectedOrder.value = order;
  editingOrderStatus.value = order.status;
  editCustomerInfo.value = false;
  editOrderItems.value = false;

  // Initialize editing customer info
  editingCustomer.customer = order.customer;
  editingCustomer.email = order.email;
  editingCustomer.phone = order.phone;
  editingCustomer.address = order.address;

  // Initialize editing order items
  editingOrderItems.value = JSON.parse(JSON.stringify(order.items));
  editingDeliveryFee.value = order.deliveryFee;

  showOrderDetailsModal.value = true;
};

const saveCustomerChanges = async () => {
  if (isProcessing.value) return;

  isProcessing.value = true;

  try {
    // Simulate API call
    await new Promise((resolve) => setTimeout(resolve, 800));

    if (selectedOrder.value) {
      // Update customer info
      selectedOrder.value.customer = editingCustomer.customer;
      selectedOrder.value.email = editingCustomer.email;
      selectedOrder.value.phone = editingCustomer.phone;
      selectedOrder.value.address = editingCustomer.address;

      // Update the order in the orders array
      const index = orders.value.findIndex(
        (o) => o.id === selectedOrder.value.id
      );
      if (index !== -1) {
        orders.value[index] = { ...selectedOrder.value };
      }

      // Show success toast
      showToast(
        "success",
        "Customer Updated",
        "Customer information has been successfully updated."
      );

      // Exit edit mode
      editCustomerInfo.value = false;
    }
  } catch (error) {
    showToast(
      "error",
      "Update Failed",
      "There was an error updating the customer information."
    );
  } finally {
    isProcessing.value = false;
  }
};

const calculateSubtotal = () => {
  return editingOrderItems.value.reduce(
    (total, item) => total + item.price * item.quantity,
    0
  );
};

const calculateTotal = () => {
  return calculateSubtotal() + editingDeliveryFee.value;
};

const incrementQuantity = (index) => {
  editingOrderItems.value[index].quantity++;
};

const decrementQuantity = (index) => {
  if (editingOrderItems.value[index].quantity > 1) {
    editingOrderItems.value[index].quantity--;
  }
};

const removeOrderItem = (index) => {
  editingOrderItems.value.splice(index, 1);
};

const addItemToOrder = () => {
  if (!selectedProductToAdd.value || newItemQuantity.value < 1) return;

  // Check if the product is already in the order
  const existingItemIndex = editingOrderItems.value.findIndex(
    (item) => item.name === selectedProductToAdd.value.name
  );

  if (existingItemIndex !== -1) {
    // Update quantity if product already exists
    editingOrderItems.value[existingItemIndex].quantity +=
      newItemQuantity.value;
  } else {
    // Add new item
    editingOrderItems.value.push({
      name: selectedProductToAdd.value.name,
      price: selectedProductToAdd.value.price,
      quantity: newItemQuantity.value,
      image: selectedProductToAdd.value.image,
    });
  }

  // Reset form
  selectedProductToAdd.value = null;
  newItemQuantity.value = 1;
  showAddItemModal.value = false;

  // Show success toast
  showToast("success", "Item Added", "Product has been added to the order.");
};

const saveOrderItemChanges = async () => {
  if (isProcessing.value) return;

  isProcessing.value = true;

  try {
    // Simulate API call
    await new Promise((resolve) => setTimeout(resolve, 1000));

    if (selectedOrder.value) {
      // Calculate new subtotal and total
      const subtotal = calculateSubtotal();
      const total = calculateTotal();

      // Update order
      selectedOrder.value.items = JSON.parse(
        JSON.stringify(editingOrderItems.value)
      );
      selectedOrder.value.subtotal = subtotal;
      selectedOrder.value.deliveryFee = editingDeliveryFee.value;
      selectedOrder.value.total = total;

      // Update the order in the orders array
      const index = orders.value.findIndex(
        (o) => o.id === selectedOrder.value.id
      );
      if (index !== -1) {
        orders.value[index] = { ...selectedOrder.value };
      }

      // Show success toast
      showToast(
        "success",
        "Order Updated",
        "Order items have been successfully updated."
      );

      // Exit edit mode
      editOrderItems.value = false;
    }
  } catch (error) {
    showToast(
      "error",
      "Update Failed",
      "There was an error updating the order items."
    );
  } finally {
    isProcessing.value = false;
  }
};

const updateOrderStatus = async (id) => {
  console.log(editingOrderItems.value);
  try {
    const res = await patch(`/orders/${id}/`, {
      order_status: editingOrderStatus.value,
    });
    if (res.data) {
      // Show success toast
      showToast(
        "success",
        "Order Status Updated",
        `Order #${id} status has been updated to ${editingOrderStatus.value}.`
      );

      // Close modal
      showOrderDetailsModal.value = false;
    }
  } catch (error) {
    console.error("Error updating order status:", error);
    showToast(
      "error",
      "Update Failed",
      "There was an error updating the order status."
    );
  } finally {
    isProcessing.value = false;
    await getOrders();
  }
};

const printOrder = async (order) => {
  try {
    const doc = new jsPDF();

    // Add company header
    doc.setFontSize(20);
    doc.setTextColor(66, 66, 66);
    doc.text("Your Company Name", 105, 20, { align: "center" });

    doc.setFontSize(12);
    doc.setTextColor(100, 100, 100);
    doc.text("123 Business Street, City, Country", 105, 28, {
      align: "center",
    });
    doc.text("Phone: +1 234 567 890 | Email: info@yourcompany.com", 105, 34, {
      align: "center",
    });

    doc.line(14, 38, 196, 38);

    // Order details
    doc.setFontSize(16);
    doc.setTextColor(66, 66, 66);
    doc.text(`Order #${order.id}`, 14, 48);

    doc.setFontSize(10);
    doc.setTextColor(100, 100, 100);
    doc.text(`Date: ${order.date}`, 14, 55);
    doc.text(`Status: ${order.status.toUpperCase()}`, 14, 60);

    // Customer details
    doc.setFontSize(12);
    doc.setTextColor(66, 66, 66);
    doc.text("Customer Details", 14, 70);

    doc.setFontSize(10);
    doc.setTextColor(100, 100, 100);
    doc.text(`Name: ${order.customer}`, 14, 77);
    doc.text(`Email: ${order.email}`, 14, 82);
    doc.text(`Phone: ${order.phone}`, 14, 87);
    doc.text(`Address: ${order.address}`, 14, 92);

    // Payment details
    doc.setFontSize(12);
    doc.setTextColor(66, 66, 66);
    doc.text("Payment Details", 120, 70);

    doc.setFontSize(10);
    doc.setTextColor(100, 100, 100);
    doc.text(`Method: ${order.paymentMethod}`, 120, 77);
    doc.text(`Status: ${order.paymentStatus}`, 120, 82);

    // Order items - List format
    doc.setFontSize(12);
    doc.setTextColor(66, 66, 66);
    doc.text("Products", 14, 105);

    let yPos = 115;

    // Draw header line
    doc.setDrawColor(220, 220, 220);
    doc.line(14, yPos - 3, 196, yPos - 3);

    order.items.forEach((item, index) => {
      // Draw item details
      doc.setFontSize(10);
      doc.setTextColor(80, 80, 80);
      doc.text(`${index + 1}. ${item.name}`, 14, yPos);

      doc.setTextColor(100, 100, 100);
      doc.text(`${item.quantity} × ৳${item.price}`, 14, yPos + 5);

      doc.setFontSize(10);
      doc.setTextColor(80, 80, 80);
      doc.text(`৳${item.price * item.quantity}`, 180, yPos, { align: "right" });

      // Draw separator line
      if (index < order.items.length - 1) {
        doc.setDrawColor(240, 240, 240);
        doc.line(14, yPos + 8, 196, yPos + 8);
      }

      yPos += 15;
    });

    // Draw bottom line
    doc.setDrawColor(220, 220, 220);
    doc.line(14, yPos, 196, yPos);
    yPos += 10;

    // Order summary
    doc.setFontSize(10);
    doc.setTextColor(100, 100, 100);
    doc.text(`Subtotal:`, 140, yPos);
    doc.text(`৳${order.subtotal}`, 180, yPos, { align: "right" });

    yPos += 5;
    doc.text(`Delivery Fee:`, 140, yPos);
    doc.text(`৳${order.deliveryFee}`, 180, yPos, { align: "right" });

    yPos += 3;
    doc.line(140, yPos + 2, 180, yPos + 2);

    yPos += 7;
    doc.setFontSize(12);
    doc.setTextColor(66, 66, 66);
    doc.text(`Total:`, 140, yPos);
    doc.text(`৳${order.total}`, 180, yPos, { align: "right" });

    // Footer
    doc.setFontSize(10);
    doc.setTextColor(100, 100, 100);
    doc.text("Thank you for your business!", 105, 280, { align: "center" });

    // Save the PDF
    doc.save(`order-${order.id}.pdf`);

    // Show success toast
    showToast(
      "success",
      "PDF Generated",
      `Order #${order.id} has been downloaded as a PDF.`
    );
  } catch (error) {
    console.error("PDF Generation Error:", error);
    showToast(
      "error",
      "PDF Generation Failed",
      "There was an error generating the PDF."
    );
  }
};

const cancelOrder = () => {
  showCancelOrderModal.value = true;
};

const confirmCancelOrder = async () => {
  if (isProcessing.value) return;

  isProcessing.value = true;

  try {
    // Simulate API call
    await new Promise((resolve) => setTimeout(resolve, 1500));

    if (selectedOrder.value) {
      // Update order status to cancelled
      selectedOrder.value.status = "cancelled";

      // If payment was made with account funds, update payment status
      if (
        selectedOrder.value.paymentMethod === "Account Funds" ||
        selectedOrder.value.paymentMethod === "Credit Card" ||
        selectedOrder.value.paymentMethod === "PayPal"
      ) {
        selectedOrder.value.paymentStatus = "Refunded";
      }

      // Update the order in the orders array
      const index = orders.value.findIndex(
        (o) => o.id === selectedOrder.value.id
      );
      if (index !== -1) {
        orders.value[index] = { ...selectedOrder.value };
      }

      // Show success toast with refund info if applicable
      if (
        selectedOrder.value.paymentMethod === "Account Funds" ||
        selectedOrder.value.paymentMethod === "Credit Card" ||
        selectedOrder.value.paymentMethod === "PayPal"
      ) {
        showToast(
          "success",
          "Order Cancelled",
          `Order #${selectedOrder.value.id} has been cancelled and ৳${selectedOrder.value.total} has been refunded.`
        );
      } else {
        showToast(
          "success",
          "Order Cancelled",
          `Order #${selectedOrder.value.id} has been cancelled.`
        );
      }
    }

    // Close modals
    showCancelOrderModal.value = false;
    showOrderDetailsModal.value = false;
  } catch (error) {
    showToast(
      "error",
      "Cancellation Failed",
      "There was an error cancelling the order."
    );
  } finally {
    isProcessing.value = false;
  }
};

const editProduct = (product) => {
  selectedProduct.value = product;
  // Clone the product to avoid direct mutation
  Object.assign(editingProduct, product);
  showEditProductModal.value = true;
};

const saveProductChanges = async () => {
  if (isProcessing.value) return;

  isProcessing.value = true;

  try {
    // Simulate API call
    await new Promise((resolve) => setTimeout(resolve, 1000));

    // Update the product in the products array
    const index = products.value.findIndex((p) => p.id === editingProduct.id);
    if (index !== -1) {
      products.value[index] = { ...editingProduct };

      // Show success toast
      showToast(
        "success",
        "Product Updated",
        `${editingProduct.name} has been successfully updated.`
      );
    }

    // Close the modal
    showEditProductModal.value = false;
  } catch (error) {
    showToast(
      "error",
      "Update Failed",
      "There was an error updating the product."
    );
  } finally {
    isProcessing.value = false;
  }
};

const toggleProductStatus = async (product) => {
  if (isProcessing.value) return;

  isProcessing.value = true;

  try {
    // Simulate API call
    await new Promise((resolve) => setTimeout(resolve, 800));

    const index = products.value.findIndex((p) => p.id === product.id);
    if (index !== -1) {
      const newStatus = product.status === "active" ? "inactive" : "active";
      products.value[index].status = newStatus;

      // Show success toast
      showToast(
        "success",
        "Status Changed",
        `${product.name} is now ${
          newStatus === "active" ? "visible" : "hidden"
        } to customers.`
      );
    }
  } catch (error) {
    showToast(
      "error",
      "Status Change Failed",
      "There was an error changing the product status."
    );
  } finally {
    isProcessing.value = false;
  }
};

const confirmDeleteProduct = (product) => {
  selectedProduct.value = product;
  showDeleteConfirmModal.value = true;
};

const deleteProduct = async () => {
  if (isProcessing.value) return;

  isProcessing.value = true;

  try {
    // Simulate API call
    await new Promise((resolve) => setTimeout(resolve, 1200));

    // Remove the product from the products array
    const index = products.value.findIndex(
      (p) => p.id === selectedProduct.value.id
    );
    if (index !== -1) {
      const productName = selectedProduct.value.name;
      products.value.splice(index, 1);

      // Show success toast
      showToast(
        "success",
        "Product Deleted",
        `${productName} has been successfully deleted.`
      );
    }

    // Close the modal
    showDeleteConfirmModal.value = false;
  } catch (error) {
    showToast(
      "error",
      "Deletion Failed",
      "There was an error deleting the product."
    );
  } finally {
    isProcessing.value = false;
  }
};

// Pagination methods
const goToPage = (page) => {
  if (typeof page === "number") {
    currentPage.value = page;
  }
};

const nextPage = () => {
  if (currentPage.value < totalPages.value) {
    currentPage.value++;
  }
};

const prevPage = () => {
  if (currentPage.value > 1) {
    currentPage.value--;
  }
};

// Toast methods
const showToast = (type, title, message) => {
  const id = toastId++;
  toasts.value.push({ id, type, title, message });

  // Auto-remove toast after 5 seconds
  setTimeout(() => {
    removeToast(id);
  }, 5000);
};

const removeToast = (id) => {
  const index = toasts.value.findIndex((toast) => toast.id === id);
  if (index !== -1) {
    toasts.value.splice(index, 1);
  }
};

// Lifecycle hooks
onMounted(() => {
  // Reset pagination when tab changes
  watch(activeTab, () => {
    currentPage.value = 1;
    currentProductPage.value = 1;
  });

  // Reset pagination when filters change
  watch([orderFilter, orderSearch], () => {
    currentPage.value = 1;
  });

  watch([productFilter, productSearch], () => {
    currentProductPage.value = 1;
  });
});

const isEditing = ref(false);
const editedUser = reactive({
  store_name: user.value.user.store_name || "",
  store_username: user.value.user.store_username || "",
  store_address: user.value.user.store_address || "",
  store_description: user.value.user.store_description || "",
});

// Copy to clipboard functionality
const copied = ref(false);

function copyToClipboard(text) {
  navigator.clipboard.writeText(text).then(() => {
    copied.value = true;
    setTimeout(() => {
      copied.value = false;
    }, 2000);
  });
}

// Emit events for parent component
const emit = defineEmits(["update"]);

// Watch for editing state changes
watch(isEditing, (newValue, oldValue) => {
  if (oldValue === true && newValue === false) {
    // User clicked Save (switched from editing to viewing)
    emit("update", editedUser);
  }
});
</script>
<style setup>
/* Only essential styles */
.toast-enter-active,
.toast-leave-active {
  transition: all 0.3s ease;
}
.toast-enter-from {
  transform: translateX(100%);
  opacity: 0;
}
.toast-leave-to {
  transform: translateX(100%);
  opacity: 0;
}
</style>
