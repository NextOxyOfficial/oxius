<template>
  <div class="min-h-screen bg-gradient-to-b from-indigo-50 via-white to-white flex items-center justify-center px-1 py-10 overflow-hidden">
    <div class="w-full max-w-md bg-white rounded-2xl border border-slate-200 shadow-sm p-8 text-center relative">
      <a href="https://www.adsyclub.com" class="inline-flex items-center mb-5">
        <img src="https://adsyclub.com/static/frontend/images/logo.png" alt="AdsyClub" class="h-9 w-auto" />
      </a>
      <!-- Loading -->
      <template v-if="state === 'loading'">
        <div class="h-14 w-14 mx-auto rounded-full border-4 border-indigo-200 border-t-indigo-600 animate-spin mb-4"></div>
        <p class="text-slate-600 font-medium">{{ t.confirming }}</p>
      </template>

      <!-- Success / welcome -->
      <template v-else-if="state === 'completed'">
        <div class="confetti" aria-hidden="true">
          <span v-for="n in 18" :key="n" :style="confettiStyle(n)"></span>
        </div>
        <div class="h-20 w-20 mx-auto rounded-full bg-gradient-to-br from-indigo-500 to-violet-500 flex items-center justify-center text-4xl mb-5 shadow-lg">🎉</div>
        <h1 class="text-2xl font-extrabold text-slate-900">{{ t.welcomeTitle }}</h1>
        <p class="text-slate-700 text-sm mt-3 leading-relaxed font-medium">{{ t.thankYou(name, amount) }}</p>
        <p class="text-slate-500 text-sm mt-2 leading-relaxed">{{ t.impact }}</p>
        <a href="https://adsyclub.com"
           class="inline-block mt-7 rounded-xl bg-indigo-600 hover:bg-indigo-700 text-white font-semibold px-7 py-3 text-sm">
          {{ t.backBtn }}
        </a>
      </template>

      <!-- Pending / failed -->
      <template v-else>
        <div class="h-16 w-16 mx-auto rounded-full bg-amber-100 flex items-center justify-center text-3xl mb-4">⏳</div>
        <h1 class="text-xl font-bold text-slate-900">{{ t.pendingTitle }}</h1>
        <p class="text-slate-600 text-sm mt-2">{{ t.pendingMsg }}</p>
        <div class="flex gap-2 justify-center mt-6">
          <button @click="verify" class="rounded-xl border border-slate-300 px-5 py-2.5 text-sm font-semibold text-slate-600 hover:bg-slate-50">{{ t.checkAgain }}</button>
          <a href="/donate" class="rounded-xl bg-indigo-600 hover:bg-indigo-700 text-white px-5 py-2.5 text-sm font-semibold">{{ t.tryAgain }}</a>
        </div>
      </template>

      <p class="text-[11px] text-slate-400 mt-7">
        {{ t.footer }} · <a href="https://www.adsyclub.com" class="text-indigo-600">https://www.adsyclub.com</a>
      </p>
    </div>
  </div>
</template>

<script setup>
definePageMeta({ layout: false });

const runtimeConfig = useRuntimeConfig();
const API = `${runtimeConfig.public.baseURL}/api/alliance`;
const route = useRoute();

const state = ref("loading"); // loading | completed | pending
const amount = ref("");
const name = ref("");
const lang = ref(route.query.lang === "bn" ? "bn" : "en");

const I18N = {
  en: {
    confirming: "Confirming your donation…",
    welcomeTitle: "Welcome to the AdsyClub family!",
    thankYou: (n, a) => `Thank you${n ? ", " + n : ""}! Your donation of ৳${a} was successful.`,
    impact: "You're now part of a movement creating income & employment across Bangladesh. We're thrilled to have your support. 💚",
    backBtn: "Back to AdsyClub",
    pendingTitle: "Payment not confirmed yet",
    pendingMsg: "We couldn't confirm the payment as completed. If you were charged, it will reflect shortly.",
    checkAgain: "Check again",
    tryAgain: "Try again",
    footer: "AdsyClub · Bangladesh",
  },
  bn: {
    confirming: "আপনার ডোনেশন কনফার্ম করা হচ্ছে…",
    welcomeTitle: "AdsyClub পরিবারে স্বাগতম!",
    thankYou: (n, a) => `ধন্যবাদ${n ? " " + n : ""}! আপনার ৳${a} ডোনেশন কমপ্লিট হয়েছে।`,
    impact: "আপনি এখন আমাদের সাথে আছেন — বাংলাদেশের মানুষের জন্য ইনকাম আর কাজের সুযোগ তৈরিতে। আপনার সাপোর্ট পেয়ে আমরা সত্যিই অনেক খুশি। 💚",
    backBtn: "AdsyClub-এ ফিরে যান",
    pendingTitle: "পেমেন্ট এখনো কমপ্লিট হয়নি",
    pendingMsg: "পেমেন্ট কমপ্লিট হয়নি। যদি টাকা কেটে নেওয়া হয়ে থাকে, তা সম্ভবত শীঘ্রই দেখা যাবে।",
    checkAgain: "আবার চেক করুন",
    tryAgain: "আবার চেষ্টা করুন",
    footer: "AdsyClub · বাংলাদেশ",
  },
};
const t = computed(() => I18N[lang.value] || I18N.en);

useHead(() => ({ title: lang.value === "bn" ? "ডোনেশন — AdsyClub" : "Donation — AdsyClub" }));

const PALETTE = ["#6366f1", "#8b5cf6", "#22c55e", "#f59e0b", "#ec4899"];
function confettiStyle(n) {
  const left = (n * 5.3) % 100;
  return {
    left: left + "%",
    background: PALETTE[n % PALETTE.length],
    animationDelay: ((n % 6) * 0.18).toFixed(2) + "s",
    animationDuration: (2.4 + (n % 4) * 0.4).toFixed(2) + "s",
  };
}

async function verify() {
  state.value = "loading";
  const ref_ = route.query.ref;
  const orderId = route.query.order_id;
  if (!ref_) { state.value = "pending"; return; }
  try {
    const q = new URLSearchParams({ ref: ref_ });
    if (orderId) q.append("order_id", orderId);
    const res = await $fetch(`${API}/donate/verify/?${q.toString()}`);
    amount.value = res.amount || "";
    name.value = res.name || "";
    if (res.language === "bn" || res.language === "en") lang.value = res.language;
    state.value = res.status === "completed" ? "completed" : "pending";
  } catch {
    state.value = "pending";
  }
}

onMounted(verify);
</script>

<style scoped>
.confetti { position: absolute; inset: 0; pointer-events: none; overflow: hidden; }
.confetti span {
  position: absolute; top: -12px; width: 9px; height: 14px; border-radius: 2px;
  opacity: 0; animation-name: fall; animation-timing-function: ease-in; animation-iteration-count: 1;
}
@keyframes fall {
  0% { transform: translateY(-10px) rotate(0deg); opacity: 0; }
  10% { opacity: 1; }
  100% { transform: translateY(420px) rotate(540deg); opacity: 0; }
}
</style>
