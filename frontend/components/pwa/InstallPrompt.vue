<template>
  <div>
    <Transition name="fade">
      <div
        v-if="showInstallPrompt"
        class="fixed bottom-24 sm:bottom-10 left-0 right-0 mx-auto w-[92%] max-w-md p-5 bg-white dark:bg-slate-800 rounded-xl shadow-sm border border-slate-200 dark:border-slate-700 z-[60] animate-bounce-gentle"
      >
        <div class="flex items-start gap-4">
          <!-- App Icon with pulse effect -->
          <div class="flex-shrink-0 relative">
            <div class="absolute inset-0 bg-primary-100 rounded-xl animate-pulse-slow opacity-70"></div>
            <img
              src="/static/frontend/favicon.png"
              alt="AdsyClub"
              class="w-14 h-14 rounded-xl relative z-10"
            />
          </div>

          <!-- Content -->
          <div class="flex-1 min-w-0">
            <h3 class="font-semibold text-gray-800 dark:text-white text-lg">
              {{ $t("add_to_home_screen") }}
            </h3>
            <p class="text-sm text-gray-500 dark:text-gray-400 mt-1">
              {{ $t("install_app_message") }}
            </p>
            
            <!-- Buttons -->
            <div class="flex gap-3 mt-4">
              <UButton
                size="md"
                color="primary"
                variant="solid"
                @click="installPWA"
                class="flex-1 relative overflow-hidden group"
              >
                <span class="relative z-10 flex items-center justify-center">
                  {{ $t("install") }}
                  <UIcon name="i-heroicons-arrow-down-tray" class="ml-1.5 group-hover:animate-bounce-once" />
                </span>
                <span class="absolute inset-0 bg-gradient-to-r from-primary-600/0 via-primary-400/30 to-primary-600/0 -translate-x-full group-hover:translate-x-full transition-all duration-700"></span>
              </UButton>
              <UButton
                size="md"
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
            class="flex-shrink-0 p-1.5 text-gray-500 hover:text-gray-800 dark:text-gray-500 dark:hover:text-gray-300 transition-transform hover:rotate-90 duration-300"
          >
            <UIcon name="i-heroicons-x-mark" class="w-5 h-5" />
          </button>
        </div>
      </div>
    </Transition>

    <!-- iOS Instructions Modal -->
    <UModal v-model="showIOSModal">
      <UCard :ui="{ divide: 'divide-y divide-gray-100 dark:divide-gray-800' }">
        <template #header>
          <div class="flex items-center gap-2">
            <UIcon name="i-heroicons-information-circle" class="text-primary w-5 h-5" />
            <h3 class="text-lg font-medium">{{ $t("add_to_home_screen") }}</h3>
          </div>
        </template>

        <div class="space-y-4 py-4">
          <p class="text-sm text-gray-500 dark:text-gray-400">
            {{ $t("ios_install_instructions") }}
          </p>
          
          <div class="flex flex-col items-center gap-3 mt-2">
            <div class="flex items-center gap-2 text-sm">
              <UIcon name="i-heroicons-arrow-up-tray" class="text-blue-500 w-5 h-5" />
              <span>{{ $t("tap_share_button") }}</span>
            </div>
            <img src="/frontend/images/pwa/ios-share.png" alt="iOS Share Button" class="h-12 rounded-md border border-gray-200" />
            
            <div class="flex items-center gap-2 text-sm mt-3">
              <UIcon name="i-heroicons-plus" class="text-blue-500 w-5 h-5" />
              <span>{{ $t("tap_add_to_home") }}</span>
            </div>
            <img src="/frontend/images/pwa/ios-add-home.png" alt="Add to Home Screen" class="h-12 rounded-md border border-gray-200" />
          </div>
        </div>

        <template #footer>
          <div class="flex justify-end">
            <UButton
              color="primary"
              variant="solid" 
              @click="showIOSModal = false"
            >
              {{ $t("got_it") }}
            </UButton>
          </div>
        </template>
      </UCard>
    </UModal>
  </div>
</template>

<script setup>
const { t } = useI18n();
const showInstallPrompt = ref(false);
const showIOSModal = ref(false);
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
      
      // Show prompt again after 3 days (reduced from 2 weeks for better engagement)
      const threeDaysInMs = 3 * 24 * 60 * 60 * 1000;
      
      if (currentTime - dismissedTime < threeDaysInMs) {
        return true; // Still in cooldown period
      }
    }
  }
  return false;
};

// Check if the app is already in standalone mode (installed)
const isInStandaloneMode = () => {
  if (!process.client) return false;
  return (window.matchMedia('(display-mode: standalone)').matches) || 
         (window.navigator.standalone) || 
         document.referrer.includes('android-app://');
};

