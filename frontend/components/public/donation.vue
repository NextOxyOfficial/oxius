<template>
  <div class="donation-section mb-2">
    <!-- Donation Banner with Animated Donors List -->
    <div
      class="relative overflow-hidden bg-gradient-to-r from-primary-50 via-white to-primary-50 shadow-sm rounded-lg border border-primary-100"
    >
      <!-- Decorative elements -->
      <div
        class="absolute -top-12 -right-12 w-24 h-24 rounded-full bg-primary-100/50 blur-xl"
      ></div>
      <div
        class="absolute -bottom-8 -left-8 w-20 h-20 rounded-full bg-primary-100/30 blur-lg"
      ></div>

      <div
        class="relative z-10 p-2 sm:p-4 flex flex-col md:flex-row items-center justify-between sm:gap-4"
      >
        <div class="flex-1">
          <div class="flex items-center gap-3 mb-2">
            <div class="relative">
              <UIcon name="i-heroicons-heart" class="text-red-500 text-xl" />
              <span class="absolute -top-1 -right-1 flex h-3 w-3">
                <span
                  class="animate-ping absolute inline-flex h-full w-full rounded-full bg-red-400 opacity-75"
                ></span>
                <span
                  class="relative inline-flex rounded-full h-3 w-3 bg-red-500"
                ></span>
              </span>
            </div>
            <h3 class="text-lg font-semibold text-gray-800">
              সাম্প্রতি যারা ডোনেট করেছেন
            </h3>
          </div>

          <!-- Animated donors list -->
          <div class="donors-carousel overflow-hidden h-8">
            <TransitionGroup
              name="donor-slide"
              tag="div"
              class="flex flex-col h-full"
            >
              <div
                v-for="(donor, i) in visibleDonors"
                :key="`donor-${i}-${donor.id}`"
                class="donor-item flex items-center gap-2"
              >
                <UBadge color="primary" size="sm" class="whitespace-nowrap">
                  {{ formatDate(donor.date) }}
                </UBadge>
                <span class="font-medium">
                  {{ donor.name.slice(0, 7) }}***
                </span>
                <span class="text-primary-600 font-semibold">
                  {{ donor.amount }} {{ $t("currency") }}
                </span>
              </div>
            </TransitionGroup>
          </div>
        </div>

        <img
          class="h-12"
          src="/static/frontend/images/donate.png"
          @click="showDonationModal = true"
        />
      </div>
    </div>

    <!-- Donation Modal -->
    <UModal v-model="showDonationModal" prevent-close>
      <div class="p-0">
        <!-- Header with cool title effect -->
        <div
          class="donation-header relative overflow-hidden py-8 px-6 bg-gradient-to-r from-primary-700 to-primary-500 text-white rounded-t-lg"
        >
          <div class="sparkles absolute inset-0 opacity-20"></div>
          <div class="z-10 relative">
            <h2 class="text-xl font-extrabold mb-1 gradient-text">
              <span class="animate-letter" style="--delay: 0s">M</span>
              <span class="animate-letter" style="--delay: 0.05s">a</span>
              <span class="animate-letter" style="--delay: 0.1s">k</span>
              <span class="animate-letter" style="--delay: 0.15s">e</span>
              <span class="animate-letter" style="--delay: 0.2s">&nbsp;</span>
              <span class="animate-letter" style="--delay: 0.25s">a</span>
              <span class="animate-letter" style="--delay: 0.3s">&nbsp;</span>
              <span class="animate-letter" style="--delay: 0.35s">D</span>
              <span class="animate-letter" style="--delay: 0.4s">i</span>
              <span class="animate-letter" style="--delay: 0.45s">f</span>
              <span class="animate-letter" style="--delay: 0.5s">f</span>
              <span class="animate-letter" style="--delay: 0.55s">e</span>
              <span class="animate-letter" style="--delay: 0.6s">r</span>
              <span class="animate-letter" style="--delay: 0.65s">e</span>
              <span class="animate-letter" style="--delay: 0.7s">n</span>
              <span class="animate-letter" style="--delay: 0.75s">c</span>
              <span class="animate-letter" style="--delay: 0.8s">e</span>
            </h2>
            <p class="text-white/90 max-w-md fade-in-up">
              Every contribution helps us build a better platform for our
              community. Your generosity powers innovation and keeps our
              services accessible to all.
            </p>
          </div>
        </div>

        <div class="p-6">
          <!-- Donation Form -->
          <div class="mb-6">
            <!-- Donor Name Input -->
            <UFormGroup label="Your Name" class="mb-4">
              <UInput
                v-model="donorName"
                placeholder="Enter your name or remain anonymous"
                icon="i-heroicons-user-circle"
              />
            </UFormGroup>

            <!-- Amount Selection -->
            <label class="block text-sm font-medium text-gray-700 mb-2"
              >Select Amount</label
            >
            <div class="grid grid-cols-2 gap-3 mb-5">
              <button
                v-for="amount in donationAmounts"
                :key="amount"
                type="button"
                class="donation-amount-btn relative overflow-hidden"
                :class="selectedAmount === amount ? 'selected-amount' : ''"
                @click="selectAmount(amount)"
              >
                <span class="amount-value">{{ amount }}</span>
                <span class="currency-symbol">৳</span>
              </button>
            </div>

            <!-- Custom Amount -->
            <UFormGroup label="Custom Amount">
              <div class="relative">
                <span
                  class="absolute left-3 top-1/2 -translate-y-1/2 text-gray-500 font-medium"
                  >৳</span
                >
                <UInput
                  v-model="customAmount"
                  type="number"
                  placeholder="Enter amount"
                  class="pl-7"
                  @update:model-value="selectedAmount = null"
                />
              </div>
            </UFormGroup>
          </div>

          <!-- Payment Button -->
          <UButton
            color="primary"
            :label="$t('proceed_to_payment')"
            block
            :disabled="!canProceed"
            @click="handleDonation"
            class="donation-cta-btn mb-4"
          />

          <!-- Recent Donors Section -->
          <div class="mt-8 pt-6 border-t border-gray-200">
            <h4
              class="text-lg font-semibold text-gray-800 mb-3 flex items-center gap-2"
            >
              <UIcon name="i-heroicons-users" class="text-primary-500" />
              Recent Supporters
            </h4>

            <div class="recent-donors-list">
              <div
                v-for="(donor, index) in allDonors.slice(0, 5)"
                :key="index"
                class="donor-card"
              >
                <div class="flex items-center gap-2">
                  <div class="donor-avatar">
                    {{ donor.name.charAt(0).toUpperCase() }}
                  </div>
                  <div>
                    <p class="donor-name">{{ donor.name.slice(0, 7) }}***</p>
                    <p class="donor-meta">
                      <span class="donor-amount">৳{{ donor.amount }}</span>
                      <span class="donor-time">{{
                        formatDate(donor.date)
                      }}</span>
                    </p>
                  </div>
                </div>
              </div>
            </div>
          </div>

          <div class="text-center mt-6">
            <UButton
              color="gray"
              variant="ghost"
              :label="$t('cancel')"
              @click="showDonationModal = false"
            />
          </div>
        </div>
      </div>
    </UModal>
  </div>
