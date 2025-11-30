/**
 * Composable for handling static asset paths
 * Uses /static/frontend/ prefix which works in both dev and production
 * (Nuxt's nitro config serves public folder at /static/frontend/ as well)
 */
export const useStaticAssets = () => {
  // Use /static/frontend/ prefix consistently - works in both environments
  // because nitro.publicAssets is configured to serve public folder at this path
  const chatIconPath = '/static/frontend/images/chat_icon.png';
  const placeholderPath = '/static/frontend/images/placeholder.jpg';
  const faviconPath = '/static/frontend/favicon.png';
  const logoPath = '/static/frontend/images/logo.png';
  
  return {
    chatIconPath,
    placeholderPath,
    faviconPath,
    logoPath
  };
};
