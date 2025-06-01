<template>
  <div class="font-AnekBangla">
    <PublicHeader />
    <slot />
    <PublicFooter />
    <UNotifications />

    <!-- Mobile App Download Popup for Non-Logged Users -->
    <Teleport to="body">
      <div
        v-if="showMobileAppPopup"
        class="fixed inset-0 z-[70] flex items-center justify-center p-4 bg-black/50 backdrop-blur-sm animate-fade-in"
      >
        <div
          class="relative bg-white dark:bg-gray-900 rounded-2xl shadow-2xl max-w-md w-full mx-4 overflow-hidden animate-scale-in"
          @click.stop
        >
          <!-- Close Button -->
          <button
            @click="closeMobileAppPopup"
            class="absolute top-4 right-4 z-10 p-2 rounded-full bg-gray-100 dark:bg-gray-800 hover:bg-gray-200 dark:hover:bg-gray-700 transition-colors"
          >
            <UIcon name="i-heroicons-x-mark" class="w-5 h-5 text-gray-600 dark:text-gray-400" />
          </button>

          <!-- Header with Gradient Background -->
          <div class="relative bg-gradient-to-br from-emerald-500 via-emerald-600 to-blue-600 text-white p-6 pb-8">
            <!-- Background Pattern -->
            <div
              class="absolute inset-0 opacity-10 bg-[radial-gradient(circle_at_1px_1px,white_1px,transparent_0)]"
              style="background-size: 20px 20px"
            ></div>
            
            <div class="relative text-center">
              <div class="w-16 h-16 mx-auto mb-4 bg-white/20 backdrop-blur-sm rounded-2xl flex items-center justify-center">
                <UIcon name="i-heroicons-device-phone-mobile" class="w-8 h-8 text-white" />
              </div>
              <h3 class="text-xl font-bold mb-2">Get Our Mobile App!</h3>
              <p class="text-emerald-100 text-sm">Experience AdsyClub on the go with our mobile application</p>
            </div>
          </div>          <!-- Content -->
          <div class="p-6">
            <!-- Version Information (if available) -->
            <div v-if="appVersion || versionCode" class="mb-4 p-3 bg-gray-50 dark:bg-gray-800 rounded-lg">
              <div class="flex items-center justify-between text-sm">
                <span class="text-gray-600 dark:text-gray-400">Latest Version:</span>
                <div class="flex items-center space-x-2">
                  <span v-if="appVersion" class="font-semibold text-emerald-600 dark:text-emerald-400">v{{ appVersion }}</span>
                  <span v-if="versionCode" class="px-2 py-1 bg-emerald-100 dark:bg-emerald-900/30 text-emerald-700 dark:text-emerald-300 rounded text-xs">
                    Build {{ versionCode }}
                  </span>
                </div>
              </div>
            </div>
            
            <div class="space-y-4 mb-6">
              <div class="flex items-center space-x-3">
                <div class="w-8 h-8 bg-emerald-100 dark:bg-emerald-900/30 rounded-full flex items-center justify-center">
                  <UIcon name="i-heroicons-lightning-bolt" class="w-4 h-4 text-emerald-600 dark:text-emerald-400" />
                </div>
                <span class="text-gray-700 dark:text-gray-300 text-sm">Lightning fast performance</span>
              </div>
              
              <div class="flex items-center space-x-3">
                <div class="w-8 h-8 bg-blue-100 dark:bg-blue-900/30 rounded-full flex items-center justify-center">
                  <UIcon name="i-heroicons-bell" class="w-4 h-4 text-blue-600 dark:text-blue-400" />
                </div>
                <span class="text-gray-700 dark:text-gray-300 text-sm">Push notifications for deals</span>
              </div>
              
              <div class="flex items-center space-x-3">
                <div class="w-8 h-8 bg-purple-100 dark:bg-purple-900/30 rounded-full flex items-center justify-center">
                  <UIcon name="i-heroicons-wifi" class="w-4 h-4 text-purple-600 dark:text-purple-400" />
                </div>
                <span class="text-gray-700 dark:text-gray-300 text-sm">Works offline for saved content</span>
              </div>
            </div>            
            <!-- Action Buttons -->
            <div class="space-y-3">              <UButton
                @click="downloadMobileApp"
                color="emerald"
                variant="solid"
                class="w-full py-3 font-semibold shadow-lg hover:shadow-xl transition-all group"
                size="lg"
              >                <UIcon name="i-heroicons-arrow-down-tray" class="w-5 h-5 mr-2 group-hover:animate-bounce" />
                Download APK {{ appVersion ? `v${appVersion}` : '' }}{{ versionCode ? ` (${versionCode})` : '' }}{{ fileSize ? ` - ${fileSize}` : '' }}
              </UButton>
              
              <div class="flex gap-2">
                <UButton
                  @click="remindMeLater"
                  color="gray"
                  variant="ghost"
                  class="flex-1 py-2"
                  size="sm"
                >
                  Remind me later
                </UButton>
                
                <UButton
                  @click="dontShowAgain"
                  color="gray"
                  variant="ghost"
                  class="flex-1 py-2"
                  size="sm"
                >
                  Don't show again
                </UButton>
              </div>
            </div>

            <!-- Privacy Note -->
            <p class="text-xs text-gray-500 dark:text-gray-400 text-center mt-4">
              Safe download from our official servers. Your privacy is protected.
            </p>
          </div>
        </div>
      </div>
    </Teleport>

    <div v-if="loader" class="fixed inset-0 z-[99999999] bg-white">
      <NuxtLoadingIndicator class="!opacity-[1]" />
      <section class="h-screen w-screen flex items-center justify-center">
        <CommonPreloader />
      </section>
    </div>
  </div>
