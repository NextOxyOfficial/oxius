<template>
  <div class="group bg-white dark:bg-slate-800/80 rounded-2xl overflow-hidden border border-slate-200/80 dark:border-slate-700/60 hover:border-purple-300 dark:hover:border-purple-600/50 transition-all duration-300 shadow-sm hover:shadow-xl hover:shadow-slate-200/50 dark:hover:shadow-slate-900/50 flex flex-col">
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

        <!-- Play Button - Only for videos -->
        <div v-if="plan.media_type === 'video'" class="absolute inset-0 flex items-center justify-center">
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

      <!-- Top Donator Highlight -->
      <div v-if="topDonator" class="mt-1.5 flex items-center justify-between px-3 py-1.5 rounded-lg bg-gradient-to-r from-amber-50 to-yellow-50 dark:from-amber-900/20 dark:to-yellow-900/20 border border-amber-200 dark:border-amber-800">
        <div class="flex items-center gap-2 flex-1 min-w-0">
          <UIcon name="i-heroicons-trophy" class="w-4 h-4 text-amber-600 dark:text-amber-400 flex-shrink-0" />
          <div class="flex items-center gap-1.5 min-w-0">
            <span class="text-[10px] font-medium text-amber-700 dark:text-amber-400">Top Donator:</span>
            <span class="text-xs font-bold text-amber-800 dark:text-amber-300 truncate">{{ topDonator.name }}</span>
          </div>
        </div>
        <div class="flex items-center gap-2 flex-shrink-0">
          <span class="text-xs font-bold text-amber-700 dark:text-amber-400">৳{{ topDonator.amount.toLocaleString() }}</span>
          <button
            type="button"
            @click.stop="showDonationsList(1)"
            class="p-1 flex hover:bg-amber-100 dark:hover:bg-amber-800/50 rounded transition-colors"
            aria-label="View all donations"
          >
            <UIcon name="i-heroicons-list-bullet" class="w-3.5 h-3.5 text-amber-600 dark:text-amber-400" />
          </button>
        </div>
      </div>

      <!-- CTA Buttons -->
      <div class="mt-auto pt-3 grid grid-cols-3 gap-2">
        <NuxtLink
          :to="`/raise-up/${plan.id}`"
          class="inline-flex items-center justify-center gap-1.5 px-3 py-1.5 rounded-md text-sm font-semibold bg-gray-100 dark:bg-gray-800 text-gray-700 dark:text-gray-300 hover:bg-gray-200 dark:hover:bg-gray-700 transition"
        >
          <UIcon name="i-heroicons-document-text" class="w-4 h-4" />
          <span>Details</span>
        </NuxtLink>
        <UButton
          color="purple"
          variant="soft"
          size="sm"
          class="justify-center font-semibold"
          @click.stop="handleDonate(plan)"
        >
          <template #leading>
            <UIcon name="i-heroicons-heart" class="w-4 h-4" />
          </template>
          Donate
        </UButton>
        <UButton
          size="sm"
          class="justify-center font-semibold bg-gradient-to-r from-purple-500 to-indigo-600 hover:from-purple-600 hover:to-indigo-700 text-white border-0"
          @click.stop="handleInvest(plan)"
        >
          <template #leading>
            <UIcon name="i-heroicons-currency-dollar" class="w-4 h-4" />
          </template>
          Invest
        </UButton>
      </div>
    </div>

    <!-- Modals -->
    <DonateModal v-model="showDonateModal" :plan="plan" @success="onDonateSuccess" />
    <InvestModal v-model="showInvestModal" :plan="plan" @success="onInvestSuccess" />
    
    <!-- Donations List Modal -->
    <UModal v-model="showDonationsListModal" :ui="{ width: 'sm:max-w-md' }">
      <UCard>
        <template #header>
          <div class="flex items-center justify-between">
            <h3 class="text-lg font-semibold text-gray-900 dark:text-white">All Donations</h3>
            <UButton
              color="gray"
              variant="ghost"
              icon="i-heroicons-x-mark"
              @click="showDonationsListModal = false"
            />
          </div>
        </template>

        <div v-if="loadingDonations" class="flex items-center justify-center py-8">
          <div class="animate-spin rounded-full h-8 w-8 border-b-2 border-purple-600"></div>
        </div>

        <div v-else-if="donationsList.length === 0" class="text-center py-8">
          <UIcon name="i-heroicons-inbox" class="w-12 h-12 mx-auto text-gray-400 mb-2" />
          <p class="text-sm text-gray-500 dark:text-gray-400">No donations yet</p>
        </div>

        <div v-else>
          <!-- Donations List -->
          <div class="space-y-2 max-h-80 overflow-y-auto mb-4">
            <div
              v-for="(donation, index) in donationsList"
              :key="index"
              class="flex items-center justify-between p-3 rounded-lg bg-gray-50 dark:bg-gray-800 hover:bg-gray-100 dark:hover:bg-gray-700 transition-colors"
            >
              <div class="flex items-center gap-2 flex-1 min-w-0">
                <div class="w-8 h-8 rounded-full bg-gradient-to-br from-purple-500 to-indigo-600 flex items-center justify-center text-white text-xs font-bold flex-shrink-0">
                  {{ donation.user_name.charAt(0).toUpperCase() }}
                </div>
                <div class="min-w-0">
                  <p class="text-sm font-semibold text-gray-900 dark:text-white truncate">{{ donation.user_name }}</p>
                  <p class="text-xs text-gray-500 dark:text-gray-400">{{ donation.created_at }}</p>
                </div>
              </div>
              <div class="text-right flex-shrink-0">
                <p class="text-sm font-bold text-purple-600 dark:text-purple-400">৳{{ donation.amount.toLocaleString() }}</p>
              </div>
            </div>
          </div>

          <!-- Pagination -->
          <div v-if="totalPages > 1" class="flex items-center justify-between pt-3 border-t border-gray-200 dark:border-gray-700">
            <div class="flex items-center gap-2">
              <UButton
                size="xs"
                variant="ghost"
                color="gray"
                :disabled="currentPage === 1"
                @click="prevPage"
                icon="i-heroicons-chevron-left"
              />
              
              <div class="flex items-center gap-1">
                <template v-for="page in Math.min(totalPages, 5)" :key="page">
                  <UButton
                    v-if="shouldShowPage(page)"
                    size="xs"
                    :variant="currentPage === page ? 'solid' : 'ghost'"
                    :color="currentPage === page ? 'purple' : 'gray'"
                    @click="goToPage(page)"
                    class="min-w-[28px]"
                  >
                    {{ page }}
                  </UButton>
                  <span v-else-if="page === 4 && totalPages > 5" class="text-xs text-gray-400 px-1">...</span>
                </template>
                
                <UButton
                  v-if="totalPages > 5 && currentPage < totalPages - 2"
                  size="xs"
                  variant="ghost"
                  color="gray"
                  @click="goToPage(totalPages)"
                  class="min-w-[28px]"
                >
                  {{ totalPages }}
                </UButton>
              </div>
              
              <UButton
                size="xs"
                variant="ghost"
                color="gray"
                :disabled="currentPage === totalPages"
                @click="nextPage"
                icon="i-heroicons-chevron-right"
              />
            </div>
            
            <div class="text-xs text-gray-500 dark:text-gray-400">
              Page {{ currentPage }} of {{ totalPages }}
            </div>
          </div>
        </div>
      </UCard>
    </UModal>
    
    <!-- Chat Slideout -->
    <ProfileChatSlideout v-if="chatUser" v-model="showChatSlideout" :user="chatUser" :chatroom-id="chatRoomId" />
  </div>
