<template>
  <UContainer class="mt-3 mb-10">
    <div class="max-w-3xl mx-auto">
      <!-- ── Header ─────────────────────────────────────────────── -->
      <div
        class="relative overflow-hidden rounded-2xl bg-gradient-to-r from-blue-800 to-indigo-900 text-white shadow-md mb-4"
      >
        <div class="absolute -top-16 -right-16 w-56 h-56 rounded-full bg-white/10"></div>
        <div class="relative px-5 py-5 sm:px-7 flex items-center gap-3">
          <NuxtLink
            :to="`/business-network/abn-ads/${adId}`"
            class="p-2 rounded-xl bg-white/15 hover:bg-white/25 transition-colors"
            aria-label="ফিরে যান"
          >
            <UIcon name="i-heroicons-arrow-left" class="w-5 h-5" />
          </NuxtLink>
          <div>
            <h1 class="text-lg font-semibold">বিজ্ঞাপন সম্পাদনা</h1>
            <p class="text-xs text-white/70 mt-0.5">
              পরিবর্তন সংরক্ষণ করলে বিজ্ঞাপনটি আবার রিভিউতে যেতে পারে
            </p>
          </div>
        </div>
      </div>

      <!-- ── Loading ────────────────────────────────────────────── -->
      <div v-if="loading" class="py-16 flex justify-center">
        <UIcon name="i-heroicons-arrow-path" class="w-7 h-7 animate-spin text-blue-600" />
      </div>

      <!-- ── Not found / not yours ──────────────────────────────── -->
      <div
        v-else-if="notFound"
        class="rounded-2xl border border-red-200 bg-red-50 p-6 text-center"
      >
        <UIcon name="i-heroicons-exclamation-triangle" class="w-8 h-8 text-red-500 mx-auto" />
        <p class="mt-2 text-sm font-medium text-red-700">
          বিজ্ঞাপনটি পাওয়া যায়নি, অথবা এটি সম্পাদনার অনুমতি আপনার নেই।
        </p>
        <NuxtLink
          to="/business-network/abn-ads"
          class="inline-block mt-4 px-4 py-2 rounded-lg bg-red-600 text-white text-sm font-medium"
        >
          বিজ্ঞাপন প্যানেলে ফিরে যান
        </NuxtLink>
      </div>

      <template v-else>
        <!-- ── Live status strip (read-only, server-controlled) ─── -->
        <div class="rounded-2xl border border-gray-200 bg-white p-4 mb-4">
          <div class="grid grid-cols-2 sm:grid-cols-4 gap-3 text-center">
            <div>
              <p class="text-[11px] text-gray-500">অবস্থা</p>
              <p class="text-sm font-semibold" :class="statusClass">{{ statusLabel }}</p>
            </div>
            <div>
              <p class="text-[11px] text-gray-500">খরচ হয়েছে</p>
              <p class="text-sm font-semibold text-gray-800">৳{{ fmt(ad.spent) }}</p>
            </div>
            <div>
              <p class="text-[11px] text-gray-500">ভিউ</p>
              <p class="text-sm font-semibold text-gray-800">{{ ad.views ?? 0 }}</p>
            </div>
            <div>
              <p class="text-[11px] text-gray-500">ক্লিক</p>
              <p class="text-sm font-semibold text-gray-800">{{ ad.clicks ?? 0 }}</p>
            </div>
          </div>
          <p
            v-if="ad.status === 'rejected' && ad.reject_reason"
            class="mt-3 text-xs text-red-600 bg-red-50 rounded-lg px-3 py-2"
          >
            বাতিলের কারণ: {{ ad.reject_reason }}
          </p>
        </div>

        <form class="space-y-4" @submit.prevent="save">
          <!-- ── Content ──────────────────────────────────────── -->
          <section class="rounded-2xl border border-gray-200 bg-white p-4 sm:p-5">
            <h2 class="text-sm font-semibold text-gray-800 mb-3">বিজ্ঞাপনের বিষয়বস্তু</h2>

            <label class="block text-xs font-medium text-gray-600 mb-1">শিরোনাম</label>
            <input
              v-model="form.title"
              type="text"
              maxlength="255"
              required
              class="w-full rounded-lg border border-gray-300 px-3 py-2 text-sm focus:border-blue-500 focus:outline-none"
              placeholder="যেমন: ঈদ অফার — ৫০% ছাড়"
            />

            <label class="block text-xs font-medium text-gray-600 mb-1 mt-3">বিবরণ</label>
            <textarea
              v-model="form.description"
              rows="3"
              required
              class="w-full rounded-lg border border-gray-300 px-3 py-2 text-sm focus:border-blue-500 focus:outline-none"
              placeholder="আপনার অফার সম্পর্কে সংক্ষেপে লিখুন"
            ></textarea>
          </section>

          <!-- ── Call to action ───────────────────────────────── -->
          <section class="rounded-2xl border border-gray-200 bg-white p-4 sm:p-5">
            <h2 class="text-sm font-semibold text-gray-800 mb-3">অ্যাকশন বাটন</h2>

            <label class="block text-xs font-medium text-gray-600 mb-1">বাটনের ধরন</label>
            <select
              v-model="form.ad_type"
              class="w-full rounded-lg border border-gray-300 px-3 py-2 text-sm focus:border-blue-500 focus:outline-none"
            >
              <option v-for="t in adTypes" :key="t.value" :value="t.value">
                {{ t.label }}
              </option>
            </select>

            <label class="block text-xs font-medium text-gray-600 mb-1 mt-3">
              {{ adTypeDetailLabel }}
            </label>
            <input
              v-model="form.ad_type_details"
              type="text"
              class="w-full rounded-lg border border-gray-300 px-3 py-2 text-sm focus:border-blue-500 focus:outline-none"
              :placeholder="adTypeDetailPlaceholder"
            />
            <p v-if="detailError" class="mt-1 text-xs text-red-600">{{ detailError }}</p>
          </section>

          <!-- ── Budget ───────────────────────────────────────── -->
          <section class="rounded-2xl border border-gray-200 bg-white p-4 sm:p-5">
            <h2 class="text-sm font-semibold text-gray-800 mb-3">বাজেট</h2>

            <label class="block text-xs font-medium text-gray-600 mb-1">মোট বাজেট (৳)</label>
            <input
              v-model="form.budget"
              type="number"
              min="1"
              step="1"
              required
              class="w-full rounded-lg border border-gray-300 px-3 py-2 text-sm focus:border-blue-500 focus:outline-none"
            />

            <!-- Live money feedback so the charge is never a surprise -->
            <div
              v-if="budgetDelta > 0"
              class="mt-2 text-xs rounded-lg px-3 py-2"
              :class="canAffordDelta
                ? 'bg-blue-50 text-blue-700'
                : 'bg-red-50 text-red-700'"
            >
              <template v-if="canAffordDelta">
                সংরক্ষণ করলে আপনার ব্যালেন্স থেকে আরও
                <b>৳{{ fmt(budgetDelta) }}</b> কেটে নেওয়া হবে।
                (বর্তমান ব্যালেন্স ৳{{ fmt(balance) }})
              </template>
              <template v-else>
                আরও ৳{{ fmt(budgetDelta) }} প্রয়োজন, কিন্তু আপনার ব্যালেন্সে আছে
                ৳{{ fmt(balance) }}। আগে ব্যালেন্স যোগ করুন।
              </template>
            </div>
            <div
              v-else-if="budgetDelta < 0"
              class="mt-2 text-xs rounded-lg px-3 py-2 bg-emerald-50 text-emerald-700"
            >
              না-খরচ <b>৳{{ fmt(-budgetDelta) }}</b> আপনার ব্যালেন্সে ফেরত যাবে।
            </div>
            <p class="mt-2 text-[11px] text-gray-500">
              ইতিমধ্যে খরচ হওয়া ৳{{ fmt(ad.spent) }} এর কম বাজেট দেওয়া যাবে না।
            </p>

            <label class="block text-xs font-medium text-gray-600 mb-1 mt-3">
              দৈনিক সীমা (৳) — খালি রাখলে সীমা নেই
            </label>
            <input
              v-model="form.daily_budget"
              type="number"
              min="0"
              step="1"
              class="w-full rounded-lg border border-gray-300 px-3 py-2 text-sm focus:border-blue-500 focus:outline-none"
            />
          </section>

          <!-- ── Schedule ─────────────────────────────────────── -->
          <section class="rounded-2xl border border-gray-200 bg-white p-4 sm:p-5">
            <h2 class="text-sm font-semibold text-gray-800 mb-3">সময়সূচি</h2>
            <div class="grid sm:grid-cols-2 gap-3">
              <div>
                <label class="block text-xs font-medium text-gray-600 mb-1">শুরুর সময়</label>
                <input
                  v-model="form.start_at"
                  type="datetime-local"
                  class="w-full rounded-lg border border-gray-300 px-3 py-2 text-sm focus:border-blue-500 focus:outline-none"
                />
              </div>
              <div>
                <label class="block text-xs font-medium text-gray-600 mb-1">শেষের সময়</label>
                <input
                  v-model="form.end_at"
                  type="datetime-local"
                  class="w-full rounded-lg border border-gray-300 px-3 py-2 text-sm focus:border-blue-500 focus:outline-none"
                />
              </div>
            </div>
            <p v-if="scheduleError" class="mt-1 text-xs text-red-600">{{ scheduleError }}</p>
          </section>

          <!-- ── Targeting ────────────────────────────────────── -->
          <section class="rounded-2xl border border-gray-200 bg-white p-4 sm:p-5">
            <h2 class="text-sm font-semibold text-gray-800 mb-3">কাদের দেখাবেন</h2>

            <p class="text-xs font-medium text-gray-600 mb-1.5">লিঙ্গ</p>
            <div class="flex flex-wrap gap-3 mb-3">
              <label
                v-for="g in genders"
                :key="g.key"
                class="inline-flex items-center gap-1.5 text-sm text-gray-700"
              >
                <input v-model="form[g.key]" type="checkbox" class="rounded" />
                {{ g.label }}
              </label>
            </div>
            <p class="text-[11px] text-gray-500 -mt-2 mb-3">
              কোনোটি নির্বাচন না করলে সবাইকে দেখানো হবে।
            </p>

            <div class="grid sm:grid-cols-2 gap-3">
              <div>
                <label class="block text-xs font-medium text-gray-600 mb-1">সর্বনিম্ন বয়স</label>
                <input
                  v-model="form.min_age"
                  type="number"
                  min="0"
                  max="100"
                  class="w-full rounded-lg border border-gray-300 px-3 py-2 text-sm focus:border-blue-500 focus:outline-none"
                />
              </div>
              <div>
                <label class="block text-xs font-medium text-gray-600 mb-1">সর্বোচ্চ বয়স</label>
                <input
                  v-model="form.max_age"
                  type="number"
                  min="0"
                  max="100"
                  class="w-full rounded-lg border border-gray-300 px-3 py-2 text-sm focus:border-blue-500 focus:outline-none"
                />
              </div>
            </div>
            <p v-if="ageError" class="mt-1 text-xs text-red-600">{{ ageError }}</p>
          </section>

          <!-- ── Placements ───────────────────────────────────── -->
          <section class="rounded-2xl border border-gray-200 bg-white p-4 sm:p-5">
            <h2 class="text-sm font-semibold text-gray-800 mb-1">কোথায় দেখাবেন</h2>
            <p class="text-[11px] text-gray-500 mb-3">
              কোনোটি নির্বাচন না করলে সব জায়গায় দেখানো হবে।
            </p>
            <div class="grid sm:grid-cols-2 gap-2">
              <label
                v-for="p in placementOptions"
                :key="p.value"
                class="inline-flex items-center gap-2 text-sm text-gray-700 rounded-lg border border-gray-200 px-3 py-2 cursor-pointer hover:bg-gray-50"
              >
                <input
                  v-model="form.placements"
                  type="checkbox"
                  :value="p.value"
                  class="rounded"
                />
                {{ p.label }}
              </label>
            </div>
          </section>

          <!-- ── Errors + actions ─────────────────────────────── -->
          <div
            v-if="saveError"
            class="rounded-xl border border-red-200 bg-red-50 px-4 py-3 text-sm text-red-700"
          >
            {{ saveError }}
          </div>

          <div class="flex flex-wrap gap-3 pb-2">
            <button
              type="submit"
              :disabled="saving || !canSubmit"
              class="px-5 py-2.5 rounded-xl bg-blue-600 text-white text-sm font-semibold disabled:opacity-50 disabled:cursor-not-allowed hover:bg-blue-700 transition-colors"
            >
              {{ saving ? "সংরক্ষণ হচ্ছে…" : "পরিবর্তন সংরক্ষণ করুন" }}
            </button>
            <NuxtLink
              :to="`/business-network/abn-ads/${adId}`"
              class="px-5 py-2.5 rounded-xl border border-gray-300 text-sm font-medium text-gray-700 hover:bg-gray-50 transition-colors"
            >
              বাতিল
            </NuxtLink>
          </div>
        </form>
      </template>
    </div>
  </UContainer>
