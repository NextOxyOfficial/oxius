/**
 * Professional Pull-to-Refresh Composable
 * Provides smooth slide down and auto reload functionality for mobile app experience
 */

export const usePullToRefresh = (refreshCallback, options = {}) => {
  const {
    threshold = 100, // Distance to trigger refresh (increased from 80)
    maxPullDistance = 150, // Maximum pull distance (increased from 120)
    resistance = 3.0, // Resistance factor for smooth feel (increased from 2.5)
    hapticFeedback = true, // Enable haptic feedback on mobile
    showIndicator = true, // Show pull indicator
    autoHide = true, // Auto hide after refresh
    resetDelay = 300, // Delay before reset animation
    minPullDistance = 30, // Minimum distance to consider as pull vs tap
  } = options;

  // State management
  const isRefreshing = ref(false);
  const isPulling = ref(false);
  const pullDistance = ref(0);
  const canRefresh = ref(false);
  const refreshTriggered = ref(false);  // Touch tracking
  let startY = 0;
  let currentY = 0;
  let isScrolling = false;
  let scrollElement = null;
  let hasMovedEnough = false;

  // Check if device supports touch
  const isTouchDevice = ref(false);

  // Pull state computed
  const pullProgress = computed(() => {
    return Math.min(pullDistance.value / threshold, 1);
  });

  const pullOpacity = computed(() => {
    return Math.min(pullDistance.value / (threshold * 0.6), 1);
  });

  const refreshReady = computed(() => {
    return pullDistance.value >= threshold && !isRefreshing.value;
  });

  // Initialize touch events
  const initializePullToRefresh = (element = null) => {
    isTouchDevice.value = 'ontouchstart' in window || navigator.maxTouchPoints > 0;
    
    if (!isTouchDevice.value) return;

    scrollElement = element || window;
    
    // Add passive event listeners for better performance
    document.addEventListener('touchstart', handleTouchStart, { passive: false });
    document.addEventListener('touchmove', handleTouchMove, { passive: false });
    document.addEventListener('touchend', handleTouchEnd, { passive: true });
    
    return () => cleanup();
  };  // Handle touch start
  const handleTouchStart = (e) => {
    if (isRefreshing.value) return;
    
    const touch = e.touches[0];
    startY = touch.clientY;
    currentY = startY;
    isScrolling = false;
    refreshTriggered.value = false;
    hasMovedEnough = false;

    // Check if we're at the top of the page
    const scrollTop = scrollElement === window 
      ? window.pageYOffset || document.documentElement.scrollTop
      : scrollElement.scrollTop;
    
    if (scrollTop > 0) return;
    
    // Don't automatically set isPulling to true on touch start
    // Only activate pull-to-refresh when user actually moves their finger down
  };// Handle touch move
  const handleTouchMove = (e) => {
    // Always track current Y position
    const touch = e.touches[0];
    currentY = touch.clientY;
    const deltaY = currentY - startY;
    
    // Check for minimum movement threshold to differentiate from tap
    if (deltaY > minPullDistance) {
      hasMovedEnough = true;
      
      // Only activate pull-to-refresh when user actually moves down
      if (!isPulling.value && deltaY > 0) {
        // Check if we're still at the top of the page
        const scrollTop = scrollElement === window 
          ? window.pageYOffset || document.documentElement.scrollTop
          : scrollElement.scrollTop;
        
        if (scrollTop === 0) {
          isPulling.value = true;
        }
      }
    }
    
    // Only proceed with pull logic if we're in pulling state
    if (!isPulling.value || isRefreshing.value) return;

    // Only proceed if pulling down
    if (deltaY <= 0) {
      resetPull();
      return;
    }

    // Check if we're still at the top
    const scrollTop = scrollElement === window 
      ? window.pageYOffset || document.documentElement.scrollTop
      : scrollElement.scrollTop;
    
    if (scrollTop > 0) {
      resetPull();
      return;
    }

    // Prevent default scrolling when pulling down from top
    if (hasMovedEnough && deltaY > minPullDistance) {
      e.preventDefault();
    }

    // Calculate pull distance with resistance
    const resistedDistance = deltaY / resistance;
    pullDistance.value = Math.min(resistedDistance, maxPullDistance);

    // Update state
    canRefresh.value = pullDistance.value >= threshold;

    // Haptic feedback when reaching threshold
    if (canRefresh.value && !refreshTriggered.value && hapticFeedback) {
      triggerHapticFeedback();
      refreshTriggered.value = true;
    }
  };  // Handle touch end
  const handleTouchEnd = () => {
    // If we didn't move enough, treat it as a tap, not a pull
    if (!hasMovedEnough) {
      resetPull();
      return;
    }
    
    if (!isPulling.value) return;

    isPulling.value = false;

    if (canRefresh.value && !isRefreshing.value) {
      // Trigger refresh
      triggerRefresh();
    } else {
      // Reset to initial state
      resetPull();
    }
  };

  // Trigger refresh
  const triggerRefresh = async () => {
    if (isRefreshing.value) return;

    isRefreshing.value = true;
    canRefresh.value = false;

    // Keep indicator visible during refresh
    pullDistance.value = threshold;

    try {
      // Call the refresh callback
      if (refreshCallback && typeof refreshCallback === 'function') {
        await refreshCallback();
      }

      // Haptic feedback for completion
      if (hapticFeedback) {
        triggerHapticFeedback('success');
      }

    } catch (error) {
      console.error('Refresh failed:', error);
      
      if (hapticFeedback) {
        triggerHapticFeedback('error');
      }
    } finally {
      // Reset after delay
      setTimeout(() => {
        resetPull();
        isRefreshing.value = false;
      }, resetDelay);
    }
  };  // Reset pull state
  const resetPull = () => {
    pullDistance.value = 0;
    canRefresh.value = false;
    isPulling.value = false;
    refreshTriggered.value = false;
    hasMovedEnough = false;
  };

  // Trigger haptic feedback
  const triggerHapticFeedback = (type = 'light') => {
    if (!hapticFeedback || !navigator.vibrate) return;

    const patterns = {
      light: [10],
      success: [10, 50, 10],
      error: [50, 50, 50],
    };

    navigator.vibrate(patterns[type] || patterns.light);
  };

  // Manual refresh function
  const manualRefresh = async () => {
    await triggerRefresh();
  };  // Cleanup
  const cleanup = () => {
    document.removeEventListener('touchstart', handleTouchStart);
    document.removeEventListener('touchmove', handleTouchMove);
    document.removeEventListener('touchend', handleTouchEnd);
    
    resetPull();
  };

  // Auto cleanup on unmount
  onUnmounted(() => {
    cleanup();
  });

  return {
    // State
    isRefreshing: readonly(isRefreshing),
    isPulling: readonly(isPulling),
    pullDistance: readonly(pullDistance),
    canRefresh: readonly(canRefresh),
    pullProgress: readonly(pullProgress),
    pullOpacity: readonly(pullOpacity),
    refreshReady: readonly(refreshReady),
    isTouchDevice: readonly(isTouchDevice),

    // Methods
    initializePullToRefresh,
    triggerRefresh,
    manualRefresh,
    resetPull,
    cleanup,
  };
};
