<template>
  <div class="container mx-auto px-4 py-8">
    <div class="max-w-4xl mx-auto">
      <h1 class="text-3xl font-bold mb-8 text-center">Authentication System Test</h1>
      
      <!-- Authentication Status -->
      <div class="bg-white rounded-lg shadow-md p-6 mb-6">
        <h2 class="text-xl font-semibold mb-4">Authentication Status</h2>
        <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
          <div class="space-y-2">
            <div class="flex items-center">
              <span class="font-medium w-32">User Status:</span>
              <span :class="user ? 'text-green-600' : 'text-red-600'">
                {{ user ? 'Authenticated' : 'Not Authenticated' }}
              </span>
            </div>
            <div class="flex items-center">
              <span class="font-medium w-32">JWT Token:</span>
              <span :class="jwtCookie ? 'text-green-600' : 'text-red-600'">
                {{ jwtCookie ? 'Present' : 'Missing' }}
              </span>
            </div>
            <div class="flex items-center">
              <span class="font-medium w-32">Refresh Token:</span>
              <span :class="refreshCookie ? 'text-green-600' : 'text-red-600'">
                {{ refreshCookie ? 'Present' : 'Missing' }}
              </span>
            </div>
            <div class="flex items-center">
              <span class="font-medium w-32">Token Validity:</span>
              <span :class="tokenValid ? 'text-green-600' : 'text-orange-600'">
                {{ tokenStatus }}
              </span>
            </div>
          </div>
          
          <div class="space-y-2" v-if="user">
            <div class="flex items-center">
              <span class="font-medium w-32">Username:</span>
              <span>{{ user.user?.username || 'N/A' }}</span>
            </div>
            <div class="flex items-center">
              <span class="font-medium w-32">Email:</span>
              <span>{{ user.user?.email || 'N/A' }}</span>
            </div>
            <div class="flex items-center">
              <span class="font-medium w-32">User Type:</span>
              <span>{{ user.user?.user_type || 'N/A' }}</span>
            </div>
          </div>
        </div>
      </div>

      <!-- Token Information -->
      <div class="bg-white rounded-lg shadow-md p-6 mb-6" v-if="jwtCookie">
        <h2 class="text-xl font-semibold mb-4">Token Information</h2>
        <div class="space-y-3">
          <div>
            <span class="font-medium">Token Expiry:</span>
            <span class="ml-2" :class="tokenExpired ? 'text-red-600' : 'text-green-600'">
              {{ tokenExpiryDisplay }}
            </span>
          </div>
          <div>
            <span class="font-medium">Time Until Expiry:</span>
            <span class="ml-2" :class="timeUntilExpiry < 300 ? 'text-orange-600' : 'text-green-600'">
              {{ timeUntilExpiryDisplay }}
            </span>
          </div>
          <div class="mt-4">
            <button 
              @click="checkTokenValidity"
              class="bg-blue-500 hover:bg-blue-600 text-white px-4 py-2 rounded mr-2"
              :disabled="checking"
            >
              {{ checking ? 'Checking...' : 'Check Token Validity' }}
            </button>
            <button 
              @click="forceTokenRefresh"
              class="bg-green-500 hover:bg-green-600 text-white px-4 py-2 rounded"
              :disabled="refreshing"
            >
              {{ refreshing ? 'Refreshing...' : 'Force Token Refresh' }}
            </button>
          </div>
        </div>
      </div>

      <!-- API Test Section -->
      <div class="bg-white rounded-lg shadow-md p-6 mb-6">
        <h2 class="text-xl font-semibold mb-4">API Test</h2>
        <div class="space-y-4">
          <div class="flex gap-4 flex-wrap">
            <button 
              @click="testApiCall"
              class="bg-purple-500 hover:bg-purple-600 text-white px-4 py-2 rounded"
              :disabled="apiTesting"
            >
              {{ apiTesting ? 'Testing...' : 'Test Protected API Call' }}
            </button>
            <button 
              @click="testExpiredToken"
              class="bg-orange-500 hover:bg-orange-600 text-white px-4 py-2 rounded"
              :disabled="apiTesting"
            >
              Test with Expired Token
            </button>
          </div>
          
          <div v-if="apiResult" class="mt-4 p-4 rounded" :class="apiResult.success ? 'bg-green-100' : 'bg-red-100'">
            <h3 class="font-semibold">API Test Result:</h3>
            <pre class="mt-2 text-sm overflow-x-auto">{{ apiResult.message }}</pre>
            <div v-if="apiResult.data" class="mt-2">
              <span class="font-medium">Response:</span>
              <pre class="mt-1 text-xs overflow-x-auto bg-gray-100 p-2 rounded">{{ JSON.stringify(apiResult.data, null, 2) }}</pre>
            </div>
          </div>
        </div>
      </div>

      <!-- Test Results -->
      <div class="bg-white rounded-lg shadow-md p-6">
        <h2 class="text-xl font-semibold mb-4">Test Log</h2>
        <div class="max-h-64 overflow-y-auto space-y-2">
          <div 
            v-for="(log, index) in testLogs" 
            :key="index"
            class="text-sm p-2 rounded"
            :class="log.type === 'success' ? 'bg-green-100' : log.type === 'error' ? 'bg-red-100' : 'bg-blue-100'"
          >
            <span class="font-medium">{{ formatTime(log.timestamp) }}:</span>
            {{ log.message }}
          </div>
        </div>
        <button 
          @click="clearLogs"
          class="mt-4 bg-gray-500 hover:bg-gray-600 text-white px-4 py-2 rounded text-sm"
        >
          Clear Logs
        </button>
      </div>
    </div>
  </div>