</template>

<script setup>
// Dedicated edit PAGE (previously a cramped modal shared with "create").
// Everything money-related is echoed back to the advertiser before they save,
// because the server settles the budget difference on submit — an increase is
// charged, a decrease is refunded, and shrinking below the already-spent
// amount is refused.
const { get, patch } = useApi();
const { user } = useAuth();
const route = useRoute();
const router = useRouter();
const toast = useToast();

const adId = computed(() => route.params.id);

const ad = ref(null);
const loading = ref(true);
const notFound = ref(false);
const saving = ref(false);
const saveError = ref("");

const form = reactive({
  title: "",
  description: "",
  ad_type: "click_to_website",
  ad_type_details: "",
  budget: 0,
  daily_budget: null,
  start_at: "",
  end_at: "",
  male: false,
  female: false,
  other: false,
  min_age: null,
  max_age: null,
  placements: [],
});

const adTypes = [
  { value: "click_to_website", label: "ওয়েবসাইটে নিয়ে যান" },
  { value: "call_on_whatsapp", label: "হোয়াটসঅ্যাপে বার্তা" },
  { value: "call_on_phone", label: "ফোন কল" },
  { value: "email_us", label: "ইমেইল করুন" },
];

const genders = [
  { key: "male", label: "পুরুষ" },
  { key: "female", label: "নারী" },
  { key: "other", label: "অন্যান্য" },
];

