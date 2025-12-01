<template>
  <div v-if="program && program.active" class="mb-10">
    <!-- New Year Banner -->
    <div class="relative overflow-hidden rounded-2xl bg-gradient-to-br from-emerald-600 via-emerald-500 to-teal-500 p-6 md:p-8 text-white shadow-xl">
      <!-- Decorative elements -->
      <div class="absolute top-0 right-0 w-40 h-40 bg-white/10 rounded-full -translate-y-1/2 translate-x-1/2"></div>
      <div class="absolute bottom-0 left-0 w-32 h-32 bg-white/10 rounded-full translate-y-1/2 -translate-x-1/2"></div>
      <div class="absolute top-4 left-4 text-4xl animate-bounce">🎉</div>
      <div class="absolute top-4 right-4 text-4xl animate-bounce" style="animation-delay: 0.5s">🎊</div>
      
      <div class="relative z-10 text-center">
        <div class="inline-flex items-center gap-2 bg-white/20 backdrop-blur-sm rounded-full px-4 py-1.5 mb-4">
          <span class="text-yellow-300 text-lg">✨</span>
          <span class="text-sm font-semibold">{{ program.program?.name || 'New Year 2025 Special' }}</span>
          <span class="text-yellow-300 text-lg">✨</span>
        </div>
        
        <h2 class="text-2xl md:text-3xl font-bold mb-2">
          Refer Friends & Earn Rewards!
        </h2>
        <p class="text-white/90 text-sm md:text-base mb-4 max-w-lg mx-auto">
          {{ program.program?.description || 'Invite friends and both of you earn rewards when they complete simple tasks!' }}
        </p>
        <p class="text-white/80 text-sm mb-2">
          You earn <span class="font-bold text-yellow-300">৳{{ program.program?.referrer_reward || 100 }}</span> • 
          Friend earns <span class="font-bold text-yellow-300">৳{{ program.program?.referee_reward || 50 }}</span>
        </p>
        
        <div class="flex flex-wrap justify-center gap-4 mb-6">
          <div class="bg-white/20 backdrop-blur-sm rounded-xl px-5 py-4 text-center min-w-[140px]">
            <div class="text-3xl font-bold">৳{{ program.program?.referrer_reward || 100 }}</div>
            <div class="text-xs text-white/80 mt-1">You Earn (Referrer)</div>
          </div>
          <div class="bg-white/20 backdrop-blur-sm rounded-xl px-5 py-4 text-center min-w-[140px]">
            <div class="text-3xl font-bold">৳{{ program.program?.referee_reward || 50 }}</div>
            <div class="text-xs text-white/80 mt-1">Friend Earns (Referee)</div>
          </div>
        </div>
      </div>
    </div>

    <!-- Reward Status Card (for users who were referred) -->
    <div v-if="conditions" class="mt-6 bg-white dark:bg-gray-800 rounded-xl p-6 shadow-sm border border-gray-100 dark:border-gray-700">
      <div class="flex items-center justify-between mb-4">
        <h3 class="text-lg font-semibold text-gray-800 dark:text-white flex items-center gap-2">
          <span class="text-2xl">🎁</span>
          Your Reward Progress
        </h3>
        <div v-if="conditions.reward_info?.is_referee" class="text-right">
          <span class="text-sm text-gray-500">Referred by:</span>
          <span class="ml-1 font-medium text-emerald-600">{{ conditions.reward_info.referrer_name }}</span>
        </div>
      </div>

      <!-- Tasks Left Indicator -->
      <div class="mb-6 p-4 rounded-xl" :class="remainingTasks === 0 ? 'bg-emerald-50 dark:bg-emerald-900/20 border border-emerald-200' : 'bg-amber-50 dark:bg-amber-900/20 border border-amber-200'">
        <div class="flex items-center justify-between">
          <div class="flex items-center gap-3">
            <div class="w-12 h-12 rounded-full flex items-center justify-center" :class="remainingTasks === 0 ? 'bg-emerald-500' : 'bg-amber-500'">
              <span class="text-white text-xl font-bold">{{ remainingTasks }}</span>
            </div>
            <div>
              <div class="font-semibold" :class="remainingTasks === 0 ? 'text-emerald-700' : 'text-amber-700'">
                {{ remainingTasks === 0 ? '🎉 All Tasks Completed!' : `${remainingTasks} Task${remainingTasks > 1 ? 's' : ''} Remaining` }}
              </div>
              <div class="text-sm" :class="remainingTasks === 0 ? 'text-emerald-600' : 'text-amber-600'">
                {{ remainingTasks === 0 ? 'You can now claim your reward!' : 'Complete the tasks below to unlock your reward' }}
              </div>
            </div>
          </div>
          <div class="text-right">
            <div class="text-2xl font-bold" :class="remainingTasks === 0 ? 'text-emerald-600' : 'text-gray-400'">
              ৳{{ conditions.reward_info?.reward_amount || program.program?.referee_reward || 50 }}
            </div>
            <div class="text-xs text-gray-500">Reward</div>
          </div>
        </div>
      </div>

      <!-- Conditions Progress -->
      <div class="space-y-3 mb-6">
        <!-- Condition 1: Business Network Post -->
        <div class="flex items-center gap-4 p-4 rounded-xl border transition-all" :class="conditions.conditions?.has_posted_bn ? 'bg-emerald-50 dark:bg-emerald-900/20 border-emerald-200' : 'bg-gray-50 dark:bg-gray-700/50 border-gray-200 dark:border-gray-600'">
          <div class="w-12 h-12 rounded-full flex items-center justify-center transition-all" :class="conditions.conditions?.has_posted_bn ? 'bg-emerald-500 text-white' : 'bg-gray-200 dark:bg-gray-600 text-gray-500'">
            <UIcon :name="conditions.conditions?.has_posted_bn ? 'i-heroicons-check' : 'i-heroicons-document-text'" class="text-xl" />
          </div>
          <div class="flex-1">
            <div class="font-semibold text-gray-800 dark:text-white">Post on Business Network</div>
            <div class="text-sm text-gray-500">Create at least 1 post to share with the community</div>
          </div>
          <div class="text-right">
            <UBadge :color="conditions.conditions?.has_posted_bn ? 'green' : 'yellow'" variant="soft" size="md">
              {{ conditions.conditions?.has_posted_bn ? '✓ Completed' : 'Pending' }}
            </UBadge>
            <NuxtLink v-if="!conditions.conditions?.has_posted_bn" to="/business-network" class="block mt-1 text-xs text-emerald-600 hover:underline">
              Go to Business Network →
            </NuxtLink>
          </div>
        </div>

        <!-- Condition 2: MicroGig Task -->
        <div class="flex items-center gap-4 p-4 rounded-xl border transition-all" :class="conditions.conditions?.has_completed_microgig ? 'bg-emerald-50 dark:bg-emerald-900/20 border-emerald-200' : 'bg-gray-50 dark:bg-gray-700/50 border-gray-200 dark:border-gray-600'">
          <div class="w-12 h-12 rounded-full flex items-center justify-center transition-all" :class="conditions.conditions?.has_completed_microgig ? 'bg-emerald-500 text-white' : 'bg-gray-200 dark:bg-gray-600 text-gray-500'">
            <UIcon :name="conditions.conditions?.has_completed_microgig ? 'i-heroicons-check' : 'i-heroicons-briefcase'" class="text-xl" />
          </div>
          <div class="flex-1">
            <div class="font-semibold text-gray-800 dark:text-white">Complete a MicroGig Task</div>
            <div class="text-sm text-gray-500">Complete at least 1 task from MicroGigs to earn</div>
          </div>
          <div class="text-right">
            <UBadge :color="conditions.conditions?.has_completed_microgig ? 'green' : 'yellow'" variant="soft" size="md">
              {{ conditions.conditions?.has_completed_microgig ? '✓ Completed' : 'Pending' }}
            </UBadge>
            <NuxtLink v-if="!conditions.conditions?.has_completed_microgig" to="/micro-gigs" class="block mt-1 text-xs text-emerald-600 hover:underline">
              Browse MicroGigs →
            </NuxtLink>
          </div>
        </div>

        <!-- Condition 3: KYC Verification -->
        <div class="flex items-center gap-4 p-4 rounded-xl border transition-all" :class="conditions.conditions?.has_kyc_verified ? 'bg-emerald-50 dark:bg-emerald-900/20 border-emerald-200' : 'bg-gray-50 dark:bg-gray-700/50 border-gray-200 dark:border-gray-600'">
          <div class="w-12 h-12 rounded-full flex items-center justify-center transition-all" :class="conditions.conditions?.has_kyc_verified ? 'bg-emerald-500 text-white' : 'bg-gray-200 dark:bg-gray-600 text-gray-500'">
            <UIcon :name="conditions.conditions?.has_kyc_verified ? 'i-heroicons-check' : 'i-heroicons-identification'" class="text-xl" />
          </div>
          <div class="flex-1">
            <div class="font-semibold text-gray-800 dark:text-white">Verify KYC (NID Upload)</div>
            <div class="text-sm text-gray-500">Upload your NID and get verified for security</div>
          </div>
          <div class="text-right">
            <UBadge :color="conditions.conditions?.has_kyc_verified ? 'green' : 'yellow'" variant="soft" size="md">
              {{ conditions.conditions?.has_kyc_verified ? '✓ Verified' : 'Pending' }}
            </UBadge>
            <NuxtLink v-if="!conditions.conditions?.has_kyc_verified" to="/upload-center" class="block mt-1 text-xs text-emerald-600 hover:underline">
              Verify KYC →
            </NuxtLink>
          </div>
        </div>
      </div>

      <!-- Progress Bar -->
      <div class="mb-6">
        <div class="flex justify-between text-sm mb-2">
          <span class="text-gray-600 dark:text-gray-400">Overall Progress</span>
          <span class="font-semibold" :class="completedCount === 3 ? 'text-emerald-600' : 'text-amber-600'">
            {{ completedCount }}/3 tasks completed
          </span>
        </div>
        <div class="h-3 bg-gray-200 dark:bg-gray-700 rounded-full overflow-hidden">
          <div 
            class="h-full rounded-full transition-all duration-500" 
            :class="completedCount === 3 ? 'bg-gradient-to-r from-emerald-500 to-teal-500' : 'bg-gradient-to-r from-amber-400 to-amber-500'"
            :style="{ width: `${(completedCount / 3) * 100}%` }"
          ></div>
        </div>
      </div>

      <!-- Claim Button or Status -->
      <div v-if="conditions.reward_info?.is_referee" class="text-center">
        <div v-if="conditions.reward_info?.claim_status === 'claimed'" class="p-4 bg-emerald-50 dark:bg-emerald-900/20 rounded-xl">
          <div class="inline-flex items-center gap-2 text-emerald-600 font-semibold text-lg">
            <UIcon name="i-heroicons-check-circle-solid" class="text-2xl" />
            Reward Claimed Successfully!
          </div>
          <p class="text-sm text-emerald-600 mt-1">৳{{ conditions.reward_info?.reward_amount || program.program?.referee_reward }} has been added to your balance</p>
        </div>
        <div v-else-if="conditions.conditions?.all_met" class="space-y-3">
          <div class="p-3 bg-emerald-50 dark:bg-emerald-900/20 rounded-lg text-emerald-700 text-sm">
            🎉 Congratulations! All conditions met. Claim your reward now!
          </div>
          <UButton 
            color="primary" 
            size="xl" 
            class="px-10 py-3"
            :loading="claiming"
            @click="$emit('claim-reward')"
          >
            <UIcon name="i-heroicons-gift" class="mr-2 text-xl" />
            Claim ৳{{ conditions.reward_info?.reward_amount || program.program?.referee_reward }} Reward
          </UButton>
        </div>
        <div v-else class="p-4 bg-gray-50 dark:bg-gray-700/50 rounded-xl">
          <p class="text-gray-600 dark:text-gray-400">
            Complete <span class="font-semibold text-amber-600">{{ remainingTasks }} more task{{ remainingTasks > 1 ? 's' : '' }}</span> to unlock your 
            <span class="font-semibold text-emerald-600">৳{{ conditions.reward_info?.reward_amount || program.program?.referee_reward }}</span> reward
          </p>
        </div>
      </div>
    </div>

    <!-- My Referral Claims Section (for referrers) -->
    <div v-if="claims?.claims?.length > 0" class="mt-6 bg-white dark:bg-gray-800 rounded-xl p-6 shadow-sm border border-gray-100 dark:border-gray-700">
      <h3 class="text-lg font-semibold text-gray-800 dark:text-white mb-4 flex items-center gap-2">
        <span class="text-2xl">💰</span>
        Your Referral Rewards (As Referrer)
      </h3>
      
      <div class="space-y-4">
        <div v-for="claim in claims.claims" :key="claim.id" class="p-4 rounded-xl border" :class="claim.status === 'claimed' ? 'bg-emerald-50 border-emerald-200' : claim.all_met ? 'bg-blue-50 border-blue-200' : 'bg-gray-50 border-gray-200'">
          <div class="flex items-center justify-between mb-3">
            <div class="flex items-center gap-3">
              <div class="w-10 h-10 rounded-full flex items-center justify-center" :class="claim.status === 'claimed' ? 'bg-emerald-500' : claim.all_met ? 'bg-blue-500' : 'bg-gray-300'">
                <UIcon :name="claim.status === 'claimed' ? 'i-heroicons-check' : 'i-heroicons-user-plus'" class="text-white" />
              </div>
              <div>
                <div class="font-semibold text-gray-800 dark:text-white">
                  {{ claim.claim_type === 'referrer' ? `Referred: ${claim.referred_user?.name || 'User'}` : 'Your Referee Reward' }}
                </div>
                <div class="text-xs text-gray-500">
                  {{ claim.status === 'claimed' ? 'Reward claimed' : claim.all_met ? 'Ready to claim!' : 'Waiting for friend to complete tasks' }}
                </div>
              </div>
            </div>
            <div class="text-right">
              <div class="text-xl font-bold" :class="claim.status === 'claimed' ? 'text-emerald-600' : claim.all_met ? 'text-blue-600' : 'text-gray-400'">
                ৳{{ claim.reward_amount }}
              </div>
              <UBadge :color="getStatusColor(claim.status)" variant="soft" size="xs">
                {{ getStatusLabel(claim.status) }}
              </UBadge>
            </div>
          </div>
          
          <!-- Friend's Task Progress (for referrer claims) -->
          <div v-if="claim.claim_type === 'referrer' && claim.status !== 'claimed'" class="mt-3 pt-3 border-t border-gray-200">
            <div class="text-xs text-gray-500 mb-2">Friend's Progress:</div>
            <div class="flex items-center gap-2">
              <div class="flex-1 flex items-center gap-1">
                <div class="w-6 h-6 rounded-full flex items-center justify-center text-xs" :class="claim.conditions?.has_posted_bn ? 'bg-emerald-500 text-white' : 'bg-gray-200 text-gray-500'">
                  <UIcon :name="claim.conditions?.has_posted_bn ? 'i-heroicons-check' : 'i-heroicons-document-text'" class="w-3 h-3" />
                </div>
                <span class="text-xs" :class="claim.conditions?.has_posted_bn ? 'text-emerald-600' : 'text-gray-400'">Post</span>
              </div>
              <div class="flex-1 flex items-center gap-1">
                <div class="w-6 h-6 rounded-full flex items-center justify-center text-xs" :class="claim.conditions?.has_completed_microgig ? 'bg-emerald-500 text-white' : 'bg-gray-200 text-gray-500'">
                  <UIcon :name="claim.conditions?.has_completed_microgig ? 'i-heroicons-check' : 'i-heroicons-briefcase'" class="w-3 h-3" />
                </div>
                <span class="text-xs" :class="claim.conditions?.has_completed_microgig ? 'text-emerald-600' : 'text-gray-400'">Task</span>
              </div>
              <div class="flex-1 flex items-center gap-1">
                <div class="w-6 h-6 rounded-full flex items-center justify-center text-xs" :class="claim.conditions?.has_kyc_verified ? 'bg-emerald-500 text-white' : 'bg-gray-200 text-gray-500'">
                  <UIcon :name="claim.conditions?.has_kyc_verified ? 'i-heroicons-check' : 'i-heroicons-identification'" class="w-3 h-3" />
                </div>
                <span class="text-xs" :class="claim.conditions?.has_kyc_verified ? 'text-emerald-600' : 'text-gray-400'">KYC</span>
              </div>
              <div class="text-xs font-medium" :class="claim.all_met ? 'text-emerald-600' : 'text-amber-600'">
                {{ getClaimTasksRemaining(claim) === 0 ? '✓ All done!' : `${getClaimTasksRemaining(claim)} left` }}
              </div>
            </div>
            
            <!-- Claim Button for eligible referrer rewards -->
            <div v-if="claim.all_met && claim.status === 'eligible'" class="mt-3 text-center">
              <UButton 
                color="primary" 
                size="sm"
                :loading="claiming"
                @click="$emit('claim-reward', claim.id)"
              >
                <UIcon name="i-heroicons-gift" class="mr-1" />
                Claim ৳{{ claim.reward_amount }}
              </UButton>
            </div>
          </div>
        </div>
      </div>
      
      <!-- Summary -->
      <div class="mt-4 grid grid-cols-2 gap-4">
        <div class="p-4 bg-emerald-50 dark:bg-emerald-900/20 rounded-xl text-center">
          <div class="text-sm text-emerald-700 dark:text-emerald-300">Total Claimed</div>
          <div class="text-2xl font-bold text-emerald-600">৳{{ claims.total_claimed || 0 }}</div>
        </div>
        <div class="p-4 bg-blue-50 dark:bg-blue-900/20 rounded-xl text-center">
          <div class="text-sm text-blue-700 dark:text-blue-300">Ready to Claim</div>
          <div class="text-2xl font-bold text-blue-600">৳{{ claims.total_claimable || 0 }}</div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
const props = defineProps({
  program: Object,
  conditions: Object,
  claims: Object,
  claiming: Boolean,
})

defineEmits(['claim-reward'])

// Computed: Count of completed tasks
const completedCount = computed(() => {
  if (!props.conditions?.conditions) return 0
  const c = props.conditions.conditions
  return [c.has_posted_bn, c.has_completed_microgig, c.has_kyc_verified].filter(Boolean).length
})

// Computed: Remaining tasks count
const remainingTasks = computed(() => {
  return 3 - completedCount.value
})

// Get status badge color
function getStatusColor(status) {
  const colors = {
    pending: 'yellow',
    eligible: 'blue',
    claimed: 'green',
  }
  return colors[status] || 'gray'
}

// Get status label text
function getStatusLabel(status) {
  const labels = {
    pending: 'Waiting',
    eligible: 'Ready to Claim',
    claimed: 'Claimed',
  }
  return labels[status] || status
}

// Get remaining tasks for a specific claim
function getClaimTasksRemaining(claim) {
  if (!claim?.conditions) return 3
  const c = claim.conditions
  const completed = [c.has_posted_bn, c.has_completed_microgig, c.has_kyc_verified].filter(Boolean).length
  return 3 - completed
}
</script>
