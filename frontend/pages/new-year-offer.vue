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
              Earn Rewards!
            </span>
          </h1>

          <p class="text-xl text-gray-600 mb-4 max-w-2xl mx-auto">
            Celebrate the New Year with us! Invite your friends to join AdsyClub and both of you earn rewards when they complete simple tasks.
          </p>
          <p class="text-lg text-gray-500 mb-8">
            You earn <span class="font-bold text-emerald-600">৳{{ program?.program?.referrer_reward || 100 }}</span> • 
            Friend earns <span class="font-bold text-teal-600">৳{{ program?.program?.referee_reward || 50 }}</span>
          </p>

          <!-- Reward Cards -->
          <div class="flex flex-wrap justify-center gap-6 mb-10">
            <div class="bg-white rounded-2xl p-6 shadow-xl border-2 border-emerald-200 min-w-[200px]">
              <div class="text-4xl mb-2">👤</div>
              <div class="text-sm text-gray-500 mb-1">You Earn</div>
              <div class="text-3xl font-bold text-emerald-600">৳{{ program?.program?.referrer_reward || 100 }}</div>
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

    <!-- Conditions Section - Progress Bar Style -->
    <div class="py-16 bg-gradient-to-br from-emerald-50 to-teal-50">
      <div class="container mx-auto px-4">
        <div class="max-w-4xl mx-auto">
          <div class="text-center mb-12">
            <h2 class="text-3xl font-bold text-gray-800 mb-4">Simple Conditions to Earn</h2>
            <p class="text-gray-600">Your referred friend needs to complete these 3 easy tasks:</p>
          </div>

          <!-- Progress Steps -->
          <div class="bg-white rounded-2xl shadow-lg p-8">
            <!-- Progress Bar -->
            <div class="relative mb-8">
              <!-- Background Line -->
              <div class="absolute top-6 left-0 right-0 h-1 bg-gray-200 rounded-full"></div>
              <!-- Progress Line (animated) -->
              <div class="absolute top-6 left-0 h-1 bg-gradient-to-r from-emerald-500 via-teal-500 to-blue-500 rounded-full transition-all duration-1000" style="width: 100%"></div>
              
              <!-- Step Indicators -->
              <div class="relative flex justify-between">
                <!-- Step 1 -->
                <div class="flex flex-col items-center">
                  <div class="w-12 h-12 rounded-full bg-gradient-to-br from-emerald-500 to-emerald-600 flex items-center justify-center shadow-lg shadow-emerald-200 z-10">
                    <UIcon name="i-heroicons-document-text" class="text-xl text-white" />
                  </div>
                  <div class="mt-4 text-center">
                    <div class="font-semibold text-gray-800 text-sm">Post on BN</div>
                    <div class="text-xs text-gray-500 mt-1 max-w-[100px]">Create 1 post</div>
                  </div>
                </div>

                <!-- Step 2 -->
                <div class="flex flex-col items-center">
                  <div class="w-12 h-12 rounded-full bg-gradient-to-br from-teal-500 to-teal-600 flex items-center justify-center shadow-lg shadow-teal-200 z-10">
                    <UIcon name="i-heroicons-identification" class="text-xl text-white" />
                  </div>
                  <div class="mt-4 text-center">
                    <div class="font-semibold text-gray-800 text-sm">Verify KYC</div>
                    <div class="text-xs text-gray-500 mt-1 max-w-[100px]">Upload NID</div>
                  </div>
                </div>

                <!-- Step 3 -->
                <div class="flex flex-col items-center">
                  <div class="w-12 h-12 rounded-full bg-gradient-to-br from-blue-500 to-blue-600 flex items-center justify-center shadow-lg shadow-blue-200 z-10">
                    <UIcon name="i-heroicons-briefcase" class="text-xl text-white" />
                  </div>
                  <div class="mt-4 text-center">
                    <div class="font-semibold text-gray-800 text-sm">MicroGig Task</div>
                    <div class="text-xs text-gray-500 mt-1 max-w-[100px]">Complete 1 task</div>
                  </div>
                </div>
              </div>
            </div>

            <!-- Detailed Steps List -->
            <div class="mt-8 space-y-3">
              <div class="flex items-center gap-4 p-4 rounded-xl bg-emerald-50 border border-emerald-100">
                <div class="w-8 h-8 rounded-full bg-emerald-500 flex items-center justify-center flex-shrink-0">
                  <span class="text-white font-bold text-sm">1</span>
                </div>
                <div class="flex-1">
                  <span class="font-medium text-gray-800">Post on Business Network</span>
                  <span class="text-gray-500 text-sm ml-2">— Share with the community</span>
                </div>
                <UBadge color="emerald" variant="soft" size="xs">Easy</UBadge>
              </div>

              <div class="flex items-center gap-4 p-4 rounded-xl bg-teal-50 border border-teal-100">
                <div class="w-8 h-8 rounded-full bg-teal-500 flex items-center justify-center flex-shrink-0">
                  <span class="text-white font-bold text-sm">2</span>
                </div>
                <div class="flex-1">
                  <span class="font-medium text-gray-800">Verify KYC (NID Upload)</span>
                  <span class="text-gray-500 text-sm ml-2">— For security & trust</span>
                </div>
                <UBadge color="teal" variant="soft" size="xs">Required</UBadge>
              </div>

              <div class="flex items-center gap-4 p-4 rounded-xl bg-blue-50 border border-blue-100">
                <div class="w-8 h-8 rounded-full bg-blue-500 flex items-center justify-center flex-shrink-0">
                  <span class="text-white font-bold text-sm">3</span>
                </div>
                <div class="flex-1">
                  <span class="font-medium text-gray-800">Complete a MicroGig Task</span>
                  <span class="text-gray-500 text-sm ml-2">— Earn while learning</span>
                </div>
                <UBadge color="blue" variant="soft" size="xs">Easy</UBadge>
              </div>
            </div>

            <!-- Reward Summary -->
            <div class="mt-8 p-4 bg-gradient-to-r from-emerald-500 to-teal-500 rounded-xl text-white text-center">
              <div class="flex items-center justify-center gap-2 mb-1">
                <UIcon name="i-heroicons-gift" class="text-xl" />
                <span class="font-semibold">Complete all 3 tasks = Unlock Reward!</span>
              </div>
              <p class="text-sm text-white/80">Both you and your friend earn rewards when tasks are completed</p>
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