// Keys must match VALID_PLACEMENTS in business_network/ads_api.py.
const placementOptions = [
  { value: "bn_feed", label: "বিজনেস নেটওয়ার্ক ফিড" },
  { value: "shorts_banner", label: "শর্টস — ভিডিওর উপরে ব্যানার" },
  { value: "shorts_reel", label: "শর্টস — রিলের ভেতরে" },
  { value: "gigs_list", label: "মাইক্রো গিগস তালিকা" },
  { value: "sale_list", label: "সেল তালিকা" },
  { value: "news_list", label: "নিউজ তালিকা" },
  { value: "food_list", label: "ফুড জোন তালিকা" },
  { value: "classified_list", label: "ক্লাসিফায়েড তালিকা" },
  { value: "web_feed", label: "ওয়েব ফিড" },
  { value: "app_open", label: "অ্যাপ ওপেন" },
];

const statusLabels = {
  review: "রিভিউতে আছে",
  active: "চলছে",
  pending: "অপেক্ষমাণ",
  rejected: "বাতিল",
  stoped: "বন্ধ",
  completed: "সম্পন্ন",
};
const statusLabel = computed(
  () => statusLabels[ad.value?.status] || ad.value?.status || "—"
);
const statusClass = computed(() => {
  switch (ad.value?.status) {
    case "active":
      return "text-emerald-600";
    case "rejected":
      return "text-red-600";
    case "review":
    case "pending":
      return "text-amber-600";
    default:
      return "text-gray-700";
  }
});

