<template>
  <UModal v-model="isOpen" :ui="{ width: 'sm:max-w-md' }">
    <UCard :ui="{ ring: '', divide: 'divide-y divide-gray-100 dark:divide-gray-800' }">
      <template #header>
        <div class="flex items-center justify-between">
          <h3 class="text-lg font-semibold text-gray-900 dark:text-white">
            Donate to {{ plan?.title }}
          </h3>
          <UButton color="gray" variant="ghost" icon="i-heroicons-x-mark-20-solid" class="-my-1" @click="isOpen = false" />
        </div>
      </template>

      <div class="space-y-4">
        <!-- Available Balance Display -->
        <div v-if="user" class="bg-gradient-to-br from-green-50 to-emerald-50 dark:from-green-900/20 dark:to-emerald-900/20 rounded-lg p-4 border border-green-200 dark:border-green-800">
          <div class="flex items-center justify-between">
            <div class="flex items-center gap-2">
              <UIcon name="i-heroicons-wallet" class="w-5 h-5 text-green-600 dark:text-green-400" />
              <span class="text-sm font-medium text-gray-700 dark:text-gray-300">Available Balance</span>
            </div>
            <div class="flex items-center gap-1 text-lg font-bold text-green-700 dark:text-green-400">
              <UIcon name="i-mdi:currency-bdt" class="w-5 h-5" />
              <span>{{ user?.user?.balance || 0 }}</span>
            </div>
          </div>
        </div>

        <!-- Amount Input -->
        <div>
          <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
            Donation Amount
          </label>
          <UInput
            v-model="amount"
            type="number"
            placeholder="Enter amount"
            size="lg"
            icon="i-mdi:currency-bdt"
            :ui="{ icon: { trailing: { pointer: '' } } }"
          >
            <template #trailing>
              <span class="text-gray-400 text-sm">BDT</span>
            </template>
          </UInput>
          <p v-if="amount && Number(amount) < minAmount" class="mt-1 text-xs text-red-600 dark:text-red-400">
            Minimum donation amount is ৳{{ minAmount }}
          </p>
        </div>

        <!-- Quick Amount Buttons -->
        <div class="grid grid-cols-4 gap-2">
          <button
            v-for="quickAmount in quickAmounts"
            :key="quickAmount"
            type="button"
            class="px-3 py-2 text-sm font-medium rounded-lg border-2 transition-all"
            :class="Number(amount) === quickAmount 
              ? 'border-purple-500 bg-purple-50 dark:bg-purple-900/20 text-purple-700 dark:text-purple-300' 
              : 'border-gray-200 dark:border-gray-700 text-gray-700 dark:text-gray-300 hover:border-purple-300 dark:hover:border-purple-600'"
            @click="amount = quickAmount"
          >
            ৳{{ quickAmount }}
          </button>
        </div>

        <!-- Payment Method Selection -->
        <div>
          <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-3">
            Payment Method
          </label>
          <div class="space-y-2">
            <!-- Pay with Balance -->
            <button
              type="button"
              class="w-full flex items-center justify-between p-4 rounded-lg border-2 transition-all"
              :class="paymentMethod === 'balance' 
                ? 'border-green-500 bg-green-50 dark:bg-green-900/20' 
                : 'border-gray-200 dark:border-gray-700 hover:border-green-300 dark:hover:border-green-600'"
              :disabled="!user || Number(user?.user?.balance || 0) < Number(amount || 0)"
              @click="paymentMethod = 'balance'"
            >
              <div class="flex items-center gap-3">
                <div class="w-10 h-10 rounded-full bg-green-100 dark:bg-green-900/40 flex items-center justify-center">
                  <UIcon name="i-heroicons-wallet" class="w-5 h-5 text-green-600 dark:text-green-400" />
                </div>
                <div class="text-left">
                  <p class="font-semibold text-gray-900 dark:text-white">Pay with Balance</p>
                  <p class="text-xs text-gray-500 dark:text-gray-400">
                    Available: ৳{{ user?.user?.balance || 0 }}
                  </p>
                </div>
              </div>
              <div v-if="paymentMethod === 'balance'" class="w-5 h-5 rounded-full bg-green-500 flex items-center justify-center">
                <UIcon name="i-heroicons-check" class="w-4 h-4 text-white" />
              </div>
            </button>

            <!-- Pay with Payment Gateway -->
            <button
              type="button"
              class="w-full flex items-center justify-between p-4 rounded-lg border-2 transition-all"
              :class="paymentMethod === 'gateway' 
                ? 'border-purple-500 bg-purple-50 dark:bg-purple-900/20' 
                : 'border-gray-200 dark:border-gray-700 hover:border-purple-300 dark:hover:border-purple-600'"
              @click="paymentMethod = 'gateway'"
            >
              <div class="flex items-center gap-3">
                <div class="w-10 h-10 rounded-full bg-purple-100 dark:bg-purple-900/40 flex items-center justify-center">
                  <UIcon name="i-heroicons-credit-card" class="w-5 h-5 text-purple-600 dark:text-purple-400" />
                </div>
                <div class="text-left">
                  <p class="font-semibold text-gray-900 dark:text-white">Payment Gateway</p>
                  <p class="text-xs text-gray-500 dark:text-gray-400">
                    bKash, Nagad, Card
                  </p>
                </div>
              </div>
              <div v-if="paymentMethod === 'gateway'" class="w-5 h-5 rounded-full bg-purple-500 flex items-center justify-center">
                <UIcon name="i-heroicons-check" class="w-4 h-4 text-white" />
              </div>
            </button>
          </div>

          <!-- Insufficient Balance Warning -->
          <p v-if="user && paymentMethod === 'balance' && Number(user?.user?.balance || 0) < Number(amount || 0)" class="mt-2 text-xs text-amber-600 dark:text-amber-400 flex items-center gap-1">
            <UIcon name="i-heroicons-exclamation-triangle" class="w-4 h-4" />
            Insufficient balance. Please use payment gateway or add funds.
          </p>
        </div>
      </div>

      <template #footer>
        <div class="flex items-center justify-between gap-3">
          <UButton color="gray" variant="ghost" @click="isOpen = false">
            Cancel
          </UButton>
          <UButton
            color="green"
            :loading="processing"
            :disabled="!canProceed"
            @click="handleDonate"
          >
            <UIcon name="i-heroicons-heart" class="w-4 h-4 mr-1" />
            Donate ৳{{ amount || 0 }}
          </UButton>
        </div>
      </template>
    </UCard>
  </UModal>
