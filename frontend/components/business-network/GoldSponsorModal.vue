<!-- Gold Sponsor Application Modal -->
<template>
  <transition
    enter-active-class="transition duration-300 ease-out"
    enter-from-class="transform scale-95 opacity-0"
    enter-to-class="transform scale-100 opacity-100"
    leave-active-class="transition duration-200 ease-in"
    leave-from-class="transform scale-100 opacity-100"
    leave-to-class="transform scale-95 opacity-0"
  >
    <div v-if="isOpen" class="fixed inset-0 z-[9999] overflow-y-auto" aria-labelledby="gold-sponsor-modal" role="dialog" aria-modal="true">
      <div class="flex items-end justify-center min-h-screen pt-20 pb-20 text-center sm:block sm:p-0">
        <!-- Background overlay -->
        <div class="fixed inset-0 bg-gray-500 bg-opacity-75 transition-opacity" aria-hidden="true" @click="close"></div>
          <!-- Modal panel -->
        <div class="inline-block align-bottom bg-white dark:bg-slate-800 rounded-lg text-left overflow-hidden shadow-xl transform transition-all sm:my-8 sm:align-middle sm:max-w-3xl sm:w-full">
          <div class="absolute top-0 right-0 pt-4 pr-4 z-50">
            <button type="button" @click="close" class="bg-white dark:bg-slate-700 rounded-full p-1 text-gray-400 hover:text-gray-500 dark:hover:text-gray-300 focus:outline-none shadow-md">
              <span class="sr-only">Close</span>
              <UIcon name="i-heroicons-x-mark" class="h-6 w-6" />
            </button>
          </div>
          
          <!-- Gold sponsor header -->
          <div class="relative h-24 bg-gradient-to-r from-amber-500 to-yellow-500 overflow-hidden">
            <div class="absolute inset-0 opacity-30">
              <div class="absolute inset-0 bg-amber-500 rotate-45 transform origin-top-left"></div>
              <div class="absolute bottom-0 right-0 w-20 h-20 rounded-full bg-yellow-300 -mb-10 -mr-10"></div>
              <div class="absolute top-5 right-10 text-4xl text-white opacity-50">✦</div>
            </div>
            <div class="absolute inset-0 flex items-center justify-center">
              <h2 class="text-2xl font-bold text-white">Become a Gold Sponsor</h2>
            </div>
          </div>
          
          <!-- Form content -->
          <div class="bg-white dark:bg-slate-800 px-4 pt-5 pb-6 sm:p-6">
            <p class="text-sm text-gray-600 dark:text-gray-300 mb-5">
              Join our exclusive Gold Sponsors and showcase your business to thousands of potential customers. Gold Sponsors receive premium visibility and additional benefits.
            </p>
            
            <form @submit.prevent="submitForm">
              <!-- Business Information -->
              <div class="space-y-4">
                <div>
                  <label for="businessName" class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">Business Name</label>
                  <input 
                    id="businessName" 
                    v-model="form.businessName" 
                    type="text" 
                    class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-md focus:outline-none focus:ring-2 focus:ring-amber-500 dark:bg-slate-700 dark:text-white"
                    placeholder="Your business name"
                    required
                  />
                </div>
                
                <div>
                  <label for="businessDescription" class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">Business Description</label>
                  <textarea 
                    id="businessDescription" 
                    v-model="form.businessDescription" 
                    class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-md focus:outline-none focus:ring-2 focus:ring-amber-500 dark:bg-slate-700 dark:text-white"
                    placeholder="Describe your business (max 200 characters)"
                    rows="3"
                    maxlength="200"
                    required
                  ></textarea>
                </div>
                
                <div>
                  <label for="contactEmail" class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">Contact Email</label>
                  <input 
                    id="contactEmail" 
                    v-model="form.contactEmail" 
                    type="email" 
                    class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-md focus:outline-none focus:ring-2 focus:ring-amber-500 dark:bg-slate-700 dark:text-white"
                    placeholder="email@example.com"
                    required
                  />
                </div>
                  <div>
                  <label for="phoneNumber" class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">Phone Number</label>
                  <input 
                    id="phoneNumber" 
                    v-model="form.phoneNumber" 
                    type="text" 
                    class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-md focus:outline-none focus:ring-2 focus:ring-amber-500 dark:bg-slate-700 dark:text-white"
                    placeholder="Enter your phone number"
                    required
                  />
                </div>                
                <div>
                  <label for="website" class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">Website URL</label>
                  <input 
                    id="website" 
                    v-model="form.website" 
                    type="text" 
                    class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-md focus:outline-none focus:ring-2 focus:ring-amber-500 dark:bg-slate-700 dark:text-white"
                    placeholder="example.com"
                  />
                </div>
                
                <div>
                  <label for="profileUrl" class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">Profile URL <span class="text-xs text-gray-500">(Users will be redirected here when clicking "Visit Sponsor's Profile")</span></label>
                  <input 
                    id="profileUrl" 
                    v-model="form.profileUrl" 
                    type="text" 
                    class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-md focus:outline-none focus:ring-2 focus:ring-amber-500 dark:bg-slate-700 dark:text-white"
                    placeholder="www.example.com"
                  />
                </div>
                
                <!-- Logo Upload -->
                <div>
                  <label for="logo" class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">Business Logo</label>
                  <div class="mt-1 flex items-center space-x-3">
                    <div class="relative h-16 w-16 rounded-md border border-gray-300 dark:border-gray-600 overflow-hidden bg-gray-100 dark:bg-gray-700">
                      <img v-if="logoPreview" :src="logoPreview" alt="Logo preview" class="h-full w-full object-cover" />
                      <div v-else class="h-full w-full flex items-center justify-center text-gray-400">
                        <UIcon name="i-heroicons-photo" class="h-8 w-8" />
                      </div>
                    </div>
                    <div class="flex flex-col">
                      <label 
                        for="logoFile" 
                        class="cursor-pointer px-3 py-1.5 text-xs bg-white dark:bg-slate-700 border border-gray-300 dark:border-gray-600 rounded-md hover:bg-gray-50 dark:hover:bg-slate-600 text-gray-700 dark:text-gray-300"
                      >
                        Choose File
                      </label>
                      <span class="text-xs text-gray-500 dark:text-gray-400 mt-1">
                        {{ logoFilename || 'No file chosen' }}
                      </span>
                    </div>
                    <input 
                      type="file" 
                      id="logoFile" 
                      ref="logoFileInput" 
                      @change="handleLogoUpload" 
                      accept="image/png,image/jpeg,image/jpg,image/svg+xml" 
                      class="hidden"
                    />
                  </div>
                  <p class="mt-1 text-xs text-gray-500 dark:text-gray-400">Recommended: 250x250px, PNG or JPG</p>
                </div>
                  <!-- Sponsorship package selection -->
                <div>
                  <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">Select Sponsorship Package</label>
                  
                  <!-- Loading packages -->
                  <div v-if="isLoadingPackages" class="space-y-2">
                    <div class="border rounded-lg p-3 animate-pulse">
                      <div class="h-4 bg-gray-200 rounded w-3/4 mb-2"></div>
                      <div class="h-3 bg-gray-200 rounded w-1/2"></div>
                    </div>
                  </div>
                    <!-- Package error -->
                  <div v-else-if="packageError" class="p-3 bg-amber-50 border border-amber-200 rounded-lg">
                    <p class="text-sm text-amber-700">{{ packageError }}</p>
                    <button @click="fetchPackages" class="mt-2 text-sm text-amber-700 underline">Try again</button>
                  </div>
                  
                  <!-- Package list -->
                  <div v-else class="space-y-2">
                    <div 
                      v-for="pkg in packages" 
                      :key="pkg.id"
                      class="relative border rounded-lg p-3 cursor-pointer transition-all"
                      :class="form.selectedPackage === pkg.id ? 'border-amber-500 bg-amber-50 dark:bg-amber-900/20' : 'border-gray-200 dark:border-gray-700'"
                      @click="form.selectedPackage = pkg.id"
                    >
                      <div class="flex justify-between items-center">
                        <div>
                          <span class="font-medium text-gray-800 dark:text-white">{{ pkg.name }}</span>
                          <p class="text-xs text-gray-500 dark:text-gray-400 mt-1">{{ pkg.description }}</p>
                        </div>
                        <div class="text-amber-600 dark:text-amber-400 font-bold">৳{{ pkg.price }}</div>
                      </div>
                      <div v-if="form.selectedPackage === pkg.id" class="absolute top-2 right-2 text-amber-500">
                        <div class="w-5 h-5 rounded-full bg-amber-500 flex items-center justify-center">
                          <span class="text-white text-xs">✓</span>
                        </div>
                      </div>
                    </div>
                  </div>
                </div>
              </div>                <!-- Error message - only show if there's an error and no success -->
              <div v-if="submitError && !submitSuccess" class="mt-4 p-3 bg-red-50 border border-red-200 rounded-lg">
                <p class="text-sm text-red-600">{{ submitError }}</p>
              </div>
              
              <!-- Success message -->
              <div v-if="submitSuccess" class="mt-4 p-3 bg-green-50 border border-green-200 rounded-lg">
                <p class="text-sm text-green-600">✓ Your Gold Sponsor application has been submitted successfully!</p>
              </div>
                <!-- Submit buttons -->
              <div class="mt-5">
                <button 
                  type="submit" 
                  class="w-full py-2 px-4 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-gradient-to-r from-amber-500 to-yellow-500 hover:from-amber-600 hover:to-yellow-600 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-amber-500 disabled:opacity-50 disabled:cursor-not-allowed"
                  :disabled="isSubmitting || isLoadingPackages"
                >
                  <span v-if="isSubmitting" class="flex items-center justify-center">
                    <svg class="animate-spin -ml-1 mr-3 h-4 w-4 text-white" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
                      <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
                      <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
                    </svg>
                    Submitting...
                  </span>
                  <span v-else>Submit Application</span>
                </button>
                  <!-- Alternative submission method if regular method fails and not already successful -->
                <div v-if="submitError && !submitSuccess" class="mt-3">
                  <button 
                    type="button" 
                    @click.prevent="submitFormDirectFetch"
                    class="w-full py-2 px-4 border border-amber-300 rounded-md shadow-sm text-sm font-medium text-amber-700 bg-amber-50 hover:bg-amber-100 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-amber-500 disabled:opacity-50 disabled:cursor-not-allowed"
                    :disabled="isSubmitting"
                  >
                    <span v-if="isSubmitting" class="flex items-center justify-center">
                      <svg class="animate-spin -ml-1 mr-3 h-4 w-4 text-amber-700" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
                        <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
                        <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
                      </svg>
                      Trying alternative method...
                    </span>
                    <span v-else>Try Alternative Submission Method</span>
                  </button>
                </div>
              </div>
            </form>
          </div>
        </div>
      </div>
    </div>
  </transition>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { useApi } from '~/composables/useApi'

