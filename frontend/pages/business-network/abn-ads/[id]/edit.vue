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
            class="p-2 rounded-xl flex bg-white/15 hover:bg-white/25 transition-colors"
            :aria-label='$t("ads_edit_back")'
          >
            <UIcon name="i-heroicons-arrow-left" class="w-5 h-5" />
          </NuxtLink>
          <div>
            <h1 class="text-lg font-semibold">{{ $t("ads_edit_title") }}</h1>
            <p class="text-xs text-white/70 mt-0.5">
              {{ $t("ads_edit_sub") }}
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
          {{ $t("ads_edit_not_found") }}
        </p>
        <NuxtLink
          to="/business-network/abn-ads"
          class="inline-block mt-4 px-4 py-2 rounded-lg bg-red-600 text-white text-sm font-medium"
        >
          {{ $t("ads_edit_back_panel") }}
        </NuxtLink>
      </div>

      <template v-else>
        <!-- ── Live status strip (read-only, server-controlled) ─── -->
        <div class="rounded-2xl border border-gray-200 bg-white p-4 mb-4">
          <div class="grid grid-cols-2 sm:grid-cols-4 gap-3 text-center">
            <div>
              <p class="text-[11px] text-gray-500">{{ $t("ads_edit_status") }}</p>
              <p class="text-sm font-semibold" :class="statusClass">{{ statusLabel }}</p>
            </div>
            <div>
              <p class="text-[11px] text-gray-500">{{ $t("ads_edit_spent") }}</p>
              <p class="text-sm font-semibold text-gray-800">৳{{ fmt(ad.spent) }}</p>
            </div>
            <div>
              <p class="text-[11px] text-gray-500">{{ $t("ads_edit_views") }}</p>
              <p class="text-sm font-semibold text-gray-800">{{ ad.views ?? 0 }}</p>
            </div>
            <div>
              <p class="text-[11px] text-gray-500">{{ $t("ads_edit_clicks") }}</p>
              <p class="text-sm font-semibold text-gray-800">{{ ad.clicks ?? 0 }}</p>
            </div>
          </div>
          <p
            v-if="ad.status === 'rejected' && ad.reject_reason"
            class="mt-3 text-xs text-red-600 bg-red-50 rounded-lg px-3 py-2"
          >
            {{ $t("ads_edit_reject_reason") }}: {{ ad.reject_reason }}
          </p>
        </div>

        <form class="space-y-4" @submit.prevent="save">
          <!-- ── Content ──────────────────────────────────────── -->
          <section class="rounded-2xl border border-gray-200 bg-white p-4 sm:p-5">
            <h2 class="text-sm font-semibold text-gray-800 mb-3">{{ $t("ads_edit_content") }}</h2>

            <label class="block text-xs font-medium text-gray-600 mb-1">{{ $t("ads_edit_title_label") }}</label>
            <input
              v-model="form.title"
              type="text"
              maxlength="255"
              required
              class="w-full rounded-lg border border-gray-300 px-3 py-2 text-sm focus:border-blue-500 focus:outline-none"
              :placeholder='$t("ads_edit_title_ph")'
            />

            <label class="block text-xs font-medium text-gray-600 mb-1 mt-3">{{ $t("ads_edit_desc") }}</label>
            <textarea
              v-model="form.description"
              rows="3"
              required
              class="w-full rounded-lg border border-gray-300 px-3 py-2 text-sm focus:border-blue-500 focus:outline-none"
              :placeholder='$t("ads_edit_desc_ph")'
            ></textarea>
          </section>

          <!-- ── Call to action ───────────────────────────────── -->
          <section class="rounded-2xl border border-gray-200 bg-white p-4 sm:p-5">
            <h2 class="text-sm font-semibold text-gray-800 mb-3">{{ $t("ads_edit_cta") }}</h2>

            <label class="block text-xs font-medium text-gray-600 mb-1">{{ $t("ads_edit_cta_type") }}</label>
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
            <h2 class="text-sm font-semibold text-gray-800 mb-3">{{ $t("ads_edit_budget") }}</h2>

            <label class="block text-xs font-medium text-gray-600 mb-1">{{ $t("ads_edit_total_budget") }}</label>
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
                {{ $t("ads_edit_charge_more", { amount: fmt(budgetDelta), balance: fmt(balance) }) }}
              </template>
              <template v-else>
                {{ $t("ads_edit_need_more", { amount: fmt(budgetDelta), balance: fmt(balance) }) }}
              </template>
            </div>
            <div
              v-else-if="budgetDelta < 0"
              class="mt-2 text-xs rounded-lg px-3 py-2 bg-emerald-50 text-emerald-700"
            >
              {{ $t("ads_edit_refund", { amount: fmt(-budgetDelta) }) }}
            </div>
            <p class="mt-2 text-[11px] text-gray-500">
              {{ $t("ads_edit_spent_note", { spent: fmt(ad.spent) }) }}
            </p>

            <label class="block text-xs font-medium text-gray-600 mb-1 mt-3">
              {{ $t("ads_edit_daily_cap") }}
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
            <h2 class="text-sm font-semibold text-gray-800 mb-3">{{ $t("ads_edit_schedule") }}</h2>
            <div class="grid sm:grid-cols-2 gap-3">
              <div>
                <label class="block text-xs font-medium text-gray-600 mb-1">{{ $t("ads_edit_start") }}</label>
                <input
                  v-model="form.start_at"
                  type="datetime-local"
                  class="w-full rounded-lg border border-gray-300 px-3 py-2 text-sm focus:border-blue-500 focus:outline-none"
                />
              </div>
              <div>
                <label class="block text-xs font-medium text-gray-600 mb-1">{{ $t("ads_edit_end") }}</label>
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
            <h2 class="text-sm font-semibold text-gray-800 mb-3">{{ $t("ads_edit_audience") }}</h2>

            <p class="text-xs font-medium text-gray-600 mb-1.5">{{ $t("ads_edit_gender") }}</p>
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
              {{ $t("ads_edit_gender_note") }}
            </p>

            <div class="grid sm:grid-cols-2 gap-3">
              <div>
                <label class="block text-xs font-medium text-gray-600 mb-1">{{ $t("ads_edit_min_age") }}</label>
                <input
                  v-model="form.min_age"
                  type="number"
                  min="0"
                  max="100"
                  class="w-full rounded-lg border border-gray-300 px-3 py-2 text-sm focus:border-blue-500 focus:outline-none"
                />
              </div>
              <div>
                <label class="block text-xs font-medium text-gray-600 mb-1">{{ $t("ads_edit_max_age") }}</label>
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
            <h2 class="text-sm font-semibold text-gray-800 mb-1">{{ $t("ads_edit_placements") }}</h2>
            <p class="text-[11px] text-gray-500 mb-3">
              {{ $t("ads_edit_placements_note") }}
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
              {{ saving ? $t("ads_edit_saving") : $t("ads_edit_save") }}
            </button>
            <NuxtLink
              :to="`/business-network/abn-ads/${adId}`"
              class="px-5 py-2.5 rounded-xl border border-gray-300 text-sm font-medium text-gray-700 hover:bg-gray-50 transition-colors"
            >
              {{ $t("ads_edit_cancel") }}
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
const { t } = useI18n();

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

