<template>
  <div class="space-y-4 sm:space-y-6">
    <!-- Filter Dropdown -->
    <div class="flex items-center justify-between">
      <div class="relative">
        <button
          @click="showFilterDropdown = !showFilterDropdown"
          class="flex items-center gap-2 px-4 py-2 bg-white border border-gray-200 rounded-lg hover:bg-gray-50 transition-colors shadow-sm"
        >
          <span class="text-sm font-medium text-gray-700">{{ getFilterLabel(activeFilter) }}</span>
          <span 
            v-if="getFilterCount(activeFilter) > 0"
            class="inline-flex items-center justify-center min-w-[20px] h-5 px-1.5 text-xs font-semibold rounded-full bg-purple-100 text-purple-600"
          >
            {{ getFilterCount(activeFilter) }}
          </span>
          <UIcon 
            name="i-heroicons-chevron-down" 
            class="w-4 h-4 text-gray-500 transition-transform"
            :class="{ 'rotate-180': showFilterDropdown }"
          />
        </button>
        
        <!-- Dropdown Backdrop -->
        <div 
          v-if="showFilterDropdown" 
          class="fixed inset-0 z-10" 
          @click="showFilterDropdown = false"
        ></div>
        
        <!-- Dropdown Menu -->
        <div
          v-if="showFilterDropdown"
          class="absolute top-full left-0 mt-1 w-48 bg-white border border-gray-200 rounded-lg shadow-lg z-20 overflow-hidden"
        >
          <button
            v-for="filter in orderFilters"
            :key="filter.value"
            @click="selectFilter(filter.value)"
            :class="[
              'w-full flex items-center justify-between px-4 py-2.5 text-sm transition-colors',
              activeFilter === filter.value
                ? 'bg-purple-50 text-purple-700 font-medium'
                : 'text-gray-700 hover:bg-gray-50'
            ]"
          >
            <span>{{ filter.label }}</span>
            <span 
              v-if="getFilterCount(filter.value) > 0"
              :class="[
                'inline-flex items-center justify-center min-w-[20px] h-5 px-1.5 text-xs font-semibold rounded-full',
                activeFilter === filter.value
                  ? 'bg-purple-200 text-purple-700'
                  : 'bg-gray-100 text-gray-600'
              ]"
            >
              {{ getFilterCount(filter.value) }}
            </span>
          </button>
        </div>
      </div>
      
      <!-- Total Orders Count -->
      <span class="text-sm text-gray-500">
        {{ filteredOrders.length }} order{{ filteredOrders.length !== 1 ? 's' : '' }}
      </span>
    </div>

    <!-- Loading State -->
    <div v-if="isLoading" class="space-y-3 sm:space-y-4">
      <div
        v-for="i in 3"
        :key="i"
        class="bg-white rounded-lg sm:rounded-xl border border-gray-200 p-3 sm:p-5 animate-pulse"
      >
        <div class="flex items-start space-x-3">
          <div class="w-14 h-14 sm:w-16 sm:h-16 rounded-lg bg-gray-200"></div>
          <div class="flex-1 space-y-2">
            <div class="h-4 bg-gray-200 rounded w-3/4"></div>
            <div class="h-3 bg-gray-200 rounded w-1/2"></div>
            <div class="h-3 bg-gray-200 rounded w-1/4"></div>
          </div>
        </div>
        <div class="grid grid-cols-3 gap-2 mt-4 pt-3 border-t border-gray-100">
          <div class="h-8 bg-gray-200 rounded"></div>
          <div class="h-8 bg-gray-200 rounded"></div>
          <div class="h-8 bg-gray-200 rounded"></div>
        </div>
      </div>
    </div>

    <!-- Orders List -->
    <div v-else-if="filteredOrders.length > 0" class="space-y-3 sm:space-y-4">
      <div
        v-for="order in filteredOrders"
        :key="order.id"
        class="bg-white rounded-lg sm:rounded-xl border border-gray-200 overflow-hidden hover:shadow-sm transition-shadow"
      >
        <div class="p-3 sm:p-5">
          <!-- Order Header - Mobile Optimized -->
          <div class="flex flex-col sm:flex-row sm:items-start gap-3 mb-3 sm:mb-4">
            <div class="flex items-start space-x-3">
              <!-- Gig Image -->
              <div class="w-14 h-14 sm:w-16 sm:h-16 rounded-lg overflow-hidden bg-gray-100 flex-shrink-0">
                <img
                  :src="order.gig.image"
                  :alt="order.gig.title"
                  class="w-full h-full object-cover"
                />
              </div>
              
              <!-- Order Info -->
              <div class="flex-1 min-w-0">
                <div class="flex items-start justify-between gap-2">
                  <h3 class="text-sm sm:text-base font-semibold text-gray-900 line-clamp-2">
                    {{ order.gig.title }}
                  </h3>
                  <!-- Status Badge - Mobile inline -->
                  <div :class="getStatusClass(order.status)" class="flex-shrink-0 px-2 py-0.5 sm:py-1 rounded-full text-xs font-medium whitespace-nowrap">
                    {{ getStatusLabel(order.status) }}
                  </div>
                </div>
                <p class="text-xs sm:text-sm text-gray-600 mt-1">
                  from {{ order.buyer.name }}
                </p>
                <div class="flex flex-wrap items-center gap-x-2 gap-y-0.5 text-xs text-gray-500 mt-1">
                  <span>Order #{{ String(order.id).slice(0, 8) }}</span>
                  <span class="hidden sm:inline">•</span>
                  <span>{{ formatDate(order.createdAt) }}</span>
                </div>
              </div>
            </div>
          </div>

          <!-- Order Details Grid - Responsive -->
          <div class="grid grid-cols-3 gap-2 sm:gap-4 py-3 border-t border-gray-100">
            <div class="text-center sm:text-left">
              <p class="text-xs text-gray-500 mb-0.5">Amount</p>
              <p class="text-sm sm:text-base font-semibold text-gray-900 inline-flex items-center justify-center sm:justify-start"><UIcon name="i-mdi:currency-bdt" />{{ order.amount }}</p>
            </div>
            <div class="text-center sm:text-left">
              <p class="text-xs text-gray-500 mb-0.5">Delivery</p>
              <p class="text-sm sm:text-base font-medium text-gray-700">{{ formatDeliveryDate(order.deliveryDate) }}</p>
            </div>
            <div class="text-center sm:text-left">
              <p class="text-xs text-gray-500 mb-0.5">Revisions</p>
              <p class="text-sm sm:text-base font-medium text-gray-700">{{ order.revisions || 'N/A' }}</p>
            </div>
          </div>

          <!-- Action Buttons - Responsive -->
          <div v-if="order.status !== 'cancelled'" class="flex flex-row gap-2 pt-3 border-t border-gray-100">
            <button
              @click="openChat(order)"
              :class="[
                'relative px-3 sm:px-4 py-2 border border-gray-200 text-gray-700 rounded-lg hover:bg-gray-50 transition-colors text-xs font-medium flex items-center justify-center gap-1',
                order.status === 'pending' || order.status === 'in_progress' ? 'flex-1' : 'flex-none'
              ]"
            >
              <img src="/images/chat_icon.png" alt="Chat" class="h-4 w-4" />
              <span class="hidden xs:inline">Chat</span>
              <span
                v-if="order.unreadMessages && order.unreadMessages > 0"
                class="absolute -top-1 -right-1 bg-red-500 text-white text-xs font-bold rounded-full h-4 w-4 flex items-center justify-center"
              >
                {{ order.unreadMessages > 9 ? '9+' : order.unreadMessages }}
              </span>
            </button>
            
            <button
              v-if="order.status === 'pending'"
              @click="acceptOrder(order)"
              class="flex-1 px-2 py-2 bg-green-600 text-white rounded-lg hover:bg-green-700 transition-colors text-xs font-medium"
            >
              Accept Order
            </button>
            
            <button
              v-if="order.status === 'pending'"
              @click="declineOrder(order)"
              class="flex-1 px-2 py-2 border border-red-200 text-red-600 rounded-lg hover:bg-red-50 transition-colors text-xs font-medium"
            >
              Decline
            </button>
            
            <button
              v-if="order.status === 'in_progress'"
              @click="deliverOrder(order)"
              class="flex-1 px-2 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors text-xs font-medium"
            >
              Deliver Order
            </button>
          </div>
        </div>
      </div>
    </div>

    <!-- Empty State -->
    <div v-else-if="!isLoading" class="flex flex-col items-center justify-center py-12 sm:py-16 bg-gray-50/50 rounded-lg sm:rounded-xl border border-dashed border-gray-200">
      <div class="text-center px-4">
        <div class="w-14 h-14 sm:w-16 sm:h-16 bg-purple-100 rounded-full flex items-center justify-center mx-auto mb-3 sm:mb-4">
          <ShoppingCart class="h-7 w-7 sm:h-8 sm:w-8 text-purple-600" />
        </div>
        <h3 class="text-base sm:text-lg font-semibold text-gray-900 mb-1 sm:mb-2">
          No {{ getFilterLabel(activeFilter) }} Orders
        </h3>
        <p class="text-sm sm:text-base text-gray-600 mb-4 max-w-xs mx-auto">
          You don't have any {{ getFilterLabel(activeFilter).toLowerCase() }} orders at the moment.
        </p>
        <button
          @click="$emit('switchTab', 'all-gigs')"
          class="inline-flex items-center px-4 sm:px-6 py-2 sm:py-3 rounded-lg bg-purple-600 text-white hover:bg-purple-700 transition-colors text-sm sm:text-base font-medium"
        >
          <ShoppingCart class="h-4 w-4 mr-2" />
          Browse Gigs
        </button>
      </div>
    </div>

  </div>

  <!-- Chat Bottom Sheet -->
  <BusinessNetworkOrderChatSheet
    v-model:isOpen="showChatSheet"
    :orderId="selectedOrder?.id"
    :orderNumber="'ORD-' + String(selectedOrder?.id || '').slice(0, 8).toUpperCase()"
    :otherUser="selectedOrder?.buyer"
    :currentUserId="currentUser?.id"
    @close="selectedOrder = null"
  />

  <!-- Deliver Order Confirmation Modal -->
  <Teleport to="body">
    <Transition name="fade">
      <div v-if="showDeliverModal" class="fixed inset-0 bg-black/50 z-50 flex items-center justify-center p-4" @click="showDeliverModal = false">
        <div class="bg-white rounded-2xl shadow-xl max-w-md w-full overflow-hidden" @click.stop>
          <!-- Header -->
          <div class="bg-gradient-to-r from-blue-500 to-blue-600 px-6 py-4">
            <div class="flex items-center gap-3">
              <div class="w-12 h-12 bg-white/20 rounded-full flex items-center justify-center">
                <UIcon name="i-heroicons-truck" class="w-6 h-6 text-white" />
              </div>
              <div>
                <h3 class="text-lg font-semibold text-white">Deliver Order</h3>
                <p class="text-blue-100 text-sm">Order #{{ orderToAction?.id?.slice(0, 8).toUpperCase() }}</p>
              </div>
            </div>
          </div>
          
          <!-- Content -->
          <div class="p-6">
            <p class="text-gray-600 mb-4">
              You're about to mark this order as delivered. Please ensure:
            </p>
            <ul class="space-y-2 mb-6">
              <li class="flex items-start gap-2">
                <UIcon name="i-heroicons-check-circle" class="w-5 h-5 text-green-500 mt-0.5 flex-shrink-0" />
                <span class="text-sm text-gray-700">All deliverables are complete and attached</span>
              </li>
              <li class="flex items-start gap-2">
                <UIcon name="i-heroicons-check-circle" class="w-5 h-5 text-green-500 mt-0.5 flex-shrink-0" />
                <span class="text-sm text-gray-700">Work meets the requirements specified</span>
              </li>
              <li class="flex items-start gap-2">
                <UIcon name="i-heroicons-check-circle" class="w-5 h-5 text-green-500 mt-0.5 flex-shrink-0" />
                <span class="text-sm text-gray-700">Files are properly formatted and accessible</span>
              </li>
            </ul>
            
            <!-- Delivery Note -->
            <div class="mb-4">
              <label class="block text-sm font-medium text-gray-700 mb-2">Delivery Note (Optional)</label>
              <textarea
                v-model="deliveryNote"
                placeholder="Add a message for the buyer..."
                rows="3"
                class="w-full px-3 py-2 border border-gray-200 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500 text-sm resize-none"
              ></textarea>
            </div>
          </div>
          
          <!-- Actions -->
          <div class="px-6 py-4 bg-gray-50 flex gap-3">
            <button
              @click="showDeliverModal = false"
              class="flex-1 px-4 py-2.5 border border-gray-200 text-gray-700 rounded-lg hover:bg-gray-100 transition-colors font-medium"
            >
              Cancel
            </button>
            <button
              @click="confirmDeliverOrder"
              :disabled="isProcessing"
              class="flex-1 px-4 py-2.5 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors font-medium flex items-center justify-center gap-2 disabled:opacity-50"
            >
              <UIcon v-if="isProcessing" name="i-heroicons-arrow-path" class="w-4 h-4 animate-spin" />
              <span>{{ isProcessing ? 'Delivering...' : 'Confirm Delivery' }}</span>
            </button>
          </div>
        </div>
      </div>
    </Transition>
  </Teleport>

  <!-- Decline Order Confirmation Modal -->
  <Teleport to="body">
    <Transition name="fade">
      <div v-if="showDeclineModal" class="fixed inset-0 bg-black/50 z-50 flex items-center justify-center p-4" @click="showDeclineModal = false">
        <div class="bg-white rounded-2xl shadow-xl max-w-md w-full overflow-hidden" @click.stop>
          <!-- Header -->
          <div class="bg-gradient-to-r from-red-500 to-red-600 px-6 py-4">
            <div class="flex items-center gap-3">
              <div class="w-12 h-12 bg-white/20 rounded-full flex items-center justify-center">
                <UIcon name="i-heroicons-x-circle" class="w-6 h-6 text-white" />
              </div>
              <div>
                <h3 class="text-lg font-semibold text-white">Decline Order</h3>
                <p class="text-red-100 text-sm">Order #{{ orderToAction?.id?.slice(0, 8).toUpperCase() }}</p>
              </div>
            </div>
          </div>
          
          <!-- Content -->
          <div class="p-6">
            <div class="flex items-start gap-3 p-4 bg-amber-50 border border-amber-200 rounded-lg mb-4">
              <UIcon name="i-heroicons-exclamation-triangle" class="w-5 h-5 text-amber-500 mt-0.5 flex-shrink-0" />
              <p class="text-sm text-amber-800">
                Declining orders may affect your seller rating. Please only decline if you cannot fulfill this order.
              </p>
            </div>
            
            <!-- Decline Reason -->
            <div class="mb-4">
              <label class="block text-sm font-medium text-gray-700 mb-2">Reason for Declining <span class="text-red-500">*</span></label>
              <select
                v-model="declineReason"
                class="w-full px-3 py-2.5 border border-gray-200 rounded-lg focus:ring-2 focus:ring-red-500 focus:border-red-500 text-sm"
              >
                <option value="">Select a reason</option>
                <option value="busy">Too busy / Overbooked</option>
                <option value="scope">Project scope unclear</option>
                <option value="budget">Budget too low</option>
                <option value="timeline">Timeline too short</option>
                <option value="expertise">Outside my expertise</option>
                <option value="other">Other reason</option>
              </select>
            </div>
            
            <!-- Additional Notes -->
            <div>
              <label class="block text-sm font-medium text-gray-700 mb-2">Additional Notes (Optional)</label>
              <textarea
                v-model="declineNote"
                placeholder="Provide more details to the buyer..."
                rows="3"
                class="w-full px-3 py-2 border border-gray-200 rounded-lg focus:ring-2 focus:ring-red-500 focus:border-red-500 text-sm resize-none"
              ></textarea>
            </div>
          </div>
          
          <!-- Actions -->
          <div class="px-6 py-4 bg-gray-50 flex gap-3">
            <button
              @click="showDeclineModal = false"
              class="flex-1 px-4 py-2.5 border border-gray-200 text-gray-700 rounded-lg hover:bg-gray-100 transition-colors font-medium"
            >
              Cancel
            </button>
            <button
              @click="confirmDeclineOrder"
              :disabled="!declineReason || isProcessing"
              class="flex-1 px-4 py-2.5 bg-red-600 text-white rounded-lg hover:bg-red-700 transition-colors font-medium flex items-center justify-center gap-2 disabled:opacity-50 disabled:cursor-not-allowed"
            >
              <UIcon v-if="isProcessing" name="i-heroicons-arrow-path" class="w-4 h-4 animate-spin" />
              <span>{{ isProcessing ? 'Declining...' : 'Decline Order' }}</span>
            </button>
          </div>
        </div>
      </div>
    </Transition>
  </Teleport>
