<template>
  <div class="min-h-screen bg-gray-50 dark:bg-slate-900">
    <!-- Container -->
    <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-4 sm:py-6">
      <!-- Breadcrumb - Hidden on mobile -->
      <nav class="hidden sm:flex items-center gap-2 text-sm mb-4 sm:mb-6">
        <NuxtLink to="/" class="text-slate-500 dark:text-slate-400 hover:text-purple-600 dark:hover:text-purple-400 transition">
          Home
        </NuxtLink>
        <UIcon name="i-heroicons-chevron-right" class="w-4 h-4 text-slate-400" />
        <span class="text-gray-900 dark:text-white font-medium">Raise Up</span>
      </nav>

      <!-- Mobile Back -->
      <div class="sm:hidden flex items-center gap-2 mb-4">
        <NuxtLink to="/" class="inline-flex items-center gap-1.5 text-sm text-slate-600 dark:text-slate-400">
          <UIcon name="i-heroicons-arrow-left" class="w-4 h-4" />
          Home
        </NuxtLink>
      </div>

      <!-- Header Bar -->
      <div class="flex items-center justify-between gap-4 mb-4 sm:mb-6">
        <div class="flex items-center gap-2.5 sm:gap-3">
          <div class="w-9 h-9 sm:w-10 sm:h-10 rounded-lg bg-gradient-to-br from-purple-500 to-indigo-600 flex items-center justify-center shrink-0 shadow-lg shadow-purple-500/25">
            <UIcon name="i-heroicons-rocket-launch" class="w-4 h-4 sm:w-5 sm:h-5 text-white" />
          </div>
          <h1 class="text-base sm:text-lg lg:text-xl font-bold text-gray-900 dark:text-white">
            Raise Up
          </h1>
        </div>
        <NuxtLink
          to="/raise-up/create"
          class="inline-flex items-center justify-center gap-1.5 px-3 sm:px-4 py-1.5 sm:py-2 rounded-full bg-gradient-to-r from-purple-500 to-indigo-600 text-white text-xs sm:text-sm font-semibold shadow-lg shadow-purple-500/25 hover:shadow-purple-500/40 hover:scale-[1.02] transition-all duration-200"
        >
          <UIcon name="i-heroicons-plus" class="w-3.5 h-3.5 sm:w-4 sm:h-4" />
          <span class="hidden sm:inline">Post Your Idea</span>
          <span class="sm:hidden">Post</span>
        </NuxtLink>
      </div>

      <!-- Banner Slider -->
      <div class="mb-4 sm:mb-6 rounded-xl sm:rounded-2xl overflow-hidden relative">
        <div 
          class="flex transition-transform duration-500 ease-out"
          :style="{ transform: `translateX(-${currentSlide * 100}%)` }"
        >
          <div 
            v-for="(banner, idx) in banners" 
            :key="idx"
            class="w-full shrink-0 relative aspect-[2.5/1] sm:aspect-[3.5/1] lg:aspect-[4/1]"
          >
            <img 
              :src="banner.image" 
              :alt="banner.title"
              class="absolute inset-0 w-full h-full object-cover"
            />
            <div class="absolute inset-0 bg-gradient-to-r from-purple-900/80 via-indigo-900/60 to-transparent"></div>
            <div class="absolute inset-0 flex items-center">
              <div class="px-4 sm:px-6 lg:px-8 max-w-lg">
                <h2 class="text-white text-sm sm:text-lg lg:text-xl font-bold mb-1 sm:mb-2 line-clamp-2">
                  {{ banner.title }}
                </h2>
                <p class="text-purple-100 text-[10px] sm:text-xs lg:text-sm line-clamp-2 hidden sm:block">
                  {{ banner.subtitle }}
                </p>
              </div>
            </div>
          </div>
        </div>

        <!-- Slider Controls -->
        <button 
          v-if="banners.length > 1"
          type="button"
          class="absolute left-2 top-1/2 -translate-y-1/2 w-7 h-7 sm:w-8 sm:h-8 rounded-full bg-white/20 backdrop-blur-sm flex items-center justify-center text-white hover:bg-white/30 transition"
          @click="prevSlide"
        >
          <UIcon name="i-heroicons-chevron-left" class="w-4 h-4 sm:w-5 sm:h-5" />
        </button>
        <button 
          v-if="banners.length > 1"
          type="button"
          class="absolute right-2 top-1/2 -translate-y-1/2 w-7 h-7 sm:w-8 sm:h-8 rounded-full bg-white/20 backdrop-blur-sm flex items-center justify-center text-white hover:bg-white/30 transition"
          @click="nextSlide"
        >
          <UIcon name="i-heroicons-chevron-right" class="w-4 h-4 sm:w-5 sm:h-5" />
        </button>

        <!-- Dots -->
        <div v-if="banners.length > 1" class="absolute bottom-2 sm:bottom-3 left-1/2 -translate-x-1/2 flex items-center gap-1.5">
          <button
            v-for="(_, idx) in banners"
            :key="idx"
            type="button"
            class="w-1.5 h-1.5 sm:w-2 sm:h-2 rounded-full transition-all duration-300"
            :class="idx === currentSlide ? 'bg-white w-4 sm:w-5' : 'bg-white/50 hover:bg-white/70'"
            @click="currentSlide = idx"
          ></button>
        </div>
      </div>

      <!-- Warning/Disclaimer Banner -->
      <div class="bg-amber-50 dark:bg-amber-900/20 border border-amber-200 dark:border-amber-800/50 rounded-xl p-3 sm:p-4 mb-4 sm:mb-6">
        <div class="flex gap-2.5 sm:gap-3">
          <div class="shrink-0">
            <UIcon name="i-heroicons-exclamation-triangle" class="w-4 h-4 sm:w-5 sm:h-5 text-amber-500" />
          </div>
          <div>
            <h3 class="text-xs sm:text-sm font-semibold text-amber-800 dark:text-amber-200 mb-0.5">Investment Risk Warning</h3>
            <p class="text-[11px] sm:text-xs text-amber-700 dark:text-amber-300 leading-relaxed">
              Investing in early-stage businesses involves significant risk. You may lose some or all of your investment. 
              Only invest money you can afford to lose. Past performance is not indicative of future results.
            </p>
          </div>
        </div>
      </div>

      <!-- Filter/Sort Bar -->
      <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-3 mb-4 sm:mb-6">
        <h2 class="text-base sm:text-lg font-bold text-gray-900 dark:text-white">
          Featured Ideas
          <span class="text-xs sm:text-sm font-normal text-slate-500 dark:text-slate-400 ml-2">({{ plans.length }})</span>
        </h2>
        <div class="flex items-center gap-2">
          <span class="text-xs text-slate-500 dark:text-slate-400">Sort by:</span>
          <select class="text-xs sm:text-sm bg-white dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-lg px-2 py-1.5 text-slate-700 dark:text-slate-300 focus:outline-none focus:ring-2 focus:ring-purple-500">
            <option>Most Funded</option>
            <option>Newest</option>
            <option>Ending Soon</option>
          </select>
        </div>
      </div>

      <!-- Ideas Grid -->
      <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4 sm:gap-5 mb-6 sm:mb-8">
        <NuxtLink
          v-for="plan in plans"
          :key="plan.id"
          :to="`/raise-up/${plan.id}`"
          class="group bg-white dark:bg-slate-800 rounded-xl border border-slate-200 dark:border-slate-700 overflow-hidden hover:border-purple-300 dark:hover:border-purple-600 hover:shadow-xl transition-all duration-300"
        >
          <!-- Thumbnail -->
          <div class="relative aspect-video bg-slate-100 dark:bg-slate-700 overflow-hidden">
            <img
              :src="plan.thumbnail"
              :alt="plan.title"
              class="w-full h-full object-cover group-hover:scale-105 transition-transform duration-500"
            />
            <div class="absolute inset-0 bg-gradient-to-t from-black/70 via-black/20 to-transparent"></div>
            
            <!-- Stage Badge -->
            <div class="absolute top-2 sm:top-3 right-2 sm:right-3">
              <span
                class="inline-flex items-center px-2 py-0.5 rounded-full text-[9px] sm:text-[10px] font-bold uppercase shadow-lg"
                :class="{
                  'bg-purple-500 text-white': plan.stageColor === 'emerald' || plan.stageColor === 'purple',
                  'bg-blue-500 text-white': plan.stageColor === 'blue',
                  'bg-amber-500 text-white': plan.stageColor === 'amber'
                }"
              >
                {{ plan.stage }}
              </span>
            </div>

            <!-- Funding Type Badge -->
            <div class="absolute top-2 sm:top-3 left-2 sm:left-3">
              <span class="inline-flex items-center px-2 py-0.5 rounded-full text-[9px] sm:text-[10px] font-medium bg-black/50 backdrop-blur-sm text-white">
                {{ plan.fundingType.split('+')[0].trim() }}
              </span>
            </div>

            <!-- Progress -->
            <div class="absolute bottom-2 sm:bottom-3 left-2 sm:left-3 right-2 sm:right-3">
              <div class="flex items-center justify-between text-white text-[10px] sm:text-xs mb-1">
                <span class="font-medium">{{ progressPercent(plan) }}% funded</span>
                <span class="font-bold">৳{{ plan.raised.toLocaleString() }}</span>
              </div>
              <div class="h-1.5 bg-white/30 rounded-full overflow-hidden">
                <div
                  class="h-full bg-gradient-to-r from-purple-400 to-indigo-400 rounded-full"
                  :style="{ width: `${progressPercent(plan)}%` }"
                ></div>
              </div>
            </div>
          </div>

          <!-- Content -->
          <div class="p-3 sm:p-4">
            <h3 class="text-sm sm:text-base font-bold text-gray-900 dark:text-white line-clamp-2 mb-2 sm:mb-3 group-hover:text-purple-600 dark:group-hover:text-purple-400 transition">
              {{ plan.title }}
            </h3>
            
            <!-- Founder -->
            <div class="flex items-center gap-2 mb-2 sm:mb-3">
              <img
                :src="plan.poster.avatar"
                :alt="plan.poster.name"
                class="w-6 h-6 sm:w-7 sm:h-7 rounded-full object-cover ring-1 ring-slate-200 dark:ring-slate-700"
              />
              <div class="min-w-0 flex-1">
                <div class="flex items-center gap-1">
                  <span class="text-xs sm:text-sm text-slate-700 dark:text-slate-300 font-medium truncate">{{ plan.poster.name }}</span>
                  <UIcon
                    v-if="plan.poster.kyc"
                    name="i-heroicons-check-badge-solid"
                    class="w-3.5 h-3.5 text-blue-500 shrink-0"
                  />
                  <div
                    v-if="plan.poster.is_pro"
                    class="shrink-0 bg-gradient-to-r from-amber-400 to-orange-500 text-white rounded px-1 py-0.5 text-[8px] font-bold"
                  >
                    PRO
                  </div>
                </div>
              </div>
            </div>

            <!-- Meta Info -->
            <div class="flex items-center justify-between text-[10px] sm:text-xs pt-2 sm:pt-3 border-t border-slate-100 dark:border-slate-700">
              <span class="inline-flex items-center gap-1 text-slate-500 dark:text-slate-400">
                <UIcon name="i-heroicons-map-pin" class="w-3 h-3" />
                {{ plan.city }}
              </span>
              <span
                class="px-1.5 py-0.5 rounded text-[9px] sm:text-[10px] font-bold"
                :class="riskBadgeClass(plan.riskLevel)"
              >
                {{ plan.riskLevel }} Risk
              </span>
            </div>

            <!-- Quick Stats -->
            <div class="grid grid-cols-2 gap-2 mt-2 sm:mt-3 pt-2 sm:pt-3 border-t border-slate-100 dark:border-slate-700">
              <div class="text-center">
                <div class="text-[10px] sm:text-xs text-slate-500 dark:text-slate-400">Min Invest</div>
                <div class="text-xs sm:text-sm font-bold text-slate-800 dark:text-slate-100">৳{{ (plan.minInvestment / 1000).toFixed(0) }}K</div>
              </div>
              <div class="text-center">
                <div class="text-[10px] sm:text-xs text-slate-500 dark:text-slate-400">Return</div>
                <div class="text-xs sm:text-sm font-bold text-purple-600 dark:text-purple-400">{{ plan.expectedReturn.split(' ')[0] }}</div>
              </div>
            </div>
          </div>
        </NuxtLink>
      </div>

      <!-- Safety Tips Section -->
      <div class="bg-slate-100 dark:bg-slate-800/50 rounded-xl p-4 sm:p-5 mb-4 sm:mb-6">
        <div class="flex items-start gap-2.5 sm:gap-3 mb-3 sm:mb-4">
          <UIcon name="i-heroicons-shield-check" class="w-4 h-4 sm:w-5 sm:h-5 text-purple-600 dark:text-purple-400 shrink-0 mt-0.5" />
          <div>
            <h3 class="text-xs sm:text-sm font-bold text-gray-900 dark:text-white mb-0.5">Safety Tips for Investors</h3>
            <p class="text-[11px] sm:text-xs text-slate-600 dark:text-slate-400">Follow these guidelines to make informed investment decisions.</p>
          </div>
        </div>
        <div class="grid grid-cols-1 sm:grid-cols-2 gap-1.5 sm:gap-2">
          <div class="flex items-start gap-2">
            <UIcon name="i-heroicons-check-circle" class="w-3.5 h-3.5 text-purple-500 shrink-0 mt-0.5" />
            <span class="text-[11px] sm:text-xs text-slate-600 dark:text-slate-400">Research the founder's background and track record</span>
          </div>
          <div class="flex items-start gap-2">
            <UIcon name="i-heroicons-check-circle" class="w-3.5 h-3.5 text-purple-500 shrink-0 mt-0.5" />
            <span class="text-[11px] sm:text-xs text-slate-600 dark:text-slate-400">Understand the business model and revenue plan</span>
          </div>
          <div class="flex items-start gap-2">
            <UIcon name="i-heroicons-check-circle" class="w-3.5 h-3.5 text-purple-500 shrink-0 mt-0.5" />
            <span class="text-[11px] sm:text-xs text-slate-600 dark:text-slate-400">Never invest more than you can afford to lose</span>
          </div>
          <div class="flex items-start gap-2">
            <UIcon name="i-heroicons-check-circle" class="w-3.5 h-3.5 text-purple-500 shrink-0 mt-0.5" />
            <span class="text-[11px] sm:text-xs text-slate-600 dark:text-slate-400">Diversify your investments across multiple ideas</span>
          </div>
        </div>
      </div>

      <!-- How It Works Section -->
      <div class="mb-4 sm:mb-6">
        <h2 class="text-sm sm:text-base font-bold text-gray-900 dark:text-white mb-3 sm:mb-4">How It Works</h2>
        <div class="grid grid-cols-1 sm:grid-cols-3 gap-2.5 sm:gap-3">
          <div class="bg-white dark:bg-slate-800 rounded-xl border border-slate-200 dark:border-slate-700 p-3 sm:p-4">
            <div class="w-7 h-7 sm:w-8 sm:h-8 rounded-lg bg-purple-100 dark:bg-purple-900/30 flex items-center justify-center mb-2">
              <UIcon name="i-heroicons-magnifying-glass" class="w-3.5 h-3.5 sm:w-4 sm:h-4 text-purple-600 dark:text-purple-400" />
            </div>
            <h3 class="text-xs sm:text-sm font-semibold text-gray-900 dark:text-white mb-0.5">1. Discover</h3>
            <p class="text-[11px] sm:text-xs text-slate-500 dark:text-slate-400">Browse verified business ideas from local entrepreneurs seeking funding.</p>
          </div>
          <div class="bg-white dark:bg-slate-800 rounded-xl border border-slate-200 dark:border-slate-700 p-3 sm:p-4">
            <div class="w-7 h-7 sm:w-8 sm:h-8 rounded-lg bg-indigo-100 dark:bg-indigo-900/30 flex items-center justify-center mb-2">
              <UIcon name="i-heroicons-chat-bubble-left-right" class="w-3.5 h-3.5 sm:w-4 sm:h-4 text-indigo-600 dark:text-indigo-400" />
            </div>
            <h3 class="text-xs sm:text-sm font-semibold text-gray-900 dark:text-white mb-0.5">2. Connect</h3>
            <p class="text-[11px] sm:text-xs text-slate-500 dark:text-slate-400">Chat directly with founders to learn more about their vision and plans.</p>
          </div>
          <div class="bg-white dark:bg-slate-800 rounded-xl border border-slate-200 dark:border-slate-700 p-3 sm:p-4">
            <div class="w-7 h-7 sm:w-8 sm:h-8 rounded-lg bg-purple-100 dark:bg-purple-900/30 flex items-center justify-center mb-2">
              <UIcon name="i-heroicons-banknotes" class="w-3.5 h-3.5 sm:w-4 sm:h-4 text-purple-600 dark:text-purple-400" />
            </div>
            <h3 class="text-xs sm:text-sm font-semibold text-gray-900 dark:text-white mb-0.5">3. Support</h3>
            <p class="text-[11px] sm:text-xs text-slate-500 dark:text-slate-400">Invest or donate to help bring promising ideas to life in your community.</p>
          </div>
        </div>
      </div>

      <!-- CTA Section -->
      <div class="bg-gradient-to-r from-purple-600 to-indigo-600 rounded-xl p-4 sm:p-6 text-white text-center">
        <h3 class="text-base sm:text-lg font-bold mb-2">Have a Business Idea?</h3>
        <p class="text-xs sm:text-sm text-purple-100 mb-4">Share your vision and get funding support from the community.</p>
        <NuxtLink
          to="/raise-up/create"
          class="inline-flex items-center gap-2 px-5 py-2.5 rounded-full bg-white text-purple-600 text-sm font-semibold hover:shadow-lg transition"
        >
          <UIcon name="i-heroicons-light-bulb" class="w-5 h-5" />
          Submit Your Idea
        </NuxtLink>
      </div>
    </div>
  </div>
</template>

<script setup>
// Computed total raised
const totalRaised = computed(() => {
  const total = plans.reduce((sum, p) => sum + (p.raised || 0), 0)
  if (total >= 1000000) return `${(total / 1000000).toFixed(1)}M`
  if (total >= 1000) return `${(total / 1000).toFixed(0)}K`
  return total.toLocaleString()
})

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
  },
]

const progressPercent = (plan) => {
  const value = Math.round((Number(plan.raised || 0) / Number(plan.goal || 1)) * 100)
  return Math.max(0, Math.min(100, value))
}

const riskBadgeClass = (riskLevel) => {
  if (riskLevel === 'Low') return 'bg-purple-500/10 text-purple-700 dark:text-purple-300'
  if (riskLevel === 'Medium') return 'bg-amber-500/10 text-amber-700 dark:text-amber-300'
  return 'bg-rose-500/10 text-rose-700 dark:text-rose-300'
}
</script>
