<template>
  <div class="user-sponsors-section">
    <div class="flex justify-between items-center mb-4">
      <h3 class="text-lg font-semibold text-gray-800">My Sponsors</h3>
      <button 
        @click="openCreateModal"
        class="px-3 py-1.5 bg-gradient-to-r from-yellow-400 to-yellow-600 text-white text-sm rounded-lg hover:from-yellow-500 hover:to-yellow-700 transition-all duration-300 shadow-md"
      >
        <Icon name="mdi:plus" class="w-4 h-4 inline mr-1" />
        Add New
      </button>
    </div>

    <!-- Loading State -->
    <div v-if="loading" class="text-center py-8">
      <div class="animate-spin rounded-full h-8 w-8 border-b-2 border-yellow-500 mx-auto"></div>
      <p class="text-gray-600 mt-2">Loading sponsors...</p>
    </div>

    <!-- No Sponsors State -->
    <div v-else-if="sponsors.length === 0" class="text-center py-8">
      <Icon name="mdi:star-outline" class="w-12 h-12 text-gray-300 mx-auto mb-2" />
      <p class="text-gray-600 mb-4">No sponsors yet</p>
      <button 
        @click="openCreateModal"
        class="px-4 py-2 bg-gradient-to-r from-yellow-400 to-yellow-600 text-white rounded-lg hover:from-yellow-500 hover:to-yellow-700 transition-all duration-300"
      >
        Create Your First Sponsor
      </button>
    </div>

    <!-- Sponsors List -->
    <div v-else class="space-y-3">
      <div 
        v-for="sponsor in sponsors" 
        :key="sponsor.id"
        class="bg-white rounded-lg border border-gray-200 p-4 hover:shadow-md transition-shadow duration-300"
      >
        <!-- Sponsor Header -->
        <div class="flex items-start justify-between mb-3">
          <div class="flex items-center space-x-3">
            <img 
              v-if="sponsor.logo" 
              :src="sponsor.logo" 
              :alt="sponsor.business_name"
              class="w-10 h-10 rounded-lg object-cover"
            />
            <div v-else class="w-10 h-10 bg-gradient-to-br from-yellow-100 to-yellow-200 rounded-lg flex items-center justify-center">
              <Icon name="mdi:domain" class="w-6 h-6 text-yellow-600" />
            </div>
            <div>
              <h4 class="font-semibold text-gray-800 truncate">{{ sponsor.business_name }}</h4>
              <span 
                :class="getStatusClass(sponsor.status)"
                class="inline-flex items-center px-2 py-1 rounded-full text-xs font-medium"
              >
                <span class="w-1.5 h-1.5 rounded-full mr-1" :class="getStatusDotClass(sponsor.status)"></span>
                {{ getStatusText(sponsor.status) }}
              </span>
            </div>
          </div>
          
          <!-- Actions Dropdown -->
          <div class="relative" v-click-outside="() => closeActionsMenu(sponsor.id)">
            <button 
              @click="toggleActionsMenu(sponsor.id)"
              class="p-1.5 text-gray-400 hover:text-gray-600 rounded-lg hover:bg-gray-100 transition-colors"
            >
              <Icon name="mdi:dots-vertical" class="w-5 h-5" />
            </button>
            
            <div 
              v-if="activeActionMenu === sponsor.id"
              class="absolute right-0 top-full mt-1 w-48 bg-white rounded-lg shadow-lg border border-gray-200 py-2 z-10"
            >
              <button 
                @click="editSponsor(sponsor)"
                class="w-full px-4 py-2 text-left text-gray-800 hover:bg-gray-50 flex items-center space-x-2"
              >
                <Icon name="mdi:pencil" class="w-4 h-4" />
                <span>Edit</span>
              </button>
              <button 
                @click="viewAnalytics(sponsor)"
                class="w-full px-4 py-2 text-left text-gray-800 hover:bg-gray-50 flex items-center space-x-2"
              >
                <Icon name="mdi:chart-line" class="w-4 h-4" />
                <span>Analytics</span>
              </button>
              <hr class="my-1" />
              <button 
                @click="deleteSponsor(sponsor)"
                class="w-full px-4 py-2 text-left text-red-600 hover:bg-red-50 flex items-center space-x-2"
              >
                <Icon name="mdi:delete" class="w-4 h-4" />
                <span>Delete</span>
              </button>
            </div>
          </div>
        </div>

        <!-- Sponsor Stats -->
        <div class="grid grid-cols-2 gap-4 text-sm">
          <div>
            <span class="text-gray-600">Views:</span>
            <span class="font-semibold text-gray-800 ml-1">{{ formatNumber(sponsor.views) }}</span>
          </div>
          <div>
            <span class="text-gray-600">Days Left:</span>
            <span class="font-semibold text-gray-800 ml-1">
              {{ sponsor.days_remaining > 0 ? sponsor.days_remaining : 'Expired' }}
            </span>
          </div>
        </div>

        <!-- Package Info -->
        <div class="mt-3 pt-3 border-t border-gray-100">
          <div class="flex items-center justify-between">
            <span class="text-sm text-gray-600">{{ sponsor.package.name }}</span>
            <span class="text-sm font-semibold text-yellow-600">৳{{ sponsor.package.price }}</span>
          </div>
        </div>
      </div>
    </div>

    <!-- Sponsor Creation/Edit Modal -->
    <GoldSponsorModal 
      v-if="showModal"
      :is-open="showModal"
      :edit-sponsor="editingSponsor"
      @close="closeModal"
      @sponsor-created="onSponsorCreated"
      @sponsor-updated="onSponsorUpdated"
    />

    <!-- Delete Confirmation Modal -->
    <ConfirmDialog
      v-if="showDeleteDialog"
      :is-open="showDeleteDialog"
      title="Delete Sponsor"
      :message="`Are you sure you want to delete '${deletingSponsor?.business_name}'? This action cannot be undone.`"
      confirm-text="Delete"
      confirm-class="bg-red-600 hover:bg-red-700"
      @confirm="confirmDelete"
      @cancel="cancelDelete"
    />
  </div>
