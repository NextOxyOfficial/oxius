// Authentication middleware for protected routes
export default defineNuxtRouteMiddleware(async (to, from) => {
  const { user, getValidToken, clearAuthData } = useAuth();

  // Routes that don't require authentication
  const publicRoutes = [
    "/",
    "/login",
    "/register",
    "/auth/login",
    "/auth/register",
    "/about",
    "/contact",
    "/privacy",
    "/terms",
  ];

  // Check if the route is public
  const isPublicRoute = publicRoutes.some((route) => {
    if (route === to.path) return true;
    // Handle dynamic routes
    if (route.includes("*") || to.path.startsWith(route + "/")) return true;
    return false;
  });

  // If it's a public route, allow access
  if (isPublicRoute) {
    return;
  }

  // For protected routes, check authentication
  try {
    // Try to get a valid token
    const validToken = await getValidToken();

    if (!validToken || !user.value) {
      // Clear any invalid auth data
      await clearAuthData();

      // Redirect to login with return URL
      return navigateTo({
        path: "/auth/login",
        query: { redirect: to.fullPath },
      });
    }
  } catch (error) {
    console.error("Auth middleware error:", error);
    await clearAuthData();

    return navigateTo({
      path: "/auth/login",
      query: { redirect: to.fullPath },
    });
  }
});
