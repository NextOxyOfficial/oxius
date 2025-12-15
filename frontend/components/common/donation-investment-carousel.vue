<template>
  <section class="py-6 sm:py-10">
    <div class="px-4 sm:px-6 lg:px-8 max-w-7xl mx-auto">
      <!-- Section Header -->
      <div class="flex items-center justify-between gap-3 mb-6">
        <div class="flex items-center gap-3">
          <div class="w-10 h-10 sm:w-12 sm:h-12 rounded-xl sm:rounded-2xl bg-gradient-to-br from-purple-500 to-indigo-600 flex items-center justify-center shadow-lg shadow-purple-500/25">
            <UIcon name="i-heroicons-rocket-launch" class="w-5 h-5 sm:w-6 sm:h-6 text-white" />
          </div>
          <div>
            <h2 class="text-lg sm:text-2xl font-bold text-gray-900 dark:text-white tracking-tight">
              Raise Up
            </h2>
            <p class="text-[10px] sm:text-sm text-slate-500 dark:text-slate-400">
              Support founders through investment or donation
            </p>
          </div>
        </div>
        <div class="flex items-center gap-2">
          <NuxtLink
            to="/raise-up/create"
            class="group inline-flex items-center gap-1 sm:gap-1.5 px-2.5 sm:px-4 py-1.5 sm:py-2 rounded-full border border-purple-300 dark:border-purple-600 text-purple-600 dark:text-purple-400 text-[10px] sm:text-sm font-semibold hover:bg-purple-50 dark:hover:bg-purple-900/20 transition-all duration-200"
          >
            <UIcon name="i-heroicons-plus" class="w-3 h-3 sm:w-4 sm:h-4" />
            <span class="hidden sm:inline">Post Idea</span>
            <span class="sm:hidden">Post</span>
          </NuxtLink>
          <NuxtLink
            to="/raise-up"
            class="group inline-flex items-center gap-1 sm:gap-1.5 px-2.5 sm:px-4 py-1.5 sm:py-2 rounded-full bg-gradient-to-r from-purple-500 to-indigo-600 text-[10px] sm:text-sm font-semibold text-white shadow-lg shadow-purple-500/25 hover:shadow-purple-500/40 hover:scale-[1.02] transition-all duration-200"
          >
            <span>Explore</span>
            <UIcon name="i-heroicons-arrow-right" class="w-3 h-3 sm:w-4 sm:h-4 group-hover:translate-x-0.5 transition-transform" />
          </NuxtLink>
        </div>
      </div>

      <!-- Carousel -->
      <div class="relative">
        <div
          ref="sliderRef"
          class="overflow-x-auto scrollbar-hide scroll-smooth -mx-4 px-1"
          @scroll="updateScrollPosition"
        >
          <div class="flex gap-3 pb-4">
            <div
              v-for="plan in displayedPlans"
              :key="plan.id"
              class="flex-shrink-0 w-[320px] sm:w-[380px]"
            >
              <IdeaCard :plan="plan" />
            </div>
          </div>
        </div>

        <!-- Navigation Arrows -->
        <button
          type="button"
          class="hidden sm:flex absolute top-1/2 -translate-y-1/2 left-0 z-10 w-10 h-10 rounded-full bg-white dark:bg-slate-800 border border-slate-200 dark:border-slate-700 items-center justify-center text-slate-600 dark:text-slate-300 hover:text-purple-600 dark:hover:text-purple-400 hover:border-purple-300 dark:hover:border-purple-600 shadow-lg hover:shadow-xl transition-all duration-200 disabled:opacity-30 disabled:cursor-not-allowed disabled:hover:shadow-lg"
          :disabled="scrollPosition <= 0"
          @click="scrollLeft"
          aria-label="Scroll left"
        >
          <UIcon name="i-heroicons-chevron-left" class="w-5 h-5" />
        </button>

        <button
          type="button"
          class="hidden sm:flex absolute top-1/2 -translate-y-1/2 right-0 z-10 w-10 h-10 rounded-full bg-white dark:bg-slate-800 border border-slate-200 dark:border-slate-700 items-center justify-center text-slate-600 dark:text-slate-300 hover:text-purple-600 dark:hover:text-purple-400 hover:border-purple-300 dark:hover:border-purple-600 shadow-lg hover:shadow-xl transition-all duration-200 disabled:opacity-30 disabled:cursor-not-allowed disabled:hover:shadow-lg"
          :disabled="!canScrollRight"
          @click="scrollRight"
          aria-label="Scroll right"
        >
          <UIcon name="i-heroicons-chevron-right" class="w-5 h-5" />
        </button>
      </div>
    </div>

<ProfileChatSlideout v-model="showChatSlideout" :user="chatUser" :chatroom-id="chatRoomId" />
  </section>
</template>

<script setup>
// Import the IdeaCard component
import IdeaCard from '~/components/raise-up/IdeaCard.vue'

const props = defineProps({
  randomize: { type: Boolean, default: false },
  limit: { type: Number, default: 0 },
})

const toast = useToast()
const { user: currentUser } = useAuth()
const { getOrCreateChatRoom } = useAdsyChat()

// Use shared plans data
const { plans, loading, fetchPlans } = usePlans()

// Fetch plans on component mount
onMounted(() => {
  fetchPlans()
})

const showChatSlideout = ref(false)
const chatRoomId = ref(null)
const chatUser = ref({})

const displayedPlans = computed(() => {
  const list = [...plans.value]

  if (props.randomize) {
    for (let i = list.length - 1; i > 0; i--) {
      const j = Math.floor(Math.random() * (i + 1))
      ;[list[i], list[j]] = [list[j], list[i]]
    }
  }

  if (props.limit && props.limit > 0) return list.slice(0, props.limit)
  return list
})

const sliderRef = ref(null)
const scrollPosition = ref(0)
const canScrollRight = ref(true)

const progress = (plan) => {
  const value = Math.round((Number(plan?.raised || 0) / Number(plan?.goal || 1)) * 100)
  return Math.max(0, Math.min(100, value))
}

const router = useRouter()

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
      chatRoomId.value = room.id
      chatUser.value = { id: poster.id, name: poster.name, image: poster.avatar }
      showChatSlideout.value = true
    }
  } catch (e) {
    toast.add({
      title: 'Chat Error',
      description: 'Unable to open chat right now',
      color: 'red',
    })
  }
}

const riskBadgeClass = (riskLevel) => {
  if (riskLevel === 'Low') {
    return 'bg-emerald-500/10 text-emerald-700 dark:text-emerald-300'
  }
  if (riskLevel === 'Medium') {
    return 'bg-amber-500/10 text-amber-700 dark:text-amber-300'
  }
  return 'bg-rose-500/10 text-rose-700 dark:text-rose-300'
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

const updateScrollPosition = () => {
  const el = sliderRef.value
  if (!el) return

  scrollPosition.value = el.scrollLeft
  const maxScroll = el.scrollWidth - el.clientWidth
  canScrollRight.value = el.scrollLeft < maxScroll - 2
}

const scrollLeft = () => {
  const el = sliderRef.value
  if (!el) return
  el.scrollBy({ left: -360, behavior: 'smooth' })
}

const scrollRight = () => {
  const el = sliderRef.value
  if (!el) return
  el.scrollBy({ left: 360, behavior: 'smooth' })
}

onMounted(() => {
  updateScrollPosition()
})
</script>
