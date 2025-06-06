<template>
  <div
    class="bg-white dark:bg-slate-800 border border-slate-100 dark:border-slate-700 rounded-lg px-3 py-4 transition-all duration-300 cursor-pointer relative overflow-hidden hover:shadow-sm group transform hover:shadow-sm"
    @click="$emit('click', problem)"
  >
    <!-- Premium subtle background patterns with gradient overlay -->
    <div
      class="absolute inset-0 opacity-5 bg-grid-pattern pointer-events-none"
    ></div>

    <!-- Enhanced highlight effect on hover -->
    <div
      :class="[
        'absolute inset-0 opacity-0 group-hover:opacity-20 transition-all duration-300 pointer-events-none',
        problem.status === 'solved'
          ? 'bg-gradient-to-br from-emerald-400 to-green-500'
          : isOwnerProblem
          ? 'bg-gradient-to-br from-indigo-400 to-purple-500'
          : 'bg-gradient-to-br from-blue-400 to-violet-500',
      ]"
    ></div>

    <div class="flex justify-between items-start mb-2 relative">
      <div class="flex items-center">
        <div
          class="size-12 rounded-full border-2 border-white dark:border-slate-700 shadow-sm relative glow-effect"
        >
          <!-- Pro user border with gradient effect -->
          <div
            v-if="problem?.user_details?.is_pro"
            class="absolute inset-0 rounded-full pro-border-ring z-20"
            style="pointer-events: none"
          ></div>
          <div
            class="absolute inset-0 bg-gradient-to-br from-blue-400 to-violet-500 opacity-0 z-10"
          ></div>
          <img
            :src="problem?.user_details?.image || '/static/frontend/images/placeholder.jpg'"
            :alt="problem?.user_details?.name"
            class="h-full w-full object-cover relative z-15 rounded-full overflow-hidden"
            style="object-fit: cover; aspect-ratio: 1/1"
          />
          <!-- Pro text badge with increased z-index -->
          <div
            v-if="problem?.user_details?.is_pro"
            class="absolute -bottom-1 -right-1 bg-gradient-to-r from-[#7f00ff] to-[#e100ff] text-white rounded-full px-1.5 py-0.5 flex items-center justify-center shadow-sm z-40 text-[9px] font-medium"
            style="border: 1px solid rgba(255, 255, 255, 0.5)"
          >
            PRO
          </div>
          <!-- Subtle glow effect on hover -->
          <div
            :class="[
              'absolute inset-0 rounded-full opacity-0 group-hover:opacity-100 transition-opacity duration-300 blur-md -z-10',
              'bg-gradient-to-r from-[#7f00ff]/20 to-[#e100ff]/20',
            ]"
          ></div>
        </div>
        <div class="ml-2 sm:ml-3">
          <div class="inline-flex items-center space-x-1">
            <h1 class="text-base font-medium flex items-center gap-1.5">
              {{ problem?.user_details?.name }}
              <div class="relative inline-flex tooltip-container">
                <UIcon
                  v-if="problem?.user_details?.kyc"
                  name="i-mdi-check-decagram"
                  class="w-4 h-4 text-blue-600 animate-pulse-subtle"
                />
              </div>
              <span
                v-if="problem?.user_details?.is_topcontributor"
                class="px-1.5 py-0.5 bg-gradient-to-r from-amber-500 to-yellow-500 text-white rounded-full text-xs font-medium shadow-sm"
              >
                <div class="flex items-center gap-1">
                  <Trophy class="size-3" />
                  <span class="text-2xs">Top Contributor</span>
                </div>
              </span>
              <!-- Verified badge for mobile -->
            </h1>
          </div>
          <div class="flex items-center text-sm text-slate-500">
            <Clock class="h-3 w-3 mr-1" />
            <span>{{ formatTimeAgo(problem?.created_at) }}</span>
          </div>
        </div>
      </div>
    </div>

    <h3
      class="text-base sm:text-base font-medium text-gray-800 dark:text-slate-200 group-hover:text-blue-600 dark:group-hover:text-blue-400 transition-colors line-clamp-2"
      :class="{
        'group-hover:text-emerald-600 dark:group-hover:text-emerald-400':
          problem.status === 'solved',
        'group-hover:text-indigo-600 dark:group-hover:text-indigo-400':
          isOwnerProblem,
      }"
    >
      {{ problem?.title }}
    </h3>

    <div class="flex items-center mt-1 gap-1">
      <span
        v-if="problem?.payment_option === 'paid'"
        class="inline-flex items-center rounded-full px-2.5 py-0.5 sm:px-3 sm:py-1 text-sm font-medium transition-all border-0 bg-emerald-50 dark:bg-emerald-900/30 text-emerald-700 dark:text-emerald-400 shadow-sm"
      >
        {{ problem?.payment_amount > 0 ? `I can pay ` : "Paid Help" }}
        <span
          v-if="problem?.payment_amount > 0"
          class="inline-flex items-center"
        >
          <UIcon
            name="i-mdi-currency-bdt"
            class="text-emerald-600 dark:text-emerald-400"
          />
          {{ problem?.payment_amount }}
        </span>
      </span>
      <span
        v-else
        class="inline-flex items-center rounded-full px-2.5 py-0.5 sm:px-3 sm:py-1 text-sm font-medium transition-all border-0 bg-blue-50 dark:bg-blue-900/30 text-blue-700 dark:text-blue-400 shadow-sm"
      >
        Free help needed
      </span>
      <span
        class="inline-flex items-center rounded-full px-2.5 py-0.5 text-sm font-medium transition-all bg-slate-100 dark:bg-slate-700 text-slate-700 dark:text-slate-300 shadow-sm"
      >
        {{ problem?.category_details?.name }}
      </span>
    </div>
    <!-- Description preview with truncation -->
    <!-- <p class="mt-1.5 text-sm text-gray-600 dark:text-slate-400 line-clamp-2">
      {{ problem?.description }}
    </p> -->

    <div class="mt-4 flex items-center justify-between relative">
      <div class="flex items-center space-x-4">
        <span
          class="text-sm text-gray-600 dark:text-slate-400 flex items-center group"
        >
          <div
            class="p-1 rounded-full bg-slate-100 dark:bg-slate-700 mr-1.5 group-hover:bg-blue-100 dark:group-hover:bg-blue-900/30 transition-colors"
          >
            <MessageSquare
              class="h-3 w-3 sm:h-3.5 sm:w-3.5 group-hover:text-blue-500 transition-colors"
            />
          </div>
          <span
            class="group-hover:text-blue-500 dark:group-hover:text-blue-400 transition-colors"
          >
            {{ problem?.mindforce_comments?.length || 0 }}
          </span>
        </span>

        <span
          class="text-sm text-slate-500 dark:text-slate-500 flex items-center"
        >
          <div class="p-1 rounded-full bg-slate-100 dark:bg-slate-700 mr-1.5">
            <Eye class="h-3 w-3 sm:h-3.5 sm:w-3.5" />
          </div>
          {{ problem?.views || 0 }}
        </span>
      </div>

      <span
        v-if="problem?.status === 'solved'"
        class="inline-flex items-center rounded-full px-2.5 py-0.5 text-sm font-medium bg-gradient-to-r from-emerald-500 to-green-500 text-white shadow-sm"
      >
        <CheckCircle class="h-3 w-3 mr-1" /> Solved
      </span>
    </div>

    <!-- Shimmer effect on hover -->
    <div
      class="absolute inset-0 bg-gradient-to-r from-transparent via-white/20 to-transparent shimmer opacity-0 group-hover:opacity-100 pointer-events-none"
    ></div>
  </div>
