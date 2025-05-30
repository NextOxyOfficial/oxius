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
            class="relative mx-auto max-w-3xl overflow-hidden rounded-xl border-0 bg-gradient-to-br from-slate-50 to-slate-100 shadow-sm dark:from-slate-900 dark:to-slate-800"
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
                    class="mb-3 text-xl font-semibold tracking-tight text-slate-700"
                  >
                    {{ $t("premium_access_required") }}
                  </h3>
                  <p class="text-muted-foreground">
                    {{ $t("premium_access_text") }}
                  </p>
                </div>

                <NuxtLink
                  href="/upgrade-to-pro"
                  class="group relative flex w-full items-center justify-center gap-2 overflow-hidden rounded-lg bg-gradient-to-r from-blue-600 to-purple-700 px-4 py-3 text-white transition-all hover:shadow-sm hover:shadow-blue-500/25"
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
          :getStoreDetails="handleReload"
        />
        <div v-else>
          <!-- store details -->
          <div
            class="bg-white rounded-lg shadow-sm border border-gray-100 hover:shadow-sm transition-all duration-300 w-full mb-3 overflow-hidden transform hover:scale-[1.01]"
          >            <!-- Compact Header with Shimmer Effect -->
            <div
              class="bg-gradient-to-r from-emerald-600 to-teal-500 px-4 py-3 flex items-center relative overflow-hidden cursor-pointer"
              @click="toggleStoreDetails"
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

              <!-- Arrow Icon -->
              <UIcon
                name="i-heroicons-chevron-down"
                class="h-5 w-5 text-white ml-2 relative z-10 transition-transform duration-300"
                :class="{ 'rotate-180': !isStoreDetailsCollapsed }"
              />

              <!-- Edit Button -->
              <button
                v-if="!isEditing"
                @click.stop="isEditing = true"
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
              <button
                v-else
                @click.stop="(isEditing = false), updateStoreInfo()"
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
            </div>            <!-- Collapsible Content -->
            <Transition
              name="collapse"
              enter-active-class="transition-all duration-300 ease-out"
              leave-active-class="transition-all duration-300 ease-in"
              enter-from-class="opacity-0 max-h-0"
              enter-to-class="opacity-100 max-h-screen"
              leave-from-class="opacity-100 max-h-screen"
              leave-to-class="opacity-0 max-h-0"
            >
              <div v-show="!isStoreDetailsCollapsed" class="overflow-hidden">
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
                      <p class="text-xs font-medium text-gray-600 mb-1">
                        Shop Name
                      </p>
                      <input
                        v-if="isEditing"
                        v-model="editedUser.store_name"
                        class="text-sm font-semibold text-gray-800 w-full border-b border-emerald-200 focus:outline-none px-2 py-1"
                      />
                      <p
                        v-else
                        class="text-sm font-semibold text-gray-800 truncate"
                      >
                        {{ storeDetails.store_name || "Not set" }}
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
                      <p class="text-xs font-medium text-gray-600 mb-1">
                        Store URL
                      </p>
                      <div class="flex items-center flex-wrap">
                        <div
                          class="flex items-center bg-gray-50 rounded px-2 py-1 max-w-full overflow-hidden"
                        >
                          <NuxtLink
                            class="flex items-center"
                            :to="`/eshop/${storeDetails.store_username}`"
                          >
                            <p class="text-xs text-gray-600 whitespace-nowrap">
                              https://adsyclub.com/eshop/
                            </p>
                            <p
                              class="text-sm font-semibold text-emerald-600 truncate"
                            >
                              {{ storeDetails.store_username || "Not set" }}
                            </p>
                          </NuxtLink>
                          <button
                            v-if="storeDetails.store_username"
                            @click="
                              copyToClipboard(
                                `https://adsyclub.com/eshop/${storeDetails.store_username}`
                              )
                            "
                            class="ml-1.5 text-gray-600 hover:text-emerald-600 transition-colors flex-shrink-0"
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
                      <p class="text-xs text-gray-600 mt-1 italic">
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
                      <p class="text-xs font-medium text-gray-600 mb-1">
                        Shop Address
                      </p>
                      <input
                        v-if="isEditing"
                        v-model="editedUser.store_address"
                        class="text-sm font-semibold text-gray-800 w-full border-b border-emerald-200 focus:outline-none px-2 py-1"
                      />
                      <p
                        v-else
                        class="text-sm font-semibold text-gray-800 truncate"
                      >
                        {{ storeDetails?.store_address || "Not set" }}
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
                      <p class="text-xs font-medium text-gray-600 mb-1">
                        Description
                      </p>
                      <textarea
                        v-if="isEditing"
                        v-model="editedUser.store_description"
                        rows="2"
                        class="text-sm text-gray-800 w-full border border-emerald-200 rounded focus:outline-none py-1 px-2 resize-none"
                      ></textarea>
                      <p v-else class="text-sm text-gray-800 line-clamp-2">
                        {{
                          storeDetails?.store_description ||
                          "No description available"
                        }}
                      </p>
                    </div>
                  </div>
                </div>                <!-- Status Indicator -->
                <div
                  class="px-4 py-2 bg-gray-50 border-t border-gray-100 flex flex-col sm:flex-row items-start sm:items-center"
                >
                  <div class="flex items-center">
                    <div
                      class="h-2 w-2 rounded-full bg-emerald-500 mr-2 animate-pulse"
                    ></div>
                    <span class="text-xs text-gray-600">Store Active</span>
                  </div>                  <div class="mt-1 sm:mt-0 sm:ml-auto text-xs text-gray-600 flex items-center gap-3">
                    <div class="flex items-center">
                      <UIcon name="i-heroicons-cube-transparent" class="h-3.5 w-3.5 mr-1 text-indigo-600" />
                      <span>
                        Product slots: 
                        <span 
                          class="font-medium"
                          :class="{
                            'text-red-600': remainingProductLimit <= 0,
                            'text-amber-600': remainingProductLimit > 0 && remainingProductLimit <= 2,
                            'text-emerald-600': remainingProductLimit > 2
                          }"
                        >
                          {{ products.length }}/{{ productLimit }}
                        </span>
                        <button 
                          v-if="remainingProductLimit <= 3"
                          @click="showBuySlotsModal = true" 
                          class="ml-2 inline-flex items-center px-1.5 py-0.5 rounded-sm text-xs bg-emerald-100 text-emerald-700 hover:bg-emerald-200 transition-colors"
                        >
                          <UIcon name="i-heroicons-plus-small" class="h-3 w-3 mr-0.5" />
                          Buy more
                        </button>
                      </span>
                    </div>
                    <span class="text-gray-400">|</span>
                    <span>
                      Last order: {{ lastOrderDate ? formatDate(lastOrderDate) : 'No orders yet' }}
                    </span>
                  </div>
                </div>

                <!-- Pulse Effect at Bottom -->
                <div
                  class="h-1 bg-gradient-to-r from-emerald-500 via-teal-500 to-emerald-500 bg-[length:200%_100%] animate-gradient-x"
                ></div>
              </div>
            </Transition>
          </div>
          <!-- Premium Tabs -->
          <div class="bg-white rounded-xl shadow-sm overflow-hidden mb-4">
            <div class="flex border-b border-gray-100">
              <button
                v-for="tab in tabs"
                :key="tab.id"
                @click="tab.disabled ? showProductLimitModal = true : activeTab = tab.id"
                class="relative flex-1 flex items-center justify-center py-5 px-4 text-sm font-medium transition-all duration-200 overflow-hidden"
                :class="[
                  activeTab === tab.id
                    ? 'text-indigo-600 bg-gray-200'
                    : tab.disabled
                    ? 'text-gray-400 bg-gray-50 cursor-not-allowed'
                    : 'text-gray-600 hover:text-gray-800 hover:bg-gray-50',
                ]"
              >
                <div class="flex items-center space-x-2">
                  <component
                    :is="tab.icon"
                    :class="[
                      'h-5 w-5 transition-transform duration-300',
                      activeTab === tab.id
                        ? 'text-indigo-600 scale-110'
                        : tab.disabled
                        ? 'text-gray-400'
                        : 'text-gray-600',
                    ]"
                  />
                  <span>{{ tab.name }}</span>
                  <UIcon
                    v-if="tab.disabled"
                    name="i-heroicons-lock-closed"
                    class="h-3.5 w-3.5 text-gray-400 ml-1"
                  />
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
              activeTab === 'add-product' ? '' : 'bg-white shadow-sm rounded-xl'
            "
          >
            <CommonMyOrdersTab v-if="activeTab === 'orders'" />

            <CommonMyProductsTab v-if="activeTab === 'products'" />
          </div>
          <!-- Add New Product Tab -->
          <div
            v-if="activeTab === 'add-product'"
            class="text-center text-gray-600"
          >
            <CommonAddProductTab v-if="products.length < productLimit" />
            <div
              v-else
              class="bg-white rounded-lg shadow-sm p-8 flex flex-col items-center"
            >
              <div class="bg-red-50 p-3 rounded-full mb-4">
                <UIcon name="i-heroicons-exclamation-triangle" class="h-8 w-8 text-red-400" />
              </div>
              <h3 class="text-lg font-medium text-gray-800 mb-2">
                Product Limit Reached
              </h3>                <p class="text-gray-600 max-w-md mx-auto mb-6">
                You have reached the maximum limit of {{ productLimit }} products
                for your shop. You can buy additional product slots to list more products.
              </p>
              <div class="flex space-x-4">
                <UButton
                  color="primary"
                  @click="showBuySlotsModal = true"
                  icon="i-heroicons-shopping-cart"
                  class="bg-gradient-to-r from-emerald-500 to-emerald-600 hover:from-emerald-600 hover:to-emerald-700"
                >
                  Buy More Product Slots
                </UButton>
                <UButton
                  color="gray"
                  variant="ghost"
                  @click="activeTab = 'products'"
                  icon="i-heroicons-arrow-left"
                >
                  Back to My Products
                </UButton>
              </div>
            </div>
          </div>
        </div>
      </div>
    </UContainer>

    <!-- Edit Product Modal -->
    <div
      v-if="showEditProductModal"
      class="fixed inset-0 z-10 overflow-y-auto"
      aria-labelledby="modal-title"
      role="dialog"
      aria-modal="true"
    >
      <div
        class="flex items-end justify-center min-h-screen pt-4 pb-20 text-center sm:block sm:p-0"
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
          class="inline-block align-bottom bg-white rounded-xl text-left overflow-hidden shadow-sm transform transition-all sm:my-8 sm:align-middle sm:max-w-lg sm:w-full animate-slide-up"
        >
          <div
            class="absolute top-0 left-0 right-0 h-1 bg-gradient-to-r from-indigo-400 via-purple-500 to-indigo-600"
          ></div>
          <div
            class="px-6 py-5 border-b border-gray-200 flex justify-between items-center"
          >
            <h3
              class="text-xl font-semibold text-gray-800 flex items-center"
              id="modal-title"
            >
              <Edit2 class="h-5 w-5 mr-2 text-indigo-600" />
              Edit Product
            </h3>
            <button
              @click="showEditProductModal = false"
              class="text-gray-600 hover:text-gray-600 transition-colors duration-150"
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
                    class="block text-sm font-medium text-gray-800"
                    >Product Name</label
                  >
                  <input
                    type="text"
                    id="product-name"
                    v-model="editingProduct.name"
                    class="mt-1 block w-full border-gray-300 rounded-md shadow-sm sm:text-sm focus:outline-none px-2 py-1"
                    required
                  />
                </div>
                <div>
                  <label
                    for="product-description"
                    class="block text-sm font-medium text-gray-800"
                    >Description</label
                  >
                  <textarea
                    id="product-description"
                    v-model="editingProduct.description"
                    rows="3"
                    class="mt-1 block w-full border-gray-300 rounded-md shadow-sm sm:text-sm"
                  ></textarea>
                </div>
                <div class="grid grid-cols-2 gap-4">
                  <div>
                    <label
                      for="product-price"
                      class="block text-sm font-medium text-gray-800"
                      >Price (৳)</label
                    >
                    <input
                      type="number"
                      id="product-price"
                      v-model.number="editingProduct.price"
                      min="0"
                      step="0.01"
                      class="mt-1 block w-full border-gray-300 rounded-md shadow-sm sm:text-sm focus:outline-none px-2 py-1"
                      required
                    />
                  </div>
                  <div>
                    <label
                      for="product-stock"
                      class="block text-sm font-medium text-gray-800"
                      >Stock</label
                    >
                    <input
                      type="number"
                      id="product-stock"
                      v-model.number="editingProduct.stock"
                      min="0"
                      class="mt-1 block w-full border-gray-300 rounded-md shadow-sm sm:text-sm focus:outline-none px-2 py-1"
                      required
                    />
                  </div>
                </div>
                <div>
                  <label
                    for="product-status"
                    class="block text-sm font-medium text-gray-800"
                    >Status</label
                  >
                  <select
                    id="product-status"
                    v-model="editingProduct.status"
                    class="mt-1 block w-full border-gray-300 rounded-md shadow-sm sm:text-sm"
                  >
                    <option value="active">Active</option>
                    <option value="inactive">Inactive</option>
                    <option value="out-of-stock">Out of Stock</option>
                  </select>
                </div>
                <div>
                  <label
                    for="product-image"
                    class="block text-sm font-medium text-gray-800"
                    >Image URL</label
                  >
                  <input
                    type="text"
                    id="product-image"
                    v-model="editingProduct.image"
                    class="mt-1 block w-full border-gray-300 rounded-md shadow-sm sm:text-sm focus:outline-none px-2 py-1"
                  />
                  <div class="mt-2">
                    <img
                      :src="editingProduct.image"
                      alt="Product preview"
                      class="h-32 w-32 object-contain rounded-md border border-gray-200"
                    />
                  </div>
                </div>
              </div>
            </form>
          </div>
          <div class="bg-gray-50 px-6 py-4 flex justify-end space-x-3">
            <button
              @click="saveProductChanges"
              class="inline-flex justify-center items-center rounded-md border border-transparent shadow-sm px-4 py-2 bg-gradient-to-r from-indigo-500 to-indigo-600 text-base font-medium text-white hover:from-indigo-600 hover:to-indigo-700 focus:outline-none sm:text-sm transition-all duration-200 transform hover:-translate-y-0.5"
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
              class="inline-flex justify-center items-center rounded-md border border-gray-300 shadow-sm px-4 py-2 bg-white text-base font-medium text-gray-800 hover:bg-gray-50 focus:outline-none sm:text-sm transition-colors duration-200"
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
        class="flex items-end justify-center min-h-screen pt-4 pb-20 text-center sm:block sm:p-0"
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
          class="inline-block align-bottom bg-white rounded-xl text-left overflow-hidden shadow-sm transform transition-all sm:my-8 sm:align-middle sm:max-w-lg sm:w-full animate-slide-up"
        >
          <div
            class="absolute top-0 left-0 right-0 h-1 bg-gradient-to-r from-red-400 to-red-600"
          ></div>
          <div
            class="px-6 py-5 border-b border-gray-200 flex justify-between items-center"
          >
            <h3
              class="text-xl font-semibold text-gray-800 flex items-center"
              id="modal-title"
            >
              <AlertTriangle class="h-5 w-5 mr-2 text-red-500" />
              Confirm Deletion
            </h3>
            <button
              @click="showDeleteConfirmModal = false"
              class="text-gray-600 hover:text-gray-600 transition-colors duration-150"
            >
              <X class="h-6 w-6" />
            </button>
          </div>
          <div class="px-6 py-4">
            <p class="text-gray-800">
              Are you sure you want to delete the product
              <span class="font-medium">{{ selectedProduct?.name }}</span
              >? This action cannot be undone.
            </p>
          </div>
          <div class="bg-gray-50 px-6 py-4 flex justify-end space-x-3">
            <button
              @click="deleteProduct"
              class="inline-flex justify-center items-center rounded-md border border-transparent shadow-sm px-4 py-2 bg-gradient-to-r from-red-500 to-red-600 text-base font-medium text-white hover:from-red-600 hover:to-red-700 focus:outline-none sm:text-sm transition-all duration-200 transform hover:-translate-y-0.5"
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
              class="inline-flex justify-center items-center rounded-md border border-gray-300 shadow-sm px-4 py-2 bg-white text-base font-medium text-gray-800 hover:bg-gray-50 focus:outline-none sm:text-sm transition-colors duration-200"
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
        class="flex items-end justify-center min-h-screen pt-4 pb-20 text-center sm:block sm:p-0"
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
          class="inline-block align-bottom bg-white rounded-xl text-left overflow-hidden shadow-sm transform transition-all sm:my-8 sm:align-middle sm:max-w-lg sm:w-full animate-slide-up"
        >
          <div
            class="absolute top-0 left-0 right-0 h-1 bg-gradient-to-r from-red-400 to-red-600"
          ></div>
          <div
            class="px-6 py-5 border-b border-gray-200 flex justify-between items-center"
          >
            <h3
              class="text-xl font-semibold text-gray-800 flex items-center"
              id="modal-title"
            >
              <AlertTriangle class="h-5 w-5 mr-2 text-red-500" />
              Confirm Order Cancellation
            </h3>
            <button
              @click="showCancelOrderModal = false"
              class="text-gray-600 hover:text-gray-600 transition-colors duration-150"
            >
              <X class="h-6 w-6" />
            </button>
          </div>
          <div class="px-6 py-4">
            <p class="text-gray-800 mb-4">
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
              class="inline-flex justify-center items-center rounded-md border border-transparent shadow-sm px-4 py-2 bg-gradient-to-r from-red-500 to-red-600 text-base font-medium text-white hover:from-red-600 hover:to-red-700 focus:outline-none sm:text-sm transition-all duration-200 transform hover:-translate-y-0.5"
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
              class="inline-flex justify-center items-center rounded-md border border-gray-300 shadow-sm px-4 py-2 bg-white text-base font-medium text-gray-800 hover:bg-gray-50 focus:outline-none sm:text-sm transition-colors duration-200"
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
          class="mb-3 p-4 rounded-lg shadow-sm flex items-start max-w-md transform transition-all duration-300"
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
            class="ml-4 text-gray-600 hover:text-gray-600"
          >
            <X class="h-4 w-4" />
          </button>
        </div>
      </transition-group>
    </div>

    <!-- Product Limit Modal -->
    <UModal v-model="showProductLimitModal">
      <div class="bg-white rounded-xl shadow-sm overflow-hidden max-w-md">
        <!-- Premium gradient header -->
        <div class="bg-gradient-to-r from-red-500 via-orange-400 to-amber-500 p-6 text-white relative overflow-hidden">
          <!-- Decorative elements -->
          <div class="absolute -left-4 -top-4 h-16 w-16 rounded-full bg-white/10 blur-xl"></div>
          <div class="absolute -right-4 -bottom-4 h-16 w-16 rounded-full bg-white/10 blur-xl"></div>
          
          <div class="flex items-center justify-center mb-2 relative z-10">
            <div class="bg-white/20 p-3 rounded-full backdrop-blur-sm">
              <UIcon name="i-heroicons-shield-exclamation" class="h-8 w-8 text-white" />
            </div>
          </div>
          <h3 class="text-xl font-semibold text-center text-white mb-1 relative z-10">
            Product Limit Reached
          </h3>
          <p class="text-sm text-center text-white/90 relative z-10">
            Your store has reached the maximum limit
          </p>
        </div>
        
        <div class="p-6">
          <div class="flex items-center mb-6 bg-amber-50 rounded-lg p-4">
            <UIcon name="i-heroicons-information-circle" class="h-5 w-5 text-amber-600 mr-3 flex-shrink-0" />
            <p class="text-sm text-amber-800">
              Your shop currently has <span class="font-semibold text-amber-900">{{ products.length }}</span> products, 
              which is the maximum allowed limit of <span class="font-semibold text-amber-900">{{ productLimit }}</span>.
            </p>
          </div>
            <p class="text-gray-600 text-center mb-6">
            You can increase your product capacity by purchasing additional product slots. Each slot allows you to list one more product in your store.
          </p>
            <div class="flex flex-col sm:flex-row gap-4 w-full">
            <UButton
              color="primary"
              icon="i-heroicons-shopping-cart"
              @click="showBuySlotsModal = true; showProductLimitModal = false"
              class="flex-1 bg-gradient-to-r from-emerald-500 to-emerald-600 hover:from-emerald-600 hover:to-emerald-700"
            >
              Buy More Product Slots
            </UButton>
            <UButton
              color="gray"
              variant="outline"
              @click="showProductLimitModal = false"
              class="flex-1"
            >
              Close
            </UButton>
          </div>
          
          <div class="mt-6 border-t border-gray-100 pt-4">
            <div class="flex justify-center">
              <NuxtLink to="/upgrade-to-pro" class="text-xs text-indigo-600 hover:text-indigo-800 flex items-center transition-colors">
                <UIcon name="i-heroicons-arrow-up-circle" class="h-3.5 w-3.5 mr-1" />
                Learn about our premium shop features
              </NuxtLink>
            </div>
          </div>
        </div>
      </div>
    </UModal>

    <!-- Buy More Slots Modal -->
    <UModal v-model="showBuySlotsModal">
      <div class="bg-white rounded-xl shadow-sm overflow-hidden max-w-md">
        <!-- Header -->
        <div class="bg-gradient-to-r from-emerald-600 to-emerald-500 p-6 text-white relative overflow-hidden">
          <!-- Decorative elements -->
          <div class="absolute -left-4 -top-4 h-16 w-16 rounded-full bg-white/10 blur-xl"></div>
          <div class="absolute -right-4 -bottom-4 h-16 w-16 rounded-full bg-white/10 blur-xl"></div>
          
          <div class="flex items-center justify-center mb-2 relative z-10">
            <div class="bg-white/20 p-3 rounded-full backdrop-blur-sm">
              <UIcon name="i-heroicons-shopping-bag-plus" class="h-8 w-8 text-white" />
            </div>
          </div>
          <h3 class="text-xl font-semibold text-center text-white mb-1 relative z-10">
            Buy Additional Product Slots
          </h3>
          <p class="text-sm text-center text-white/90 relative z-10">
            Expand your store capacity
          </p>
        </div>
        
        <div class="p-6">
          <!-- Current slots info -->
          <div class="flex items-center mb-6 bg-emerald-50 rounded-lg p-4">
            <UIcon name="i-heroicons-information-circle" class="h-5 w-5 text-emerald-600 mr-3 flex-shrink-0" />
            <p class="text-sm text-emerald-800">
              Your shop currently has <span class="font-semibold">{{ products.length }}/{{ productLimit }}</span> product slots used.
              You need more slots to add additional products.
            </p>
          </div>
          
          <!-- Slot package selection -->
          <div class="space-y-4 mb-6">
            <h4 class="text-gray-700 font-medium">Select Package:</h4>
            
            <div class="grid gap-3">
              <label class="relative flex cursor-pointer rounded-lg border bg-white p-4 shadow-sm focus:outline-none hover:border-emerald-500 transition-all"
                :class="{'border-emerald-500 ring-2 ring-emerald-500 ring-opacity-30': selectedSlotPackage === 5}"
              >
                <input 
                  type="radio" 
                  name="slot-package" 
                  value="5"
                  v-model="selectedSlotPackage"
                  class="sr-only" 
                />
                <span class="flex flex-1">
                  <span class="flex flex-col">
                    <span class="block font-medium text-gray-900">5 Additional Slots</span>
                    <span class="mt-1 flex items-center text-sm text-gray-500">
                      <UIcon name="i-heroicons-shopping-bag" class="h-3.5 w-3.5 mr-1.5 text-emerald-500" />
                      Add 5 more product listings
                    </span>
                    <span class="mt-2 text-emerald-600 font-medium flex items-center">
                      <UIcon name="i-heroicons-tag" class="h-4 w-4 mr-1" /> ৳500
                    </span>
                  </span>
                </span>
                <UIcon 
                  name="i-heroicons-check-circle" 
                  class="h-5 w-5 text-emerald-600"
                  :class="{'opacity-100': selectedSlotPackage === 5, 'opacity-0': selectedSlotPackage !== 5}"
                />
              </label>

              <label class="relative flex cursor-pointer rounded-lg border bg-white p-4 shadow-sm focus:outline-none hover:border-emerald-500 transition-all"
                :class="{'border-emerald-500 ring-2 ring-emerald-500 ring-opacity-30': selectedSlotPackage === 10}"
              >
                <input 
                  type="radio" 
                  name="slot-package" 
                  value="10"
                  v-model="selectedSlotPackage"
                  class="sr-only" 
                />
                <span class="flex flex-1">
                  <span class="flex flex-col">
                    <span class="block font-medium text-gray-900">10 Additional Slots</span>
                    <span class="mt-1 flex items-center text-sm text-gray-500">
                      <UIcon name="i-heroicons-shopping-bag" class="h-3.5 w-3.5 mr-1.5 text-emerald-500" />
                      Add 10 more product listings
                    </span>
                    <span class="mt-2 text-emerald-600 font-medium flex items-center">
                      <UIcon name="i-heroicons-tag" class="h-4 w-4 mr-1" /> ৳900 
                      <span class="text-xs text-gray-500 line-through ml-2">৳1000</span>
                      <span class="text-xs bg-emerald-100 text-emerald-800 ml-2 px-1.5 py-0.5 rounded">Save 10%</span>
                    </span>
                  </span>
                </span>
                <UIcon 
                  name="i-heroicons-check-circle" 
                  class="h-5 w-5 text-emerald-600"
                  :class="{'opacity-100': selectedSlotPackage === 10, 'opacity-0': selectedSlotPackage !== 10}"
                />
              </label>

              <label class="relative flex cursor-pointer rounded-lg border bg-white p-4 shadow-sm focus:outline-none hover:border-emerald-500 transition-all"
                :class="{'border-emerald-500 ring-2 ring-emerald-500 ring-opacity-30': selectedSlotPackage === 20}"
              >
                <input 
                  type="radio" 
                  name="slot-package" 
                  value="20"
                  v-model="selectedSlotPackage"
                  class="sr-only" 
                />
                <span class="flex flex-1">
                  <span class="flex flex-col">
                    <span class="block font-medium text-gray-900">
                      20 Additional Slots
                      <span class="ml-2 text-xs bg-indigo-100 text-indigo-800 px-1.5 py-0.5 rounded">BEST VALUE</span>
                    </span>
                    <span class="mt-1 flex items-center text-sm text-gray-500">
                      <UIcon name="i-heroicons-shopping-bag" class="h-3.5 w-3.5 mr-1.5 text-emerald-500" />
                      Add 20 more product listings
                    </span>
                    <span class="mt-2 text-emerald-600 font-medium flex items-center">
                      <UIcon name="i-heroicons-tag" class="h-4 w-4 mr-1" /> ৳1600 
                      <span class="text-xs text-gray-500 line-through ml-2">৳2000</span>
                      <span class="text-xs bg-emerald-100 text-emerald-800 ml-2 px-1.5 py-0.5 rounded">Save 20%</span>
                    </span>
                  </span>
                </span>
                <UIcon 
                  name="i-heroicons-check-circle" 
                  class="h-5 w-5 text-emerald-600"
                  :class="{'opacity-100': selectedSlotPackage === 20, 'opacity-0': selectedSlotPackage !== 20}"
                />
              </label>
            </div>
          </div>

          <!-- Account balance -->
          <div class="bg-gray-50 p-4 rounded-lg flex justify-between items-center mb-6">
            <div>
              <p class="text-sm font-medium text-gray-700">Your Account Balance</p>
              <p class="text-lg font-semibold text-gray-900">৳{{ user?.user?.balance || 0 }}</p>
            </div>
            <NuxtLink to="/add-funds" class="text-xs text-indigo-600 hover:text-indigo-800 flex items-center">
              <UIcon name="i-heroicons-plus-circle" class="h-3.5 w-3.5 mr-1" />
              Add Funds
            </NuxtLink>
          </div>          <!-- Insufficient balance warning -->
          <div v-if="(selectedSlotPackage === 5 && user?.user?.balance < 500) || 
                     (selectedSlotPackage === 10 && user?.user?.balance < 900) || 
                     (selectedSlotPackage === 20 && user?.user?.balance < 1600)"
               class="bg-red-50 border border-red-100 rounded-lg p-3 mb-6 text-sm text-red-800 flex items-start">
            <UIcon name="i-heroicons-exclamation-circle" class="h-5 w-5 text-red-500 mr-2 flex-shrink-0" />
            <div>
              <p class="mb-1">
                You have insufficient balance to purchase this package. Please add funds to your account.
              </p>
              <NuxtLink to="/add-funds" class="text-red-600 hover:text-red-800 flex items-center font-medium text-xs">
                <UIcon name="i-heroicons-plus-circle" class="h-3.5 w-3.5 mr-1" />
                Add Funds to Your Account
              </NuxtLink>
            </div>
          </div>

          <div class="flex flex-col sm:flex-row gap-4 w-full">
            <UButton
              color="primary"
              icon="i-heroicons-shopping-cart"
              @click="purchaseProductSlots"
              class="flex-1 bg-gradient-to-r from-emerald-500 to-emerald-600 hover:from-emerald-600 hover:to-emerald-700"
              :disabled="(selectedSlotPackage === 5 && user?.user?.balance < 500) || 
                         (selectedSlotPackage === 10 && user?.user?.balance < 900) || 
                         (selectedSlotPackage === 20 && user?.user?.balance < 1600) ||
                         isPurchasing"
              :loading="isPurchasing"
            >
              {{ isPurchasing ? 'Processing...' : 'Purchase Now' }}
            </UButton>
            <UButton
              color="gray"
              variant="outline"
              @click="showBuySlotsModal = false"
              class="flex-1"
            >
              Cancel
            </UButton>
          </div>
        </div>
      </div>
    </UModal>
  </div>
