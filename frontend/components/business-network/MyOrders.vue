<template>
  <div class="space-y-6">
    <!-- Filter Tabs - Professional Design -->
    <div class="border-b border-gray-200">
      <!-- Mobile: 2 rows layout -->
      <div class="grid grid-cols-2 gap-1 sm:hidden">
        <button
          v-for="filter in orderFilters"
          :key="filter.value"
          @click="activeFilter = filter.value"
          :class="[
            'relative px-3 py-3 text-sm font-medium transition-colors border-b-2 text-center',
            activeFilter === filter.value
              ? 'text-blue-600 border-blue-600 bg-blue-50'
              : 'text-gray-600 border-transparent hover:text-gray-900 hover:border-gray-300'
          ]"
        >
          <div class="flex items-center justify-center space-x-1.5">
            <span>{{ filter.label }}</span>
            <span v-if="getFilterCount(filter.value) > 0" class="inline-flex items-center justify-center min-w-[18px] h-4 px-1 bg-gray-500 text-white text-xs font-medium rounded-full">
              {{ getFilterCount(filter.value) }}
            </span>
          </div>
        </button>
      </div>
      
      <!-- Desktop: single row layout -->
      <div class="hidden sm:flex">
        <button
          v-for="filter in orderFilters"
          :key="filter.value"
          @click="activeFilter = filter.value"
          :class="[
            'relative px-6 py-4 text-sm font-medium transition-colors border-b-2 whitespace-nowrap',
            activeFilter === filter.value
              ? 'text-blue-600 border-blue-600 bg-blue-50/30'
              : 'text-gray-600 border-transparent hover:text-gray-900 hover:border-gray-300'
          ]"
        >
          <div class="flex items-center space-x-2">
            <span>{{ filter.label }}</span>
            <span v-if="getFilterCount(filter.value) > 0" class="inline-flex items-center justify-center min-w-[24px] h-6 px-2 bg-gray-100 text-gray-700 text-xs font-medium rounded-full">
              {{ getFilterCount(filter.value) }}
            </span>
          </div>
        </button>
      </div>
    </div>

    <!-- Orders List -->
    <div v-if="filteredOrders.length > 0" class="space-y-4">
      <div
        v-for="order in filteredOrders"
        :key="order.id"
        class="bg-white rounded-xl border border-gray-200 overflow-hidden hover:shadow-sm transition-shadow"
      >
        <div class="p-4 sm:p-6">
          <!-- Order Header -->
          <div class="flex items-start justify-between mb-4">
            <div class="flex items-start space-x-4">
              <!-- Gig Image -->
              <div class="w-16 h-16 sm:w-20 sm:h-20 rounded-lg overflow-hidden bg-gray-100 flex-shrink-0">
                <img
                  :src="order.gig.image"
                  :alt="order.gig.title"
                  class="w-full h-full object-cover"
                />
              </div>
              
              <!-- Order Info -->
              <div class="flex-1 min-w-0">
                <h3 class="text-base font-semibold text-gray-900 mb-1 line-clamp-2">
                  {{ order.gig.title }}
                </h3>
                <div class="flex items-center justify-between mb-2">
                  <p class="text-sm text-gray-600">
                    from {{ order.buyer.name }}
                  </p>
                  <!-- Order Status Badge -->
                  <div :class="getStatusClass(order.status)" class="px-2 py-1 rounded-full text-xs font-medium whitespace-nowrap">
                    {{ getStatusLabel(order.status) }}
                  </div>
                </div>
                <div class="flex items-center space-x-4 text-xs text-gray-500">
                  <span>Order #{{ order.id }}</span>
                  <span>•</span>
                  <span>{{ formatDate(order.createdAt) }}</span>
                </div>
              </div>
            </div>
          </div>

          <!-- Order Details Grid -->
          <div class="grid grid-cols-3 gap-4 py-4 border-t border-gray-100">
            <div>
              <p class="text-xs text-gray-500 mb-1">Amount</p>
              <p class="font-semibold text-gray-900">${{ order.amount }}</p>
            </div>
            <div>
              <p class="text-xs text-gray-500 mb-1">Delivery</p>
              <p class="font-medium text-gray-700">{{ formatDeliveryDate(order.deliveryDate) }}</p>
            </div>
            <div>
              <p class="text-xs text-gray-500 mb-1">Revisions</p>
              <p class="font-medium text-gray-700">{{ order.revisions || 'N/A' }}</p>
            </div>
          </div>

          <!-- Action Buttons -->
          <div v-if="order.status !== 'cancelled'" class="flex flex-row gap-2 pt-4 border-t border-gray-100">
            <button
              @click="openChat(order)"
              :class="[
                'relative px-4 py-2 border border-gray-200 text-gray-700 rounded-lg hover:bg-gray-50 transition-colors text-xs font-medium flex items-center justify-center gap-1',
                order.status === 'pending' || order.status === 'in_progress' ? 'flex-1' : 'flex-none'
              ]"
            >
              <MessageCircle class="h-3 w-3" />
              Chat
              <!-- Notification Badge -->
              <span
                v-if="order.unreadMessages && order.unreadMessages > 0"
                class="absolute -top-1 -right-1 bg-red-500 text-white text-xs font-bold rounded-full h-4 w-4 flex items-center justify-center min-w-[16px]"
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
    <div v-else class="text-center py-16">
      <div class="w-16 h-16 bg-blue-100 rounded-full flex items-center justify-center mx-auto mb-4">
        <ShoppingCart class="h-8 w-8 text-blue-600" />
      </div>
      <h3 class="text-lg font-semibold text-gray-900 mb-2">
        No {{ getFilterLabel(activeFilter) }} Orders
      </h3>
      <p class="text-gray-600 mb-4">
        You don't have any {{ getFilterLabel(activeFilter).toLowerCase() }} orders at the moment.
      </p>
      <button
        @click="$emit('switchTab', 'all-gigs')"
        class="inline-flex items-center px-4 py-2 rounded-lg bg-blue-100 text-blue-700 hover:bg-blue-200 transition-colors"
      >
        Browse Gigs
      </button>
    </div>

  </div>
