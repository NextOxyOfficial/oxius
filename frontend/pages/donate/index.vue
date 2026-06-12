<template>
  <div class="min-h-screen bg-gradient-to-b from-indigo-50 via-white to-white flex items-center justify-center px-1 py-10">
    <div class="w-full max-w-md">
      <!-- Brand -->
      <div class="text-center mb-6">
        <a href="https://www.adsyclub.com" class="inline-flex items-center">
          <img src="https://adsyclub.com/static/frontend/images/logo.png" alt="AdsyClub" class="h-11 w-auto" />
        </a>
      </div>

      <!-- Personalized greeting -->
      <div class="bg-white rounded-2xl border border-slate-200 shadow-sm p-4 sm:p-6 mb-4">
        <p class="text-base font-bold text-slate-900">{{ t.greeting }}</p>
        <p class="text-sm text-indigo-700 font-semibold mt-1.5">{{ t.thanks }} 💚</p>
        <p class="text-sm text-slate-500 mt-2 leading-relaxed">{{ t.subtitle }}</p>
      </div>

      <div class="bg-white rounded-2xl border border-slate-200 shadow-sm p-4 sm:p-6">
        <p v-if="cancelled" class="mb-4 rounded-lg bg-amber-50 text-amber-700 text-sm px-3 py-2 text-center">
          {{ t.cancelled }}
        </p>

        <!-- Amount -->
        <label class="text-xs font-semibold uppercase text-slate-400">{{ t.chooseAmount }}</label>
        <div class="grid grid-cols-3 gap-2 mt-2 mb-3">
          <button v-for="a in presets" :key="a" @click="amount = a"
                  class="rounded-xl border py-2.5 text-sm font-bold transition-colors"
                  :class="amount === a ? 'bg-indigo-600 border-indigo-600 text-white' : 'bg-white border-slate-200 text-slate-700 hover:border-indigo-300'">
            ৳{{ a }}
          </button>
        </div>
        <input v-model.number="amount" type="number" min="1" :placeholder="t.customAmount"
               class="w-full rounded-lg border border-slate-300 px-3.5 py-2.5 text-sm focus:outline-none focus:ring-2 focus:ring-indigo-500 mb-4" />

        <!-- Donor (optional) -->
        <div class="space-y-2.5 mb-4">
          <input v-model="form.name" :placeholder="t.namePh"
                 class="w-full rounded-lg border border-slate-300 px-3.5 py-2.5 text-sm focus:outline-none focus:ring-2 focus:ring-indigo-500" />
          <div class="grid grid-cols-2 gap-2.5">
            <input v-model="form.email" type="email" :placeholder="t.emailPh"
                   class="w-full rounded-lg border border-slate-300 px-3.5 py-2.5 text-sm focus:outline-none focus:ring-2 focus:ring-indigo-500" />
            <input v-model="form.phone" :placeholder="t.phonePh"
                   class="w-full rounded-lg border border-slate-300 px-3.5 py-2.5 text-sm focus:outline-none focus:ring-2 focus:ring-indigo-500" />
          </div>
        </div>

        <p v-if="error" class="text-sm text-red-600 mb-3">{{ error }}</p>

        <button @click="donate" :disabled="busy || !(amount > 0)"
                class="w-full rounded-xl bg-indigo-600 hover:bg-indigo-700 text-white font-bold py-3 text-sm disabled:opacity-60">
          {{ busy ? t.redirecting : `❤️ ${t.donateBtn(amount || 0)}` }}
        </button>
        <p class="text-[11px] text-slate-400 text-center mt-3">{{ t.secure }}</p>
      </div>

      <p class="text-center text-xs text-slate-400 mt-5">
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

const presets = [200, 500, 1000, 2000, 5000, 10000];
const amount = ref(500);
const form = ref({ name: "", email: "", phone: "" });
const busy = ref(false);
const error = ref("");
const cancelled = computed(() => route.query.cancelled === "1");

const lang = ref("en");
const recipientName = ref("");

