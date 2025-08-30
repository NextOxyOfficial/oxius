<template>
  <div>
    <div v-if="myGigs.length > 0" class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
      <div 
        v-for="gig in myGigs" 
        :key="gig.id" 
        class="bg-white rounded-lg border border-gray-200 hover:border-blue-300 transition-colors cursor-pointer"
        @click="navigateTo(`/business-network/workspace-details?id=${gig.id}`)"
      >
        <div class="p-4">
          <div class="flex items-start justify-between mb-3">
            <div class="flex-1">
              <h3 class="text-lg font-semibold text-gray-900 mb-1 hover:text-blue-600">
                {{ gig.title }}
              </h3>
              <p class="text-sm text-gray-600 mb-2">{{ getCategoryLabel(gig.category) }}</p>
            </div>
            <div class="flex items-center space-x-2">
              <Heart class="w-5 h-5 text-gray-400 hover:text-red-500" />
              <button class="text-gray-400 hover:text-blue-600">
                <Settings class="w-5 h-5" />
              </button>
            </div>
          </div>
          
          <div class="flex items-center mb-3">
            <img 
              :src="gig.user.avatar" 
              :alt="gig.user.name" 
              class="w-8 h-8 rounded-full mr-2"
            >
            <div>
              <p class="text-sm font-medium text-gray-900">{{ gig.user.name }}</p>
              <div class="flex items-center">
                <Star class="w-4 h-4 fill-yellow-400 text-yellow-400 mr-1" />
                <span class="text-sm text-gray-600">{{ gig.rating }}</span>
                <span class="text-sm text-gray-500 ml-1">({{ gig.reviews }})</span>
              </div>
            </div>
          </div>
          
          <div class="flex items-center justify-between mb-4">
            <div class="text-sm text-gray-500">
              <span :class="getStatusBadgeClass(gig.status || 'Active')">
                {{ gig.status || 'Active' }}
              </span>
            </div>
            <div class="text-right">
              <p class="text-lg font-bold text-gray-900">
                Starting at ${{ gig.price }}
              </p>
            </div>
          </div>

          <!-- Gig Stats -->
          <div class="flex items-center justify-between text-xs text-gray-500 pt-2 border-t">
            <span>{{ gig.views || 0 }} views</span>
            <span>{{ gig.orders || 0 }} orders</span>
            <span>{{ gig.impressions || 0 }} impressions</span>
          </div>
        </div>
      </div>
    </div>

    <!-- Empty State for My Gigs -->
    <div v-else class="text-center py-16">
      <Briefcase class="w-16 h-16 text-gray-300 mx-auto mb-4" />
      <h3 class="text-xl font-semibold text-gray-600 mb-2">No gigs created yet</h3>
      <p class="text-gray-500 mb-6">Start earning by creating your first gig</p>
      <button 
        @click="$emit('switchTab', 'create-gig')"
        class="bg-blue-600 text-white px-6 py-3 rounded-lg hover:bg-blue-700 transition-colors"
      >
        Create Your First Gig
      </button>
    </div>
  </div>
</template>

<script setup>
import { Star, Heart, Briefcase, Settings } from "lucide-vue-next";
import { computed } from "vue";

// Props
const props = defineProps({
  gigs: {
    type: Array,
    required: true
  }
});

// Emits
defineEmits(['switchTab']);

// Composables
const { user } = useAuth();

// Computed properties
const myGigs = computed(() => {
  if (!user.value?.user) return [];
  
  // Filter gigs created by current user
  return props.gigs.filter(gig => 
    gig.user.name === user.value.user.username || 
    gig.user.name === user.value.user.first_name + ' ' + user.value.user.last_name ||
    gig.sellerId === user.value.user.id
  );
});

// Methods
const getCategoryLabel = (category) => {
  const labels = {
    design: 'Design',
    development: 'Development', 
    marketing: 'Marketing',
    writing: 'Writing',
    business: 'Business'
  };
  return labels[category] || category;
};

const getStatusBadgeClass = (status) => {
  const classes = {
    'Active': 'bg-green-100 text-green-800 px-2 py-1 rounded text-xs',
    'Paused': 'bg-yellow-100 text-yellow-800 px-2 py-1 rounded text-xs',
    'Draft': 'bg-gray-100 text-gray-800 px-2 py-1 rounded text-xs',
    'Denied': 'bg-red-100 text-red-800 px-2 py-1 rounded text-xs'
  };
  return classes[status] || 'bg-gray-100 text-gray-800 px-2 py-1 rounded text-xs';
};
</script>