</template>

<script setup>
import { ShoppingCart, MessageCircle } from 'lucide-vue-next';

// Emit events to parent component
const emit = defineEmits(['switchTab']);

// Composables
const toast = useToast();

// Reactive data
const activeFilter = ref('pending');

// Order filters
const orderFilters = [
  { label: 'Pending', value: 'pending' },
  { label: 'In Progress', value: 'in_progress' },
  { label: 'Completed', value: 'completed' },
  { label: 'Cancelled', value: 'cancelled' }
];

// Sample orders data (replace with API call)
const orders = ref([
  {
    id: 'ORD-2024-001',
    status: 'in_progress',
    amount: 150,
    progress: 65,
    revisions: 2,
    unreadMessages: 3,
    createdAt: new Date('2024-08-25'),
    deliveryDate: new Date('2024-09-05'),
    gig: {
      id: 1,
      title: 'I will develop a responsive React web application for your startup',
      image: 'https://images.unsplash.com/photo-1633356122544-f134324a6cee?w=400&h=300&fit=crop'
    },
    buyer: {
      id: 2,
      name: 'Mike Chen',
      avatar: 'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=100&h=100&fit=crop&crop=face'
    }
  },
  {
    id: 'ORD-2024-002',
    status: 'delivered',
    amount: 75,
    progress: 100,
    revisions: 'Unlimited',
    unreadMessages: 0,
    createdAt: new Date('2024-08-20'),
    deliveryDate: new Date('2024-08-30'),
    gig: {
      id: 3,
      title: 'I will write compelling copy for your marketing campaigns',
      image: 'https://images.unsplash.com/photo-1586953208448-b95a79798f07?w=400&h=300&fit=crop'
    },
    buyer: {
      id: 3,
      name: 'Emma Davis',
      avatar: 'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=100&h=100&fit=crop&crop=face'
    }
  },
  {
    id: 'ORD-2024-003',
    status: 'pending',
    amount: 25,
    progress: 0,
    revisions: 3,
    unreadMessages: 12,
    createdAt: new Date('2024-08-29'),
    deliveryDate: new Date('2024-09-02'),
    gig: {
      id: 4,
      title: 'I will design a modern and professional logo for your business',
      image: 'https://images.unsplash.com/photo-1626785774573-4b799315345d?w=400&h=300&fit=crop'
    },
    buyer: {
      id: 4,
      name: 'Sarah Johnson',
      avatar: 'https://images.unsplash.com/photo-1494790108755-2616b612b789?w=100&h=100&fit=crop&crop=face'
    }
  },
  {
    id: 'ORD-2024-004',
    status: 'completed',
    amount: 200,
    progress: 100,
    revisions: 1,
    unreadMessages: 1,
    createdAt: new Date('2024-08-15'),
    deliveryDate: new Date('2024-08-25'),
    gig: {
      id: 5,
      title: 'I will create a comprehensive digital marketing strategy',
      image: 'https://images.unsplash.com/photo-1460925895917-afdab827c52f?w=400&h=300&fit=crop'
    },
    buyer: {
      id: 5,
      name: 'Alex Rivera',
      avatar: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=100&h=100&fit=crop&crop=face'
    }
  },
  {
    id: 'ORD-2024-005',
    status: 'in_progress',
    amount: 120,
    progress: 45,
    revisions: 2,
    unreadMessages: 5,
    createdAt: new Date('2024-08-28'),
    deliveryDate: new Date('2024-09-08'),
    gig: {
      id: 6,
      title: 'I will design a modern mobile app UI/UX with Figma',
      image: 'https://images.unsplash.com/photo-1551288049-bebda4e38f71?w=400&h=300&fit=crop'
    },
    buyer: {
      id: 6,
      name: 'Jessica Wong',
      avatar: 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=100&h=100&fit=crop&crop=face'
    }
  },
  {
    id: 'ORD-2024-006',
    status: 'pending',
    amount: 50,
    progress: 0,
    revisions: 3,
    unreadMessages: 2,
    createdAt: new Date('2024-08-30'),
    deliveryDate: new Date('2024-09-10'),
    gig: {
      id: 7,
      title: 'I will create engaging social media content for your brand',
      image: 'https://images.unsplash.com/photo-1611224923853-80b023f02d71?w=400&h=300&fit=crop'
    },
    buyer: {
      id: 7,
      name: 'David Kim',
      avatar: 'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=100&h=100&fit=crop&crop=face'
    }
  },
  {
    id: 'ORD-2024-007',
    status: 'in_progress',
    amount: 300,
    progress: 80,
    revisions: 1,
    unreadMessages: 0,
    createdAt: new Date('2024-08-22'),
    deliveryDate: new Date('2024-09-03'),
    gig: {
      id: 8,
      title: 'I will build a complete e-commerce website with admin panel',
      image: 'https://images.unsplash.com/photo-1556742049-0cfed4f6a45d?w=400&h=300&fit=crop'
    },
    buyer: {
      id: 8,
      name: 'Maria Rodriguez',
      avatar: 'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=100&h=100&fit=crop&crop=face'
    }
  },
  {
    id: 'ORD-2024-008',
    status: 'cancelled',
    amount: 80,
    progress: 0,
    revisions: 0,
    unreadMessages: 0,
    createdAt: new Date('2024-08-26'),
    deliveryDate: new Date('2024-09-06'),
    gig: {
      id: 9,
      title: 'I will write professional blog posts for your website',
      image: 'https://images.unsplash.com/photo-1455390582262-044cdead277a?w=400&h=300&fit=crop'
    },
    buyer: {
      id: 9,
      name: 'Thomas Brown',
      avatar: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=100&h=100&fit=crop&crop=face'
    }
  },
  {
    id: 'ORD-2024-009',
    status: 'in_progress',
    amount: 150,
    progress: 25,
    revisions: 5,
    unreadMessages: 8,
    createdAt: new Date('2024-08-27'),
    deliveryDate: new Date('2024-09-07'),
    gig: {
      id: 10,
      title: 'I will create a brand identity package with logo and guidelines',
      image: 'https://images.unsplash.com/photo-1626785774573-4b799315345d?w=400&h=300&fit=crop'
    },
    buyer: {
      id: 10,
      name: 'Lisa Chen',
      avatar: 'https://images.unsplash.com/photo-1494790108755-2616b612b789?w=100&h=100&fit=crop&crop=face'
    }
  }
]);

// Computed
const filteredOrders = computed(() => {
  return orders.value.filter(order => order.status === activeFilter.value);
});

// Methods
const getFilterCount = (filterValue) => {
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
  toast.add({
    title: 'Opening Chat',
    description: `Starting conversation with ${order.buyer.name} for order #${order.id}`,
    color: 'blue'
  });
  // Here you would typically navigate to chat or open chat modal
  // Example: navigateTo(`/chat/${order.buyer.id}?order=${order.id}`)
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
  order.status = 'cancelled';
  toast.add({
    title: 'Order Declined',
    description: `Order #${order.id} has been declined`,
    color: 'red'
  });
};

const deliverOrder = (order) => {
  order.status = 'delivered';
  toast.add({
    title: 'Order Delivered',
    description: `Order #${order.id} has been marked as delivered`,
    color: 'green'
  });
};
</script>
