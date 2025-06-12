<template>
  <div class="animate-fade-in">
    <!-- Order Summary Cards -->
    <div
      class="grid grid-cols-2 md:grid-cols-4 gap-2 p-2 bg-gray-50 border-b border-gray-200"
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
            class="h-6 w-6 animate-spin text-gray-600"
          />
        </div>        <div class="flex items-center justify-between">
          <div>
            <p class="text-sm font-medium text-gray-600">Total Orders</p>
            <p class="text-xl font-semibold text-gray-800">
              {{ orderStats.total }}
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
          ৳{{ formatAmount(orderStats.total_amount) }}
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
            class="h-6 w-6 animate-spin text-gray-600"
          />
        </div>        <div class="flex items-center justify-between">
          <div>
            <p class="text-sm font-medium text-gray-600">Pending Orders</p>
            <p class="text-xl font-semibold text-gray-800">
              {{ orderStats.pending }}
            </p>
          </div>
          <div
            class="h-12 w-12 rounded-full bg-yellow-50 flex items-center justify-center"
          >
            <UIcon name="i-heroicons-clock" class="h-6 w-6 text-yellow-500" />
          </div>
        </div>
        <p class="mt-2 text-sm font-medium text-yellow-600">
          ৳{{ formatAmount(orderStats.pending_amount) }}
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
            class="h-6 w-6 animate-spin text-gray-600"
          />
        </div>        <div class="flex items-center justify-between">
          <div>
            <p class="text-sm font-medium text-gray-600">Processing Orders</p>
            <p class="text-xl font-semibold text-gray-800">
              {{ orderStats.processing }}
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
          ৳{{ formatAmount(orderStats.processing_amount) }}
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
            class="h-6 w-6 animate-spin text-gray-600"
          />
        </div>        <div class="flex items-center justify-between">
          <div>
            <p class="text-sm font-medium text-gray-600">Delivered Orders</p>
            <p class="text-xl font-semibold text-gray-800">
              {{ orderStats.delivered }}
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
          ৳{{ formatAmount(orderStats.delivered_amount) }}
        </p>
      </div>
    </div>

    <div class="px-6 py-5 border-b border-gray-200 bg-gray-50">
      <div class="flex flex-col md:flex-row md:items-center md:justify-between">
        <div class="flex items-center space-x-2">
          <ShoppingBag class="h-5 w-5 text-indigo-600" />
          <h2 class="text-xl font-semibold text-gray-800">My Orders</h2>
        </div>
        <div class="mt-3 md:mt-0 flex items-center space-x-4">
          <div class="relative">
            <select
              v-model="orderFilter"
              class="block w-full pl-3 pr-10 py-1.5 text-base border-gray-300 focus:outline-none sm:text-sm rounded-md"
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
              class="block w-full pr-10 py-2 pl-1.5 sm:text-sm border-gray-300 rounded-md focus:outline-none"
            />
            <div
              class="absolute inset-y-0 right-0 pr-3 flex items-center pointer-events-none"
            >
              <Search class="h-5 w-5 text-gray-600" />
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
              class="px-6 py-3 text-left text-xs font-medium text-gray-600 uppercase tracking-wider"
            >
              Order ID
            </th>
            <th
              scope="col"
              class="px-6 py-3 text-left text-xs font-medium text-gray-600 uppercase tracking-wider"
            >
              Status
            </th>
            <th
              scope="col"
              class="px-6 py-3 text-left text-xs font-medium text-gray-600 uppercase tracking-wider"
            >
              Date
            </th>
            <th
              scope="col"
              class="px-6 py-3 text-left text-xs font-medium text-gray-600 uppercase tracking-wider"
            >
              Customer
            </th>
            <th
              scope="col"
              class="px-6 py-3 text-left text-xs font-medium text-gray-600 uppercase tracking-wider"
            >
              Total
            </th>
            <th
              scope="col"
              class="px-6 py-3 text-left text-xs font-medium text-gray-600 uppercase tracking-wider"
            >
              Actions
            </th>
          </tr>
        </thead>
        <tbody class="bg-white divide-y divide-gray-200">
          <tr
            v-for="order in orders"
            :key="order.id"
            class="hover:bg-gray-50 transition-colors duration-150"
          >
            <td class="px-6 py-4 whitespace-nowrap">
              <div class="text-sm font-medium text-indigo-600">
                #{{ order.order_number }}
              </div>
            </td>
            <td class="px-6 py-4 whitespace-nowrap">
              <span
                class="px-2 inline-flex text-xs leading-5 font-semibold rounded-full capitalize"
                :class="getStatusClass(order.order_status)"
              >
                {{ order.order_status }}
              </span>
            </td>
            <td class="px-6 py-4 whitespace-nowrap">
              <div class="text-sm text-gray-800">
                {{ formatDate(order.created_at) }}
              </div>
            </td>
            <td class="px-6 py-4 whitespace-nowrap">
              <div class="text-sm text-gray-800">
                {{ order.name }}
              </div>
              <div class="text-sm text-gray-600">
                {{ order.email }}
              </div>
            </td>
            <td class="px-6 py-4 whitespace-nowrap">
              <div class="text-sm font-medium text-gray-800">
                ৳{{ +order.total + +order.delivery_fee }}
              </div>
            </td>
            <td class="px-6 py-4 whitespace-nowrap text-sm font-medium">
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
                  class="text-gray-600 hover:text-gray-800 transition-colors duration-150 flex items-center"
                >
                  <Printer class="h-4 w-4 mr-1" />
                  Print
                </button>
              </div>
            </td>
          </tr>          <tr v-if="orders.length === 0">
            <td colspan="6" class="px-6 py-10 text-center text-gray-600">
              <div class="flex flex-col items-center justify-center">
                <PackageX class="h-10 w-10 text-gray-400 mb-2" />
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
      <div class="hidden sm:flex-1 sm:flex sm:items-center sm:justify-between">        <div>
          <p class="text-sm text-gray-800">
            Showing
            <span class="font-medium">{{ paginationStart }}</span> to
            <span class="font-medium">{{ paginationEnd }}</span> of
            <span class="font-medium">{{ pagination?.count || 0 }}</span>
            results
          </p>
        </div>
        <div>
          <nav
            class="relative z-0 inline-flex rounded-md shadow-sm -space-x-px"
            aria-label="Pagination"
          >            <button
              @click="prevPage"
              :disabled="currentPage === 1"
              class="relative inline-flex items-center px-2 py-2 rounded-l-md border border-gray-300 bg-white text-sm font-medium text-gray-600 hover:bg-gray-50 disabled:opacity-50 disabled:cursor-not-allowed"
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
                  : 'bg-white text-gray-800 hover:bg-gray-50',
                'relative inline-flex items-center px-4 py-2 border border-gray-300 text-sm font-medium',
              ]"
            >
              {{ page }}
            </button>

            <button
              @click="nextPage"
              :disabled="currentPage === totalPages"
              class="relative inline-flex items-center px-2 py-2 rounded-r-md border border-gray-300 bg-white text-sm font-medium text-gray-600 hover:bg-gray-50 disabled:opacity-50 disabled:cursor-not-allowed"
            >
              <span class="sr-only">Next</span>
              <ChevronRight class="h-5 w-5" />
            </button>
          </nav>
        </div>
      </div>
    </div>
    <!-- Order Details Modal -->
    <UModal
      v-model="showOrderDetailsModal"
      :ui="{
        fullscreen: 'w-full sm:max-w-3xl h-auto',
      }"
      fullscreen
      :prevent-close="showAddItemModal"
    >
      <div
        class="flex items-center justify-center min-h-screen py-20 text-center sm:block"
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
          class="inline-block align-bottom bg-white rounded-xl text-left shadow-sm transform transition-all sm:my-24 sm:align-middle sm:max-w-3xl w-full animate-slide-up overflow-auto"
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
              <ShoppingBag class="h-5 w-5 mr-2 text-indigo-600" />
              Order #{{ selectedOrder?.order_number }}
            </h3>
            <div class="flex items-center space-x-2">
              <button
                @click="printOrder(selectedOrder)"
                class="text-gray-600 hover:text-gray-800 transition-colors duration-150"
                title="Print Order"
              >
                <Printer class="h-5 w-5" />
              </button>
              <button
                @click="showOrderDetailsModal = false"
                class="text-gray-600 hover:text-gray-600 transition-colors duration-150"
              >
                <X class="h-6 w-6" />
              </button>
            </div>
          </div>
          <div class="px-6 py-2">
            <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
              <div>
                <h4
                  class="text-sm font-medium text-gray-600 uppercase tracking-wider mb-3 flex items-center"
                >
                  <FileText class="h-4 w-4 mr-1 text-indigo-500" />
                  Order Information
                </h4>
                <div class="bg-gray-50 rounded-lg p-4">
                  <div class="grid grid-cols-2 gap-4 text-sm">
                    <div>
                      <p class="text-gray-600">Date</p>
                      <p class="font-medium">
                        {{ selectedOrder?.created_at.split("T")[0] }}
                      </p>
                      <p class="text-xs text-gray-600">
                        {{ formatDate(selectedOrder?.created_at) }}
                      </p>
                    </div>
                    <div>
                      <p class="text-gray-600">Status</p>
                      <div class="flex items-center mt-1">
                        <select
                          v-model="editingOrderStatus"
                          class="block w-full pl-2 pr-8 py-1 text-sm border-gray-300 focus:outline-none rounded-md"
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
                      <p class="text-gray-600">Payment Method</p>
                      <p class="font-medium capitalize">
                        {{ selectedOrder?.payment_method }}
                      </p>
                    </div>
                    <div></div>
                  </div>
                </div>
              </div>
              <div>
                <h4
                  class="text-sm font-medium text-gray-600 uppercase tracking-wider mb-3 flex items-center justify-between"
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
                      <p class="text-gray-600">Name</p>
                      <p class="font-medium">{{ selectedOrder?.name }}</p>
                    </div>
                    <div>
                      <p class="text-gray-600">Phone</p>
                      <p class="font-medium">{{ selectedOrder?.phone }}</p>
                    </div>
                    <div>
                      <p class="text-gray-600">Address</p>
                      <p class="font-medium">{{ selectedOrder?.address }}</p>
                    </div>
                  </div>
                  <div v-else class="space-y-3">
                    <div>
                      <label
                        class="block text-xs font-medium text-gray-600 mb-1"
                        >Name</label
                      >
                      <input
                        type="text"
                        v-model="editingCustomer.name"
                        class="block w-full border-gray-300 rounded-md shadow-sm sm:text-sm focus:outline-none px-2 py-1"
                      />
                    </div>
                    <div>
                      <label
                        class="block text-xs font-medium text-gray-600 mb-1"
                        >Email</label
                      >
                      <input
                        type="email"
                        v-model="editingCustomer.email"
                        class="block w-full border-gray-300 rounded-md shadow-sm sm:text-sm focus:outline-none px-2 py-1"
                      />
                    </div>
                    <div>
                      <label
                        class="block text-xs font-medium text-gray-600 mb-1"
                        >Phone</label
                      >
                      <input
                        type="tel"
                        v-model="editingCustomer.phone"
                        class="block w-full border-gray-300 rounded-md shadow-sm sm:text-sm focus:outline-none px-2 py-1"
                      />
                    </div>
                    <div>
                      <label
                        class="block text-xs font-medium text-gray-600 mb-1"
                        >Address</label
                      >
                      <textarea
                        v-model="editingCustomer.address"
                        rows="2"
                        class="block w-full border-gray-300 rounded-md shadow-sm sm:text-sm focus:outline-none px-2 py-1"
                      ></textarea>
                    </div>
                    <div class="flex justify-end">
                      <button
                        @click="saveCustomerChanges"
                        class="inline-flex items-center px-3 py-1.5 border border-transparent text-xs font-medium rounded-md shadow-sm text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none"
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
                class="text-sm font-medium text-gray-600 uppercase tracking-wider mb-3 flex items-center justify-between"
              >
                <div class="flex items-center">
                  <ShoppingCart class="h-4 w-4 mr-1 text-indigo-500" />
                  Order Items
                </div>
                <button
                  @click="handleEditOrderItem"
                  class="text-xs text-indigo-600 hover:text-indigo-800 flex items-center"
                >
                  <Edit2 class="h-3 w-3 mr-1" />
                  {{ editOrderItems ? "Cancel" : "Edit Items" }}
                </button>
              </h4>

              <!-- Edit Mode Indicator -->
              <div
                v-if="editOrderItems"
                class="mb-4 bg-blue-50 border border-blue-200 rounded-lg p-3 flex items-center"
              >
                <UIcon
                  name="i-heroicons-pencil-square"
                  class="h-4 w-4 text-blue-500 mr-2"
                />
                <span class="text-sm text-blue-700 font-medium">
                  Edit Mode Active: You can now modify quantities, remove items,
                  or add new products to this order.
                </span>
              </div>

              <!-- Desktop view for order items -->
              <div
                class="hidden md:block bg-white border border-gray-200 rounded-lg overflow-hidden"
              >
                <table class="min-w-full divide-y divide-gray-200">
                  <thead class="bg-gray-50">
                    <tr>
                      <th
                        scope="col"
                        class="px-6 py-3 text-left text-xs font-medium text-gray-600 uppercase tracking-wider"
                      >
                        Product
                      </th>
                      <th
                        scope="col"
                        class="px-6 py-3 text-left text-xs font-medium text-gray-600 uppercase tracking-wider"
                      >
                        Price
                      </th>
                      <th
                        scope="col"
                        class="px-6 py-3 text-left text-xs font-medium text-gray-600 uppercase tracking-wider"
                      >
                        Quantity
                      </th>
                      <th
                        scope="col"
                        class="px-6 py-3 text-left text-xs font-medium text-gray-600 uppercase tracking-wider"
                      >
                        Total
                      </th>
                      <th
                        v-if="editOrderItems"
                        scope="col"
                        class="px-6 py-3 text-left text-xs font-medium text-gray-600 uppercase tracking-wider"
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
                              v-if="getItemImage(item)"
                              class="h-10 w-10 rounded-md object-contain"
                              :src="getItemImage(item)"
                              :alt="item.product_details?.name || 'Product'"
                            />
                            <div
                              v-else
                              class="h-10 w-10 rounded-md bg-gray-200 flex items-center justify-center"
                            >
                              <svg
                                class="h-6 w-6 text-gray-400"
                                fill="none"
                                stroke="currentColor"
                                viewBox="0 0 24 24"
                              >
                                <path
                                  stroke-linecap="round"
                                  stroke-linejoin="round"
                                  stroke-width="2"
                                  d="M4 16l4.586-4.586a2 2 0 012.828 0L16 16m-2-2l1.586-1.586a2 2 0 012.828 0L20 14m-6-6h.01M6 20h12a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v12a2 2 0 002 2z"
                                ></path>
                              </svg>
                            </div>
                          </div>
                          <div class="ml-4">
                            <div class="text-sm font-medium text-gray-800">
                              {{ item.product_details?.name }}
                            </div>
                          </div>
                        </div>
                      </td>
                      <td class="px-6 py-4 whitespace-nowrap">
                        <div
                          v-if="!editOrderItems"
                          class="text-sm text-gray-800"
                        >
                          ৳{{ item.price }}
                        </div>
                        <input
                          v-else
                          type="number"
                          v-model.number="item.price"
                          min="0"
                          step="0.01"
                          class="block w-24 border-gray-300 rounded-md shadow-sm focus:outline-none sm:text-sm px-2 py-1"
                        />
                      </td>
                      <td class="px-6 py-4 whitespace-nowrap">
                        <div
                          v-if="!editOrderItems"
                          class="text-sm text-gray-800"
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
                            class="mx-1 block w-16 border-gray-300 rounded-md shadow-sm sm:text-sm text-center focus:outline-none px-2 py-1"
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
                        <div class="text-sm font-medium text-gray-800">
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
                    <tr v-if="editOrderItems">
                      <td colspan="5" class="px-6 py-4">
                        <UButton
                          @click="handleShowAddItemModal"
                          color="indigo"
                          variant="outline"
                          icon="i-heroicons-plus"
                          size="sm"
                          :loading="false"
                          class="hover:bg-indigo-50 focus:ring-2 focus:ring-indigo-500 focus:ring-offset-2"
                        >
                          Add Product to Order
                        </UButton>
                      </td>
                    </tr>
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
                    <div
                      class="h-16 w-16 rounded-md overflow-hidden bg-gray-200 flex-shrink-0"
                    >
                      <img
                        v-if="getItemImage(item)"
                        class="h-full w-full object-contain"
                        :src="getItemImage(item)"
                        :alt="item.product_details?.name || 'Product'"
                      />
                      <div
                        v-else
                        class="h-full w-full flex items-center justify-center"
                      >
                        <svg
                          class="h-8 w-8 text-gray-400"
                          fill="none"
                          stroke="currentColor"
                          viewBox="0 0 24 24"
                        >
                          <path
                            stroke-linecap="round"
                            stroke-linejoin="round"
                            stroke-width="2"
                            d="M4 16l4.586-4.586a2 2 0 012.828 0L16 16m-2-2l1.586-1.586a2 2 0 012.828 0L20 14m-6-6h.01M6 20h12a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v12a2 2 0 002 2z"
                          ></path>
                        </svg>
                      </div>
                    </div>
                    <div class="flex-1">
                      <h5 class="font-medium text-gray-800">
                        {{ item.product_details?.name || "Product" }}
                      </h5>
                      <div class="mt-2 grid grid-cols-2 gap-2 text-sm">
                        <div>
                          <span class="text-gray-600">Price:</span>
                          <span v-if="!editOrderItems" class="font-medium"
                            >৳{{ item.price }}</span
                          >
                          <input
                            v-else
                            type="number"
                            v-model.number="item.price"
                            min="0"
                            step="0.01"
                            class="mt-1 block w-full border-gray-300 rounded-md shadow-sm sm:text-sm focus:outline-none px-2 py-1"
                          />
                        </div>
                        <div>
                          <span class="text-gray-600">Quantity:</span>
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
                              class="mx-1 block w-12 border-gray-300 rounded-md shadow-sm sm:text-sm text-center focus:outline-none px-2 py-1"
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
                          <span class="text-gray-600">Total:</span>
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
                <!-- <button
                  v-if="editOrderItems"
                  @click="handleShowAddItemModal"
                  class="inline-flex items-center px-3 py-1.5 border border-gray-300 shadow-sm text-xs font-medium rounded-md text-gray-800 bg-white hover:bg-gray-50 focus:outline-none"
                >
                  <Plus class="h-3 w-3 mr-1.5" />
                  Add Item
                </button> -->
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
                    >৳{{ Number(selectedOrder?.delivery_fee) || 0 }}</span
                  >
                </div>
                <div v-else class="flex items-center">
                  <input
                    type="number"
                    v-model.number="editingDeliveryFee"
                    min="0"
                    class="block w-24 border-gray-300 rounded-md shadow-sm sm:text-sm focus:outline-none px-2 py-1"
                  />
                </div>
              </div>
              <div
                class="flex justify-between items-center pt-2 border-t border-gray-200 mt-2"
              >
                <span class="text-gray-800 font-medium">Total</span>
                <span class="text-lg font-semibold text-indigo-600"
                  >৳{{ calculateTotal() }}</span
                >
              </div>
            </div>
          </div>
          <div class="bg-gray-50 px-6 py-4 flex flex-wrap justify-end gap-3">
            <button
              v-if="editOrderItems"
              @click="saveOrderItemChanges"
              class="inline-flex justify-center items-center rounded-md border border-transparent shadow-sm px-4 py-2 bg-indigo-600 text-base font-medium text-white hover:bg-indigo-700 focus:outline-none sm:text-sm transition-all duration-200"
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
              @click="updateOrderStatus(selectedOrder.id)"
              class="inline-flex justify-center items-center rounded-md border border-transparent shadow-sm px-4 py-2 bg-gradient-to-r from-indigo-500 to-indigo-600 text-base font-medium text-white hover:from-indigo-600 hover:to-indigo-700 focus:outline-none sm:text-sm transition-all duration-200 transform hover:-translate-y-0.5"
              :disabled="isProcessing"
              v-if="!editOrderItems"
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
              class="inline-flex justify-center items-center rounded-md border border-gray-300 shadow-sm px-4 py-2 bg-white text-base font-medium text-gray-800 hover:bg-gray-50 focus:outline-none sm:text-sm transition-colors duration-200"
            >
              <X class="h-4 w-4 mr-1.5" />
              Close
            </button>
          </div>
        </div>
      </div>
    </UModal>

    <!-- DEBUG: Modal State Indicator -->
    <div
      v-if="showAddItemModal"
      class="fixed top-4 right-4 bg-red-500 text-white p-2 rounded z-[9999]"
    >
      DEBUG: showAddItemModal is TRUE
    </div>

    <!-- Add Item Modal -->
    <UModal
      v-model="showAddItemModal"
      :ui="{
        wrapper: 'z-[100]',
        overlay: 'z-[99]',
        modal: 'z-[101]',
      }"
      prevent-close
    >
      <div
        class="bg-white rounded-xl shadow-sm overflow-hidden max-w-lg w-full relative"
      >
        <div
          class="absolute top-0 left-0 right-0 h-1 bg-gradient-to-r from-indigo-400 via-purple-500 to-indigo-600"
        ></div>
        <!-- <div
          class="px-6 py-5 border-b border-gray-200 flex justify-between items-center"
        >
          <h3 class="text-xl font-semibold text-gray-800 flex items-center">
            <UIcon
              name="i-heroicons-shopping-cart"
              class="h-5 w-5 mr-2 text-indigo-600"
            />
            Add Product to Order
          </h3>          
          <button
            @click="closeAddItemModal"
            class="text-gray-600 hover:text-gray-800 transition-colors duration-150 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:ring-offset-2 rounded-full p-1"
          >
            <UIcon name="i-heroicons-x-mark" class="h-6 w-6" />
          </button>
        </div>         -->
        <div class="px-6 py-4">
          <!-- Product Search/Select -->
          <div class="mb-4">
            <label class="block text-sm font-medium text-gray-800 mb-2">
              Select Product
            </label>
            <USelectMenu
              v-model="selectedProductToAdd"
              :options="availableProductsForOrder"
              option-attribute="name"
              value-attribute="id"
              placeholder="Search for a product..."
              searchable
              :searchable-placeholder="'Type to search products...'"
              class="w-full"
              :loading="!products.length"
            >
              <template #option="{ option }">
                <div class="flex items-center space-x-3">
                  <div
                    class="h-10 w-10 rounded-md overflow-hidden bg-gray-200 flex-shrink-0"
                  >
                    <img
                      v-if="option.image_details?.length"
                      :src="option.image_details[0].image"
                      :alt="option.name"
                      class="h-full w-full object-cover"
                    />
                    <div
                      v-else
                      class="h-full w-full flex items-center justify-center"
                    >
                      <UIcon
                        name="i-heroicons-photo"
                        class="h-4 w-4 text-gray-400"
                      />
                    </div>
                  </div>
                  <div class="flex-1 min-w-0">
                    <p class="text-sm font-medium text-gray-900 truncate">
                      {{ option.name }}
                    </p>
                    <p class="text-sm text-gray-600">
                      ৳{{ option.sale_price || option.regular_price }} -
                      Available: {{ getAvailableStock(option) }}
                    </p>
                  </div>
                </div>
              </template>
              <template #empty>
                <div class="text-center py-4">
                  <UIcon
                    name="i-heroicons-inbox"
                    class="h-8 w-8 text-gray-400 mx-auto mb-2"
                  />
                  <p class="text-sm text-gray-600">No products available</p>
                </div>
              </template>
            </USelectMenu>
            <p
              v-if="
                availableProductsForOrder.length === 0 && products.length > 0
              "
              class="text-sm text-amber-600 mt-1"
            >
              All your products are either out of stock or already added to this
              order.
            </p>
          </div>
          <!-- Selected Product Details -->
          <div
            v-if="selectedProductDetails"
            class="bg-gray-50 rounded-lg p-4 mb-4"
          >
            <div class="flex items-start space-x-3">
              <div class="h-16 w-16 rounded-md overflow-hidden bg-gray-200">
                <img
                  v-if="selectedProductDetails.image_details?.length"
                  :src="selectedProductDetails.image_details[0].image"
                  :alt="selectedProductDetails.name"
                  class="h-full w-full object-contain"
                />
                <div
                  v-else
                  class="h-full w-full flex items-center justify-center"
                >
                  <UIcon
                    name="i-heroicons-photo"
                    class="h-8 w-8 text-gray-600"
                  />
                </div>
              </div>
              <div class="flex-1">
                <h5 class="font-medium text-gray-800">
                  {{ selectedProductDetails.name }}
                </h5>
                <p class="text-sm text-gray-600 mt-1 line-clamp-2">
                  {{
                    selectedProductDetails.short_description ||
                    "No description available"
                  }}
                </p>
                <div class="mt-2 grid grid-cols-2 gap-2 text-sm">
                  <div>
                    <span class="text-gray-600">Price:</span>
                    <span class="font-medium ml-1"
                      >৳{{
                        selectedProductDetails.sale_price ||
                        selectedProductDetails.regular_price
                      }}</span
                    >
                  </div>
                  <div>
                    <span class="text-gray-600">Available:</span>
                    <span class="font-medium ml-1">{{
                      maxAvailableQuantity
                    }}</span>
                  </div>
                </div>
              </div>
            </div>
          </div>

          <!-- Quantity Input -->
          <div v-if="selectedProductDetails">
            <label
              for="quantity-input"
              class="block text-sm font-medium text-gray-800 mb-1"
            >
              Quantity
            </label>
            <div class="flex items-center">
              <UButton
                @click="decrementNewItemQuantity"
                :disabled="newItemQuantity <= 1"
                color="gray"
                variant="soft"
                icon="i-heroicons-minus"
                size="sm"
              />
              <input
                id="quantity-input"
                type="number"
                v-model.number="newItemQuantity"
                min="1"
                :max="maxAvailableQuantity"
                class="mx-2 block w-20 border-gray-300 rounded-md shadow-sm sm:text-sm text-center focus:ring-2 focus:ring-indigo-200 focus:outline-none px-2 py-1"
              />
              <UButton
                @click="incrementNewItemQuantity"
                :disabled="newItemQuantity >= maxAvailableQuantity"
                color="gray"
                variant="soft"
                icon="i-heroicons-plus"
                size="sm"
              />
            </div>
            <p
              v-if="newItemQuantity > maxAvailableQuantity"
              class="text-xs text-red-500 mt-1"
            >
              Only {{ maxAvailableQuantity }} items available in stock
            </p>
          </div>
        </div>

        <!-- Modal Footer -->
        <div class="bg-gray-50 px-6 py-4 flex justify-end space-x-3">
          <UButton
            @click="addItemToOrder"
            :disabled="
              !selectedProductDetails ||
              newItemQuantity < 1 ||
              newItemQuantity > maxAvailableQuantity ||
              maxAvailableQuantity <= 0
            "
            color="indigo"
            :loading="isAddingItem"
            icon="i-heroicons-plus"
          >
            Add to Order
          </UButton>
          <UButton
            @click="closeAddItemModal"
            color="gray"
            variant="outline"
            icon="i-heroicons-x-mark"
          >
            Cancel
          </UButton>
        </div>
      </div>
    </UModal>
  </div>
