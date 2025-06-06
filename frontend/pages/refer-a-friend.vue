<template>
  <div>
    <!-- Logged-in User Component -->
    <LoggedInUserView
      v-if="user?.user"
      :user="user"
      :show-share-modal="showShareModal"
      :custom-message="customMessage"
      :is-loading-commissions="isLoadingCommissions"
      :is-loading-users="isLoadingUsers"
      :commission-error="commissionError"
      :users-error="usersError"
      :commission-breakdown="commissionBreakdown"
      :commission-data="commissionData"
      :referred-users="referredUsers"
      :earnings="earnings"
      :tabs="tabs"
      :active-tab="activeTab"
      :current-page="currentPage"
      :filter-period="filterPeriod"
      :filtered-earnings="filteredEarnings"
      :average-commission="averageCommission"
      :best-performing-service="bestPerformingService"
      :this-month-earnings="thisMonthEarnings"
      :growth-rate="growthRate"
      @update:show-share-modal="showShareModal = $event"
      @update:custom-message="customMessage = $event"
      @update:filter-period="filterPeriod = $event"
      @update:current-page="currentPage = $event"
      @copy-to-clip="CopyToClip"
      @share-on-social="shareOnSocial"
      @share-custom-message="shareCustomMessage"
      @get-commission-history="getCommissionHistory"
      @get-referred-users="getReferredUsers"
      @set-active-tab="setActiveTab"
      @export-commissions="exportCommissions"
      @format-date="formatDate"
      @get-service-type-color="getServiceTypeColor"
      @get-commission-rate="getCommissionRate"
    />
    
    <!-- Public User Component -->
    <PublicUserView
      v-else
      :platform-stats="platformStats"
      :is-loading-platform-stats="isLoadingPlatformStats"
      @get-platform-stats="getPlatformStats"    />
  </div>
</template>

<script setup>
import LoggedInUserView from '~/components/refer-friend/LoggedInUserView.vue'
import PublicUserView from '~/components/refer-friend/PublicUserView.vue'

definePageMeta({
  layout: "default",
});

const { user } = useAuth();
const { get } = useApi();
const toast = useToast();

const filterPeriod = ref("All Time");
const currentPage = ref(1);
const activeTab = ref(0);
const indicatorLeft = ref(0);
const indicatorWidth = ref(0);
const referredUsers = ref([]);
const isLoadingCommissions = ref(false);
const isLoadingUsers = ref(false);
const commissionError = ref(null);
const usersError = ref(null);
const showShareModal = ref(false);
const customMessage = ref("Join me on AdSyClub and start earning! Use my referral link to get started: ");
const platformStats = ref({
  active_referrers: 500,
  top_earner_amount: 10000,
  quick_payout_time: "24hr",
  commission_rates: {
    gig_completion: '5%',
    pro_subscription: '20%',
    gold_sponsor: '20%'
  }
});
const isLoadingPlatformStats = ref(false);
const commissionData = ref({
  total_commissions: 0,
  total_earned: 0,
  commission_breakdown: {
    gig_completion: { count: 0, total_amount: 0, rate: '5%', transactions: [] },
    pro_subscription: { count: 0, total_amount: 0, rate: '20%', transactions: [] },
    gold_sponsor: { count: 0, total_amount: 0, rate: '20%', transactions: [] }
  },
  recent_transactions: []
});

// Update custom message with referral link when modal opens
watch(showShareModal, (newValue) => {
  if (newValue === true && user.value?.user?.referral_code) {
    const referralUrl = `https://adsyclub.com/auth/register/?ref=${user.value.user.referral_code}`;
    customMessage.value = `Join me on AdSyClub and start earning! Use my referral link to get started: ${referralUrl}`;
  }
});

async function getPlatformStats() {
  isLoadingPlatformStats.value = true;
  
  try {
    const res = await get("/platform-referral-stats/");
    if (res?.data) {
      platformStats.value = {
        active_referrers: res.data.active_referrers || 0,
        top_earner_amount: res.data.top_earner_amount || 0,
        quick_payout_time: res.data.quick_payout_time || "24hr",
        commission_rates: res.data.commission_rates || {
          gig_completion: '5%',
          pro_subscription: '20%',
          gold_sponsor: '20%'
        }
      };
    }
  } catch (error) {
    console.error("Error fetching platform stats:", error);
    // Keep default values if API fails
  } finally {
    isLoadingPlatformStats.value = false;
  }
}

async function getReferredUsers() {
  isLoadingUsers.value = true;
  usersError.value = null;
  
  try {
    const res = await get("/referred-users/");

    if (res?.data?.referred_users) {
      referredUsers.value = res.data.referred_users;
      tabs.value[1].count = referredUsers.value.length;
    } else if (Array.isArray(res?.data)) {
      referredUsers.value = res.data;
      tabs.value[1].count = referredUsers.value.length;
    } else {
      console.error("Unexpected data format:", res);
      referredUsers.value = [];
      usersError.value = "Unexpected data format received";
    }
  } catch (error) {
    console.error("Error fetching referred users:", error);
    referredUsers.value = [];
    usersError.value = "Failed to load referred users. Please try again.";
    toast.add({ 
      title: "Error", 
      description: "Failed to load referred users", 
      color: "red" 
    });
  } finally {
    isLoadingUsers.value = false;
  }
}