// Register service worker
const registerServiceWorker = async () => {
  if (process.client && 'serviceWorker' in navigator) {
    try {
      // Check if service worker was previously registered
      const registrations = await navigator.serviceWorker.getRegistrations();
      if (registrations.length) {
        console.log('Service worker is already registered');
        return;
      }
      
      // Register service worker
      const registration = await navigator.serviceWorker.register('/service-worker.js', {
        scope: '/'
      });
      console.log('Service Worker registered with scope:', registration.scope);

      // Force update to ensure the latest version is active
      if (registration.active) {
        registration.update();
        console.log('Service Worker updated');
      }
    } catch (error) {
      console.error('Service Worker registration failed:', error);
    }
  }
};

// Event listener for the beforeinstallprompt event
const setupInstallPrompt = () => {
  if (process.client) {
    // Don't show prompt if already in standalone mode
    if (isInStandaloneMode()) {
      console.log('App is already in standalone mode');
      return;
    }
    
    window.addEventListener('beforeinstallprompt', (e) => {
      console.log('beforeinstallprompt event fired');
      // Prevent the default browser prompt
      e.preventDefault();
      // Store the event for later use
      deferredPrompt.value = e;
      
      // Don't show the prompt immediately, wait for good UX moment
      setTimeout(() => {
        if (!hasPromptedUser.value && !checkDismissalState()) {
          showInstallPrompt.value = true;
        }
      }, 3000); // Reduced to 3 seconds for better engagement
    });
    
    // Hide install prompt if app is already installed
    window.addEventListener('appinstalled', () => {
      console.log('PWA was installed');
      showInstallPrompt.value = false;
      deferredPrompt.value = null;
      hasPromptedUser.value = true;
      
      // Show confirmation toast
      const toast = useToast();
      toast.add({
        title: t('app_installed_successfully'),
        description: t('app_installed_success_message'),
        icon: 'i-heroicons-check-circle',
        timeout: 5000,
        color: 'green',
      });
    });
    
    // Check if it's iOS - show iOS-specific prompt after a delay
    const isIOS = /iPad|iPhone|iPod/.test(navigator.userAgent) && !window.MSStream;
    if (isIOS && !checkDismissalState()) {
      console.log('iOS device detected, showing delayed prompt');
      setTimeout(() => {
        showInstallPrompt.value = true;
      }, 3000);
    }
  }
};

// Install the PWA
const installPWA = async () => {
  console.log('Install PWA button clicked');
  const isIOS = /iPad|iPhone|iPod/.test(navigator.userAgent) && !window.MSStream;
  
  if (deferredPrompt.value) {
    try {
      console.log('Using stored beforeinstallprompt event');
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
  } else if (isIOS) {
    console.log('iOS device detected, showing iOS installation modal');
    // For iOS devices that don't support beforeinstallprompt
    showIOSModal.value = true;
    showInstallPrompt.value = false;
  } else {
    console.log('No installation method available for this browser/device');
    // Show a message for browsers that don't support Add to Home Screen
    const toast = useToast();
    toast.add({
      title: t('installation_not_supported'),
      description: t('installation_not_supported_message') || 'Your browser does not support automatic installation. Please add this website to your home screen manually.',
      icon: 'i-heroicons-information-circle',
      timeout: 5000,
      color: 'blue',
    });
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

// Debugging function to check PWA requirements
const checkPwaRequirements = () => {
  if (process.client) {
    // Check HTTPS
    const isSecure = window.location.protocol === 'https:' || window.location.hostname === 'localhost';
    console.log('Is secure context:', isSecure);
    
    // Check service worker support
    const swSupported = 'serviceWorker' in navigator;
    console.log('Service Worker supported:', swSupported);
    
    // Check manifest existence
    fetch('/manifest.json')
      .then(response => {
        console.log('Manifest exists:', response.ok);
        if (response.ok) return response.json();
      })
      .then(data => {
        console.log('Manifest content:', data);
      })
      .catch(err => {
        console.error('Error fetching manifest:', err);
      });
  }
};

onMounted(() => {
  // Only run on client-side
  if (process.client) {
    checkPwaRequirements();
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

@keyframes bounce-gentle {
  0%, 100% {
    transform: translateY(0);
  }
  50% {
    transform: translateY(-5px);
  }
}

.animate-bounce-gentle {
  animation: bounce-gentle 3s ease-in-out infinite;
}

@keyframes pulse-slow {
  0%, 100% {
    opacity: 0.7;
  }
  50% {
    opacity: 0.4;
  }
}

.animate-pulse-slow {
  animation: pulse-slow 2s infinite;
}

@keyframes bounce-once {
  0%, 20%, 50%, 80%, 100% {
    transform: translateY(0);
  }
  40% {
    transform: translateY(-5px);
  }
  60% {
    transform: translateY(-3px);
  }
}

.group-hover\:animate-bounce-once:hover {
  animation: bounce-once 1s;
}
</style>