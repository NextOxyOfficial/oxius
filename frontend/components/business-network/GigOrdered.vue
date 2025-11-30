<template>
  <div class="space-y-4 sm:space-y-6">
    <!-- Status Filter Dropdown -->
    <div class="flex items-center justify-between">
      <div class="flex items-center gap-3">
        <!-- Status Dropdown -->
        <div class="relative">
          <button
            @click="showStatusDropdown = !showStatusDropdown"
            class="flex items-center gap-2 px-3 sm:px-4 py-2 bg-white border border-gray-200 rounded-lg hover:bg-gray-50 transition-colors text-sm font-medium"
          >
            <span class="text-gray-700">{{ getActiveStatusLabel() }}</span>
            <span 
              v-if="getActiveStatusCount() > 0"
              class="inline-flex items-center justify-center min-w-[20px] h-5 px-1.5 rounded-full text-xs font-medium bg-purple-100 text-purple-600"
            >
              {{ getActiveStatusCount() }}
            </span>
            <ChevronDown class="h-4 w-4 text-gray-400" />
          </button>
          
          <!-- Dropdown Menu -->
          <div 
            v-if="showStatusDropdown"
            class="absolute left-0 mt-2 w-48 bg-white rounded-lg shadow-lg border border-gray-200 z-50 py-1"
          >
            <button
              v-for="status in statusTabs"
              :key="status.id"
              @click="selectStatus(status.id)"
              :class="[
                'w-full flex items-center justify-between px-4 py-2.5 text-sm transition-colors',
                activeStatus === status.id
                  ? 'bg-purple-50 text-purple-600'
                  : 'text-gray-700 hover:bg-gray-50'
              ]"
            >
              <span>{{ status.name }}</span>
              <span
                v-if="status.count > 0"
                :class="[
                  'inline-flex items-center justify-center min-w-[20px] h-5 px-1.5 rounded-full text-xs font-medium',
                  activeStatus === status.id
                    ? 'bg-purple-100 text-purple-600'
                    : 'bg-gray-100 text-gray-500'
                ]"
              >
                {{ status.count }}
              </span>
            </button>
          </div>
        </div>
      </div>
      
      <!-- Results count -->
      <p class="text-sm text-gray-500">
        {{ filteredOrders.length }} order{{ filteredOrders.length !== 1 ? 's' : '' }}
      </p>
    </div>
    
    <!-- Click outside to close dropdown -->
    <div v-if="showStatusDropdown" class="fixed inset-0 z-40" @click="showStatusDropdown = false"></div>

    <!-- Orders List -->
    <div class="space-y-4">
      <!-- Loading State -->
      <div v-if="isLoading" class="space-y-4">
        <div
          v-for="i in 3"
          :key="i"
          class="bg-white border border-gray-200 rounded-xl p-6 animate-pulse"
        >
          <div class="flex items-start space-x-4">
            <div class="w-20 h-20 bg-gray-200 rounded-lg"></div>
            <div class="flex-1 space-y-2">
              <div class="h-4 bg-gray-200 rounded w-3/4"></div>
              <div class="h-3 bg-gray-200 rounded w-1/2"></div>
              <div class="h-3 bg-gray-200 rounded w-1/4"></div>
            </div>
          </div>
        </div>
      </div>

      <!-- Orders Grid -->
      <div v-else-if="filteredOrders.length > 0" class="grid gap-3 sm:gap-4">
        <div
          v-for="order in filteredOrders"
          :key="order.id"
          class="bg-white border border-gray-200 rounded-lg sm:rounded-xl hover:shadow-md transition-all duration-200"
        >
          <div class="p-4 sm:p-6">
            <!-- Order Header - Mobile Optimized -->
            <div class="flex flex-col sm:flex-row sm:items-start sm:justify-between gap-3 sm:gap-4 mb-4">
              <div class="flex items-start space-x-3 sm:space-x-4">
                <!-- Gig Image -->
                <div class="w-16 h-16 sm:w-20 sm:h-20 rounded-lg overflow-hidden flex-shrink-0 bg-gray-100">
                  <img
                    :src="order.gig.image"
                    :alt="order.gig.title"
                    class="w-full h-full object-cover"
                  />
                </div>
                
                <!-- Order Info -->
                <div class="flex-1 min-w-0">
                  <NuxtLink 
                    :to="`/business-network/workspace-details?id=${order.gig.id}`"
                    class="text-sm sm:text-base font-semibold text-gray-900 mb-1 sm:mb-2 line-clamp-2 hover:text-purple-600 transition-colors block"
                    @click.stop
                  >
                    {{ order.gig.title }}
                  </NuxtLink>
                  
                  <div class="flex items-center space-x-2 mb-1 sm:mb-2">
                    <img
                      :src="order.seller.avatar"
                      :alt="order.seller.name"
                      class="h-5 w-5 sm:h-6 sm:w-6 rounded-full object-cover"
                    />
                    <NuxtLink 
                      :to="`/business-network/profile/${order.seller.id}`"
                      class="text-xs sm:text-sm text-gray-600 truncate hover:text-purple-600 transition-colors flex items-center gap-1"
                      @click.stop
                    >
                      by <span class="font-medium hover:underline">{{ order.seller.name }}</span>
                      <!-- Verified Badge -->
                      <UIcon v-if="order.seller.kyc" name="i-heroicons-check-badge-solid" class="w-4 h-4 text-blue-500 flex-shrink-0" />
                      <!-- Pro Badge -->
                      <span v-if="order.seller.is_pro" class="inline-flex items-center px-1.5 py-0.5 rounded text-[10px] font-bold bg-gradient-to-r from-amber-400 to-orange-500 text-white">
                        PRO
                      </span>
                    </NuxtLink>
                  </div>
                  
                  <div class="flex flex-wrap items-center gap-x-2 sm:gap-x-4 gap-y-1 text-xs sm:text-sm text-gray-500">
                    <span>Order #{{ order.orderNumber }}</span>
                    <span class="hidden sm:inline">•</span>
                    <span>{{ formatDate(order.orderDate) }}</span>
                  </div>
                </div>
              </div>

              <!-- Status Badge - Mobile: Below header, Desktop: Right side -->
              <div class="flex-shrink-0 self-start sm:self-auto">
                <span
                  :class="[
                    'inline-flex items-center px-2.5 sm:px-3 py-1 rounded-full text-xs font-medium',
                    getStatusBadgeClass(order.status)
                  ]"
                >
                  {{ getStatusLabel(order.status) }}
                </span>
              </div>
            </div>

            <!-- Order Details - Responsive Grid -->
            <div class="border-t border-gray-100 pt-3 sm:pt-4">
              <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-3 sm:gap-4">
                <!-- Order Stats -->
                <div class="grid grid-cols-3 sm:flex sm:items-center gap-2 sm:gap-6 text-xs sm:text-sm">
                  <div class="text-center sm:text-left">
                    <span class="text-gray-500 block sm:inline">Price</span>
                    <span class="font-semibold text-gray-900 sm:ml-1 inline-flex items-center"><UIcon name="i-mdi:currency-bdt" />{{ order.amount }}</span>
                  </div>
                  <div v-if="order.deliveryDate" class="text-center sm:text-left">
                    <span class="text-gray-500 block sm:inline">Delivery</span>
                    <span class="font-semibold text-gray-900 sm:ml-1">{{ formatDate(order.deliveryDate) }}</span>
                  </div>
                  <div v-if="order.status === 'in_progress' && order.timeRemaining" class="text-center sm:text-left">
                    <span class="text-gray-500 block sm:inline">Time Left</span>
                    <span class="font-semibold text-orange-600 sm:ml-1">{{ order.timeRemaining }}</span>
                  </div>
                </div>
                
                <!-- Action Buttons - Responsive -->
                <div class="flex items-center justify-end gap-2">
                  <button
                    @click="openChat(order)"
                    class="relative flex-1 sm:flex-none px-3 sm:px-4 py-2 border border-gray-200 text-gray-700 rounded-lg hover:bg-gray-50 transition-colors text-xs sm:text-sm font-medium flex items-center justify-center gap-1.5 sm:gap-2"
                  >
                    <img src="/images/chat_icon.png" alt="Chat" class="h-4 w-4 sm:h-5 sm:w-5" />
                    <span>Chat</span>
                    <span
                      v-if="order.unreadMessages && order.unreadMessages > 0"
                      class="absolute -top-1 -right-1 bg-red-500 text-white text-xs font-bold rounded-full h-4 w-4 sm:h-5 sm:w-5 flex items-center justify-center"
                    >
                      {{ order.unreadMessages > 9 ? '9+' : order.unreadMessages }}
                    </span>
                  </button>
                  
                  <button
                    v-if="order.status === 'delivered'"
                    @click="leaveReview(order)"
                    class="flex-1 sm:flex-none px-3 sm:px-4 py-2 bg-purple-600 text-white rounded-lg hover:bg-purple-700 transition-colors text-xs sm:text-sm font-medium flex items-center justify-center gap-1.5 sm:gap-2"
                  >
                    <Star class="h-3.5 w-3.5 sm:h-4 sm:w-4" />
                    <span>Review</span>
                  </button>
                  
                  <button
                    v-else-if="order.status === 'pending'"
                    @click="cancelOrder(order)"
                    class="flex-1 sm:flex-none px-3 sm:px-4 py-2 border border-red-200 text-red-600 rounded-lg hover:bg-red-50 transition-colors text-xs sm:text-sm font-medium"
                  >
                    Cancel
                  </button>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- Empty State -->
      <div
        v-else
        class="flex flex-col items-center justify-center py-16 bg-gray-50/50 rounded-xl border border-dashed border-gray-200"
      >
        <div class="text-center">
          <div class="w-16 h-16 bg-purple-100 rounded-full flex items-center justify-center mx-auto mb-4">
            <ShoppingCart class="h-8 w-8 text-purple-600" />
          </div>
          <h3 class="text-lg font-semibold text-gray-900 mb-2">
            {{ getEmptyStateTitle() }}
          </h3>
          <p class="text-gray-600 mb-4">
            {{ getEmptyStateDescription() }}
          </p>
          <button
            @click="$emit('switchTab', 'all-gigs')"
            class="inline-flex items-center px-6 py-3 rounded-lg bg-purple-600 text-white hover:bg-purple-700 transition-colors font-medium"
          >
            <ShoppingCart class="h-4 w-4 mr-2" />
            Browse Gigs
          </button>
        </div>
      </div>
    </div>

    <!-- Cancel Order Modal -->
    <div
      v-if="showCancelModal"
      class="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50"
      @click.self="!isCancelling && (showCancelModal = false)"
    >
      <div class="bg-white rounded-xl shadow-xl p-6 max-w-md w-full mx-4">
        <h3 class="text-lg font-semibold text-gray-900 mb-4">Cancel Order</h3>
        <p class="text-gray-600 mb-2">
          Are you sure you want to cancel this order?
        </p>
        <p class="text-sm text-green-600 mb-6">
          ৳{{ orderToCancel?.amount }} will be refunded to your balance.
        </p>
        <div class="flex space-x-3">
          <button
            @click="showCancelModal = false"
            :disabled="isCancelling"
            class="flex-1 px-4 py-2 border border-gray-200 text-gray-700 rounded-lg hover:bg-gray-50 transition-colors disabled:opacity-50"
          >
            Keep Order
          </button>
          <button
            @click="confirmCancelOrder"
            :disabled="isCancelling"
            class="flex-1 px-4 py-2 bg-red-600 text-white rounded-lg hover:bg-red-700 transition-colors disabled:opacity-50 flex items-center justify-center gap-2"
          >
            <span v-if="isCancelling" class="animate-spin w-4 h-4 border-2 border-white border-t-transparent rounded-full"></span>
            <span>{{ isCancelling ? 'Cancelling...' : 'Cancel Order' }}</span>
          </button>
        </div>
      </div>
    </div>
  </div>

  <!-- Chat Bottom Sheet -->
  <BusinessNetworkOrderChatSheet
    v-model:isOpen="showChatSheet"
    :orderId="selectedOrder?.id"
    :orderNumber="selectedOrder?.orderNumber"
    :otherUser="selectedOrder?.seller"
    :currentUserId="user?.user?.id || user?.id"
    @close="selectedOrder = null"
    @messages-read="handleMessagesRead"
  />
