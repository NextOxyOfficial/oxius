<template>
  <div>
    <!-- Install Prompt Button - Only shows when installation is available -->
    <div
      v-if="showInstallBtn"
      class="fixed bottom-20 right-4 z-50"
      @click="installPWA"
    >
      <button
        class="flex items-center gap-2 bg-primary-500 text-white px-4 py-3 rounded-full shadow-lg hover:bg-primary-600 transition-all"
        aria-label="Install App"
      >
        <span class="hidden sm:inline">{{ $t("install_app") }}</span>
        <span class="text-xl">
          <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
            <path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"></path>
            <polyline points="7 10 12 15 17 10"></polyline>
            <line x1="12" y1="15" x2="12" y2="3"></line>
          </svg>
        </span>
      </button>
    </div>
    
    <!-- iOS Install Instructions Modal -->
    <UModal v-model="showIOSModal">
      <UCard>
        <template #header>
          <div class="flex items-center gap-2">
            <span class="text-lg font-medium">{{ $t("add_to_home") }}</span>
          </div>
        </template>

        <div class="p-4 space-y-4">
          <p>{{ $t("ios_install_guide") }}</p>
          
          <ol class="list-decimal pl-5 space-y-2">
            <li>{{ $t("tap_share_icon") }}</li>
            <li>{{ $t("scroll_and_tap") }} <strong>"{{ $t("add_to_home_screen") }}"</strong></li>
            <li>{{ $t("tap_add") }}</li>
          </ol>
          
          <div class="flex justify-center mt-4">
            <img src="/img/ios-guide.png" alt="iOS Installation Guide" class="max-w-[200px] border rounded-md" />
          </div>
        </div>

        <template #footer>
          <div class="flex justify-end">
            <UButton color="primary" @click="showIOSModal = false">
              {{ $t("got_it") }}
            </UButton>
          </div>
        </template>
      </UCard>
    </UModal>
  </div>
</template>

<script setup>
import { ref, onMounted, onUnmounted } from 'vue';

const showInstallBtn = ref(false);
const showIOSModal = ref(false);
let deferredPrompt = null;

// Function to handle install button click
const installPWA = async () => {
  // Check if it's iOS
  const isIOS = /iPad|iPhone|iPod/.test(navigator.userAgent) && !window.MSStream;
  
  if (isIOS) {
    // Show iOS-specific install instructions
    showIOSModal.value = true;
    return;
  }
  
  // For other browsers that support the install prompt
  if (deferredPrompt) {
    // Show the install prompt
    deferredPrompt.prompt();
    
    // Wait for the user to respond to the prompt
    const { outcome } = await deferredPrompt.userChoice;
    console.log(`User response to the install prompt: ${outcome}`);
    
    // Clear the saved prompt as it can't be used again
    deferredPrompt = null;
    
    // Hide the install button
    showInstallBtn.value = false;
  } else {
    console.log('No installation prompt available');
  }
};

// Function to check if the app is already installed
const isAppInstalled = () => {
  if (window.matchMedia('(display-mode: standalone)').matches) {
    return true;
  }
  
  // For iOS
  if (window.navigator.standalone === true) {
    return true;
  }
  
  return false;
};

// Event handler for beforeinstallprompt
const beforeInstallPromptHandler = (e) => {
  // Prevent Chrome 67 and earlier from automatically showing the prompt
  e.preventDefault();
  
  // Stash the event so it can be triggered later
  deferredPrompt = e;
  
  // Show the install button
  showInstallBtn.value = true;
};

// Event handler for appinstalled
const appInstalledHandler = (e) => {
  // Hide the install button
  showInstallBtn.value = false;
  console.log('PWA was installed');
};

onMounted(() => {
  // Don't show the install button if the app is already installed
  if (isAppInstalled()) {
    console.log('App is already installed');
    return;
  }
  
  // Listen for the beforeinstallprompt event
  window.addEventListener('beforeinstallprompt', beforeInstallPromptHandler);
  
  // Listen for the appinstalled event
  window.addEventListener('appinstalled', appInstalledHandler);
});

onUnmounted(() => {
  // Clean up event listeners
  window.removeEventListener('beforeinstallprompt', beforeInstallPromptHandler);
  window.removeEventListener('appinstalled', appInstalledHandler);
});
</script>