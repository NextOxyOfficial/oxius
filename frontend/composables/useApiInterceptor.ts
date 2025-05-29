// API interceptor for handling authentication and automatic token refresh
export function useApiInterceptor() {
  const { refreshTokens, clearAuthData } = useAuth();
  
  // Track ongoing refresh attempts to prevent multiple simultaneous refreshes
  let isRefreshing = false;
  let refreshPromise: Promise<boolean> | null = null;

  // Enhanced fetch wrapper that handles 401 errors with automatic token refresh
  const enhancedFetch = async (url: string, options: any = {}) => {
    // First attempt
    let response = await useFetch(url, options);

    // Check if we got a 401 Unauthorized error
    if (response.error.value && 
        typeof response.error.value === 'object' && 
        'statusCode' in response.error.value &&
        response.error.value.statusCode === 401) {
      
      console.log("Received 401 error, attempting token refresh...");

      // If we're already refreshing, wait for that to complete
      if (isRefreshing && refreshPromise) {
        const refreshSuccess = await refreshPromise;
        if (!refreshSuccess) {
          await clearAuthData();
          await navigateTo('/login');
          return response;
        }
      } else {
        // Start a new refresh
        isRefreshing = true;
        refreshPromise = refreshTokens();
        
        const refreshSuccess = await refreshPromise;
        isRefreshing = false;
        refreshPromise = null;

        if (!refreshSuccess) {
          console.log("Token refresh failed, redirecting to login");
          await clearAuthData();
          
          // Check if we're not already on a public page
          const route = useRoute();
          if (route.path !== '/' && route.path !== '/login' && route.path !== '/register') {
            await navigateTo('/login');
          }
          return response;
        }
      }

      // Retry the original request with the new token
      console.log("Retrying original request with refreshed token...");
      
      // Update the authorization header if it exists
      if (options.headers && typeof options.headers === 'object') {
        const { getValidToken } = useAuth();
        const newToken = await getValidToken();
        if (newToken) {
          options.headers.Authorization = `Bearer ${newToken}`;
        }
      }

      // Retry the request
      response = await useFetch(url, options);
    }

    return response;
  };

  // Create enhanced API methods that use the interceptor
  const createEnhancedApi = (baseURL: string) => {
    const getHeaders = async (includeContentType = false) => {
      const { getValidToken } = useAuth();
      const validToken = await getValidToken();
      
      const headers: Record<string, string> = {
        Accept: "application/json",
      };
      
      if (includeContentType) {
        headers["Content-Type"] = "application/json";
      }
      
      if (validToken) {
        headers.Authorization = `Bearer ${validToken}`;
      }
      
      return headers;
    };

    return {
      async get(endpoint: string) {
        const headers = await getHeaders();
        return enhancedFetch(baseURL + endpoint, {
          headers,
          method: "GET",
        });
      },

      async post(endpoint: string, postData: object | FormData) {
        const headers = postData instanceof FormData
          ? await getHeaders(false) // Don't include Content-Type for FormData
          : await getHeaders(true);  // Include Content-Type for JSON

        return enhancedFetch(baseURL + endpoint, {
          headers,
          method: "POST",
          body: postData,
        });
      },

      async put(endpoint: string, postData: object) {
        const headers = await getHeaders(true);
        return enhancedFetch(baseURL + endpoint, {
          headers,
          method: "PUT",
          body: JSON.stringify(postData),
        });
      },

      async patch(endpoint: string, postData: object) {
        const headers = await getHeaders(true);
        return enhancedFetch(baseURL + endpoint, {
          headers,
          method: "PATCH",
          body: JSON.stringify(postData),
        });
      },

      async del(endpoint: string) {
        const headers = await getHeaders();
        return enhancedFetch(baseURL + endpoint, {
          headers,
          method: "DELETE",
        });
      },
    };
  };

  return {
    enhancedFetch,
    createEnhancedApi,
  };
}