</template>

<script setup>
import {
  MessageSquare,
  Eye,
  CheckCircle,
  Clock,
  Trophy,
} from "lucide-vue-next";
import { computed } from "vue";

const props = defineProps({
  problem: {
    type: Object,
    required: true,
  },
  currentUserId: {
    type: [String, Number],
    default: null,
  },
});

const emit = defineEmits(["click", "photo-view"]);

const isOwnerProblem = computed(() => {
  return props.problem?.user_details?.id === props.currentUserId;
});

// Time formatting function
const formatTimeAgo = (dateString) => {
  const date = new Date(dateString);
  const now = new Date();
  const diffInSeconds = Math.floor((now.getTime() - date.getTime()) / 1000);

  if (diffInSeconds < 60) {
    return `${Math.abs(diffInSeconds)} ${
      diffInSeconds === 1 ? "second" : "seconds"
    } ago`;
  }

  const diffInMinutes = Math.floor(diffInSeconds / 60);
  if (diffInMinutes < 60) {
    return `${Math.abs(diffInMinutes)} ${
      diffInMinutes === 1 ? "minute" : "minutes"
    } ago`;
  }

  const diffInHours = Math.floor(diffInMinutes / 60);
  if (diffInHours < 24) {
    return `${Math.abs(diffInHours)} ${
      diffInHours === 1 ? "hour" : "hours"
    } ago`;
  }

  const diffInDays = Math.floor(diffInHours / 24);
  if (diffInDays < 30) {
    return `${Math.abs(diffInDays)} ${diffInDays === 1 ? "day" : "days"} ago`;
  }

  const diffInMonths = Math.floor(diffInDays / 30);
  return `${Math.abs(diffInMonths)} ${
    diffInMonths === 1 ? "month" : "months"
  } ago`;
};
</script>

