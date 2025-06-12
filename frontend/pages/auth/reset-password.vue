<template>
  <div class=" bg-gradient-to-br from-gray-50 to-gray-100">
    <UContainer class="py-8 md:py-12">
      <div class="flex items-center justify-center">
        <div class="max-w-md w-full">
          <div class="bg-white rounded-2xl shadow-sm p-8">
            <!-- Header -->
            <div class="text-center mb-8">
              <div class="inline-flex items-center justify-center w-16 h-16 bg-blue-100 rounded-full mb-4">
                <UIcon name="i-heroicons-lock-closed" class="w-8 h-8 text-blue-600" />
              </div>
              <h1 class="text-2xl font-bold text-gray-900 mb-2">Reset Password</h1>
              <p class="text-gray-600">{{ getCurrentStepDescription() }}</p>
            </div>

        <!-- Progress Indicator -->
        <div class="flex items-center justify-center mb-8">
          <div class="flex items-center space-x-4">
            <div :class="[
              'w-8 h-8 rounded-full flex items-center justify-center text-sm font-medium',
              step >= 1 ? 'bg-blue-600 text-white' : 'bg-gray-200 text-gray-600'
            ]">
              1
            </div>
            <div :class="[
              'w-16 h-1',
              step >= 2 ? 'bg-blue-600' : 'bg-gray-200'
            ]"></div>
            <div :class="[
              'w-8 h-8 rounded-full flex items-center justify-center text-sm font-medium',
              step >= 2 ? 'bg-blue-600 text-white' : 'bg-gray-200 text-gray-600'
            ]">
              2
            </div>
            <div :class="[
              'w-16 h-1',
              step >= 3 ? 'bg-blue-600' : 'bg-gray-200'
            ]"></div>
            <div :class="[
              'w-8 h-8 rounded-full flex items-center justify-center text-sm font-medium',
              step >= 3 ? 'bg-blue-600 text-white' : 'bg-gray-200 text-gray-600'
            ]">
              3
            </div>
          </div>
        </div>

        <!-- Error Display -->
        <div v-if="error" class="mb-6 p-4 bg-red-50 border border-red-200 rounded-lg">
          <div class="flex items-center">
            <UIcon name="i-heroicons-exclamation-triangle" class="w-5 h-5 text-red-600 mr-3" />
            <p class="text-red-700">{{ error }}</p>
          </div>
        </div>

        <!-- Success Display -->
        <div v-if="success" class="mb-6 p-4 bg-green-50 border border-green-200 rounded-lg">
          <div class="flex items-center">
            <UIcon name="i-heroicons-check-circle" class="w-5 h-5 text-green-600 mr-3" />
            <p class="text-green-700">{{ success }}</p>
          </div>
        </div>

        <!-- Step 1: Method Selection & Contact Input -->
        <form v-if="step === 1" @submit.prevent="handleSendOtp" class="space-y-6">
          <div class="space-y-4">            <!-- Method Selection -->
            <div class="space-y-3">
              <label class="block text-sm font-medium text-gray-700">Reset method</label>
              <div class="grid grid-cols-1 gap-3">
                <button
                  type="button"
                  @click="form.method = 'phone'"
                  :class="[
                    'p-3 border-2 rounded-lg text-sm font-medium transition-all duration-200 flex items-center justify-center space-x-2',
                    form.method === 'phone'
                      ? 'border-blue-600 bg-blue-50 text-blue-700'
                      : 'border-gray-200 hover:border-gray-300 text-gray-700'
                  ]"
                >
                  <UIcon name="i-heroicons-phone" class="w-4 h-4" />
                  <span>Phone</span>
                </button>
                <!-- Email option temporarily hidden - code structure preserved for future SMTP implementation
                <button
                  type="button"
                  @click="form.method = 'email'"
                  :class="[
                    'p-3 border-2 rounded-lg text-sm font-medium transition-all duration-200 flex items-center justify-center space-x-2',
                    form.method === 'email'
                      ? 'border-blue-600 bg-blue-50 text-blue-700'
                      : 'border-gray-200 hover:border-gray-300 text-gray-700'
                  ]"
                >
                  <UIcon name="i-heroicons-envelope" class="w-4 h-4" />
                  <span>Email</span>
                </button>
                -->
              </div>
            </div>            <!-- Contact Input -->
            <div class="space-y-2">
              <label class="block text-sm font-medium text-gray-700">
                Phone Number
              </label>
              <div class="relative">
                <UIcon 
                  name="i-heroicons-phone" 
                  class="absolute left-3 top-1/2 transform -translate-y-1/2 w-5 h-5 text-gray-400" 
                />
                <input
                  type="tel"
                  v-model="form.value"
                  placeholder="01XXXXXXXXX"
                  class="w-full pl-11 pr-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500 transition-all"
                  required
                />
              </div>
            </div>
          </div>

          <button
            type="submit"
            :disabled="loading || !form.value"
            class="w-full py-3 px-4 bg-blue-600 text-white font-medium rounded-lg hover:bg-blue-700 focus:ring-2 focus:ring-blue-500 focus:ring-offset-2 disabled:opacity-50 disabled:cursor-not-allowed transition-all duration-200"
          >
            <div v-if="loading" class="flex items-center justify-center">
              <svg class="animate-spin -ml-1 mr-3 h-5 w-5 text-white" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
                <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
                <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
              </svg>
              Sending...
            </div>
            <span v-else>Send Reset Code</span>
          </button>
        </form>

        <!-- Step 2: OTP Verification -->
        <form v-else-if="step === 2" @submit.prevent="handleVerifyOtp" class="space-y-6">
          <div class="space-y-4">
            <div class="text-center">
              <p class="text-sm text-gray-600 mb-4">
                We sent a 6-digit code to 
                <span class="font-medium text-gray-900">{{ maskedContact }}</span>
              </p>
            </div>

            <div class="space-y-2">
              <label class="block text-sm font-medium text-gray-700">Verification Code</label>
              <input
                type="text"
                v-model="otpForm.otp"
                placeholder="000000"
                maxlength="6"
                class="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500 text-center text-lg font-mono tracking-widest transition-all"
                required
                @input="formatOtpInput"
              />
            </div>
          </div>

          <div class="space-y-4">
            <button
              type="submit"
              :disabled="loading || otpForm.otp.length !== 6"
              class="w-full py-3 px-4 bg-blue-600 text-white font-medium rounded-lg hover:bg-blue-700 focus:ring-2 focus:ring-blue-500 focus:ring-offset-2 disabled:opacity-50 disabled:cursor-not-allowed transition-all duration-200"
            >
              <div v-if="loading" class="flex items-center justify-center">
                <svg class="animate-spin -ml-1 mr-3 h-5 w-5 text-white" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
                  <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
                  <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
                </svg>
                Verifying...
              </div>
              <span v-else>Verify Code</span>
            </button>

            <button
              type="button"
              @click="handleResendOtp"
              :disabled="resendCooldown > 0"
              class="w-full py-2 px-4 text-blue-600 hover:text-blue-700 font-medium disabled:text-gray-400 transition-all"
            >
              {{ resendCooldown > 0 ? `Resend in ${resendCooldown}s` : 'Resend Code' }}
            </button>
          </div>
        </form>

        <!-- Step 3: New Password -->
        <form v-else-if="step === 3" @submit.prevent="handleResetPassword" class="space-y-6">
          <div class="space-y-4">
            <div class="space-y-2">
              <label class="block text-sm font-medium text-gray-700">New Password</label>
              <div class="relative">
                <UIcon name="i-heroicons-lock-closed" class="absolute left-3 top-1/2 transform -translate-y-1/2 w-5 h-5 text-gray-400" />
                <input
                  :type="showPassword ? 'text' : 'password'"
                  v-model="passwordForm.new_password"
                  placeholder="Enter new password"
                  class="w-full pl-11 pr-11 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500 transition-all"
                  required
                  minlength="8"
                />
                <button
                  type="button"
                  @click="showPassword = !showPassword"
                  class="absolute right-3 top-1/2 transform -translate-y-1/2 text-gray-400 hover:text-gray-600"
                >
                  <UIcon :name="showPassword ? 'i-heroicons-eye-slash' : 'i-heroicons-eye'" class="w-5 h-5" />
                </button>
              </div>
            </div>

            <div class="space-y-2">
              <label class="block text-sm font-medium text-gray-700">Confirm Password</label>
              <div class="relative">
                <UIcon name="i-heroicons-lock-closed" class="absolute left-3 top-1/2 transform -translate-y-1/2 w-5 h-5 text-gray-400" />
                <input
                  :type="showConfirmPassword ? 'text' : 'password'"
                  v-model="passwordForm.confirm_password"
                  placeholder="Confirm new password"
                  class="w-full pl-11 pr-11 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500 transition-all"
                  required
                  minlength="8"
                />
                <button
                  type="button"
                  @click="showConfirmPassword = !showConfirmPassword"
                  class="absolute right-3 top-1/2 transform -translate-y-1/2 text-gray-400 hover:text-gray-600"
                >
                  <UIcon :name="showConfirmPassword ? 'i-heroicons-eye-slash' : 'i-heroicons-eye'" class="w-5 h-5" />
                </button>
              </div>
            </div>

            <!-- Password Strength Indicator -->
            <div class="space-y-2">
              <div class="flex items-center space-x-2">
                <div class="flex-1 bg-gray-200 rounded-full h-2">
                  <div 
                    :class="[
                      'h-2 rounded-full transition-all duration-300',
                      passwordStrength === 'weak' ? 'bg-red-500 w-1/3' :
                      passwordStrength === 'medium' ? 'bg-yellow-500 w-2/3' :
                      passwordStrength === 'strong' ? 'bg-green-500 w-full' : 'w-0'
                    ]"
                  ></div>
                </div>
                <span 
                  :class="[
                    'text-xs font-medium',
                    passwordStrength === 'weak' ? 'text-red-600' :
                    passwordStrength === 'medium' ? 'text-yellow-600' :
                    passwordStrength === 'strong' ? 'text-green-600' : 'text-gray-400'
                  ]"
                >
                  {{ passwordStrength || 'Enter password' }}
                </span>
              </div>
              <ul class="text-xs text-gray-600 space-y-1">
                <li :class="{ 'text-green-600': passwordForm.new_password.length >= 8 }">
                  ✓ At least 8 characters
                </li>
                <li :class="{ 'text-green-600': /[A-Z]/.test(passwordForm.new_password) }">
                  ✓ One uppercase letter
                </li>
                <li :class="{ 'text-green-600': /[0-9]/.test(passwordForm.new_password) }">
                  ✓ One number
                </li>
              </ul>
            </div>
          </div>

          <button
            type="submit"
            :disabled="loading || !isPasswordValid"
            class="w-full py-3 px-4 bg-blue-600 text-white font-medium rounded-lg hover:bg-blue-700 focus:ring-2 focus:ring-blue-500 focus:ring-offset-2 disabled:opacity-50 disabled:cursor-not-allowed transition-all duration-200"
          >
            <div v-if="loading" class="flex items-center justify-center">
              <svg class="animate-spin -ml-1 mr-3 h-5 w-5 text-white" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
                <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
                <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
              </svg>
              Resetting...
            </div>
            <span v-else>Reset Password</span>
          </button>
        </form>

        <!-- Navigation -->
        <div class="mt-8 flex justify-between">
          <button
            v-if="step > 1"
            @click="goToPreviousStep"
            class="text-blue-600 hover:text-blue-700 font-medium transition-colors"
          >
            ← Go Back
          </button>
          <NuxtLink
            to="/auth/login"
            class="text-gray-600 hover:text-gray-800 font-medium transition-colors ml-auto"
          >
            Back to Login
          </NuxtLink>
        </div>
      </div>
    </div>
  </div>
  </UContainer>
