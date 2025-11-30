<template>
  <div class="space-y-6">
    <!-- Header -->
    <div class="flex items-center justify-between">
      <div>
        <h2 class="text-lg font-semibold text-gray-900">Gigs You've Ordered</h2>
        <p class="text-sm text-gray-600 mt-1">Track and manage your purchased gigs</p>
      </div>
    </div>

    <!-- Status Filter Tabs -->
    <div class="border-b border-gray-100">
      <nav class="flex space-x-8" aria-label="Tabs">
        <button
          v-for="status in statusTabs"
          :key="status.id"
          @click="activeStatus = status.id"
          :class="[
            'py-3 px-1 border-b-2 font-medium text-sm transition-colors flex items-center',
            activeStatus === status.id
              ? 'border-purple-500 text-purple-600'
              : 'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300'
          ]"
        >
          {{ status.name }}
          <span
            v-if="status.count > 0"
            :class="[
              'ml-2 inline-flex items-center justify-center px-2 py-1 rounded-full text-xs font-medium',
              activeStatus === status.id
                ? 'bg-purple-100 text-purple-600'
                : 'bg-gray-100 text-gray-500'
            ]"
          >
            {{ status.count }}
          </span>
        </button>
      </nav>
    </div>

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
      <div v-else-if="filteredOrders.length > 0" class="grid gap-4">
        <div
          v-for="order in filteredOrders"
          :key="order.id"
          class="bg-white border border-gray-200 rounded-xl hover:shadow-md transition-all duration-200"
        >
          <div class="p-6">
            <!-- Order Header -->
            <div class="flex items-start justify-between mb-4">
              <div class="flex items-start space-x-4">
                <!-- Gig Image -->
                <div class="w-20 h-20 rounded-lg overflow-hidden flex-shrink-0">
                  <img
                    :src="order.gig.image"
                    :alt="order.gig.title"
                    class="w-full h-full object-cover"
                  />
                </div>
                
                <!-- Order Info -->
                <div class="flex-1">
                  <h3 class="text-lg font-semibold text-gray-900 mb-2 line-clamp-2">
                    {{ order.gig.title }}
                  </h3>
                  
                  <div class="flex items-center space-x-2 mb-2">
                    <img
                      :src="order.seller.avatar"
                      :alt="order.seller.name"
                      class="h-6 w-6 rounded-full object-cover"
                    />
                    <span class="text-sm text-gray-600">by {{ order.seller.name }}</span>
                  </div>
                  
                  <div class="flex items-center space-x-4 text-sm text-gray-500">
                    <span>Order #{{ order.orderNumber }}</span>
                    <span>{{ formatDate(order.orderDate) }}</span>
                  </div>
                </div>
              </div>

              <!-- Status Badge -->
              <div class="flex-shrink-0">
                <span
                  :class="[
                    'inline-flex items-center px-3 py-1 rounded-full text-xs font-medium',
                    getStatusBadgeClass(order.status)
                  ]"
                >
                  {{ getStatusLabel(order.status) }}
                </span>
              </div>
            </div>

            <!-- Order Details -->
            <div class="border-t border-gray-100 pt-4">
              <div class="flex items-center justify-between">
                <div class="flex items-center space-x-6 text-sm">
                  <div>
                    <span class="text-gray-500">Price:</span>
                    <span class="font-semibold text-gray-900 ml-1">${{ order.amount }}</span>
                  </div>
                  <div v-if="order.deliveryDate">
                    <span class="text-gray-500">Delivery:</span>
                    <span class="font-semibold text-gray-900 ml-1">{{ formatDate(order.deliveryDate) }}</span>
                  </div>
                  <div v-if="order.status === 'in_progress' && order.timeRemaining">
                    <span class="text-gray-500">Time Remaining:</span>
                    <span class="font-semibold text-orange-600 ml-1">{{ order.timeRemaining }}</span>
                  </div>
                </div>
                
                <!-- Action Buttons -->
                <div class="flex items-center space-x-2">
                  <button
                    @click="openChat(order)"
                    class="relative px-4 py-2 border border-gray-200 text-gray-700 rounded-lg hover:bg-gray-50 transition-colors text-sm font-medium flex items-center space-x-2"
                  >
                    <MessageCircle class="h-4 w-4" />
                    <span>Chat</span>
                    <!-- Notification Badge -->
                    <span
                      v-if="order.unreadMessages && order.unreadMessages > 0"
                      class="absolute -top-1 -right-1 bg-red-500 text-white text-xs font-bold rounded-full h-5 w-5 flex items-center justify-center min-w-[20px]"
                    >
                      {{ order.unreadMessages > 9 ? '9+' : order.unreadMessages }}
                    </span>
                  </button>
                  
                  <button
                    v-if="order.status === 'delivered'"
                    @click="leaveReview(order)"
                    class="px-4 py-2 bg-purple-600 text-white rounded-lg hover:bg-purple-700 transition-colors text-sm font-medium flex items-center space-x-2"
                  >
                    <Star class="h-4 w-4" />
                    <span>Review</span>
                  </button>
                  
                  <button
                    v-else-if="order.status === 'pending'"
                    @click="cancelOrder(order)"
                    class="px-4 py-2 border border-red-200 text-red-600 rounded-lg hover:bg-red-50 transition-colors text-sm font-medium"
                  >
                    Cancel Order
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
      @click.self="showCancelModal = false"
    >
      <div class="bg-white rounded-xl shadow-xl p-6 max-w-md w-full mx-4">
        <h3 class="text-lg font-semibold text-gray-900 mb-4">Cancel Order</h3>
        <p class="text-gray-600 mb-6">
          Are you sure you want to cancel this order? This action cannot be undone and you may be charged a cancellation fee.
        </p>
        <div class="flex space-x-3">
          <button
            @click="showCancelModal = false"
            class="flex-1 px-4 py-2 border border-gray-200 text-gray-700 rounded-lg hover:bg-gray-50 transition-colors"
          >
            Keep Order
          </button>
          <button
            @click="confirmCancelOrder"
            class="flex-1 px-4 py-2 bg-red-600 text-white rounded-lg hover:bg-red-700 transition-colors"
          >
            Cancel Order
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue';
import { Star, MessageCircle, ShoppingCart } from 'lucide-vue-next';

