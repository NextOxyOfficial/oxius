<template>
  <div class="group bg-white dark:bg-slate-800/80 rounded-2xl overflow-hidden border border-slate-200/80 dark:border-slate-700/60 hover:border-purple-300 dark:hover:border-purple-600/50 transition-all duration-300 shadow-sm hover:shadow-xl hover:shadow-slate-200/50 dark:hover:shadow-slate-900/50 h-[540px] flex flex-col">
    <!-- Video Thumbnail -->
    <button
      type="button"
      class="w-full text-left relative"
      @click="openPitch(plan)"
    >
      <div class="relative aspect-[16/9] bg-slate-100 dark:bg-slate-700 overflow-hidden">
        <img
          :src="plan.thumbnail"
          :alt="plan.title"
          class="w-full h-full object-cover group-hover:scale-105 transition-transform duration-500"
        />
        <div class="absolute inset-0 bg-gradient-to-t from-black/60 via-black/20 to-transparent"></div>

        <!-- Stage Badge -->
        <div class="absolute top-3 right-3">
          <span
            class="inline-flex items-center px-2.5 py-1 rounded-full text-xs font-bold uppercase tracking-wide shadow-lg"
            :class="{
              'bg-emerald-500 text-white': plan.stageColor === 'emerald',
              'bg-blue-500 text-white': plan.stageColor === 'blue',
              'bg-purple-500 text-white': plan.stageColor === 'purple',
              'bg-amber-500 text-white': plan.stageColor === 'amber'
            }"
          >
            {{ plan.stage }}
          </span>
        </div>

        <!-- Play Button -->
        <div class="absolute inset-0 flex items-center justify-center">
          <div class="w-16 h-16 rounded-full bg-white/95 dark:bg-slate-900/95 flex items-center justify-center shadow-2xl group-hover:scale-110 transition-transform duration-300">
            <UIcon name="i-heroicons-play-solid" class="w-7 h-7 text-purple-600 dark:text-purple-400 ml-1" />
          </div>
        </div>

        <!-- Raised Amount Overlay -->
        <div class="absolute bottom-3 left-3 right-3">
          <div class="flex items-center justify-between text-white text-xs">
            <span class="font-medium bg-black/40 backdrop-blur-sm px-2 py-1 rounded-full">{{ progressPercent }}% funded</span>
            <span class="font-bold bg-purple-500/90 backdrop-blur-sm px-2 py-1 rounded-full">৳{{ plan.raised.toLocaleString() }}</span>
          </div>
        </div>
      </div>
    </button>

    <!-- Card Content -->
    <div class="p-4 flex flex-col flex-1">
      <!-- Title & Tags -->
      <div>
        <h3 class="text-base font-bold text-gray-900 dark:text-white leading-snug line-clamp-2 mb-2">
          {{ plan.title }}
        </h3>
        <div class="flex items-center justify-between gap-2">
          <span
            class="inline-flex items-center gap-1 px-2 py-0.5 rounded-md text-[11px] font-bold"
            :class="riskBadgeClass"
          >
            {{ plan.riskLevel }} Risk
          </span>
          <span class="inline-flex items-center gap-1 text-[11px] font-medium text-slate-500 dark:text-slate-400">
            <UIcon name="i-heroicons-map-pin" class="w-3 h-3" />
            {{ plan.city }}, {{ plan.area }}
          </span>
        </div>
      </div>

      <!-- Founder Info -->
      <div class="mt-3 flex items-center justify-between gap-2 py-2 border-t border-b border-slate-100 dark:border-slate-700/50">
        <div class="flex items-center gap-2.5 min-w-0">
          <NuxtLink :to="`/business-network/profile/${plan.poster.id}`" class="shrink-0">
            <img
              :src="plan.poster.avatar"
              :alt="plan.poster.name"
              class="w-9 h-9 rounded-full object-cover ring-2 ring-white dark:ring-slate-700 shadow-md"
            />
          </NuxtLink>
          <div class="min-w-0">
            <div class="flex items-center gap-1.5 flex-wrap">
              <NuxtLink
                :to="`/business-network/profile/${plan.poster.id}`"
                class="text-sm font-semibold text-slate-800 dark:text-slate-100 hover:text-purple-600 dark:hover:text-purple-400 transition"
              >
                {{ plan.poster.name }}
              </NuxtLink>
              <UIcon
                v-if="plan.poster.kyc"
                name="i-heroicons-check-badge-solid"
                class="w-4 h-4 text-blue-500 shrink-0"
              />
              <div
                v-if="plan.poster.is_pro"
                class="shrink-0 bg-gradient-to-r from-amber-400 to-orange-500 text-white rounded px-1.5 py-0.5 text-[9px] font-bold shadow-sm"
              >
                PRO
              </div>
              <button
                type="button"
                class="shrink-0 hover:scale-110 transition-transform"
                @click.stop="openChat(plan.poster)"
                aria-label="Chat"
              >
                <img
                  src="https://adsyclub.com/static/frontend/images/chat_icon.png"
                  alt="Chat"
                  class="w-5 h-5"
                />
              </button>
            </div>
            <div class="text-xs text-slate-500 dark:text-slate-400 truncate">
              {{ plan.poster.profession }}
            </div>
          </div>
        </div>
        <div class="shrink-0 text-right">
          <div class="text-[10px] text-slate-400 dark:text-slate-500 uppercase tracking-wide">Traction</div>
          <div class="text-xs font-bold text-purple-600 dark:text-purple-400">{{ plan.traction }}</div>
        </div>
      </div>

      <!-- Summary -->
      <p class="mt-2 text-xs text-slate-600 dark:text-slate-400 line-clamp-2 leading-relaxed">
        {{ plan.summary }}
      </p>

      <!-- Stats Grid -->
      <div class="mt-3 grid grid-cols-3 gap-2">
        <div class="text-center p-2 rounded-xl bg-gradient-to-br from-slate-50 to-slate-100 dark:from-slate-800 dark:to-slate-700/50">
          <div class="text-[10px] text-slate-500 dark:text-slate-400 uppercase tracking-wide">Target</div>
          <div class="text-xs font-bold text-slate-800 dark:text-slate-100">৳{{ (plan.goal / 1000).toFixed(0) }}K</div>
        </div>
        <div class="text-center p-2 rounded-xl bg-gradient-to-br from-slate-50 to-slate-100 dark:from-slate-800 dark:to-slate-700/50">
          <div class="text-[10px] text-slate-500 dark:text-slate-400 uppercase tracking-wide">Min</div>
          <div class="text-xs font-bold text-slate-800 dark:text-slate-100">৳{{ (plan.minInvestment / 1000).toFixed(0) }}K</div>
        </div>
        <div class="text-center p-2 rounded-xl bg-gradient-to-br from-purple-50 to-indigo-50 dark:from-purple-900/30 dark:to-indigo-900/30">
          <div class="text-[10px] text-purple-600 dark:text-purple-400 uppercase tracking-wide">Return</div>
          <div class="text-xs font-bold text-purple-700 dark:text-purple-300">{{ plan.expectedReturn.split(' ')[0] }}</div>
        </div>
      </div>

      <!-- Progress Bar -->
      <div class="mt-3">
        <div class="h-1.5 bg-slate-100 dark:bg-slate-700 rounded-full overflow-hidden">
          <div
            class="h-full bg-gradient-to-r from-purple-500 to-indigo-500 rounded-full transition-all duration-500"
            :style="{ width: `${progressPercent}%` }"
          ></div>
        </div>
      </div>

      <!-- CTA Buttons -->
      <div class="mt-auto pt-3 grid grid-cols-3 gap-2">
        <NuxtLink
          :to="`/raise-up/${plan.id}`"
          class="inline-flex items-center justify-center px-3 py-1.5 rounded-md text-sm font-semibold bg-gray-100 dark:bg-gray-800 text-gray-700 dark:text-gray-300 hover:bg-gray-200 dark:hover:bg-gray-700 transition"
        >
          Details
        </NuxtLink>
        <UButton
          color="purple"
          variant="soft"
          size="sm"
          class="justify-center font-semibold"
          @click.stop="handleDonate(plan)"
        >
          Donate
        </UButton>
        <UButton
          size="sm"
          class="justify-center font-semibold bg-gradient-to-r from-purple-500 to-indigo-600 hover:from-purple-600 hover:to-indigo-700 text-white border-0"
          @click.stop="handleInvest(plan)"
        >
          Invest
        </UButton>
      </div>
    </div>
  </div>