</template>

<script setup>
import { ShoppingCart } from 'lucide-vue-next';
import { ref, computed, onMounted } from 'vue';

// Emit events to parent component
const emit = defineEmits(['switchTab']);

// Composables
const toast = useToast();
const { get } = useApi();
const { user: currentUser } = useAuth();

// Reactive data
const activeFilter = ref('all');
const isLoading = ref(true);
const orders = ref([]);
const showChatSheet = ref(false);
const selectedOrder = ref(null);
const showFilterDropdown = ref(false);

// Modal states
const showDeliverModal = ref(false);
const showDeclineModal = ref(false);
const orderToAction = ref(null);
const isProcessing = ref(false);
const deliveryNote = ref('');
const declineReason = ref('');
const declineNote = ref('');

// Select filter and close dropdown
const selectFilter = (value) => {
  activeFilter.value = value;
  showFilterDropdown.value = false;
};

// Order filters
const orderFilters = [
  { label: 'All Orders', value: 'all' },
  { label: 'Pending', value: 'pending' },
  { label: 'In Progress', value: 'in_progress' },
  { label: 'Completed', value: 'completed' },
  { label: 'Cancelled', value: 'cancelled' }
];

// Fetch orders from API
async function fetchOrders() {
  isLoading.value = true;
  try {
    const { data, error } = await get('/workspace/orders/seller/');
    
    console.log('MyOrders (seller) API response:', { data, error });
    
    if (error) {
      console.error('Error fetching orders:', error);
      orders.value = [];
      return;
    }
    
    const results = data?.results || data || [];
    console.log('MyOrders parsed results:', results);
    orders.value = results.map(order => ({
      id: order.id,
      status: order.status,
      amount: parseFloat(order.price),
      progress: getProgressFromStatus(order.status),
      revisions: order.gig?.revisions || 0,
      unreadMessages: 0,
      createdAt: new Date(order.created_at),
      deliveryDate: order.delivery_date ? new Date(order.delivery_date) : new Date(),
      gig: {
        id: order.gig?.id,
        title: order.gig?.title || 'Unknown Gig',
        image: order.gig?.image_url || order.gig?.image || '/images/placeholder-gig.png'
      },
      buyer: {
        id: order.buyer?.id,
        name: order.buyer?.name || 'Unknown Buyer',
        avatar: order.buyer?.avatar || '/images/default-avatar.png'
      }
    }));
  } catch (err) {
    console.error('Error fetching orders:', err);
    orders.value = [];
  } finally {
    isLoading.value = false;
  }
}

