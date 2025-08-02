export default defineNuxtPlugin(() => {
  // Only run on client side
  if (process.client) {
    const router = useRouter();
    
    // Check if we're in a Capacitor environment
    const isCapacitor = typeof window !== 'undefined' && 
      (window.location.protocol === 'capacitor:' || 
       (window.location.protocol === 'https:' && window.location.hostname === 'localhost'));
    
    if (isCapacitor) {
      console.log('Capacitor environment detected');
      
      // Handle navigation errors
      router.onError((error) => {
        console.error('Router error in Capacitor:', error);
        
        // If it's a route not found error, try to reload
        if (error.message.includes('404') || error.message.includes('not found')) {
          console.log('Route not found, attempting fallback...');
          
          // Try to extract the actual route from the URL
          const currentPath = window.location.pathname;
          if (currentPath.startsWith('/order/')) {
            console.log('Order route detected, forcing reload...');
            setTimeout(() => {
              window.location.href = currentPath;
            }, 100);
          }
        }
      });
      
      // Override history navigation for better Capacitor compatibility
      const originalPushState = window.history.pushState;
      const originalReplaceState = window.history.replaceState;
      
      window.history.pushState = function(state, title, url) {
        console.log('History pushState:', url);
        return originalPushState.call(this, state, title, url);
      };
      
      window.history.replaceState = function(state, title, url) {
        console.log('History replaceState:', url);
        return originalReplaceState.call(this, state, title, url);
      };
    }
  }
});
