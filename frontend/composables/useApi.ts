const runtimeConfig = useRuntimeConfig();
export function useApi() {
  // const baseURL = "";
  const baseURL = runtimeConfig.public.baseURL + "/api";
  const staticURL = runtimeConfig.public.baseURL;

  const jwt = useCookie("jwt");
  const head = computed(() => {
    if (jwt.value) {
      return {
        Authorization: `Bearer ${jwt.value}`,
        Accept: "application/json",
      };
    } else {
      return {
        Accept: "application/json",
      };
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
      headers: head.value, // Skip headers for FormData
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
    const { data, pending, error, refresh } = await useFetch<any>(
      baseURL + endpoint,
      {
        headers: head.value,
        method: "patch",
        body: JSON.stringify(postData),
      }
    );
    return {
      data: data.value,
      error: error.value,
    };
  };

  const del = async (endpoint: string) => {
    const { data, pending, error, refresh } = await useFetch<any>(
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