const getProgressFromStatus = (status) => {
  const progressMap = {
    'pending': 0,
    'in_progress': 50,
    'delivered': 100,
    'completed': 100,
    'cancelled': 0,
    'revision': 75
  };
  return progressMap[status] || 0;
};

onMounted(() => {
  fetchOrders();
});

// Computed
const filteredOrders = computed(() => {
  if (activeFilter.value === 'all') {
    return orders.value;
  }
  return orders.value.filter(order => order.status === activeFilter.value);
});

// Methods
const getFilterCount = (filterValue) => {
  if (filterValue === 'all') {
    return orders.value.length;
  }
  return orders.value.filter(order => order.status === filterValue).length;
};

const getFilterLabel = (filterValue) => {
  const filter = orderFilters.find(f => f.value === filterValue);
  return filter ? filter.label : 'Unknown';
};

const getStatusClass = (status) => {
  const classes = {
    pending: 'bg-yellow-100 text-yellow-800',
    in_progress: 'bg-blue-100 text-blue-800',
    delivered: 'bg-green-100 text-green-800',
    completed: 'bg-green-100 text-green-800',
    cancelled: 'bg-red-100 text-red-800'
  };
  return classes[status] || 'bg-gray-100 text-gray-800';
};

const getStatusLabel = (status) => {
  const labels = {
    pending: 'Pending',
    in_progress: 'In Progress',
    delivered: 'Delivered',
    completed: 'Completed',
    cancelled: 'Cancelled'
  };
  return labels[status] || 'Unknown';
};

