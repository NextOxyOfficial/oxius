import { ref, computed } from 'vue'

export const useVideoAccess = () => {
  const { user, isAuthenticated } = useAuth()
  const showAccessModal = ref(false)
  const accessModalType = ref('login') // 'login' or 'upgrade'

  // Check if user is Pro subscriber
  const isProUser = computed(() => {
    if (!user.value?.user) return false
    return user.value.user.is_pro && user.value.user.pro_validity
  })

  // Check if Pro subscription is valid (not expired)
  const isProValid = computed(() => {
    if (!isProUser.value || !user.value?.user?.pro_validity) return false
    const now = new Date()
    const proValidity = new Date(user.value.user.pro_validity)
    return proValidity > now
  })

  // Check if user can access video content
  const canAccessVideo = computed(() => {
    return isAuthenticated.value && isProValid.value
  })

  // Check video access and show appropriate modal if needed
  const checkVideoAccess = () => {
    // If user is not logged in, show login modal
    if (!isAuthenticated.value) {
      accessModalType.value = 'login'
      showAccessModal.value = true
      return false
    }

    // If user is logged in but not Pro or Pro subscription expired, show upgrade modal  
    if (!isProValid.value) {
      accessModalType.value = 'upgrade'
      showAccessModal.value = true
      return false
    }

    // User has valid Pro access
    return true
  }

  // Close access modal
  const closeAccessModal = () => {
    showAccessModal.value = false
  }

  // Get user subscription status for display
  const getSubscriptionStatus = computed(() => {
    if (!isAuthenticated.value) {
      return {
        status: 'guest',
        message: 'Please log in to access videos'
      }
    }

    if (!user.value?.user?.is_pro) {
      return {
        status: 'free',
        message: 'Upgrade to Pro to watch videos'
      }
    }

    if (!isProValid.value) {
      return {
        status: 'expired',
        message: 'Your Pro subscription has expired'
      }
    }

    return {
      status: 'pro',
      message: 'Enjoy unlimited video access'
    }
  })

  // Get days remaining in Pro subscription
  const daysRemaining = computed(() => {
    if (!isProValid.value || !user.value?.user?.pro_validity) return 0
    
    const now = new Date()
    const proValidity = new Date(user.value.user.pro_validity)
    const diffTime = proValidity - now
    const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24))
    
    return Math.max(0, diffDays)
  })

  return {
    // State
    showAccessModal,
    accessModalType,
    
    // Computed
    isProUser,
    isProValid,
    canAccessVideo,
    getSubscriptionStatus,
    daysRemaining,
    
    // Methods
    checkVideoAccess,
    closeAccessModal
  }
}
