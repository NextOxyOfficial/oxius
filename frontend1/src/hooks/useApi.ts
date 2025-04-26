import axios, { AxiosError, AxiosInstance, AxiosRequestConfig } from 'axios';
import { useQuery, useMutation, QueryClient } from '@tanstack/react-query';
import Cookies from 'js-cookie';

// Create a QueryClient to be used at the app level
export const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      retry: 1,
      staleTime: 5 * 60 * 1000, // 5 minutes
      refetchOnWindowFocus: false,
    },
  },
});

export function useApi() {
  const baseURL = process.env.NEXT_PUBLIC_BASE_URL + "/api";
  const staticURL = process.env.NEXT_PUBLIC_BASE_URL;

  // Create axios instance
  const axiosInstance: AxiosInstance = axios.create({
    baseURL,
    headers: {
      'Accept': 'application/json',
    }
  });

  // Request interceptor to add auth token
  axiosInstance.interceptors.request.use(
    (config) => {
      const jwt = Cookies.get('adsyclub-jwt');
      if (jwt && config.headers) {
        config.headers['Authorization'] = `Bearer ${jwt}`;
      }
      return config;
    },
    (error) => {
      return Promise.reject(error);
    }
  );

  // Response interceptor for error handling
  axiosInstance.interceptors.response.use(
    (response) => response,
    (error: AxiosError) => {
      // Handle specific error cases like 401 for auth
      if (error.response?.status === 401) {
        Cookies.remove('adsyclub-jwt');
        // Redirect to login if needed
      }
      return Promise.reject(error);
    }
  );

  // GET request with React Query
  const useApiGet = <T>(key: string | string[], endpoint: string, options = {}) => {
    return useQuery({
      queryKey: Array.isArray(key) ? key : [key],
      queryFn: async () => {
        const response = await axiosInstance.get<T>(endpoint);
        return response.data;
      },
      ...options,
    });
  };

  // Simple GET without React Query
  const get = async <T>(endpoint: string) => {
    try {
      const response = await axiosInstance.get<T>(endpoint);
      return { data: response.data, error: null };
    } catch (error) {
      return { data: null, error };
    }
  };

  // POST mutation
  const useApiPost = <T, D>(endpoint: string, options = {}) => {
    return useMutation<T, AxiosError, D>({
      mutationFn: async (postData) => {
        const response = await axiosInstance.post<T>(endpoint, postData);
        return response.data;
      },
      ...options,
    });
  };

  // Simple POST without React Query
  const post = async <T>(endpoint: string, postData: object | FormData) => {
    try {
      const config: AxiosRequestConfig = {};
      if (postData instanceof FormData) {
        config.headers = {
          'Content-Type': 'multipart/form-data',
        };
      }
      const response = await axiosInstance.post<T>(endpoint, postData, config);
      return { data: response.data, error: null };
    } catch (error) {
      return { data: null, error };
    }
  };

  // PUT mutation
  const useApiPut = <T, D>(endpoint: string, options = {}) => {
    return useMutation<T, AxiosError, D>({
      mutationFn: async (putData) => {
        const response = await axiosInstance.put<T>(endpoint, putData);
        return response.data;
      },
      ...options,
    });
  };

  // Simple PUT without React Query
  const put = async <T>(endpoint: string, putData: object) => {
    try {
      const response = await axiosInstance.put<T>(endpoint, putData);
      return { data: response.data, error: null };
    } catch (error) {
      return { data: null, error };
    }
  };

  // PATCH mutation
  const useApiPatch = <T, D>(endpoint: string, options = {}) => {
    return useMutation<T, AxiosError, D>({
      mutationFn: async (patchData) => {
        const response = await axiosInstance.patch<T>(endpoint, patchData);
        return response.data;
      },
      ...options,
    });
  };

  // Simple PATCH without React Query
  const patch = async <T>(endpoint: string, patchData: object) => {
    try {
      const response = await axiosInstance.patch<T>(endpoint, patchData);
      return { data: response.data, error: null };
    } catch (error) {
      return { data: null, error };
    }
  };

  // DELETE mutation
  const useApiDelete = <T>(endpoint: string, options = {}) => {
    return useMutation<T, AxiosError, void>({
      mutationFn: async () => {
        const response = await axiosInstance.delete<T>(endpoint);
        return response.data;
      },
      ...options,
    });
  };

  // Simple DELETE without React Query
  const del = async <T>(endpoint: string) => {
    try {
      const response = await axiosInstance.delete<T>(endpoint);
      return { data: response.data, error: null };
    } catch (error) {
      return { data: null, error };
    }
  };

  return {
    baseURL,
    staticURL,
    // Simple API functions
    get,
    post,
    put,
    patch,
    del,
    // React Query enhanced API functions
    useApiGet,
    useApiPost,
    useApiPut, 
    useApiPatch,
    useApiDelete,
    // Expose the axios instance for custom uses
    axiosInstance
  };
}