</div>
</template>

<script setup>
const { post } = useApi();
const toast = useToast();

// Reactive state
const step = ref(1);
const loading = ref(false);
const error = ref('');
const success = ref('');
const maskedContact = ref('');
const resetToken = ref('');
const resendCooldown = ref(0);
const showPassword = ref(false);
const showConfirmPassword = ref(false);

// Form data
const form = ref({
  method: 'phone',
  value: '',
});

const otpForm = ref({
  otp: '',
});

const passwordForm = ref({
  new_password: '',
  confirm_password: '',
});

// Computed properties
const getCurrentStepDescription = () => {
  switch (step.value) {
    case 1:
      return 'Enter your phone number to receive a reset code';
    case 2:
      return 'Enter the verification code we sent you';
    case 3:
      return 'Create a new secure password';
    default:
      return '';
  }
};

const passwordStrength = computed(() => {
  const password = passwordForm.value.new_password;
  if (!password) return null;
  
  let score = 0;
  if (password.length >= 8) score++;
  if (/[A-Z]/.test(password)) score++;
  if (/[a-z]/.test(password)) score++;
  if (/[0-9]/.test(password)) score++;
  if (/[^A-Za-z0-9]/.test(password)) score++;
  
  if (score < 3) return 'weak';
  if (score < 5) return 'medium';
  return 'strong';
});

