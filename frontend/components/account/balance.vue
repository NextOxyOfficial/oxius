<template>
  <UCard
    v-if="user?.user"
    class="md:max-w-4xl mx-auto mb-4 sm:mb-8 overflow-hidden transition-all duration-500 hover:shadow-sm"
    :ui="{
      rounded: 'rounded-xl',
      body: {
        padding: 'p-0',
      },
      ring: '',
      base: 'bg-gradient-to-br from-green-100 to-teal-100/60   border border-dashed border-emerald-400/70',
    }"
  >
    <!-- Decorative elements -->
    <div
      class="absolute top-0 right-0 w-32 h-32 bg-emerald-100/20 rounded-full -z-10"
    ></div>
    <div
      class="absolute bottom-0 left-0 w-40 h-40 bg-teal-300/10 rounded-full -z-10"
    ></div>

    <!-- Header with balance info -->
    <div class="relative p-4 sm:p-6 overflow-hidden">
      <!-- Decorative pattern -->
      <div class="absolute top-0 right-0 opacity-5 pointer-events-none">
        <svg
          width="200"
          height="200"
          viewBox="0 0 100 100"
          xmlns="http://www.w3.org/2000/svg"
        >
          <path fill="currentColor" d="M0,0 L100,0 L100,100 L0,100 Z" />
          <path
            fill="none"
            stroke="currentColor"
            stroke-width="1"
            d="M0,0 L100,100 M100,0 L0,100"
          />
          <circle
            cx="50"
            cy="50"
            r="30"
            fill="none"
            stroke="currentColor"
            stroke-width="1"
          />
        </svg>
      </div>

      <div class="flex flex-col md:flex-row justify-between gap-4 sm:gap-6">
        <!-- Main balance -->
        <div
          class="balance-container group bg-white rounded-xl p-4 shadow-sm hover:shadow-sm transition-all duration-300 border border-emerald-300"
        >
          <div class="flex items-center gap-3">
            <div
              class="flex-shrink-0 w-12 h-12 rounded-full bg-gradient-to-br from-emerald-500 to-teal-500 flex items-center justify-center shadow-sm"
            >
              <UIcon
                name="i-material-symbols:account-balance-wallet-outline"
                class="text-white text-xl"
              />
            </div>
            <div>
              <p class="text-sm text-emerald-700 font-medium">
                {{ $t("balance") }}
              </p>
              <h3
                class="text-xl font-semibold text-emerald-900 flex items-center gap-1 group-hover:scale-105 transition-transform duration-300"
              >
                <UIcon
                  name="i-mdi:currency-bdt"
                  class="text-xl text-emerald-600"
                />
                <span class="balance-value">{{ user?.user.balance }}</span>
              </h3>
            </div>
          </div>
        </div>

        <!-- Pending tasks -->
        <div
          class="pending-container group bg-white dark:bg-slate-800 rounded-xl p-4 shadow-sm hover:shadmd-lg transition-all duration-300 border border-amber-200"
        >
          <div class="flex items-center justify-between">
            <div class="flex items-center gap-3">
              <div
                class="flex-shrink-0 w-12 h-12 rounded-full bg-gradient-to-br from-amber-400 to-orange-400 flex items-center justify-center shadow-sm"
              >
                <UIcon
                  name="i-ic:outline-watch-later"
                  class="text-white text-xl"
                />
              </div>
              <div>
                <p class="text-sm text-amber-700 font-medium">
                  {{ $t("pending_task") }}
                </p>
                <h3
                  class="text-xl font-semibold text-amber-900 flex items-center gap-1 group-hover:scale-105 transition-transform duration-300"
                >
                  <UIcon
                    name="i-mdi:currency-bdt"
                    class="text-xl text-amber-600"
                  />
                  <span class="pending-value">{{
                    user?.user.pending_balance
                  }}</span>
                </h3>
              </div>
            </div>

            <UButton
              size="md"
              color="amber"
              variant="ghost"
              icon="i-mdi-eye-outline"
              :label="t('view')"
              :to="`/pending-tasks/${user?.user.id}`"
              class="ml-2 hover:scale-105 transition-transform duration-300"
              :ui="{
                padding: {
                  sm: 'px-3 py-2',
                },
                base: 'font-medium',
              }"
            />
          </div>
        </div>
      </div>

      <!-- Action buttons -->
      <div class="grid grid-cols-2 md:grid-cols-4 gap-3 mt-6">        <UButton
          size="md"
          color="emerald"
          variant="soft"
          to="/deposit-withdraw/"
          class="action-button justify-center py-3 rounded-xl shadow-sm hover:shadow-sm transition-all duration-300 hover:scale-102 bg-gradient-to-r from-emerald-500/10 to-emerald-500/5"
          :ui="{
            base: 'font-medium',
          }"
          @click="handleButtonClick('transaction')"
        >
          <template #leading>
            <div v-if="loadingButtons.has('transaction')" class="dotted-spinner emerald"></div>
            <UIcon v-else name="i-token:cusd" />
          </template>
          <span v-if="!loadingButtons.has('transaction')">{{ t('transaction') }}</span>
        </UButton>        <UButton
          size="md"
          color="blue"
          variant="soft"
          to="/inbox/"
          class="action-button justify-center py-3 rounded-xl shadow-sm hover:shadow-sm transition-all duration-300 hover:scale-102 bg-gradient-to-r from-blue-500/10 to-blue-500/5 relative"
          :ui="{
            base: 'font-medium',
          }"
          @click="handleButtonClick('inbox')"
        >
          <template #leading>
            <div v-if="loadingButtons.has('inbox')" class="dotted-spinner blue"></div>
            <UIcon v-else name="i-material-symbols:mark-email-unread-outline" />
          </template>
          <span v-if="!loadingButtons.has('inbox')">{{ t('inbox') }}</span>
          <div
            v-if="badgeCount > 0"
            class="notification-badge absolute top-1 right-16 min-w-5 h-5 flex items-center justify-center rounded-full bg-red-500 text-white text-xs px-1 font-semibold shadow-sm animate-pulse-subtle"
          >
            {{ badgeCount > 99 ? "99+" : badgeCount }}
          </div>
        </UButton>        <UButton
          size="md"
          color="violet"
          variant="soft"
          :to="isUser ? '/my-gigs/' + user?.user.id : '/my-gigs/'"
          class="action-button justify-center py-3 rounded-xl shadow-sm hover:shadow-sm transition-all duration-300 hover:scale-102 bg-gradient-to-r from-violet-500/10 to-violet-500/5"
          :ui="{
            base: 'font-medium',
          }"
          @click="handleButtonClick('my-gigs')"
        >
          <template #leading>
            <div v-if="loadingButtons.has('my-gigs')" class="dotted-spinner violet"></div>
            <UIcon v-else name="i-material-symbols:list-rounded" />
          </template>
          <span v-if="!loadingButtons.has('my-gigs')">{{ t('my_gigs') }}</span>
        </UButton><UButton
          size="md"
          color="slate"
          variant="soft"
          to="/post-a-gig"
          class="action-button justify-center py-3 rounded-xl shadow-sm hover:shadow-sm transition-all duration-300 hover:scale-102 bg-gradient-to-r from-slate-500/10 to-slate-500/5"
          :ui="{
            base: 'font-medium',
          }"
          @click="handleButtonClick('post-gigs-balance')"
        >
          <template #leading>
            <div v-if="loadingButtons.has('post-gigs-balance')" class="dotted-spinner slate"></div>
            <UIcon v-else name="i-heroicons-plus-circle" />
          </template>
          <span v-if="!loadingButtons.has('post-gigs-balance')">{{ t('post_gigs') }}</span>
        </UButton>
      </div>
    </div>

    <!-- Divider with dot accent -->
    <div class="relative">
      <UDivider class="my-1" />
      <div
        class="absolute top-1/2 left-1/2 transform -translate-x-1/2 -translate-y-1/2 w-6 h-6 rounded-full bg-white dark:bg-slate-800 border-2 border-emerald-200 dark:border-emerald-800 flex items-center justify-center"
      >
        <div class="w-2 h-2 rounded-full bg-emerald-500"></div>
      </div>
    </div>

    <!-- Referral section -->
    <div
      class="p-4 sm:p-6 bg-gradient-to-br from-white/50 to-emerald-50/50 dark:from-slate-900/50 dark:to-emerald-950/30"
    >
      <div class="flex flex-col gap-4">
        <div class="text-center w-full flex flex-col items-center gap-3">
          <h3
            class="font-semibold text-emerald-800 dark:text-emerald-300 flex items-center gap-2"
          >
            <UIcon
              name="i-heroicons-user-group"
              class="text-emerald-600 dark:text-emerald-400"
            />
            {{ $t("refer") }}
          </h3>
          <div class="relative w-full max-w-md mx-auto">
            <div
              class="flex items-center bg-white dark:bg-slate-800 rounded-lg overflow-hidden border border-emerald-200 dark:border-emerald-700"
            >
              <input
                type="text"
                class="text-sm py-3 px-4 w-full bg-transparent border-0 focus:ring-0 focus:outline-none text-slate-700 dark:text-slate-200"
                readonly
                :value="`https://adsyclub.com/auth/register/?ref=${user.user.referral_code}`"
              />
              <UButton
                size="sm"
                color="emerald"
                icon="i-iconamoon-copy-light"
                variant="solid"
                class="m-1"
                @click="
                  CopyToClip(
                    `https://adsyclub.com/auth/register/?ref=${user.user.referral_code}`
                  )
                "
                :ui="{
                  base: 'font-medium',
                }"
              >
                Copy
              </UButton>
            </div>
          </div>
        </div>
        <!-- Referral stats -->
        <div
          class="flex gap-6 justify-center items-center bg-white/80 rounded-xl p-3"
        >
          <div class="flex flex-col items-center">
            <p class="text-sm text-slate-500 dark:text-slate-400">
              {{ $t("refer_user") }}
            </p>
            <p
              class="text-xl font-semibold text-emerald-700 dark:text-emerald-400"
            >
              {{ user.user.refer_count }}
            </p>
          </div>

          <div class="h-10 w-px bg-slate-200 dark:bg-slate-700"></div>

          <div class="flex flex-col items-center">
            <p class="text-sm text-slate-500 dark:text-slate-400">
              {{ $t("earnings") }}
            </p>
            <p
              class="text-xl font-semibold text-emerald-700 dark:text-emerald-400 flex items-center"
            >
              <UIcon name="i-mdi:currency-bdt" class="text-lg" />
              {{ user.user.commission_earned }}
            </p>
          </div>
        </div>
      </div>
    </div>
  </UCard>
