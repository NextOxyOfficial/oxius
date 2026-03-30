export const useLocationPermission = () => {
  const locationGranted = ref(false);
  const locationDenied = ref(false);
  const locationLoading = ref(false);
  const locationError = ref<string | null>(null);
  const currentPosition = ref<{ latitude: number; longitude: number } | null>(null);

  const checkPermission = async () => {
    if (!navigator.permissions) {
      // Fallback for browsers that don't support permissions API
      return requestLocation();
    }

    try {
      const result = await navigator.permissions.query({ name: 'geolocation' });
      
      if (result.state === 'granted') {
        locationGranted.value = true;
        locationDenied.value = false;
        return true;
      } else if (result.state === 'denied') {
        locationGranted.value = false;
        locationDenied.value = true;
        return false;
      } else {
        // prompt state - need to request
        locationGranted.value = false;
        locationDenied.value = false;
        return null;
      }
    } catch (error) {
      console.error('Permission check failed:', error);
      return null;
    }
  };

  const requestLocation = () => {
    return new Promise<boolean>((resolve) => {
      if (!navigator.geolocation) {
        locationError.value = 'Geolocation is not supported by your browser';
        locationDenied.value = true;
        resolve(false);
        return;
      }

      locationLoading.value = true;
      locationError.value = null;

      navigator.geolocation.getCurrentPosition(
        (position) => {
          locationGranted.value = true;
          locationDenied.value = false;
          locationLoading.value = false;
          currentPosition.value = {
            latitude: position.coords.latitude,
            longitude: position.coords.longitude,
          };
          resolve(true);
        },
        (error) => {
          locationLoading.value = false;
          locationGranted.value = false;
          
          switch (error.code) {
            case error.PERMISSION_DENIED:
              locationDenied.value = true;
              locationError.value = 'Location permission denied. Please enable location access in your browser settings.';
              break;
            case error.POSITION_UNAVAILABLE:
              locationError.value = 'Location information is unavailable.';
              break;
            case error.TIMEOUT:
              locationError.value = 'Location request timed out.';
              break;
            default:
              locationError.value = 'An unknown error occurred while getting location.';
          }
          resolve(false);
        },
        {
          enableHighAccuracy: true,
          timeout: 10000,
          maximumAge: 0,
        }
      );
    });
  };

  const watchPosition = (callback: (position: { latitude: number; longitude: number }) => void) => {
    if (!navigator.geolocation) {
      return null;
    }

    const watchId = navigator.geolocation.watchPosition(
      (position) => {
        const pos = {
          latitude: position.coords.latitude,
          longitude: position.coords.longitude,
        };
        currentPosition.value = pos;
        callback(pos);
      },
      (error) => {
        console.error('Watch position error:', error);
      },
      {
        enableHighAccuracy: true,
        timeout: 10000,
        maximumAge: 5000,
      }
    );

    return watchId;
  };

  const clearWatch = (watchId: number) => {
    if (navigator.geolocation && watchId) {
      navigator.geolocation.clearWatch(watchId);
    }
  };

  // Check permission on mount
  onMounted(() => {
    checkPermission();
  });

  return {
    locationGranted,
    locationDenied,
    locationLoading,
    locationError,
    currentPosition,
    checkPermission,
    requestLocation,
    watchPosition,
    clearWatch,
  };
};
