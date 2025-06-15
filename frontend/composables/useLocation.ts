// Enhanced location persistence composable
// Provides long-term location storage with cookie and localStorage fallback

export function useLocation() {
  const config = useRuntimeConfig();
  
  // Configure location cookie with long-term persistence (1 year)
  const locationCookie = useCookie("location", {
    maxAge: 60 * 60 * 24 * 365, // 1 year in seconds
    sameSite: 'lax',
    secure: config.public.cookieOptions?.default?.secure || false,
    httpOnly: false,
    expires: new Date(Date.now() + (365 * 24 * 60 * 60 * 1000)) // 1 year from now
  });

  // Enhanced location getter with fallback
  const getLocation = () => {
    // First try to get from cookie
    if (locationCookie.value) {
      try {
        // Ensure the location data is valid
        const location = typeof locationCookie.value === 'string' 
          ? JSON.parse(locationCookie.value) 
          : locationCookie.value;
        
        // Validate location structure
        if (location && (location.allOverBangladesh || location.country)) {
          console.log('Location retrieved from cookie:', location);
          return location;
        }
      } catch (error) {
        console.warn('Failed to parse location from cookie:', error);
      }
    }    // Fallback to localStorage
    if (typeof window !== 'undefined') {
      try {
        const storedLocation = localStorage.getItem('adsyclub_location');
        if (storedLocation) {
          const location = JSON.parse(storedLocation);
          if (location && (location.allOverBangladesh || location.country)) {
            console.log('Location retrieved from localStorage:', location);
            // Also update the cookie since we found it in localStorage
            setLocation(location);
            return location;
          }
        }
      } catch (error) {
        console.warn('Failed to retrieve location from localStorage:', error);
      }
    }

    return null;
  };

  // Enhanced location setter with dual storage
  const setLocation = (location: any) => {
    try {
      // Set in cookie for long-term persistence
      locationCookie.value = location;
        // Also set in localStorage as backup
      if (typeof window !== 'undefined') {
        if (location) {
          localStorage.setItem('adsyclub_location', JSON.stringify(location));
          localStorage.setItem('adsyclub_location_timestamp', Date.now().toString());
        } else {
          localStorage.removeItem('adsyclub_location');
          localStorage.removeItem('adsyclub_location_timestamp');
        }
      }
      
      console.log('Location saved:', location);
    } catch (error) {
      console.error('Failed to save location:', error);
    }
  };

  // Clear location from all storage methods
  const clearLocation = () => {
    try {
      // Clear cookie
      locationCookie.value = null;
        // Clear localStorage
      if (typeof window !== 'undefined') {
        localStorage.removeItem('adsyclub_location');
        localStorage.removeItem('adsyclub_location_timestamp');
      }
      
      console.log('Location cleared from all storage');
    } catch (error) {
      console.error('Failed to clear location:', error);
    }
  };
  // Check if location is expired (optional feature for future use)
  const isLocationExpired = (maxAgeHours = 24 * 30) => { // Default 30 days
    if (typeof window === 'undefined') return false;
    
    try {
      const timestamp = localStorage.getItem('adsyclub_location_timestamp');
      if (!timestamp) return true;
      
      const locationAge = Date.now() - parseInt(timestamp);
      const maxAge = maxAgeHours * 60 * 60 * 1000;
      
      return locationAge > maxAge;
    } catch (error) {
      console.warn('Failed to check location expiration:', error);
      return false;
    }
  };

  // Get reactive location with automatic fallback
  const location = computed({
    get: () => getLocation(),
    set: (value) => setLocation(value)
  });

  return {
    location,
    getLocation,
    setLocation,
    clearLocation,
    isLocationExpired
  };
}
