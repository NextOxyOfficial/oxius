export const usePlans = () => {
  const plans = ref([])
  const loading = ref(false)
  const error = ref(null)

  const fetchPlans = async () => {
    loading.value = true
    error.value = null
    
    try {
      const config = useRuntimeConfig()
      const response = await $fetch(`${config.public.baseURL}/api/raise-up/featured/`)
      plans.value = response
    } catch (err) {
      error.value = err
      console.error('Error fetching plans:', err)
      // Fallback to empty array on error
      plans.value = []
    } finally {
      loading.value = false
    }
  }

  const fetchAllPlans = async (params = {}) => {
    loading.value = true
    error.value = null
    
    try {
      const config = useRuntimeConfig()
      const queryParams = new URLSearchParams()
      
      // Add search and filter parameters
      if (params.search) queryParams.append('search', params.search)
      if (params.stage) queryParams.append('stage', params.stage)
      if (params.sort_by) queryParams.append('sort_by', params.sort_by)
      if (params.page) queryParams.append('page', params.page)
      
      const url = `${config.public.baseURL}/api/raise-up/posts/${queryParams.toString() ? '?' + queryParams.toString() : ''}`
      const response = await $fetch(url)
      
      return response
    } catch (err) {
      error.value = err
      console.error('Error fetching all plans:', err)
      throw err
    } finally {
      loading.value = false
    }
  }

  const getPlanById = async (id) => {
    try {
      const config = useRuntimeConfig()
      const response = await $fetch(`${config.public.baseURL}/api/raise-up/posts/${id}/`)
      return response
    } catch (err) {
      console.error('Error fetching plan:', err)
      throw err
    }
  }

  return {
    plans: readonly(plans),
    loading: readonly(loading),
    error: readonly(error),
    fetchPlans,
    fetchAllPlans,
    getPlanById
  }
}