const isPasswordValid = computed(() => {
  const password = passwordForm.value.new_password;
  return password.length >= 8 &&
         password === passwordForm.value.confirm_password &&
         /[A-Z]/.test(password) &&
         /[0-9]/.test(password);
});

// Methods
const clearErrors = () => {
  error.value = '';
  success.value = '';
};

const formatOtpInput = (event) => {
  // Only allow numbers
  otpForm.value.otp = event.target.value.replace(/\D/g, '');
};

const validateContact = () => {
  const { method, value } = form.value;
  
  if (method === 'phone') {
    const phonePattern = /^(?:\+?88)?01[3-9]\d{8}$/;
    return phonePattern.test(value);
  } 
  // Email validation preserved for future SMTP implementation
  else if (method === 'email') {
    const emailPattern = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    return emailPattern.test(value);
  }
  
  return false;
};

const handleSendOtp = async () => {
  clearErrors();
    if (!validateContact()) {
    error.value = 'Please enter a valid phone number (e.g., 01XXXXXXXXX)';
    return;
  }
  
  loading.value = true;
    try {
    const payload = {
      method: form.value.method,
      [form.value.method]: form.value.value,
    };
    
    const response = await post('/send-otp/', payload);
    
    // Check if there's an error in the response
    if (response.error) {
      console.error('Send OTP API error:', response.error);
      
      // Handle different error response structures
      if (response.error.data?.error) {
        error.value = response.error.data.error;
      } else if (response.error.data?.message) {
        error.value = response.error.data.message;
      } else if (response.error.statusMessage) {
        error.value = response.error.statusMessage;
      } else if (typeof response.error === 'string') {
        error.value = response.error;
      } else {
        error.value = 'Failed to send verification code. Please try again.';
      }
      return;
    }
    
    if (response.data) {
      maskedContact.value = response.data.masked_phone || response.data.masked_email;
      success.value = response.data.message;
      step.value = 2;
      startResendCooldown();
    } else {
      error.value = 'Failed to send verification code. Please try again.';
    }
  } catch (err) {
    console.error('Send OTP error:', err);
    error.value = 'Failed to send verification code. Please check your connection and try again.';
  } finally {
    loading.value = false;
  }
};

