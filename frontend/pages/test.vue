<template>
  <PublicSection>
    <UContainer>
      <div class="order-history-page">
        <!-- Page Header with Animation -->
        <div class="page-header relative overflow-hidden mb-6">
          <div
            class="flex flex-col md:flex-row md:items-center justify-between gap-4 py-2"
          >
            <div class="relative">
              <!-- Subtle animated underline -->
              <h1
                class="text-2xl sm:text-3xl font-bold text-slate-800 dark:text-white relative inline-block"
              >
                My Orders
                <span
                  class="absolute bottom-0 left-0 w-full h-1 bg-gradient-to-r from-primary-400 to-primary-600 dark:from-primary-600 dark:to-primary-400 transform origin-left scale-x-0 animate-expand"
                ></span>
              </h1>
              <p class="text-slate-500 dark:text-slate-400 mt-1">
                Track and manage all your order history
              </p>
            </div>

            <!-- Order Stats Cards -->
            <div class="flex flex-wrap gap-3">
              <div
                class="stat-card flex items-center gap-3 px-4 py-2.5 bg-white dark:bg-slate-800 rounded-lg shadow-sm border border-slate-100 dark:border-slate-700/60"
              >
                <div
                  class="w-10 h-10 rounded-full bg-green-50 dark:bg-green-900/20 flex items-center justify-center"
                >
                  <UIcon
                    name="i-heroicons-check-circle"
                    class="w-5 h-5 text-green-500"
                  />
                </div>
                <div>
                  <div class="text-xs text-slate-500 dark:text-slate-400">
                    Completed
                  </div>
                  <div class="text-lg font-bold text-slate-900 dark:text-white">
                    24
                  </div>
                </div>
              </div>

              <div
                class="stat-card flex items-center gap-3 px-4 py-2.5 bg-white dark:bg-slate-800 rounded-lg shadow-sm border border-slate-100 dark:border-slate-700/60"
              >
                <div
                  class="w-10 h-10 rounded-full bg-amber-50 dark:bg-amber-900/20 flex items-center justify-center"
                >
                  <UIcon
                    name="i-heroicons-clock"
                    class="w-5 h-5 text-amber-500"
                  />
                </div>
                <div>
                  <div class="text-xs mt-2 text-slate-500 dark:text-slate-400">
                    Processing
                  </div>
                  <div class="text-lg font-bold text-slate-900 dark:text-white">
                    2
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>

        <!-- Search & Filter Section -->
        <div class="search-filter mb-6">
          <div
            class="bg-white dark:bg-slate-800 rounded-xl shadow-sm border border-slate-100 dark:border-slate-700/60 p-4"
          >
            <div class="flex flex-col sm:flex-row gap-4">
              <!-- Search Input -->
              <div class="relative flex-1">
                <div
                  class="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none"
                >
                  <UIcon
                    name="i-heroicons-magnifying-glass"
                    class="w-5 h-5 text-slate-400"
                  />
                </div>
                <input
                  type="text"
                  placeholder="Search orders by ID or product name..."
                  class="w-full pl-10 pr-4 py-2.5 rounded-lg border border-slate-200 dark:border-slate-700 bg-slate-50 dark:bg-slate-900/50 text-slate-800 dark:text-slate-200 placeholder-slate-400 dark:placeholder-slate-500 focus:outline-none focus:ring-2 focus:ring-primary-500/30 focus:border-primary-500 transition-all duration-200"
                />
              </div>

              <!-- Filters -->
              <div class="flex flex-wrap gap-2">
                <!-- Date Range -->
                <USelectMenu
                  placeholder="Filter by date"
                  size="md"
                  :options="[
                    { label: 'All time', value: 'all' },
                    { label: 'Last 7 days', value: '7d' },
                    { label: 'Last 30 days', value: '30d' },
                    { label: 'Last 3 months', value: '3m' },
                  ]"
                  :ui="{
                    base: 'w-40',
                    trigger: {
                      padding: 'py-2.5 px-3',
                      base: 'bg-slate-50 dark:bg-slate-900/50 border border-slate-200 dark:border-slate-700 rounded-lg',
                    },
                  }"
                >
                  <template #leading>
                    <UIcon
                      name="i-heroicons-calendar"
                      class="w-5 h-5 text-slate-400"
                    />
                  </template>
                </USelectMenu>

                <!-- Status Filter -->
                <USelectMenu
                  placeholder="Status"
                  size="md"
                  :options="[
                    { label: 'All statuses', value: 'all' },
                    { label: 'Processing', value: 'processing' },
                    { label: 'Shipped', value: 'shipped' },
                    { label: 'Delivered', value: 'delivered' },
                    { label: 'Cancelled', value: 'cancelled' },
                    { label: 'Refunded', value: 'refunded' },
                  ]"
                  :ui="{
                    base: 'w-40',
                    trigger: {
                      padding: 'py-2.5 px-3',
                      base: 'bg-slate-50 dark:bg-slate-900/50 border border-slate-200 dark:border-slate-700 rounded-lg',
                    },
                  }"
                >
                  <template #leading>
                    <UIcon
                      name="i-heroicons-funnel"
                      class="w-5 h-5 text-slate-400"
                    />
                  </template>
                </USelectMenu>
              </div>
            </div>
          </div>
        </div>

        <!-- Orders List With Premium Design -->
        <div class="orders-list space-y-5">
          <!-- Order Card -->
          <div
            v-for="order in [1, 2, 3]"
            :key="order"
            class="order-card group bg-white dark:bg-slate-800 rounded-xl shadow-lg border border-slate-100 dark:border-slate-700/60 overflow-hidden transition-all duration-300 hover:shadow-xl hover:border-primary-300 dark:hover:border-primary-700/50"
          >
            <!-- Premium Glass Effect Header -->
            <div class="relative overflow-hidden">
              <!-- Background Pattern -->
              <div
                class="absolute inset-0 bg-gradient-to-r from-primary-50 to-slate-50 dark:from-slate-800/50 dark:to-slate-900/50 opacity-70"
              ></div>

              <!-- Animated Lines -->
              <div class="absolute inset-0">
                <div
                  class="absolute top-0 left-0 w-full h-px bg-gradient-to-r from-transparent via-primary-300/50 dark:via-primary-500/30 to-transparent transform translate-x-0 animate-line-scroll"
                ></div>
                <div
                  class="absolute bottom-0 left-0 w-full h-px bg-gradient-to-r from-transparent via-primary-300/50 dark:via-primary-500/30 to-transparent transform translate-x-0 animate-line-scroll-reverse"
                ></div>
              </div>

              <!-- Order ID and Date Banner -->
              <div
                class="flex items-center justify-between px-5 py-2.5 relative z-10 border-b border-slate-200/70 dark:border-slate-700/30"
              >
                <!-- Order ID with Copy Button -->
                <div class="flex items-center gap-3">
                  <div class="copy-id-container relative group/copy">
                    <div
                      class="flex items-center gap-2 px-3 py-1.5 bg-white/80 dark:bg-slate-700/70 backdrop-blur-sm rounded-lg shadow-sm"
                    >
                      <UIcon
                        name="i-heroicons-document-text"
                        class="w-4 h-4 text-primary-500"
                      />
                      <span
                        class="text-sm font-medium text-slate-700 dark:text-slate-300"
                        >Order #OXY-{{ 10000 + order * 173 }}</span
                      >
                      <button
                        class="w-6 h-6 flex items-center justify-center text-slate-400 hover:text-primary-500 transition-colors bg-white/80 dark:bg-slate-800/80 rounded-full"
                      >
                        <UIcon
                          name="i-heroicons-clipboard-document"
                          class="w-3.5 h-3.5"
                        />
                      </button>
                    </div>
                    <!-- Tooltip -->
                    <div
                      class="absolute -top-8 left-1/2 transform -translate-x-1/2 px-2 py-1 bg-slate-800 text-white text-xs rounded opacity-0 group-hover/copy:opacity-100 transition-opacity pointer-events-none"
                    >
                      Copy ID
                    </div>
                  </div>

                  <!-- Order Date -->
                  <div
                    class="flex items-center gap-1.5 px-3 py-1.5 bg-white/80 dark:bg-slate-700/70 backdrop-blur-sm rounded-lg text-slate-600 dark:text-slate-300"
                  >
                    <UIcon
                      name="i-heroicons-calendar-days"
                      class="w-4 h-4 text-slate-500"
                    />
                    <span class="text-sm">March {{ 10 + order }}, 2025</span>
                  </div>
                </div>

                <!-- Price Tag -->
                <div
                  class="price-tag px-3 py-1.5 bg-primary-500/10 dark:bg-primary-500/20 backdrop-blur-sm rounded-lg"
                >
                  <span
                    class="text-sm font-medium text-primary-700 dark:text-primary-300"
                    >৳{{ 1250 * order }}</span
                  >
                </div>
              </div>

              <!-- Order Content Section -->
              <div class="px-5 py-4 relative z-10">
                <div class="flex flex-col lg:flex-row gap-6">
                  <!-- Customer Info Card -->
                  <div
                    class="customer-info flex-none lg:w-80 p-4 bg-white dark:bg-slate-800/90 backdrop-blur-sm rounded-xl shadow-sm border border-slate-100 dark:border-slate-700/40 relative overflow-hidden group/customer"
                  >
                    <!-- Avatar & Customer Name -->
                    <div class="flex items-center gap-3 mb-3">
                      <div class="relative">
                        <div
                          class="absolute inset-0 bg-gradient-to-br from-primary-300 to-primary-500 dark:from-primary-500 dark:to-primary-700 rounded-full blur-md opacity-20 group-hover/customer:opacity-40 transition-opacity"
                        ></div>
                        <div
                          class="w-12 h-12 bg-gradient-to-br from-slate-100 to-slate-200 dark:from-slate-700 dark:to-slate-800 rounded-full flex items-center justify-center border-2 border-white dark:border-slate-700 relative z-10 overflow-hidden"
                        >
                          <img
                            src="https://randomuser.me/api/portraits/thumb/men/75.jpg"
                            alt="Customer avatar"
                            class="w-full h-full object-cover transition-transform duration-700 group-hover/customer:scale-110"
                            :class="
                              order % 2 === 0
                                ? 'group-hover/customer:rotate-3'
                                : 'group-hover/customer:rotate-[-3deg]'
                            "
                          />
                        </div>
                      </div>
                      <div>
                        <h4
                          class="font-semibold text-slate-800 dark:text-white text-base"
                        >
                          {{
                            order === 1
                              ? "John Doe"
                              : order === 2
                              ? "Sarah Johnson"
                              : "Michael Chen"
                          }}
                        </h4>
                        <div
                          class="flex items-center gap-1.5 text-xs text-slate-500 dark:text-slate-400"
                        >
                          <UIcon name="i-heroicons-user" class="w-3.5 h-3.5" />
                          <span>Customer since 2024</span>
                        </div>
                      </div>
                    </div>

                    <!-- Customer Details -->
                    <div class="space-y-2 pl-2">
                      <!-- Email -->
                      <div class="flex items-center gap-2 group/email">
                        <div
                          class="w-8 h-8 rounded-lg bg-slate-100 dark:bg-slate-700 flex items-center justify-center shadow-sm group-hover/email:bg-primary-50 dark:group-hover/email:bg-primary-900/30 transition-colors"
                        >
                          <UIcon
                            name="i-heroicons-envelope"
                            class="w-4 h-4 text-slate-500 dark:text-slate-400 group-hover/email:text-primary-500 dark:group-hover/email:text-primary-400 transition-colors"
                          />
                        </div>
                        <div>
                          <div
                            class="text-xs text-slate-500 dark:text-slate-400"
                          >
                            Email
                          </div>
                          <div
                            class="text-sm font-medium text-slate-700 dark:text-slate-300"
                          >
                            {{
                              order === 1
                                ? "john.doe@example.com"
                                : order === 2
                                ? "sarah.j@example.com"
                                : "michael.chen@example.com"
                            }}
                          </div>
                        </div>
                      </div>

                      <!-- Phone -->
                      <div class="flex items-center gap-2 group/phone">
                        <div
                          class="w-8 h-8 rounded-lg bg-slate-100 dark:bg-slate-700 flex items-center justify-center shadow-sm group-hover/phone:bg-primary-50 dark:group-hover/phone:bg-primary-900/30 transition-colors"
                        >
                          <UIcon
                            name="i-heroicons-phone"
                            class="w-4 h-4 text-slate-500 dark:text-slate-400 group-hover/phone:text-primary-500 dark:group-hover/phone:text-primary-400 transition-colors"
                          />
                        </div>
                        <div>
                          <div
                            class="text-xs text-slate-500 dark:text-slate-400"
                          >
                            Phone
                          </div>
                          <div
                            class="text-sm font-medium text-slate-700 dark:text-slate-300"
                          >
                            {{
                              order === 1
                                ? "+1 (555) 123-4567"
                                : order === 2
                                ? "+1 (555) 987-6543"
                                : "+1 (555) 246-8102"
                            }}
                          </div>
                        </div>
                      </div>

                      <!-- Address Preview -->
                      <div class="flex items-center gap-2 group/address">
                        <div
                          class="w-8 h-8 rounded-lg bg-slate-100 dark:bg-slate-700 flex items-center justify-center shadow-sm group-hover/address:bg-primary-50 dark:group-hover/address:bg-primary-900/30 transition-colors"
                        >
                          <UIcon
                            name="i-heroicons-map-pin"
                            class="w-4 h-4 text-slate-500 dark:text-slate-400 group-hover/address:text-primary-500 dark:group-hover/address:text-primary-400 transition-colors"
                          />
                        </div>
                        <div>
                          <div
                            class="text-xs text-slate-500 dark:text-slate-400"
                          >
                            Address
                          </div>
                          <div
                            class="text-sm font-medium text-slate-700 dark:text-slate-300 truncate max-w-[180px]"
                          >
                            {{
                              order === 1
                                ? "123 Main St, New York, NY 10001"
                                : order === 2
                                ? "456 Park Ave, Chicago, IL 60601"
                                : "789 Ocean Blvd, San Francisco, CA 94107"
                            }}
                          </div>
                        </div>
                      </div>
                    </div>
                  </div>

                  <!-- Order Details -->
                  <div class="flex-1">
                    <!-- Products Preview with Enhanced Styling -->
                    <div class="mb-4">
                      <h5
                        class="text-sm font-medium text-slate-500 dark:text-slate-400 mb-3 flex items-center"
                      >
                        <UIcon
                          name="i-heroicons-shopping-bag"
                          class="w-4 h-4 mr-1.5"
                        />
                        Order Items ({{ order + (order - 1) }})
                      </h5>

                      <!-- Products Grid -->
                      <div
                        class="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 lg:grid-cols-3 xl:grid-cols-4 gap-3"
                      >
                        <div
                          v-for="item in [1, 2, 3, 4].slice(0, order + 1)"
                          :key="item"
                          class="product-preview group/product relative rounded-lg overflow-hidden shadow-sm bg-gradient-to-br from-slate-50 to-slate-100 dark:from-slate-700/50 dark:to-slate-800/50 border border-slate-200 dark:border-slate-700/70 transition-all duration-300 hover:shadow-md hover:border-primary-200 dark:hover:border-primary-700/50"
                        >
                          <!-- Product Image -->
                          <div class="aspect-square relative overflow-hidden">
                            <img
                              :src="`https://picsum.photos/seed/${
                                order * 10 + item
                              }/300/300`"
                              class="w-full h-full object-cover transition-transform duration-700 group-hover/product:scale-110"
                              alt="Product image"
                            />

                            <!-- Quick View Overlay -->
                            <div
                              class="absolute inset-0 flex items-center justify-center bg-gradient-to-t from-black/70 via-black/40 to-transparent opacity-0 group-hover/product:opacity-100 transition-opacity"
                            >
                              <button
                                class="bg-white/90 dark:bg-slate-800/90 text-primary-600 dark:text-primary-400 p-1.5 rounded-full transform translate-y-4 group-hover/product:translate-y-0 transition-transform"
                              >
                                <UIcon name="i-heroicons-eye" class="w-4 h-4" />
                              </button>
                            </div>

                            <!-- Product Price -->
                            <div
                              class="absolute bottom-0 right-0 bg-white/90 dark:bg-slate-800/90 px-2 py-1 text-xs font-medium text-slate-700 dark:text-slate-300 rounded-tl-lg"
                            >
                              ৳{{ 350 * item }}
                            </div>
                          </div>

                          <!-- Product Name -->
                          <div
                            class="p-2 text-xs text-slate-600 dark:text-slate-300 font-medium line-clamp-1"
                          >
                            {{
                              [
                                "Premium Headphones",
                                "Wireless Mouse",
                                "Mechanical Keyboard",
                                "USB-C Cable",
                              ][item - 1]
                            }}
                          </div>
                        </div>

                        <!-- View All Button (if more items) -->
                        <div
                          v-if="order > 1"
                          class="view-more-products flex items-center justify-center aspect-square rounded-lg bg-slate-50/80 dark:bg-slate-800/50 border border-dashed border-slate-200 dark:border-slate-700 hover:border-primary-200 dark:hover:border-primary-700/50 transition-colors duration-300"
                        >
                          <button
                            class="p-3 rounded-full text-slate-500 dark:text-slate-400 hover:text-primary-500 dark:hover:text-primary-400 transition-colors"
                          >
                            <UIcon
                              name="i-heroicons-ellipsis-horizontal-circle"
                              class="w-6 h-6"
                            />
                            <span class="text-xs block mt-1">View All</span>
                          </button>
                        </div>
                      </div>
                    </div>

                    <!-- Status and Actions -->
                    <div
                      class="flex flex-col sm:flex-row sm:items-center justify-between gap-4 pt-3 border-t border-slate-200/70 dark:border-slate-700/30"
                    >
                      <!-- Order Status with Timeline Indicator -->
                      <div class="order-status-timeline flex items-center">
                        <!-- Status Steps -->
                        <div class="flex items-center">
                          <!-- Processing -->
                          <div class="relative">
                            <div
                              class="w-8 h-8 rounded-full flex items-center justify-center relative z-10"
                              :class="
                                order >= 1
                                  ? 'bg-primary-100 dark:bg-primary-900/30 text-primary-600 dark:text-primary-400 ring-2 ring-primary-500/20 dark:ring-primary-500/30'
                                  : 'bg-slate-100 dark:bg-slate-700/50 text-slate-400'
                              "
                            >
                              <UIcon
                                name="i-heroicons-clipboard-document-check"
                                class="w-4 h-4"
                              />
                            </div>
                            <div
                              v-if="order >= 1"
                              class="absolute -bottom-1 left-1/2 transform -translate-x-1/2 text-[10px] font-medium text-primary-600 dark:text-primary-400 whitespace-nowrap"
                            >
                              Processing
                            </div>
                          </div>

                          <!-- Connecting Line -->
                          <div
                            class="w-12 h-1 mx-1"
                            :class="
                              order >= 2
                                ? 'bg-primary-400 dark:bg-primary-700'
                                : 'bg-slate-200 dark:bg-slate-700'
                            "
                          ></div>

                          <!-- Shipped -->
                          <div class="relative">
                            <div
                              class="w-8 h-8 rounded-full flex items-center justify-center relative z-10"
                              :class="
                                order >= 2
                                  ? 'bg-primary-100 dark:bg-primary-900/30 text-primary-600 dark:text-primary-400 ring-2 ring-primary-500/20 dark:ring-primary-500/30'
                                  : 'bg-slate-100 dark:bg-slate-700/50 text-slate-400'
                              "
                            >
                              <UIcon name="i-heroicons-truck" class="w-4 h-4" />
                            </div>
                            <div
                              v-if="order >= 2"
                              class="absolute -bottom-1 left-1/2 transform -translate-x-1/2 text-[10px] font-medium text-primary-600 dark:text-primary-400 whitespace-nowrap"
                            >
                              Shipped
                            </div>
                          </div>

                          <!-- Connecting Line -->
                          <div
                            class="w-12 h-1 mx-1"
                            :class="
                              order >= 3
                                ? 'bg-primary-400 dark:bg-primary-700'
                                : 'bg-slate-200 dark:bg-slate-700'
                            "
                          ></div>

                          <!-- Delivered -->
                          <div class="relative">
                            <div
                              class="w-8 h-8 rounded-full flex items-center justify-center relative z-10"
                              :class="
                                order >= 3
                                  ? 'bg-primary-100 dark:bg-primary-900/30 text-primary-600 dark:text-primary-400 ring-2 ring-primary-500/20 dark:ring-primary-500/30'
                                  : 'bg-slate-100 dark:bg-slate-700/50 text-slate-400'
                              "
                            >
                              <UIcon
                                name="i-heroicons-check-badge"
                                class="w-4 h-4"
                              />
                            </div>
                            <div
                              v-if="order >= 3"
                              class="absolute -bottom-1 left-1/2 transform -translate-x-1/2 text-[10px] font-medium text-primary-600 dark:text-primary-400 whitespace-nowrap"
                            >
                              Delivered
                            </div>
                          </div>
                        </div>

                        <!-- Current Status Badge -->
                        <UBadge
                          :color="
                            order === 1
                              ? 'amber'
                              : order === 2
                              ? 'blue'
                              : 'green'
                          "
                          :variant="order < 3 ? 'soft' : 'solid'"
                          size="md"
                          class="ml-4 px-3"
                        >
                          <span class="flex items-center gap-1.5">
                            <UIcon
                              :name="
                                order === 1
                                  ? 'i-heroicons-clock'
                                  : order === 2
                                  ? 'i-heroicons-truck'
                                  : 'i-heroicons-check-badge'
                              "
                              class="w-3.5 h-3.5"
                            />
                            <span>{{
                              order === 1
                                ? "Processing"
                                : order === 2
                                ? "Shipped"
                                : "Delivered"
                            }}</span>
                          </span>
                        </UBadge>
                      </div>

                      <!-- Action Buttons -->
                      <div class="flex items-center gap-3">
                        <!-- View Details Button -->
                        <UTooltip text="View Order Details">
                          <UButton
                            color="gray"
                            variant="ghost"
                            size="md"
                            icon="i-heroicons-eye"
                            class="details-btn relative overflow-hidden group/details"
                            @click="() => {}"
                          >
                            <span
                              class="flex items-center gap-1.5 z-10 relative"
                            >
                              <span>View Details</span>
                            </span>

                            <!-- Hover Effect -->
                            <div
                              class="absolute inset-0 w-full h-full bg-gradient-to-r from-transparent via-slate-100 dark:via-slate-700/30 to-transparent -translate-x-full group-hover/details:animate-shimmer"
                            ></div>
                          </UButton>
                        </UTooltip>

                        <!-- Deliver Button (Only for Processing orders) -->
                        <UTooltip v-if="order === 1" text="Mark as Shipped">
                          <UButton
                            color="primary"
                            variant="soft"
                            size="md"
                            class="deliver-btn relative overflow-hidden group/deliver"
                            @click="() => {}"
                          >
                            <span
                              class="flex items-center gap-1.5 z-10 relative"
                            >
                              <UIcon
                                name="i-heroicons-truck"
                                class="w-4 h-4 transition-transform group-hover/deliver:translate-x-1"
                              />
                              <span>Process Shipment</span>
                            </span>

                            <!-- Hover Effect -->
                            <div
                              class="absolute inset-0 w-full h-full bg-gradient-to-r from-transparent via-white/20 dark:via-white/10 to-transparent -translate-x-full group-hover/deliver:animate-shimmer"
                            ></div>
                          </UButton>
                        </UTooltip>

                        <!-- Complete Button (Only for Shipped orders) -->
                        <UTooltip v-if="order === 2" text="Mark as Delivered">
                          <UButton
                            color="primary"
                            variant="soft"
                            size="md"
                            class="deliver-btn relative overflow-hidden group/complete"
                            @click="() => {}"
                          >
                            <span
                              class="flex items-center gap-1.5 z-10 relative"
                            >
                              <UIcon
                                name="i-heroicons-check-badge"
                                class="w-4 h-4 transition-transform group-hover/complete:scale-110"
                              />
                              <span>Confirm Delivery</span>
                            </span>

                            <!-- Hover Effect -->
                            <div
                              class="absolute inset-0 w-full h-full bg-gradient-to-r from-transparent via-white/20 dark:via-white/10 to-transparent -translate-x-full group-hover/complete:animate-shimmer"
                            ></div>
                          </UButton>
                        </UTooltip>
                      </div>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>

          <!-- Enhanced Pagination -->
          <div
            class="pagination flex justify-between items-center mt-8 pt-5 border-t border-slate-200 dark:border-slate-700/50"
          >
            <div
              class="text-sm text-slate-500 dark:text-slate-400 flex items-center"
            >
              <span class="hidden sm:inline-flex items-center">
                <UIcon name="i-heroicons-squares-2x2" class="w-4 h-4 mr-1.5" />
                Showing
              </span>
              <UBadge color="gray" variant="soft" class="mx-1">1-3</UBadge>
              <span>of</span>
              <UBadge color="primary" variant="soft" class="mx-1">27</UBadge>
              <span>orders</span>
            </div>

            <div class="pagination-buttons relative">
              <!-- Background Highlight for Current Page -->
              <div
                class="absolute h-full top-0 bottom-0 bg-primary-50 dark:bg-primary-900/30 rounded-md transition-all duration-300"
                :style="{ width: '2.5rem', left: '2.75rem' }"
              ></div>

              <!-- Pagination Controls -->
              <div class="flex items-center gap-1 relative z-10">
                <!-- Previous Button -->
                <UButton
                  color="gray"
                  variant="ghost"
                  size="sm"
                  icon="i-heroicons-chevron-left"
                  class="pagination-btn"
                  :ui="{ rounded: 'rounded-l-lg rounded-r-none' }"
                  disabled
                />

                <!-- Page Buttons -->
                <UButton
                  color="gray"
                  variant="ghost"
                  size="sm"
                  class="pagination-btn min-w-[2.5rem] text-primary-600 dark:text-primary-400 font-medium"
                >
                  1
                </UButton>

                <UButton
                  color="gray"
                  variant="ghost"
                  size="sm"
                  class="pagination-btn min-w-[2.5rem]"
                >
                  2
                </UButton>

                <UButton
                  color="gray"
                  variant="ghost"
                  size="sm"
                  class="pagination-btn min-w-[2.5rem]"
                >
                  3
                </UButton>

                <!-- Ellipsis -->
                <UButton
                  color="gray"
                  variant="ghost"
                  size="sm"
                  icon="i-heroicons-ellipsis-horizontal"
                  class="pagination-btn min-w-[2.5rem]"
                />

                <!-- Last Page -->
                <UButton
                  color="gray"
                  variant="ghost"
                  size="sm"
                  class="pagination-btn min-w-[2.5rem]"
                >
                  9
                </UButton>

                <!-- Next Button -->
                <UButton
                  color="gray"
                  variant="ghost"
                  size="sm"
                  icon="i-heroicons-chevron-right"
                  class="pagination-btn"
                  :ui="{ rounded: 'rounded-r-lg rounded-l-none' }"
                />
              </div>
            </div>
          </div>
        </div>

        <!-- Pagination -->
      </div>
    </UContainer>
  </PublicSection>
</template>

<style scoped>
/* Subtle animations */
@keyframes shimmer {
  100% {
    transform: translateX(100%);
  }
}

.group:hover .animate-shimmer {
  animation: shimmer 1.5s;
}

@keyframes expand {
  0% {
    transform: scaleX(0);
  }
  100% {
    transform: scaleX(1);
  }
}

.animate-expand {
  animation: expand 1s ease-out forwards;
}

.no-scrollbar {
  -ms-overflow-style: none;
  scrollbar-width: none;
}

.no-scrollbar::-webkit-scrollbar {
  display: none;
}

/* Card hover effects */
.order-card {
  transition: all 0.3s cubic-bezier(0.21, 0.61, 0.35, 1);
}

.order-card:hover {
  transform: translateY(-2px);
}

/* Stat cards hover effect */
.stat-card {
  transition: all 0.2s ease;
}

.stat-card:hover {
  transform: translateY(-2px);
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.05);
}
/* Animations for line effects */
@keyframes line-scroll {
  0% {
    transform: translateX(-100%);
  }
  100% {
    transform: translateX(100%);
  }
}

@keyframes line-scroll-reverse {
  0% {
    transform: translateX(100%);
  }
  100% {
    transform: translateX(-100%);
  }
}

.animate-line-scroll {
  animation: line-scroll 8s infinite linear;
}

.animate-line-scroll-reverse {
  animation: line-scroll-reverse 8s infinite linear;
}

/* Shimmer effect animation */
@keyframes shimmer {
  100% {
    transform: translateX(100%);
  }
}

.group-hover\/details:animate-shimmer,
.group-hover\/deliver:animate-shimmer,
.group-hover\/complete:animate-shimmer {
  animation: shimmer 1.5s ease;
}

/* Card hover effects */
.order-card {
  transition: all 0.4s cubic-bezier(0.21, 0.61, 0.35, 1);
}

.order-card:hover {
  transform: translateY(-4px);
}

/* Pagination highlight effect */
.pagination-btn {
  position: relative;
  z-index: 10;
  transition: color 0.3s ease;
}

/* Timeline status transitions */
.order-status-timeline .w-8 {
  transition: all 0.3s ease;
}

.order-status-timeline .w-12 {
  transition: background-color 0.5s ease;
}

/* Product hover effect */
.product-preview img {
  transition: transform 1.2s cubic-bezier(0.21, 0.61, 0.35, 1);
}

/* Subtle animated underline */
@keyframes expand {
  0% {
    transform: scaleX(0);
  }
  100% {
    transform: scaleX(1);
  }
}

.animate-expand {
  animation: expand 1s ease-out forwards;
}

/* Hide scrollbars but allow scrolling */
.no-scrollbar {
  -ms-overflow-style: none;
  scrollbar-width: none;
}

.no-scrollbar::-webkit-scrollbar {
  display: none;
}
</style>