</template>

<script setup>
const { user } = useAuth();
const { get, patch, put } = useApi();
const { formatDate } = useUtils();
const toast = useToast();
import { nextTick } from "vue";
import {
  ShoppingBag,
  ShoppingCart,
  Search,
  ChevronLeft,
  ChevronRight,
  Eye,
  Edit2,
  Trash2,
  X,
  Save,
  PackageX,
  User,
  FileText,
  RefreshCw,
  Loader2,
  Printer,
  Plus,
  Minus,
} from "lucide-vue-next";
import { jsPDF } from "jspdf";
import "jspdf-autotable";

// UI state
const showOrderDetailsModal = ref(false);
const isProcessing = ref(false);
const editCustomerInfo = ref(false);
const editOrderItems = ref(false);
const isOrdersLoading = ref(false);

// Pagination state
const currentPage = ref(1);
const hasMoreOrders = ref(false);
const pagination = ref(null);
const pageSize = 10; // Display 10 orders per page
const searchTimeout = ref(null);

// Order items editing
const editingOrderItems = ref([]);
const editingDeliveryFee = ref(0);
const selectedProductToAdd = ref(null);
const newItemQuantity = ref(1);

// Filters and search
const orderFilter = ref("all");
const orderSearch = ref("");

// Pagination for orders (removed old frontend pagination)
// const itemsPerPage = 5;
// const currentPage = ref(1);

