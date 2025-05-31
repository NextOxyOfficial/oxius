/**
 * Ultra-Restrictive Pull-to-Refresh Composable
 * ONLY activates when page is at exact top and user pulls down significantly
 */

export const usePullToRefresh = (refreshCallback, options = {}) => {
  const {
    threshold = 120, // Increased threshold to make it harder to trigger
    maxPullDistance = 150,
    resistance = 4.0, // Increased resistance
    hapticFeedback = true,
    showIndicator = true,
    autoHide = true,
    resetDelay = 300,
    minPullDistance = 50, // INCREASED - need significant movement to activate
  } = options;

  // State management
  const isRefreshing = ref(false);
  const isPulling = ref(false);
  const pullDistance = ref(0);
  const canRefresh = ref(false);
  const refreshTriggered = ref(false);

  // Touch tracking
  let startY = 0;
  let currentY = 0;
  let scrollElement = null;
  let targetElement = null;
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

  // ULTRA-STRICT scroll position check
  const isAtExactTop = () => {
    if (scrollElement === window || scrollElement === document.documentElement) {
      return Math.max(
        window.pageYOffset || 0,
        document.documentElement.scrollTop || 0,
        document.body.scrollTop || 0
      ) === 0;
    }
    return (scrollElement.scrollTop || 0) === 0;
  };

  // Initialize touch events
  const initializePullToRefresh = (element = null) => {
    isTouchDevice.value = 'ontouchstart' in window || navigator.maxTouchPoints > 0;
    
    if (!isTouchDevice.value) return;

    scrollElement = element || document.documentElement;
    targetElement = element || document.body;
    
    targetElement.addEventListener('touchstart', handleTouchStart, { passive: false });
    targetElement.addEventListener('touchmove', handleTouchMove, { passive: false });
    targetElement.addEventListener('touchend', handleTouchEnd, { passive: true });
    
    return () => cleanup();
  };

  // Handle touch start - VERY restrictive
  const handleTouchStart = (e) => {
    // Don't interfere if refreshing
    if (isRefreshing.value) return;
    
    // IMMEDIATELY exit if not at exact top
    if (!isAtExactTop()) return;
    
    // Check for ANY interactive elements
    const target = e.target;
    const isInteractiveElement = target.closest('.carousel, .slider, .swiper, .glide, [data-carousel], [data-slider], .keen-slider, .splide, .owl-carousel') ||
                                target.closest('.touch-slider, .rtl-slider, .slider-page, .gold-sponsors-slider, .product-slider-container, .donors-carousel') ||
                                target.closest('.slider-nav-btn, [class*="slider"], [class*="carousel"], [class*="swiper"]') ||
                                target.closest('.swiper-container, .swiper-wrapper, .swiper-slide, .sponsors-container, .sponsors-track') ||
                                target.closest('.product-card, .sponsor-item, .slider-container, .hero-banner') ||
                                target.closest('input, button, select, textarea, [contenteditable], [draggable]') ||
                                target.closest('[role="button"], [role="slider"], [role="tabpanel"]') ||
                                target.closest('.overflow-x-auto, .overflow-x-scroll') ||
                                target.closest('a, [onclick]'); // Also block links and clickable elements
    
    if (isInteractiveElement) return;
    
    const touch = e.touches[0];
    startY = touch.clientY;
    currentY = startY;
    refreshTriggered.value = false;
    hasMovedEnough = false;
    
    // Don't set isPulling yet - wait for significant movement
  };

  // Handle touch move - EXTREMELY restrictive
  const handleTouchMove = (e) => {
    // Bail out immediately if refreshing
    if (isRefreshing.value) return;

    const touch = e.touches[0];
    currentY = touch.clientY;
    const deltaY = currentY - startY;

    // CRITICAL: Must still be at exact top
    if (!isAtExactTop()) {
      resetPull();
      return;
    }

    // Must be pulling DOWN significantly
    if (deltaY <= 0) {
      resetPull();
      return;
    }

    // Check interactive elements again during move
    const target = e.target;
    const isInteractiveElement = target.closest('.carousel, .slider, .swiper, .glide, [data-carousel], [data-slider], .keen-slider, .splide, .owl-carousel') ||
                                target.closest('.touch-slider, .rtl-slider, .slider-page, .gold-sponsors-slider, .product-slider-container, .donors-carousel') ||
                                target.closest('.slider-nav-btn, [class*="slider"], [class*="carousel"], [class*="swiper"]') ||
                                target.closest('.swiper-container, .swiper-wrapper, .swiper-slide, .sponsors-container, .sponsors-track') ||
                                target.closest('.product-card, .sponsor-item, .slider-container, .hero-banner') ||
                                target.closest('input, button, select, textarea, [contenteditable], [draggable]') ||
                                target.closest('[role="button"], [role="slider"], [role="tabpanel"]') ||
                                target.closest('.overflow-x-auto, .overflow-x-scroll') ||
                                target.closest('a, [onclick]');
    
    if (isInteractiveElement) {
      resetPull();
      return;
    }

    // Only activate after SIGNIFICANT downward movement
    if (deltaY > minPullDistance && isAtExactTop()) {
      hasMovedEnough = true;
      
      // Only now allow pull-to-refresh
      if (!isPulling.value) {
        isPulling.value = true;
      }
    }
    
    // Only proceed if we're actively pulling
    if (!isPulling.value || !hasMovedEnough) return;

    // Triple check - still at top?
    if (!isAtExactTop()) {
      resetPull();
      return;
    }

    // Prevent scrolling only when actively pulling
    if (isPulling.value && hasMovedEnough) {
      e.preventDefault();
    }

    // Calculate pull distance
    const resistedDistance = deltaY / resistance;
    pullDistance.value = Math.min(resistedDistance, maxPullDistance);

    // Update state
    canRefresh.value = pullDistance.value >= threshold;

    // Haptic feedback
    if (canRefresh.value && !refreshTriggered.value && hapticFeedback) {
      triggerHapticFeedback();
      refreshTriggered.value = true;
    }
  };

  // Handle touch end
  const handleTouchEnd = () => {
    // Only trigger if we had significant movement and are pulling
    if (!hasMovedEnough || !isPulling.value) {
      resetPull();
      return;
    }

    isPulling.value = false;

    if (canRefresh.value && !isRefreshing.value && isAtExactTop()) {
      triggerRefresh();
    } else {
      resetPull();
    }
  };

  // Trigger refresh
  const triggerRefresh = async () => {
    if (isRefreshing.value) return;

    isRefreshing.value = true;
    canRefresh.value = false;
    pullDistance.value = threshold;

    try {
      if (refreshCallback && typeof refreshCallback === 'function') {
        await refreshCallback();
      }

      if (hapticFeedback) {
        triggerHapticFeedback('success');
      }
    } catch (error) {
      console.error('Refresh failed:', error);
      if (hapticFeedback) {
        triggerHapticFeedback('error');
      }
    } finally {
      setTimeout(() => {
        resetPull();
        isRefreshing.value = false;
      }, resetDelay);
    }
  };

  // Reset pull state
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
  };

  // Cleanup
  const cleanup = () => {
    if (targetElement) {
      targetElement.removeEventListener('touchstart', handleTouchStart);
      targetElement.removeEventListener('touchmove', handleTouchMove);
      targetElement.removeEventListener('touchend', handleTouchEnd);
    }
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