</template>

<script setup>
const donorName = ref("");

// Update your handleDonation function:
const handleDonation = () => {
  const finalAmount = selectedAmount.value || customAmount.value;
  const name = donorName.value || "Anonymous";
  isProcessing.value = true;

  // Simulate API call
  setTimeout(() => {
    isProcessing.value = false;
    showDonationModal.value = false;

    // Add to local donors list with the provided name
    allDonors.unshift({
      id: Date.now(),
      name: name,
      amount: finalAmount,
      date: new Date(),
    });

    // Reset form
    selectedAmount.value = null;
    customAmount.value = null;
    donorName.value = "";

    // Show success message
    try {
      toast.add({
        title: "Thank you for your donation!",
        description: `Your donation of ${finalAmount}৳ helps us greatly.`,
        color: "green",
      });
    } catch (e) {
      alert("Thank you for your donation!");
    }
  }, 1500);
};

// Mock donor data - replace with actual API data
const allDonors = [
  {
    id: 1,
    name: "Ahmed Khan",
    amount: 500,
    date: new Date(Date.now() - 1000 * 60 * 5),
  },
  {
    id: 2,
    name: "Maryam Sultana",
    amount: 200,
    date: new Date(Date.now() - 1000 * 60 * 30),
  },
  {
    id: 3,
    name: "Tariq Rahman",
    amount: 1000,
    date: new Date(Date.now() - 1000 * 60 * 60),
  },
  {
    id: 4,
    name: "Samira Hossain",
    amount: 100,
    date: new Date(Date.now() - 1000 * 60 * 120),
  },
  {
    id: 5,
    name: "Kamal Zaman",
    amount: 50,
    date: new Date(Date.now() - 1000 * 60 * 180),
  },
];

const visibleDonors = ref([allDonors[0]]);
const currentDonorIndex = ref(0);
const donationAmounts = [50, 100, 500, 1000];
const selectedAmount = ref(null);
const customAmount = ref(null);
const showDonationModal = ref(false);
const isProcessing = ref(false);
let donorRotationTimer;

// Format date to relative time (e.g., "2m ago")
const formatDate = (date) => {
  const now = new Date();
  const diffMs = now - date;
  const diffMins = Math.round(diffMs / 60000);

  if (diffMins < 60) {
    return `${diffMins}m ago`;
  } else if (diffMins < 1440) {
    return `${Math.floor(diffMins / 60)}h ago`;
  } else {
    return `${Math.floor(diffMins / 1440)}d ago`;
  }
};

// Check if user can proceed with donation
const canProceed = computed(() => {
  return selectedAmount.value || (customAmount.value && customAmount.value > 0);
});

// Select predefined amount
const selectAmount = (amount) => {
  selectedAmount.value = amount;
  customAmount.value = null;
};