</template>

<script setup>
import { ref, computed, onMounted, onUnmounted, watch } from 'vue';
import { Star, ShoppingCart, ChevronDown } from 'lucide-vue-next';

// Emit events
const emit = defineEmits(['switchTab']);

// Reactive data
const activeStatus = ref('all');
const isLoading = ref(true);
const showCancelModal = ref(false);
const orderToCancel = ref(null);
const showStatusDropdown = ref(false);
const showChatSheet = ref(false);
const selectedOrder = ref(null);

// Polling interval for unread counts
let unreadPollingInterval = null;

// Status tabs configuration
const statusTabs = ref([
  { id: 'all', name: 'All Orders', count: 0 },
  { id: 'pending', name: 'Pending', count: 0 },
  { id: 'in_progress', name: 'In Progress', count: 0 },
  { id: 'delivered', name: 'Delivered', count: 0 },
  { id: 'completed', name: 'Completed', count: 0 },
  { id: 'cancelled', name: 'Cancelled', count: 0 }
]);

// Orders data from API
const orders = ref([]);
const { get, post } = useApi();
const { user } = useAuth();
const toast = useToast();
const { clearWorkspaceOrderCount } = useNotifications();

// Fetch orders from API
async function fetchOrders() {
  isLoading.value = true;
  
  console.log('GigOrdered: Current user:', user.value?.email);
  
  if (!user.value) {
    console.log('GigOrdered: No user logged in, skipping fetch');
    isLoading.value = false;
    return;
  }
  
  try {
    const { data, error } = await get('/workspace/orders/');
    
    console.log('GigOrdered API response:', { data, error });
    
    if (error) {
      console.error('Error fetching orders:', error);
      console.error('Error status:', error?.response?.status || error?.status);
      console.error('Error message:', error?.message || error?.data?.detail);
      orders.value = [];
      return;
    }
    
    const results = data?.results || data || [];
    console.log('GigOrdered parsed results count:', results.length);
    orders.value = results.map(order => ({
      id: order.id,
      orderNumber: `ORD-${String(order.id).slice(0, 8).toUpperCase()}`,
      status: order.status,
      orderDate: new Date(order.created_at),
      deliveryDate: order.delivery_date ? new Date(order.delivery_date) : null,
      amount: parseFloat(order.price),
      timeRemaining: calculateTimeRemaining(order.delivery_date),
      unreadMessages: 0,
      gig: {
        id: order.gig?.id,
        title: order.gig?.title || 'Unknown Gig',
        image: order.gig?.image_url || order.gig?.image || '/images/placeholder-gig.png'
      },
      seller: {
        id: order.seller?.id,
        name: order.seller?.name || 'Unknown Seller',
        avatar: order.seller?.avatar || '/images/default-avatar.png',
        kyc: order.seller?.kyc || false,
        is_pro: order.seller?.is_pro || false
      }
    }));
    
    updateStatusCounts();
    
    // Fetch unread message counts
    await fetchUnreadCounts();
  } catch (err) {
    console.error('Error fetching orders:', err);
    orders.value = [];
  } finally {
    isLoading.value = false;
  }
}