</template>

<script setup>
import { ref, onMounted, computed } from 'vue'
import { useToast } from 'vue-toastification'

const toast = useToast()

// Reactive data
const sponsors = ref([])
const loading = ref(false)
const showModal = ref(false)
const editingSponsor = ref(null)
const activeActionMenu = ref(null)
const showDeleteDialog = ref(false)
const deletingSponsor = ref(null)

// Computed
const sponsorCount = computed(() => sponsors.value.length)

// Methods
const fetchUserSponsors = async () => {
  loading.value = true
  try {
    // Use the same API pattern as the sidebar
    const { get } = useApi()
    let response
    try {
      response = await get('/bn/gold-sponsors/my-sponsors/')
    } catch (err) {
      try {
        response = await get('/api/bn/gold-sponsors/my-sponsors/')
      } catch (err2) {
        response = await get('/business_network/gold-sponsors/my-sponsors/')
      }
    }
    
    // Extract user sponsors from response
    if (response && response.data) {
      const userSponsors = response.data.user_sponsors || response.data.sponsors || response.data || []
      sponsors.value = Array.isArray(userSponsors) ? userSponsors : []
    } else {
      sponsors.value = []
    }
  } catch (error) {
    console.error('Error fetching user sponsors:', error)
    toast.error('Failed to load sponsors')
    sponsors.value = []
  } finally {
    loading.value = false
  }
}

const openCreateModal = () => {
  editingSponsor.value = null
  showModal.value = true
}

const closeModal = () => {
  showModal.value = false
  editingSponsor.value = null
}

const editSponsor = (sponsor) => {
  editingSponsor.value = sponsor
  showModal.value = true
  closeActionsMenu(sponsor.id)
}

const deleteSponsor = (sponsor) => {
  deletingSponsor.value = sponsor
  showDeleteDialog.value = true
  closeActionsMenu(sponsor.id)
}

