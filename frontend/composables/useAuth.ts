export function useAuth() {
  const Api = useApi();
  const baseURL = Api.baseURL;
  const user = useState<any>("user", () => null);
  // const { getUserDetails } = useStoreUser();
  const notifs = useState<Array<any>>("notifs", () => []);
  const isAuthenticated = computed(() => user.value !== null);
  // Configure JWT cookie with 30 days expiration to match backend token lifetime
  const jwt = useCookie("adsyclub-jwt", {
    default: () => null,
    maxAge: 60 * 60 * 24 * 30, // 30 days - matches backend JWT and session settings
    httpOnly: false,
    secure: false, // Set to true in production
    sameSite: 'lax',
    // Ensure cookie persists across browser sessions
    expires: new Date(Date.now() + (60 * 60 * 24 * 30 * 1000)) // 30 days from now
  });

  const jwtLogin = async () => {
    if (!jwt.value) {
      user.value = null;
      return false;
    }
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
    if (error.value) {
      console.log("JWT validation error:", error.value);
      const jwt = useCookie("adsyclub-jwt");
      user.value = null;
      jwt.value = null;
      // navigateTo("/");
      return false;
    }
    if (data.value) {
      user.value = data.value;
      const jwt = useCookie("adsyclub-jwt");
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

      if (error.value) {
        //console.log("Login error:", error.value); // Log the error for debugging
        return error; // Return false or handle error as needed
      }

      if (data.value) {
        user.value = data.value;
        const jwt = useCookie("adsyclub-jwt");
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
    const jwt = useCookie("adsyclub-jwt");
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