// Fetch unread message counts
async function fetchUnreadCounts() {
  try {
    const { data, error } = await get('/workspace/orders/unread-counts/');
    if (data && !error && data.counts) {
      // Update unread counts for each order
      orders.value.forEach(order => {
        order.unreadMessages = data.counts[order.id] || 0;
      });
    }
  } catch (err) {
    console.error('Error fetching unread counts:', err);
  }
}

const calculateTimeRemaining = (deliveryDate) => {
  if (!deliveryDate) return null;
  const now = new Date();
  const delivery = new Date(deliveryDate);
  const diffTime = delivery.getTime() - now.getTime();
  const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24));
  
  if (diffDays < 0) return 'Overdue';
  if (diffDays === 0) return 'Today';
  if (diffDays === 1) return '1 day';
  return `${diffDays} days`;
};

// Computed properties
const filteredOrders = computed(() => {
  if (activeStatus.value === 'all') {
    return orders.value;
  }
  return orders.value.filter(order => order.status === activeStatus.value);
});

// Update status counts
const updateStatusCounts = () => {
  statusTabs.value.forEach(tab => {
    if (tab.id === 'all') {
      tab.count = orders.value.length;
    } else {
      tab.count = orders.value.filter(order => order.status === tab.id).length;
    }
  });
};