const confirmDelete = async () => {
  if (!deletingSponsor.value) return
  
  try {
    // Get a fresh instance of the API methods to ensure we're using the latest token
    const { delete: deleteApi } = useApi()
    
    // Make sure we have a valid ID
    const sponsorId = deletingSponsor.value.id;
    if (!sponsorId) {
      throw new Error('Sponsor ID is missing');
    }
    
    // Get the current auth token
    const authToken = useCookie("adsyclub-jwt").value;
    console.log('Auth token available:', !!authToken);
    
    // Check if token exists before proceeding
    if (!authToken) {
      throw new Error('Authentication token is missing');
    }
    
    // Try the correct endpoint path
    try {
      console.log('Attempting to delete sponsor with ID:', sponsorId);
      // This is the correct path according to the backend URLs configuration
      const response = await deleteApi(`/business_network/gold-sponsors/delete/${sponsorId}/`);
      console.log('Delete response:', response);
      
      // Handle successful deletion
      sponsors.value = sponsors.value.filter(s => s.id !== deletingSponsor.value.id);
      toast.success('Sponsor deleted successfully');
      return; // Exit early if successful
    } catch (error) {
      console.error('Standard API delete attempt failed:', error);
      
      // If standard approach fails, try with direct fetch as fallback
      try {
        const token = `Bearer ${authToken}`;
        // Based on URLs, this is the endpoint the backend should be exposing
        const apiUrl = `${window.location.origin}/api/business_network/gold-sponsors/delete/${sponsorId}/`;
        console.log('Making direct fetch DELETE request to:', apiUrl);
        
        const response = await fetch(apiUrl, {
          method: 'DELETE',
          headers: {
            'Authorization': token,
            'Content-Type': 'application/json'
          },
          credentials: 'include' // Include cookies
        });
        
        console.log('Direct fetch response status:', response.status);
        
        if (response.ok) {
          // Handle successful deletion
          sponsors.value = sponsors.value.filter(s => s.id !== deletingSponsor.value.id);
          toast.success('Sponsor deleted successfully');
          return;
        } else {
          // Try to parse response for more details
          let errorMsg = 'Unknown error';
          try {
            const responseData = await response.text();
            console.error('Direct fetch error response:', responseData);
            errorMsg = responseData;
          } catch (e) {
            console.error('Error parsing error response:', e);
          }
          
          throw new Error(`API returned error status: ${response.status} - ${errorMsg}`);
        }
      } catch (directFetchError) {
        console.error('Direct fetch approach failed:', directFetchError);
        throw directFetchError; // Re-throw to be caught by outer catch
      }
    }
  } catch (error) {
    console.error('Error deleting sponsor:', error);
    toast.error(`Failed to delete sponsor: ${error.message || 'Unknown error'}`);
  } finally {
    // Always close the dialog and reset state
    showDeleteDialog.value = false;
    deletingSponsor.value = null;
  }
}

const cancelDelete = () => {
  showDeleteDialog.value = false
  deletingSponsor.value = null
}

const toggleActionsMenu = (sponsorId) => {
  activeActionMenu.value = activeActionMenu.value === sponsorId ? null : sponsorId
}

const closeActionsMenu = (sponsorId) => {
  if (activeActionMenu.value === sponsorId) {
    activeActionMenu.value = null
  }
}

const viewAnalytics = (sponsor) => {
  // Navigate to analytics page or show analytics modal
  console.log('View analytics for:', sponsor.business_name)
  toast.info('Analytics feature coming soon!')
  closeActionsMenu(sponsor.id)
}

const onSponsorCreated = (newSponsor) => {
  sponsors.value.unshift(newSponsor)
  toast.success('Sponsor created successfully!')
  closeModal()
}

const onSponsorUpdated = (updatedSponsor) => {
  const index = sponsors.value.findIndex(s => s.id === updatedSponsor.id)
  if (index !== -1) {
    sponsors.value[index] = updatedSponsor
  }
  toast.success('Sponsor updated successfully!')
  closeModal()
}

const getStatusClass = (status) => {
  switch (status) {
    case 'active':
      return 'bg-green-100 text-green-800'
    case 'pending':
      return 'bg-yellow-100 text-yellow-800'
    case 'expired':
      return 'bg-red-100 text-red-800'
    case 'rejected':
      return 'bg-gray-100 text-gray-800'
    default:
      return 'bg-gray-100 text-gray-800'
  }
}

const getStatusDotClass = (status) => {
  switch (status) {
    case 'active':
      return 'bg-green-500'
    case 'pending':
      return 'bg-yellow-500'
    case 'expired':
      return 'bg-red-500'
    case 'rejected':
      return 'bg-gray-500'
    default:
      return 'bg-gray-500'
  }
}

const getStatusText = (status) => {
  switch (status) {
    case 'active':
      return 'Active'
    case 'pending':
      return 'Pending'
    case 'expired':
      return 'Expired'
    case 'rejected':
      return 'Rejected'
    default:
      return 'Unknown'
  }
}

const formatNumber = (num) => {
  if (num >= 1000000) {
    return (num / 1000000).toFixed(1) + 'M'
  } else if (num >= 1000) {
    return (num / 1000).toFixed(1) + 'K'
  }
  return num.toString()
}

// Lifecycle
onMounted(() => {
  fetchUserSponsors()
})

// Expose methods for parent components
defineExpose({
  refreshSponsors: fetchUserSponsors,
  sponsorCount
})
</script>

<style scoped>
/* Add any additional custom styles here */
</style>
