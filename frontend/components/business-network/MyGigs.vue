<template>
  <div>
    <!-- View Toggle and Stats Header -->
    <div v-if="myGigs.length > 0" class="flex items-center justify-between mb-4">
      <p class="text-sm text-gray-600">{{ myGigs.length }} gig{{ myGigs.length !== 1 ? 's' : '' }} found</p>
      <div class="flex items-center space-x-2">
        <button
          @click="viewMode = 'grid'"
          :class="[
            'p-2 rounded-md transition-colors',
            viewMode === 'grid' ? 'bg-purple-100 text-purple-600' : 'text-gray-400 hover:text-gray-600 hover:bg-gray-100'
          ]"
        >
          <LayoutGrid class="h-4 w-4" />
        </button>
        <button
          @click="viewMode = 'list'"
          :class="[
            'p-2 rounded-md transition-colors',
            viewMode === 'list' ? 'bg-purple-100 text-purple-600' : 'text-gray-400 hover:text-gray-600 hover:bg-gray-100'
          ]"
        >
          <List class="h-4 w-4" />
        </button>
      </div>
    </div>

    <!-- Grid View -->
    <div v-if="myGigs.length > 0 && viewMode === 'grid'" class="grid grid-cols-2 gap-2">
      <div
        v-for="gig in myGigs"
        :key="gig.id"
        class="bg-white border border-gray-100 rounded-lg overflow-hidden hover:shadow-sm transition-all duration-200 cursor-pointer group"
        @click="openGigDetails(gig)"
      >
        <!-- Gig Image -->
        <div class="relative h-48 overflow-hidden">
          <img
            :src="gig.image"
            :alt="gig.title"
            class="w-full h-full object-cover group-hover:scale-105 transition-transform duration-200"
          />
          <div class="absolute top-3 right-3">
            <span
              class="inline-flex items-center px-2 py-1 rounded-full text-xs font-medium"
              :class="getCategoryBadgeClass(gig.category)"
            >
              {{ getCategoryLabel(gig.category) }}
            </span>
          </div>
          <!-- Status Badge -->
          <div class="absolute top-3 left-3">
            <span :class="getStatusBadgeClass(gig.status || 'active')">
              {{ getStatusLabel(gig.status || 'active') }}
            </span>
          </div>
          <!-- Settings Button -->
          <button
            class="absolute bottom-3 right-3 p-1.5 rounded-full bg-white/80 hover:bg-white transition-colors opacity-0 group-hover:opacity-100"
            @click.stop="openSettings(gig)"
          >
            <Settings class="h-4 w-4 text-gray-600" />
          </button>
        </div>
        
        <!-- Gig Content -->
        <div class="p-4">
          <!-- User Info -->
          <div class="flex items-center mb-3">
            <img
              :src="gig.user.avatar"
              :alt="gig.user.name"
              class="h-8 w-8 rounded-full object-cover"
            />
            <div class="ml-2">
              <p class="text-sm font-medium text-gray-900">{{ gig.user.name }}</p>
              <div class="flex items-center">
                <Star class="h-3 w-3 text-yellow-400 fill-current" />
                <span class="text-xs text-gray-600 ml-1">{{ gig.rating }} ({{ gig.reviews }})</span>
              </div>
            </div>
          </div>
          
          <!-- Gig Title -->
          <h3 
            class="text-sm font-semibold text-gray-900 mb-2 line-clamp-2 group-hover:text-purple-600 transition-colors cursor-pointer"
          >
            {{ gig.title }}
          </h3>
          
          <!-- Stats Row -->
          <div class="flex items-center justify-between text-xs text-gray-500 mb-2">
            <span class="flex items-center"><Eye class="h-3 w-3 mr-1" />{{ gig.views_count || 0 }}</span>
            <span class="flex items-center"><ShoppingCart class="h-3 w-3 mr-1" />{{ gig.orders_count || 0 }}</span>
          </div>
          
          <!-- Price -->
          <div class="flex justify-between items-center">
            <span class="text-xs text-gray-500">Starting at</span>
            <div class="text-lg font-bold text-gray-900">${{ gig.price }}</div>
          </div>
        </div>
      </div>
    </div>

    <!-- List View -->
    <div v-if="myGigs.length > 0 && viewMode === 'list'" class="space-y-3">
      <div
        v-for="gig in myGigs"
        :key="gig.id"
        class="bg-white border border-gray-100 rounded-lg overflow-hidden hover:shadow-sm transition-all duration-200 cursor-pointer group"
        @click="openGigDetails(gig)"
      >
        <div class="flex">
          <!-- Gig Image -->
          <div class="relative w-40 h-32 sm:w-48 sm:h-36 flex-shrink-0 overflow-hidden">
            <img
              :src="gig.image"
              :alt="gig.title"
              class="w-full h-full object-cover group-hover:scale-105 transition-transform duration-200"
            />
            <!-- Status Badge -->
            <div class="absolute top-2 left-2">
              <span :class="getStatusBadgeClass(gig.status || 'active')">
                {{ getStatusLabel(gig.status || 'active') }}
              </span>
            </div>
          </div>
          
          <!-- Gig Content -->
          <div class="flex-1 p-4 flex flex-col justify-between">
            <div>
              <!-- Category and Settings -->
              <div class="flex items-center justify-between mb-2">
                <span
                  class="inline-flex items-center px-2 py-1 rounded-full text-xs font-medium"
                  :class="getCategoryBadgeClass(gig.category)"
                >
                  {{ getCategoryLabel(gig.category) }}
                </span>
                <button
                  class="p-1.5 rounded-full hover:bg-gray-100 transition-colors"
                  @click.stop="openSettings(gig)"
                >
                  <Settings class="h-4 w-4 text-gray-400 hover:text-gray-600" />
                </button>
              </div>
              
              <!-- Gig Title -->
              <h3 class="text-sm sm:text-base font-semibold text-gray-900 mb-2 line-clamp-2 group-hover:text-purple-600 transition-colors">
                {{ gig.title }}
              </h3>
              
              <!-- User Info -->
              <div class="flex items-center mb-2">
                <img
                  :src="gig.user.avatar"
                  :alt="gig.user.name"
                  class="h-6 w-6 rounded-full object-cover"
                />
                <div class="ml-2 flex items-center">
                  <p class="text-xs font-medium text-gray-900 mr-2">{{ gig.user.name }}</p>
                  <Star class="h-3 w-3 text-yellow-400 fill-current" />
                  <span class="text-xs text-gray-600 ml-1">{{ gig.rating }} ({{ gig.reviews }})</span>
                </div>
              </div>
            </div>
            
            <!-- Bottom Row: Stats and Price -->
            <div class="flex items-center justify-between">
              <div class="flex items-center space-x-4 text-xs text-gray-500">
                <span class="flex items-center"><Eye class="h-3 w-3 mr-1" />{{ gig.views_count || 0 }} views</span>
                <span class="flex items-center"><ShoppingCart class="h-3 w-3 mr-1" />{{ gig.orders_count || 0 }} orders</span>
              </div>
              <div class="text-lg font-bold text-gray-900">${{ gig.price }}</div>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- Empty State for My Gigs -->
    <div v-if="myGigs.length === 0" class="flex flex-col items-center justify-center py-16 bg-gray-50/50 rounded-lg border border-dashed border-gray-200">
      <div class="text-center">
        <div class="w-16 h-16 bg-purple-100 rounded-full flex items-center justify-center mx-auto mb-4">
          <Briefcase class="h-8 w-8 text-purple-600" />
        </div>
        <h3 class="text-lg font-semibold text-gray-900 mb-2">No gigs created yet</h3>
        <p class="text-gray-600 mb-4">Start earning by creating your first gig</p>
        <button 
          @click="$emit('switchTab', 'create-gig')"
          class="inline-flex items-center px-6 py-3 rounded-lg bg-purple-600 text-white hover:bg-purple-700 transition-colors font-medium"
        >
          <Plus class="h-4 w-4 mr-2" />
          Create Your First Gig
        </button>
      </div>
    </div>
  </div>