</template>

<script setup>
const { user } = useAuth();
const { t } = useI18n();
const toast = useToast();
const { unreadTicketCount, totalUnreadCount, fetchUnreadCount } = useTickets();
const badgeCount = ref(0);

// Loading state for buttons
const loadingButtons = ref(new Set());

// Function to handle button click and show loading
const handleButtonClick = (buttonId) => {
  loadingButtons.value.add(buttonId);
  // Remove loading state after navigation (cleanup happens in route change)
  setTimeout(() => {
    loadingButtons.value.delete(buttonId);
  }, 3000); // Fallback timeout
};

// Watch for route changes to clear loading states
const route = useRoute();
watch(() => route.path, () => {
  loadingButtons.value.clear();
});

// Update badge count when totalUnreadCount changes
watch(
  () => totalUnreadCount.value,
  (newCount) => {
    badgeCount.value = newCount;
  }
);

// Fetch unread ticket count when component mounts
onMounted(async () => {
  await fetchUnreadCount();
  badgeCount.value = totalUnreadCount.value;
});

defineProps({
  user: {
    type: Object,
    required: true,
  },
  isUser: {
    type: Boolean,
    required: true,
  },
});

function CopyToClip(text) {
  //Copy text to clipboard
  navigator.clipboard.writeText(text);
  toast.add({
    title: "Link copied",
    color: "emerald",
    icon: "i-heroicons-check-circle",
  });
}
</script>