const props = defineProps({
  isOpen: {
    type: Boolean,
    default: false
  }
});

// Import useApi composable
const { get, post } = useApi();

const emit = defineEmits(['close', 'submit']);

// Form data
const form = ref({
  businessName: '',
  businessDescription: '',
  contactEmail: '',
  phoneNumber: '',
  website: '',
  profileUrl: '',
  selectedPackage: 1,
  logo: null
});

// Logo handling
const logoFileInput = ref(null);
const logoPreview = ref(null);
const logoFilename = ref('');

// Function to handle logo upload
const handleLogoUpload = (event) => {
  const file = event.target.files[0];
  if (!file) return;
  
  logoFilename.value = file.name;
  form.value.logo = file;
  
  // Create preview URL
  const reader = new FileReader();
  reader.onload = (e) => {
    logoPreview.value = e.target.result;
  };
  reader.readAsDataURL(file);
};

// Sponsorship packages
const packages = ref([]);
const isLoadingPackages = ref(false);
const packageError = ref('');

// Form submission state
const isSubmitting = ref(false);
const submitError = ref('');
const submitSuccess = ref(false);

// Fetch packages from API
const fetchPackages = async () => {
  isLoadingPackages.value = true;
  packageError.value = '';
  
  try {
    console.log('Fetching sponsorship packages...');
    console.log('API endpoint URL (direct fetch):', '/api/bn/gold-sponsors/packages/');
    console.log('API endpoint URL (useApi):', '/bn/gold-sponsors/packages/');
    
    // Try direct fetch first as a more reliable option
    try {
      const directResponse = await $fetch('/api/bn/gold-sponsors/packages/', {
        method: 'GET',
        headers: {
          'Accept': 'application/json'
        }
      });
      
      console.log('Direct fetch response:', directResponse);
      if (Array.isArray(directResponse)) {
        packages.value = directResponse;
        console.log('Packages loaded successfully (direct):', packages.value.length);
        return;
      }
    } catch (directError) {
      console.error('Direct fetch failed, falling back to useApi:', directError);
    }
    
    // Fall back to useApi if direct fetch failed
    // Note: useApi already adds /api prefix, so we shouldn't include it in the path
    const result = await get('/bn/gold-sponsors/packages/');
    
    if (result.error) {
      console.error('API Error fetching packages:', result.error);
      throw new Error('Failed to fetch packages: ' + (result.error?.message || 'Unknown error'));
    } else if (result.data && Array.isArray(result.data)) {
      packages.value = result.data;
      console.log('Packages loaded successfully:', packages.value.length);
    } else {
      console.log('No packages data received');
      packageError.value = 'No sponsorship packages available.';
      packages.value = [];
    }
  } catch (error) {
    console.error('Error fetching packages:', error);    packageError.value = 'Using default package options. You can still submit your application.';
    console.log('Setting fallback packages');
    
    // Fallback to default packages
    packages.value = [
      {
        id: 1,
        name: '1 Month Gold Sponsor',
        description: 'Premium visibility for 1 month',
        price: 2999,
        duration_months: 1
      },
      {
        id: 2,
        name: '3 Months Gold Sponsor',
        description: 'Premium visibility for 3 months (10% discount)',
        price: 8099,
        duration_months: 3
      },
      {
        id: 3,
        name: '6 Months Gold Sponsor',
        description: 'Premium visibility for 6 months (15% discount)',
        price: 15299,
        duration_months: 6
      }
    ];
  } finally {
    isLoadingPackages.value = false;
  }
};

