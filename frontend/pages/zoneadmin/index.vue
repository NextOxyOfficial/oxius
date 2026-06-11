<template>
  <div class="min-h-screen bg-slate-100 py-6 px-3 sm:px-6">
    <div class="max-w-5xl mx-auto">
      <!-- ============ LOADING ============ -->
      <div v-if="phase === 'loading'" class="bg-white rounded-2xl shadow-sm border border-slate-200 p-10 text-center">
        <div class="animate-spin h-8 w-8 border-3 border-emerald-500 border-t-transparent rounded-full mx-auto mb-3"></div>
        <p class="text-slate-500 text-sm">লোড হচ্ছে...</p>
      </div>

      <!-- ============ LOGIN ============ -->
      <div v-else-if="phase === 'login'" class="max-w-md mx-auto bg-white rounded-2xl shadow-sm border border-slate-200 overflow-hidden">
        <div class="px-6 pt-8 pb-6 text-center border-b border-slate-100">
          <img src="/images/logo.png" alt="AdsyClub" class="h-10 mx-auto mb-3" onerror="this.style.display='none'" />
          <h1 class="text-xl font-bold text-slate-800">জোনাল অফিস প্যানেল</h1>
          <p class="text-sm text-slate-500 mt-1">আপনার অফিসার অ্যাকাউন্ট দিয়ে লগইন করুন</p>
        </div>
        <form class="p-6 space-y-4" @submit.prevent="doLogin">
          <div>
            <label class="block text-sm font-medium text-slate-700 mb-1">ইমেইল</label>
            <input v-model="loginForm.email" type="email" required autocomplete="email"
              class="w-full rounded-lg border border-slate-300 px-3 py-2.5 text-sm focus:outline-none focus:ring-2 focus:ring-emerald-500" placeholder="email@example.com" />
          </div>
          <div>
            <label class="block text-sm font-medium text-slate-700 mb-1">পাসওয়ার্ড</label>
            <input v-model="loginForm.password" type="password" required autocomplete="current-password"
              class="w-full rounded-lg border border-slate-300 px-3 py-2.5 text-sm focus:outline-none focus:ring-2 focus:ring-emerald-500" placeholder="••••••••" />
          </div>
          <p v-if="loginError" class="text-sm text-red-600 bg-red-50 rounded-lg px-3 py-2">{{ loginError }}</p>
          <button type="submit" :disabled="loggingIn"
            class="w-full bg-emerald-600 hover:bg-emerald-700 disabled:opacity-60 text-white font-semibold rounded-lg py-2.5 text-sm transition">
            {{ loggingIn ? 'লগইন হচ্ছে...' : 'লগইন' }}
          </button>
        </form>
      </div>

      <!-- ============ NOT AN OFFICER ============ -->
      <div v-else-if="phase === 'denied'" class="max-w-md mx-auto bg-white rounded-2xl shadow-sm border border-slate-200 p-8 text-center">
        <div class="text-4xl mb-3">🔒</div>
        <h1 class="text-lg font-bold text-slate-800 mb-2">প্রবেশাধিকার নেই</h1>
        <p class="text-sm text-slate-500 mb-5">এই অ্যাকাউন্টটি কোনো জোনাল অফিসের সাথে যুক্ত নয়। অফিসার হিসেবে যুক্ত হতে অ্যাডমিনের সাথে যোগাযোগ করুন।</p>
        <button class="text-sm font-semibold text-emerald-700 hover:underline" @click="doLogout">অন্য অ্যাকাউন্টে লগইন করুন</button>
      </div>

      <!-- ============ DASHBOARD ============ -->
      <div v-else-if="phase === 'dash' && report" class="bg-white rounded-2xl shadow-sm border border-slate-200 overflow-hidden">
        <!-- Header -->
        <div class="px-5 py-4 flex flex-wrap items-center justify-between gap-3 border-b border-slate-100">
          <div>
            <h1 class="text-lg font-bold text-slate-800">{{ report.office.name }}</h1>
            <p class="text-xs text-slate-500 mt-0.5">জোন: {{ report.office.city }} &bull; অফিসার: {{ report.office.officer }}</p>
          </div>
          <div class="flex items-center gap-2">
            <span class="text-[11px] bg-emerald-50 text-emerald-700 font-semibold px-2.5 py-1 rounded-full">Zonal Office</span>
            <button class="text-xs text-slate-400 hover:text-red-500 font-medium" @click="doLogout">লগআউট</button>
          </div>
        </div>

        <!-- Date range -->
        <div class="px-5 py-3 border-b border-slate-100 flex flex-wrap items-center gap-2">
          <button v-for="r in quickRanges" :key="r.days"
            class="text-xs font-semibold px-3 py-1.5 rounded-full border transition"
            :class="activeQuick === r.days ? 'bg-emerald-600 text-white border-emerald-600' : 'bg-white text-slate-600 border-slate-200 hover:border-emerald-400'"
            @click="setQuickRange(r.days)">{{ r.label }}</button>
          <div class="flex items-center gap-1.5 ml-auto">
            <input v-model="range.from" type="date" class="text-xs border border-slate-200 rounded-lg px-2 py-1.5" />
            <span class="text-slate-400 text-xs">—</span>
            <input v-model="range.to" type="date" class="text-xs border border-slate-200 rounded-lg px-2 py-1.5" />
            <button class="text-xs font-semibold bg-slate-800 text-white px-3 py-1.5 rounded-lg hover:bg-slate-700" @click="applyCustomRange">দেখুন</button>
          </div>
        </div>

        <div v-if="loadingReport" class="p-10 text-center">
          <div class="animate-spin h-7 w-7 border-3 border-emerald-500 border-t-transparent rounded-full mx-auto"></div>
        </div>

        <template v-else>
          <!-- Summary tiles -->
          <div class="grid grid-cols-2 sm:grid-cols-4 divide-x divide-y divide-slate-100 border-b border-slate-100">
            <div v-for="t in summaryTiles" :key="t.label" class="p-4">
              <p class="text-[11px] text-slate-500 mb-1">{{ t.label }}</p>
              <p class="text-lg font-bold" :class="t.accent || 'text-slate-800'">{{ t.value }}</p>
              <p v-if="t.sub" class="text-[11px] text-slate-400 mt-0.5">{{ t.sub }}</p>
            </div>
          </div>

          <!-- Commission breakdown -->
          <div class="px-5 pt-5 pb-2">
            <h2 class="text-sm font-bold text-slate-700">কমিশন হিসাব <span class="font-normal text-slate-400">({{ report.range.from }} → {{ report.range.to }})</span></h2>
          </div>
          <div class="px-5 pb-5 overflow-x-auto">
            <table class="w-full text-sm">
              <thead>
                <tr class="text-[11px] text-slate-400 border-b border-slate-100">
                  <th class="text-left py-2 font-medium">ফিচার</th>
                  <th class="text-right py-2 font-medium">রেট</th>
                  <th class="text-right py-2 font-medium">সেলস (৳)</th>
                  <th class="text-right py-2 font-medium">কমিশন (৳)</th>
                </tr>
              </thead>
              <tbody>
                <tr v-for="c in report.commissions" :key="c.feature" class="border-b border-slate-50">
                  <td class="py-2 text-slate-700">{{ featureBn(c.feature) }}</td>
                  <td class="py-2 text-right text-slate-600">{{ c.percent }}%</td>
                  <td class="py-2 text-right text-slate-600">{{ money(c.base_amount) }}</td>
                  <td class="py-2 text-right font-semibold text-emerald-700">{{ money(c.earned) }}</td>
                </tr>
                <tr>
                  <td colspan="3" class="py-2.5 text-right text-sm font-bold text-slate-700">মোট কমিশন</td>
                  <td class="py-2.5 text-right text-base font-bold text-emerald-700">৳{{ money(report.totals.commission) }}</td>
                </tr>
              </tbody>
            </table>
          </div>

          <!-- Area-wise registrations -->
          <div class="px-5 pt-4 pb-2 border-t border-slate-100">
            <h2 class="text-sm font-bold text-slate-700">এলাকা অনুযায়ী নতুন রেজিস্ট্রেশন</h2>
          </div>
          <div class="px-5 pb-5">
            <div v-if="!report.by_area.length" class="text-sm text-slate-400 py-3">এই সময়ে কোনো নতুন রেজিস্ট্রেশন নেই।</div>
            <div v-else class="grid sm:grid-cols-2 gap-x-8">
              <div v-for="a in report.by_area" :key="a.upazila" class="flex items-center justify-between py-1.5 border-b border-slate-50 text-sm">
                <span class="text-slate-700">{{ a.upazila }}</span>
                <span class="font-semibold text-slate-800">{{ a.n }} জন</span>
              </div>
            </div>
          </div>

          <!-- Daily activity -->
          <div class="px-5 pt-4 pb-2 border-t border-slate-100">
            <h2 class="text-sm font-bold text-slate-700">দৈনিক অ্যাক্টিভিটি</h2>
          </div>
          <div class="px-5 pb-6 overflow-x-auto">
            <table class="w-full text-xs sm:text-sm whitespace-nowrap">
              <thead>
                <tr class="text-[11px] text-slate-400 border-b border-slate-100">
                  <th class="text-left py-2 font-medium">তারিখ</th>
                  <th class="text-right py-2 font-medium">রেজিস্ট্রেশন</th>
                  <th class="text-right py-2 font-medium">Pro (৳)</th>
                  <th class="text-right py-2 font-medium">গিগ (৳)</th>
                  <th class="text-right py-2 font-medium">অর্ডার (৳)</th>
                  <th class="text-right py-2 font-medium">রিচার্জ (৳)</th>
                </tr>
              </thead>
              <tbody>
                <tr v-for="d in report.days" :key="d.date" class="border-b border-slate-50">
                  <td class="py-1.5 text-slate-600">{{ d.date }}</td>
                  <td class="py-1.5 text-right" :class="d.registrations ? 'font-semibold text-slate-800' : 'text-slate-300'">{{ d.registrations }}</td>
                  <td class="py-1.5 text-right" :class="d.pro.n ? 'text-slate-700' : 'text-slate-300'">{{ d.pro.n }} / {{ money(d.pro.s) }}</td>
                  <td class="py-1.5 text-right" :class="d.gigs.n ? 'text-slate-700' : 'text-slate-300'">{{ d.gigs.n }} / {{ money(d.gigs.s) }}</td>
                  <td class="py-1.5 text-right" :class="d.orders.n ? 'text-slate-700' : 'text-slate-300'">{{ d.orders.n }} / {{ money(d.orders.s) }}</td>
                  <td class="py-1.5 text-right" :class="d.recharges.n ? 'text-slate-700' : 'text-slate-300'">{{ d.recharges.n }} / {{ money(d.recharges.s) }}</td>
                </tr>
              </tbody>
            </table>
          </div>
        </template>
      </div>
    </div>
  </div>