</template>

<script setup>
definePageMeta({
  layout: "dashboard",
});
const { user, jwtLogin } = useAuth();
const { get, patch, post } = useApi();
const { formatDate } = useUtils();
import {
  ShoppingBag,
  ShoppingCart,
  PlusCircle,
  Edit2,
  Trash2,
  X,
  Save,
  AlertTriangle,
  CircleCheck,
  XCircle,
  Loader2,
  CheckCircle,
  AlertCircle,
  Info,
  Crown as CrownIcon,
  Sparkles as SparklesIcon,
} from "lucide-vue-next";

// Tab state
const activeTab = ref("orders");

// Product limit configuration (dynamic from user data)
const productLimit = computed(() => user.value?.user?.product_limit || 10);
const remainingProductLimit = computed(() => productLimit.value - products.value.length);

// Tabs configuration
const tabs = computed(() => [
  {
    id: "orders",
    name: "My Orders",
    icon: ShoppingBag,
  },
  {
    id: "products",
    name: "My Products",
    icon: ShoppingCart,
  },  {
    id: "add-product",
    name: "Add New Product",
    icon: PlusCircle,
    disabled: products.value.length >= productLimit.value
  },
]);

// UI state
const showEditProductModal = ref(false);
const showDeleteConfirmModal = ref(false);
const showCancelOrderModal = ref(false);
const isProcessing = ref(false);
const showProductLimitModal = ref(false);
const showBuySlotsModal = ref(false); // State for Buy Slots modal