const formatDate = (date) => {
  return new Intl.DateTimeFormat('en-US', {
    month: 'short',
    day: 'numeric',
    year: 'numeric'
  }).format(date);
};

const formatDeliveryDate = (date) => {
  const now = new Date();
  const diffTime = date.getTime() - now.getTime();
  const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24));
  
  if (diffDays < 0) {
    return 'Overdue';
  } else if (diffDays === 0) {
    return 'Today';
  } else if (diffDays === 1) {
    return 'Tomorrow';
  } else {
    return `${diffDays} days`;
  }
};

// Action methods
const openChat = (order) => {
  selectedOrder.value = order;
  showChatSheet.value = true;
};

const acceptOrder = (order) => {
  order.status = 'in_progress';
  toast.add({
    title: 'Order Accepted',
    description: `Order #${order.id} has been accepted and is now in progress`,
    color: 'green'
  });
};

const declineOrder = (order) => {
  orderToAction.value = order;
  declineReason.value = '';
  declineNote.value = '';
  showDeclineModal.value = true;
};

const deliverOrder = (order) => {
  orderToAction.value = order;
  deliveryNote.value = '';
  showDeliverModal.value = true;
};

const confirmDeliverOrder = async () => {
  if (!orderToAction.value) return;
  
  isProcessing.value = true;
  try {
    // TODO: API call to deliver order
    // await post(`/workspace/orders/${orderToAction.value.id}/deliver/`, { note: deliveryNote.value });
    
    // Update local state
    orderToAction.value.status = 'delivered';
    
    toast.add({
      title: 'Order Delivered! 🎉',
      description: `Order #${orderToAction.value.id.slice(0, 8).toUpperCase()} has been marked as delivered. The buyer will be notified.`,
      color: 'green'
    });
    
    showDeliverModal.value = false;
    orderToAction.value = null;
    deliveryNote.value = '';
  } catch (error) {
    toast.add({
      title: 'Error',
      description: 'Failed to deliver order. Please try again.',
      color: 'red'
    });
  } finally {
    isProcessing.value = false;
  }
};

