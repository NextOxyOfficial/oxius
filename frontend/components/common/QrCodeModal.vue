<template>  <UModal
    v-model="isOpen"
    :ui="{ 
      width: 'w-full sm:max-w-md', 
      background: 'bg-white',
      ring: 'ring-1 ring-gray-200',
      shadow: 'shadow-sm'
    }"
  >
    <div
      class="px-6 py-8 flex flex-col gap-6 items-center justify-center relative rounded-2xl overflow-hidden bg-gradient-to-br from-white to-gray-50"
    >      <UButton
        icon="i-heroicons-x-mark"
        size="sm"
        color="gray"
        variant="ghost"
        @click="closeModal"
        class="absolute top-3 right-3 rounded-full hover:bg-gray-100 transition-colors duration-200"
      />
        <!-- Enhanced Header -->
      <div class="text-center mb-6">
        <div class="flex items-center justify-center gap-2 mb-2">
          <div class="w-8 h-8 bg-gradient-to-br from-green-500 to-green-700 rounded-lg flex items-center justify-center shadow-sm">
            <UIcon name="i-heroicons-credit-card" class="w-5 h-5 text-white" />
          </div>
          <h3 class="text-2xl font-bold bg-gradient-to-r from-green-600 to-green-800 bg-clip-text text-transparent">
            AdsyPay
          </h3>
        </div>
      </div>
      <!-- Tabs -->
      <div class="w-full max-w-sm">
        <div class="relative bg-gray-50 rounded-xl p-1.5 mb-6 shadow-inner">
          <!-- Tab Background Slider -->
          <div 
            class="absolute top-1.5 bottom-1.5 w-1/2 bg-white rounded-lg shadow-sm transition-all duration-300 ease-out"
            :class="{
              'left-1.5': activeTab === 'receive',
              'left-1/2 ml-0.5': activeTab === 'send'
            }"
          ></div>
          
          <!-- Tab Buttons -->
          <div class="relative flex">
            <button
              @click="activeTab = 'receive'"
              :class="[
                'flex-1 py-3 px-4 text-sm font-semibold rounded-lg transition-all duration-300 ease-out relative z-10 flex items-center justify-center gap-2',
                activeTab === 'receive' 
                  ? 'text-green-700 transform scale-105' 
                  : 'text-gray-500 hover:text-gray-700 hover:scale-102'
              ]"
            >
              <UIcon 
                name="i-heroicons-qr-code" 
                :class="[
                  'w-4 h-4 transition-all duration-300',
                  activeTab === 'receive' ? 'text-green-600' : 'text-gray-400'
                ]" 
              />
              <span>Receive</span>
            </button>
            <button
              @click="activeTab = 'send'"
              :class="[
                'flex-1 py-3 px-4 text-sm font-semibold rounded-lg transition-all duration-300 ease-out relative z-10 flex items-center justify-center gap-2',
                activeTab === 'send' 
                  ? 'text-blue-700 transform scale-105' 
                  : 'text-gray-500 hover:text-gray-700 hover:scale-102'
              ]"
            >
              <UIcon 
                name="i-heroicons-paper-airplane" 
                :class="[
                  'w-4 h-4 transition-all duration-300',
                  activeTab === 'send' ? 'text-blue-600' : 'text-gray-400'
                ]" 
              />
              <span>Send</span>
            </button>
          </div>
        </div>        <!-- Tab Content with Smooth Transitions -->
        <div class="relative min-h-[320px] overflow-hidden rounded-lg">
          <!-- Receive Tab -->
          <Transition
            name="tab-fade"
            mode="out-in"
          >
            <div v-if="activeTab === 'receive'" key="receive" class="text-center w-full">
              <div class="animate-in slide-in-from-right-4 duration-300">
                <h4 class="text-lg font-semibold mb-2 text-gray-800">{{ title }}</h4>
                <p class="text-sm text-gray-600 mb-4">Show this QR code to receive payment</p>
                <div class="border p-4 rounded-xl shadow-sm bg-white inline-block hover:shadow-sm transition-shadow duration-300">
                  <NuxtImg
                    class="w-[200px] h-[200px] rounded-lg"
                    :src="qrCodeUrl"
                    :alt="title"
                  />
                </div>
                <div class="mt-4 text-xs text-gray-500">
                  Powered by AdsyPay Digital Payment Solution
                </div>
              </div>
            </div>
          </Transition>

          <!-- Send Tab -->
          <Transition
            name="tab-fade"
            mode="out-in"
          >
            <div v-if="activeTab === 'send'" key="send" class="text-center w-full">
              <div class="animate-in slide-in-from-left-4 duration-300">
                <div class="flex flex-col items-center gap-6">
                  <div class="w-20 h-20 bg-gradient-to-br from-blue-100 to-blue-200 rounded-full flex items-center justify-center shadow-sm hover:shadow-sm transition-all duration-300 hover:scale-105">
                    <UIcon name="i-heroicons-banknotes" class="w-10 h-10 text-blue-600" />
                  </div>
                  <div>
                    <h4 class="text-lg font-semibold mb-2 text-gray-800">Send Money</h4>
                    <p class="text-sm text-gray-600 mb-6">Transfer money to other users quickly and securely</p>
                  </div>
                  <UButton
                    color="blue"
                    variant="solid"
                    size="lg"
                    @click="navigateToDepositWithdraw"
                    class="w-full max-w-xs group hover:scale-105 transition-all duration-300 shadow-sm hover:shadow-sm"
                  >
                    <UIcon name="i-heroicons-arrow-right" class="w-4 h-4 mr-2 group-hover:translate-x-1 transition-transform duration-300" />
                    Go to Send Money
                  </UButton>
                  <div class="text-xs text-gray-500 mt-2">
                    Secure transfers with AdsyPay
                  </div>
                </div>
              </div>
            </div>
          </Transition>
        </div>
      </div>
    </div>
  </UModal>