</template>

<script setup>
const props = defineProps({
  modelValue: Boolean,
  plan: {
    type: Object,
    required: true
  }
})

const emit = defineEmits(['update:modelValue', 'success'])

const { user } = useAuth()
const toast = useToast()
const config = useRuntimeConfig()

const isOpen = computed({
  get: () => props.modelValue,
  set: (value) => emit('update:modelValue', value)
})

const amount = ref('')
const paymentMethod = ref('balance')
const processing = ref(false)
const minAmount = 10
const quickAmounts = [50, 100, 500, 1000]

const canProceed = computed(() => {
  const amt = Number(amount.value || 0)
  if (amt < minAmount) return false
  if (paymentMethod.value === 'balance') {
    return user.value && Number(user.value?.user?.balance || 0) >= amt
  }
  return true
})

const handleDonate = async () => {
  if (!canProceed.value) return

  processing.value = true

  try {
    console.log('Making donation request with:', {
      url: `${config.public.baseURL}/api/raise-up/posts/${props.plan.id}/donate/`,
      token: user.value.access ? 'Token exists' : 'No token',
      amount: Number(amount.value),
      payment_method: paymentMethod.value,
      planId: props.plan.id
    })
    
    const response = await $fetch(`${config.public.baseURL}/api/raise-up/posts/${props.plan.id}/donate/`, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${user.value.access}`,
        'Content-Type': 'application/json'
      },
      body: {
        amount: Number(amount.value),
        payment_method: paymentMethod.value
      }
    })
    
    console.log('Donation response:', response)

    // Update user balance in frontend if balance was used
    if (paymentMethod.value === 'balance' && response.new_balance !== null) {
      user.value.user.balance = response.new_balance
    }

    toast.add({
      title: 'Donation Successful',
      description: `Thank you for donating ৳${amount.value} to ${props.plan.title}`,
      color: 'green',
      timeout: 4000,
    })

    emit('success', response)
    isOpen.value = false
    
    // Reset form
    amount.value = ''
    paymentMethod.value = 'balance'
  } catch (err) {
    console.error('Donation error:', err)
    console.error('Full error object:', JSON.stringify(err, null, 2))
    
    let errorMessage = 'Unable to process donation. Please try again.'
    
    // Check different error response formats
    if (err.data?.message) {
      errorMessage = err.data.message
    } else if (err.data?.detail) {
      errorMessage = err.data.detail
    } else if (err.message) {
      errorMessage = err.message
    } else if (err.statusText) {
      errorMessage = `${err.status}: ${err.statusText}`
    }
    
    toast.add({
      title: 'Donation Failed',
      description: errorMessage,
      color: 'red',
      timeout: 5000,
    })
  } finally {
    processing.value = false
  }
}

// Auto-select payment method based on balance
watch([amount, () => user.value?.user?.balance], () => {
  if (user.value && amount.value) {
    const amt = Number(amount.value)
    const balance = Number(user.value?.user?.balance || 0)
    if (balance < amt && paymentMethod.value === 'balance') {
      paymentMethod.value = 'gateway'
    }
  }
})
</script>