<style scoped>
/* Grid background pattern */
.bg-grid-pattern {
  background-image: linear-gradient(
      to right,
      rgba(0, 0, 0, 0.05) 1px,
      transparent 1px
    ),
    linear-gradient(to bottom, rgba(0, 0, 0, 0.05) 1px, transparent 1px);
  background-size: 20px 20px;
}

@media (prefers-color-scheme: dark) {
  .bg-grid-pattern {
    background-image: linear-gradient(
        to right,
        rgba(255, 255, 255, 0.05) 1px,
        transparent 1px
      ),
      linear-gradient(to bottom, rgba(255, 255, 255, 0.05) 1px, transparent 1px);
  }
}

/* Shimmer effect */
.shimmer {
  background-size: 1000px 100%;
  animation: none;
}

.group:hover .shimmer {
  animation: shimmer 2s infinite;
}

@keyframes shimmer {
  0% {
    background-position: -1000px 0;
  }
  100% {
    background-position: 1000px 0;
  }
}

/* Glow effect for profile images */
.glow-effect::before {
  content: "";
  position: absolute;
  top: -2px;
  left: -2px;
  right: -2px;
  bottom: -2px;
  background: linear-gradient(45deg, #4f46e5, #06b6d4);
  border-radius: 50%;
  z-index: 0;
  opacity: 0;
  transition: opacity 0.3s ease;
}

.glow-effect:hover::before {
  opacity: 0.5;
}

/* Line clamp for text truncation */
.line-clamp-2 {
  display: -webkit-box;
  -webkit-line-clamp: 2;
  -webkit-box-orient: vertical;
  overflow: hidden;
}

/* Pro user border with gradient effect */
.pro-border-ring {
  border-radius: 9999px; /* Ensure full circle */
  border: 2px solid transparent;
  background: linear-gradient(to right, #7f00ff, #e100ff, #9500ff, #d700ff)
    border-box;
  -webkit-mask: linear-gradient(#fff 0 0) padding-box, linear-gradient(#fff 0 0);
  -webkit-mask-composite: xor;
  mask-composite: exclude;
}

/* Subtle pulse animation for verified badge */
@keyframes pulse-subtle {
  0% {
    opacity: 0.8;
  }
  50% {
    opacity: 1;
  }
  100% {
    opacity: 0.8;
  }
}

.animate-pulse-subtle {
  animation: pulse-subtle 2s ease-in-out infinite;
}
</style>
