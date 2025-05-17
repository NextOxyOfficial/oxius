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
                v-if="!isEditing"
                @click="isEditing = true"
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
                @click="(isEditing = false), updateStoreInfo()"
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
                    class="text-sm font-semibold text-gray-700 w-full border-b border-emerald-200 focus:outline-none px-2 py-1"
                  />
                  <p
                    v-else
                    class="text-sm font-semibold text-gray-700 truncate"
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
                  <p class="text-xs font-medium text-gray-500 mb-1">
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
                        <p class="text-xs text-gray-500 whitespace-nowrap">
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
                        class="ml-1.5 text-gray-500 hover:text-emerald-600 transition-colors flex-shrink-0"
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
                  <p class="text-xs text-gray-500 mt-1 italic">
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
                    class="text-sm font-semibold text-gray-700 w-full border-b border-emerald-200 focus:outline-none px-2 py-1"
                  />
                  <p
                    v-else
                    class="text-sm font-semibold text-gray-700 truncate"
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
                  <p class="text-xs font-medium text-gray-500 mb-1">
                    Description
                  </p>
                  <textarea
                    v-if="isEditing"
                    v-model="editedUser.store_description"
                    rows="2"
                    class="text-sm text-gray-700 w-full border border-emerald-200 rounded focus:outline-none py-1 px-2 resize-none"
                  ></textarea>
                  <p v-else class="text-sm text-gray-700 line-clamp-2">
                    {{
                      storeDetails?.store_description ||
                      "No description available"
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
                <span class="text-xs text-gray-500">Store Active</span>
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
          <div class="bg-white rounded-xl shadow-sm overflow-hidden mb-4">
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
                        : 'text-gray-500',
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
              activeTab === 'add-product' ? '' : 'bg-white shadow-sm rounded-xl'
            "
          >
            <CommonMyOrdersTab v-if="activeTab === 'orders'" />

            <CommonMyProductsTab v-if="activeTab === 'products'" />
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
              class="text-xl font-semibold text-gray-700 flex items-center"
              id="modal-title"
            >
              <Edit2 class="h-5 w-5 mr-2 text-indigo-600" />
              Edit Product
            </h3>
            <button
              @click="showEditProductModal = false"
              class="text-gray-500 hover:text-gray-500 transition-colors duration-150"
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
                    class="mt-1 block w-full border-gray-300 rounded-md shadow-sm sm:text-sm focus:outline-none px-2 py-1"
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
                    class="mt-1 block w-full border-gray-300 rounded-md shadow-sm sm:text-sm"
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
                      class="mt-1 block w-full border-gray-300 rounded-md shadow-sm sm:text-sm focus:outline-none px-2 py-1"
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
                      class="mt-1 block w-full border-gray-300 rounded-md shadow-sm sm:text-sm focus:outline-none px-2 py-1"
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
                    class="block text-sm font-medium text-gray-700"
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
              class="inline-flex justify-center items-center rounded-md border border-gray-300 shadow-sm px-4 py-2 bg-white text-base font-medium text-gray-700 hover:bg-gray-50 focus:outline-none sm:text-sm transition-colors duration-200"
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
              class="text-xl font-semibold text-gray-700 flex items-center"
              id="modal-title"
            >
              <AlertTriangle class="h-5 w-5 mr-2 text-red-500" />
              Confirm Deletion
            </h3>
            <button
              @click="showDeleteConfirmModal = false"
              class="text-gray-500 hover:text-gray-500 transition-colors duration-150"
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
              class="inline-flex justify-center items-center rounded-md border border-gray-300 shadow-sm px-4 py-2 bg-white text-base font-medium text-gray-700 hover:bg-gray-50 focus:outline-none sm:text-sm transition-colors duration-200"
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
              class="text-xl font-semibold text-gray-700 flex items-center"
              id="modal-title"
            >
              <AlertTriangle class="h-5 w-5 mr-2 text-red-500" />
              Confirm Order Cancellation
            </h3>
            <button
              @click="showCancelOrderModal = false"
              class="text-gray-500 hover:text-gray-500 transition-colors duration-150"
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
              class="inline-flex justify-center items-center rounded-md border border-gray-300 shadow-sm px-4 py-2 bg-white text-base font-medium text-gray-700 hover:bg-gray-50 focus:outline-none sm:text-sm transition-colors duration-200"
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
            class="ml-4 text-gray-500 hover:text-gray-500"
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
const { user, jwtLogin } = useAuth();
const { get, patch } = useApi();
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
const showEditProductModal = ref(false);
const showDeleteConfirmModal = ref(false);
const showCancelOrderModal = ref(false);
const isProcessing = ref(false);

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

// Products management
const products = ref([]);

async function getProducts() {
  try {
    const res = await get("/my-products/");
    if (res && res.data) {
      products.value = res.data;
      console.log(`Loaded ${products.value.length} products`);
    } else {
      console.warn("No product data received");
      products.value = [];
    }
  } catch (error) {
    console.error("Error fetching products:", error);
    toast.add({
      title: "Error loading products",
      description: "Could not load your products. Please try again later.",
      color: "red",
    });
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
const editedUser = reactive({
  store_name: user.value?.user?.store_name || "",
  store_username: user.value?.user?.store_username || "",
  store_address: user.value?.user?.store_address || "",
  store_description: user.value?.user?.store_description || "",
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
