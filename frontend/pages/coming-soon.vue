<template>
  <PublicSection>
    <UContainer>
      <div class="flex items-center justify-center min-h-[35vh]">
        <div class="text-center space-y-8 p-8">
          <!-- Heading -->
          <h1 class="text-2xl md:text-2xl font-semibold tracking-wide">
            Mobile Apps & Features
          </h1>          <!-- Subheading -->
          <p class="text-lg md:text-xl text-gray-600">
            <strong>Android App</strong> & <strong>Affiliate Program</strong> are now available! 
            <strong>iOS App</strong> is under development.
          </p>

          <!-- Icons for Android & iOS -->
          <div class="flex justify-center items-center space-x-8 mt-6">
            <!-- Android Icon - Clickable -->
            <div class="text-center">
              <button
                @click="downloadAndroidApp"
                class="group relative p-4 bg-green-50 hover:bg-green-100 rounded-2xl shadow-sm hover:shadow-md transition-all duration-300 transform hover:scale-105"
              >
                <img
                  src="https://cdn-icons-png.flaticon.com/512/888/888857.png"
                  alt="Download Android App"
                  class="h-16 w-16 group-hover:scale-110 transition-transform duration-300"
                />
                <!-- Download indicator -->
                <div class="absolute -top-2 -right-2 bg-green-500 text-white rounded-full p-1">
                  <UIcon name="i-heroicons-arrow-down-tray" class="w-4 h-4" />
                </div>
              </button>
              <p class="mt-2 text-sm font-medium text-green-600">Available Now</p>
              <p class="text-xs text-gray-500">APK Download</p>
            </div>

            <!-- iOS Icon - Coming Soon -->
            <div class="text-center">
              <div class="relative p-4 bg-gray-50 rounded-2xl shadow-sm opacity-60">
                <img
                  src="https://cdn-icons-png.flaticon.com/512/888/888841.png"
                  alt="iOS App Coming Soon"
                  class="h-16 w-16"
                />
                <!-- Coming soon badge -->
                <div class="absolute -top-2 -right-2 bg-gray-400 text-white rounded-full px-2 py-1">
                  <span class="text-xs font-medium">Soon</span>
                </div>
              </div>
              <p class="mt-2 text-sm font-medium text-gray-400">Coming Soon</p>
              <p class="text-xs text-gray-400">App Store</p>
            </div>
          </div>          <!-- Features section -->
          <div class="mt-8 max-w-2xl mx-auto">
            <h3 class="text-lg font-semibold mb-4">What's Available</h3>
            <div class="grid grid-cols-1 md:grid-cols-3 gap-4 text-sm">
              <div class="bg-green-50 p-4 rounded-lg">
                <UIcon name="i-heroicons-device-phone-mobile" class="w-6 h-6 text-green-600 mx-auto mb-2" />
                <p class="font-medium text-green-700">Android App</p>
                <p class="text-green-600">Ready to download</p>
              </div>
              <div class="bg-gray-50 p-4 rounded-lg">
                <UIcon name="i-heroicons-device-phone-mobile" class="w-6 h-6 text-gray-400 mx-auto mb-2" />
                <p class="font-medium text-gray-500">iOS App</p>
                <p class="text-gray-400">In development</p>
              </div>
              <div class="bg-green-50 p-4 rounded-lg">
                <UIcon name="i-heroicons-users" class="w-6 h-6 text-green-600 mx-auto mb-2" />
                <p class="font-medium text-green-700">Affiliate Program</p>
                <p class="text-green-600">Now available</p>
              </div>
            </div>
          </div>
        </div>
      </div>
    </UContainer>
  </PublicSection>
</template>

<script setup>
const toast = useToast();

// Download Android app function
const downloadAndroidApp = () => {
  try {
    console.log('Starting APK download from Google Drive...');
    
    // Direct Google Drive download link
    const apkUrl = 'https://drive.usercontent.google.com/download?id=1pqqxQbxXjkuWfBWeZLELTq8yno2Aq35o&export=download&authuser=0';
    
    // Open the download link in a new tab
    window.open(apkUrl, '_blank');
    
    console.log('Opened Google Drive download link in new tab');
    
    // Show success toast
    toast.add({
      title: 'Download Started',
      description: 'AdsyClub Android app is downloading...',
      color: 'green',
      icon: 'i-heroicons-check-circle'
    });
    
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
</script>

<style scoped></style>
