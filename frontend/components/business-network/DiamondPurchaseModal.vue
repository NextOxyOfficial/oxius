<template>
  <UModal 
    v-model="isOpen" 
    @update:modelValue="$emit('update:modelValue', $event)"
    :ui="{ 
      width: 'w-full max-w-lg', 
      container: 'h-[75vh] overflow-y-auto mt-20', 
      wrapper: 'z-[9999] mt-20', 
      base: 'mt-20'
    }"
  >
    <!-- Modal contents with premium styling -->
    <div class="rounded-xl overflow-hidden">
      <!-- Header with gradient background -->
      <div class="p-5 bg-gradient-to-r from-pink-500 to-purple-500 text-white">
        <div class="flex items-center justify-between">
          <h3 class="text-xl font-semibold flex items-center gap-2">
            <div class="p-1.5 bg-white/20 rounded-lg">
              <UIcon name="i-heroicons-sparkles" class="h-5 w-5" />
            </div>
            {{ activeTab === 'purchase' ? 'Purchase Diamonds' : 'Purchase History' }}
          </h3>
          <button @click="closeModal" class="p-1.5 rounded-full bg-white/20 hover:bg-white/30 transition-colors">
            <UIcon name="i-heroicons-x-mark" class="h-5 w-5" />
          </button>
        </div>
      </div>

      <div class="bg-white dark:bg-slate-800 overflow-y-auto">
        <!-- Balance Information with shimmer effect -->
        <div class="relative p-4 mx-6 mt-6 mb-4 rounded-xl overflow-hidden diamond-balance-card">
          <!-- Animated shimmer background -->
          <div class="absolute inset-0 bg-gradient-to-r from-pink-50/80 via-purple-50/80 to-pink-50/80 dark:from-pink-900/10 dark:via-purple-900/15 dark:to-pink-900/10 shimmer-background"></div>
          
          <div class="relative flex justify-between items-center">
            <div>
              <div class="text-sm text-gray-600 dark:text-gray-400 mb-1">Available Diamonds</div>
              <div class="flex items-center">
                <span class="text-xl font-bold mr-2">
                  <UIcon name="material-symbols:diamond-outline" class="size-5 text-pink-500" />
                  {{ user.user.diamond_balance }}</span>
                <UIcon name="i-heroicons-gem" class="h-5 w-5 text-pink-500" />
              </div>
            </div>
            <div>
              <div class="text-sm text-gray-600 dark:text-gray-400 mb-1">Account funds</div>
              <div class="text-xl font-bold"><span class="text-2xl font-bold">৳</span> {{ user.user.balance }}</div>
            </div>
          </div>
        </div>

        <!-- Tabs Navigation -->
        <div class="flex border-b border-gray-200 dark:border-gray-700 px-6">
          <button 
            @click="activeTab = 'purchase'"
            class="py-3 px-4 font-medium text-sm transition-colors relative"
            :class="activeTab === 'purchase' 
              ? 'text-pink-600 dark:text-pink-400' 
              : 'text-gray-600 dark:text-gray-400 hover:text-pink-500 dark:hover:text-pink-300'"
          >
            <div class="flex items-center gap-2">
              <UIcon name="i-heroicons-shopping-cart" class="h-4 w-4" />
              Purchase
            </div>
            <div v-if="activeTab === 'purchase'" class="absolute bottom-0 left-0 w-full h-0.5 bg-gradient-to-r from-pink-500 to-purple-500"></div>
          </button>
          <button 
            @click="setHistoryTab"
            class="py-3 px-4 font-medium text-sm transition-colors relative"
            :class="activeTab === 'history' 
              ? 'text-pink-600 dark:text-pink-400' 
              : 'text-gray-600 dark:text-gray-400 hover:text-pink-500 dark:hover:text-pink-300'"
          >
            <div class="flex items-center gap-2">
              <UIcon name="i-heroicons-clock" class="h-4 w-4" />
              History
            </div>
            <div v-if="activeTab === 'history'" class="absolute bottom-0 left-0 w-full h-0.5 bg-gradient-to-r from-pink-500 to-purple-500"></div>
          </button>
        </div>

        <!-- Purchase Tab Content -->
        <div v-if="activeTab === 'purchase'" class="p-6 pt-4">
          <!-- Diamond packages section -->
          <div>
            <h4 class="font-medium text-gray-700 dark:text-gray-300 mb-4">Select Diamond Package</h4>
            
            <div class="grid grid-cols-2 gap-4 mb-6">
              <button 
                v-for="(pkg, index) in diamondPackages" 
                :key="index"
                @click="selectDiamondPackage(pkg.amount)"
                :class="[ 
                  'relative flex flex-col items-center justify-center p-4 rounded-lg border transition-all duration-200',
                  selectedPackage === pkg.amount 
                    ? 'bg-gradient-to-r from-pink-50 to-purple-50 dark:from-pink-900/20 dark:to-purple-900/20 border-pink-300 dark:border-pink-700 shadow'
                    : 'bg-white dark:bg-slate-700/50 border-gray-200 dark:border-slate-600 hover:border-pink-200 dark:hover:border-pink-800'
                ]"
              >
                <div class="absolute top-2 right-2 text-xs font-semibold bg-pink-100 dark:bg-pink-900/50 text-pink-600 dark:text-pink-300 px-1.5 py-0.5 rounded-full">
                  <span class="text-lg font-medium">৳</span>{{ pkg.price }}
                </div>
                
                <UIcon name="i-heroicons-gem" class="h-8 w-8 text-pink-500 mb-1" />
                <div class="text-lg font-bold text-gray-800 dark:text-gray-100">{{ pkg.amount }}</div>
                <div class="text-xs text-gray-500">diamonds</div>
                
                <!-- Selected indicator -->
                <div v-if="selectedPackage === pkg.amount" class="absolute -top-1.5 -right-1.5 h-5 w-5 bg-gradient-to-br from-pink-500 to-purple-500 rounded-full flex items-center justify-center shadow-sm">
                  <UIcon name="i-heroicons-check" class="h-3 w-3 text-white" />
                </div>
              </button>
            </div>
            
            <!-- Custom amount input -->
            <div class="mb-6">
              <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1.5">
                Custom Amount
              </label>
              <div class="relative">
                <input 
                  type="number" 
                  v-model="customDiamondAmount"
                  placeholder="Enter diamond amount"
                  min="10"
                  class="w-full px-3.5 py-2.5 border border-gray-200 dark:border-slate-700 rounded-lg focus:outline-none focus:ring-2 focus:ring-pink-500/50 dark:focus:ring-pink-400/40 text-gray-700 dark:text-gray-200 bg-white dark:bg-slate-800"
                  @input="onCustomAmountInput"
                />
                <div class="absolute right-3 top-1/2 -translate-y-1/2 flex items-center">
                  <UIcon name="i-heroicons-sparkles" class="h-4 w-4 text-pink-400" />
                </div>
              </div>
              <div class="flex items-center justify-between mt-1.5">
                <p class="text-xs text-gray-500">Minimum 10 diamonds</p>
                <p class="text-xs text-gray-500">
                  ≈ {{ calculatePrice(customDiamondAmount || 0) }} BDT
                </p>
              </div>
            </div>
            
            <div class="mb-4">
              <div class="text-sm text-gray-700 dark:text-gray-300 flex items-center gap-1 mb-2">
                <UIcon name="i-heroicons-information-circle" class="h-4 w-4 text-blue-500" />
                <span>10 diamonds = 1 BDT</span>
              </div>
              
              <div class="bg-blue-50 dark:bg-blue-900/20 p-3 rounded-lg text-sm text-blue-800 dark:text-blue-200">
                You will be charged <span class="text-lg font-medium">৳</span>{{ calculateTotal }} from your account balance
              </div>
            </div>

            <!-- Purchase button -->
            <UButton
              block
              size="lg" 
              color="pink"
              :loading="isLoading"
              :disabled="!canPurchase || isLoading" 
              @click="purchaseDiamonds"
            >
              <template #leading>
                <UIcon name="i-heroicons-shopping-cart" />
              </template>
              Purchase Diamonds
            </UButton>
            
            <div class="mt-3 flex justify-center">
              <UButton
                variant="link"
                size="sm"
                color="gray"
                @click="goToDeposit"
              >
                <template #leading>
                  <UIcon name="i-heroicons-plus-circle" />
                </template>
                Add funds to your account
              </UButton>
            </div>
          </div>
        </div>

        <!-- History Tab Content -->
        <div v-else class="p-6 pt-4">
          <!-- Loading state -->
          <div v-if="isLoadingHistory" class="py-16 flex flex-col items-center justify-center">
            <div class="relative h-10 w-10 mb-3">
              <div class="animate-spin rounded-full h-10 w-10 border-b-2 border-pink-500"></div>
              <div class="absolute top-0 left-0 rounded-full h-10 w-10 border-2 border-transparent border-t-pink-300 opacity-30"></div>
            </div>
            <p class="text-gray-500 dark:text-gray-400">Loading purchase history...</p>
          </div>

          <!-- Error state -->
          <div v-else-if="historyError" class="py-16 flex flex-col items-center justify-center">
            <UIcon name="i-heroicons-exclamation-circle" class="h-10 w-10 text-red-500 mb-3" />
            <p class="text-gray-700 dark:text-gray-300 mb-2">Failed to load history</p>
            <p class="text-sm text-gray-500 dark:text-gray-400 mb-4">{{ historyError }}</p>
            <UButton size="sm" color="pink" @click="loadPurchaseHistory">Try Again</UButton>
          </div>

          <!-- Empty state -->
          <div v-else-if="purchaseHistory.length === 0" class="py-16 flex flex-col items-center justify-center">
            <UIcon name="i-heroicons-document-text" class="h-10 w-10 text-gray-400 mb-3" />
            <p class="text-gray-700 dark:text-gray-300 mb-2">No purchase history</p>
            <p class="text-sm text-gray-500 dark:text-gray-400 mb-4">You haven't purchased any diamonds yet.</p>
            <UButton size="sm" color="pink" @click="activeTab = 'purchase'">Buy Diamonds</UButton>
          </div>

          <!-- History list -->
          <div v-else>
            <div class="mb-4 flex items-center justify-between">
              <h3 class="font-medium text-gray-800 dark:text-gray-200">Recent Transactions</h3>
              <UButton 
                size="xs" 
                variant="ghost" 
                color="gray" 
                @click="loadPurchaseHistory" 
                :disabled="isLoadingHistory"
                class="flex items-center gap-1"
              >
                <UIcon name="i-heroicons-arrow-path" class="h-3 w-3" :class="{ 'animate-spin': isRefreshing }"/>
                <span>Refresh</span>
              </UButton>
            </div>

            <ul class="space-y-3">
              <li 
                v-for="(item, index) in purchaseHistory" 
                :key="index"
                class="rounded-lg border border-gray-200 dark:border-gray-700 bg-white dark:bg-slate-800/50 p-3 hover:bg-gray-50 dark:hover:bg-slate-700/50 transition-colors"
              >
                <div class="flex justify-between items-center">
                  <div class="flex items-center">
                    <div class="bg-pink-100 dark:bg-pink-900/30 rounded-full p-2 mr-3">
                      <UIcon name="i-heroicons-gem" class="h-5 w-5 text-pink-500" />
                    </div>
                    <div>
                      <div class="font-medium text-gray-900 dark:text-gray-100">
                        {{ item.amount }} Diamonds
                      </div>
                      <div class="text-sm text-gray-500 dark:text-gray-400">
                        {{ formatDate(item.created_at) }}
                      </div>
                    </div>
                  </div>
                  <div class="text-right">
                    <div class="font-medium text-gray-900 dark:text-gray-100">
                      <span class="text-lg">৳</span>{{ item.cost }}
                    </div>
                    <div :class="[
                      'text-xs px-2 py-0.5 rounded-full inline-flex items-center',
                      item.status === 'completed' ? 'bg-green-100 text-green-800 dark:bg-green-900/30 dark:text-green-400' : 'bg-amber-100 text-amber-800 dark:bg-amber-900/30 dark:text-amber-400'
                    ]">
                      <span class="capitalize">{{ item.status }}</span>
                    </div>
                  </div>
                </div>
              </li>
            </ul>

            <!-- Pagination -->
            <div v-if="totalPages > 1" class="mt-4 flex justify-center">
              <div class="flex space-x-1">
                <button
                  @click="prevPage"
                  :disabled="currentPage === 1"
                  :class="[
                    'px-2.5 py-1.5 rounded-md text-sm font-medium transition-colors',
                    currentPage === 1
                      ? 'bg-gray-100 text-gray-400 dark:bg-gray-800 dark:text-gray-500 cursor-not-allowed'
                      : 'bg-gray-100 text-gray-700 hover:bg-gray-200 dark:bg-gray-800 dark:text-gray-300 dark:hover:bg-gray-700'
                  ]"
                >
                  <UIcon name="i-heroicons-chevron-left" class="h-4 w-4" />
                </button>
                
                <div class="px-3 py-1.5 bg-gray-100 dark:bg-gray-800 rounded-md text-sm">
                  <span class="font-medium text-gray-700 dark:text-gray-300">{{ currentPage }}</span>
                  <span class="text-gray-500 dark:text-gray-400"> / {{ totalPages }}</span>
                </div>
                
                <button
                  @click="nextPage"
                  :disabled="currentPage >= totalPages"
                  :class="[
                    'px-2.5 py-1.5 rounded-md text-sm font-medium transition-colors',
                    currentPage >= totalPages
                      ? 'bg-gray-100 text-gray-400 dark:bg-gray-800 dark:text-gray-500 cursor-not-allowed'
                      : 'bg-gray-100 text-gray-700 hover:bg-gray-200 dark:bg-gray-800 dark:text-gray-300 dark:hover:bg-gray-700'
                  ]"
                >
                  <UIcon name="i-heroicons-chevron-right" class="h-4 w-4" />
                </button>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  </UModal>