// Dropdown helper methods
const getActiveStatusLabel = () => {
  const activeTab = statusTabs.value.find(tab => tab.id === activeStatus.value);
  return activeTab ? activeTab.name : 'All Orders';
};

const getActiveStatusCount = () => {
  const activeTab = statusTabs.value.find(tab => tab.id === activeStatus.value);
  return activeTab ? activeTab.count : 0;
};

const selectStatus = (statusId) => {
  activeStatus.value = statusId;
  showStatusDropdown.value = false;
};

// Utility functions
const formatDate = (date) => {
  return new Date(date).toLocaleDateString('en-US', {
    month: 'short',
    day: 'numeric',
    year: 'numeric'
  });
};

const getStatusBadgeClass = (status) => {
  const classes = {
    pending: 'bg-yellow-100 text-yellow-800',
    in_progress: 'bg-blue-100 text-blue-800',
    delivered: 'bg-purple-100 text-purple-800',
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

const getEmptyStateTitle = () => {
  const titles = {
    all: 'No orders yet',
    pending: 'No pending orders',
    in_progress: 'No orders in progress',
    delivered: 'No delivered orders',
    completed: 'No completed orders',
    cancelled: 'No cancelled orders'
  };
  return titles[activeStatus.value] || 'No orders found';
};

const getEmptyStateDescription = () => {
  const descriptions = {
    all: 'Start browsing gigs and place your first order',
    pending: 'All orders are either accepted or in progress',
    in_progress: 'No orders are currently being worked on',
    delivered: 'No orders have been delivered yet',
    completed: 'No orders have been completed and reviewed',
    cancelled: 'No orders have been cancelled'
  };
  return descriptions[activeStatus.value] || 'Try browsing available gigs';
};

// Methods
const openChat = (order) => {
  selectedOrder.value = order;
  showChatSheet.value = true;
};

const leaveReview = (order) => {
  console.log('Leaving review for order:', order.orderNumber);
  // Here you would implement the review functionality
};

const cancelOrder = (order) => {
  orderToCancel.value = order;
  showCancelModal.value = true;
};

const isCancelling = ref(false);

const confirmCancelOrder = async () => {
  if (!orderToCancel.value || isCancelling.value) return;
  
  isCancelling.value = true;
  
  try {
    const { data, error } = await post(`/workspace/orders/${orderToCancel.value.id}/cancel/`);
    
    if (error) {
      toast.add({
        title: 'Cancel Failed',
        description: error.message || error.error || 'Failed to cancel order',
        color: 'red',
      });
      return;
    }
    
    // Update order status locally
    orderToCancel.value.status = 'cancelled';
    
    // Update counts
    updateStatusCounts();
    
    toast.add({
      title: 'Order Cancelled',
      description: `৳${data.refund?.amount || orderToCancel.value.amount} has been refunded to your balance.`,
      color: 'green',
    });
    
    console.log('Order cancelled:', orderToCancel.value.orderNumber, 'Refund:', data.refund);
    
  } catch (err) {
    console.error('Cancel error:', err);
    toast.add({
      title: 'Error',
      description: 'An unexpected error occurred',
      color: 'red',
    });
  } finally {
    isCancelling.value = false;
    showCancelModal.value = false;
    orderToCancel.value = null;
  }
};

// Handle messages read event from chat
const handleMessagesRead = ({ orderId, count }) => {
  const order = orders.value.find(o => o.id === orderId);
  if (order) {
    order.unreadMessages = Math.max(0, order.unreadMessages - count);
    // Also update global notification count
    clearWorkspaceOrderCount(orderId, count);
  }
};

// Start polling for unread counts
const startUnreadPolling = () => {
  if (unreadPollingInterval) clearInterval(unreadPollingInterval);
  
  unreadPollingInterval = setInterval(() => {
    if (!showChatSheet.value) {
      fetchUnreadCounts();
    }
  }, 10000); // Poll every 10 seconds when chat is not open
};

// Stop polling
const stopUnreadPolling = () => {
  if (unreadPollingInterval) {
    clearInterval(unreadPollingInterval);
    unreadPollingInterval = null;
  }
};

// Lifecycle
onMounted(() => {
  fetchOrders();
  startUnreadPolling();
});

onUnmounted(() => {
  stopUnreadPolling();
});

// Watch for user changes
watch(() => user.value, (newUser) => {
  if (newUser) {
    fetchOrders();
  }
}, { immediate: false });
</script>

<style scoped>
.line-clamp-2 {
  display: -webkit-box;
  -webkit-line-clamp: 2;
  line-clamp: 2;
  -webkit-box-orient: vertical;
  overflow: hidden;
}

.scrollbar-hide {
  -ms-overflow-style: none;
  scrollbar-width: none;
}

.scrollbar-hide::-webkit-scrollbar {
  display: none;
}
</style>
