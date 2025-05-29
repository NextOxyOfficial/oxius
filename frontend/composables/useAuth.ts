export function useAuth() {
  const Api = useApi();
  const baseURL = Api.baseURL;
  const user = useState<any>("user", () => null);
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

  // Store refresh token separately
  const refreshToken = useCookie("adsyclub-refresh", {
    default: () => null,
    maxAge: 60 * 60 * 24 * 30, // 30 days
    httpOnly: false,
    secure: false, // Set to true in production
    sameSite: 'lax',
    expires: new Date(Date.now() + (60 * 60 * 24 * 30 * 1000))
  });
  // Token refresh function with enhanced error handling
  const refreshTokens = async () => {
    if (!refreshToken.value) {
      console.log("No refresh token available");
      return false;
    }

    try {
      console.log("Attempting to refresh tokens...");
      const { data, error } = await useFetch<any>(
        baseURL + "/token/refresh/",
        {
          method: "POST",
          body: JSON.stringify({ refresh: refreshToken.value }),
          headers: {
            "Content-Type": "application/json",
          },
        }
      );

      if (error.value) {
        console.log("Token refresh failed:", error.value);
        
        // If refresh fails, clear all auth data and redirect to login
        await clearAuthData();
        
        // Check if we're not already on a public page
        const route = useRoute();
        if (route.path !== '/' && route.path !== '/login' && route.path !== '/register') {
          await navigateTo('/login');
        }
        
        return false;
      }

      if (data.value && data.value.access) {
        console.log("Tokens refreshed successfully");
        // Update tokens
        jwt.value = data.value.access;
        if (data.value.refresh) {
          refreshToken.value = data.value.refresh;
        }
        return true;
      }
    } catch (err) {
      console.error("Token refresh error:", err);
      await clearAuthData();
      return false;
    }
    return false;
  };

  // Helper function to clear all authentication data
  const clearAuthData = async () => {
    jwt.value = null;
    refreshToken.value = null;
    user.value = null;
    
    // Clear username cookie
    const username = useCookie("username");
    username.value = null;
    
    // Clear any cached user data
    if (typeof window !== 'undefined') {
      localStorage.removeItem('token');
      localStorage.removeItem('user');
      sessionStorage.clear();
    }
  };

  const jwtLogin = async () => {
    if (!jwt.value) {
      user.value = null;
      return false;    }
    
    // First attempt with current token
    let { data, error } = await useFetch<any>(
      baseURL + "/auth/validate-token/",
      {
        headers: {
          Authorization: `Bearer ${jwt.value}`,
          Accept: "application/json",
        },
        method: "GET",
      }
    );

    // If token validation fails, try to refresh
    if (error.value) {
      console.log("JWT validation failed, attempting token refresh");
      const refreshSuccess = await refreshTokens();
      
      if (refreshSuccess) {
        // Retry validation with new token
        const retryResult = await useFetch<any>(
          baseURL + "/auth/validate-token/",
          {
            headers: {
              Authorization: `Bearer ${jwt.value}`,
              Accept: "application/json",
            },
            method: "GET",
          }
        );
        
        data = retryResult.data;
        error = retryResult.error;
      }
    }

    if (error.value) {
      console.log("JWT validation error after refresh attempt:", error.value);
      jwt.value = null;
      refreshToken.value = null;
      user.value = null;
      return false;
    }

    if (data.value) {
      user.value = data.value;
      jwt.value = data.value.access;
      
      // Store refresh token if provided
      if (data.value.refresh) {
        refreshToken.value = data.value.refresh;
      }
      
      const username = useCookie("username");
      if (data.value.user && data.value.user.username) {
        username.value = data.value.user.username;
      }
      return true;
    }
    return false;
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
      }      if (data.value) {
        user.value = data.value;
        jwt.value = data.value.access;
        
        // Store refresh token
        if (data.value.refresh) {
          refreshToken.value = data.value.refresh;
        }
        
        const username = useCookie("username");
        if (data.value.user && data.value.user.username) {
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
  };  // Helper function to get current token (with auto-refresh if needed)
  const getValidToken = async () => {
    if (!jwt.value || typeof jwt.value !== 'string') {
      // Try to refresh if we have a refresh token but no access token
      if (refreshToken.value) {
        const refreshSuccess = await refreshTokens();
        if (refreshSuccess) {
          return jwt.value;
        }
      }
      return null;
    }    // Simple check: try to decode the JWT to see if it's expired
    try {
      const tokenParts = (jwt.value as string).split('.');
      if (tokenParts.length === 3) {
        const payload = JSON.parse(atob(tokenParts[1]));
        const currentTime = Math.floor(Date.now() / 1000);
        
        // If token expires in less than 5 minutes, refresh it
        if (payload.exp && payload.exp - currentTime < 300) {
          console.log("Token expires soon, refreshing...");
          const refreshSuccess = await refreshTokens();
          if (!refreshSuccess) {
            return null;
          }
        }
      }
    } catch (error) {
      console.warn("Could not decode JWT token:", error);
      // If we can't decode it, try to refresh
      const refreshSuccess = await refreshTokens();
      if (!refreshSuccess) {
        return null;
      }
    }

    return jwt.value;
  };

  // Enhanced logout with better cleanup
  const logout = async () => {
    try {      // If we have a refresh token, try to blacklist it on the server
      if (refreshToken.value) {
        const headers: Record<string, string> = {
          "Content-Type": "application/json"
        };
        
        if (jwt.value) {
          headers.Authorization = `Bearer ${jwt.value}`;
        }
        
        await useFetch(baseURL + "/auth/logout/", {
          method: "POST",
          body: JSON.stringify({ refresh: refreshToken.value }),
          headers,
        }).catch(err => {
          // Don't fail logout if server request fails
          console.warn("Server logout failed:", err);
        });
      }
    } catch (error) {
      console.warn("Server logout error:", error);
    } finally {
      // Always clear local data regardless of server response
      await clearAuthData();
      await navigateTo("/");
    }
  };
  return {
    user,
    isAuthenticated,
    jwtLogin,
    login,
    logout,
    notifs,
    refreshTokens,
    getValidToken,
    clearAuthData,
  };
}