async function getCommissionHistory() {
  isLoadingCommissions.value = true;
  commissionError.value = null;
  
  try {
    const res = await get("/commission-history/");

    if (res?.data) {
      commissionData.value = res.data;      // Update earnings with real data
      earnings.value = res.data.recent_transactions.map(transaction => ({
        date: transaction.date,
        name: transaction.referred_user?.name || 'Unknown User',
        task: transaction.type,
        type_code: transaction.type_code,
        amount: transaction.amount,
        commission_rate: transaction.commission_rate
      }));
      
      // Update tab count
      tabs.value[0].count = res.data.recent_transactions.length;
    }
  } catch (error) {
    console.error("Error fetching commission history:", error);
    commissionError.value = "Failed to load commission history. Please try again.";
    toast.add({ 
      title: "Error", 
      description: "Failed to load commission history", 
      color: "red" 
    });
  } finally {
    isLoadingCommissions.value = false;
  }
}

// Computed properties for commission breakdown
const commissionBreakdown = computed(() => {
  return [
    {
      name: 'Gig Completions',
      type: 'gig_completion',
      rate: '5%',
      count: commissionData.value.commission_breakdown.gig_completion.count,
      amount: commissionData.value.commission_breakdown.gig_completion.total_amount,
      color: 'blue',
      icon: 'i-heroicons-briefcase'
    },
    {
      name: 'Pro Subscriptions',
      type: 'pro_subscription', 
      rate: '20%',
      count: commissionData.value.commission_breakdown.pro_subscription.count,
      amount: commissionData.value.commission_breakdown.pro_subscription.total_amount,
      color: 'purple',
      icon: 'i-heroicons-star'
    },
    {
      name: 'Gold Sponsors',
      type: 'gold_sponsor',
      rate: '20%',
      count: commissionData.value.commission_breakdown.gold_sponsor.count,
      amount: commissionData.value.commission_breakdown.gold_sponsor.total_amount,
      color: 'yellow',
      icon: 'i-heroicons-trophy'
    }
  ];
});

// Analytics computed properties
const averageCommission = computed(() => {
  if (earnings.value.length === 0) return 0;
  const total = earnings.value.reduce((sum, earning) => sum + earning.amount, 0);
  return total / earnings.value.length;
});

const bestPerformingService = computed(() => {
  const breakdown = commissionBreakdown.value;
  if (breakdown.length === 0) return 'No Data';
  const best = breakdown.reduce((max, service) => 
    service.amount > max.amount ? service : max, breakdown[0]);
  return best.name;
});

const thisMonthEarnings = computed(() => {
  const now = new Date();
  const startOfMonth = new Date(now.getFullYear(), now.getMonth(), 1);
  return earnings.value
    .filter(earning => new Date(earning.date) >= startOfMonth)
    .reduce((sum, earning) => sum + earning.amount, 0);
});

const lastMonthEarnings = computed(() => {
  const now = new Date();
  const startOfLastMonth = new Date(now.getFullYear(), now.getMonth() - 1, 1);
  const startOfThisMonth = new Date(now.getFullYear(), now.getMonth(), 1);
  return earnings.value
    .filter(earning => {
      const date = new Date(earning.date);
      return date >= startOfLastMonth && date < startOfThisMonth;
    })
    .reduce((sum, earning) => sum + earning.amount, 0);
});

const growthRate = computed(() => {
  const thisMonth = thisMonthEarnings.value;
  const lastMonth = lastMonthEarnings.value;
  if (lastMonth === 0) return thisMonth > 0 ? 100 : 0;
  return ((thisMonth - lastMonth) / lastMonth) * 100;
});

// Initialize earnings as empty array - will be populated from API
const earnings = ref([]);

// Define tabs with counts from actual data
const tabs = ref([
  {
    name: "Earnings History",
    icon: "i-heroicons-banknotes",
    count: 0, // This will be updated after data is fetched
  },
  {
    name: "Referred Users",
    icon: "i-heroicons-users",
    count: 0, // This will be updated after data is fetched
  },
]);

function CopyToClip(text) {
  navigator.clipboard.writeText(text);
  toast.add({ 
    title: "Link copied", 
    description: "Referral link copied to clipboard",
    color: "green",
    icon: "i-heroicons-check-circle"
  });
}

