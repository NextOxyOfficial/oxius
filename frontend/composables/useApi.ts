const runtimeConfig = useRuntimeConfig();
export function useApi() {
  // const baseURL = "";
  const baseURL = runtimeConfig.public.baseURL + "/api";
  const staticURL = runtimeConfig.public.baseURL;

  const jwt = useCookie("adsyclub-jwt");
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
    const { data, pending, error, refresh } = await useFetch<any>(
      baseURL + endpoint,
      {
        headers: head.value,
        method: "get",
      }
    );

    return {
      data: data.value,
      error: error.value,
    };
  };
  const post = async (endpoint: string, postData: object | FormData) => {
    const { data, error } = await useFetch(baseURL + endpoint, {
      headers: head.value,
      method: "post",
      body: postData,
    });
    return {
      data: data.value,
      error: error.value,
    };
  };

  const put = async (endpoint: string, postData: object) => {
    const { data, pending, error, refresh } = await useFetch<any>(
      baseURL + endpoint,
      {
        headers: head.value,
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
    // Create headers with content type for JSON data
    const headers = { ...head.value, "Content-Type": "application/json" } as HeadersInit;
    
    try {
      console.log('PATCH request to:', baseURL + endpoint);
      console.log('Request body:', JSON.stringify(postData));
      
      const { data, error } = await useFetch<any>(
        baseURL + endpoint,
        {
          headers,
          method: "patch",
          body: JSON.stringify(postData)
        }
      );
      
      if (error.value) {
        console.error('PATCH error response:', error.value);
      }
      
      return {
        data: data.value,
        error: error.value,
      };
    } catch (err) {
      console.error('PATCH request failed with exception:', err);
      return {
        data: null,
        error: err,
      };
    }
  };

  const del = async (endpoint: string) => {
    const { data, pending, error, status, refresh } = await useFetch<any>(
      baseURL + endpoint,
      {
        headers: head.value,
        method: "delete",
      }
    );

    return {
      data: data.value,
      error: error.value,
    };
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
