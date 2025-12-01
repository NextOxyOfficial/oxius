<template>
  <div class="min-h-screen bg-gradient-to-br from-gray-50 via-white to-emerald-50/30 flex items-center justify-center p-4">
    <div class="w-full max-w-md">
      <!-- Loading State -->
      <div v-if="loader" class="bg-white rounded-2xl shadow-xl p-8 text-center">
        <div class="w-20 h-20 mx-auto mb-6 rounded-full bg-gray-100 flex items-center justify-center animate-pulse">
          <UIcon name="i-heroicons-credit-card" class="text-4xl text-gray-400" />
        </div>
        <h2 class="text-xl font-semibold text-gray-800 mb-2">Verifying Payment</h2>
        <p class="text-gray-500 mb-6">Please wait while we confirm your transaction...</p>
        <div class="flex justify-center">
          <div class="w-8 h-8 border-4 border-emerald-500 border-t-transparent rounded-full animate-spin"></div>
        </div>
      </div>

      <!-- Success State -->
      <div v-else-if="!showError" class="bg-white rounded-2xl shadow-xl overflow-hidden">
        <!-- Success Header -->
        <div class="bg-gradient-to-r from-emerald-500 to-teal-500 p-8 text-center">
          <div class="w-20 h-20 mx-auto mb-4 rounded-full bg-white/20 backdrop-blur-sm flex items-center justify-center">
            <UIcon name="i-heroicons-check" class="text-5xl text-white" />
          </div>
          <h2 class="text-2xl font-bold text-white mb-1">Payment Successful!</h2>
          <p class="text-white/80">Your transaction has been completed</p>
        </div>

        <!-- Transaction Details -->
        <div class="p-6">
          <div class="space-y-4 mb-6">
            <div class="flex justify-between items-center py-3 border-b border-gray-100">
              <span class="text-gray-500">Amount</span>
              <span class="font-semibold text-gray-800">৳{{ verifyPaymentDetails.amount || '0' }}</span>
            </div>
            <div class="flex justify-between items-center py-3 border-b border-gray-100">
              <span class="text-gray-500">Payment Method</span>
              <span class="font-medium text-gray-800">{{ verifyPaymentDetails.payment_method || 'N/A' }}</span>
            </div>
            <div class="flex justify-between items-center py-3 border-b border-gray-100">
              <span class="text-gray-500">Transaction ID</span>
              <span class="font-mono text-sm text-gray-800">{{ verifyPaymentDetails.shurjopay_order_id?.slice(0, 15) || 'N/A' }}...</span>
            </div>
            <div class="flex justify-between items-center py-3">
              <span class="text-gray-500">Status</span>
              <UBadge color="green" variant="soft" size="md">
                <UIcon name="i-heroicons-check-circle" class="mr-1" />
                Completed
              </UBadge>
            </div>
          </div>

          <!-- Action Buttons -->
          <div class="space-y-3">
            <UButton
              color="emerald"
              size="lg"
              block
              to="/deposit-withdraw"
              class="justify-center"
            >
              <UIcon name="i-heroicons-wallet" class="mr-2" />
              View Transaction History
            </UButton>
            <UButton
              color="gray"
              variant="soft"
              size="lg"
              block
              to="/"
              class="justify-center"
            >
              <UIcon name="i-heroicons-home" class="mr-2" />
              Back to Home
            </UButton>
          </div>
        </div>

        <!-- Auto Redirect Notice -->
        <div class="bg-gray-50 px-6 py-4 text-center border-t border-gray-100">
          <p class="text-sm text-gray-500">
            <UIcon name="i-heroicons-clock" class="inline mr-1" />
            Redirecting to transaction history in <span class="font-semibold text-emerald-600">{{ countdown }}</span> seconds...
          </p>
        </div>
      </div>

      <!-- Error State -->
      <div v-else class="bg-white rounded-2xl shadow-xl overflow-hidden">
        <!-- Error Header -->
        <div class="bg-gradient-to-r from-red-500 to-rose-500 p-8 text-center">
          <div class="w-20 h-20 mx-auto mb-4 rounded-full bg-white/20 backdrop-blur-sm flex items-center justify-center">
            <UIcon name="i-heroicons-x-mark" class="text-5xl text-white" />
          </div>
          <h2 class="text-2xl font-bold text-white mb-1">Payment Failed</h2>
          <p class="text-white/80">Your transaction could not be completed</p>
        </div>

        <!-- Error Details -->
        <div class="p-6">
          <div class="bg-red-50 border border-red-100 rounded-xl p-4 mb-6">
            <div class="flex items-start gap-3">
              <UIcon name="i-heroicons-exclamation-triangle" class="text-red-500 text-xl flex-shrink-0 mt-0.5" />
              <div>
                <p class="font-medium text-red-800">Transaction Unsuccessful</p>
                <p class="text-sm text-red-600 mt-1">
                  The payment could not be verified. Please try again or contact support if the issue persists.
                </p>
              </div>
            </div>
          </div>

          <!-- Action Buttons -->
          <div class="space-y-3">
            <UButton
              color="primary"
              size="lg"
              block
              to="/deposit-withdraw"
              class="justify-center"
            >
              <UIcon name="i-heroicons-arrow-path" class="mr-2" />
              Try Again
            </UButton>
            <UButton
              color="gray"
              variant="soft"
              size="lg"
              block
              to="/"
              class="justify-center"
            >
              <UIcon name="i-heroicons-home" class="mr-2" />
              Back to Home
            </UButton>
          </div>
        </div>

        <!-- Support Notice -->
        <div class="bg-gray-50 px-6 py-4 text-center border-t border-gray-100">
          <p class="text-sm text-gray-500">
            Need help? <NuxtLink to="/contact" class="text-emerald-600 font-medium hover:underline">Contact Support</NuxtLink>
          </p>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
