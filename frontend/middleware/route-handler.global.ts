// Global middleware to handle routing issues in Capacitor apps
export default defineNuxtRouteMiddleware((to, from) => {
  // Handle routes with special characters that might cause issues in Capacitor
  if (process.client && typeof window !== 'undefined') {
    // Check if we're in a Capacitor environment
    const isCapacitor = window.location.protocol === 'capacitor:' || 
                       window.location.protocol === 'https:' && 
                       window.location.hostname === 'localhost';
    
    if (isCapacitor) {
      // Log route navigation for debugging
      console.log('Navigating to:', to.fullPath);
      console.log('Route params:', to.params);
      
      // Handle order routes specifically
      if (to.path.startsWith('/order/') && to.params.id) {
        // Ensure the ID parameter is properly formatted
        const id = Array.isArray(to.params.id) ? to.params.id[0] : to.params.id;
        console.log('Order ID:', id);
        
        // Validate the ID format (allow alphanumeric, hyphens, underscores)
        if (typeof id === 'string' && !/^[a-zA-Z0-9\-_]+$/.test(id)) {
          console.warn('Invalid order ID format:', id);
          throw createError({
            statusCode: 400,
            statusMessage: 'Invalid order ID format'
          });
        }
      }
    }
  }
});
