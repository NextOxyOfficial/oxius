<template>
  <div
    v-if="user?.user"
    class="md:max-w-4xl mx-auto mb-4 sm:mb-6 bg-white rounded-xl border border-gray-200 overflow-hidden"
  >
    <!-- Balance + Pending tiles -->
    <div class="p-4 sm:p-5">
      <div class="grid grid-cols-1 sm:grid-cols-2 gap-3">
        <!-- Balance -->
        <div
          class="flex items-center gap-3 rounded-xl border border-emerald-100 bg-emerald-50/60 p-3.5"
        >
          <div
            class="flex h-11 w-11 shrink-0 items-center justify-center rounded-xl bg-emerald-600 text-white"
          >
            <UIcon
              name="i-material-symbols:account-balance-wallet-outline"
              class="text-2xl"
            />
          </div>
          <div class="min-w-0">
            <p class="text-xs font-medium text-emerald-700">
              {{ $t("balance") }}
            </p>
            <p class="text-xl font-bold text-emerald-900 flex items-center gap-0.5">
              <UIcon name="i-mdi:currency-bdt" class="text-lg" />
              <span class="truncate">{{ user?.user.balance }}</span>
            </p>
          </div>
        </div>

        <!-- Pending tasks -->
        <div
          class="flex items-center justify-between gap-2 rounded-xl border border-amber-100 bg-amber-50/60 p-3.5"
        >
          <div class="flex items-center gap-3 min-w-0">
            <div
              class="flex h-11 w-11 shrink-0 items-center justify-center rounded-xl bg-amber-500 text-white"
            >
              <UIcon name="i-ic:outline-watch-later" class="text-2xl" />
            </div>
            <div class="min-w-0">
              <p class="text-xs font-medium text-amber-700">
                {{ $t("pending_task") }}
              </p>
              <p class="text-xl font-bold text-amber-900 flex items-center gap-0.5">
                <UIcon name="i-mdi:currency-bdt" class="text-lg" />
                <span class="truncate">{{ user?.user.pending_balance }}</span>
              </p>
            </div>
          </div>

          <UButton
            size="xs"
            color="amber"
            variant="soft"
            icon="i-mdi-eye-outline"
            :label="t('view')"
            :to="`/pending-tasks/${user?.user.id}`"
            class="shrink-0"
          />
        </div>
      </div>

      <!-- Action buttons -->
      <div class="grid grid-cols-2 md:grid-cols-4 gap-2.5 mt-3.5">
        <UButton
          color="gray"
          variant="soft"
          to="/deposit-withdraw/"
          class="justify-center py-2.5 rounded-xl font-medium text-gray-700 hover:bg-gray-200/70"
          @click="handleButtonClick('transaction')"
        >
          <template #leading>
            <div v-if="loadingButtons.has('transaction')" class="dotted-spinner emerald"></div>
            <UIcon v-else name="i-token:cusd" class="text-emerald-600 text-lg" />
          </template>
          <span v-if="!loadingButtons.has('transaction')" class="text-xs sm:text-sm">{{ t('transaction') }}</span>
        </UButton>

        <UButton
          color="gray"
          variant="soft"
          to="/inbox/"
          class="relative justify-center py-2.5 rounded-xl font-medium text-gray-700 hover:bg-gray-200/70"
          @click="handleButtonClick('inbox')"
        >
          <template #leading>
            <div v-if="loadingButtons.has('inbox')" class="dotted-spinner blue"></div>
            <UIcon v-else name="i-material-symbols:mark-email-unread-outline" class="text-blue-600 text-lg" />
          </template>
          <span v-if="!loadingButtons.has('inbox')" class="text-xs sm:text-sm">{{ t('inbox') }}</span>
          <div
            v-if="badgeCount > 0"
            class="notification-badge absolute -top-1.5 -right-1.5 min-w-5 h-5 flex items-center justify-center rounded-full bg-red-500 text-white text-xs px-1 font-semibold shadow-sm animate-pulse-subtle"
          >
            {{ badgeCount > 99 ? "99+" : badgeCount }}
          </div>
        </UButton>

        <UButton
          color="gray"
          variant="soft"
          :to="isUser ? '/my-gigs/' + user?.user.id : '/my-gigs/'"
          class="justify-center py-2.5 rounded-xl font-medium text-gray-700 hover:bg-gray-200/70"
          @click="handleButtonClick('my-gigs')"
        >
          <template #leading>
            <div v-if="loadingButtons.has('my-gigs')" class="dotted-spinner violet"></div>
            <UIcon v-else name="i-material-symbols:list-rounded" class="text-violet-600 text-lg" />
          </template>
          <span v-if="!loadingButtons.has('my-gigs')" class="text-xs sm:text-sm">{{ t('my_gigs') }}</span>
        </UButton>

        <UButton
          color="gray"
          variant="soft"
          to="/post-a-gig"
          class="justify-center py-2.5 rounded-xl font-medium text-gray-700 hover:bg-gray-200/70"
          @click="handleButtonClick('post-gigs-balance')"
        >
          <template #leading>
            <div v-if="loadingButtons.has('post-gigs-balance')" class="dotted-spinner slate"></div>
            <UIcon v-else name="i-heroicons-plus-circle" class="text-emerald-600 text-lg" />
          </template>
          <span v-if="!loadingButtons.has('post-gigs-balance')" class="text-xs sm:text-sm">{{ t('post_gigs') }}</span>
        </UButton>
      </div>
    </div>

    <!-- Mobile Recharge -->
    <NuxtLink
      to="/mobile-recharge"
      class="group flex items-center justify-between gap-3 px-4 sm:px-5 py-3.5 border-t border-gray-100 hover:bg-gray-50 transition-colors"
    >
      <div class="flex items-center gap-3 min-w-0">
        <div
          class="flex h-10 w-10 shrink-0 items-center justify-center rounded-xl bg-emerald-50 text-emerald-600"
        >
          <UIcon name="i-heroicons-device-phone-mobile" class="w-5 h-5" />
        </div>
        <div class="min-w-0">
          <p class="text-sm font-bold text-gray-900 truncate">
            {{ $t("mobile_recharge") }}
          </p>
          <p class="text-xs text-gray-500 truncate">
            {{ $t("mobile_recharge_subtitle") }}
          </p>
        </div>
      </div>
      <div class="flex items-center gap-3 shrink-0">
        <div v-if="operators?.length" class="hidden sm:flex -space-x-1.5">
          <img
            v-for="op in operators.slice(0, 4)"
            :key="op.id"
            :src="op.icon"
            :title="op.title"
            class="w-7 h-7 rounded-full border-2 border-white bg-white object-contain"
          />
        </div>
        <span class="hidden sm:inline text-sm font-semibold text-emerald-600">
          {{ $t("recharge_now") }}
        </span>
        <UIcon
          name="i-heroicons-arrow-right"
          class="w-4 h-4 text-emerald-600 group-hover:translate-x-0.5 transition-transform"
        />
      </div>
    </NuxtLink>

    <!-- Referral -->
    <div class="px-4 sm:px-5 py-4 border-t border-gray-100 bg-gray-50/60">
      <div class="flex items-center gap-2 mb-2.5">
        <UIcon name="i-heroicons-user-group" class="w-5 h-5 text-emerald-600 shrink-0" />
        <h3 class="text-sm font-bold text-gray-900">{{ $t("refer") }}</h3>
      </div>

      <div class="flex flex-col sm:flex-row gap-3">
        <!-- Link + copy -->
        <div
          class="w-full sm:w-[420px] sm:shrink-0 min-w-0 flex items-center bg-white rounded-lg border border-gray-200 overflow-hidden"
        >
          <input
            type="text"
            class="text-xs sm:text-sm py-2.5 px-3 w-full bg-transparent border-0 focus:ring-0 focus:outline-none text-gray-600 truncate"
            readonly
            :value="referralUrl"
          />
          <UButton
            size="sm"
            color="emerald"
            icon="i-iconamoon-copy-light"
            variant="solid"
            class="m-1 shrink-0"
            @click="CopyToClip(referralUrl)"
          >
            Copy
          </UButton>
        </div>

        <!-- Stats -->
        <div class="flex gap-3 flex-1">
          <div
            class="flex-1 text-center rounded-lg bg-white border border-gray-200 px-4 py-2"
          >
            <p class="text-xs text-gray-500">{{ $t("refer_user") }}</p>
            <p class="text-base font-bold text-emerald-700">
              {{ user.user.refer_count }}
            </p>
          </div>
          <div
            class="flex-1 text-center rounded-lg bg-white border border-gray-200 px-4 py-2"
          >
            <p class="text-xs text-gray-500">{{ $t("earnings") }}</p>
            <p
              class="text-base font-bold text-emerald-700 flex items-center justify-center gap-0.5"
            >
              <UIcon name="i-mdi:currency-bdt" class="text-sm" />
              {{ user.user.commission_earned }}
            </p>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