const balance = computed(() => Number(user.value?.user?.balance ?? 0));
const originalBudget = computed(() => Number(ad.value?.budget ?? 0));
const budgetDelta = computed(() => Number(form.budget || 0) - originalBudget.value);
const canAffordDelta = computed(() => budgetDelta.value <= balance.value);

const adTypeDetailLabel = computed(
  () =>
    ({
      click_to_website: "ওয়েবসাইট লিংক",
      call_on_whatsapp: "হোয়াটসঅ্যাপ নম্বর",
      call_on_phone: "ফোন নম্বর",
      email_us: "ইমেইল ঠিকানা",
    }[form.ad_type] || "বিস্তারিত")
);
const adTypeDetailPlaceholder = computed(
  () =>
    ({
      click_to_website: "https://example.com",
      call_on_whatsapp: "01XXXXXXXXX",
      call_on_phone: "01XXXXXXXXX",
      email_us: "you@example.com",
    }[form.ad_type] || "")
);

// ── Client-side validation (the server re-checks everything) ──
const detailError = computed(() => {
  const v = (form.ad_type_details || "").trim();
  if (!v) return "";
  if (form.ad_type === "click_to_website" && !/^https?:\/\/.+/i.test(v)) {
    return "লিংকটি http:// বা https:// দিয়ে শুরু হতে হবে।";
  }
  if (form.ad_type === "email_us" && !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(v)) {
    return "সঠিক ইমেইল ঠিকানা দিন।";
  }
  if (
    (form.ad_type === "call_on_phone" || form.ad_type === "call_on_whatsapp") &&
    !/^[0-9+\-\s]{6,20}$/.test(v)
  ) {
    return "সঠিক ফোন নম্বর দিন।";
  }
  return "";
});

const ageError = computed(() => {
  const lo = form.min_age === null || form.min_age === "" ? null : Number(form.min_age);
  const hi = form.max_age === null || form.max_age === "" ? null : Number(form.max_age);
  if (lo !== null && hi !== null && lo > hi) {
    return "সর্বনিম্ন বয়স সর্বোচ্চ বয়সের চেয়ে বেশি হতে পারে না।";
  }
  return "";
});

