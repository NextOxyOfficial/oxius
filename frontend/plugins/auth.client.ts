// Auto-authentication plugin for session persistence
export default defineNuxtPlugin(async () => {
  const { getValidToken, jwtLogin, clearAuthData } = useAuth();
  
  // Only run on client side
  if (process.client) {
    try {
      // Check if we have any tokens
      const jwt = useCookie("adsyclub-jwt");
      const refreshToken = useCookie("adsyclub-refresh");
      
      if (jwt.value || refreshToken.value) {
        // Try to get a valid token (this will refresh if needed)
        const validToken = await getValidToken();
        
        if (validToken) {
          // Validate with server
          const loginSuccess = await jwtLogin();
          
          if (!loginSuccess) {
            await clearAuthData();
          }
        } else {
          await clearAuthData();
        }
      }
    } catch (error) {
      await clearAuthData();
    }
  }
});
