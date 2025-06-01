/**
 * Ultra-Restrictive Pull-to-Refresh Composable
 * ONLY activates when page is at exact top and user pulls down significantly
 */

export const usePullToRefresh = (refreshCallback, options = {}) => {
  const {
    threshold = 60, // Facebook-like easy trigger
    maxPullDistance = 120, // Reasonable constraint
    resistance = 1.8, // Smooth resistance like Facebook
    hapticFeedback = true,
    showIndicator = true,
    autoHide = true,
    resetDelay = 800, // Facebook-like completion feel
    minPullDistance = 15, // Reasonable activation threshold
  } = options;

  // State management
  const isRefreshing = ref(false);
  const isPulling = ref(false);
  const pullDistance = ref(0);
  const canRefresh = ref(false);
  const refreshTriggered = ref(false);  // Touch tracking
  let startY = 0;
  let startX = 0;
  let currentY = 0;
  let initialTouchY = 0;
  let scrollElement = null;
  let targetElement = null;
  let hasMovedEnough = false;
  let touchStartTime = 0;
  let isScrolling = false;
  let rafId = null;
  // Check if device supports touch
  const isTouchDevice = ref(false);

  // Smooth pull calculations with Facebook-like behavior
  const pullProgress = computed(() => {
    const progress = pullDistance.value / threshold;
    return Math.min(Math.sqrt(progress), 1);
  });

  const pullOpacity = computed(() => {
    const baseOpacity = Math.min(pullDistance.value / 30, 1);
    return Math.max(0, Math.min(baseOpacity, 1));
  });

  const refreshReady = computed(() => {
    return pullDistance.value >= threshold && !isRefreshing.value;
  });

  // Facebook-like elastic resistance
  const elasticPullDistance = computed(() => {
    if (pullDistance.value <= threshold) {
      return pullDistance.value;
    }
    const excess = pullDistance.value - threshold;
    const elasticExcess = Math.sqrt(excess) * 8;
    return Math.min(threshold + elasticExcess, maxPullDistance);
  });  // ULTRA-STRICT scroll position check - must be at absolute top
  const isAtExactTop = () => {
    // Check multiple scroll positions to be absolutely sure
    const windowScrollY = window.pageYOffset || window.scrollY || 0;
    const documentScrollTop = document.documentElement.scrollTop || 0;
    const bodyScrollTop = document.body.scrollTop || 0;
    
    // Must be at absolute zero
    if (windowScrollY !== 0 || documentScrollTop !== 0 || bodyScrollTop !== 0) {
      return false;
    }
    
    // Additional check for custom scroll element
    if (scrollElement && scrollElement !== window && scrollElement !== document.documentElement) {
      return scrollElement.scrollTop === 0;
    }
    
    return true;
  };
  // Scroll handler to immediately disable pull-to-refresh if page scrolls
  const handleScroll = () => {
    if (!isAtExactTop() && (isPulling.value || hasMovedEnough)) {
      resetPull();
    }
  };

  // Initialize touch events
  const initializePullToRefresh = (element = null) => {
    isTouchDevice.value = 'ontouchstart' in window || navigator.maxTouchPoints > 0;
    
    if (!isTouchDevice.value) return;

    scrollElement = element || document.documentElement;
    targetElement = element || document.body;
    
    // Add scroll listener to immediately disable on scroll
    window.addEventListener('scroll', handleScroll, { passive: true });
    document.addEventListener('scroll', handleScroll, { passive: true });
    
    targetElement.addEventListener('touchstart', handleTouchStart, { passive: false });
    targetElement.addEventListener('touchmove', handleTouchMove, { passive: false });
    targetElement.addEventListener('touchend', handleTouchEnd, { passive: true });
    
    return () => cleanup();
  };// Handle touch start - ULTRA conservative approach
  const handleTouchStart = (e) => {
    // CRITICAL: Must be at absolute top with multiple checks
    if (!isAtExactTop()) return;
    
    // Double-check after a tiny delay to catch any scroll momentum
    setTimeout(() => {
      if (!isAtExactTop()) {
        resetPull();
        return;
      }
    }, 10);
    
    // Store initial touch direction check data
    initialTouchY = e.touches[0].clientY;
    
    // Quick check for essential interactive elements only
    const target = e.target;
    const tagName = target.tagName.toLowerCase();
    
    // Block only critical interactive elements
    if (tagName === 'input' || tagName === 'button' || tagName === 'select' || 
        tagName === 'textarea' || tagName === 'a') return;
    
    // Block contenteditable and draggable
    if (target.contentEditable === 'true' || target.draggable) return;
    
    // Block if inside horizontal scrollable container
    if (target.closest('.overflow-x-auto, .overflow-x-scroll, [style*="overflow-x"]')) return;
    
    const touch = e.touches[0];
    startY = touch.clientY;
    startX = touch.clientX;
    currentY = startY;
    touchStartTime = Date.now();
    refreshTriggered.value = false;
    hasMovedEnough = false;
    isScrolling = false;
      // Cancel any existing animation
    if (rafId) {
      cancelAnimationFrame(rafId);
      rafId = null;
    }
  };  // Handle touch move - ULTRA conservative with constant position checking
  const handleTouchMove = (e) => {
    if (isRefreshing.value) return;

    // CRITICAL: Constantly verify we're still at top
    if (!isAtExactTop()) {
      resetPull();
      return;
    }

    const touch = e.touches[0];
    currentY = touch.clientY;
    const deltaY = currentY - startY;
    const deltaX = Math.abs(touch.clientX - startX);

    // Detect horizontal scrolling early and exit
    if (deltaX > Math.abs(deltaY) && deltaX > 10) {
      isScrolling = true;
      resetPull();
      return;
    }

    // CRITICAL FIX: Only activate when pulling DOWN (positive deltaY)
    // This ensures pulling UP (negative deltaY) doesn't trigger refresh
    if (deltaY <= 0) {
      resetPull();
      return;
    }    // Triple check - still at exact top AND pulling DOWN before activating
    if (deltaY > minPullDistance && !hasMovedEnough && isAtExactTop() && (currentY > startY)) {
      hasMovedEnough = true;
      isPulling.value = true;
    }
      // Only proceed if we're actively pulling DOWN and still at top
    if (!isPulling.value || !hasMovedEnough || isScrolling || !isAtExactTop() || currentY <= startY) {
      resetPull();
      return;
    }

    // Prevent default behavior only when actively pulling
    e.preventDefault();

    // Calculate pull distance with smooth resistance
    let calculatedDistance;
    if (deltaY <= threshold) {
      calculatedDistance = deltaY / resistance;
    } else {
      const baseDistance = threshold / resistance;
      const excess = deltaY - threshold;
      const elasticFactor = Math.max(0.1, 1 - (excess / (maxPullDistance * 2)));
      calculatedDistance = baseDistance + (excess * elasticFactor) / resistance;
    }
      pullDistance.value = Math.min(calculatedDistance, maxPullDistance);
    canRefresh.value = pullDistance.value >= (threshold / resistance);

    // Haptic feedback
    if (canRefresh.value && !refreshTriggered.value && hapticFeedback) {
      navigator.vibrate?.(25); // Light feedback like Facebook
      refreshTriggered.value = true;
    }
  };
  // Handle touch end - conservative completion
  const handleTouchEnd = () => {
    if (!hasMovedEnough || !isPulling.value || isScrolling) {
      animateReset();
      return;
    }

    isPulling.value = false;

    if (canRefresh.value && !isRefreshing.value && isAtExactTop()) {
      triggerRefresh();
    } else {
      animateReset();
    }
  };
  // Trigger refresh with improved feedback
  const triggerRefresh = async () => {
    if (isRefreshing.value) return;

    isRefreshing.value = true;
    canRefresh.value = false;
    
    // Keep indicator at optimal position during refresh
    const optimalPosition = threshold / resistance * 0.8;
    pullDistance.value = optimalPosition;

    try {
      if (refreshCallback && typeof refreshCallback === 'function') {
        await refreshCallback();
      }

      if (hapticFeedback) {
        navigator.vibrate?.([15, 100, 15]); // Success pattern
      }
    } catch (error) {
      console.error('Refresh failed:', error);
      if (hapticFeedback) {
        navigator.vibrate?.([100, 50, 100]); // Error pattern
      }
    } finally {
      setTimeout(() => {
        animateReset();
        setTimeout(() => {
          isRefreshing.value = false;
        }, 200);
      }, resetDelay);
    }
  };
  // Smooth animation for reset
  const animateReset = () => {
    if (!pullDistance.value) {
      resetPull();
      return;
    }

    const startDistance = pullDistance.value;
    const duration = 300;
    const startTime = performance.now();

    const animate = (currentTime) => {
      const elapsed = currentTime - startTime;
      const progress = Math.min(elapsed / duration, 1);
      
      const easeOut = 1 - Math.pow(1 - progress, 3);
      
      pullDistance.value = startDistance * (1 - easeOut);
      
      if (progress < 1 && pullDistance.value > 0.5) {
        rafId = requestAnimationFrame(animate);
      } else {
        resetPull();
        if (rafId) {
          cancelAnimationFrame(rafId);
          rafId = null;
        }
      }
    };
    
    rafId = requestAnimationFrame(animate);
  };

  // Reset pull state
  const resetPull = () => {
    pullDistance.value = 0;
    canRefresh.value = false;
    isPulling.value = false;
    refreshTriggered.value = false;
    hasMovedEnough = false;
    isScrolling = false;
    
    if (rafId) {
      cancelAnimationFrame(rafId);
      rafId = null;
    }
  };
  // Manual refresh function
  const manualRefresh = async () => {
    await triggerRefresh();
  };  // Cleanup with animation cleanup
  const cleanup = () => {
    if (rafId) {
      cancelAnimationFrame(rafId);
      rafId = null;
    }
    
    // Remove scroll listeners
    window.removeEventListener('scroll', handleScroll);
    document.removeEventListener('scroll', handleScroll);
    
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
    elasticPullDistance: readonly(elasticPullDistance),
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
    animateReset,
  };
};
