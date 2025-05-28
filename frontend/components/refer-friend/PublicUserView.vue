<template>
  <div class="relative">
    <!-- Animated Background -->
    <div class="absolute inset-0 -z-10 overflow-hidden">
      <div
        class="absolute top-0 -left-40 w-[600px] h-[600px] rounded-full bg-gradient-to-br from-primary-100/30 to-primary-300/20 blur-3xl animate-float-slow"
      ></div>
      <div
        class="absolute bottom-0 -right-40 w-[600px] h-[600px] rounded-full bg-gradient-to-tr from-blue-100/30 to-green-200/20 blur-3xl animate-float-reverse"
      ></div>
      <div
        class="absolute inset-0 bg-[url('/noise-pattern.svg')] opacity-[0.02] pointer-events-none"
      ></div>
    </div>

    <div class="container mx-auto px-4 py-16 md:py-24">
      <!-- Hero Section -->
      <div class="max-w-4xl mx-auto text-center mb-20">
        <div
          class="inline-block mb-4 px-6 py-2 rounded-full bg-primary-50 dark:bg-primary-900/30 text-primary-600 dark:text-primary-400 font-medium text-sm"
        >
          Invite Friends & Earn Together
        </div>
        <h1
          class="text-2xl md:text-2xl lg:text-6xl font-semibold mb-6 text-gray-800 dark:text-white tracking-tight animate-fade-in"
        >
          Earn
          <span class="text-primary-600 dark:text-primary-400"
            >Up to 20%</span
          >
          Commission
        </h1>
        <p
          class="text-xl text-gray-500 dark:text-gray-400 mb-10 max-w-2xl mx-auto animate-fade-in-delayed"
        >
          Share your unique link with friends, and earn rewards with different commission rates: 5% on gig completions, 20% on subscriptions and sponsorships!
        </p>
        <div class="flex flex-wrap justify-center gap-4">
          <UButton
            size="xl"
            color="primary"
            to="/auth/register"
            class="cta-button"
          >
            Sign Up & Start Earning
            <template #trailing>
              <UIcon name="i-heroicons-arrow-right" />
            </template>
          </UButton>
          <UButton
            size="xl"
            color="gray"
            variant="soft"
            to="#how-it-works"
            class="cta-button-secondary"
          >
            Learn More
            <template #trailing>
              <UIcon name="i-heroicons-arrow-down" />
            </template>
          </UButton>
        </div>
      </div>

      <!-- How It Works Section -->
      <div id="how-it-works" class="max-w-6xl mx-auto mb-20 scroll-mt-20">
        <div class="text-center mb-12">
          <h2
            class="text-2xl md:text-2xl font-semibold text-gray-800 dark:text-white mb-4"
          >
            How It Works
          </h2>
          <div
            class="h-1 w-20 bg-primary-500 mx-auto mb-6 rounded-full animate-expand"
          ></div>
          <p
            class="text-lg text-gray-500 dark:text-gray-400 max-w-2xl mx-auto"
          >
            Our referral program is simple, transparent, and rewarding. Just
            follow these easy steps:
          </p>
        </div>

        <div class="grid md:grid-cols-3 gap-8">
          <!-- Step 1 -->
          <div
            class="bg-white dark:bg-gray-800 rounded-xl p-8 shadow-sm border border-gray-100 dark:border-gray-700 text-center step-card"
          >
            <div
              class="w-16 h-16 mx-auto mb-6 rounded-full bg-primary-100 dark:bg-primary-900/50 flex items-center justify-center"
            >
              <span
                class="text-xl font-semibold text-primary-600 dark:text-primary-400"
                >1</span
              >
            </div>
            <h3
              class="text-xl font-semibold mb-3 text-gray-800 dark:text-white"
            >
              Create Account
            </h3>
            <p class="text-gray-500 dark:text-gray-500">
              Sign up for a free account and get your unique referral link
              instantly.
            </p>
          </div>

          <!-- Step 2 -->
          <div
            class="bg-white dark:bg-gray-800 rounded-xl p-8 shadow-sm border border-gray-100 dark:border-gray-700 text-center step-card"
          >
            <div
              class="w-16 h-16 mx-auto mb-6 rounded-full bg-primary-100 dark:bg-primary-900/50 flex items-center justify-center"
            >
              <span
                class="text-xl font-semibold text-primary-600 dark:text-primary-400"
                >2</span
              >
            </div>
            <h3
              class="text-xl font-semibold mb-3 text-gray-800 dark:text-white"
            >
              Share Your Link
            </h3>
            <p class="text-gray-500 dark:text-gray-500">
              Share your referral link with friends via email, social media,
              or messaging apps.
            </p>
          </div>

          <!-- Step 3 -->
          <div
            class="bg-white dark:bg-gray-800 rounded-xl p-8 shadow-sm border border-gray-100 dark:border-gray-700 text-center step-card"
          >
            <div
              class="w-16 h-16 mx-auto mb-6 rounded-full bg-primary-100 dark:bg-primary-900/50 flex items-center justify-center"
            >
              <span
                class="text-xl font-semibold text-primary-600 dark:text-primary-400"
                >3</span
              >
            </div>
            <h3
              class="text-xl font-semibold mb-3 text-gray-800 dark:text-white"
            >
              Earn Commissions
            </h3>
            <p class="text-gray-500 dark:text-gray-500">
              Earn different commission rates: 5% on gig completions, 20% on Pro subscriptions and Gold sponsorships.
            </p>
          </div>
        </div>
      </div>

      <!-- Stats Section -->
      <div class="max-w-6xl mx-auto mb-20">
        <div class="grid grid-cols-2 md:grid-cols-4 gap-4 md:gap-8">
          <div
            class="bg-white dark:bg-gray-800 rounded-xl p-6 shadow-sm border border-gray-100 dark:border-gray-700 text-center stat-box"
          >
            <div
              class="text-2xl md:text-2xl font-semibold text-primary-600 dark:text-primary-400 mb-2"
            >
              5-20%
            </div>
            <p class="text-sm md:text-base text-gray-500 dark:text-gray-500">
              Commission Rate
            </p>
          </div>

          <div
            class="bg-white dark:bg-gray-800 rounded-xl p-6 shadow-sm border border-gray-100 dark:border-gray-700 text-center stat-box"
          >
            <div
              class="text-2xl md:text-2xl font-semibold text-primary-600 dark:text-primary-400 mb-2"
            >
              <span v-if="isLoadingPlatformStats">
                <USkeleton class="h-8 w-16 mx-auto" />
              </span>
              <span v-else>{{ platformStats.active_referrers }}+</span>
            </div>
            <p class="text-sm md:text-base text-gray-500 dark:text-gray-500">
              Active Referrers
            </p>
          </div>

          <div
            class="bg-white dark:bg-gray-800 rounded-xl p-6 shadow-sm border border-gray-100 dark:border-gray-700 text-center stat-box"
          >
            <div
              class="text-2xl md:text-2xl font-semibold text-primary-600 dark:text-primary-400 mb-2"
            >
              <span v-if="isLoadingPlatformStats">
                <USkeleton class="h-8 w-20 mx-auto" />
              </span>
              <span v-else>৳ {{ platformStats.top_earner_amount.toLocaleString() }}</span>
            </div>
            <p class="text-sm md:text-base text-gray-500 dark:text-gray-500">
              Top Earner
            </p>
          </div>

          <div
            class="bg-white dark:bg-gray-800 rounded-xl p-6 shadow-sm border border-gray-100 dark:border-gray-700 text-center stat-box"
          >
            <div
              class="text-2xl md:text-2xl font-semibold text-primary-600 dark:text-primary-400 mb-2"
            >
              <span v-if="isLoadingPlatformStats">
                <USkeleton class="h-8 w-12 mx-auto" />
              </span>
              <span v-else>{{ platformStats.quick_payout_time }}</span>
            </div>
            <p class="text-sm md:text-base text-gray-500 dark:text-gray-500">
              Quick Payouts
            </p>
          </div>
        </div>
      </div>

      <!-- CTA Section -->
      <div class="max-w-4xl mx-auto text-center">
        <div
          class="bg-gradient-to-r from-primary-500 to-primary-600 rounded-xl p-8 md:p-12 shadow-sm cta-section"
        >
          <h2 class="text-xl md:text-2xl font-semibold text-white mb-4">
            Ready to Start Earning?
          </h2>
          <p class="text-white/90 mb-8 max-w-2xl mx-auto">
            Join our referral program today and turn your connections into
            cash. It's free to join and only takes a minute to get started.
          </p>
          <UButton
            size="xl"
            color="white"
            variant="solid"
            to="/auth/register"
            class="cta-button-final"
          >
            Create Your Account
            <template #trailing>
              <UIcon name="i-heroicons-arrow-right" />
            </template>
          </UButton>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
