<template>
  <div class="space-y-3">
    <!-- Loading skeleton -->
    <div v-if="isLoadingWorkspace" class="space-y-3">
      <div
        v-for="i in 4"
        :key="i"
        class="bg-white border border-gray-100 rounded-lg p-4 animate-pulse"
      >
        <div class="flex gap-4">
          <div class="w-24 h-24 bg-gray-200 rounded-lg flex-shrink-0"></div>
          <div class="flex-1 space-y-2">
            <div class="h-4 bg-gray-200 rounded w-3/4"></div>
            <div class="h-3 bg-gray-200 rounded w-1/2"></div>
            <div class="flex gap-4 mt-2">
              <div class="h-3 bg-gray-200 rounded w-16"></div>
              <div class="h-3 bg-gray-200 rounded w-16"></div>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- User's Gigs List -->
    <div v-else-if="userGigs.length > 0" class="space-y-3">
      <div
        v-for="gig in userGigs"
        :key="gig.id"
        class="bg-white border border-gray-100 rounded-lg p-4 hover:shadow-sm hover:border-gray-200 transition-all duration-200 cursor-pointer group"
        @click="openGigDetails(gig)"
      >
        <div class="flex gap-4">
          <!-- Gig Image -->
          <div class="relative w-24 h-24 flex-shrink-0 rounded-lg overflow-hidden">
            <img
              :src="gig.image"
              :alt="gig.title"
              class="w-full h-full object-cover group-hover:scale-105 transition-transform duration-200"
            />
            <div class="absolute top-1 left-1">
              <span
                class="inline-flex items-center px-1.5 py-0.5 rounded text-[10px] font-medium"
                :class="getStatusBadgeClass(gig.status)"
              >
                {{ getStatusLabel(gig.status) }}
              </span>
            </div>
          </div>
          
          <!-- Gig Content -->
          <div class="flex-1 min-w-0">
            <!-- Title -->
            <h3 class="text-sm font-semibold text-gray-900 line-clamp-2 group-hover:text-purple-600 transition-colors mb-1">
              {{ gig.title }}
            </h3>
            
            <!-- Category Badge -->
            <span
              class="inline-flex items-center px-2 py-0.5 rounded-full text-xs font-medium mb-2"
              :class="getCategoryBadgeClass(gig.category)"
            >
              {{ getCategoryLabel(gig.category) }}
            </span>
            
            <!-- Stats Row -->
            <div class="flex items-center gap-4 text-xs text-gray-500">
              <div class="flex items-center gap-1">
                <Eye class="h-3.5 w-3.5" />
                <span>{{ gig.views }}</span>
              </div>
              <div class="flex items-center gap-1">
                <Star class="h-3.5 w-3.5 text-yellow-400 fill-current" />
                <span>{{ gig.rating }} ({{ gig.reviews }})</span>
              </div>
              <div class="font-semibold text-gray-900">
                ${{ gig.price }}
              </div>
            </div>
          </div>
          
          <!-- Actions (only for own profile) -->
          <div v-if="isOwnProfile" class="flex items-center gap-1 flex-shrink-0">
            <button
              @click.stop="editGig(gig)"
              class="p-2 rounded-lg hover:bg-gray-100 transition-colors"
              title="Edit gig"
            >
              <Edit class="h-4 w-4 text-gray-500" />
            </button>
            <button
              @click.stop="toggleGigStatus(gig)"
              class="p-2 rounded-lg hover:bg-gray-100 transition-colors"
              :title="gig.status === 'active' ? 'Pause gig' : 'Activate gig'"
            >
              <component 
                :is="gig.status === 'active' ? Pause : Play"
                class="h-4 w-4 text-gray-500"
              />
            </button>
          </div>
        </div>
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
