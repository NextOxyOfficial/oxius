/**
 * Global Refresh Coordinator Plugin
 * Provides app-wide refresh functionality and coordinates refreshes across all layouts and pages
 */

export default defineNuxtPlugin((nuxtApp) => {
  if (!process.client) return;

  const router = useRouter();
  const route = useRoute();
  const { $pullToRefresh } = nuxtApp;
  const refreshCoordinator = useRefreshCoordinator();

  // Global refresh state
  const globalRefreshState = reactive({
    isRefreshing: false,
    lastRefreshTime: 0,
    refreshCount: 0,
    failedRefreshCount: 0
  });

  // Page-specific refresh handlers registry
  const pageRefreshHandlers = new Map();

  // Component refresh registry
  const componentRefreshRegistry = new Map();

  // Global refresh function that works across all layouts
  const performGlobalRefresh = async () => {
    if (globalRefreshState.isRefreshing) return;

    try {
      globalRefreshState.isRefreshing = true;
      globalRefreshState.lastRefreshTime = Date.now();
      globalRefreshState.refreshCount++;

      console.log('🔄 Starting global refresh...', {
        route: route.name,
        path: route.path,
        layout: route.meta?.layout || 'default'
      });

      // Emit start event
      refreshCoordinator.eventBus.emit('global-refresh-start');

      // Get current page refresh handler
      const currentPageHandler = pageRefreshHandlers.get(route.name);
      
      if (currentPageHandler) {
        console.log('📄 Executing page-specific refresh for:', route.name);
        await currentPageHandler();
      } else {
        console.log('🔄 Executing default refresh behavior');
        await performDefaultRefresh();
      }

      // Refresh all registered components
      for (const [componentId, refreshFn] of componentRefreshRegistry) {
        try {
          console.log('🧩 Refreshing component:', componentId);
          await refreshFn();
        } catch (error) {
          console.error(`Failed to refresh component ${componentId}:`, error);
        }
      }

      // Emit success event
      refreshCoordinator.eventBus.emit('global-refresh-success');
      globalRefreshState.failedRefreshCount = 0; // Reset failure count on success

      console.log('✅ Global refresh completed successfully');

    } catch (error) {
      console.error('❌ Global refresh failed:', error);
      globalRefreshState.failedRefreshCount++;
      refreshCoordinator.eventBus.emit('global-refresh-error', error);
      throw error;
    } finally {
      globalRefreshState.isRefreshing = false;
    }
  };

  // Default refresh behavior
  const performDefaultRefresh = async () => {
    // Refresh route data
    await refreshCookie('global-refresh-trigger', true);
    
    // Clear Nuxt data cache for current route
    if (nuxtApp.ssrContext) {
      await nuxtApp.runWithContext(() => clearNuxtData());
    }
    
    // Small delay for UI feedback
    await new Promise(resolve => setTimeout(resolve, 300));
    
    // Clear refresh trigger
    await refreshCookie('global-refresh-trigger', false);
  };

  // Register page-specific refresh handler
  const registerPageRefresh = (pageName, refreshHandler) => {
    pageRefreshHandlers.set(pageName, refreshHandler);
    
    // Return unregister function
    return () => pageRefreshHandlers.delete(pageName);
  };

  // Register component refresh handler
  const registerComponentRefresh = (componentId, refreshHandler) => {
    componentRefreshRegistry.set(componentId, refreshHandler);
    
    // Return unregister function
    return () => componentRefreshRegistry.delete(componentId);
  };

  // Auto-refresh when coming back from background (app focus)
  const setupAppFocusRefresh = () => {
    let wasHidden = false;
    let hiddenTime = 0;

    const handleVisibilityChange = async () => {
      if (document.hidden) {
        wasHidden = true;
        hiddenTime = Date.now();
      } else if (wasHidden) {
        const timeHidden = Date.now() - hiddenTime;
        const fiveMinutes = 5 * 60 * 1000;

        // Auto refresh if app was hidden for more than 5 minutes
        if (timeHidden > fiveMinutes) {
          console.log('🔄 App returned from background after', Math.round(timeHidden / 1000), 'seconds - triggering refresh');
          try {
            await performGlobalRefresh();
          } catch (error) {
            console.error('Auto refresh on app focus failed:', error);
          }
        }
        wasHidden = false;
      }
    };

    document.addEventListener('visibilitychange', handleVisibilityChange);

    // Cleanup function
    return () => {
      document.removeEventListener('visibilitychange', handleVisibilityChange);
    };
  };

  // Setup network-based refresh
  const setupNetworkRefresh = () => {
    const handleOnline = async () => {
      console.log('🌐 Network connection restored - triggering refresh');
      try {
        await performGlobalRefresh();
      } catch (error) {
        console.error('Network refresh failed:', error);
      }
    };

    window.addEventListener('online', handleOnline);

    return () => {
      window.removeEventListener('online', handleOnline);
    };
  };

  // Initialize global refresh system
  const cleanupFunctions = [];
  
  // Setup various refresh triggers
  cleanupFunctions.push(setupAppFocusRefresh());
  cleanupFunctions.push(setupNetworkRefresh());

  // Listen for route changes to reset page handlers
  const routeChangeCleanup = router.afterEach((to, from) => {
    if (to.name !== from.name) {
      // Clear page-specific handlers when navigating to different pages
      pageRefreshHandlers.clear();
    }
  });

  cleanupFunctions.push(() => routeChangeCleanup());

  // Provide global refresh functionality
  nuxtApp.provide('globalRefresh', {
    // Core functions
    refresh: performGlobalRefresh,
    registerPageRefresh,
    registerComponentRefresh,
    
    // State
    state: readonly(globalRefreshState),
    
    // Utilities
    isRefreshing: computed(() => globalRefreshState.isRefreshing),
    canRefresh: computed(() => !globalRefreshState.isRefreshing),
    lastRefreshTime: computed(() => globalRefreshState.lastRefreshTime),
    
    // Event helpers
    onRefreshStart: (callback) => refreshCoordinator.onRefresh(callback, 'global-refresh-start'),
    onRefreshSuccess: (callback) => refreshCoordinator.onRefresh(callback, 'global-refresh-success'),
    onRefreshError: (callback) => refreshCoordinator.onRefresh(callback, 'global-refresh-error'),
  });

  // Add global properties for easier access in components
  nuxtApp.vueApp.config.globalProperties.$globalRefresh = performGlobalRefresh;
  nuxtApp.vueApp.config.globalProperties.$registerPageRefresh = registerPageRefresh;
  nuxtApp.vueApp.config.globalProperties.$registerComponentRefresh = registerComponentRefresh;

  // Cleanup on app unmount
  nuxtApp.hook('app:beforeUnmount', () => {
    cleanupFunctions.forEach(cleanup => cleanup());
    pageRefreshHandlers.clear();
    componentRefreshRegistry.clear();
  });

  console.log('🚀 Global refresh coordinator initialized');
});
