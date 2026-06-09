<template>
  <main class="min-h-screen bg-slate-50">
    <section class="mx-auto max-w-6xl px-4 py-8 sm:py-10">
      <div
        class="overflow-hidden rounded-3xl border border-emerald-100 bg-white shadow-sm"
      >
        <div
          class="grid gap-0 lg:grid-cols-[1.05fr_0.95fr]"
        >
          <div class="p-5 sm:p-8 lg:p-10">
            <div
              class="mb-4 inline-flex items-center gap-2 rounded-full border border-emerald-100 bg-emerald-50 px-3 py-1.5 text-xs font-semibold text-emerald-700"
            >
              <UIcon name="i-heroicons-gift" class="h-4 w-4" />
              {{ offerName }}
            </div>

            <h1
              class="max-w-2xl text-3xl font-extrabold leading-tight tracking-tight text-slate-950 sm:text-4xl lg:text-5xl"
            >
              Refer friends and earn rewards together
            </h1>

            <p class="mt-4 max-w-xl text-sm leading-6 text-slate-600 sm:text-base">
              Invite a friend to AdsyClub. When your friend completes the simple
              joining tasks, both accounts unlock the New Year reward.
            </p>

            <div class="mt-6 grid max-w-xl grid-cols-2 gap-3">
              <div
                class="rounded-2xl border border-emerald-100 bg-emerald-50/70 p-4"
              >
                <p class="text-xs font-semibold uppercase tracking-wide text-emerald-700">
                  You earn
                </p>
                <p class="mt-1 text-3xl font-black text-emerald-700">
                  {{ formatMoney(referrerReward) }}
                </p>
              </div>
              <div class="rounded-2xl border border-cyan-100 bg-cyan-50/70 p-4">
                <p class="text-xs font-semibold uppercase tracking-wide text-cyan-700">
                  Friend earns
                </p>
                <p class="mt-1 text-3xl font-black text-cyan-700">
                  {{ formatMoney(refereeReward) }}
                </p>
              </div>
            </div>

            <div class="mt-6 flex flex-wrap items-center gap-3">
              <NuxtLink
                :to="user?.user ? '/refer-a-friend' : '/auth/register'"
                class="inline-flex items-center justify-center rounded-xl bg-emerald-600 px-5 py-3 text-sm font-bold text-white shadow-sm transition hover:bg-emerald-700"
              >
                {{ user?.user ? "Start referring" : "Join and start earning" }}
                <UIcon name="i-heroicons-arrow-right" class="ml-2 h-4 w-4" />
              </NuxtLink>
              <NuxtLink
                to="/refer-a-friend"
                class="inline-flex items-center justify-center rounded-xl border border-slate-200 bg-white px-5 py-3 text-sm font-bold text-slate-700 transition hover:bg-slate-50"
              >
                View referral dashboard
              </NuxtLink>
            </div>
          </div>

          <div
            class="border-t border-slate-100 bg-gradient-to-br from-emerald-600 to-teal-600 p-5 text-white sm:p-8 lg:border-l lg:border-t-0 lg:p-10"
          >
            <div class="rounded-3xl bg-white/12 p-5 ring-1 ring-white/20">
              <div class="flex items-center justify-between gap-3">
                <div>
                  <p class="text-sm font-semibold text-emerald-50">
                    Unlock requirements
                  </p>
                  <h2 class="mt-1 text-2xl font-black">3 simple tasks</h2>
                </div>
                <div
                  class="flex h-12 w-12 items-center justify-center rounded-2xl bg-white text-emerald-700"
                >
                  <UIcon name="i-heroicons-check-badge" class="h-7 w-7" />
                </div>
              </div>

              <div class="mt-6 space-y-3">
                <div
                  v-for="task in tasks"
                  :key="task.title"
                  class="flex items-center gap-3 rounded-2xl bg-white/12 p-3 ring-1 ring-white/15"
                >
                  <div
                    class="flex h-9 w-9 shrink-0 items-center justify-center rounded-xl bg-white text-emerald-700"
                  >
                    <UIcon :name="task.icon" class="h-5 w-5" />
                  </div>
                  <div>
                    <p class="text-sm font-bold">{{ task.title }}</p>
                    <p class="text-xs leading-5 text-emerald-50/85">
                      {{ task.description }}
                    </p>
                  </div>
                </div>
              </div>

              <div
                class="mt-5 rounded-2xl bg-white p-4 text-slate-900 shadow-sm"
              >
                <p class="text-xs font-bold uppercase tracking-wide text-slate-500">
                  Reward summary
                </p>
                <p class="mt-1 text-sm font-semibold leading-6">
                  Complete all tasks once. Rewards are added to AdsyPay balance
                  after successful claim.
                </p>
              </div>
            </div>
          </div>
        </div>
      </div>

      <div class="mt-5 grid gap-4 md:grid-cols-3">
        <div
          v-for="step in steps"
          :key="step.title"
          class="rounded-2xl border border-slate-200 bg-white p-5 shadow-sm"
        >
          <div class="flex items-center gap-3">
            <div
              class="flex h-10 w-10 items-center justify-center rounded-xl bg-slate-100 text-slate-700"
            >
              <UIcon :name="step.icon" class="h-5 w-5" />
            </div>
            <h3 class="text-base font-extrabold text-slate-900">
              {{ step.title }}
            </h3>
          </div>
          <p class="mt-3 text-sm leading-6 text-slate-600">
            {{ step.description }}
          </p>
        </div>
      </div>
    </section>
  </main>
</template>

<script setup>
definePageMeta({
  layout: "default",
});

const { user } = useAuth();
const { get } = useApi();

const program = ref(null);

const offerName = computed(
  () => program.value?.program?.name || "2026 New Year Reward"
);
const referrerReward = computed(
  () => program.value?.program?.referrer_reward || 100
);
const refereeReward = computed(
  () => program.value?.program?.referee_reward || 50
);

const tasks = [
  {
    title: "Post on Business Network",
    description: "Create one useful post from the referred account.",
    icon: "i-heroicons-document-text",
  },
  {
    title: "Verify KYC",
    description: "Complete identity verification for account safety.",
    icon: "i-heroicons-identification",
  },
  {
    title: "Complete one MicroGig",
    description: "Finish one task through the MicroGigs workspace.",
    icon: "i-heroicons-briefcase",
  },
];

const steps = [
  {
    title: "Share link",
    description:
      "Open your referral dashboard and share your unique invite link with friends.",
    icon: "i-heroicons-link",
  },
  {
    title: "Friend joins",
    description:
      "Your friend signs up with your link and completes the required tasks.",
    icon: "i-heroicons-user-plus",
  },
  {
    title: "Claim reward",
    description:
      "When all requirements are complete, claim the reward to your AdsyPay balance.",
    icon: "i-heroicons-banknotes",
  },
];

function formatMoney(value) {
  const amount = Number(value || 0);
  return `৳${Number.isInteger(amount) ? amount : amount.toFixed(2)}`;
}

async function getRewardProgram() {
  try {
    const res = await get("/referral-rewards/program/");
    if (res?.data) {
      program.value = res.data;
    }
  } catch (error) {
    console.error("Error fetching reward program:", error);
  }
}

onMounted(() => {
  getRewardProgram();
});
</script>