</template>

<script setup>
definePageMeta({ layout: false });
useHead({ title: "জোনাল অফিস প্যানেল | AdsyClub" });

const { get } = useApi();
const auth = useAuth();

const phase = ref("loading"); // loading | login | denied | dash
const report = ref(null);
const loadingReport = ref(false);
const loggingIn = ref(false);
const loginError = ref("");
const loginForm = reactive({ email: "", password: "" });
const activeQuick = ref(30);

const today = () => new Date().toISOString().slice(0, 10);
const daysAgo = (n) => new Date(Date.now() - n * 86400000).toISOString().slice(0, 10);
const range = reactive({ from: daysAgo(29), to: today() });

const quickRanges = [
  { label: "আজ", days: 1 },
  { label: "৭ দিন", days: 7 },
  { label: "৩০ দিন", days: 30 },
  { label: "৯০ দিন", days: 90 },
];

const featureLabels = {
  registration: "ইউজার রেজিস্ট্রেশন",
  pro_subscription: "Pro সাবস্ক্রিপশন",
  microgig_post: "মাইক্রোগিগ পোস্ট",
  eshop_order: "eShop অর্ডার",
  mobile_recharge: "মোবাইল রিচার্জ",
};
const featureBn = (f) => featureLabels[f] || f;
const money = (v) => Number(v || 0).toLocaleString("en-US", { maximumFractionDigits: 0 });

