export function useApi() {
  const runtimeConfig = useRuntimeConfig();
  // const baseURL = "";
  const baseURL = runtimeConfig.public.baseURL + "/api";
  const staticURL = runtimeConfig.public.baseURL;

  const jwt = useCookie("adsyclub-jwt");
  
  // Enhanced header function that refreshes tokens when needed
  const getHeaders = async (includeContentType = false) => {
    // Try to get fresh token if we have auth composable available
    try {
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
      
      return headers as HeadersInit;
    } catch (error) {
      // Fallback to current jwt if useAuth is not available
      const headers: Record<string, string> = {
        Accept: "application/json",
      };
      
      if (includeContentType) {
        headers["Content-Type"] = "application/json";
      }
      
      if (jwt.value) {
        headers.Authorization = `Bearer ${jwt.value}`;
      }
      
      return headers as HeadersInit;
    }
  };

  const head = computed<HeadersInit>(() => {
    if (jwt.value) {
      return {
        Authorization: `Bearer ${jwt.value}`,
        Accept: "application/json",
      } as HeadersInit;
    } else {
      return {
        Accept: "application/json",
      } as HeadersInit;
    }
  });

  const get = async (endpoint: string, options?: { params?: Record<string, any> }) => {
    const headers = await getHeaders();
    try {
      const data = await $fetch<any>(baseURL + endpoint, {
        headers,
        method: "GET",
        params: options?.params,
      });
      return {
        data,
        error: null,
      };
    } catch (error: any) {
      // Silently handle 404 errors for optional endpoints
      if (error?.response?.status !== 404 && error?.status !== 404) {
        console.error('GET request error:', error);
      }
      return {
        data: null,
        error,
      };
    }
  };  const post = async (endpoint: string, postData: object | FormData) => {
    // For FormData, don't set Content-Type header - let browser set it with boundary
    const headers = postData instanceof FormData
      ? await getHeaders(false) // Don't include Content-Type for FormData
      : await getHeaders(true);  // Include Content-Type for JSON

    try {
      const data = await $fetch(baseURL + endpoint, {
        headers,
        method: "POST",
        body: postData,
      });
      return {
        data,
        error: null,
      };
    } catch (error: any) {
      console.error('POST request error:', error);
      return {
        data: null,
        error,
      };
    }
  };
  const put = async (endpoint: string, postData: object) => {
    const headers = await getHeaders(true); // Include Content-Type for JSON
    try {
      const data = await $fetch<any>(baseURL + endpoint, {
        headers,
        method: "PUT",
        body: postData,
      });
      return {
        data,
        error: null,
      };
    } catch (error: any) {
      console.error('PUT request error:', error);
      return {
        data: null,
        error,
      };
    }
  };
  const patch = async (endpoint: string, postData: object) => {
    // Use async header generation with content type for JSON data
    const headers = await getHeaders(true);

    try {
      const data = await $fetch<any>(baseURL + endpoint, {
        headers,
        method: "PATCH",
        body: postData,
      });
      return {
        data,
        error: null,
      };
    } catch (err) {
      console.error("PATCH request failed:", err);
      return {
        data: null,
        error: err,
      };
    }
  };  const del = async (endpoint: string) => {
    try {
      // Get valid token with automatic refresh
      const headers = await getHeaders();
      
      // Check if we have authorization after refresh attempt
      const headersObj = headers as Record<string, string>;
      if (!headersObj.Authorization) {
        console.error("DELETE request failed: No valid JWT token available");
        throw new Error("Authentication token is missing or expired");
      }

      // Make the request with $fetch
      const data = await $fetch<any>(baseURL + endpoint, {
        headers,
        method: "DELETE",
      });

      return {
        data,
        error: null,
        status: 200,
      };
    } catch (err: any) {
      console.error("DELETE request failed:", err);
      return {
        data: null,
        error: {
          message: err.message || "Unknown error",
          originalError: err,
        },
        status: 500, // Assume server error for uncaught exceptions
      };
    }
  };

  const Api = {
    baseURL,
    get: get,
    post: post,
    put: put,
    del: del,
    patch: patch,
    staticURL: staticURL,
  };

  return Api;
}