</template>

<script setup>
import { Star, Heart, Briefcase, Settings, LayoutGrid, List, Eye, ShoppingCart, Plus } from "lucide-vue-next";
import { ref, computed } from "vue";

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
const toast = useToast();

// State
const viewMode = ref('grid');

// Computed properties
const myGigs = computed(() => {
  if (!user.value?.user) return [];
  
  // Filter gigs created by current user
  return props.gigs.filter(gig => 
    gig.user?.id === user.value.user.id ||
    gig.user?.name === user.value.user.username || 
    gig.user?.name === `${user.value.user.first_name} ${user.value.user.last_name}`.trim()
  );
});

// Methods
const openGigDetails = (gig) => {
  navigateTo(`/business-network/workspace-details?id=${gig.id}`);
};

const openSettings = (gig) => {
  toast.add({
    title: "Gig Settings",
    description: `Opening settings for "${gig.title}"`,
    color: "blue",
  });
  // TODO: Open settings modal or navigate to edit page
};

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

const getCategoryBadgeClass = (category) => {
  const classes = {
    design: 'bg-pink-100 text-pink-800',
    development: 'bg-blue-100 text-blue-800',
    marketing: 'bg-green-100 text-green-800',
    writing: 'bg-yellow-100 text-yellow-800',
    business: 'bg-purple-100 text-purple-800'
  };
  return classes[category] || 'bg-gray-100 text-gray-800';
};

const getStatusBadgeClass = (status) => {
  const classes = {
    'active': 'bg-green-100 text-green-800 px-2 py-1 rounded-full text-xs font-medium',
    'paused': 'bg-yellow-100 text-yellow-800 px-2 py-1 rounded-full text-xs font-medium',
    'draft': 'bg-gray-100 text-gray-800 px-2 py-1 rounded-full text-xs font-medium',
    'deleted': 'bg-red-100 text-red-800 px-2 py-1 rounded-full text-xs font-medium'
  };
  return classes[status?.toLowerCase()] || 'bg-green-100 text-green-800 px-2 py-1 rounded-full text-xs font-medium';
};

const getStatusLabel = (status) => {
  const labels = {
    'active': 'Active',
    'paused': 'Paused',
    'draft': 'Draft',
    'deleted': 'Deleted'
  };
  return labels[status?.toLowerCase()] || 'Active';
};
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