const handleVerifyOtp = async () => {
  clearErrors();
  
  if (otpForm.value.otp.length !== 6) {
    error.value = 'Please enter a valid 6-digit code';
    return;
  }
  
  loading.value = true;
  try {
    const payload = {
      method: form.value.method,
      [form.value.method]: form.value.value,
      otp: otpForm.value.otp,
    };
      const response = await post('/verify-otp/', payload);
    
    if (response.error) {
      console.error('Verify OTP API error:', response.error);
      
      // Handle different error response structures
      if (response.error.data?.error) {
        error.value = response.error.data.error;
        
        // Check for reset required or attempt limits
        if (response.error.data.reset_required) {
          setTimeout(() => {
            step.value = 1;
            otpForm.value.otp = '';
          }, 3000);
        }
      } else if (response.error.data?.message) {
        error.value = response.error.data.message;
      } else if (response.error.statusMessage) {
        error.value = response.error.statusMessage;
      } else if (typeof response.error === 'string') {
        error.value = response.error;
      } else {
        error.value = 'Invalid verification code. Please try again.';
      }
      return;
    }
      if (response.data?.token) {
      resetToken.value = response.data.token;
      success.value = response.data.message;
      step.value = 3;
    } else {
      error.value = 'Invalid verification code. Please try again.';
    }
  } catch (err) {
    console.error('Verify OTP error:', err);
    error.value = 'Invalid verification code. Please check your connection and try again.';
  } finally {
    loading.value = false;
  }
};