definePageMeta({
  layout: "dashboard",
});

const { jwtLogin } = useAuth();
const { get, post } = useApi();
const route = useRoute();
const router = useRouter();
const toast = useToast();

const verifyPaymentDetails = ref({});
const showError = ref(false);
const loader = ref(true);
const countdown = ref(5);
let countdownInterval = null;

// Start countdown and redirect
function startCountdown() {
  countdownInterval = setInterval(() => {
    countdown.value--;
    if (countdown.value <= 0) {
      clearInterval(countdownInterval);
      router.push('/deposit-withdraw');
    }
  }, 1000);
}

async function addBalance() {
  const {
    bank_status,
    payment_method,
    amount,
    payable_amount,
    received_amount,
    merchant_invoice_no,
    shurjopay_order_id,
    payment_confirmed_at,
  } = verifyPaymentDetails.value;
  
  const res = await post("/add-user-balance/", {
    bank_status: bank_status.toLowerCase(),
    transaction_type: "Deposit",
    payment_method,
    amount,
    payable_amount,
    received_amount,
    merchant_invoice_no,
    shurjopay_order_id,
    payment_confirmed_at,
  });

  if (res.data) {
    toast.add({ 
      title: "Payment Successful!", 
      description: `৳${amount} has been added to your balance.`,
      color: "green",
      icon: "i-heroicons-check-circle"
    });
    await jwtLogin();
    // Start countdown for auto-redirect
    startCountdown();
  } else {
    toast.add({ 
      title: "Payment Failed", 
      description: res.error?.data?.error || "An error occurred",
      color: "red",
      icon: "i-heroicons-x-circle"
    });
    showError.value = true;
  }
  loader.value = false;
}

async function VerifyPayment() {
  const response = await get(
    "/verify-pay/?sp_order_id=" + route.query.order_id
  );

  if (response.data) {
    verifyPaymentDetails.value = response.data;
  } else {
    toast.add({ 
      title: "Verification Failed", 
      description: response.error?.data?.error || "Could not verify payment",
      color: "red"
    });
    showError.value = true;
    loader.value = false;
  }
}

onMounted(() => {
  VerifyPayment();
});

watch(verifyPaymentDetails, () => {
  if (verifyPaymentDetails.value?.shurjopay_message === "Success") {
    addBalance();
  } else if (Object.keys(verifyPaymentDetails.value).length > 0) {
    toast.add({ 
      title: "Payment Verification Failed!", 
      color: "red"
    });
    showError.value = true;
    loader.value = false;
  }
});

// Cleanup on unmount
onUnmounted(() => {
  if (countdownInterval) {
    clearInterval(countdownInterval);
  }
});
</script>

<style scoped>
@keyframes spin {
  to {
    transform: rotate(360deg);
  }
}
.animate-spin {
  animation: spin 1s linear infinite;
}
</style>