const adTypes = computed(() => [
  { value: "click_to_website", label: t("ads_edit_cta_website") },
  { value: "call_on_whatsapp", label: t("ads_edit_cta_whatsapp") },
  { value: "call_on_phone", label: t("ads_edit_cta_phone") },
  { value: "email_us", label: t("ads_edit_cta_email") },
]);

const genders = computed(() => [
  { key: "male", label: t("ads_edit_male") },
  { key: "female", label: t("ads_edit_female") },
  { key: "other", label: t("ads_edit_other") },
]);

// Keys must match VALID_PLACEMENTS in business_network/ads_api.py.
const placementOptions = computed(() => [
  { value: "bn_feed", label: t("ads_pl_bn_feed") },
  { value: "shorts_banner", label: t("ads_pl_shorts_banner") },
  { value: "shorts_reel", label: t("ads_pl_shorts_reel") },
  { value: "gigs_list", label: t("ads_pl_gigs_list") },
  { value: "sale_list", label: t("ads_pl_sale_list") },
  { value: "news_list", label: t("ads_pl_news_list") },
  { value: "food_list", label: t("ads_pl_food_list") },
  { value: "classified_list", label: t("ads_pl_classified_list") },
  { value: "web_feed", label: t("ads_pl_web_feed") },
  { value: "app_open", label: t("ads_pl_app_open") },
]);

// Reuses the panel-wide ads_status_* keys instead of its own copy — this page
// previously said "চলছে" where every other page said "চালু" for the same status.
const statusKeys = {
  review: "ads_status_review",
  active: "ads_status_active",
  pending: "ads_status_review",
  rejected: "ads_status_rejected",
  stoped: "ads_status_stopped",
  completed: "ads_status_completed",
};
const statusLabel = computed(() => {
  const key = statusKeys[ad.value?.status];
  return key ? t(key) : ad.value?.status || "—";
});
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
      click_to_website: t("ads_edit_link"),
      call_on_whatsapp: t("ads_edit_whatsapp_no"),
      call_on_phone: t("ads_edit_phone_no"),
      email_us: t("ads_edit_email_addr"),
    }[form.ad_type] || t("ads_edit_detail"))
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
    return t("ads_edit_err_link");
  }
  if (form.ad_type === "email_us" && !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(v)) {
    return t("ads_edit_err_email");
  }
  if (
    (form.ad_type === "call_on_phone" || form.ad_type === "call_on_whatsapp") &&
    !/^[0-9+\-\s]{6,20}$/.test(v)
  ) {
    return t("ads_edit_err_phone");
  }
  return "";
});

const ageError = computed(() => {
  const lo = form.min_age === null || form.min_age === "" ? null : Number(form.min_age);
  const hi = form.max_age === null || form.max_age === "" ? null : Number(form.max_age);
  if (lo !== null && hi !== null && lo > hi) {
    return t("ads_edit_err_age");
  }
  return "";
});

const scheduleError = computed(() => {
  if (form.start_at && form.end_at && new Date(form.start_at) >= new Date(form.end_at)) {
    return t("ads_edit_err_schedule");
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
      title: t("ads_edit_saved"),
      description:
        budgetDelta.value !== 0 ? t("ads_edit_saved_budget") : undefined,
      color: "green",
    });
    router.push(`/business-network/abn-ads/${adId.value}`);
  } catch (e) {
    saveError.value = t("ads_edit_save_failed");
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
  return t("ads_edit_save_failed");
}

onMounted(fetchAd);
</script>
