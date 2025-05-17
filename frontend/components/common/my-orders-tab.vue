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
            class="h-6 w-6 animate-spin text-gray-400"
          />
        </div>
        <div class="flex items-center justify-between">
          <div>
            <p class="text-sm font-medium text-gray-500">Total Orders</p>
            <p class="text-xl font-semibold text-gray-900">
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
            <p class="text-sm font-medium text-gray-500">Pending Orders</p>
            <p class="text-xl font-semibold text-gray-900">
              {{ pendingOrders.length }}
            </p>
          </div>
          <div
            class="h-12 w-12 rounded-full bg-yellow-50 flex items-center justify-center"
          >
            <UIcon name="i-heroicons-clock" class="h-6 w-6 text-yellow-500" />
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
            <p class="text-sm font-medium text-gray-500">Processing Orders</p>
            <p class="text-xl font-semibold text-gray-900">
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
            <p class="text-sm font-medium text-gray-500">Delivered Orders</p>
            <p class="text-xl font-semibold text-gray-900">
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
              <div class="text-sm text-gray-900">
                {{ formatDate(order.created_at) }}
              </div>
            </td>
            <td class="px-6 py-4 whitespace-nowrap">
              <div class="text-sm text-gray-900">
                {{ order.name }}
              </div>
              <div class="text-sm text-gray-500">
                {{ order.email }}
              </div>
            </td>
            <td class="px-6 py-4 whitespace-nowrap">
              <div class="text-sm font-medium text-gray-900">
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
                  class="text-gray-600 hover:text-gray-900 transition-colors duration-150 flex items-center"
                >
                  <Printer class="h-4 w-4 mr-1" />
                  Print
                </button>
              </div>
            </td>
          </tr>
          <tr v-if="paginatedOrders.length === 0">
            <td colspan="6" class="px-6 py-10 text-center text-gray-500">
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
      <div class="hidden sm:flex-1 sm:flex sm:items-center sm:justify-between">
        <div>
          <p class="text-sm text-gray-700">
            Showing
            <span class="font-medium">{{ paginationStart }}</span> to
            <span class="font-medium">{{ paginationEnd }}</span> of
            <span class="font-medium">{{ filteredOrders.length }}</span>
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
    <!-- Order Details Modal -->
    <UModal
      v-model="showOrderDetailsModal"
      :ui="{ width: 'w-full sm:max-w-3xl' }"
    >
      <div
        class="flex items-center justify-center min-h-screen pt-4 px-4 pb-20 text-center sm:block sm:p-0"
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
          class="inline-block align-bottom bg-white rounded-xl text-left shadow-sm transform transition-all sm:my-24 sm:align-middle sm:max-w-3xl sm:w-full animate-slide-up max-h-[80vh] overflow-auto"
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
              Order #{{ selectedOrder?.order_number }}
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
                      <p class="font-medium">
                        {{ selectedOrder?.created_at.split("T")[0] }}
                      </p>
                      <p class="text-xs text-gray-500">
                        {{ formatDate(selectedOrder?.created_at) }}
                      </p>
                    </div>
                    <div>
                      <p class="text-gray-500">Status</p>
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
                      <p class="text-gray-500">Payment Method</p>
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
                      <p class="font-medium">{{ selectedOrder?.name }}</p>
                    </div>
                    <!-- <div>
                      <p class="text-gray-500">Email</p>
                      <p class="font-medium">
                        {{ selectedOrder?.email }}
                      </p>
                    </div> -->
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
                        v-model="editingCustomer.name"
                        class="block w-full border-gray-300 rounded-md shadow-sm sm:text-sm focus:outline-none px-2 py-1"
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
                        class="block w-full border-gray-300 rounded-md shadow-sm sm:text-sm focus:outline-none px-2 py-1"
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
                        class="block w-full border-gray-300 rounded-md shadow-sm sm:text-sm focus:outline-none px-2 py-1"
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
                              v-if="item?.product_details?.image[0]"
                              class="h-10 w-10 rounded-md object-cover"
                              :src="item?.product_details?.image[0]"
                              alt=""
                            />
                          </div>
                          <div class="ml-4">
                            <div class="text-sm font-medium text-gray-900">
                              {{ item.product_details?.name }}
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
                          class="block w-24 border-gray-300 rounded-md shadow-sm focus:outline-none sm:text-sm px-2 py-1"
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
                    <tr v-if="editOrderItems">
                      <td colspan="5" class="px-6 py-4">
                        <button
                          @click="showAddItemModal = true"
                          class="inline-flex items-center px-3 py-1.5 border border-gray-300 shadow-sm text-xs font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50 focus:outline-none"
                        >
                          <Plus class="h-3 w-3 mr-1.5" />
                          Add Item
                        </button>
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
                            class="mt-1 block w-full border-gray-300 rounded-md shadow-sm sm:text-sm focus:outline-none px-2 py-1"
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
                  class="inline-flex items-center px-3 py-1.5 border border-gray-300 shadow-sm text-xs font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50 focus:outline-none"
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
              class="inline-flex justify-center items-center rounded-md border border-gray-300 shadow-sm px-4 py-2 bg-white text-base font-medium text-gray-700 hover:bg-gray-50 focus:outline-none sm:text-sm transition-colors duration-200"
            >
              <X class="h-4 w-4 mr-1.5" />
              Close
            </button>
          </div>
        </div>
      </div>
    </UModal>

    <!-- Add Item Modal -->
    <UModal
      v-model="showAddItemModal"
      :ui="{
        wrapper: 'relative z-[9999999]',
      }"
    >
      <div
        class="bg-white rounded-xl shadow-sm overflow-hidden max-w-lg w-full"
      >
        <div
          class="absolute top-0 left-0 right-0 h-1 bg-gradient-to-r from-indigo-400 via-purple-500 to-indigo-600"
        ></div>
        <div
          class="px-6 py-5 border-b border-gray-200 flex justify-between items-center"
        >
          <h3 class="text-xl font-semibold text-gray-900 flex items-center">
            <UIcon
              name="i-heroicons-shopping-cart"
              class="h-5 w-5 mr-2 text-indigo-600"
            />
            Add Product to Order
          </h3>
          <button
            @click="showAddItemModal = false"
            class="text-gray-400 hover:text-gray-500 transition-colors duration-150"
          >
            <UIcon name="i-heroicons-x-mark" class="h-6 w-6" />
          </button>
        </div>

        <div class="px-6 py-4">
          <!-- Product Search/Select -->
          <div class="mb-4">
            <UInputMenu
              v-model="selectedProductToAdd"
              :options="products"
              option-attribute="name"
              :ui="{
                input: 'w-full',
                container: 'w-full',
              }"
              placeholder="Search for a product..."
            />
          </div>

          <!-- Selected Product Details -->
          <div
            v-if="selectedProductToAdd"
            class="bg-gray-50 rounded-lg p-4 mb-4"
          >
            <div class="flex items-start space-x-3">
              <div class="h-16 w-16 rounded-md overflow-hidden bg-gray-200">
                <img
                  v-if="selectedProductToAdd.image_details?.length"
                  :src="selectedProductToAdd.image_details[0].image"
                  :alt="selectedProductToAdd.name"
                  class="h-full w-full object-cover"
                />
                <div
                  v-else
                  class="h-full w-full flex items-center justify-center"
                >
                  <UIcon
                    name="i-heroicons-photo"
                    class="h-8 w-8 text-gray-400"
                  />
                </div>
              </div>
              <div class="flex-1">
                <h5 class="font-medium text-gray-900">
                  {{ selectedProductToAdd.name }}
                </h5>
                <p class="text-sm text-gray-500 mt-1 line-clamp-2">
                  {{
                    selectedProductToAdd.short_description ||
                    "No description available"
                  }}
                </p>
                <div class="mt-2 grid grid-cols-2 gap-2 text-sm">
                  <div>
                    <span class="text-gray-500">Price:</span>
                    <span class="font-medium ml-1"
                      >৳{{ selectedProductToAdd.sale_price }}</span
                    >
                  </div>
                  <div>
                    <span class="text-gray-500">Available:</span>
                    <span class="font-medium ml-1">{{
                      selectedProductToAdd.quantity
                    }}</span>
                  </div>
                </div>
              </div>
            </div>
          </div>

          <!-- Quantity Input -->
          <div v-if="selectedProductToAdd">
            <label
              for="quantity-input"
              class="block text-sm font-medium text-gray-700 mb-1"
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
              !selectedProductToAdd ||
              newItemQuantity < 1 ||
              newItemQuantity > maxAvailableQuantity
            "
            color="indigo"
            :loading="isAddingItem"
            icon="i-heroicons-plus"
          >
            Add to Order
          </UButton>
          <UButton
            @click="showAddItemModal = false"
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
  name: "",
  email: "",
  phone: "",
  address: "",
});