const summaryTiles = computed(() => {
  const t = report.value?.totals;
  if (!t) return [];
  return [
    { label: "জোনের মোট ইউজার", value: t.zone_users.toLocaleString() },
    { label: "নতুন রেজিস্ট্রেশন (লিড)", value: t.registrations.toLocaleString(), accent: "text-blue-600" },
    { label: "Pro আপগ্রেড", value: t.pro.count, sub: `৳${money(t.pro.amount)}` },
    { label: "মাইক্রোগিগ পোস্ট", value: t.gigs.count, sub: `৳${money(t.gigs.amount)}` },
    { label: "eShop অর্ডার", value: t.orders.count, sub: `৳${money(t.orders.amount)}` },
    { label: "মোবাইল রিচার্জ", value: t.recharges.count, sub: `৳${money(t.recharges.amount)}` },
    { label: "মোট সেলস", value: `৳${money(t.revenue)}`, accent: "text-slate-800" },
    { label: "মোট কমিশন", value: `৳${money(t.commission)}`, accent: "text-emerald-600" },
  ];
});

async function loadReport() {
  loadingReport.value = true;
  try {
    const { data, error } = await get(`/zonal/dashboard/?from=${range.from}&to=${range.to}`);
    if (data && !error) {
      report.value = data;
      phase.value = "dash";
    } else {
      const status =
        error?.response?.status || error?.statusCode || error?.status;
      phase.value = status === 403 ? "denied" : "login";
    }
  } finally {
    loadingReport.value = false;
  }
}

function setQuickRange(days) {
  activeQuick.value = days;
  range.from = daysAgo(days - 1);
  range.to = today();
  loadReport();
}

function applyCustomRange() {
  activeQuick.value = 0;
  if (range.from && range.to) loadReport();
}

async function doLogin() {
  loginError.value = "";
  loggingIn.value = true;
  try {
    // useAuth().login returns { loggedIn, message? }
    const res = await auth.login(loginForm.email, loginForm.password);
    if (!res?.loggedIn) {
      loginError.value = res?.message || "ইমেইল বা পাসওয়ার্ড সঠিক নয়।";
      return;
    }
    await loadReport(); // sets phase to dash/denied based on /zonal/ access
  } catch (e) {
    loginError.value = "লগইন করা যায়নি, আবার চেষ্টা করুন।";
  } finally {
    loggingIn.value = false;
  }
}

async function doLogout() {
  try {
    if (typeof auth.logout === "function") await auth.logout();
  } catch (e) { /* ignore */ }
  report.value = null;
  phase.value = "login";
}

onMounted(async () => {
  const { data, error } = await get("/zonal/me/");
  if (data && !error) {
    await loadReport();
  } else {
    const status =
      error?.response?.status || error?.statusCode || error?.status;
    if (status === 403) phase.value = "denied";
    else phase.value = "login";
  }
});
</script>
