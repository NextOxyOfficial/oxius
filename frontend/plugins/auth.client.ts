// Auto-authentication plugin for session persistence
export default defineNuxtPlugin(async () => {
  const { getValidToken, jwtLogin, clearAuthData } = useAuth();
  
  // Only run on client side
  if (process.client) {
    console.log("Initializing authentication session...");
    
    try {
      // Check if we have any tokens
      const jwt = useCookie("adsyclub-jwt");
      const refreshToken = useCookie("adsyclub-refresh");
      
      if (jwt.value || refreshToken.value) {
        console.log("Found existing tokens, validating session...");
        
        // Try to get a valid token (this will refresh if needed)
        const validToken = await getValidToken();
        
        if (validToken) {
          // Validate with server
          const loginSuccess = await jwtLogin();
          
          if (loginSuccess) {
            console.log("Session restored successfully");
          } else {
            console.log("Session validation failed, clearing auth data");
            await clearAuthData();
          }
        } else {
          console.log("Token validation/refresh failed, clearing auth data");
          await clearAuthData();
        }
      } else {
        console.log("No existing tokens found");
      }
    } catch (error) {
      console.error("Auth initialization error:", error);
      await clearAuthData();
    }
  }
});