// Emit events
const emit = defineEmits(['switchTab']);

// Reactive data
const activeStatus = ref('all');
const isLoading = ref(true);
const showCancelModal = ref(false);
const orderToCancel = ref(null);

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
const { get } = useApi();

// Fetch orders from API
async function fetchOrders() {
  isLoading.value = true;
  try {
    const { data, error } = await get('/workspace/orders/');
    
    if (error) {
      console.error('Error fetching orders:', error);
      orders.value = [];
      return;
    }
    
    const results = data?.results || data || [];
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
        name: order.seller?.name || 'Unknown Seller',
        avatar: order.seller?.avatar || '/images/default-avatar.png'
      }
    }));
    
    updateStatusCounts();
  } catch (err) {
    console.error('Error fetching orders:', err);
    orders.value = [];
  } finally {
    isLoading.value = false;
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
  console.log('Opening chat for order:', order.orderNumber);
  // Here you would implement the chat functionality
};

const leaveReview = (order) => {
  console.log('Leaving review for order:', order.orderNumber);
  // Here you would implement the review functionality
};

const cancelOrder = (order) => {
  orderToCancel.value = order;
  showCancelModal.value = true;
};

const confirmCancelOrder = () => {
  if (orderToCancel.value) {
    // Update order status
    orderToCancel.value.status = 'cancelled';
    
    // Update counts
    updateStatusCounts();
    
    console.log('Order cancelled:', orderToCancel.value.orderNumber);
  }
  
  showCancelModal.value = false;
  orderToCancel.value = null;
};

// Lifecycle
onMounted(() => {
  fetchOrders();
});
</script>

<style scoped>
.line-clamp-2 {
  display: -webkit-box;
  -webkit-line-clamp: 2;
  line-clamp: 2;
  -webkit-box-orient: vertical;
  overflow: hidden;
}
</style>