</template>

<script setup>
const { jwtLogin, user, getValidToken } = useAuth();
const toast = useToast();

const loader = ref(true);
const showMobileAppPopup = ref(false);
const appSize = ref(''); // Will be populated from API

// Cookie utility functions
const setCookie = (name, value, hours = 24) => {
  if (!process.client) return;
  const expires = new Date();
  expires.setTime(expires.getTime() + (hours * 60 * 60 * 1000));
  document.cookie = `${name}=${value}; expires=${expires.toUTCString()}; path=/; SameSite=Lax`;
};

const getCookie = (name) => {
  if (!process.client) return null;
  const nameEQ = name + "=";
  const ca = document.cookie.split(';');
  for (let i = 0; i < ca.length; i++) {
    let c = ca[i];
    while (c.charAt(0) === ' ') c = c.substring(1, c.length);
    if (c.indexOf(nameEQ) === 0) return c.substring(nameEQ.length, c.length);
  }
  return null;
};

// Check if mobile app is already installed
const isMobileAppInstalled = () => {
  if (!process.client) return false;
  
  // Check if PWA is installed (standalone mode)
  if (window.matchMedia('(display-mode: standalone)').matches) {
    return true;
  }
  
  // Check for iOS standalone mode
  if (window.navigator.standalone === true) {
    return true;
  }
  
  // Check for Android app webview
  if (document.referrer.includes('android-app://')) {
    return true;
  }
  
  // Check user agent for mobile app indicators
  const userAgent = navigator.userAgent || '';
  
  // Check for common webview indicators
  if (userAgent.includes('AdsyClub') || 
      userAgent.includes('wv') || 
      userAgent.includes('Version') && userAgent.includes('Mobile')) {
    return true;
  }
  
  // Check for specific webview patterns
  if (userAgent.match(/\bwv\b/) || 
      userAgent.match(/Android.*Mobile.*Chrome\/\d+\.\d+\.\d+\.\d+/) ||
      userAgent.includes('FB_IAB') || 
      userAgent.includes('FBAN') ||
      userAgent.includes('Instagram')) {
    return true;
  }
  
  // Check window properties that indicate app context
  if (typeof window !== 'undefined') {
    // Check for Android app bridge
    if (window.Android || window.AndroidInterface) {
      return true;
    }
    
    // Check for iOS app bridge  
    if (window.webkit && window.webkit.messageHandlers) {
      return true;
    }
  }
    // Check if user has previously installed and dismissed permanently (check both localStorage and cookies)
  if (localStorage.getItem('mobileAppInstalled') === 'true' || 
      getCookie('mobileAppInstalled') === 'true') {
    return true;
  }
  
  return false;
};

// Check if user should see the mobile app popup
const shouldShowMobileAppPopup = () => {
  // Only show for non-logged-in users
  if (user.value) {
    return false;
  }
  
  // Don't show if mobile app is already installed
  if (isMobileAppInstalled()) {
    return false;
  }
  
  // Don't show if user has permanently dismissed (check both localStorage and cookies)
  if (localStorage.getItem('mobileAppPopupPermanentlyDismissed') === 'true' || 
      getCookie('mobileAppDismissed') === 'permanently') {
    return false;
  }
  
  // Check if popup was shown in the last 24 hours using cookies
  const lastShownCookie = getCookie('mobileAppPopupLastShown');
  if (lastShownCookie) {
    const lastShownTime = parseInt(lastShownCookie);
    const now = new Date().getTime();
    const hoursDiff = Math.floor((now - lastShownTime) / (1000 * 60 * 60));
    
    // Show only if 24 hours have passed
    if (hoursDiff < 24) {
      return false;
    }
  }
  
  // Show popup if conditions are met
  return true;
};