</template>

<script setup>
definePageMeta({
  layout: 'dashboard',
  middleware: 'auth'
});

const { user, getValidToken, refreshTokens, jwtLogin } = useAuth();
const Api = useApi();

// Reactive state
const checking = ref(false);
const refreshing = ref(false);
const apiTesting = ref(false);
const tokenValid = ref(false);
const tokenStatus = ref('Unknown');
const tokenExpired = ref(false);
const tokenExpiryDisplay = ref('Unknown');
const timeUntilExpiry = ref(0);
const timeUntilExpiryDisplay = ref('Unknown');
const apiResult = ref(null);
const testLogs = ref([]);

// Get cookies
const jwtCookie = useCookie("adsyclub-jwt");
const refreshCookie = useCookie("adsyclub-refresh");

// Add log entry
const addLog = (message, type = 'info') => {
  testLogs.value.unshift({
    message,
    type,
    timestamp: new Date()
  });
  
  // Keep only last 50 logs
  if (testLogs.value.length > 50) {
    testLogs.value = testLogs.value.slice(0, 50);
  }
};

// Format time
const formatTime = (date) => {
  return date.toLocaleTimeString();
};

// Clear logs
const clearLogs = () => {
  testLogs.value = [];
};

// Decode JWT token
const decodeToken = (token) => {
  try {
    if (!token) return null;
    const parts = token.split('.');
    if (parts.length !== 3) return null;
    return JSON.parse(atob(parts[1]));
  } catch (error) {
    return null;
  }
};

