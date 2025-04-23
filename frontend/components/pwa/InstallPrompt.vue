<template>
  <div>
    <Transition name="fade">
      <div
        v-if="showInstallPrompt"
        class="fixed bottom-20 left-0 right-0 mx-auto w-[90%] max-w-md p-4 bg-white dark:bg-slate-800 rounded-xl shadow-xl border border-slate-200 dark:border-slate-700 z-50"
      >
        <div class="flex items-start gap-3">
          <!-- App Icon -->
          <div class="flex-shrink-0">
            <img
              src="/static/frontend/favicon.png"
              alt="AdsyClub"
              class="w-12 h-12 rounded-xl"
            />
          </div>

          <!-- Content -->
          <div class="flex-1 min-w-0">
            <h3 class="font-semibold text-gray-900 dark:text-white">
              {{ $t("add_to_home_screen") }}
            </h3>
            <p class="text-sm text-gray-600 dark:text-gray-300 mt-1">
              {{ $t("install_app_message") }}
            </p>
            
            <!-- Buttons -->
            <div class="flex gap-3 mt-3">
              <UButton
                size="sm"
                color="primary"
                variant="solid"
                @click="installPWA"
                class="flex-1"
              >
                {{ $t("install") }}
                <UIcon name="i-heroicons-arrow-down-tray" class="ml-1.5" />
              </UButton>
              <UButton
                size="sm"
                color="gray"
                variant="ghost"
                @click="dismissPrompt"
                class="flex-0"
              >
                {{ $t("not_now") }}
              </UButton>
            </div>
          </div>

          <!-- Close Button -->
          <button
            @click="dismissPrompt"
            class="flex-shrink-0 p-1 text-gray-500 hover:text-gray-700 dark:text-gray-400 dark:hover:text-gray-200"
          >
            <UIcon name="i-heroicons-x-mark" class="w-5 h-5" />
          </button>
        </div>
      </div>
    </Transition>
  </div>
</template>

<script setup>
const { t } = useI18n();
const showInstallPrompt = ref(false);
const deferredPrompt = ref(null);
const hasPromptedUser = ref(false);

// Check if PWA has been previously dismissed
// and respect a cooldown period before showing again
const checkDismissalState = () => {
  if (process.client) {
    const lastDismissed = localStorage.getItem('pwaPromptDismissed');
    if (lastDismissed) {
      const dismissedTime = parseInt(lastDismissed);
      const currentTime = new Date().getTime();
      
      // Show prompt again after 2 weeks (or your preferred timeframe)
      const twoWeeksInMs = 14 * 24 * 60 * 60 * 1000;
      
      if (currentTime - dismissedTime < twoWeeksInMs) {
        return true; // Still in cooldown period
      }
    }
  }
  return false;
};

// Register service worker
const registerServiceWorker = async () => {
  if ('serviceWorker' in navigator) {
    try {
      const registration = await navigator.serviceWorker.register('/service-worker.js');
      console.log('Service Worker registered with scope:', registration.scope);
    } catch (error) {
      console.error('Service Worker registration failed:', error);
    }
  }
};

// Event listener for the beforeinstallprompt event
const setupInstallPrompt = () => {
  if (process.client) {
    window.addEventListener('beforeinstallprompt', (e) => {
      // Prevent the default browser prompt
      e.preventDefault();
      // Store the event for later use
      deferredPrompt.value = e;
      
      // Don't show the prompt immediately, wait for good UX moment
      setTimeout(() => {
        if (!hasPromptedUser.value && !checkDismissalState()) {
          showInstallPrompt.value = true;
        }
      }, 5000); // Wait 5 seconds before showing prompt
    });
    
    // Hide install prompt if app is already installed
    window.addEventListener('appinstalled', () => {
      console.log('PWA was installed');
      showInstallPrompt.value = false;
      deferredPrompt.value = null;
      hasPromptedUser.value = true;
    });
  }
};

// Install the PWA
const installPWA = async () => {
  if (deferredPrompt.value) {
    try {
      // Show the browser install prompt
      deferredPrompt.value.prompt();
      // Wait for user to respond
      const choiceResult = await deferredPrompt.value.userChoice;
      
      if (choiceResult.outcome === 'accepted') {
        console.log('User accepted the install prompt');
        hasPromptedUser.value = true;
      } else {
        console.log('User dismissed the install prompt');
        dismissPrompt();
      }
    } catch (error) {
      console.error('Error during installation:', error);
    } finally {
      deferredPrompt.value = null;
      showInstallPrompt.value = false;
    }
  } else {
    // For iOS devices that don't support beforeinstallprompt
    showIOSInstallInstructions();
  }
};

// Dismiss the install prompt
const dismissPrompt = () => {
  showInstallPrompt.value = false;
  
  // Store dismissal timestamp
  if (process.client) {
    localStorage.setItem('pwaPromptDismissed', new Date().getTime().toString());
  }
};

// Special instructions for iOS devices
const showIOSInstallInstructions = () => {
  // Show a modal or toast with iOS installation instructions
  const isIOS = /iPad|iPhone|iPod/.test(navigator.userAgent) && !window.MSStream;
  
  if (isIOS) {
    // iOS-specific instructions using toast
    const toast = useToast();
    toast.add({
      title: t('add_to_home_screen'),
      description: t('ios_install_instructions'),
      icon: 'i-heroicons-information-circle',
      timeout: 8000,
      color: 'blue',
    });
  }
};

onMounted(() => {
  // Only run on client-side
  if (process.client) {
    registerServiceWorker();
    setupInstallPrompt();
    
    // For testing the UI without waiting for the actual event
    // Uncomment during development if needed
    // setTimeout(() => {
    //   showInstallPrompt.value = true;
    // }, 3000);
  }
});
</script>

<style scoped>
.fade-enter-active,
.fade-leave-active {
  transition: opacity 0.5s, transform 0.5s;
}

.fade-enter-from,
.fade-leave-to {
  opacity: 0;
  transform: translateY(20px);
}
</style>