const handleResetPassword = async () => {
  clearErrors();
    if (!isPasswordValid.value) {
    if (passwordForm.value.new_password.length < 8) {
      error.value = 'Password must be at least 8 characters long.';
    } else if (!/[A-Z]/.test(passwordForm.value.new_password)) {
      error.value = 'Password must contain at least one uppercase letter.';
    } else if (!/[0-9]/.test(passwordForm.value.new_password)) {
      error.value = 'Password must contain at least one number.';
    } else if (passwordForm.value.new_password !== passwordForm.value.confirm_password) {
      error.value = 'Passwords do not match.';
    } else {
      error.value = 'Please ensure your password meets all requirements and both passwords match.';
    }
    return;
  }
  
  loading.value = true;
  try {
    const payload = {
      token: resetToken.value,
      new_password: passwordForm.value.new_password,
    };
    
    console.log('Reset password payload:', payload);
    console.log('Token length:', resetToken.value?.length);
    console.log('Password length:', passwordForm.value.new_password?.length);
    
    const response = await post('/reset-password/', payload);
    
    console.log('Reset password response:', response);
      if (response.error) {
      console.error('Reset password API error:', response.error);
      
      // Handle different error response structures
      if (response.error.data?.error) {
        error.value = response.error.data.error;
      } else if (response.error.data?.message) {
        error.value = response.error.data.message;
      } else if (response.error.statusMessage) {
        error.value = response.error.statusMessage;
      } else if (typeof response.error === 'string') {
        error.value = response.error;
      } else {
        error.value = 'Failed to reset password. Please try again.';
      }
      return;
    }
      if (response.data?.message) {
      // Check if auto_login is enabled and tokens are provided
      if (response.data.auto_login && response.data.tokens) {
        // Get auth composable to handle login
        const { setTokens, setUser } = useAuth();
        
        // Set the tokens and user data
        await setTokens(response.data.tokens.access, response.data.tokens.refresh);
        if (response.data.user) {
          setUser(response.data.user);
        }
        
        toast.add({
          title: 'Success!',
          description: response.data.message,
          color: 'green',
        });
        
        // Redirect to dashboard after successful auto-login
        setTimeout(() => {
          navigateTo('/#home');
        }, 1500);
      } else {
        // Traditional success without auto-login
        toast.add({
          title: 'Success!',
          description: response.data.message,
          color: 'green',
        });
        
        // Redirect to login after a short delay
        setTimeout(() => {
          navigateTo('/auth/login');
        }, 2000);
      }
    } else {
      error.value = 'Failed to reset password. Please try again.';
    }  } catch (err) {
    console.error('Reset password error:', err);
    error.value = 'Failed to reset password. Please check your connection and try again.';
  } finally {
    loading.value = false;
  }
};

const handleResendOtp = async () => {
  if (resendCooldown.value > 0) return;
  
  otpForm.value.otp = '';
  await handleSendOtp();
};

const startResendCooldown = () => {
  resendCooldown.value = 60;
  const timer = setInterval(() => {
    resendCooldown.value--;
    if (resendCooldown.value <= 0) {
      clearInterval(timer);
    }
  }, 1000);
};

const goToPreviousStep = () => {
  clearErrors();
  
  if (step.value === 2) {
    step.value = 1;
    otpForm.value.otp = '';
  } else if (step.value === 3) {
    step.value = 2;
    passwordForm.value.new_password = '';
    passwordForm.value.confirm_password = '';
  }
};

// Set page meta - use default layout to show header and footer
definePageMeta({
  layout: 'default',
});

// Watch for password changes to clear errors
watch(() => passwordForm.value.new_password, () => {
  if (error.value.includes('password')) {
    error.value = '';
  }
});

watch(() => passwordForm.value.confirm_password, () => {
  if (error.value.includes('password')) {
    error.value = '';
  }
});
</script>
