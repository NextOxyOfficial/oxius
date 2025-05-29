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

  const get = async (endpoint: string) => {
    const headers = await getHeaders();
    const { data, pending, error, refresh } = await useFetch<any>(
      baseURL + endpoint,
      {
        headers,
        method: "get",
      }
    );

    return {
      data: data.value,
      error: error.value,
    };
  };  const post = async (endpoint: string, postData: object | FormData) => {
    // For FormData, don't set Content-Type header - let browser set it with boundary
    const headers = postData instanceof FormData
      ? await getHeaders(false) // Don't include Content-Type for FormData
      : await getHeaders(true);  // Include Content-Type for JSON

    const { data, error } = await useFetch(baseURL + endpoint, {
      headers,
      method: "post",
      body: postData,
    });
    return {
      data: data.value,
      error: error.value,
    };
  };
  const put = async (endpoint: string, postData: object) => {
    const headers = await getHeaders(true); // Include Content-Type for JSON
    const { data, pending, error, refresh } = await useFetch<any>(
      baseURL + endpoint,
      {
        headers,
        method: "put",
        body: JSON.stringify(postData),
      }
    );
    return {
      data: data.value,
      error: error.value,
    };
  };
  const patch = async (endpoint: string, postData: object) => {
    // Use async header generation with content type for JSON data
    const headers = await getHeaders(true);

    try {
      console.log("PATCH request to:", baseURL + endpoint);
      console.log("Request body:", JSON.stringify(postData));

      const { data, error } = await useFetch<any>(baseURL + endpoint, {
        headers,
        method: "patch",
        body: JSON.stringify(postData),
      });

      if (error.value) {
        console.error("PATCH error response:", error.value);
      }

      return {
        data: data.value,
        error: error.value,
      };
    } catch (err) {
      console.error("PATCH request failed with exception:", err);
      return {
        data: null,
        error: err,
      };
    }
  };  const del = async (endpoint: string) => {
    try {
      console.log(`DELETE request to: ${baseURL + endpoint}`);

      // Get valid token with automatic refresh
      const headers = await getHeaders();
      
      // Check if we have authorization after refresh attempt
      const headersObj = headers as Record<string, string>;
      if (!headersObj.Authorization) {
        console.error("DELETE request failed: No valid JWT token available after refresh attempt");
        throw new Error("Authentication token is missing or expired");
      }

      // Log auth token format (first few chars only for security)
      console.log("Authorization header present:", !!headersObj.Authorization);
      if (headersObj.Authorization) {
        const tokenPrefix = headersObj.Authorization.substring(0, 20);
        console.log(`Authorization header starts with: ${tokenPrefix}...`);
      }

      // Add logging for the full URL
      console.log(`Full DELETE URL: ${baseURL + endpoint}`);

      // Make the request with proper error handling
      const { data, pending, error, status } = await useFetch<any>(
        baseURL + endpoint,
        {
          headers,
          method: "delete",
          retry: 1, // Add a single retry attempt
          onRequest({ request, options }) {
            // Request has been made
            console.log(
              "DELETE request sent with options:",
              JSON.stringify(options.method)
            );
          },
          onRequestError({ request, options, error }) {
            // Handle request errors
            console.error("DELETE request error:", error);
          },
          onResponse({ request, response, options }) {
            // Process the response data
            console.log("DELETE response received, status:", response.status);
          },
          onResponseError({ request, response, options }) {
            // Handle the response errors
            console.error(
              "DELETE response error:",
              response.status,
              response.statusText
            );
          },
        }
      );

      // Better error handling
      if (error.value) {
        console.error("DELETE error response:", error.value);
        console.error("Error status:", status.value);

        // Try to extract more details from the error
        let errorDetails = "Unknown error";
        if (typeof error.value === "object") {
          errorDetails = JSON.stringify(error.value);
        } else if (typeof error.value === "string") {
          errorDetails = error.value;
        }

        console.error("Error details:", errorDetails);

        // Return structured error for better handling
        return {
          data: null,
          error: {
            message: errorDetails,
            statusCode: status.value,
            originalError: error.value,
          },
          status: status.value,
        };
      }

      console.log("DELETE success response:", data.value);

      // Return successful response
      return {
        data: data.value,
        error: null,
        status: status.value,
      };
    } catch (err: any) {
      console.error("DELETE request failed with exception:", err);
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