// Direct fetch fallback (in case useApi has issues)
const submitFormDirectFetch = async () => {
  try {
    isSubmitting.value = true;
    submitError.value = '';
    submitSuccess.value = false;
    
    // Create FormData for file upload
    const formData = new FormData();
    formData.append('business_name', form.value.businessName);
    formData.append('business_description', form.value.businessDescription);
    formData.append('contact_email', form.value.contactEmail);
    formData.append('phone_number', form.value.phoneNumber);
    
    if (form.value.website) {
      // Make sure website has http/https prefix
      const website = form.value.website.trim();
      formData.append('website', 
        website.startsWith('http://') || website.startsWith('https://') 
          ? website 
          : `https://${website}`
      );
    }
    
    if (form.value.profileUrl) {
      // Make sure profile URL has http/https prefix
      const profileUrl = form.value.profileUrl.trim();
      formData.append('profile_url', 
        profileUrl.startsWith('http://') || profileUrl.startsWith('https://') 
          ? profileUrl 
          : `https://${profileUrl}`
      );
    }
    
    // Ensure package_id is properly added as a number
    formData.append('package_id', parseInt(form.value.selectedPackage, 10));
    
    if (form.value.logo) {
      formData.append('logo', form.value.logo);
    }
    
    console.log('Using direct axios fetch as fallback');
    
    // Debug formData in direct fetch
    console.log('FormData entries for direct fetch:');
    for(let pair of formData.entries()) {
      console.log(pair[0] + ': ' + (pair[0] === 'logo' ? 'File object' : pair[1]));
    }
    
    // Try with post method from useApi first
    try {
      console.log('Trying with useApi post method');
      const apiResponse = await post('/bn/gold-sponsors/apply/', formData);
      
      if (apiResponse.error) {
        throw new Error(apiResponse.error.message || JSON.stringify(apiResponse.error));
      }
      
      console.log('useApi response:', apiResponse);
      const responseData = apiResponse.data;
      
      // Additional validation to ensure success
      if (!responseData) {
        throw new Error('No response data received');
      }
      
      // IMPORTANT: First clear any previous error to avoid displaying both error and success
      submitError.value = '';
      submitSuccess.value = true;
      
      emit('submit', responseData);
      
      // Reset form and close modal after success
      resetForm();
      setTimeout(() => {
        close();
      }, 2000);
      
      return;
    } catch (apiError) {
      console.error('useApi approach failed:', apiError);
      console.log('Falling back to raw fetch');
      
      // Fall back to direct fetch with credentials
      const response = await fetch('/api/bn/gold-sponsors/apply/', {
        method: 'POST',
        body: formData,
        credentials: 'include', // Include credentials like cookies
        headers: {
          'Accept': 'application/json'
        }
      });
      
      if (!response.ok) {
        const errorText = await response.text();
        console.error('Server error response:', response.status, errorText);
        
        // Check if we received HTML instead of JSON
        if (errorText.includes('<!DOCTYPE html>') || errorText.includes('<html')) {
          console.error('Received HTML response instead of JSON. This could be a server error or CSRF issue.');
          throw { 
            response: { 
              status: response.status,
              data: 'Server error - received HTML instead of JSON. Try refreshing the page.'
            },
            message: `Error ${response.status}: Server returned HTML instead of JSON`
          };
        }
        
        try {
          // Try to parse the error as JSON
          const errorData = JSON.parse(errorText);
          throw { 
            response: { 
              status: response.status,
              data: errorData 
            },
            message: `Error ${response.status}: ${JSON.stringify(errorData)}`
          };
        } catch (jsonError) {
          // If can't parse as JSON, use the raw text
          throw { 
            response: { 
              status: response.status,
              data: errorText 
            },
            message: `Error ${response.status}: ${errorText}`
          };
        }
      }
      
      let responseData;
      try {
        responseData = await response.json();
        console.log('Direct fetch parsed response:', responseData);
        
        // Validate the response to ensure it's actually successful
        if (responseData && responseData.error) {
          throw new Error(responseData.error);
        }
      } catch (parseError) {
        console.error('Error parsing response as JSON:', parseError);
        const rawText = await response.text();
        console.log('Raw response text:', rawText);
        throw new Error('Invalid JSON response from server');
      }
      
      console.log('Direct fetch response:', responseData);
      
      // IMPORTANT: First clear any previous error to avoid displaying both error and success
      submitError.value = '';
      submitSuccess.value = true;
      
      // Check for success message in the response
      if (responseData && responseData.message) {
        console.log('Success message from server:', responseData.message);
      }
      
      emit('submit', responseData);
      
      // Reset form and close modal after success
      resetForm();
      setTimeout(() => {
        close();
      }, 2000);
    }
  } catch (error) {
    console.error('Error in direct fetch submission:', error);
    console.log('Direct fetch error object:', {
      message: error.message,
      name: error.name,
      stack: error.stack,
      response: error.response,
      data: error.data
    });
    
    // More detailed error handling for direct fetch
    if (error.response?.data) {
      const errorData = error.response.data;
      console.log('Direct fetch error response data:', errorData);
      
      if (typeof errorData === 'object' && !Array.isArray(errorData)) {
        const errorMessages = [];
        
        Object.keys(errorData).forEach(key => {
          if (Array.isArray(errorData[key])) {
            errorData[key].forEach(message => {
              errorMessages.push(`${key}: ${message}`);
            });
          } else if (typeof errorData[key] === 'object') {
            errorMessages.push(`${key}: ${JSON.stringify(errorData[key])}`);
          } else {
            errorMessages.push(`${key}: ${errorData[key]}`);
          }
        });
        
        if (errorMessages.length > 0) {
          submitError.value = `Alternative method error: ${errorMessages.join(', ')}`;
        } else {
          submitError.value = `Alternative method error: ${JSON.stringify(errorData)}`;
        }
      } else if (typeof errorData === 'string') {
        submitError.value = `Alternative method error: ${errorData}`;
      } else {
        submitError.value = `Alternative method error: ${JSON.stringify(errorData)}`;
      }
    } else if (error.data) {
      // Some fetch libraries put the response data in error.data
      console.log('Direct fetch error data:', error.data);
      submitError.value = `Alternative method error: ${typeof error.data === 'string' ? error.data : JSON.stringify(error.data)}`;
    } else {
      submitError.value = `Alternative method error: ${error.message || 'Failed to submit application. Please try again.'}`;
    }
  } finally {
    isSubmitting.value = false;
  }
};