// Export commission data to CSV
function exportCommissions() {  const csvData = [
    ['Date', 'Referred User', 'Service Type', 'Amount (BDT)'],
    ...filteredEarnings.value.map(earning => [
      formatDate(earning.date),
      earning.name,
      earning.task,
      earning.amount.toFixed(2)
    ])
  ];

  const csvContent = csvData.map(row => row.join(',')).join('\n');
  const blob = new Blob([csvContent], { type: 'text/csv' });
  const url = window.URL.createObjectURL(blob);
  const link = document.createElement('a');
  link.href = url;
  link.download = `commission_history_${new Date().toISOString().split('T')[0]}.csv`;
  document.body.appendChild(link);
  link.click();
  document.body.removeChild(link);
  window.URL.revokeObjectURL(url);

  toast.add({ 
    title: "Export complete", 
    description: "Commission data exported successfully",
    color: "green",
    icon: "i-heroicons-check-circle"
  });
}

// Share on social media
function shareOnSocial(platform) {
  let url = "";
  const text = customMessage.value || "Join me and earn rewards! Use my referral link:";
  const referralLink = `https://adsyclub.com/auth/register/?ref=${user?.user?.referral_code}`;

  switch (platform) {
    case "facebook":
      url = `https://www.facebook.com/sharer/sharer.php?u=${encodeURIComponent(referralLink)}`;
      break;
    case "twitter":
      url = `https://twitter.com/intent/tweet?url=${encodeURIComponent(referralLink)}&text=${encodeURIComponent(text)}`;
      break;
    case "whatsapp":
      url = `https://wa.me/?text=${encodeURIComponent(text + " " + referralLink)}`;
      break;
    case "linkedin":
      url = `https://www.linkedin.com/sharing/share-offsite/?url=${encodeURIComponent(referralLink)}`;
      break;
  }

  if (url) {
    window.open(url, "_blank");
    showShareModal.value = false;
  }
}

// Share with custom message
function shareCustomMessage() {
  const text = customMessage.value || "Join me and earn rewards! Use my referral link:";
  const referralLink = `https://adsyclub.com/auth/register/?ref=${user?.user?.referral_code}`;
  
  if (navigator.share) {
    navigator.share({
      title: 'Join AdSyClub',
      text: text,
      url: referralLink
    });
  } else {
    // Fallback to copying the full message
    const fullMessage = `${text} ${referralLink}`;
    navigator.clipboard.writeText(fullMessage);
    toast.add({ 
      title: "Message copied", 
      description: "Full message with link copied to clipboard",
      color: "green"
    });
  }
  showShareModal.value = false;
}

// Format date function
function formatDate(dateString) {
  return new Date(dateString).toLocaleDateString("en-US", {
    year: "numeric",
    month: "short",
    day: "numeric",
  });
}

// Get service type color for badges
function getServiceTypeColor(typeCode) {
  const colorMap = {
    'gig_completion': 'blue',
    'pro_subscription': 'purple',
    'gold_sponsor': 'yellow'
  };
  return colorMap[typeCode] || 'gray';
}

// Get commission rate for display
function getCommissionRate(typeCode) {
  const rateMap = {
    'gig_completion': '5%',
    'pro_subscription': '20%',
    'gold_sponsor': '20%'
  };
  return rateMap[typeCode] || '5%';
}

// Set active tab and animate the indicator
function setActiveTab(index) {
  activeTab.value = index;
  updateIndicator();
}

// Update the tab indicator position and width
function updateIndicator() {
  const activeButton = document.querySelector(".tab-button.text-primary-600");
  if (activeButton) {
    const navRect = document
      .querySelector(".tab-navigation")
      ?.getBoundingClientRect();

    if (navRect) {
      indicatorLeft.value = activeButton.offsetLeft;
      indicatorWidth.value = activeButton.offsetWidth;
    }
  }
}

// Filter earnings by period
const filteredEarnings = computed(() => {
  if (filterPeriod.value === "All Time") return earnings.value;

  const now = new Date();
  if (filterPeriod.value === "This Month") {
    const startOfMonth = new Date(now.getFullYear(), now.getMonth(), 1);
    return earnings.value.filter(
      (earning) => new Date(earning.date) >= startOfMonth
    );
  } else if (filterPeriod.value === "Last Month") {
    const startOfLastMonth = new Date(now.getFullYear(), now.getMonth() - 1, 1);
    const startOfThisMonth = new Date(now.getFullYear(), now.getMonth(), 1);
    return earnings.value.filter(
      (earning) =>
        new Date(earning.date) >= startOfLastMonth &&
        new Date(earning.date) < startOfThisMonth
    );
  }

  return earnings.value;
});

// Lifecycle hooks
onMounted(() => {
  nextTick(() => {
    updateIndicator();
  });
  // Fetch initial data
  if (user?.value?.user) {
    getReferredUsers();
    getCommissionHistory();
  }
  
  // Always fetch platform stats (public data)
  getPlatformStats();

  // Update indicator on window resize
  window.addEventListener("resize", updateIndicator);
});

onBeforeUnmount(() => {
  window.removeEventListener("resize", updateIndicator);
});
</script>

<style scoped>
/* No scoped styles needed since all styling is now in the components */
</style>
