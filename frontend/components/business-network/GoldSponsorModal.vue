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
                </div>                <div>
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
                  <div v-else-if="packageError" class="p-3 bg-red-50 border border-red-200 rounded-lg">
                    <p class="text-sm text-red-600">{{ packageError }}</p>
                    <button @click="fetchPackages" class="mt-2 text-sm text-red-700 underline">Try again</button>
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
              </div>
                <!-- Error message -->
              <div v-if="submitError" class="mt-4 p-3 bg-red-50 border border-red-200 rounded-lg">
                <p class="text-sm text-red-600">{{ submitError }}</p>
              </div>
              
              <!-- Success message -->
              <div v-if="submitSuccess" class="mt-4 p-3 bg-green-50 border border-green-200 rounded-lg">
                <p class="text-sm text-green-600">✓ Your Gold Sponsor application has been submitted successfully!</p>
              </div>
              
              <!-- Submit button -->
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

const props = defineProps({
  isOpen: {
    type: Boolean,
    default: false
  }
});

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
    const response = await $fetch('/api/bn/gold-sponsors/packages/');
    packages.value = response;
  } catch (error) {
    console.error('Error fetching packages:', error);
    packageError.value = 'Failed to load sponsorship packages. Please try again.';
    // Fallback to default packages
    packages.value = [
      {
        id: 1,
        name: '1 Month Gold Sponsor',
        description: 'Premium visibility for 1 month',
        price: 2999,
        duration_months: 1
      }
    ];
  } finally {
    isLoadingPackages.value = false;
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
  
  try {
    // Create FormData for file upload
    const formData = new FormData();
    formData.append('business_name', form.value.businessName);
    formData.append('business_description', form.value.businessDescription);
    formData.append('contact_email', form.value.contactEmail);
    formData.append('phone_number', form.value.phoneNumber);
    formData.append('website', form.value.website);
    formData.append('profile_url', form.value.profileUrl);
    formData.append('package_id', form.value.selectedPackage);
    
    if (form.value.logo) {
      formData.append('logo', form.value.logo);
    }
      // Submit to API
    const response = await $fetch('/api/bn/gold-sponsors/apply/', {
      method: 'POST',
      body: formData
    });
    
    submitSuccess.value = true;
    
    // Emit the submit event with the response data
    emit('submit', response);
    
    // Reset form
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
    
    // Close the modal after a short delay to show success message
    setTimeout(() => {
      close();
    }, 2000);
    
  } catch (error) {
    console.error('Error submitting gold sponsor application:', error);
    submitError.value = error.data?.message || 'Failed to submit application. Please try again.';
  } finally {
    isSubmitting.value = false;
  }
};
</script>

<style scoped>
/* Add any component-specific styles here */
</style>
