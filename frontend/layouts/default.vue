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
          </div>

          <!-- Content -->
          <div class="p-6">
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
            <div class="space-y-3">
              <UButton
                @click="downloadMobileApp"
                color="emerald"
                variant="solid"
                class="w-full py-3 font-semibold shadow-lg hover:shadow-xl transition-all group"
                size="lg"
              >
                <UIcon name="i-heroicons-arrow-down-tray" class="w-5 h-5 mr-2 group-hover:animate-bounce" />
                Download APK ({{ appSize }})
              </UButton>
              
              <UButton
                @click="remindMeLater"
                color="gray"
                variant="ghost"
                class="w-full py-2"
                size="sm"
              >
                Remind me later
              </UButton>
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
const { jwtLogin, user } = useAuth();
const toast = useToast();

const loader = ref(true);
const showMobileAppPopup = ref(false);
const appSize = ref('12.5 MB');

// Check if user should see the mobile app popup
const shouldShowMobileAppPopup = () => {
  // Only show for non-logged-in users
  if (user.value) {
    return false;
  }
  
  // Check if popup was shown in the last 7 days
  const lastShown = localStorage.getItem('mobileAppPopupLastShown');
  if (lastShown) {
    const lastShownDate = new Date(lastShown);
    const now = new Date();
    const daysDiff = Math.floor((now - lastShownDate) / (1000 * 60 * 60 * 24));
    
    // Show only if 7 days have passed
    return daysDiff >= 7;
  }
  
  // First time visitor - show popup
  return true;
};

// Download mobile app function
const downloadMobileApp = () => {
  try {
    // Create a download link for the APK file
    const link = document.createElement('a');
    link.href = '/AdsyClub V.1.apk';
    link.download = 'AdsyClub-V1.apk';
    link.target = '_blank';
    
    // Trigger download
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
    
    // Show success toast
    toast.add({
      title: 'Download Started',
      description: 'AdsyClub mobile app is downloading...',
      color: 'green',
      icon: 'i-heroicons-check-circle'
    });
    
    // Close popup and update last shown date
    closeMobileAppPopup();
    
  } catch (error) {
    console.error('Download error:', error);
    toast.add({
      title: 'Download Error',
      description: 'Failed to start download. Please try again.',
      color: 'red',
      icon: 'i-heroicons-exclamation-triangle'
    });
  }
};

// Remind me later function
const remindMeLater = () => {
  // Set reminder for 3 days instead of 7
  const reminderDate = new Date();
  reminderDate.setDate(reminderDate.getDate() + 3);
  localStorage.setItem('mobileAppPopupLastShown', reminderDate.toISOString());
  
  showMobileAppPopup.value = false;
  
  toast.add({
    title: 'Reminder Set',
    description: 'We\'ll remind you about our mobile app in 3 days',
    color: 'blue',
    icon: 'i-heroicons-clock'
  });
};

// Close popup function
const closeMobileAppPopup = () => {
  showMobileAppPopup.value = false;
  // Update last shown date to current date
  localStorage.setItem('mobileAppPopupLastShown', new Date().toISOString());
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

await jwtLogin();

onMounted(() => {
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
