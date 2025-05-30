/**
 * Global Refresh Composable
 * Provides easy integration with the global refresh system
 */

export const useGlobalRefresh = (options = {}) => {
  const {
    // Component identification
    componentId = null,
    
    // Refresh configuration
    autoRegister = true,
    refreshOnMount = false,
    refreshOnRouteChange = false,
    
    // Refresh handler
    onRefresh = null,
    
    // Event handlers
    onRefreshStart = null,
    onRefreshSuccess = null,
    onRefreshError = null,
  } = options;

  const nuxtApp = useNuxtApp();
  const route = useRoute();
  const { $globalRefresh } = nuxtApp;

  // State
  const isRefreshing = ref(false);
  const lastRefreshTime = ref(0);
  const refreshError = ref(null);

  // Generate component ID if not provided
  const actualComponentId = componentId || `component-${Math.random().toString(36).substring(2, 9)}`;

  // Cleanup functions
  const cleanupFunctions = [];

  // Main refresh function
  const refresh = async (force = false) => {
    if (isRefreshing.value && !force) return;

    try {
      isRefreshing.value = true;
      refreshError.value = null;
      
      if (onRefreshStart) {
        onRefreshStart();
      }

      // Call component-specific refresh handler
      if (onRefresh && typeof onRefresh === 'function') {
        await onRefresh();
      }

      lastRefreshTime.value = Date.now();

      if (onRefreshSuccess) {
        onRefreshSuccess();
      }

    } catch (error) {
      console.error(`Refresh failed for component ${actualComponentId}:`, error);
      refreshError.value = error;

      if (onRefreshError) {
        onRefreshError(error);
      }

      throw error;
    } finally {
      isRefreshing.value = false;
    }
  };

  // Register with global refresh system
  const registerWithGlobalSystem = () => {
    if (!$globalRefresh || !onRefresh) return;

    const unregister = $globalRefresh.registerComponentRefresh(actualComponentId, refresh);
    cleanupFunctions.push(unregister);
  };

  // Setup event listeners
  const setupEventListeners = () => {
    if (!$globalRefresh) return;

    if (onRefreshStart) {
      const unsubscribe = $globalRefresh.onRefreshStart(onRefreshStart);
      cleanupFunctions.push(unsubscribe);
    }

    if (onRefreshSuccess) {
      const unsubscribe = $globalRefresh.onRefreshSuccess(onRefreshSuccess);
      cleanupFunctions.push(unsubscribe);
    }

    if (onRefreshError) {
      const unsubscribe = $globalRefresh.onRefreshError(onRefreshError);
      cleanupFunctions.push(unsubscribe);
    }
  };

  // Setup route change refresh
  const setupRouteChangeRefresh = () => {
    if (!refreshOnRouteChange) return;

    const router = useRouter();
    const unsubscribe = router.afterEach(async (to, from) => {
      if (to.path !== from.path) {
        try {
          await refresh();
        } catch (error) {
          console.error('Route change refresh failed:', error);
        }
      }
    });

    cleanupFunctions.push(unsubscribe);
  };

  // Initialize
  const initialize = () => {
    if (autoRegister) {
      registerWithGlobalSystem();
    }
    
    setupEventListeners();
    setupRouteChangeRefresh();
  };

  // Cleanup
  const cleanup = () => {
    cleanupFunctions.forEach(fn => fn());
    cleanupFunctions.length = 0;
  };

  // Lifecycle hooks
  onMounted(() => {
    initialize();
    
    if (refreshOnMount) {
      nextTick(() => {
        refresh().catch(error => {
          console.error('Mount refresh failed:', error);
        });
      });
    }
  });

  onUnmounted(() => {
    cleanup();
  });

  // Watch for route changes
  if (refreshOnRouteChange) {
    watch(
      () => route.path,
      async (newPath, oldPath) => {
        if (newPath !== oldPath) {
          try {
            await refresh();
          } catch (error) {
            console.error('Route change refresh failed:', error);
          }
        }
      }
    );
  }

  return {
    // Core functionality
    refresh,
    
    // State
    isRefreshing: readonly(isRefreshing),
    lastRefreshTime: readonly(lastRefreshTime),
    refreshError: readonly(refreshError),
    
    // Configuration
    componentId: actualComponentId,
    
    // Utilities
    canRefresh: computed(() => !isRefreshing.value),
    hasError: computed(() => !!refreshError.value),
    
    // Manual control
    registerWithGlobalSystem,
    cleanup,
    
    // Global refresh access
    triggerGlobalRefresh: $globalRefresh?.refresh || (() => console.warn('Global refresh not available')),
    globalRefreshState: $globalRefresh?.state || {},
  };
};

// Convenience composable for page-level refresh
export const usePageRefresh = (refreshHandler, options = {}) => {
  const route = useRoute();
  const nuxtApp = useNuxtApp();
  const { $globalRefresh } = nuxtApp;

  const pageName = options.pageName || route.name;

  onMounted(() => {
    if ($globalRefresh && refreshHandler) {
      const unregister = $globalRefresh.registerPageRefresh(pageName, refreshHandler);
      
      onUnmounted(() => {
        unregister();
      });
    }
  });

  return {
    refresh: refreshHandler,
    triggerGlobalRefresh: $globalRefresh?.refresh || (() => console.warn('Global refresh not available')),
  };
};