// Selected items
const selectedOrder = ref(null);
const editingOrderStatus = ref("");
const editingCustomer = reactive({
  name: "",
  email: "",
  phone: "",
  address: "",
});

// Component state
const showAddItemModal = ref(false);
const isAddingItem = ref(false);
const orderItemAddition = ref({});

// Data
const orders = ref([]);
const allOrders = ref([]); // Store all orders for statistics
const orderStats = ref({
  total: 0,
  pending: 0,
  processing: 0,
  delivered: 0,
  total_amount: 0,
  pending_amount: 0,
  processing_amount: 0,
  delivered_amount: 0
});
const products = ref([]);

async function getOrders(page = 1) {
  if (page === 1) {
    isOrdersLoading.value = true;
    orders.value = [];
  }

  try {
    // Build query parameters for pagination
    const params = new URLSearchParams();
    params.append('page', page.toString());
    params.append('page_size', pageSize.toString());

    // Add filters to API call if they exist
    if (orderFilter.value && orderFilter.value !== 'all') {
      params.append('status', orderFilter.value);
    }

    if (orderSearch.value) {
      params.append('search', orderSearch.value);
    }

    const res = await get(`/seller-orders/?${params.toString()}`, {}, {
      headers: {
        "Cache-Control": "no-cache",
        Pragma: "no-cache",
      },
    });

    if (res && res.data) {
      if ("results" in res.data) {
        // Paginated response
        pagination.value = {
          count: res.data.count,
          next: res.data.next,
          previous: res.data.previous,
        };

        const processedOrders = res.data.results.map((order) => ({
          ...order,
          id: Array.isArray(order.id) ? order.id[0] : order.id,
        }));

        if (page === 1) {
          orders.value = processedOrders;
          allOrders.value = processedOrders;
        } else {
          orders.value = [...orders.value, ...processedOrders];
          allOrders.value = [...allOrders.value, ...processedOrders];
        }

        hasMoreOrders.value = !!res.data.next;
        console.log(`Loaded ${res.data.results.length} orders (page ${page})`);
      } else if (Array.isArray(res.data)) {
        // Non-paginated response - handle fallback
        const processedOrders = res.data.map((order) => ({
          ...order,
          id: Array.isArray(order.id) ? order.id[0] : order.id,
        }));
        orders.value = processedOrders;
        allOrders.value = processedOrders;
        hasMoreOrders.value = false;
        console.log(`Loaded ${res.data.length} orders (non-paginated)`);
      } else {
        console.warn("Unexpected data format received");
        orders.value = [];
        allOrders.value = [];
        hasMoreOrders.value = false;
      }
    } else {
      console.warn("No order data received");
      orders.value = [];
      allOrders.value = [];
      hasMoreOrders.value = false;
    }
  } catch (error) {
    console.error("Error fetching orders:", error);
    showToast("error", "Failed to load orders", "Please try again later");
    orders.value = [];
    allOrders.value = [];
    hasMoreOrders.value = false;  } finally {
    isOrdersLoading.value = false;
  }
}