const { t } = useI18n();
const toast = useToast();
const { totalUnreadCount, fetchUnreadCount } = useTickets();
const badgeCount = ref(0);

// Loading state for buttons
const loadingButtons = ref(new Set());

const handleButtonClick = (buttonId) => {
  loadingButtons.value.add(buttonId);
  setTimeout(() => {
    loadingButtons.value.delete(buttonId);
  }, 3000);
};

const route = useRoute();
watch(
  () => route.path,
  () => {
    loadingButtons.value.clear();
  }
);

watch(
  () => totalUnreadCount.value,
  (newCount) => {
    badgeCount.value = newCount;
  }
);

onMounted(async () => {
  await fetchUnreadCount();
  badgeCount.value = totalUnreadCount.value;
});

const props = defineProps({
  user: {
    type: Object,
    required: true,
  },
  isUser: {
    type: Boolean,
    required: true,
  },
  operators: {
    type: Array,
    default: () => [],
  },
});

const referralUrl = computed(
  () => `https://adsyclub.com/auth/register/?ref=${props.user?.user?.referral_code}`
);

function CopyToClip(text) {
  navigator.clipboard.writeText(text);
  toast.add({
    title: "Link copied",
    color: "emerald",
    icon: "i-heroicons-check-circle",
  });
}
</script>

<style scoped>
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

/* Dotted spinner */
.dotted-spinner {
  width: 1rem;
  height: 1rem;
  border: 2px dotted #2563eb;
  border-radius: 50%;
  animation: spin 1s linear infinite;
  flex-shrink: 0;
}

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