// Watch for active tab changes to handle product limit
watch(activeTab, (newTab) => {
  // Check if trying to access the add-product tab and product limit is reached
  if (newTab === 'add-product' && products.value.length >= productLimit.value) {
    activeTab.value = 'products'; // Redirect to products tab
    showProductLimitModal.value = true; // Show limit reached modal
  }
});

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

// Data fetching
const orders = ref([]);
const isOrdersLoading = ref(false);

async function getOrders() {
  isOrdersLoading.value = true;
  try {
    const res = await get("/seller-orders/");
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

// Helper functions for orders
function formatAmount(amount) {
  if (amount === undefined || amount === null) return "0.00";
  return parseFloat(amount).toFixed(2);
}

// Order status computed properties
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

// Computed property to get the most recent order date
const lastOrderDate = computed(() => {
  if (orders.value.length === 0) {
    return null;
  }
  
  // Find the most recent order by created_at date
  const sortedOrders = [...orders.value].sort((a, b) => 
    new Date(b.created_at) - new Date(a.created_at)
  );
  
  return new Date(sortedOrders[0].created_at);
});

// Products management
const products = ref([]);

async function getProducts() {
  try {
    const res = await get("/my-products/");
    if (res && res.data) {
      products.value = res.data;
      console.log(`Loaded ${products.value.length} products`);      // Check product limit and show notification if close to limit
      if (products.value.length >= productLimit.value) {
        showToast(
          "info",
          "Product Limit Reached",
          `You've reached the maximum limit of ${productLimit.value} products for your shop. Delete an existing product or buy additional product slots.`
        );
      } else if (products.value.length >= productLimit.value - 2) {
        // Show warning when approaching limit (within 2 products)
        showToast(
          "warning",
          "Approaching Product Limit",
          `You can add ${productLimit.value - products.value.length} more product(s) before reaching your shop's limit. Consider buying additional slots.`
        );
      }
    } else {
      console.warn("No product data received");
      products.value = [];
    }
  } catch (error) {
    console.error("Error fetching products:", error);
    showToast(
      "error",
      "Error loading products",
      "Could not load your products. Please try again later."
    );
    products.value = [];
  }
}

function handleReload() {
  jwtLogin();
}

// Product summary computed properties
const activeProducts = computed(() => {
  return products.value.filter((product) => product.status === "active");
});

// Toast methods
const toasts = ref([]);
let toastId = 0;

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

const isEditing = ref(false);
const isStoreDetailsCollapsed = ref(true); // State for collapsible store details - starts closed by default
const editedUser = reactive({
  store_name: user.value?.user?.store_name || "",
  store_username: user.value?.user?.store_username || "",
  store_address: user.value?.user?.store_address || "",
  store_description: user.value?.user?.store_description || "",
});

// Copy to clipboard functionality
const copied = ref(false);

// Toggle store details visibility
function toggleStoreDetails() {
  isStoreDetailsCollapsed.value = !isStoreDetailsCollapsed.value;
}

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

const storeDetails = ref({
  store_name: "",
  store_username: "",
  store_address: "",
  store_description: "",
  store_logo: "",
  store_banner: "",
});
const toast = useToast();
const isLoading = ref(false);

async function getStoreDetails() {
  isLoading.value = true;
  try {
    // Check if user and store_username exist
    if (!user.value?.user?.store_username) {
      console.warn("No store username available");
      return;
    }

    const { data } = await get(`/store/${user.value.user.store_username}/`);
    if (data) {
      storeDetails.value = data;
      console.log("Store details loaded successfully");

      // Also update the edited user object for consistency
      editedUser.store_name = data.store_name || "";
      editedUser.store_address = data.store_address || "";
      editedUser.store_description = data.store_description || "";
    }
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

async function updateStoreInfo() {
  try {
    const { data } = await patch(`/store/${user.value.user.store_username}/`, {
      store_name: editedUser.store_name,
      store_address: editedUser.store_address,
      store_description: editedUser.store_description,
    });
    if (data) {
      getStoreDetails(); 
    }
  } catch (error) {
    console.log(error);
  }
}

// Initialize data on mount
onMounted(async () => {
  try {
    await Promise.allSettled([getStoreDetails(), getProducts(), getOrders()]);
    console.log("All data loading attempts completed");
  } catch (error) {
    console.error("Error during initialization:", error);
  }
});

// Purchase product slots
const selectedSlotPackage = ref(5); // Default to 5 slots package
const isPurchasing = ref(false);

async function purchaseProductSlots() {
  isPurchasing.value = true;
  try {
    // Calculate the cost based on the selected package
    let cost = 0;
    if (selectedSlotPackage.value === 5) {
      cost = 500;
    } else if (selectedSlotPackage.value === 10) {
      cost = 900;
    } else if (selectedSlotPackage.value === 20) {
      cost = 1600;
    }

    // Check if user has enough balance
    if (user.value?.user?.balance < cost) {
      showToast(
        "error",
        "Insufficient Balance",
        `You need ৳${cost} to purchase this package. Please add funds to your account.`
      );
      return;
    }

    // Make API call to purchase slots
    const { data } = await post('/purchase-product-slots/', {
      slot_count: selectedSlotPackage.value,
      cost
    });

    if (data && data.success) {
      // Update user's product limit and balance
      user.value.user.product_limit += selectedSlotPackage.value;
      user.value.user.balance -= cost;
      
      showToast(
        "success",
        "Purchase Successful",
        `You have successfully purchased ${selectedSlotPackage.value} additional product slot${
          selectedSlotPackage.value > 1 ? "s" : ""
        } for ৳${cost}.`
      );

      // Close modal
      showBuySlotsModal.value = false;
    } else {
      throw new Error(data?.message || 'Purchase failed');
    }
  } catch (error) {
    console.error("Error purchasing product slots:", error);
    showToast("error", "Purchase Failed", "Could not complete the purchase. Please try again.");
  } finally {
    isPurchasing.value = false;
  }
}
</script>

<style scoped>
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