// Load order statistics
const loadOrderStats = async () => {
  try {
    const res = await get("/seller-orders/stats/");
    if (res && res.data) {
      orderStats.value = res.data;
    }
  } catch (error) {
    console.error("Error loading order statistics:", error);
  }
};

// Refresh statistics only (for when orders are updated)
const refreshOrderStats = async () => {
  try {
    const res = await get("/seller-orders/stats/", {}, {
      headers: {
        "Cache-Control": "no-cache",
        Pragma: "no-cache",
      },
    });

    if (res && res.data) {
      orderStats.value = res.data;
    }
  } catch (error) {
    console.error("Error refreshing order statistics:", error);
  }
};

// Load more orders
const loadMoreOrders = () => {
  if (hasMoreOrders.value) {
    currentPage.value++;
    getOrders(currentPage.value);
  }
};

async function getProducts() {
  try {
    console.log("=== getProducts started ===");
    const res = await get("/my-products/");
    console.log("Products API response:", res);

    if (res && res.data && Array.isArray(res.data)) {
      console.log("Raw products count:", res.data.length);
      const filteredProducts = res.data.filter((product) => {
        const isValid =
          product && product.id && product.name && product.quantity > 0; // Only include products with stock
        console.log(
          `Product ${product?.name || "unnamed"}: valid=${isValid}, quantity=${
            product?.quantity
          }`
        );
        return isValid;
      });

      products.value = filteredProducts;
      console.log("Filtered products count:", products.value.length);
      console.log(
        "Filtered products:",
        products.value.map((p) => ({
          id: p.id,
          name: p.name,
          quantity: p.quantity,
        }))
      );

      return products.value; // Return the products for verification
    } else {
      console.warn("Invalid products response structure:", res);
      products.value = [];
      return [];
    }
  } catch (error) {
    console.error("=== getProducts ERROR ===", error);
    products.value = [];
    showToast(
      "error",
      "Error Loading Products",
      "Failed to load your products. Please try again."
    );
    throw error; // Re-throw to be caught by the calling function
  }
}

