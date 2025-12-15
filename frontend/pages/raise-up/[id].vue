<template>
  <div class="min-h-screen bg-gray-50 dark:bg-slate-900">
    <!-- Loading State -->
    <div v-if="loading" class="flex items-center justify-center py-20">
      <div class="text-center">
        <div class="w-10 h-10 border-3 border-purple-500 border-t-transparent rounded-full animate-spin mx-auto mb-3"></div>
        <p class="text-sm text-slate-500">Loading...</p>
      </div>
    </div>

    <!-- Content -->
    <div v-else-if="plan" class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-4 sm:py-6">
      <!-- Breadcrumb - Hidden on mobile -->
      <nav class="hidden sm:flex items-center gap-2 text-sm mb-4 sm:mb-6">
        <NuxtLink to="/" class="text-slate-500 dark:text-slate-400 hover:text-purple-600 dark:hover:text-purple-400 transition">
          Home
        </NuxtLink>
        <UIcon name="i-heroicons-chevron-right" class="w-4 h-4 text-slate-400" />
        <NuxtLink to="/raise-up" class="text-slate-500 dark:text-slate-400 hover:text-purple-600 dark:hover:text-purple-400 transition">
          Raise Up
        </NuxtLink>
        <UIcon name="i-heroicons-chevron-right" class="w-4 h-4 text-slate-400" />
        <span class="text-gray-900 dark:text-white font-medium truncate max-w-[200px]">{{ plan.title }}</span>
      </nav>

      <!-- Mobile Back Button -->
      <div class="sm:hidden flex items-center gap-2 mb-4">
        <NuxtLink to="/raise-up" class="inline-flex items-center gap-1.5 text-sm text-slate-600 dark:text-slate-400">
          <UIcon name="i-heroicons-arrow-left" class="w-4 h-4" />
          Back
        </NuxtLink>
      </div>

      <!-- Main Layout -->
      <div class="flex flex-col lg:flex-row lg:gap-8">
        <!-- Main Content -->
        <div class="flex-1 min-w-0">
          <!-- Video Section -->
          <div class="rounded-xl sm:rounded-2xl overflow-hidden bg-black mb-4 sm:mb-6 -mx-4 sm:mx-0">
            <iframe
              v-if="plan.videoEmbedUrl"
              class="w-full aspect-video"
              :src="plan.videoEmbedUrl"
              title="Video"
              frameborder="0"
              allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share"
              allowfullscreen
            ></iframe>
            <img
              v-else
              :src="plan.thumbnail"
              :alt="plan.title"
              class="w-full aspect-video object-cover"
            />
          </div>

          <!-- Title & Stage -->
          <div class="flex flex-col sm:flex-row sm:items-start sm:justify-between gap-2 sm:gap-4 mb-3 sm:mb-4">
            <h1 class="text-lg sm:text-xl lg:text-2xl font-bold text-gray-900 dark:text-white leading-tight">
              {{ plan.title }}
            </h1>
            <span
              class="self-start shrink-0 inline-flex items-center px-2.5 sm:px-3 py-1 rounded-full text-[10px] sm:text-xs font-bold uppercase tracking-wide"
              :class="{
                'bg-purple-500 text-white': plan.stageColor === 'emerald' || plan.stageColor === 'purple',
                'bg-blue-500 text-white': plan.stageColor === 'blue',
                'bg-amber-500 text-white': plan.stageColor === 'amber'
              }"
            >
              {{ plan.stage }}
            </span>
          </div>

          <!-- Location & Risk -->
          <div class="flex flex-wrap items-center gap-2 sm:gap-3 mb-4 sm:mb-6">
            <span class="inline-flex items-center gap-1 text-xs sm:text-sm text-slate-500 dark:text-slate-400">
              <UIcon name="i-heroicons-map-pin" class="w-3.5 h-3.5 sm:w-4 sm:h-4" />
              {{ plan.city }}, {{ plan.area }}
            </span>
            <span
              class="inline-flex items-center gap-1 px-2 py-0.5 rounded-md text-[10px] sm:text-xs font-bold"
              :class="riskBadgeClass(plan.riskLevel)"
            >
              {{ plan.riskLevel }} Risk
            </span>
          </div>

          <!-- Founder Card -->
          <div class="bg-white dark:bg-slate-800 rounded-xl border border-slate-200 dark:border-slate-700 p-3 sm:p-4 mb-4 sm:mb-6">
            <div class="flex items-center justify-between gap-3">
              <div class="flex items-center gap-2.5 sm:gap-3 min-w-0">
                <NuxtLink :to="`/business-network/profile/${plan.poster.id}`" class="shrink-0">
                  <img
                    :src="plan.poster.avatar"
                    :alt="plan.poster.name"
                    class="w-10 h-10 sm:w-12 sm:h-12 rounded-full object-cover ring-2 ring-white dark:ring-slate-700 shadow-md"
                  />
                </NuxtLink>
                <div class="min-w-0">
                  <div class="flex items-center gap-1.5 flex-wrap">
                    <NuxtLink
                      :to="`/business-network/profile/${plan.poster.id}`"
                      class="text-sm sm:text-base font-semibold text-slate-800 dark:text-slate-100 hover:text-purple-600 dark:hover:text-purple-400 transition truncate"
                    >
                      {{ plan.poster.name }}
                    </NuxtLink>
                    <UIcon
                      v-if="plan.poster.kyc"
                      name="i-heroicons-check-badge-solid"
                      class="w-4 h-4 sm:w-5 sm:h-5 text-blue-500 shrink-0"
                    />
                    <div
                      v-if="plan.poster.is_pro"
                      class="shrink-0 bg-gradient-to-r from-amber-400 to-orange-500 text-white rounded px-1.5 py-0.5 text-[9px] sm:text-[10px] font-bold shadow-sm"
                    >
                      PRO
                    </div>
                  </div>
                  <p class="text-xs sm:text-sm text-slate-500 dark:text-slate-400 truncate">{{ plan.poster.profession }}</p>
                </div>
              </div>
              <button
                type="button"
                class="shrink-0 p-2 rounded-full hover:bg-slate-100 dark:hover:bg-slate-700 transition"
                @click="openChat(plan.poster)"
              >
                <img
                  src="https://adsyclub.com/static/frontend/images/chat_icon.png"
                  alt="Chat"
                  class="w-5 h-5 sm:w-6 sm:h-6"
                />
              </button>
            </div>
          </div>

          <!-- Progress -->
          <div class="bg-white dark:bg-slate-800 rounded-xl border border-slate-200 dark:border-slate-700 p-3 sm:p-4 mb-4 sm:mb-6">
            <div class="flex items-center justify-between mb-2">
              <span class="text-xs sm:text-sm font-medium text-slate-600 dark:text-slate-300">Funding Progress</span>
              <span class="text-xs sm:text-sm font-bold text-purple-600 dark:text-purple-400">{{ progressPercent }}%</span>
            </div>
            <div class="h-2 sm:h-3 bg-slate-100 dark:bg-slate-700 rounded-full overflow-hidden mb-2 sm:mb-3">
              <div
                class="h-full bg-gradient-to-r from-purple-500 to-indigo-500 rounded-full transition-all duration-500"
                :style="{ width: `${progressPercent}%` }"
              ></div>
            </div>
            <div class="flex items-center justify-between text-xs sm:text-sm">
              <span class="text-slate-500 dark:text-slate-400">Raised: <strong class="text-slate-800 dark:text-slate-100">৳{{ plan.raised.toLocaleString() }}</strong></span>
              <span class="text-slate-500 dark:text-slate-400">Goal: <strong class="text-slate-800 dark:text-slate-100">৳{{ plan.goal.toLocaleString() }}</strong></span>
            </div>
          </div>

          <!-- Stats Grid -->
          <div class="grid grid-cols-2 gap-2 sm:gap-3 mb-4 sm:mb-6">
            <div class="bg-white dark:bg-slate-800 rounded-xl border border-slate-200 dark:border-slate-700 p-3 sm:p-4 text-center">
              <div class="text-[10px] sm:text-xs text-slate-500 dark:text-slate-400 uppercase tracking-wide mb-0.5 sm:mb-1">Funding Type</div>
              <div class="text-xs sm:text-sm font-bold text-slate-800 dark:text-slate-100 truncate">{{ plan.fundingType }}</div>
            </div>
            <div class="bg-white dark:bg-slate-800 rounded-xl border border-slate-200 dark:border-slate-700 p-3 sm:p-4 text-center">
              <div class="text-[10px] sm:text-xs text-slate-500 dark:text-slate-400 uppercase tracking-wide mb-0.5 sm:mb-1">Min Investment</div>
              <div class="text-xs sm:text-sm font-bold text-slate-800 dark:text-slate-100">৳{{ plan.minInvestment.toLocaleString() }}</div>
            </div>
            <div class="bg-white dark:bg-slate-800 rounded-xl border border-slate-200 dark:border-slate-700 p-3 sm:p-4 text-center">
              <div class="text-[10px] sm:text-xs text-slate-500 dark:text-slate-400 uppercase tracking-wide mb-0.5 sm:mb-1">Expected Return</div>
              <div class="text-xs sm:text-sm font-bold text-purple-600 dark:text-purple-400">{{ plan.expectedReturn }}</div>
            </div>
            <div class="bg-white dark:bg-slate-800 rounded-xl border border-slate-200 dark:border-slate-700 p-3 sm:p-4 text-center">
              <div class="text-[10px] sm:text-xs text-slate-500 dark:text-slate-400 uppercase tracking-wide mb-0.5 sm:mb-1">Traction</div>
              <div class="text-xs sm:text-sm font-bold text-slate-800 dark:text-slate-100 truncate">{{ plan.traction }}</div>
            </div>
          </div>

          <!-- Overview -->
          <div class="bg-white dark:bg-slate-800 rounded-xl border border-slate-200 dark:border-slate-700 p-3 sm:p-4 mb-4 sm:mb-6">
            <h3 class="text-sm sm:text-base font-bold text-gray-900 dark:text-white mb-2 sm:mb-3">Overview</h3>
            <p class="text-xs sm:text-sm text-slate-600 dark:text-slate-300 leading-relaxed">{{ plan.summary }}</p>
            <p v-if="plan.details?.overview" class="mt-2 sm:mt-3 text-xs sm:text-sm text-slate-600 dark:text-slate-300 leading-relaxed">
              {{ plan.details.overview }}
            </p>
          </div>

          <!-- Use of Funds -->
          <div v-if="plan.details?.useOfFunds?.length" class="bg-white dark:bg-slate-800 rounded-xl border border-slate-200 dark:border-slate-700 p-3 sm:p-4 mb-4 sm:mb-6">
            <h3 class="text-sm sm:text-base font-bold text-gray-900 dark:text-white mb-2 sm:mb-3">Use of Funds</h3>
            <ul class="space-y-1.5 sm:space-y-2">
              <li
                v-for="(item, idx) in plan.details.useOfFunds"
                :key="idx"
                class="flex items-start gap-2 text-xs sm:text-sm text-slate-600 dark:text-slate-300"
              >
                <span class="mt-1.5 w-1.5 h-1.5 rounded-full bg-purple-500 shrink-0"></span>
                <span>{{ item }}</span>
              </li>
            </ul>
          </div>

          <!-- Milestones -->
          <div v-if="plan.details?.milestones?.length" class="bg-white dark:bg-slate-800 rounded-xl border border-slate-200 dark:border-slate-700 p-3 sm:p-4 mb-4 sm:mb-6">
            <h3 class="text-sm sm:text-base font-bold text-gray-900 dark:text-white mb-2 sm:mb-3">Milestones</h3>
            <ul class="space-y-1.5 sm:space-y-2">
              <li
                v-for="(item, idx) in plan.details.milestones"
                :key="idx"
                class="flex items-start gap-2 text-xs sm:text-sm text-slate-600 dark:text-slate-300"
              >
                <span class="mt-1.5 w-1.5 h-1.5 rounded-full bg-indigo-500 shrink-0"></span>
                <span>{{ item }}</span>
              </li>
            </ul>
          </div>

          <!-- CTA Buttons - Fixed on mobile, inline on desktop -->
          <div class="fixed bottom-0 left-0 right-0 sm:relative sm:bottom-auto bg-white dark:bg-slate-800 border-t sm:border-t-0 border-slate-200 dark:border-slate-700 p-3 sm:p-0 sm:mb-6 z-40">
            <div class="grid grid-cols-2 gap-2 sm:gap-3 max-w-7xl mx-auto">
              <UButton
                color="purple"
                variant="soft"
                size="md"
                class="justify-center font-semibold text-sm sm:text-base"
                @click="handleDonate"
              >
                <UIcon name="i-heroicons-heart" class="w-4 h-4 sm:w-5 sm:h-5 mr-1.5 sm:mr-2" />
                Donate
              </UButton>
              <UButton
                size="md"
                class="justify-center font-semibold text-sm sm:text-base bg-gradient-to-r from-purple-500 to-indigo-600 hover:from-purple-600 hover:to-indigo-700 text-white border-0"
                @click="handleInvest"
              >
                <UIcon name="i-heroicons-banknotes" class="w-4 h-4 sm:w-5 sm:h-5 mr-1.5 sm:mr-2" />
                Invest
              </UButton>
            </div>
          </div>

          <!-- Spacer for fixed CTA on mobile -->
          <div class="h-16 sm:hidden"></div>
        </div>

        <!-- Sidebar - Shows below on mobile -->
        <div class="w-full lg:w-80 xl:w-96 shrink-0 mt-6 lg:mt-0">
          <div class="lg:sticky lg:top-6 space-y-4 sm:space-y-6">
            <!-- Similar Ideas -->
            <div class="bg-white dark:bg-slate-800 rounded-xl border border-slate-200 dark:border-slate-700 p-3 sm:p-4">
              <h3 class="text-sm sm:text-base font-bold text-gray-900 dark:text-white mb-3 sm:mb-4">Similar Ideas</h3>
              <div class="space-y-2 sm:space-y-3">
                <NuxtLink
                  v-for="similarPlan in similarPlans"
                  :key="similarPlan.id"
                  :to="`/raise-up/${similarPlan.id}`"
                  class="group flex gap-3 p-2 sm:p-3 rounded-lg border border-slate-100 dark:border-slate-700 hover:border-purple-300 dark:hover:border-purple-600 hover:shadow-md transition-all duration-200"
                >
                  <img
                    :src="similarPlan.thumbnail"
                    :alt="similarPlan.title"
                    class="w-12 h-12 sm:w-14 sm:h-14 rounded-lg object-cover shrink-0"
                  />
                  <div class="min-w-0 flex-1">
                    <h4 class="text-xs sm:text-sm font-semibold text-gray-900 dark:text-white line-clamp-2 mb-1 group-hover:text-purple-600 dark:group-hover:text-purple-400 transition">
                      {{ similarPlan.title }}
                    </h4>
                    <div class="flex items-center gap-2 text-[10px] sm:text-xs text-slate-500 dark:text-slate-400">
                      <span
                        class="px-1.5 py-0.5 rounded text-[9px] sm:text-[10px] font-bold"
                        :class="{
                          'bg-purple-500 text-white': similarPlan.stageColor === 'emerald' || similarPlan.stageColor === 'purple',
                          'bg-blue-500 text-white': similarPlan.stageColor === 'blue',
                          'bg-amber-500 text-white': similarPlan.stageColor === 'amber'
                        }"
                      >
                        {{ similarPlan.stage }}
                      </span>
                      <span class="truncate">{{ similarPlan.city }}</span>
                    </div>
                  </div>
                </NuxtLink>

                <!-- Empty state -->
                <div v-if="!similarPlans.length" class="text-center py-4">
                  <p class="text-xs sm:text-sm text-slate-500 dark:text-slate-400">No similar ideas found</p>
                </div>
              </div>
            </div>

            <!-- Quick Actions -->
            <div class="bg-white dark:bg-slate-800 rounded-xl border border-slate-200 dark:border-slate-700 p-3 sm:p-4">
              <h3 class="text-sm sm:text-base font-bold text-gray-900 dark:text-white mb-3 sm:mb-4">Quick Actions</h3>
              <div class="space-y-1.5 sm:space-y-2">
                <NuxtLink
                  to="/raise-up/create"
                  class="flex items-center gap-2 w-full p-2 rounded-lg text-xs sm:text-sm font-medium text-purple-600 dark:text-purple-400 hover:bg-purple-50 dark:hover:bg-purple-900/20 transition"
                >
                  <UIcon name="i-heroicons-plus" class="w-4 h-4" />
                  Post Your Idea
                </NuxtLink>
                <NuxtLink
                  to="/raise-up"
                  class="flex items-center gap-2 w-full p-2 rounded-lg text-xs sm:text-sm font-medium text-slate-600 dark:text-slate-400 hover:bg-slate-50 dark:hover:bg-slate-700/50 transition"
                >
                  <UIcon name="i-heroicons-squares-2x2" class="w-4 h-4" />
                  Browse All Ideas
                </NuxtLink>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- Not Found -->
    <div v-else class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-20">
      <div class="flex items-center justify-center">
        <div class="text-center">
          <UIcon name="i-heroicons-exclamation-circle" class="w-16 h-16 text-slate-300 dark:text-slate-600 mx-auto mb-4" />
          <p class="text-lg font-medium text-slate-600 dark:text-slate-400">Project not found</p>
          <NuxtLink to="/" class="mt-4 inline-flex items-center gap-2 text-purple-600 hover:text-purple-700 font-medium">
            <UIcon name="i-heroicons-arrow-left" class="w-4 h-4" />
            Back to Home
          </NuxtLink>
        </div>
      </div>
    </div>

    <!-- Chat Slideout -->
    <ProfileChatSlideout v-model="showChatSlideout" :user="chatUser" :chatroom-id="chatRoomId" />
  </div>
