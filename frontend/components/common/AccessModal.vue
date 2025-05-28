<template>
  <div v-if="show" class="fixed inset-0 z-50 overflow-y-auto">
    <div class="flex items-center justify-center min-h-screen p-4">
      <!-- Background overlay -->
      <div 
        class="fixed inset-0 transition-opacity bg-gray-500 bg-opacity-75" 
        @click="$emit('close')"
      ></div>
      
      <!-- Modal content -->
      <div class="bg-white rounded-xl shadow-xl transform transition-all max-w-md w-full">
        <!-- Header -->
        <div class="px-6 py-4 border-b border-gray-200">
          <div class="flex items-center justify-between">
            <h3 class="text-xl font-bold text-gray-900 flex items-center">
              <svg
                class="w-6 h-6 text-red-500 mr-2"
                fill="none"
                stroke="currentColor"
                viewBox="0 0 24 24"
              >
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M12 15v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2zm10-10V7a4 4 0 00-8 0v4h8z"
                />
              </svg>
              {{ $t('premium_access_required') || 'Premium Access Required' }}
            </h3>
            <button
              @click="$emit('close')"
              class="text-gray-400 hover:text-gray-600 focus:outline-none"
            >
              <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M6 18L18 6M6 6l12 12"
                />
              </svg>
            </button>
          </div>
        </div>

        <!-- Body -->
        <div class="px-6 py-4">
          <!-- Icon and message -->
          <div class="text-center mb-4">
            <div class="mx-auto flex items-center justify-center h-16 w-16 rounded-full bg-gradient-to-br from-red-500 to-rose-600 mb-4">
              <svg
                class="h-8 w-8 text-white"
                fill="none"
                stroke="currentColor"
                viewBox="0 0 24 24"
              >
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M15 10l4.553-2.276A1 1 0 0121 8.618v6.764a1 1 0 01-1.447.894L15 14M5 18h8a2 2 0 002-2V8a2 2 0 00-2-2H5a2 2 0 00-2 2v8a2 2 0 002 2z"
                />
              </svg>
            </div>
            
            <h4 class="text-lg font-medium text-gray-900 mb-2">
              {{ isAuthenticated ? $t('premium_subscription_required') : $t('login_required') }}
            </h4>
            <p class="text-gray-600">
              {{ isAuthenticated ? $t('premium_subscription_message') : $t('login_required_message') }}
            </p>
          </div>

          <!-- Benefits list -->
          <div class="bg-gray-50 rounded-lg p-4 mb-4">
            <h5 class="font-medium text-gray-900 mb-3 flex items-center">
              <svg class="w-5 h-5 text-green-500 mr-2" fill="currentColor" viewBox="0 0 20 20">
                <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clip-rule="evenodd" />
              </svg>
              {{ $t('premium_benefits') || 'Premium Benefits' }}
            </h5>
            <ul class="space-y-2 text-sm text-gray-600">
              <li class="flex items-center">
                <svg class="w-4 h-4 text-green-500 mr-2" fill="currentColor" viewBox="0 0 20 20">
                  <path fill-rule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" clip-rule="evenodd" />
                </svg>
                {{ $t('unlimited_video_access') || 'Unlimited video access' }}
              </li>
              <li class="flex items-center">
                <svg class="w-4 h-4 text-green-500 mr-2" fill="currentColor" viewBox="0 0 20 20">
                  <path fill-rule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" clip-rule="evenodd" />
                </svg>
                {{ $t('download_materials') || 'Download course materials' }}
              </li>
              <li class="flex items-center">
                <svg class="w-4 h-4 text-green-500 mr-2" fill="currentColor" viewBox="0 0 20 20">
                  <path fill-rule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" clip-rule="evenodd" />
                </svg>
                {{ $t('priority_support') || 'Priority customer support' }}
              </li>
              <li class="flex items-center">
                <svg class="w-4 h-4 text-green-500 mr-2" fill="currentColor" viewBox="0 0 20 20">
                  <path fill-rule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" clip-rule="evenodd" />
                </svg>
                {{ $t('ad_free_experience') || 'Ad-free learning experience' }}
              </li>
            </ul>
          </div>
        </div>

        <!-- Footer -->
        <div class="px-6 py-4 bg-gray-50 rounded-b-xl flex flex-col sm:flex-row gap-3">
          <!-- Login button for non-authenticated users -->
          <button
            v-if="!isAuthenticated"
            @click="handleLogin"
            class="flex-1 bg-gradient-to-r from-blue-500 to-blue-600 text-white py-3 px-4 rounded-lg font-medium flex items-center justify-center"
          >
            <svg class="w-5 h-5 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11 16l-4-4m0 0l4-4m-4 4h14m-5 4v1a3 3 0 01-3 3H6a3 3 0 01-3-3V7a3 3 0 013-3h7a3 3 0 013 3v1" />
            </svg>
            {{ $t('login_now') || 'Login Now' }}
          </button>
          
          <!-- Subscribe button for authenticated users -->
          <button
            v-else
            @click="handleSubscribe"
            class="flex-1 bg-gradient-to-r from-green-500 to-green-600 text-white py-3 px-4 rounded-lg font-medium flex items-center justify-center"
          >
            <svg class="w-5 h-5 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 3v4M3 5h4M6 17v4m-2-2h4m5-16l2.286 6.857L21 12l-5.714 2.143L13 21l-2.286-6.857L5 12l5.714-2.143L13 3z" />
            </svg>
            {{ $t('upgrade_to_premium') || 'Upgrade to Premium' }}
          </button>

          <!-- Cancel button -->
          <button
            @click="$emit('close')"
            class="flex-1 sm:flex-none bg-gray-200 text-gray-700 py-3 px-4 rounded-lg font-medium"
          >
            {{ $t('maybe_later') || 'Maybe Later' }}
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { useAuth } from '~/composables/useAuth'

const props = defineProps({
  show: {
    type: Boolean,
    default: false
  }
})

defineEmits(['close', 'login', 'subscribe'])

const { isAuthenticated } = useAuth()

// Handlers for actions
const handleLogin = () => {
  navigateTo('/auth/login')
}

const handleSubscribe = () => {
  navigateTo('/subscription')
}
</script>