</template>

<script setup>
import DonateModal from './DonateModal.vue'
import InvestModal from './InvestModal.vue'
import ProfileChatSlideout from '~/components/business-network/profile/ProfileChatSlideout.vue'

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

// Top donator state
const topDonator = ref(props.plan.top_donator || null)

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
      // Set chat user data for slideout
      chatUser.value = {
        id: poster.id,
        name: poster.name,
        image: poster.avatar,
        avatar: poster.avatar,
        profession: poster.profession,
        kyc: poster.kyc,
        is_pro: poster.is_pro
      }
      chatRoomId.value = room.id
      showChatSlideout.value = true
    }
  } catch (e) {
    console.error('Chat error:', e)
    toast.add({
      title: 'Chat Error',
      description: 'Unable to open chat right now',
      color: 'red',
    })
  }
}

// Modal states
const showDonateModal = ref(false)
const showInvestModal = ref(false)
const showDonationsListModal = ref(false)

// Chat slideout states
const showChatSlideout = ref(false)
const chatUser = ref(null)
const chatRoomId = ref(null)

// Donations list state
const donationsList = ref([])
const loadingDonations = ref(false)
const currentPage = ref(1)
const totalPages = ref(1)
const itemsPerPage = 10

const handleDonate = (plan) => {
  if (!plan) return
  
  if (!currentUser.value) {
    toast.add({
      title: 'Login Required',
      description: 'Please login to donate',
      color: 'orange',
      timeout: 3000,
    })
    return
  }

  showDonateModal.value = true
}