const resetForm = () => {
  form.value = {
    businessName: '',
    businessDescription: '',
    contactEmail: '',
    phoneNumber: '',
    website: '',
    profileUrl: '',
    selectedPackage: 1,
    logo: null
  };
  logoPreview.value = null;
  logoFilename.value = '';
  
  // Reset file input
  if (logoFileInput.value) {
    logoFileInput.value.value = '';
  }
};

// Initialize packages on component mount
onMounted(() => {
  fetchPackages();
});

// Close modal function
const close = () => {
  emit('close');
};

// Submit form function
const submitForm = async () => {
  isSubmitting.value = true;
  submitError.value = '';
  submitSuccess.value = false;
  
  // Debug information
  console.log('Form values before submission:', {
    businessName: form.value.businessName,
    businessDescription: form.value.businessDescription,
    contactEmail: form.value.contactEmail,
    phoneNumber: form.value.phoneNumber,
    website: form.value.website,
    profileUrl: form.value.profileUrl,
    selectedPackage: form.value.selectedPackage,
    hasLogo: !!form.value.logo
  });
  
  try {
    // Create FormData for file upload
    const formData = new FormData();
    formData.append('business_name', form.value.businessName);
    formData.append('business_description', form.value.businessDescription);
    formData.append('contact_email', form.value.contactEmail);
    formData.append('phone_number', form.value.phoneNumber);
    
    // Check if optional fields are empty and provide defaults
    if (form.value.website) {
      // Make sure website has http/https prefix
      const website = form.value.website.trim();
      formData.append('website', 
        website.startsWith('http://') || website.startsWith('https://') 
          ? website 
          : `https://${website}`
      );
    }
    
    if (form.value.profileUrl) {
      // Make sure profile URL has http/https prefix
      const profileUrl = form.value.profileUrl.trim();
      formData.append('profile_url', 
        profileUrl.startsWith('http://') || profileUrl.startsWith('https://') 
          ? profileUrl 
          : `https://${profileUrl}`
      );
    }
    
    // Ensure package_id is properly added as a number
    formData.append('package_id', parseInt(form.value.selectedPackage, 10));
    
    if (form.value.logo) {
      formData.append('logo', form.value.logo);
    }

    // First try CSRF-protected request with credentials
    console.log('Trying with fetch API and credentials');
    
    // Debug formData entries
    console.log('FormData entries:');
    for(let pair of formData.entries()) {
      console.log(pair[0] + ': ' + (pair[0] === 'logo' ? 'File object' : pair[1]));
    }
    
    let responseData;
    
    try {
      // Using fetch with credentials
      const response = await fetch('/api/bn/gold-sponsors/apply/', {
        method: 'POST',
        body: formData,
        credentials: 'include',
        headers: {
          'Accept': 'application/json'
        }
      });
      
      if (!response.ok) {
        const errorText = await response.text();
        console.error('Server error response:', response.status, errorText);
        
        // Check if the response is HTML (likely CSRF or server error page)
        if (errorText.includes('<!DOCTYPE html>') || errorText.includes('<html')) {
          throw new Error('Server returned HTML instead of JSON - possible CSRF or server error.');
        }
        
        // Try to parse error as JSON
        const errorData = JSON.parse(errorText);
        throw { 
          response: { status: response.status, data: errorData },
          message: `Error ${response.status}: ${JSON.stringify(errorData)}`
        };
      }
      
      try {
        responseData = await response.json();
        console.log('Response parsed successfully:', responseData);
        
        // Additional validation to ensure the response is actually successful
        if (responseData && responseData.message && responseData.message.includes('success')) {
          console.log('Detected success message in response');
        } else if (responseData && responseData.error) {
          console.error('Error in response despite OK status:', responseData);
          throw new Error(responseData.error);
        }
      } catch (parseError) {
        console.error('Error parsing response as JSON:', parseError);
        const rawText = await response.text();
        console.log('Raw response text:', rawText);
        throw new Error('Invalid JSON response from server');
      }
    } catch (fetchError) {
      console.error('Fetch attempt failed:', fetchError);
      console.log('Trying with useApi as fallback');
      
      // Try useApi as fallback
      const apiResponse = await post('/bn/gold-sponsors/apply/', formData);
      
      if (apiResponse.error) {
        throw new Error(apiResponse.error.message || JSON.stringify(apiResponse.error));
      }
      
      responseData = apiResponse.data;
      
      // Better validation of the useApi response
      if (!responseData) {
        console.error('No data in useApi response');
        throw new Error('No data received from server');
      }
      
      if (responseData.error || responseData.status === 'error') {
        console.error('Error indicated in useApi response data:', responseData);
        throw new Error(responseData.error || 'Unknown server error');
      }
    }
    
    // If we've reached this point, the submission was successful
    console.log('Submission successful, response data:', responseData);
    
    // IMPORTANT: Clear any previous error to prevent showing both error and success
    submitError.value = '';
    submitSuccess.value = true;
    
    // Emit the submit event with the response data
    emit('submit', responseData);
    
    // Reset form after successful submission
    resetForm();
    
    // Close the modal after a short delay to show success message
    setTimeout(() => {
      close();
    }, 2000);
    
  } catch (error) {
    console.error('Error submitting gold sponsor application:', error);
    
    // Detailed error logging
    console.log('Error object:', {
      message: error.message,
      name: error.name,
      stack: error.stack,
      response: error.response,
      data: error.data
    });
    
    // Improved error handling to show more detailed error messages
    if (error.response?.data) {
      // Handle Django REST framework validation errors
      const errorData = error.response.data;
      console.log('Error response data:', errorData);
      
      if (typeof errorData === 'object' && !Array.isArray(errorData)) {
        const errorMessages = [];
        
        // Process DRF validation errors which come as field->error array
        Object.keys(errorData).forEach(key => {
          if (Array.isArray(errorData[key])) {
            errorData[key].forEach(message => {
              errorMessages.push(`${key}: ${message}`);
            });
          } else if (typeof errorData[key] === 'object') {
            errorMessages.push(`${key}: ${JSON.stringify(errorData[key])}`);
          } else {
            errorMessages.push(`${key}: ${errorData[key]}`);
          }
        });
        
        if (errorMessages.length > 0) {
          submitError.value = errorMessages.join('\n');
        } else {
          submitError.value = JSON.stringify(errorData);
        }
      } else if (typeof errorData === 'string') {
        submitError.value = errorData;
      } else {
        submitError.value = JSON.stringify(errorData);
      }
    } else if (error.data) {
      // Some fetch libraries put the response data in error.data
      console.log('Error data:', error.data);
      submitError.value = typeof error.data === 'string' ? error.data : JSON.stringify(error.data);
    } else {
      submitError.value = error.message || 'Failed to submit application. Please try again.';
    }
    
    // If the primary submission method failed, suggest using the alternative method
    submitError.value += '\n\nPlease try the alternative submission method below.';
  } finally {
    isSubmitting.value = false;
  }
};
</script>

<style scoped>
/* Add any component-specific styles here */
</style>