<style scoped>
/* Premium animations */
@keyframes pulse-subtle {
  0%,
  100% {
    opacity: 0.8;
  }
  50% {
    opacity: 1;
  }
}

.balance-value,
.pending-value {
  position: relative;
  display: inline-block;
}

.balance-value::after,
.pending-value::after {
  content: "";
  position: absolute;
  bottom: -2px;
  left: 0;
  width: 100%;
  height: 2px;
  background: currentColor;
  transform: scaleX(0);
  transform-origin: right;
  transition: transform 0.3s ease;
  opacity: 0.5;
}

.balance-container:hover .balance-value::after,
.pending-container:hover .pending-value::after {
  transform: scaleX(1);
  transform-origin: left;
}

.action-button {
  position: relative;
  overflow: hidden;
}

.action-button::after {
  content: "";
  position: absolute;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  background: linear-gradient(
    to right,
    transparent,
    rgba(255, 255, 255, 0.2),
    transparent
  );
  transform: translateX(-100%);
  transition: transform 0.6s ease;
}

.action-button:hover::after {
  transform: translateX(100%);
}

/* Scale utility */
.hover\:scale-102:hover {
  transform: scale(1.02);
}

/* Notification badge animation */
@keyframes pulse-subtle {
  0%,
  100% {
    opacity: 0.9;
  }
  50% {
    opacity: 1;
  }
}

.animate-pulse-subtle {
  animation: pulse-subtle 2s ease-in-out infinite;
}

.notification-badge {
  transform-origin: center;
  transition: all 0.3s ease;
}

/* Notification badge hover effect */
.action-button:hover .notification-badge {
  transform: scale(1.1);
}

/* Dotted Spinner Styles */
.dotted-spinner {
  width: 1rem;
  height: 1rem;
  border: 2px dotted #2563eb;
  border-radius: 50%;
  animation: spin 1s linear infinite;
  flex-shrink: 0;
}

/* Color variations for dotted spinner */
.dotted-spinner.slate {
  border-color: #64748b;
}

.dotted-spinner.emerald {
  border-color: #059669;
}

.dotted-spinner.blue {
  border-color: #2563eb;
}

.dotted-spinner.violet {
  border-color: #7c3aed;
}

@keyframes spin {
  from {
    transform: rotate(0deg);
  }
  to {
    transform: rotate(360deg);
  }
}
</style>