// Use the app download composable
import { useAppDownload } from '~/composables/useAppDownload';
const { downloadApp, fileSize, appVersion, versionCode, fetchDownloadUrl } = useAppDownload();

// Download mobile app function
const downloadMobileApp = async () => {
  try {
    console.log('Starting APK download...');
    
    // Use the composable to get the dynamic download URL from admin
    const success = await downloadApp();
    
    if (success) {
      console.log('Opened dynamic download link in new tab');
      
      // Mark app as downloaded/installed to prevent future popups (use both cookies and localStorage)
      localStorage.setItem('mobileAppInstalled', 'true');
      setCookie('mobileAppInstalled', 'true', 24 * 365); // Set for 1 year
    } else {
      throw new Error('No download URL available from admin panel');
    }
    
    // Show success toast
    toast.add({
      title: 'Download Started',
      description: 'AdsyClub mobile app is downloading...',
      color: 'green',
      icon: 'i-heroicons-check-circle'
    });
    
    // Close popup and update last shown time
    closeMobileAppPopup();
    
  } catch (error) {
    console.error('Download error:', error);
    
    // More specific error handling
    let errorMessage = 'Failed to start download. Please try again.';
    if (error.message && error.message.includes('not found')) {
      errorMessage = 'APK file not found. Please contact support.';
    } else if (error.message && error.message.includes('network')) {
      errorMessage = 'Network error. Please check your connection.';
    }
    
    toast.add({
      title: 'Download Error',
      description: errorMessage,
      color: 'red',
      icon: 'i-heroicons-exclamation-triangle'
    });
  }
};

// Remind me later function
const remindMeLater = () => {
  // Set reminder for 24 hours using cookies
  const now = new Date().getTime();
  setCookie('mobileAppPopupLastShown', now.toString(), 24);
  
  showMobileAppPopup.value = false;
  
  toast.add({
    title: 'Reminder Set',
    description: 'We\'ll remind you about our mobile app in 24 hours',
    color: 'blue',
    icon: 'i-heroicons-clock'
  });
};

// Don't show again function
const dontShowAgain = () => {
  // Mark as permanently dismissed (use both cookies and localStorage for redundancy)
  localStorage.setItem('mobileAppPopupPermanentlyDismissed', 'true');
  setCookie('mobileAppDismissed', 'permanently', 24 * 365); // Set for 1 year
  
  showMobileAppPopup.value = false;
  
  toast.add({
    title: 'Notification Disabled',
    description: 'You won\'t see this popup again',
    color: 'gray',
    icon: 'i-heroicons-eye-slash'
  });
};

// Close popup function
const closeMobileAppPopup = () => {
  showMobileAppPopup.value = false;
  // Update last shown time using cookies (24 hours)
  const now = new Date().getTime();
  setCookie('mobileAppPopupLastShown', now.toString(), 24);
};

// Initialize popup logic
const initializeMobileAppPopup = () => {
  // Wait a bit after page load to show popup
  setTimeout(() => {
    if (shouldShowMobileAppPopup()) {
      showMobileAppPopup.value = true;
    }
  }, 2000); // Show after 2 seconds
};

// Enhanced authentication initialization for default layout
const initializeAuth = async () => {
  try {
    // For default layout, try to authenticate but don't force login
    const jwt = useCookie("adsyclub-jwt");
    const refreshToken = useCookie("adsyclub-refresh");
    
    if (jwt.value || refreshToken.value) {
      // If we have tokens, try to validate/refresh them
      const validToken = await getValidToken();
      if (validToken) {
        await jwtLogin();
      }
    }
    // If no tokens or validation fails, that's ok for default layout
  } catch (error) {
    console.warn("Auth initialization error in default layout:", error);
    // Don't redirect on error in default layout
  }
};

// Initialize authentication
initializeAuth();

onMounted(async () => {
  // Fetch app details early
  await fetchDownloadUrl();
  
  setTimeout(() => {
    loader.value = false;
    // Initialize mobile app popup after loader is done
    initializeMobileAppPopup();
  }, 1000);
});

useHead({
  title:
    "AdsyClub – Bangladesh's 1st Social Business Network: Earn Money, Connect with Society & Find the Services You Need!",
});
</script>
