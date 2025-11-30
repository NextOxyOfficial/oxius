/**
 * Composable for handling static asset paths
 * Works in both development and production environments
 */
export const useStaticAssets = () => {
  const config = useRuntimeConfig();
  
  // Check if we're in production
  const isProduction = computed(() => {
    return config.public.baseURL?.includes('adsyclub.com');
  });
  
  // Get the correct path for static assets
  const getAssetPath = (path) => {
    // Remove leading slash if present
    const cleanPath = path.startsWith('/') ? path.slice(1) : path;
    
    // In production, use /static/frontend/ prefix
    // In development, use root path
    if (isProduction.value) {
      return `/static/frontend/${cleanPath}`;
    }
    return `/${cleanPath}`;
  };
  
  // Common asset paths
  const chatIconPath = computed(() => getAssetPath('images/chat_icon.png'));
  const placeholderPath = computed(() => getAssetPath('images/placeholder.jpg'));
  const faviconPath = computed(() => getAssetPath('favicon.png'));
  const logoPath = computed(() => getAssetPath('images/logo.png'));
  
  return {
    isProduction,
    getAssetPath,
    chatIconPath,
    placeholderPath,
    faviconPath,
    logoPath
  };
};
