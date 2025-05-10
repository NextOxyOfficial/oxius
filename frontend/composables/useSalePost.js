import { ref } from 'vue';
import { useApi } from './useApi';
import { useAuth } from './useAuth';

export function useSalePost() {
  const api = useApi();
  const { user } = useAuth();
  
  const loading = ref(false);
  const error = ref(null);
  const salePost = ref(null);
  const salePosts = ref([]);

  // Create a new sale post
  const createSalePost = async (formData) => {
    loading.value = true;
    error.value = null;
    
    try {
      console.log('Submitting sale post data...');
      // Send to server - using api directly without additional headers
      const response = await api.post('/sale-posts/', formData);
      
      if (response.error) {
        throw response.error;
      }
      
      console.log('Sale post created successfully:', response.data);
      salePost.value = response.data;
      return response.data;
    } catch (err) {
      console.error('Error creating sale post:', err);
      error.value = err.response?.data || err || 'Failed to create sale post';
      throw error.value;
    } finally {
      loading.value = false;
    }
  };

  // Get all sale posts (with optional filtering)
  const getSalePosts = async (params = {}) => {
    loading.value = true;
    error.value = null;
    
    try {
      // Build query string for params manually since our api doesn't support params
      let queryString = '';
      if (Object.keys(params).length > 0) {
        queryString = '?' + new URLSearchParams(params).toString();
      }
      
      const response = await api.get('/sale-posts/' + queryString);
      
      if (response.error) {
        throw response.error;
      }
      
      salePosts.value = response.data.results || response.data;
      return salePosts.value;
    } catch (err) {
      console.error('Error fetching sale posts:', err);
      error.value = err.response?.data || err || 'Failed to fetch sale posts';
      return [];
    } finally {
      loading.value = false;
    }
  };

  // Get a single sale post by ID
  const getSalePost = async (id) => {
    loading.value = true;
    error.value = null;
    
    try {
      const response = await api.get(`/sale-posts/${id}/`);
      
      if (response.error) {
        throw response.error;
      }
      
      salePost.value = response.data;
      return response.data;
    } catch (err) {
      console.error('Error fetching sale post:', err);
      error.value = err.response?.data || err || 'Failed to fetch sale post';
      return null;
    } finally {
      loading.value = false;
    }
  };

  // Get current user's sale posts
  const getMyPosts = async (params = {}) => {
    loading.value = true;
    error.value = null;
    
    try {
      // Build query string for params manually
      let queryString = '';
      if (Object.keys(params).length > 0) {
        queryString = '?' + new URLSearchParams(params).toString();
      }
      
      const response = await api.get('/sale-posts/my-posts/' + queryString);
      
      if (response.error) {
        throw response.error;
      }
      
      salePosts.value = response.data.results || response.data;
      return salePosts.value;
    } catch (err) {
      console.error('Error fetching my posts:', err);
      error.value = err.response?.data || err || 'Failed to fetch my posts';
      return [];
    } finally {
      loading.value = false;
    }
  };

  // Update a sale post
  const updateSalePost = async (id, data) => {
    loading.value = true;
    error.value = null;
    
    try {
      // Use patch or put based on the data type
      const response = data instanceof FormData 
        ? await api.post(`/sale-posts/${id}/`, data) // Use post for FormData
        : await api.patch(`/sale-posts/${id}/`, data);
      
      if (response.error) {
        throw response.error;
      }
      
      salePost.value = response.data;
      return response.data;
    } catch (err) {
      console.error('Error updating sale post:', err);
      error.value = err.response?.data || err || 'Failed to update sale post';
      throw error.value;
    } finally {
      loading.value = false;
    }
  };

  // Delete a sale post
  const deleteSalePost = async (id) => {
    loading.value = true;
    error.value = null;
    
    try {
      const response = await api.del(`/sale-posts/${id}/`);
      
      if (response.error) {
        throw response.error;
      }
      
      return true;
    } catch (err) {
      console.error('Error deleting sale post:', err);
      error.value = err.response?.data || err || 'Failed to delete sale post';
      throw error.value;
    } finally {
      loading.value = false;
    }
  };

  return {
    salePost,
    salePosts,
    loading,
    error,
    createSalePost,
    getSalePosts,
    getSalePost,
    getMyPosts,
    updateSalePost,
    deleteSalePost
  };
}