defineProps({
  platformStats: {
    type: Object,
    required: true
  },
  isLoadingPlatformStats: {
    type: Boolean,
    default: false
  }
})

const emit = defineEmits(['get-platform-stats'])

onMounted(() => {
  // Fetch platform stats when component mounts
  emit('get-platform-stats')
})
</script>

<style scoped>
/* Add component-specific styles if needed */
.cta-section {
  position: relative;
  overflow: hidden;
}

.cta-section::before {
  content: "";
  position: absolute;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background: linear-gradient(-45deg, transparent 40%, rgba(255, 255, 255, 0.1) 50%, transparent 60%);
  transform: translateX(-100%);
  animation: shimmer 3s infinite;
}

@keyframes shimmer {
  0% {
    transform: translateX(-100%);
  }
  100% {
    transform: translateX(100%);
  }
}

.step-card {
  transition: all 0.3s ease;
}

.step-card:hover {
  transform: translateY(-5px);
  box-shadow: 0 10px 25px rgba(0, 0, 0, 0.1);
}

.stat-box {
  transition: all 0.3s ease;
}

.stat-box:hover {
  transform: translateY(-2px);
  box-shadow: 0 5px 15px rgba(0, 0, 0, 0.1);
}

.cta-button {
  transition: all 0.3s ease;
}

