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
              <div
                class="group bg-white dark:bg-slate-800/80 rounded-2xl overflow-hidden border border-slate-200/80 dark:border-slate-700/60 hover:border-purple-300 dark:hover:border-purple-600/50 transition-all duration-300 shadow-sm hover:shadow-xl hover:shadow-slate-200/50 dark:hover:shadow-slate-900/50 h-[540px] flex flex-col"
              >
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
                        <span class="font-medium bg-black/40 backdrop-blur-sm px-2 py-1 rounded-full">{{ progress(plan) }}% funded</span>
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
                        :class="riskBadgeClass(plan.riskLevel)"
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
                        :style="{ width: `${progress(plan)}%` }"
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
const props = defineProps({
  randomize: { type: Boolean, default: false },
  limit: { type: Number, default: 0 },
})

const toast = useToast()
const { user: currentUser } = useAuth()
const { getOrCreateChatRoom } = useAdsyChat()

const plans = [
  {
    id: 1,
    title: 'Solar Water Purifier Micro-Business',
    poster: {
      id: 101,
      name: 'Nusrat Jahan',
      profession: 'Founder, CleanTech',
      avatar: 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?auto=format&fit=crop&w=256&q=60',
      is_pro: true,
      kyc: true,
    },
    summary:
      'Low-cost solar purification units with local distribution partners. Seeking seed capital + impact donations.',
    sector: 'CleanTech',
    location: 'Rajshahi',
    city: 'Rajshahi',
    area: 'Boalia',
    stage: 'Seed',
    stageColor: 'emerald',
    fundingType: 'Investment + Donation',
    minInvestment: 10000,
    expectedReturn: '12-18% (est.)',
    riskLevel: 'Medium',
    traction: '120 pre-orders',
    raised: 38500,
    goal: 120000,
    thumbnail: 'https://images.unsplash.com/photo-1509395062183-67c5ad6faff9?auto=format&fit=crop&w=1200&q=60',
    videoEmbedUrl: 'https://www.youtube.com/embed/aqz-KE-bpKQ',
    details: {
      overview:
        'We will manufacture solar purifier units and sell through local agents. Donations will subsidize units for ultra-low-income families while investment funds production capacity.',
      useOfFunds: [
        'Production tooling & materials (first 200 units)',
        'Local agent onboarding and sales training',
        'Quality testing and warranty support',
      ],
      milestones: [
        'Month 1: Build 50 units + pilot sales',
        'Month 2-3: Expand to 5 unions + 200 units',
        'Month 4: Break-even target and scale plan',
      ],
    },
  },
  {
    id: 2,
    title: 'Micro-Clinic: Affordable Health Checkups',
    poster: {
      id: 102,
      name: 'Rafi Hasan',
      profession: 'Founder, HealthTech',
      avatar: 'https://images.unsplash.com/photo-1547425260-76bcadfb4f2c?auto=format&fit=crop&w=256&q=60',
      is_pro: false,
      kyc: true,
    },
    summary:
      'A subscription-based micro-clinic model for low-income areas. Looking for investors to scale 3 locations.',
    sector: 'HealthTech',
    location: 'Dhaka',
    city: 'Dhaka',
    area: 'Mirpur',
    stage: 'Growth',
    stageColor: 'blue',
    fundingType: 'Investment',
    minInvestment: 25000,
    expectedReturn: '20-28% (est.)',
    riskLevel: 'Low',
    traction: '1,800 members',
    raised: 76000,
    goal: 250000,
    thumbnail: 'https://images.unsplash.com/photo-1580281657527-47f249e8f33a?auto=format&fit=crop&w=1200&q=60',
    videoEmbedUrl: 'https://www.youtube.com/embed/ScMzIvxBSi4',
    details: {
      overview:
        'We run micro-clinics with low-cost diagnostics and a monthly membership. Funds will expand operations to 3 new areas and hire medical assistants.',
      useOfFunds: [
        'Rent + basic setup for 3 micro-clinics',
        'Medical equipment and diagnostics kits',
        'Hiring and training frontline staff',
      ],
      milestones: [
        'Month 1: Secure locations and staffing',
        'Month 2: Launch 2 branches',
        'Month 3: Launch 3rd branch + marketing push',
      ],
    },
  },
  {
    id: 3,
    title: 'Skill Hub: Youth Training & Job Placement',
    poster: {
      id: 103,
      name: 'Mahmudul Islam',
      profession: 'Program Coordinator, EdTech',
      avatar: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&w=256&q=60',
      is_pro: true,
      kyc: false,
    },
    summary:
      'Training youth on digital skills and connecting to jobs. Donations help sponsor courses; investors help expand.',
    sector: 'EdTech',
    location: 'Chattogram',
    city: 'Chattogram',
    area: 'Agrabad',
    stage: 'Early',
    stageColor: 'purple',
    fundingType: 'Donation + Revenue-share',
    minInvestment: 5000,
    expectedReturn: 'Revenue-share',
    riskLevel: 'High',
    traction: '320 learners',
    raised: 24500,
    goal: 90000,
    thumbnail: 'https://images.unsplash.com/photo-1522202176988-66273c2fd55f?auto=format&fit=crop&w=1200&q=60',
    videoEmbedUrl: 'https://www.youtube.com/embed/dQw4w9WgXcQ',
    details: {
      overview:
        'We partner with mentors to train youth and connect them with jobs. Donations sponsor training seats; investors fund curriculum + placement team with revenue-share returns.',
      useOfFunds: [
        'Scholarships for 100 learners',
        'Mentor fees and curriculum production',
        'Job placement and employer partnerships',
      ],
      milestones: [
        'Month 1: Recruit mentors + finalize curriculum',
        'Month 2: Train 100 learners',
        'Month 3: Place first batch into jobs',
      ],
    },
  },
]


const showChatSlideout = ref(false)
const chatRoomId = ref(null)
const chatUser = ref({})

const displayedPlans = computed(() => {
  const list = [...plans]

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