const scheduleError = computed(() => {
  if (form.start_at && form.end_at && new Date(form.start_at) >= new Date(form.end_at)) {
    return "শেষের সময় শুরুর সময়ের পরে হতে হবে।";
  }
  return "";
});

const canSubmit = computed(() => {
  if (!form.title.trim() || !form.description.trim()) return false;
  if (Number(form.budget) <= 0) return false;
  if (Number(form.budget) < Number(ad.value?.spent ?? 0)) return false;
  if (budgetDelta.value > 0 && !canAffordDelta.value) return false;
  return !detailError.value && !ageError.value && !scheduleError.value;
});

function fmt(v) {
  const n = Number(v ?? 0);
  return Number.isInteger(n) ? String(n) : n.toFixed(2);
}

/** ISO → value accepted by <input type="datetime-local"> (local time). */
function toLocalInput(iso) {
  if (!iso) return "";
  const d = new Date(iso);
  if (Number.isNaN(d.getTime())) return "";
  const pad = (x) => String(x).padStart(2, "0");
  return `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}T${pad(
    d.getHours()
  )}:${pad(d.getMinutes())}`;
}

async function fetchAd() {
  loading.value = true;
  notFound.value = false;
  try {
    const res = await get(`/bn/abn-ads-panels/${adId.value}/`);
    if (res?.data && !res.error) {
      ad.value = res.data;
      Object.assign(form, {
        title: res.data.title ?? "",
        description: res.data.description ?? "",
        ad_type: res.data.ad_type ?? "click_to_website",
        ad_type_details: res.data.ad_type_details ?? "",
        budget: Number(res.data.budget ?? 0),
        daily_budget:
          res.data.daily_budget === null ? null : Number(res.data.daily_budget),
        start_at: toLocalInput(res.data.start_at),
        end_at: toLocalInput(res.data.end_at),
        male: !!res.data.male,
        female: !!res.data.female,
        other: !!res.data.other,
        min_age: res.data.min_age,
        max_age: res.data.max_age,
        placements: Array.isArray(res.data.placements) ? [...res.data.placements] : [],
      });
    } else {
      notFound.value = true;
    }
  } catch (e) {
    notFound.value = true;
  } finally {
    loading.value = false;
  }
}

async function save() {
  if (!canSubmit.value || saving.value) return;
  saving.value = true;
  saveError.value = "";

  // Only send what this page owns. status/views/clicks/spent are server-side
  // and rejected by the serializer anyway; sending them would just be noise.
  const payload = {
    title: form.title.trim(),
    description: form.description.trim(),
    ad_type: form.ad_type,
    ad_type_details: (form.ad_type_details || "").trim(),
    budget: Number(form.budget),
    daily_budget:
      form.daily_budget === "" || form.daily_budget === null
        ? null
        : Number(form.daily_budget),
    start_at: form.start_at ? new Date(form.start_at).toISOString() : null,
    end_at: form.end_at ? new Date(form.end_at).toISOString() : null,
    male: form.male,
    female: form.female,
    other: form.other,
    min_age: form.min_age === "" ? null : form.min_age,
    max_age: form.max_age === "" ? null : form.max_age,
    placements: form.placements,
  };

  try {
    const res = await patch(`/bn/abn-ads-panels/${adId.value}/`, payload);
    if (res?.error || (res?.status && res.status >= 400)) {
      saveError.value = extractError(res);
      return;
    }
    toast.add({
      title: "পরিবর্তন সংরক্ষিত হয়েছে",
      description:
        budgetDelta.value !== 0
          ? "বাজেটের পার্থক্য আপনার ব্যালেন্সে সমন্বয় করা হয়েছে।"
          : undefined,
      color: "green",
    });
    router.push(`/business-network/abn-ads/${adId.value}`);
  } catch (e) {
    saveError.value = "সংরক্ষণ করা যায়নি। আবার চেষ্টা করুন।";
  } finally {
    saving.value = false;
  }
}

/** Surfaces the server's Bangla field errors instead of a generic message. */
function extractError(res) {
  const d = res?.error?.data ?? res?.data ?? res?.error;
  if (typeof d === "string") return d;
  if (d && typeof d === "object") {
    for (const key of ["budget", "detail", "message", "error"]) {
      const v = d[key];
      if (typeof v === "string") return v;
      if (Array.isArray(v) && v.length) return String(v[0]);
    }
    const first = Object.values(d)[0];
    if (Array.isArray(first) && first.length) return String(first[0]);
    if (typeof first === "string") return first;
  }
  return "সংরক্ষণ করা যায়নি। আবার চেষ্টা করুন।";
}

onMounted(fetchAd);
</script>