</template>

<script setup>
const props = defineProps({
  modelValue: {
    type: Boolean,
    default: false
  },
  title: {
    type: String,
    default: 'Scan My QR Code'
  },
  qrData: {
    type: String,
    required: true
  },
  size: {
    type: String,
    default: '200x200'
  }
});

const emit = defineEmits(['update:modelValue']);

// Tab state
const activeTab = ref('receive');

const isOpen = computed({
  get: () => props.modelValue,
  set: (value) => {
    emit('update:modelValue', value);
    // Reset to receive tab when modal closes
    if (!value) {
      activeTab.value = 'receive';
    }
  }
});

const qrCodeUrl = computed(() => {
  return `https://api.qrserver.com/v1/create-qr-code/?size=${props.size}&data=${encodeURIComponent(props.qrData)}`;
});

const closeModal = () => {
  isOpen.value = false;
};

const navigateToDepositWithdraw = () => {
  // Close modal first
  closeModal();
  // Navigate to deposit-withdraw page
  navigateTo('/deposit-withdraw');
};
</script>

<style scoped>
/* Custom tab transition animations */
.tab-fade-enter-active,
.tab-fade-leave-active {
  transition: all 0.3s ease-in-out;
}

.tab-fade-enter-from {
  opacity: 0;
  transform: translateY(20px);
}

.tab-fade-leave-to {
  opacity: 0;
  transform: translateY(-20px);
}

/* Enhanced hover effects */
.group:hover .group-hover\:translate-x-1 {
  transform: translateX(0.25rem);
}

/* Additional smooth animations */
@keyframes slide-in-from-right {
  from {
    opacity: 0;
    transform: translateX(1rem);
  }
  to {
    opacity: 1;
    transform: translateX(0);
  }
}

@keyframes slide-in-from-left {
  from {
    opacity: 0;
    transform: translateX(-1rem);
  }
  to {
    opacity: 1;
    transform: translateX(0);
  }
}

.animate-in {
  animation-fill-mode: both;
}

.slide-in-from-right-4 {
  animation: slide-in-from-right 0.3s ease-out;
}

.slide-in-from-left-4 {
  animation: slide-in-from-left 0.3s ease-out;
}
</style>
