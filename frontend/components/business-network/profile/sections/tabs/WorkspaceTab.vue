<template>
  <div class="space-y-4">
    <!-- Loading skeleton -->
    <div v-if="isLoadingWorkspace" class="grid grid-cols-1 md:grid-cols-2 gap-6">
      <div
        v-for="i in 6"
        :key="i"
        class="bg-white border border-gray-100 rounded-lg overflow-hidden animate-pulse"
      >
        <div class="h-48 bg-gray-200"></div>
        <div class="p-4">
          <div class="flex items-center mb-3">
            <div class="h-8 w-8 rounded-full bg-gray-200"></div>
            <div class="ml-2 h-4 w-24 bg-gray-200 rounded"></div>
          </div>
          <div class="h-5 w-full bg-gray-200 rounded mb-2"></div>
          <div class="h-4 w-3/4 bg-gray-200 rounded mb-3"></div>
          <div class="flex justify-between items-center">
            <div class="h-4 w-20 bg-gray-200 rounded"></div>
            <div class="h-6 w-16 bg-gray-200 rounded"></div>
          </div>
        </div>
      </div>
    </div>

    <!-- User's Gigs Grid -->
    <div v-else-if="userGigs.length > 0" class="grid grid-cols-1 md:grid-cols-2 gap-6">
      <div
        v-for="gig in userGigs"
        :key="gig.id"
        class="bg-white border border-gray-100 rounded-lg overflow-hidden hover:shadow-lg transition-all duration-200 cursor-pointer group"
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
          <div class="absolute top-3 left-3">
            <span
              class="inline-flex items-center px-2 py-1 rounded-full text-xs font-medium"
              :class="getStatusBadgeClass(gig.status)"
            >
              {{ getStatusLabel(gig.status) }}
            </span>
          </div>
        </div>
        
        <!-- Gig Content -->
        <div class="p-4">
          <!-- Gig Stats -->
          <div class="flex items-center justify-between mb-3">
            <div class="flex items-center space-x-4 text-sm text-gray-600">
              <div class="flex items-center">
                <Eye class="h-4 w-4 mr-1" />
                <span>{{ gig.views }}</span>
              </div>
              <div class="flex items-center">
                <Star class="h-4 w-4 mr-1 text-yellow-400 fill-current" />
                <span>{{ gig.rating }} ({{ gig.reviews }})</span>
              </div>
            </div>
          </div>
          
          <!-- Gig Title -->
          <h3 class="text-sm font-semibold text-gray-900 mb-2 line-clamp-2 group-hover:text-purple-600 transition-colors">
            {{ gig.title }}
          </h3>
          
          <!-- Price and Actions -->
          <div class="flex justify-between items-center">
            <div class="text-lg font-bold text-gray-900">
              ${{ gig.price }}
            </div>
            <div class="flex items-center space-x-2">
              <button
                @click.stop="editGig(gig)"
                class="p-1 rounded-md hover:bg-gray-100 transition-colors"
                title="Edit gig"
              >
                <Edit class="h-4 w-4 text-gray-600" />
              </button>
              <button
                @click.stop="toggleGigStatus(gig)"
                class="p-1 rounded-md hover:bg-gray-100 transition-colors"
                :title="gig.status === 'active' ? 'Pause gig' : 'Activate gig'"
              >
                <component 
                  :is="gig.status === 'active' ? Pause : Play"
                  class="h-4 w-4 text-gray-600"
                />
              </button>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- Empty state -->
    <div
      v-else
      class="flex flex-col items-center justify-center py-16 bg-gray-50/50 rounded-lg border border-dashed border-gray-200"
    >
      <div class="text-center">
        <div class="w-16 h-16 bg-purple-100 rounded-full flex items-center justify-center mx-auto mb-4">
          <Briefcase class="h-8 w-8 text-purple-600" />
        </div>
        <h3 class="text-lg font-semibold text-gray-900 mb-2">No gigs created yet</h3>
        <p class="text-gray-600 mb-4">
          {{ isOwnProfile ? "Start creating your first gig to showcase your services" : "This user hasn't created any gigs yet" }}
        </p>
        <button
          v-if="isOwnProfile"
          @click="createNewGig"
          class="inline-flex items-center px-4 py-2 rounded-lg bg-purple-600 text-white hover:bg-purple-700 transition-colors"
        >
          <Plus class="h-4 w-4 mr-2" />
          Create Your First Gig
        </button>
      </div>
    </div>
  </div>
</template>

<script setup>
import { Eye, Star, Edit, Pause, Play, Plus, Briefcase } from "lucide-vue-next";

// Props
const props = defineProps({
  isLoadingWorkspace: {
    type: Boolean,
    default: false
  },
  userGigs: {
    type: Array,
    default: () => []
  },
  currentUser: {
    type: Object,
    default: null
  },
  profileUser: {
    type: Object,
    default: null
  }
});

// Emits
const emit = defineEmits(['edit-gig', 'toggle-gig-status', 'create-gig', 'open-gig-details']);

// Composables
const toast = useToast();

// Computed
const isOwnProfile = computed(() => {
  return props.currentUser?.user?.id === props.profileUser?.id;
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

const getStatusLabel = (status) => {
  const labels = {
    active: 'Active',
    paused: 'Paused',
    draft: 'Draft'
  };
  return labels[status] || status;
};

const getStatusBadgeClass = (status) => {
  const classes = {
    active: 'bg-green-100 text-green-800',
    paused: 'bg-yellow-100 text-yellow-800',
    draft: 'bg-gray-100 text-gray-800'
  };
  return classes[status] || 'bg-gray-100 text-gray-800';
};

const openGigDetails = (gig) => {
  emit('open-gig-details', gig);
};

const editGig = (gig) => {
  emit('edit-gig', gig);
};

const toggleGigStatus = (gig) => {
  emit('toggle-gig-status', gig);
};

const createNewGig = () => {
  emit('create-gig');
};
</script>

<style scoped>
/* Custom line clamp utility */
.line-clamp-2 {
  display: -webkit-box;
  -webkit-line-clamp: 2;
  line-clamp: 2;
  -webkit-box-orient: vertical;
  overflow: hidden;
}

/* Hover effects for gig cards */
.group:hover .group-hover\:scale-105 {
  transform: scale(1.05);
}

.group:hover .group-hover\:text-purple-600 {
  color: rgb(147 51 234);
}
</style>
