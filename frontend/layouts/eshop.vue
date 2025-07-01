<template>
  <div class="font-AnekBangla layout-default">
    <div id="header-container" class="relative">
      <PublicHeader class="hidden sm:block" />
      <PublicEshopHeader class="sm:hidden block" />
      <!-- Header spacer - maintains space when header becomes fixed -->
      <div id="header-spacer" class="header-spacer" ref="headerSpacer"></div>
    </div>
    <main id="main-content">
      <slot />
    </main>
    <PublicFooter />
    <UNotifications />

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
const router = useRouter();
const route = useRoute();

const loader = ref(true);
const showMobileAppPopup = ref(false);
const appSize = ref(""); // Will be populated from API

// Header spacing management
const headerSpacer = ref(null);
const isHeaderFixed = ref(false);

// Handle header fixed positioning compensation
const handleHeaderSpacing = () => {
  const headerContainer = document.querySelector("#header-container");
  const header = headerContainer?.querySelector(".py-3");
  if (!header || !headerSpacer.value) {
    return;
  }

  const scrollY = window.scrollY;
  const isFixed = scrollY > 80;

  if (isFixed !== isHeaderFixed.value) {
    isHeaderFixed.value = isFixed;

    if (isFixed) {
      // When header becomes fixed, set spacer height to maintain space
      const headerHeight = header.offsetHeight;

      headerSpacer.value.style.height = `${headerHeight}px`;
      headerSpacer.value.style.display = "block";
    } else {
      // When header returns to sticky, remove spacer

      headerSpacer.value.style.height = "0px";
      headerSpacer.value.style.display = "none";
    }
  }
};

// Cookie utility functions
const setCookie = (name, value, hours = 24) => {
  if (!process.client) return;
  const expires = new Date();
  expires.setTime(expires.getTime() + hours * 60 * 60 * 1000);
  document.cookie = `${name}=${value}; expires=${expires.toUTCString()}; path=/; SameSite=Lax`;
};

const getCookie = (name) => {
  if (!process.client) return null;
  const nameEQ = name + "=";
  const ca = document.cookie.split(";");
  for (let i = 0; i < ca.length; i++) {
    let c = ca[i];
    while (c.charAt(0) === " ") c = c.substring(1, c.length);
    if (c.indexOf(nameEQ) === 0) return c.substring(nameEQ.length, c.length);
  }
  return null;
};

// Check if mobile app is already installed
const isMobileAppInstalled = () => {
  if (!process.client) return false;

  // Check if PWA is installed (standalone mode)
  if (window.matchMedia("(display-mode: standalone)").matches) {
    return true;
  }

  // Check for iOS standalone mode
  if (window.navigator.standalone === true) {
    return true;
  }

  // Check for Android app webview
  if (document.referrer.includes("android-app://")) {
    return true;
  }

  // Check user agent for mobile app indicators
  const userAgent = navigator.userAgent || "";

  // Check for common webview indicators
  if (
    userAgent.includes("AdsyClub") ||
    userAgent.includes("wv") ||
    (userAgent.includes("Version") && userAgent.includes("Mobile"))
  ) {
    return true;
  }

  // Check for specific webview patterns
  if (
    userAgent.match(/\bwv\b/) ||
    userAgent.match(/Android.*Mobile.*Chrome\/\d+\.\d+\.\d+\.\d+/) ||
    userAgent.includes("FB_IAB") ||
    userAgent.includes("FBAN") ||
    userAgent.includes("Instagram")
  ) {
    return true;
  }

  // Check window properties that indicate app context
  if (typeof window !== "undefined") {
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
  if (
    localStorage.getItem("mobileAppInstalled") === "true" ||
    getCookie("mobileAppInstalled") === "true"
  ) {
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
  if (
    localStorage.getItem("mobileAppPopupPermanentlyDismissed") === "true" ||
    getCookie("mobileAppDismissed") === "permanently"
  ) {
    return false;
  }

  // Check if popup was shown in the last 24 hours using cookies
  const lastShownCookie = getCookie("mobileAppPopupLastShown");
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
import { useAppDownload } from "~/composables/useAppDownload";
const { downloadApp, fileSize, appVersion, versionCode, fetchDownloadUrl } =
  useAppDownload();

// Download mobile app function
const downloadMobileApp = async () => {
  try {
    // Use the composable to get the dynamic download URL from admin
    const success = await downloadApp();

    if (success) {
      // Mark app as downloaded/installed to prevent future popups (use both cookies and localStorage)
      localStorage.setItem("mobileAppInstalled", "true");
      setCookie("mobileAppInstalled", "true", 24 * 365); // Set for 1 year
    } else {
      throw new Error("No download URL available from admin panel");
    }

    // Show success toast
    toast.add({
      title: "Download Started",
      description: "AdsyClub mobile app is downloading...",
      color: "green",
      icon: "i-heroicons-check-circle",
    });

    // Close popup and update last shown time
    closeMobileAppPopup();
  } catch (error) {
    console.error("Download error:", error);

    // More specific error handling
    let errorMessage = "Failed to start download. Please try again.";
    if (error.message && error.message.includes("not found")) {
      errorMessage = "APK file not found. Please contact support.";
    } else if (error.message && error.message.includes("network")) {
      errorMessage = "Network error. Please check your connection.";
    }

    toast.add({
      title: "Download Error",
      description: errorMessage,
      color: "red",
      icon: "i-heroicons-exclamation-triangle",
    });
  }
};

// Remind me later function
const remindMeLater = () => {
  // Set reminder for 24 hours using cookies
  const now = new Date().getTime();
  setCookie("mobileAppPopupLastShown", now.toString(), 24);

  showMobileAppPopup.value = false;

  toast.add({
    title: "Reminder Set",
    description: "We'll remind you about our mobile app in 24 hours",
    color: "blue",
    icon: "i-heroicons-clock",
  });
};

// Don't show again function
const dontShowAgain = () => {
  // Mark as permanently dismissed (use both cookies and localStorage for redundancy)
  localStorage.setItem("mobileAppPopupPermanentlyDismissed", "true");
  setCookie("mobileAppDismissed", "permanently", 24 * 365); // Set for 1 year

  showMobileAppPopup.value = false;

  toast.add({
    title: "Notification Disabled",
    description: "You won't see this popup again",
    color: "gray",
    icon: "i-heroicons-eye-slash",
  });
};

// Close popup function
const closeMobileAppPopup = () => {
  showMobileAppPopup.value = false;
  // Update last shown time using cookies (24 hours)
  const now = new Date().getTime();
  setCookie("mobileAppPopupLastShown", now.toString(), 24);
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

  // Set up header spacing management with a small delay to ensure DOM is ready
  setTimeout(() => {
    window.addEventListener("scroll", handleHeaderSpacing);
    // Initialize the spacer state
    handleHeaderSpacing();
  }, 100);

  setTimeout(() => {
    loader.value = false;
    // Initialize mobile app popup after loader is done
    initializeMobileAppPopup();
  }, 1000);
});

onUnmounted(() => {
  window.removeEventListener("scroll", handleHeaderSpacing);
});

useHead({
  title:
    "AdsyClub – Bangladesh's 1st Social Business Network: Earn Money, Connect with Society & Find the Services You Need!",
});
</script>

<style scoped>
.header-spacer {
  height: 0px;
  display: none;
  transition: height 0.3s ease;
}

/* Ensure main content doesn't have extra margins that might cause spacing issues */
#main-content {
  margin-top: 0;
  padding-top: 0;
}

/* Make sure the header container maintains proper positioning */
#header-container {
  position: relative;
  z-index: 99999999;
}
</style>