const handleInvest = (plan) => {
  if (!plan) return
  
  if (!currentUser.value) {
    toast.add({
      title: 'Login Required',
      description: 'Please login to invest',
      color: 'orange',
      timeout: 3000,
    })
    return
  }

  showInvestModal.value = true
}

const onDonateSuccess = (response) => {
  // Update top donator if returned in response
  if (response?.top_donator) {
    topDonator.value = response.top_donator
  }
  
  toast.add({
    title: 'Thank You!',
    description: 'Your donation has been recorded',
    color: 'green',
  })
}

const onInvestSuccess = (response) => {
  // Update top donator if returned in response
  if (response?.top_donator) {
    topDonator.value = response.top_donator
  }
  
  toast.add({
    title: 'Investment Confirmed',
    description: 'Your investment has been recorded',
    color: 'green',
  })
}

// Show donations list
const showDonationsList = async (page = 1) => {
  if (page === 1) {
    showDonationsListModal.value = true
  }
  loadingDonations.value = true
  currentPage.value = page
  
  try {
    const config = useRuntimeConfig()
    console.log('Fetching donations from:', `${config.public.baseURL}/api/raise-up/posts/${props.plan.id}/donations/?page=${page}&page_size=${itemsPerPage}`)
    const response = await $fetch(`${config.public.baseURL}/api/raise-up/posts/${props.plan.id}/donations/?page=${page}&page_size=${itemsPerPage}`)
    console.log('Donations response:', response)
    donationsList.value = response.donations || []
    totalPages.value = Math.ceil((response.total_donations || 0) / itemsPerPage)
  } catch (error) {
    console.error('Error fetching donations:', error)
    console.error('Error details:', error.response || error.message)
    toast.add({
      title: 'Error',
      description: `Unable to load donations list: ${error.message || 'Unknown error'}`,
      color: 'red',
      timeout: 5000,
    })
  } finally {
    loadingDonations.value = false
  }
}

// Pagination helpers
const goToPage = (page) => {
  if (page >= 1 && page <= totalPages.value && page !== currentPage.value) {
    showDonationsList(page)
  }
}

const nextPage = () => {
  if (currentPage.value < totalPages.value) {
    goToPage(currentPage.value + 1)
  }
}

const prevPage = () => {
  if (currentPage.value > 1) {
    goToPage(currentPage.value - 1)
  }
}

// Helper function for pagination display
const shouldShowPage = (page) => {
  if (totalPages.value <= 5) return true
  if (page <= 3) return true
  if (page >= totalPages.value - 2) return true
  if (Math.abs(page - currentPage.value) <= 1) return true
  return false
}
</script>