.cta-button:hover {
  transform: translateY(-2px);
  box-shadow: 0 7px 14px rgba(0, 0, 0, 0.1), 0 3px 6px rgba(0, 0, 0, 0.08);
}

.cta-button-secondary {
  transition: all 0.3s ease;
}

.cta-button-secondary:hover {
  transform: translateY(-2px);
  box-shadow: 0 7px 14px rgba(0, 0, 0, 0.1), 0 3px 6px rgba(0, 0, 0, 0.08);
}

.cta-button-final {
  position: relative;
  overflow: hidden;
  transition: all 0.3s ease;
}

.cta-button-final:hover {
  transform: translateY(-2px);
  box-shadow: 0 7px 14px rgba(0, 0, 0, 0.1), 0 3px 6px rgba(0, 0, 0, 0.08);
}

@keyframes float-slow {
  0%, 100% {
    transform: translateY(0px) rotate(0deg);
  }
  50% {
    transform: translateY(-20px) rotate(180deg);
  }
}

@keyframes float-reverse {
  0%, 100% {
    transform: translateY(0px) rotate(0deg);
  }
  50% {
    transform: translateY(20px) rotate(-180deg);
  }
}

@keyframes fade-in {
  from {
    opacity: 0;
    transform: translateY(20px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}

@keyframes fade-in-delayed {
  from {
    opacity: 0;
    transform: translateY(20px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}

@keyframes expand {
  from {
    width: 0;
  }
  to {
    width: 5rem;
  }
}

.animate-float-slow {
  animation: float-slow 8s ease-in-out infinite;
}

.animate-float-reverse {
  animation: float-reverse 6s ease-in-out infinite;
}

.animate-fade-in {
  animation: fade-in 0.6s ease-out;
}

.animate-fade-in-delayed {
  animation: fade-in-delayed 0.8s ease-out 0.2s both;
}

.animate-expand {
  animation: expand 1s ease-out 0.5s both;
}
</style>