</template>

<script setup>
const props = defineProps({
  plan: {
    type: Object,
    required: true
  }
})

const toast = useToast()
const { user: currentUser } = useAuth()
const { getOrCreateChatRoom } = useAdsyChat()
const router = useRouter()

// Computed properties
const progressPercent = computed(() => {
  const value = Math.round((Number(props.plan.raised || 0) / Number(props.plan.goal || 1)) * 100)
  return Math.max(0, Math.min(100, value))
})

const riskBadgeClass = computed(() => {
  if (props.plan.riskLevel === 'Low') return 'bg-emerald-500/10 text-emerald-700 dark:text-emerald-300'
  if (props.plan.riskLevel === 'Medium') return 'bg-amber-500/10 text-amber-700 dark:text-amber-300'
  return 'bg-rose-500/10 text-rose-700 dark:text-rose-300'
})

// Methods from original carousel
const openPitch = (plan) => {
  router.push(`/raise-up/${plan.id}`)
}

const openChat = async (poster) => {
  if (!poster?.id) return

  if (!currentUser.value) {
    toast.add({
      title: 'Login Required',
      description: 'Please login to send messages',
      color: 'orange',
      timeout: 3000,
    })
    return
  }

  try {
    const room = await getOrCreateChatRoom(poster.id)
    if (room?.id) {
      // Note: Chat slideout functionality would need to be handled by parent component
      toast.add({
        title: 'Chat Feature',
        description: 'Chat functionality needs parent component integration',
        color: 'blue',
      })
    }
  } catch (e) {
    toast.add({
      title: 'Chat Error',
      description: 'Unable to open chat right now',
      color: 'red',
    })
  }
}

const handleDonate = (plan) => {
  if (!plan) return
  toast.add({
    title: 'Donate (Mock)',
    description: `You clicked Donate for: ${plan.title}`,
    color: 'emerald',
  })
}

const handleInvest = (plan) => {
  if (!plan) return
  toast.add({
    title: 'Invest (Mock)',
    description: `You clicked Invest for: ${plan.title}`,
    color: 'blue',
  })
}
</script>