const I18N = {
  en: {
    greeting: () => recipientName.value ? `Dear ${recipientName.value},` : "Hello,",
    thanks: "Thank you for choosing to support AdsyClub",
    subtitle: "AdsyClub is building Bangladesh's social business network — creating income and employment for everyday people. Your support helps us grow.",
    chooseAmount: "Choose an amount (৳)",
    customAmount: "Custom amount",
    namePh: "Your name (optional)",
    emailPh: "Email (optional)",
    phonePh: "Phone (optional)",
    donateBtn: (a) => `Donate ৳${a}`,
    redirecting: "Redirecting to payment…",
    secure: "Secure payment via ShurjoPay · You'll be redirected to complete the donation.",
    cancelled: "Payment was cancelled. You can try again anytime.",
    invalidAmount: "Please choose a valid amount.",
    failed: "Payment could not be started. Please try again.",
    footer: "AdsyClub · Bangladesh",
  },
  bn: {
    greeting: () => recipientName.value ? `প্রিয় ${recipientName.value},` : "হ্যালো,",
    thanks: "AdsyClub-কে সাপোর্ট করার কথা ভাবছেন — এজন্য ধন্যবাদ",
    subtitle: "AdsyClub বাংলাদেশের একটা সোশ্যাল বিজনেস নেটওয়ার্ক — সাধারণ মানুষের জন্য ইনকাম আর কাজের সুযোগ তৈরি করছে। আপনার সাপোর্ট আমাদের আরও এগিয়ে নিয়ে যাবে।",
    chooseAmount: "কত টাকা দেবেন বেছে নিন (৳)",
    customAmount: "অন্য অ্যামাউন্ট লিখুন",
    namePh: "আপনার নাম (অপশনাল)",
    emailPh: "ইমেইল (অপশনাল)",
    phonePh: "ফোন (অপশনাল)",
    donateBtn: (a) => `৳${a} ডোনেট করুন`,
    redirecting: "পেমেন্ট পেজে নিয়ে যাচ্ছি…",
    secure: "ShurjoPay দিয়ে নিরাপদ পেমেন্ট · ডোনেশন কমপ্লিট করতে আপনাকে রিডাইরেক্ট করা হবে।",
    cancelled: "পেমেন্ট ক্যানসেল হয়েছে। চাইলে আবার চেষ্টা করতে পারেন।",
    invalidAmount: "একটা সঠিক অ্যামাউন্ট দিন।",
    failed: "পেমেন্ট শুরু করা যায়নি। আবার চেষ্টা করুন।",
    footer: "AdsyClub · বাংলাদেশ",
  },
};

const t = computed(() => {
  const base = I18N[lang.value] || I18N.en;
  return { ...base, greeting: base.greeting() };
});

useHead(() => ({ title: lang.value === "bn" ? "AdsyClub-কে সহযোগিতা করুন" : "Support AdsyClub — Donate" }));

async function donate() {
  if (!(amount.value > 0)) { error.value = t.value.invalidAmount; return; }
  busy.value = true;
  error.value = "";
  try {
    const res = await $fetch(`${API}/donate/initiate/`, {
      method: "POST",
      body: { amount: amount.value, ...form.value, o: route.query.o || "", u: route.query.u || "", language: lang.value },
    });
    if (res.checkout_url) {
      window.location.href = res.checkout_url;
    } else {
      error.value = t.value.failed;
      busy.value = false;
    }
  } catch (e) {
    error.value = e?.data?.error || t.value.failed;
    busy.value = false;
  }
}

onMounted(async () => {
  // Language from the personalized link (?o= outreach / ?u= transactional) wins;
  // else ?lang=; else English.
  if (route.query.lang === "bn" || route.query.lang === "en") lang.value = route.query.lang;
  const params = {};
  if (route.query.o) params.o = route.query.o;
  if (route.query.u) params.u = route.query.u;
  if (params.o || params.u) {
    try {
      const ctx = await $fetch(`${API}/donate/context/`, { params });
      if (ctx?.name) recipientName.value = ctx.name;
      if (ctx?.language === "bn" || ctx?.language === "en") lang.value = ctx.language;
    } catch { /* fall back to defaults */ }
  }
});
</script>