</template>

<script setup>
const route = useRoute()
const toast = useToast()
const { user: currentUser } = useAuth()
const { getOrCreateChatRoom } = useAdsyChat()

const loading = ref(true)
const plan = ref(null)

const showChatSlideout = ref(false)
const chatRoomId = ref(null)
const chatUser = ref({})

// Mock data - same as carousel
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
    summary: 'Low-cost solar purification units with local distribution partners. Seeking seed capital + impact donations.',
    sector: 'CleanTech',
    location: 'Rajshahi',
    city: 'Rajshahi',
    area: 'Boalia',
    stage: 'Seed',
    stageColor: 'purple',
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
      overview: 'We will manufacture solar purifier units and sell through local agents. Donations will subsidize units for ultra-low-income families while investment funds production capacity.',
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
    summary: 'A subscription-based micro-clinic model for low-income areas. Looking for investors to scale 3 locations.',
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
      overview: 'We run micro-clinics with low-cost diagnostics and a monthly membership. Funds will expand operations to 3 new areas and hire medical assistants.',
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
    summary: 'Training youth on digital skills and connecting to jobs. Donations help sponsor courses; investors help expand.',
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
      overview: 'We partner with mentors to train youth and connect them with jobs. Donations sponsor training seats; investors fund curriculum + placement team with revenue-share returns.',
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