</template>

<script setup>
import { ref, computed, onMounted, watch } from 'vue'
const {user} = useAuth()

const props = defineProps({
  modelValue: {
    type: Boolean,
    default: false
  }
})
const isOpen = ref(props.modelValue)
console.log('DiamondPurchaseModal', props.modelValue)
watch(() => props.modelValue, (newValue) => {
  isOpen.value = newValue
})

const emit = defineEmits(['close', 'update:modelValue'])

// Tab management
const activeTab = ref('purchase')
const setHistoryTab = () => {
  activeTab.value = 'history'
  if (purchaseHistory.value.length === 0 && !historyError.value) {
    loadPurchaseHistory()
  }
}

// Create local computed for modal state management that syncs with the prop
const modelOpen = computed({
  get: () => props.modelValue,
  set: (value) => emit('update:modelValue', value)
})

// User store to access account balance
const toast = useToast()

// Diamond state
const selectedPackage = ref(null)
const customDiamondAmount = ref(null)
const isLoading = ref(false)

// Diamond packages (10 diamonds = 1 BDT)
const diamondPackages = [
  { amount: 50, price: 5 },
  { amount: 100, price: 10 },
  { amount: 250, price: 25 },
  { amount: 500, price: 50 }
]

// User balances
const userBalance = computed(() => user.user?.balance || 0)
const diamondBalance = computed(() => user.user?.diamond_balance || 0)

