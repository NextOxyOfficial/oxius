export function useAuth() {
  const Api = useApi();
  const baseURL = Api.baseURL;
  const user = useState<any>("user", () => null);
  // const { getUserDetails } = useStoreUser();
  const notifs = useState<array>("notifs", () => []);
  const isAuthenticated = computed(() => user.value !== null);
  const jwt = useCookie("jwt");

  const jwtLogin = async () => {
    const { data, pending, error, refresh } = await useFetch<any>(
      baseURL + "/auth/validate-token/",
      {
        headers: {
          Authorization: `Bearer ${jwt.value}`,
          Accept: "application/json",
        },
        method: "GET",
      }
    );

    if (data.value) {
      user.value = data.value;
      // getUserDetails(data.value);
      const jwt = useCookie("jwt");
      jwt.value = data.value.access;
      const username = useCookie("username");

      if (data.value.face) {
        username.value = data.value.user.username;
      }
    }
  };
  const login = async (email: string, password: string) => {
    try {
      const { data, pending, error } = await useFetch<any>(
        baseURL + "/auth/login/",
        {
          method: "POST",
          body: JSON.stringify({ email, password }),
          headers: {
            "Content-Type": "application/json", // Ensure correct header
          },
        }
      );
      console.log(error);

      if (error.value) {
        console.log("Login error:", error.value); // Log the error for debugging
        return false; // Return false or handle error as needed
      }

      //console.log(data.value, 343); // Log the response data for debugging

      if (data.value) {
        user.value = data.value;
        const jwt = useCookie("jwt");
        jwt.value = data.value.access;
        const username = useCookie("username");
        if (data.value.face) {
          username.value = data.value.user.username;
        }

        return {
          loggedIn: true,
          user_type: data.value.user.user_type,
          is_superuser: data.value.user.is_superuser,
        };
      }
    } catch (err) {
      console.log("Error during login:", err); // Log any exceptions
      return false; // Return false on error
    }
  };

  const logout = async () => {
    user.value = null;
    const jwt = useCookie("jwt");
    jwt.value = null;
    // getUserDetails(null);
    navigateTo("/");
  };

  return {
    user,
    isAuthenticated,
    jwtLogin,
    login,
    logout,
    notifs,
  };
}