const progressPercent = computed(() => {
  if (!plan.value) return 0
  const value = Math.round((Number(plan.value.raised || 0) / Number(plan.value.goal || 1)) * 100)
  return Math.max(0, Math.min(100, value))
})

const riskBadgeClass = (riskLevel) => {
  if (riskLevel === 'Low') return 'bg-purple-500/10 text-purple-700 dark:text-purple-300'
  if (riskLevel === 'Medium') return 'bg-amber-500/10 text-amber-700 dark:text-amber-300'
  return 'bg-rose-500/10 text-rose-700 dark:text-rose-300'
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
      chatUser.value = { id: poster.id, name: poster.name, image: poster.avatar, profession: poster.profession, is_pro: poster.is_pro, kyc: poster.kyc }
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

const handleDonate = () => {
  toast.add({
    title: 'Donate (Mock)',
    description: `You clicked Donate for: ${plan.value?.title}`,
    color: 'purple',
  })
}

const handleInvest = () => {
  toast.add({
    title: 'Invest (Mock)',
    description: `You clicked Invest for: ${plan.value?.title}`,
    color: 'indigo',
  })
}

// Similar plans computed property
const similarPlans = computed(() => {
  if (!plan.value) return []
  return plans.filter(p => p.id !== plan.value.id && p.sector === plan.value.sector).slice(0, 3)
})

onMounted(() => {
  const id = Number(route.params.id)
  plan.value = plans.find(p => p.id === id) || null
  loading.value = false
})
</script>
