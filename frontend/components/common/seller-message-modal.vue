<template>  <UModal v-model="isOpen" :ui="{ base: 'max-w-md' }">
    <UCard>
      <template #header>
        <div class="flex items-center justify-between">
          <h3 class="text-base font-medium text-gray-800 dark:text-white">
            Message to {{ sellerName || 'Seller' }}
            <span v-if="sellerTitle" class="text-xs text-gray-600 font-normal block">{{ sellerTitle }}</span>
          </h3>
          <UButton icon="i-heroicons-x-mark" color="gray" variant="ghost" size="sm" @click="closeModal" />
        </div>
      </template>
      
      <div class="space-y-4">
        <!-- Product reference -->
        <div v-if="productName" class="text-sm bg-slate-50 dark:bg-slate-800/40 p-3 rounded-lg">
          <span class="font-medium text-slate-600 dark:text-slate-300">About product:</span> 
          <span class="text-primary-600 dark:text-primary-400">{{ productName }}</span>
        </div>
        
        <!-- Message input -->
        <div>
          <label for="message-text" class="block text-sm font-medium text-gray-800 dark:text-gray-300 mb-1">
            Your Message
          </label>
          <UTextarea
            id="message-text"
            v-model="message"
            placeholder="Type your message to the seller here..."
            class="w-full min-h-24"
            size="md"
          />
          <p class="mt-1 text-xs text-slate-500">
            Please be specific about your inquiry to get a faster response.
          </p>
        </div>
        
        <!-- Contact info -->
        <div>
          <label for="contact-info" class="block text-sm font-medium text-gray-800 dark:text-gray-300 mb-1">
            Your Contact Info (optional)
          </label>
          <UInput
            id="contact-info"
            v-model="contactInfo"
            placeholder="Phone number or email"
            size="md"
          />
        </div>
      </div>
      
      <template #footer>
        <div class="flex justify-end gap-3">
          <UButton
            color="gray"
            variant="soft"
            @click="closeModal"
          >
            Cancel
          </UButton>
          <UButton
            color="primary"
            :loading="sending"
            :disabled="!message.trim() || sending"
            @click="sendMessage"
            icon="i-heroicons-paper-airplane"
          >
            Send Message
          </UButton>
        </div>
      </template>
    </UCard>
  </UModal>
</template>

<script setup>
const props = defineProps({
  isOpen: { type: Boolean, default: false },
  sellerId: { type: String, default: '' },
  sellerName: { type: String, default: 'Seller' },
  productId: { type: String, default: '' },
  productName: { type: String, default: '' }
});

const emit = defineEmits(['update:isOpen', 'message-sent']);

const message = ref('');
const contactInfo = ref('');
const sending = ref(false);

function closeModal() {
  emit('update:isOpen', false);
  // Reset form values after a delay to prevent visual jumps
  setTimeout(() => {
    message.value = '';
    contactInfo.value = '';
  }, 300);
}

async function sendMessage() {
  sending.value = true;
  
  try {
    
    // Simulate API delay
    await new Promise(resolve => setTimeout(resolve, 1000));
    
    // Show success notification
    useNuxtApp().$toast.success(`Message sent successfully to ${props.sellerName}`);
    
    // Emit success event
    emit('message-sent', {
      sellerId: props.sellerId,
      message: message.value,
      contactInfo: contactInfo.value
    });
    
    closeModal();
  } catch (error) {
    console.error('Error sending message:', error);
    useNuxtApp().$toast.error('Failed to send message. Please try again.');
  } finally {
    sending.value = false;
  }
}

// Reset values when modal opens
watch(() => props.isOpen, (isOpen) => {
  if (isOpen) {
    message.value = '';
    contactInfo.value = '';
  }
});
</script>