const orderItemAddition = ref({});

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
const isAddingItem = ref(false);

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
    products.value = []; // Ensure it's at least an empty array
  }
}

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
  editingDeliveryFee.value = Number(order.delivery_fee) || 0; // Convert to number and handle null/undefined

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
      });
      if (res.data) {
        selectedOrder.value = res.data;
        await getOrders();
        showToast(
          "success",
          "Customer Updated",
          "Customer information has been successfully updated."
        );
      }
    } else {
      return;
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
    // When editing, use editingOrderItems
    return editingOrderItems.value.reduce(
      (total, item) => total + item.price * item.quantity,
      0
    );
  } else {
    // Before editing, use selectedOrder items
    return (
      selectedOrder.value?.items?.reduce(
        (total, item) => total + item.price * item.quantity,
        0
      ) || 0
    );
  }
};

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

const maxAvailableQuantity = computed(() => {
  if (!selectedProductToAdd.value) return 0;
  return selectedProductToAdd.value.quantity || 0;
});

watch(orderItemAddition, (newValue) => {
  if (newValue) {
    selectedProductToAdd.value = products.value.find(
      (p) => p.name === newValue
    );
    newItemQuantity.value = 1;
  }
});

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
  if (isAddingItem.value || !selectedProductToAdd.value) return;

  isAddingItem.value = true;

  try {
    // Create a new item with complete details
    const newItem = {
      product: selectedProductToAdd.value.id,
      quantity: newItemQuantity.value,
      price:
        selectedProductToAdd.value.sale_price ||
        selectedProductToAdd.value.regular_price,
      // Store product details to ensure they're available in the UI
      product_details: {
        name: selectedProductToAdd.value.name,
        image:
          selectedProductToAdd.value.image_details &&
          selectedProductToAdd.value.image_details.length > 0
            ? [selectedProductToAdd.value.image_details[0].image]
            : [],
      },
    };

    console.log("Adding new item with details:", newItem);

    // Check if product already exists in order
    const existingItemIndex = editingOrderItems.value.findIndex(
      (item) => item.product === newItem.product
    );

    if (existingItemIndex !== -1) {
      // Update existing item
      editingOrderItems.value[existingItemIndex].quantity += newItem.quantity;
      console.log("Updated existing item quantity");
    } else {
      // Add new item
      editingOrderItems.value.push(newItem);
      console.log("Added new item to order");
    }

    // Reset form
    orderItemAddition.value = null;
    selectedProductToAdd.value = null;
    newItemQuantity.value = 1;
    showAddItemModal.value = false;

    // Show success message
    showToast("success", "Item Added", "Product has been added to the order");
  } catch (error) {
    console.error("Error adding item:", error);
    showToast("error", "Error", "Failed to add item to order");
  } finally {
    isAddingItem.value = false;
  }
};

const saveOrderItemChanges = async () => {
  const res = await patch(`/orders/${selectedOrder.value.id}/`, {
    delivery_fee: editingDeliveryFee.value,
    total: calculateTotal(),
  });
  console.log(res);
  console.log(editingOrderItems.value, "new order items");
  const res2 = await put(`/orders/${selectedOrder.value.id}/update/`, {
    items: editingOrderItems.value,
  });
  console.log(res2, "res2");
  if (res.data) {
    // Show success toast
    showToast(
      "success",
      "Order Items Updated",
      "Order items have been successfully updated."
    );
    await getOrders();
  } else {
    // Show error toast
    showToast(
      "error",
      "Update Failed",
      "There was an error updating the order items."
    );
  }
  showOrderDetailsModal.value = false;
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
      // Ensure we only update if we get valid data
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

// Safe initialization - use Promise.allSettled to handle potential failures
onMounted(async () => {
  try {
    await Promise.allSettled([getStoreDetails(), getProducts(), getOrders()]);
    console.log("All data loading attempts completed");
  } catch (error) {
    console.error("Error during initialization:", error);
  }
});
</script>