// Rotate through donors in the carousel
const rotateDonors = () => {
  currentDonorIndex.value = (currentDonorIndex.value + 1) % allDonors.length;
  visibleDonors.value = [allDonors[currentDonorIndex.value]];
};

// Start/stop donor rotation
onMounted(() => {
  donorRotationTimer = setInterval(rotateDonors, 3000);
});

onUnmounted(() => {
  clearInterval(donorRotationTimer);
});
</script>

<style scoped>
.donation-button {
  transition: all 0.3s ease;
}

.donation-button:hover {
  transform: translateY(-2px);
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.1);
}

.donation-button::after {
  content: "";
  position: absolute;
  top: 50%;
  left: 50%;
  width: 5px;
  height: 5px;
  background: rgba(255, 255, 255, 0.7);
  opacity: 0;
  border-radius: 100%;
  transform: scale(1, 1) translate(-50%, -50%);
  transform-origin: 50% 50%;
}

.donation-button:hover::after {
  animation: ripple 1s ease-out;
}

.donation-amount-btn {
  transition: all 0.2s ease;
}

.donation-amount-btn:hover {
  transform: scale(1.05);
}

/* Donor slide transition */
.donor-slide-enter-active,
.donor-slide-leave-active {
  transition: all 0.5s ease;
}

.donor-slide-enter-from {
  transform: translateY(20px);
  opacity: 0;
}

.donor-slide-leave-to {
  transform: translateY(-20px);
  opacity: 0;
}

.donation-header {
  position: relative;
  overflow: hidden;
}

.sparkles {
  background-image: radial-gradient(circle, white 1px, transparent 1px);
  background-size: 15px 15px;
}

.gradient-text {
  background: linear-gradient(to right, #ffffff, #e0f2fe);
  -webkit-background-clip: text;
  background-clip: text;
  color: transparent;
  display: inline-block;
}

.animate-letter {
  display: inline-block;
  opacity: 0;
  transform: translateY(20px);
  animation: fadeInUp 0.6s forwards;
  animation-delay: var(--delay);
}

.fade-in-up {
  animation: fadeInUp 0.8s forwards;
  animation-delay: 0.8s;
  opacity: 0;
  transform: translateY(20px);
}

/* Currency styling */
.donation-amount-btn {
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 12px 16px;
  border-radius: 8px;
  background: #f8fafc;
  border: 1px solid #e2e8f0;
  transition: all 0.2s ease;
  position: relative;
  overflow: hidden;
}

.donation-amount-btn:hover {
  border-color: #4f46e5;
  transform: translateY(-2px);
  box-shadow: 0 3px 10px rgba(79, 70, 229, 0.1);
}

.donation-amount-btn.selected-amount {
  background-color: #4f46e5;
  color: white;
  border-color: #4f46e5;
}

.amount-value {
  font-size: 1.25rem;
  font-weight: 600;
}

.currency-symbol {
  font-size: 1rem;
  margin-left: 2px;
  font-weight: 500;
}

.donation-cta-btn {
  position: relative;
  overflow: hidden;
}

.donation-cta-btn::after {
  content: "";
  position: absolute;
  top: -50%;
  left: -50%;
  width: 200%;
  height: 200%;
  background: linear-gradient(
    60deg,
    rgba(255, 255, 255, 0) 10%,
    rgba(255, 255, 255, 0.2) 20%,
    rgba(255, 255, 255, 0) 30%
  );
  transform: rotate(-45deg);
  animation: shineEffect 3s infinite;
}

/* Recent donors styling */
.recent-donors-list {
  display: flex;
  flex-direction: column;
  gap: 8px;
  max-height: 200px;
  overflow-y: auto;
  padding-right: 8px;
}

.donor-card {
  padding: 8px 12px;
  border-radius: 8px;
  background: #f9fafb;
  transition: all 0.2s ease;
}

.donor-card:hover {
  background: #f3f4f6;
}

.donor-avatar {
  width: 32px;
  height: 32px;
  border-radius: 50%;
  background: #4f46e5;
  color: white;
  display: flex;
  align-items: center;
  justify-content: center;
  font-weight: bold;
}

.donor-name {
  font-weight: 500;
  font-size: 0.875rem;
  color: #1f2937;
}

.donor-meta {
  display: flex;
  gap: 8px;
  font-size: 0.75rem;
}

.donor-amount {
  color: #4f46e5;
  font-weight: 600;
}

.donor-time {
  color: #6b7280;
}

@keyframes fadeInUp {
  to {
    opacity: 1;
    transform: translateY(0);
  }
}

@keyframes shineEffect {
  0% {
    left: -100%;
  }
  20% {
    left: 100%;
  }
  100% {
    left: 100%;
  }
}

@keyframes ripple {
  0% {
    transform: scale(0, 0);
    opacity: 1;
  }
  20% {
    transform: scale(25, 25);
    opacity: 0.8;
  }
  100% {
    opacity: 0;
    transform: scale(40, 40);
  }
}
</style>