// Calculate purchase total
const calculateTotal = computed(() => {
  if (selectedPackage.value) {
    return diamondPackages.find(pkg => pkg.amount === selectedPackage.value)?.price || 0
  }
  if (customDiamondAmount.value) {
    return calculatePrice(customDiamondAmount.value)
  }
  return 0
})

// Check if purchase is possible
const canPurchase = computed(() => {
  // Need to have a package selected or custom amount of at least 10
  const hasAmount = selectedPackage.value || (customDiamondAmount.value && customDiamondAmount.value >= 10)
  // Check if user has enough balance
  const hasBalance = userBalance.value >= calculateTotal.value
  
  return hasAmount && hasBalance && calculateTotal.value > 0
})

// Purchase History state
const purchaseHistory = ref([])
const isLoadingHistory = ref(false)
const isRefreshing = ref(false)
const historyError = ref(null)
const currentPage = ref(1)
const totalPages = ref(1)
const pageSize = 10

// Format date for history
const formatDate = (dateString) => {
  const date = new Date(dateString)
  return date.toLocaleString('en-US', { 
    year: 'numeric', 
    month: 'short', 
    day: 'numeric',
    hour: 'numeric',
    minute: '2-digit'
  })
}

// Load purchase history from API
const loadPurchaseHistory = async () => {
  const { get } = useApi()
  historyError.value = null
  isLoadingHistory.value = true
  isRefreshing.value = true
  
  try {
    const response = await get(`/diamonds/history/?page=${currentPage.value}&limit=${pageSize}`)
    purchaseHistory.value = response.data.results || []
    totalPages.value = Math.ceil((response.data.count || 0) / pageSize)
  } catch (error) {
    console.error('Error fetching diamond purchase history:', error)
    historyError.value = error.response?.data?.error || 'Failed to load purchase history'
  } finally {
    isLoadingHistory.value = false
    setTimeout(() => {
      isRefreshing.value = false
    }, 500)
  }
}

