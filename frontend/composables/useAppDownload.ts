/**
 * Composable for handling Android app downloads
 * Gets the download link dynamically from Django admin
 */
import { ref, onMounted } from 'vue';

export function useAppDownload() {
  const runtimeConfig = useRuntimeConfig();
  const baseURL = runtimeConfig.public.baseURL;
  
  // State for download URL
  const downloadUrl = ref<string>('');
  const isLoading = ref(false);
  const error = ref<string | null>(null);    // Response type definition
  interface AppVersionResponse {
    download_url?: string;
    file_size_mb?: number;
    version_name?: string;
    version_code?: number;
    release_notes?: string;
  }
    // App version information
  const appVersion = ref<string>('');
  const versionCode = ref<number>(0);
  const fileSize = ref<string>('');
  const releaseNotes = ref<string>('');
  
  // Get the app version download URL from the API
  const fetchDownloadUrl = async () => {
    isLoading.value = true;
    error.value = null;
    
    try {
      // Call the API to get the app version details
      const response = await $fetch<AppVersionResponse>(`${baseURL}/api/android-app/latest/`, {
        method: 'GET',
        headers: {
          'Accept': 'application/json',
        }
      });
      
      // Set the app details from the API response
      if (response && response.download_url) {
        downloadUrl.value = response.download_url;
          // Set version and size information if available
        if (response.version_name) {
          appVersion.value = response.version_name;
        }
        
        if (response.version_code) {
          versionCode.value = response.version_code;
        }
        
        if (response.file_size_mb) {
          fileSize.value = `${response.file_size_mb} MB`;
        }
        
        if (response.release_notes) {
          releaseNotes.value = response.release_notes;
        }
        
        return response.download_url;
      } else {
        console.warn('No valid download URL returned from API');
        error.value = 'No download URL available';
        return '';
      }
    } catch (err) {
      console.error('Error fetching app download URL:', err);
      error.value = 'Failed to get download link';
      return '';
    } finally {
      isLoading.value = false;
    }
  };  // Download the Android app
  const downloadApp = async () => {
    console.log('Starting APK download...');
    
    try {
      // Get the latest download URL if we don't have it yet
      if (!downloadUrl.value) {
        await fetchDownloadUrl();
      }
      
      // Only open the link if we have a valid URL
      if (downloadUrl.value) {
        // Open the download link in a new tab
        window.open(downloadUrl.value, '_blank');
        console.log('Opened download link in new tab');
        return true;
      } else {
        console.error('No download URL available');
        return false;
      }
    } catch (err) {
      console.error('Error downloading app:', err);
      return false;
    }
  };
  
  // Initialize by fetching the URL when the composable is first used
  onMounted(() => {
    fetchDownloadUrl();
  });    return {
    downloadUrl,
    isLoading,
    error,
    appVersion,
    versionCode,
    fileSize,
    releaseNotes,
    downloadApp,
    fetchDownloadUrl
  };
}