// Helper function to format currency amounts
function formatAmount(amount) {
  if (amount === undefined || amount === null) return "0.00";
  return parseFloat(amount).toFixed(2);
}

// Backend pagination computed properties
const totalPages = computed(() => {
  if (!pagination.value || !pagination.value.count) return 1;
  return Math.ceil(pagination.value.count / pageSize);
});

const paginationStart = computed(() => {
  if (!pagination.value || pagination.value.count === 0) return 0;
  return (currentPage.value - 1) * pageSize + 1;
});

const paginationEnd = computed(() => {
  if (!pagination.value) return 0;
  const end = currentPage.value * pageSize;
  return Math.min(end, pagination.value.count);
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

const maxAvailableQuantity = computed(() => {
  if (!selectedProductToAdd.value) return 0;

  // Find the product object if selectedProductToAdd is just an ID
  let product = selectedProductToAdd.value;
  if (
    typeof selectedProductToAdd.value === "string" ||
    typeof selectedProductToAdd.value === "number"
  ) {
    product = products.value.find((p) => p.id === selectedProductToAdd.value);
  }

  if (!product) return 0;

  // Check if this product is already in the order
  const existingItem = editingOrderItems.value.find(
    (item) => item.product === product.id
  );
  const alreadyInOrder = existingItem ? existingItem.quantity : 0;

  return Math.max(0, (product.quantity || 0) - alreadyInOrder);
});

const selectedProductDetails = computed(() => {
  if (!selectedProductToAdd.value) return null;

  // Find the product object if selectedProductToAdd is just an ID
  let product = selectedProductToAdd.value;
  if (
    typeof selectedProductToAdd.value === "string" ||
    typeof selectedProductToAdd.value === "number"
  ) {
    product = products.value.find((p) => p.id === selectedProductToAdd.value);
  }

  return product;
});

const availableProductsForOrder = computed(() => {
  console.log("=== availableProductsForOrder computed ===");
  console.log("products.value.length:", products.value?.length || 0);
  console.log(
    "editingOrderItems.value.length:",
    editingOrderItems.value?.length || 0
  );

  const filtered = products.value.filter((product) => {
    const existingItem = editingOrderItems.value.find(
      (item) => item.product === product.id
    );
    const alreadyInOrder = existingItem ? existingItem.quantity : 0;
    const available = (product.quantity || 0) > alreadyInOrder;
    console.log(
      `Filter check - Product ${product.name}: stock=${product.quantity}, inOrder=${alreadyInOrder}, available=${available}`
    );
    return available;
  });

  console.log("availableProductsForOrder result:", filtered.length, filtered);
  return filtered;
});

// Helper function to get available stock for a product
const getAvailableStock = (product) => {
  const existingItem = editingOrderItems.value.find(
    (item) => item.product === product.id
  );
  const alreadyInOrder = existingItem ? existingItem.quantity : 0;
  return Math.max(0, (product.quantity || 0) - alreadyInOrder);
};

// Helper function to get item image
const getItemImage = (item) => {
  // Handle different image data structures
  if (item?.product_details?.image) {
    // If image is an array, return the first element
    if (
      Array.isArray(item.product_details.image) &&
      item.product_details.image.length > 0
    ) {
      return item.product_details.image[0]?.image;
    }
    // If image is a string, return it directly
    if (typeof item.product_details.image === "string") {
      return item.product_details.image;
    }
  }
  return null;
};

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

const viewOrderDetails = (order) => {
  selectedOrder.value = order;
  editingOrderStatus.value = order.order_status;
  editCustomerInfo.value = false;
  editOrderItems.value = false;

  // Initialize editing customer info
  editingCustomer.name = order.name;
  editingCustomer.email = order.email;
  editingCustomer.phone = order.phone;
  editingCustomer.address = order.address;

  // Initialize editing order details modalitems and delivery fee
  editingOrderItems.value = JSON.parse(JSON.stringify(order.items));
  editingDeliveryFee.value = Number(order.delivery_fee) || 0;

  showOrderDetailsModal.value = true;
};

const saveCustomerChanges = async () => {
  if (isProcessing.value) return;
  isProcessing.value = true;

  try {
    if (selectedOrder.value) {
      const res = await patch(`/orders/${selectedOrder.value.id}/`, {
        name: editingCustomer.name,
        email: editingCustomer.email,
        phone: editingCustomer.phone,
        address: editingCustomer.address,
      });      if (res.data) {
        selectedOrder.value = res.data;
        await Promise.all([
          getOrders(currentPage.value),
          refreshOrderStats()
        ]);
        showToast(
          "success",
          "Customer Updated",
          "Customer information has been successfully updated."
        );
      }
    }
    editCustomerInfo.value = false;
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
  if (editOrderItems.value) {
    return editingOrderItems.value.reduce(
      (total, item) => total + item.price * item.quantity,
      0
    );
  } else {
    return (
      selectedOrder.value?.items?.reduce(
        (total, item) => total + item.price * item.quantity,
        0
      ) || 0
    );
  }
};

async function handleEditOrderItem() {
  console.log("=== handleEditOrderItem called ===");
  console.log("Current editOrderItems.value:", editOrderItems.value);
  const wasEditing = editOrderItems.value;
  editOrderItems.value = !editOrderItems.value;
  console.log("New editOrderItems.value:", editOrderItems.value);

  if (editOrderItems.value && !wasEditing) {
    // Entering edit mode
    showToast(
      "info",
      "Edit Mode Enabled",
      "You can now modify order items and add new products."
    );
    console.log("Loading products...");
    await getProducts();
    console.log("Products loaded in handleEditOrderItem");
  } else if (!editOrderItems.value && wasEditing) {
    // Exiting edit mode
    showToast(
      "info",
      "Edit Mode Disabled",
      "Order item editing has been disabled."
    );
  }
}

const closeAddItemModal = () => {
  console.log("=== closeAddItemModal called ===");
  console.log("showAddItemModal.value before:", showAddItemModal.value);
  showAddItemModal.value = false;
  console.log("showAddItemModal.value after:", showAddItemModal.value);
  selectedProductToAdd.value = null;
  newItemQuantity.value = 1;
};

async function handleShowAddItemModal() {
  try {
    console.log("=== handleShowAddItemModal started ===");
    console.log("editOrderItems.value:", editOrderItems.value);
    console.log("editingOrderItems.value:", editingOrderItems.value);
    console.log("selectedOrder.value:", selectedOrder.value);

    // Check if edit mode is enabled
    if (!editOrderItems.value) {
      showToast(
        "warning",
        "Edit Mode Required",
        "Please enable 'Edit Items' mode first to add products to the order."
      );
      return;
    }

    // Reset form state
    selectedProductToAdd.value = null;
    newItemQuantity.value = 1;

    // Ensure products are loaded
    console.log("Current products count:", products.value?.length || 0);
    if (!products.value || products.value.length === 0) {
      console.log("Loading products...");
      await getProducts();
      console.log("Products loaded:", products.value?.length || 0);
    }

    // Filter out products that are out of stock
    const availableProducts = products.value.filter((product) => {
      const existingItem = editingOrderItems.value.find(
        (item) => item.product === product.id
      );
      const alreadyInOrder = existingItem ? existingItem.quantity : 0;
      const available = (product.quantity || 0) > alreadyInOrder;
      console.log(
        `Product ${product.name}: stock=${product.quantity}, inOrder=${alreadyInOrder}, available=${available}`
      );
      return available;
    });

    console.log("Available products count:", availableProducts.length);

    if (availableProducts.length === 0) {
      console.log("No products available for selection");
      showToast(
        "warning",
        "No Products Available",
        "All products are either out of stock or already added to this order."
      );
      return;
    }
    console.log("Opening add item modal...");
    showAddItemModal.value = true;
    console.log(
      "showAddItemModal.value after setting:",
      showAddItemModal.value
    );

    // Force reactivity check
    await nextTick();
    console.log(
      "After nextTick - showAddItemModal.value:",
      showAddItemModal.value
    );
    console.log(
      "availableProductsForOrder.length:",
      availableProductsForOrder.value.length
    );
  } catch (error) {
    console.error("Error opening add item modal:", error);
    showToast("error", "Error", "Failed to load products for selection");
  }
}

const calculateTotal = () => {
  const subtotal = calculateSubtotal();
  const deliveryFee = editOrderItems.value
    ? editingDeliveryFee.value || 0
    : selectedOrder.value?.delivery_fee || 0;
  return subtotal + Number(deliveryFee);
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

const incrementNewItemQuantity = () => {
  if (newItemQuantity.value < maxAvailableQuantity.value) {
    newItemQuantity.value++;
  }
};

const decrementNewItemQuantity = () => {
  if (newItemQuantity.value > 1) {
    newItemQuantity.value--;
  }
};

const addItemToOrder = async () => {
  console.log("=== addItemToOrder started ===");
  console.log("isAddingItem.value:", isAddingItem.value);
  console.log("selectedProductToAdd.value:", selectedProductToAdd.value);

  if (isAddingItem.value || !selectedProductToAdd.value) {
    console.log("Returning early: isAddingItem or no product selected");
    return;
  }
  isAddingItem.value = true;

  try {
    // Find the product object if selectedProductToAdd is just an ID
    let product = selectedProductToAdd.value;
    if (
      typeof selectedProductToAdd.value === "string" ||
      typeof selectedProductToAdd.value === "number"
    ) {
      product = products.value.find((p) => p.id === selectedProductToAdd.value);
      console.log("Found product by ID:", product);
    }

    if (!product) {
      throw new Error("Product not found");
    }

    console.log("Selected product:", product);
    console.log("Quantity to add:", newItemQuantity.value);
    console.log("Product stock:", product.quantity);

    // Check stock availability
    if (newItemQuantity.value > product.quantity) {
      showToast(
        "error",
        "Insufficient Stock",
        `Only ${product.quantity} items available in stock`
      );
      return;
    }
    const newItem = {
      product: product.id,
      quantity: newItemQuantity.value,
      price: product.sale_price || product.regular_price,
      product_details: {
        name: product.name,
        image:
          product.image_details && product.image_details.length > 0
            ? product.image_details[0].image
            : null,
      },
    };

    console.log("New item to add:", newItem);
    console.log("Current editingOrderItems:", editingOrderItems.value);

    // Check if item already exists in order
    const existingItemIndex = editingOrderItems.value.findIndex(
      (item) => item.product === newItem.product
    );

    console.log("Existing item index:", existingItemIndex);

    if (existingItemIndex !== -1) {
      // Update existing item quantity
      const totalQuantity =
        editingOrderItems.value[existingItemIndex].quantity + newItem.quantity;
      if (totalQuantity > product.quantity) {
        showToast(
          "error",
          "Insufficient Stock",
          `Cannot add more. Only ${product.quantity} items available in stock`
        );
        return;
      }
      console.log(
        "Updating existing item quantity from",
        editingOrderItems.value[existingItemIndex].quantity,
        "to",
        totalQuantity
      );
      editingOrderItems.value[existingItemIndex].quantity = totalQuantity;
    } else {
      // Add new item
      console.log("Adding new item to order");
      editingOrderItems.value.push(newItem);
    }

    console.log("Updated editingOrderItems:", editingOrderItems.value);

    // Reset form
    selectedProductToAdd.value = null;
    newItemQuantity.value = 1;
    showAddItemModal.value = false;

    showToast("success", "Item Added", "Product has been added to the order");
  } catch (error) {
    console.error("Error adding item to order:", error);
    showToast(
      "error",
      "Error",
      "Failed to add item to order: " + error.message
    );
  } finally {
    isAddingItem.value = false;
  }
};

const saveOrderItemChanges = async () => {
  try {
    const res = await patch(`/orders/${selectedOrder.value.id}/`, {
      delivery_fee: editingDeliveryFee.value,
      total: calculateTotal(),
    });

    const res2 = await put(`/orders/${selectedOrder.value.id}/update/`, {
      items: editingOrderItems.value,
    });    if (res.data) {
      showToast(
        "success",
        "Order Items Updated",
        "Order items have been successfully updated."
      );
      await Promise.all([
        getOrders(currentPage.value),
        refreshOrderStats()
      ]);
    } else {
      showToast(
        "error",
        "Update Failed",
        "There was an error updating the order items."
      );
    }
    showOrderDetailsModal.value = false;
  } catch (error) {
    showToast(
      "error",
      "Update Failed",
      "There was an error updating the order items."
    );
  }
};

const updateOrderStatus = async (id) => {
  try {
    const res = await patch(`/orders/${id}/`, {
      order_status: editingOrderStatus.value,
    });
    if (res.data) {
      showToast(
        "success",
        "Order Status Updated",
        `Order #${id} status has been updated to ${editingOrderStatus.value}.`
      );
      showOrderDetailsModal.value = false;
    }
  } catch (error) {
    showToast(
      "error",
      "Update Failed",
      "There was an error updating the order status."
    );
  } finally {
    isProcessing.value = false;
    await Promise.all([
      getOrders(currentPage.value),
      refreshOrderStats()
    ]);
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
    doc.text(`Status: ${order.status?.toUpperCase()}`, 14, 60);

    // Customer details
    doc.setFontSize(12);
    doc.setTextColor(66, 66, 66);
    doc.text("Customer Details", 14, 70);

    doc.setFontSize(10);
    doc.setTextColor(100, 100, 100);
    doc.text(`Name: ${order.customer || order.name}`, 14, 77);
    doc.text(`Email: ${order.email}`, 14, 82);
    doc.text(`Phone: ${order.phone}`, 14, 87);
    doc.text(`Address: ${order.address}`, 14, 92);

    // Payment details
    doc.setFontSize(12);
    doc.setTextColor(66, 66, 66);
    doc.text("Payment Details", 120, 70);

    doc.setFontSize(10);
    doc.setTextColor(100, 100, 100);
    doc.text(`Method: ${order.payment_method || "Cash on Delivery"}`, 120, 77);
    doc.text(`Status: ${order.payment_status || "Pending"}`, 120, 82);

    // Order items
    doc.setFontSize(12);
    doc.setTextColor(66, 66, 66);
    doc.text("Products", 14, 105);

    let yPos = 115;

    // Draw header line
    doc.setDrawColor(220, 220, 220);
    doc.line(14, yPos - 3, 196, yPos - 3);

    (order.items || []).forEach((item, index) => {
      // Draw item details
      doc.setFontSize(10);
      doc.setTextColor(80, 80, 80);
      doc.text(
        `${index + 1}. ${item.product_details?.name || "Product"}`,
        14,
        yPos
      );

      doc.setTextColor(100, 100, 100);
      doc.text(`${item.quantity} × ৳${item.price}`, 14, yPos + 5);

      doc.setFontSize(10);
      doc.setTextColor(80, 80, 80);
      doc.text(`৳${item.price * item.quantity}`, 180, yPos, { align: "right" });

      // Draw separator line
      if (index < (order.items || []).length - 1) {
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
    doc.text(`৳${calculateSubtotal()}`, 180, yPos, { align: "right" });

    yPos += 5;
    doc.text(`Delivery Fee:`, 140, yPos);
    doc.text(`৳${order.delivery_fee || 0}`, 180, yPos, { align: "right" });

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
  } catch (error) {
    console.error("PDF Generation Error:", error);
  }
};

// Pagination methods
const goToPage = (page) => {
  if (typeof page === "number" && page !== currentPage.value) {
    currentPage.value = page;
    getOrders(page);
  }
};

const nextPage = () => {
  if (currentPage.value < totalPages.value) {
    currentPage.value++;
    getOrders(currentPage.value);
  }
};

const prevPage = () => {
  if (currentPage.value > 1) {
    currentPage.value--;
    getOrders(currentPage.value);
  }
};

// Toast methods
const showToast = (type, title, message) => {
  console.log(`=== showToast called: ${type} - ${title} - ${message} ===`);
  // Use Nuxt UI toast if available
  try {
    if (toast) {
      const colorMap = {
        success: "green",
        error: "red",
        warning: "amber",
        info: "blue",
      };

      toast.add({
        title,
        description: message,
        color: colorMap[type] || "gray",
        timeout: type === "error" ? 5000 : 3000,
      });
      console.log("Toast notification sent successfully");
    } else {
      console.log(`Toast not available - ${type}: ${title} - ${message}`);
    }
  } catch (error) {
    console.log(`Toast fallback: ${type} - ${title} - ${message}`);
  }
};

// Watch for changes
watch(selectedProductToAdd, (productId) => {
  if (productId) {
    newItemQuantity.value = 1;
    // Validate that the selected product exists and has stock
    const product = products.value.find((p) => p.id === productId);
    if (!product) {
      console.warn("Selected product not found:", productId);
      selectedProductToAdd.value = null;
      return;
    }

    // Check available quantity
    const existingItem = editingOrderItems.value.find(
      (item) => item.product === product.id
    );
    const alreadyInOrder = existingItem ? existingItem.quantity : 0;
    const available = Math.max(0, (product.quantity || 0) - alreadyInOrder);

    if (available <= 0) {
      showToast(
        "warning",
        "No Stock Available",
        `${product.name} is out of stock or already fully added to this order.`
      );
      selectedProductToAdd.value = null;
    }
  }
});

// Watch for filter changes to trigger backend search
watch(orderFilter, () => {
  currentPage.value = 1;
  getOrders(1);
});

// Watch for search changes with debounce
watch(orderSearch, () => {
  // Clear previous timeout
  if (searchTimeout.value) {
    clearTimeout(searchTimeout.value);
  }
  
  // Set new timeout for debounced search
  searchTimeout.value = setTimeout(() => {
    currentPage.value = 1;
    getOrders(1);
  }, 500); // 500ms debounce
});

// Initialize data on mount
let orderUpdateInterval;
onMounted(async () => {
  await Promise.all([
    getOrders(),
    getProducts(),
    loadOrderStats()
  ]);
});

onBeforeUnmount(() => {
  // Clear interval when component is destroyed
  if (orderUpdateInterval) clearInterval(orderUpdateInterval);
  
  // Clear search timeout
  if (searchTimeout.value) {
    clearTimeout(searchTimeout.value);
  }
});
</script>