const confirmDeclineOrder = async () => {
  if (!orderToAction.value || !declineReason.value) return;
  
  isProcessing.value = true;
  try {
    // TODO: API call to decline order
    // await post(`/workspace/orders/${orderToAction.value.id}/decline/`, { 
    //   reason: declineReason.value, 
    //   note: declineNote.value 
    // });
    
    // Update local state
    orderToAction.value.status = 'cancelled';
    
    toast.add({
      title: 'Order Declined',
      description: `Order #${orderToAction.value.id.slice(0, 8).toUpperCase()} has been declined. The buyer will be notified.`,
      color: 'orange'
    });
    
    showDeclineModal.value = false;
    orderToAction.value = null;
    declineReason.value = '';
    declineNote.value = '';
  } catch (error) {
    toast.add({
      title: 'Error',
      description: 'Failed to decline order. Please try again.',
      color: 'red'
    });
  } finally {
    isProcessing.value = false;
  }
};
</script>

<style scoped>
.scrollbar-hide {
  -ms-overflow-style: none;
  scrollbar-width: none;
}

.scrollbar-hide::-webkit-scrollbar {
  display: none;
}

.line-clamp-2 {
  display: -webkit-box;
  -webkit-line-clamp: 2;
  line-clamp: 2;
  -webkit-box-orient: vertical;
  overflow: hidden;
}

/* Modal transitions */
.fade-enter-active,
.fade-leave-active {
  transition: opacity 0.2s ease;
}

.fade-enter-from,
.fade-leave-to {
  opacity: 0;
}
</style>