// Update token information
const updateTokenInfo = () => {
  if (!jwtCookie.value) {
    tokenValid.value = false;
    tokenStatus.value = 'No Token';
    tokenExpired.value = true;
    tokenExpiryDisplay.value = 'N/A';
    timeUntilExpiryDisplay.value = 'N/A';
    return;
  }

  const payload = decodeToken(jwtCookie.value);
  if (!payload) {
    tokenValid.value = false;
    tokenStatus.value = 'Invalid Token';
    tokenExpired.value = true;
    tokenExpiryDisplay.value = 'Invalid';
    timeUntilExpiryDisplay.value = 'Invalid';
    return;
  }

  const now = Math.floor(Date.now() / 1000);
  const exp = payload.exp;
  
  if (exp) {
    tokenExpired.value = now >= exp;
    tokenValid.value = !tokenExpired.value;
    tokenStatus.value = tokenExpired.value ? 'Expired' : 'Valid';
    
    const expiryDate = new Date(exp * 1000);
    tokenExpiryDisplay.value = expiryDate.toLocaleString();
    
    timeUntilExpiry.value = exp - now;
    if (timeUntilExpiry.value > 0) {
      const hours = Math.floor(timeUntilExpiry.value / 3600);
      const minutes = Math.floor((timeUntilExpiry.value % 3600) / 60);
      const seconds = timeUntilExpiry.value % 60;
      timeUntilExpiryDisplay.value = `${hours}h ${minutes}m ${seconds}s`;
    } else {
      timeUntilExpiryDisplay.value = 'Expired';
    }
  } else {
    tokenValid.value = false;
    tokenStatus.value = 'No Expiry Info';
    tokenExpiryDisplay.value = 'Unknown';
    timeUntilExpiryDisplay.value = 'Unknown';
  }
};

// Check token validity
const checkTokenValidity = async () => {
  checking.value = true;
  addLog('Checking token validity...', 'info');
  
  try {
    const validToken = await getValidToken();
    if (validToken) {
      addLog('Token is valid', 'success');
      tokenValid.value = true;
      tokenStatus.value = 'Valid';
    } else {
      addLog('Token is invalid or refresh failed', 'error');
      tokenValid.value = false;
      tokenStatus.value = 'Invalid';
    }
  } catch (error) {
    addLog(`Token validation error: ${error.message}`, 'error');
    tokenValid.value = false;
    tokenStatus.value = 'Error';
  } finally {
    checking.value = false;
    updateTokenInfo();
  }
};

// Force token refresh
const forceTokenRefresh = async () => {
  refreshing.value = true;
  addLog('Forcing token refresh...', 'info');
  
  try {
    const success = await refreshTokens();
    if (success) {
      addLog('Token refreshed successfully', 'success');
    } else {
      addLog('Token refresh failed', 'error');
    }
  } catch (error) {
    addLog(`Token refresh error: ${error.message}`, 'error');
  } finally {
    refreshing.value = false;
    updateTokenInfo();
  }
};

// Test API call
const testApiCall = async () => {
  apiTesting.value = true;
  apiResult.value = null;
  addLog('Testing protected API call...', 'info');
  
  try {
    const result = await Api.get('/auth/validate-token/');
    
    if (result.error) {
      apiResult.value = {
        success: false,
        message: `API call failed: ${JSON.stringify(result.error)}`,
        data: result.error
      };
      addLog('API call failed', 'error');
    } else {
      apiResult.value = {
        success: true,
        message: 'API call successful',
        data: result.data
      };
      addLog('API call successful', 'success');
    }
  } catch (error) {
    apiResult.value = {
      success: false,
      message: `API call exception: ${error.message}`,
      data: null
    };
    addLog(`API call exception: ${error.message}`, 'error');
  } finally {
    apiTesting.value = false;
  }
};

// Test with expired token
const testExpiredToken = async () => {
  addLog('Testing with artificially expired token...', 'info');
  
  // Temporarily set an expired token
  const originalToken = jwtCookie.value;
  
  // Create an expired token (this is just for testing)
  jwtCookie.value = 'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJ0b2tlbl90eXBlIjoiYWNjZXNzIiwiZXhwIjoxNjAwMDAwMDAwLCJpYXQiOjE2MDAwMDAwMDAsImp0aSI6IjEyMzQ1NiIsInVzZXJfaWQiOjF9.test';
  
  await testApiCall();
  
  // Restore original token
  jwtCookie.value = originalToken;
  updateTokenInfo();
};

// Watch for token changes
watch([jwtCookie, refreshCookie], () => {
  updateTokenInfo();
}, { immediate: true });

// Update token info every second
onMounted(() => {
  updateTokenInfo();
  
  const interval = setInterval(() => {
    updateTokenInfo();
  }, 1000);
  
  onUnmounted(() => {
    clearInterval(interval);
  });
});

useHead({
  title: 'Authentication Test - AdsyClub'
});
</script>