// Pagination controls
const nextPage = () => {
  if (currentPage.value < totalPages.value) {
    currentPage.value++
    loadPurchaseHistory()
  }
}

const prevPage = () => {
  if (currentPage.value > 1) {
    currentPage.value--
    loadPurchaseHistory()
  }
}

// Select a diamond package
const selectDiamondPackage = (amount) => {
  // Toggle off if already selected
  if (selectedPackage.value === amount) {
    selectedPackage.value = null
  } else {
    selectedPackage.value = amount
    // Clear custom amount when selecting a package
    customDiamondAmount.value = null
  }
}

// Handle custom amount input
const onCustomAmountInput = () => {
  if (customDiamondAmount.value) {
    // Clear package selection when entering custom amount
    selectedPackage.value = null
  }
}

// Calculate price based on diamonds (10 diamonds = 1 BDT)
const calculatePrice = (diamonds) => {
  return parseFloat((diamonds / 10).toFixed(2))
}

// API call to purchase diamonds
const purchaseDiamonds = async () => {
  const { post } = useApi() // Initialize the API utility
  const diamondAmount = selectedPackage.value || customDiamondAmount.value
  if (!diamondAmount) return
  
  // Calculate cost in BDT (10 diamonds = 1 BDT)
  const costInBDT = calculatePrice(diamondAmount)
  
  // Check if user has sufficient balance
  if (userBalance.value < costInBDT) {
    toast.add({
      title: 'Insufficient balance',
      description: 'Please add funds to your account',
      color: 'red'
    })
    return
  }

  try {
    isLoading.value = true
    
    // Call API to purchase diamonds
    const response = await post('/diamonds/purchase/', {
      amount: parseInt(diamondAmount),
      cost: costInBDT
    })
    
    // Update UI immediately for better UX
    if (user.user) {
      // Deduct the cost from the balance
      user.user.balance -= costInBDT
      // Add diamonds to the diamond balance
      user.user.diamond_balance = (user.user.diamond_balance || 0) + parseInt(diamondAmount)
    }
    
    // Show success message
    toast.add({
      title: 'Purchase successful',
      description: `You've purchased ${diamondAmount} diamonds!`,
      color: 'green'
    })
    
    // Reset form and refresh history if needed
    resetForm()
    if (purchaseHistory.value.length > 0) {
      // Refresh history data to show the new purchase
      loadPurchaseHistory()
    }
    
  } catch (error) {
    console.error('Error purchasing diamonds:', error)
    toast.add({
      title: 'Purchase failed',
      description: error.response?.data?.error || 'Failed to purchase diamonds',
      color: 'red'
    })
  } finally {
    isLoading.value = false
  }
}

// Navigate to deposit page
const goToDeposit = () => {
  closeModal()
  navigateTo('/deposit-withdraw')
}

// Reset form values
const resetForm = () => {
  selectedPackage.value = null
  customDiamondAmount.value = null
}

// Close modal and reset form
const closeModal = () => {
  resetForm()
  activeTab.value = 'purchase' // Reset to purchase tab when closing
  emit('update:modelValue', false)
  emit('close')
}

// Load history when modal opens if on history tab
watch(
  () => props.modelValue,
  (isOpen) => {
    if (isOpen && activeTab.value === 'history' && purchaseHistory.value.length === 0) {
      loadPurchaseHistory()
    }
  }
)
</script>

<style scoped>
/* Shimmer effect for the balance card */
.shimmer-background {
  background-size: 200% 100%;
  animation: shimmer 2s infinite linear;
}

.diamond-balance-card {
  box-shadow: 0 4px 20px rgba(255, 105, 180, 0.1);
}

@keyframes shimmer {
  0% {
    background-position: 200% 0;
  }
  100% {
    background-position: -200% 0;
  }
}
</style>