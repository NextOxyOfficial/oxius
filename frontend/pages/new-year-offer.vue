<template>
  <div class="min-h-screen bg-gradient-to-br from-emerald-50 via-white to-teal-50">
    <!-- Hero Section -->
    <div class="relative overflow-hidden">
      <!-- Background decorations -->
      <div class="absolute inset-0 overflow-hidden pointer-events-none">
        <div class="absolute -top-40 -right-40 w-80 h-80 bg-emerald-200/30 rounded-full blur-3xl"></div>
        <div class="absolute -bottom-40 -left-40 w-80 h-80 bg-teal-200/30 rounded-full blur-3xl"></div>
        <div class="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-[600px] h-[600px] bg-yellow-100/20 rounded-full blur-3xl"></div>
      </div>

      <div class="relative container mx-auto px-4 py-16 md:py-24">
        <!-- Floating emojis -->
        <div class="absolute top-10 left-10 text-5xl animate-bounce" style="animation-delay: 0s;">🎉</div>
        <div class="absolute top-20 right-20 text-4xl animate-bounce" style="animation-delay: 0.5s;">🎊</div>
        <div class="absolute bottom-20 left-20 text-4xl animate-bounce" style="animation-delay: 1s;">✨</div>
        <div class="absolute bottom-10 right-10 text-5xl animate-bounce" style="animation-delay: 1.5s;">🎁</div>

        <div class="max-w-4xl mx-auto text-center">
          <!-- Badge -->
          <div class="inline-flex items-center gap-2 bg-gradient-to-r from-emerald-500 to-teal-500 text-white rounded-full px-6 py-2 mb-6 shadow-lg">
            <span class="text-yellow-300">✨</span>
            <span class="font-semibold">{{ program?.program?.name || 'New Year 2025 Special Offer' }}</span>
            <span class="text-yellow-300">✨</span>
          </div>

          <!-- Main Heading -->
          <h1 class="text-4xl md:text-6xl font-bold text-gray-800 mb-6">
            Refer Friends & 
            <span class="text-transparent bg-clip-text bg-gradient-to-r from-emerald-600 to-teal-600">
              Earn ৳{{ program?.program?.referrer_reward || 50 }}
            </span>
            Each!
          </h1>

          <p class="text-xl text-gray-600 mb-8 max-w-2xl mx-auto">
            Celebrate the New Year with us! Invite your friends to join AdsyClub and both of you earn rewards when they complete simple tasks.
          </p>

          <!-- Reward Cards -->
          <div class="flex flex-wrap justify-center gap-6 mb-10">
            <div class="bg-white rounded-2xl p-6 shadow-xl border-2 border-emerald-200 min-w-[200px]">
              <div class="text-4xl mb-2">👤</div>
              <div class="text-sm text-gray-500 mb-1">You Earn</div>
              <div class="text-3xl font-bold text-emerald-600">৳{{ program?.program?.referrer_reward || 50 }}</div>
            </div>
            <div class="bg-white rounded-2xl p-6 shadow-xl border-2 border-teal-200 min-w-[200px]">
              <div class="text-4xl mb-2">👥</div>
              <div class="text-sm text-gray-500 mb-1">Friend Earns</div>
              <div class="text-3xl font-bold text-teal-600">৳{{ program?.program?.referee_reward || 50 }}</div>
            </div>
          </div>

          <!-- CTA Buttons -->
          <div class="flex flex-wrap justify-center gap-4">
            <UButton
              v-if="!user?.user"
              size="xl"
              color="primary"
              to="/auth/register"
              class="px-8 py-4 text-lg shadow-lg hover:shadow-xl transition-all"
            >
              🚀 Join Now & Start Earning
            </UButton>
            <UButton
              v-else
              size="xl"
              color="primary"
              to="/refer-a-friend"
              class="px-8 py-4 text-lg shadow-lg hover:shadow-xl transition-all"
            >
              🎁 Start Referring Friends
            </UButton>
          </div>
        </div>
      </div>
    </div>

    <!-- How It Works Section -->
    <div class="bg-white py-16">
      <div class="container mx-auto px-4">
        <div class="text-center mb-12">
          <h2 class="text-3xl font-bold text-gray-800 mb-4">How It Works</h2>
          <div class="h-1 w-20 bg-gradient-to-r from-emerald-500 to-teal-500 mx-auto rounded-full"></div>
        </div>

        <div class="max-w-5xl mx-auto grid md:grid-cols-3 gap-8">
          <!-- Step 1 -->
          <div class="text-center">
            <div class="w-20 h-20 mx-auto mb-4 rounded-full bg-gradient-to-br from-emerald-100 to-teal-100 flex items-center justify-center">
              <span class="text-3xl">1️⃣</span>
            </div>
            <h3 class="text-xl font-semibold text-gray-800 mb-2">Share Your Link</h3>
            <p class="text-gray-600">Get your unique referral link and share it with friends via social media, WhatsApp, or email.</p>
          </div>

          <!-- Step 2 -->
          <div class="text-center">
            <div class="w-20 h-20 mx-auto mb-4 rounded-full bg-gradient-to-br from-emerald-100 to-teal-100 flex items-center justify-center">
              <span class="text-3xl">2️⃣</span>
            </div>
            <h3 class="text-xl font-semibold text-gray-800 mb-2">Friend Completes Tasks</h3>
            <p class="text-gray-600">Your friend signs up and completes 3 simple tasks: Post, Complete a task, Verify KYC.</p>
          </div>

          <!-- Step 3 -->
          <div class="text-center">
            <div class="w-20 h-20 mx-auto mb-4 rounded-full bg-gradient-to-br from-emerald-100 to-teal-100 flex items-center justify-center">
              <span class="text-3xl">3️⃣</span>
            </div>
            <h3 class="text-xl font-semibold text-gray-800 mb-2">Both Earn Rewards!</h3>
            <p class="text-gray-600">Once conditions are met, both you and your friend can claim your rewards instantly!</p>
          </div>
        </div>
      </div>
    </div>

    <!-- Conditions Section -->
    <div class="py-16 bg-gradient-to-br from-emerald-50 to-teal-50">
      <div class="container mx-auto px-4">
        <div class="max-w-3xl mx-auto">
          <div class="text-center mb-10">
            <h2 class="text-3xl font-bold text-gray-800 mb-4">Simple Conditions to Earn</h2>
            <p class="text-gray-600">Your referred friend needs to complete these 3 easy tasks:</p>
          </div>

          <div class="space-y-4">
            <!-- Condition 1 -->
            <div class="bg-white rounded-xl p-6 shadow-md flex items-center gap-4">
              <div class="w-14 h-14 rounded-full bg-emerald-100 flex items-center justify-center flex-shrink-0">
                <UIcon name="i-heroicons-document-text" class="text-2xl text-emerald-600" />
              </div>
              <div>
                <h3 class="font-semibold text-gray-800">Post on Business Network</h3>
                <p class="text-sm text-gray-500">Create at least 1 post on the Business Network</p>
              </div>
              <UBadge color="emerald" variant="soft" class="ml-auto">Easy</UBadge>
            </div>

            <!-- Condition 2 -->
            <div class="bg-white rounded-xl p-6 shadow-md flex items-center gap-4">
              <div class="w-14 h-14 rounded-full bg-teal-100 flex items-center justify-center flex-shrink-0">
                <UIcon name="i-heroicons-briefcase" class="text-2xl text-teal-600" />
              </div>
              <div>
                <h3 class="font-semibold text-gray-800">Complete a MicroGig Task</h3>
                <p class="text-sm text-gray-500">Complete at least 1 task from MicroGigs</p>
              </div>
              <UBadge color="teal" variant="soft" class="ml-auto">Easy</UBadge>
            </div>

            <!-- Condition 3 -->
            <div class="bg-white rounded-xl p-6 shadow-md flex items-center gap-4">
              <div class="w-14 h-14 rounded-full bg-blue-100 flex items-center justify-center flex-shrink-0">
                <UIcon name="i-heroicons-identification" class="text-2xl text-blue-600" />
              </div>
              <div>
                <h3 class="font-semibold text-gray-800">Verify KYC (NID Upload)</h3>
                <p class="text-sm text-gray-500">Upload NID and get verified for security</p>
              </div>
              <UBadge color="blue" variant="soft" class="ml-auto">Required</UBadge>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- Final CTA Section -->
    <div class="py-16 bg-gradient-to-r from-emerald-600 to-teal-600 text-white">
      <div class="container mx-auto px-4 text-center">
        <h2 class="text-3xl md:text-4xl font-bold mb-4">
          🎉 Don't Miss This New Year Offer!
        </h2>
        <p class="text-xl text-white/90 mb-8 max-w-2xl mx-auto">
          Limited time offer! Start referring friends today and earn unlimited rewards.
        </p>
        <UButton
          v-if="!user?.user"
          size="xl"
          color="white"
          to="/auth/register"
          class="px-10 py-4 text-lg"
        >
          Get Started Now →
        </UButton>
        <UButton
          v-else
          size="xl"
          color="white"
          to="/refer-a-friend"
          class="px-10 py-4 text-lg"
        >
          Go to Refer & Earn →
        </UButton>
      </div>
    </div>
  </div>
</template>

<script setup>
definePageMeta({
  layout: "default",
});

const { user } = useAuth();
const { get } = useApi();

const program = ref(null);

async function getRewardProgram() {
  try {
    const res = await get("/referral-rewards/program/");
    if (res?.data) {
      program.value = res.data;
    }
  } catch (error) {
    console.error("Error fetching reward program:", error);
  }
}

onMounted(() => {
  getRewardProgram();
});
</script>

<style scoped>
@keyframes bounce {
  0%, 100% {
    transform: translateY(0);
  }
  50% {
    transform: translateY(-10px);
  }
}

.animate-bounce {
  animation: bounce 2s ease-in-out infinite;
}
</style>
