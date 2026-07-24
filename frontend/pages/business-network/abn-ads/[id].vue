<template>
  <UContainer class="mt-3 mb-10">
    <div class="max-w-3xl mx-auto">
      <!-- ── Hero header ─────────────────────────────────────────── -->
      <div
        class="relative overflow-hidden rounded-2xl bg-gradient-to-r from-blue-800 to-indigo-900 text-white shadow-md mb-4"
      >
        <div
          class="absolute -top-16 -right-16 w-56 h-56 rounded-full bg-white/10"
        ></div>
        <div
          class="absolute -bottom-20 -left-10 w-44 h-44 rounded-full bg-white/10"
        ></div>
        <div
          class="relative px-5 py-5 sm:px-7 flex flex-wrap items-center justify-between gap-3"
        >
          <div class="flex items-center gap-3">
            <NuxtLink
              to="/business-network/abn-ads"
              class="p-2 rounded-xl bg-white/15 hover:bg-white/25 transition-colors"
            >
              <UIcon name="i-heroicons-arrow-left" class="w-5 h-5" />
            </NuxtLink>
            <div>
              <h1 class="text-lg sm:text-xl font-bold tracking-tight">
                বিজ্ঞাপন বিস্তারিত
              </h1>
              <p class="text-xs sm:text-sm text-blue-100/90 mt-0.5">
                আপনার বিজ্ঞাপনের পারফরম্যান্স ও টার্গেটিং একনজরে
              </p>
            </div>
          </div>
          <div
            class="flex items-center px-3.5 py-2 bg-white/15 backdrop-blur rounded-xl text-sm"
          >
            <UIcon name="i-heroicons-wallet" class="w-4 h-4 mr-1.5" />
            <span class="font-semibold">৳{{ user?.user?.balance ?? 0 }}</span>
          </div>
        </div>
      </div>

      <!-- ── Loading state ───────────────────────────────────────── -->
      <div
        v-if="loading"
        class="flex flex-col items-center justify-center py-20 text-gray-400"
      >
        <span class="loader-dots">
          <span></span><span></span><span></span>
        </span>
        <p class="mt-3 text-sm">লোড হচ্ছে…</p>
      </div>

      <!-- ── Not-found state ─────────────────────────────────────── -->
      <div
        v-else-if="notFound || !ad"
        class="text-center py-16 bg-white rounded-xl border border-gray-100 shadow-sm"
      >
        <div
          class="w-14 h-14 mx-auto mb-3 rounded-2xl bg-gray-100 flex items-center justify-center"
        >
          <UIcon
            name="i-heroicons-magnifying-glass"
            class="w-7 h-7 text-gray-400"
          />
        </div>
        <p class="text-gray-700 text-sm font-medium">বিজ্ঞাপন পাওয়া যায়নি</p>
        <p class="text-gray-500 text-xs mt-1">
          বিজ্ঞাপনটি মুছে ফেলা হয়েছে বা লিংকটি সঠিক নয়
        </p>
        <NuxtLink
          to="/business-network/abn-ads"
          class="mt-4 inline-flex items-center gap-1.5 px-4 py-2 text-sm font-medium border border-indigo-200 text-indigo-700 hover:bg-indigo-50 rounded-xl transition-colors"
        >
          <UIcon name="i-heroicons-arrow-left" class="w-4 h-4" />
          প্যানেলে ফিরে যান
        </NuxtLink>
      </div>

      <!-- ── Details ─────────────────────────────────────────────── -->
      <div v-else class="space-y-4">
        <!-- Creative preview card -->
        <div class="bg-white rounded-xl border border-gray-100 shadow-sm overflow-hidden">
          <!-- Image creative -->
          <img
            v-if="creativeImage"
            :src="creativeImage"
            alt="Ad creative"
            class="w-full max-h-72 object-cover"
          />
          <!-- Video creative -->
          <div
            v-else-if="creativeVideo"
            class="relative w-full bg-gray-900"
          >
            <video
              :src="creativeVideo"
              controls
              class="w-full max-h-72 object-contain bg-black"
            ></video>
          </div>
          <!-- Boost / placeholder -->
          <div
            v-else
            class="w-full h-44 bg-gray-100 flex items-center justify-center text-gray-400"
          >
            <UIcon
              :name="ad.format === 'boost' ? 'i-heroicons-rocket-launch' : 'i-heroicons-photo'"
              class="w-10 h-10"
            />
          </div>

          <div class="p-4">
            <div class="text-[10px] uppercase tracking-wide text-gray-400">
              Sponsored
            </div>
            <h2 class="text-base font-semibold text-gray-800 mt-0.5">
              {{ ad.title }}
            </h2>
            <p class="text-sm text-gray-600 mt-1.5 whitespace-pre-line">
              {{ ad.description }}
            </p>

            <!-- Objective + status chips -->
            <div class="mt-3 flex flex-wrap items-center gap-1.5">
              <span
                class="px-2 py-0.5 rounded-md text-[11px] font-medium"
                :class="getObjectiveClass(ad.ad_objective)"
              >
                {{ getObjectiveText(ad.ad_objective) }}
              </span>
              <span
                class="px-2 py-0.5 rounded-md text-[11px] font-medium"
                :class="getStatusClass(ad.status)"
              >
                {{ getStatusText(ad.status) }}
              </span>
              <span
                class="px-2 py-0.5 rounded-md text-[11px] font-medium bg-gray-100 text-gray-600"
              >
                {{ formatLabel(ad.format) }}
              </span>
            </div>

            <!-- Reject reason -->
            <div
              v-if="ad.status === 'rejected' && ad.reject_reason"
              class="mt-3 text-xs bg-red-50 text-red-600 rounded-md px-2.5 py-1.5"
            >
              বাতিলের কারণ: {{ ad.reject_reason }}
            </div>
          </div>
        </div>

        <!-- Boosted post card -->
        <div
          v-if="ad.format === 'boost' && ad.boosted_post"
          class="bg-white rounded-xl border border-gray-100 shadow-sm p-4"
        >
          <h3 class="text-sm font-medium text-gray-800 mb-3 flex items-center">
            <UIcon
              name="i-heroicons-rocket-launch"
              class="w-4 h-4 mr-2 text-indigo-600"
            />
            বুস্ট করা পোস্ট
          </h3>
          <div
            class="flex items-center gap-3 p-3 border border-gray-200 rounded-xl bg-gray-50"
          >
            <img
              v-if="boostThumb"
              :src="boostThumb"
              class="w-16 h-16 rounded-md object-cover shrink-0 border border-gray-200"
            />
            <div
              v-else
              class="w-16 h-16 rounded-md bg-gray-100 flex items-center justify-center text-gray-400 shrink-0"
            >
              <UIcon name="i-heroicons-photo" class="w-6 h-6" />
            </div>
            <div class="min-w-0">
              <div class="text-sm font-semibold text-gray-800 truncate">
                {{ boostAuthorName }}
              </div>
              <p class="text-xs text-gray-600 line-clamp-2 mt-0.5">
                {{ boostExcerpt || "পোস্টের কনটেন্ট" }}
              </p>
            </div>
          </div>
        </div>

        <!-- Performance card -->
        <div class="bg-white rounded-xl border border-gray-100 shadow-sm p-4">
          <h3 class="text-sm font-medium text-gray-800 mb-3 flex items-center">
            <UIcon
              name="i-heroicons-chart-bar"
              class="w-4 h-4 mr-2 text-indigo-600"
            />
            পারফরম্যান্স
          </h3>

          <div class="grid grid-cols-2 sm:grid-cols-4 gap-2.5">
            <div
              class="border border-gray-100 rounded-xl p-3 flex items-center gap-2.5"
            >
              <div
                class="w-9 h-9 rounded-lg bg-blue-50 flex items-center justify-center shrink-0"
              >
                <UIcon name="i-heroicons-eye" class="w-4.5 h-4.5 text-blue-600" />
              </div>
              <div>
                <div class="text-lg font-bold text-gray-800 leading-none">
                  {{ ad.views || 0 }}
                </div>
                <div class="text-[11.5px] text-gray-500 mt-1">মোট ভিউ</div>
              </div>
            </div>
            <div
              class="border border-gray-100 rounded-xl p-3 flex items-center gap-2.5"
            >
              <div
                class="w-9 h-9 rounded-lg bg-sky-50 flex items-center justify-center shrink-0"
              >
                <UIcon
                  name="i-heroicons-cursor-arrow-rays"
                  class="w-4.5 h-4.5 text-sky-600"
                />
              </div>
              <div>
                <div class="text-lg font-bold text-gray-800 leading-none">
                  {{ ad.clicks || 0 }}
                </div>
                <div class="text-[11.5px] text-gray-500 mt-1">ক্লিক</div>
              </div>
            </div>
            <div
              class="border border-gray-100 rounded-xl p-3 flex items-center gap-2.5"
            >
              <div
                class="w-9 h-9 rounded-lg bg-purple-50 flex items-center justify-center shrink-0"
              >
                <UIcon
                  name="i-heroicons-banknotes"
                  class="w-4.5 h-4.5 text-purple-600"
                />
              </div>
              <div>
                <div class="text-lg font-bold text-gray-800 leading-none">
                  ৳{{ ad.spent || 0 }}
                </div>
                <div class="text-[11.5px] text-gray-500 mt-1">খরচ</div>
              </div>
            </div>
            <div
              class="border border-gray-100 rounded-xl p-3 flex items-center gap-2.5"
            >
              <div
                class="w-9 h-9 rounded-lg bg-rose-50 flex items-center justify-center shrink-0"
              >
                <UIcon
                  name="i-heroicons-cursor-arrow-ripple"
                  class="w-4.5 h-4.5 text-rose-600"
                />
              </div>
              <div>
                <div class="text-lg font-bold text-gray-800 leading-none">
                  ৳{{ cpc }}
                </div>
                <div class="text-[11.5px] text-gray-500 mt-1">CPC</div>
              </div>
            </div>
          </div>

          <!-- Delivery progress -->
          <div v-if="ad.estimated_views" class="mt-4">
            <div class="flex justify-between text-[11px] text-gray-500 mb-1">
              <span>{{ ad.views || 0 }}/{{ ad.estimated_views }} ভিউ</span>
              <span>{{ viewsPct }}%</span>
            </div>
            <div class="h-2 bg-gray-100 rounded-full overflow-hidden">
              <div
                class="h-full bg-indigo-400 rounded-full transition-all"
                :style="{ width: viewsPct + '%' }"
              ></div>
            </div>
          </div>
        </div>

        <!-- Targeting card -->
        <div class="bg-white rounded-xl border border-gray-100 shadow-sm p-4">
          <h3 class="text-sm font-medium text-gray-800 mb-3 flex items-center">
            <UIcon
              name="i-heroicons-adjustments-horizontal"
              class="w-4 h-4 mr-2 text-indigo-600"
            />
            টার্গেটিং
          </h3>

          <dl class="space-y-3 text-sm">
            <div class="flex flex-wrap items-start gap-2">
              <dt class="w-28 text-gray-500 shrink-0">অবজেক্টিভ</dt>
              <dd class="text-gray-800 font-medium">
                {{ getObjectiveText(ad.ad_objective) }}
              </dd>
            </div>
            <div class="flex flex-wrap items-start gap-2">
              <dt class="w-28 text-gray-500 shrink-0">লিঙ্গ</dt>
              <dd class="text-gray-800">{{ genderText }}</dd>
            </div>
            <div class="flex flex-wrap items-start gap-2">
              <dt class="w-28 text-gray-500 shrink-0">বয়স</dt>
              <dd class="text-gray-800">
                {{ ad.min_age }}–{{ ad.max_age }} বছর
              </dd>
            </div>
            <div class="flex flex-wrap items-start gap-2">
              <dt class="w-28 text-gray-500 shrink-0">লোকেশন</dt>
              <dd class="text-gray-800">{{ locationsText }}</dd>
            </div>

            <!-- Placements -->
            <div
              v-if="placementChips.length"
              class="flex flex-wrap items-start gap-2"
            >
              <dt class="w-28 text-gray-500 shrink-0">প্লেসমেন্ট</dt>
              <dd class="flex flex-wrap gap-1.5">
                <span
                  v-for="p in placementChips"
                  :key="p"
                  class="px-2.5 py-0.5 bg-gray-100 text-gray-700 text-xs font-medium rounded-full"
                >
                  {{ p }}
                </span>
              </dd>
            </div>

            <!-- Engagement segments -->
            <div
              v-if="ad.ad_objective === 'engagement' && segmentChips.length"
              class="flex flex-wrap items-start gap-2"
            >
              <dt class="w-28 text-gray-500 shrink-0">অডিয়েন্স</dt>
              <dd class="flex flex-wrap gap-1.5">
                <span
                  v-for="s in segmentChips"
                  :key="s"
                  class="px-2.5 py-0.5 bg-indigo-50 text-indigo-700 text-xs font-medium rounded-full"
                >
                  {{ s }}
                </span>
              </dd>
            </div>

            <!-- Retargeting sources -->
            <div
              v-if="ad.ad_objective === 'retargeting' && retargetChips.length"
              class="flex flex-wrap items-start gap-2"
            >
              <dt class="w-28 text-gray-500 shrink-0">সোর্স</dt>
              <dd class="flex flex-wrap gap-1.5">
                <span
                  v-for="r in retargetChips"
                  :key="r"
                  class="px-2.5 py-0.5 bg-purple-50 text-purple-700 text-xs font-medium rounded-full"
                >
                  {{ r }}
                </span>
              </dd>
            </div>
          </dl>
        </div>

        <!-- Schedule card -->
        <div class="bg-white rounded-xl border border-gray-100 shadow-sm p-4">
          <h3 class="text-sm font-medium text-gray-800 mb-3 flex items-center">
            <UIcon
              name="i-heroicons-calendar-days"
              class="w-4 h-4 mr-2 text-indigo-600"
            />
            সময়সূচি ও বাজেট
          </h3>

          <dl class="space-y-3 text-sm">
            <div class="flex flex-wrap items-start gap-2">
              <dt class="w-28 text-gray-500 shrink-0">তৈরি হয়েছে</dt>
              <dd class="text-gray-800">{{ formatDate(ad.created_at) }}</dd>
            </div>
            <div v-if="ad.start_at" class="flex flex-wrap items-start gap-2">
              <dt class="w-28 text-gray-500 shrink-0">শুরু</dt>
              <dd class="text-gray-800">{{ formatDate(ad.start_at) }}</dd>
            </div>
            <div v-if="ad.end_at" class="flex flex-wrap items-start gap-2">
              <dt class="w-28 text-gray-500 shrink-0">শেষ</dt>
              <dd class="text-gray-800">{{ formatDate(ad.end_at) }}</dd>
            </div>
            <div class="flex flex-wrap items-start gap-2">
              <dt class="w-28 text-gray-500 shrink-0">বাজেট</dt>
              <dd class="text-gray-800 font-medium">৳{{ ad.budget }}</dd>
            </div>
            <div
              v-if="ad.daily_budget"
              class="flex flex-wrap items-start gap-2"
            >
              <dt class="w-28 text-gray-500 shrink-0">দৈনিক বাজেট</dt>
              <dd class="text-gray-800">৳{{ ad.daily_budget }}</dd>
            </div>
          </dl>
        </div>

        <!-- Actions row (compact) -->
        <div class="flex flex-wrap items-center gap-2 pt-1">
          <button
            @click="navigateTo(`/business-network/abn-ads/create?edit=${ad.id}`)"
            class="inline-flex items-center gap-1.5 px-3.5 py-2 text-sm font-medium border border-indigo-200 text-indigo-700 hover:bg-indigo-50 rounded-xl transition-colors"
          >
            <UIcon name="i-heroicons-pencil-square" class="w-4 h-4" />
            সম্পাদনা করুন
          </button>

          <button
            v-if="ad.status === 'active' || ad.status === 'stoped'"
            @click="toggleStatus"
            :disabled="actionBusy"
            class="inline-flex items-center gap-1.5 px-3.5 py-2 text-sm font-medium border border-gray-300 text-gray-700 hover:bg-gray-100 disabled:opacity-50 rounded-xl transition-colors"
          >
            <UIcon
              :name="ad.status === 'active' ? 'i-heroicons-pause' : 'i-heroicons-play'"
              class="w-4 h-4"
            />
            {{ ad.status === "active" ? "বন্ধ করুন" : "চালু করুন" }}
          </button>

          <button
            v-if="['completed', 'stoped', 'rejected'].includes(ad.status)"
            @click="rerunAd"
            :disabled="actionBusy"
            class="inline-flex items-center gap-1.5 px-3.5 py-2 text-sm font-medium border border-indigo-300 text-indigo-600 hover:bg-indigo-50 disabled:opacity-50 rounded-xl transition-colors"
          >
            <UIcon name="i-heroicons-arrow-path" class="w-4 h-4" />
            আবার চালান
          </button>

          <button
            @click="deleteAd"
            :disabled="actionBusy"
            class="inline-flex items-center gap-1.5 px-3.5 py-2 text-sm font-medium border border-red-200 text-red-600 hover:bg-red-50 disabled:opacity-50 rounded-xl transition-colors"
          >
            <UIcon name="i-heroicons-trash" class="w-4 h-4" />
            মুছুন
          </button>
        </div>

        <p v-if="actionError" class="text-sm text-red-500">{{ actionError }}</p>
      </div>
    </div>
  </UContainer>
</template>

<script setup>
const { get, post, del } = useApi();
const { user } = useAuth();
const route = useRoute();

const ad = ref(null);
const loading = ref(true);
const notFound = ref(false);
const actionBusy = ref(false);
const actionError = ref("");

// ── Fetch the single ad ──
async function fetchAd() {
  loading.value = true;
  notFound.value = false;
  try {
    const res = await get(`/bn/abn-ads-panels/${route.params.id}/`);
    if (res.data && !res.error) {
      ad.value = res.data;
    } else {
      notFound.value = true;
    }
  } catch (e) {
    notFound.value = true;
  } finally {
    loading.value = false;
  }
}
await fetchAd();

// ── Creative media (first image / first video) ──
const creativeImage = computed(() => {
  const media = Array.isArray(ad.value?.media) ? ad.value.media : [];
  return media.find((m) => m?.image)?.image || "";
});
const creativeVideo = computed(() => {
  const media = Array.isArray(ad.value?.media) ? ad.value.media : [];
  return media.find((m) => m?.video)?.video || "";
});

// ── Boosted-post details (defensive field extraction) ──
const boostThumb = computed(() => {
  const p = ad.value?.boosted_post;
  if (!p || typeof p !== "object") return "";
  const media = Array.isArray(p.media)
    ? p.media
    : Array.isArray(p.post_media)
    ? p.post_media
    : [];
  const withImage = media.find((m) => m?.image);
  if (withImage) return withImage.image;
  const withThumb = media.find((m) => m?.thumbnail);
  if (withThumb) return withThumb.thumbnail;
  return p.image || p.thumbnail || "";
});
const boostAuthorName = computed(() => {
  const p = ad.value?.boosted_post;
  if (!p || typeof p !== "object") return "AdsyClub ইউজার";
  const a = p.author_details || p.author || p.user_details || p.user || {};
  return (
    a.name ||
    a.full_name ||
    [a.first_name, a.last_name].filter(Boolean).join(" ") ||
    a.username ||
    p.author_name ||
    "AdsyClub ইউজার"
  );
});
const boostExcerpt = computed(() => {
  const p = ad.value?.boosted_post;
  if (!p || typeof p !== "object") return "";
  const text = p.title || p.content || p.post_content || "";
  return String(text).replace(/<[^>]*>/g, "");
});

// ── Performance ──
const cpc = computed(() => {
  const clicks = Number(ad.value?.clicks) || 0;
  if (!clicks) return "0.00";
  return ((Number(ad.value?.spent) || 0) / clicks).toFixed(2);
});
const viewsPct = computed(() => {
  const est = Number(ad.value?.estimated_views) || 0;
  if (!est) return 0;
  return Math.min(100, Math.round(((Number(ad.value?.views) || 0) / est) * 100));
});

// ── Targeting labels ──
const genderText = computed(() => {
  const parts = [];
  if (ad.value?.male) parts.push("পুরুষ");
  if (ad.value?.female) parts.push("নারী");
  if (ad.value?.other) parts.push("অন্যান্য");
  return parts.length ? parts.join(", ") : "সবাই";
});

const locationsText = computed(() => {
  const locs = ad.value?.target_locations;
  if (Array.isArray(locs) && locs.length) return locs.join(", ");
  return "সারা বাংলাদেশ";
});

const placementLabels = {
  bn_feed: "বিজনেস নেটওয়ার্ক ফিড",
  shorts_banner: "Shorts ব্যানার",
  shorts_fullscreen: "Shorts ফুলস্ক্রিন",
  gigs_list: "মাইক্রো গিগস",
  sale_list: "সেল লিস্ট",
  news_list: "নিউজ",
  food_list: "ফুড জোন",
  web_feed: "ওয়েবসাইট",
};
const placementChips = computed(() =>
  (Array.isArray(ad.value?.placements) ? ad.value.placements : []).map(
    (p) => placementLabels[p] || p
  )
);

const segmentLabels = {
  fashion: "ফ্যাশন",
  beauty: "বিউটি",
  food: "খাবার",
  tech: "টেক/গ্যাজেট",
  business: "ব্যবসা",
  jobs_education: "চাকরি/শিক্ষা",
  entertainment: "বিনোদন",
  sports: "খেলাধুলা",
  health: "স্বাস্থ্য",
  travel: "ভ্রমণ",
  religion: "ধর্মীয়",
  agriculture: "কৃষি",
  vehicles_property: "গাড়ি/প্রপার্টি",
  finance: "ফাইন্যান্স",
};
const segmentChips = computed(() =>
  (Array.isArray(ad.value?.target_segments) ? ad.value.target_segments : []).map(
    (s) => segmentLabels[s] || s
  )
);

const retargetLabels = {
  ad_engagers: "বিজ্ঞাপনে ক্লিক/ভিউ করেছেন",
  followers: "ফলোয়াররা",
  post_engagers: "পোস্টে লাইক/কমেন্ট করেছেন",
  post_viewers: "পোস্ট দেখেছেন",
};
const retargetChips = computed(() =>
  (Array.isArray(ad.value?.retarget_sources) ? ad.value.retarget_sources : []).map(
    (r) => retargetLabels[r] || r
  )
);

// ── Objective / status / format labels ──
function getObjectiveClass(objective) {
  switch (objective) {
    case "retargeting":
      return "bg-purple-50 text-purple-700";
    case "announcement":
      return "bg-amber-50 text-amber-700";
    default:
      return "bg-indigo-50 text-indigo-700";
  }
}
function getObjectiveText(objective) {
  switch (objective) {
    case "retargeting":
      return "রিটার্গেটিং";
    case "announcement":
      return "ঘোষণা";
    default:
      return "এনগেজমেন্ট";
  }
}
function getStatusClass(status) {
  switch (status) {
    case "active":
      return "bg-sky-100 text-sky-700";
    case "review":
    case "pending":
      return "bg-amber-100 text-amber-600";
    case "rejected":
      return "bg-red-100 text-red-600";
    case "completed":
      return "bg-blue-100 text-blue-600";
    case "stoped":
    case "stopped":
      return "bg-gray-200 text-gray-600";
    default:
      return "bg-gray-100 text-gray-600";
  }
}
function getStatusText(status) {
  switch (status) {
    case "active":
      return "চালু";
    case "review":
    case "pending":
      return "রিভিউতে";
    case "rejected":
      return "বাতিল";
    case "completed":
      return "সম্পন্ন";
    case "stoped":
    case "stopped":
      return "বন্ধ";
    default:
      return status || "—";
  }
}
function formatLabel(format) {
  switch (format) {
    case "video":
      return "ভিডিও";
    case "boost":
      return "বুস্ট";
    default:
      return "ইমেজ";
  }
}

// ── Date formatting (Bangla locale) ──
function formatDate(dateString) {
  if (!dateString) return "—";
  try {
    return new Date(dateString).toLocaleDateString("bn-BD", {
      year: "numeric",
      month: "long",
      day: "numeric",
    });
  } catch (e) {
    return String(dateString).slice(0, 10);
  }
}

// ── Actions ──
async function toggleStatus() {
  if (!ad.value?.id) return;
  actionBusy.value = true;
  actionError.value = "";
  try {
    const res = await post(`/bn/ads/${ad.value.id}/toggle/`, {});
    if (res.data?.status) {
      await fetchAd();
    } else {
      actionError.value = "স্ট্যাটাস পরিবর্তন করা যায়নি — আবার চেষ্টা করুন।";
    }
  } catch (e) {
    actionError.value = "কিছু একটা সমস্যা হয়েছে — আবার চেষ্টা করুন।";
  } finally {
    actionBusy.value = false;
  }
}

async function rerunAd() {
  if (!ad.value?.id) return;
  actionBusy.value = true;
  actionError.value = "";
  try {
    const res = await post(`/bn/ads/${ad.value.id}/rerun/`, {});
    if (res.error) {
      actionError.value =
        res.error?.data?.detail || "আবার চালানো যায়নি — আবার চেষ্টা করুন।";
      return;
    }
    await navigateTo("/business-network/abn-ads");
  } catch (e) {
    actionError.value = "কিছু একটা সমস্যা হয়েছে — আবার চেষ্টা করুন।";
  } finally {
    actionBusy.value = false;
  }
}

async function deleteAd() {
  if (!ad.value?.id) return;
  if (!window.confirm("এই বিজ্ঞাপনটি মুছে ফেলতে চান? এটি আর ফেরানো যাবে না।")) {
    return;
  }
  actionBusy.value = true;
  actionError.value = "";
  try {
    await del(`/bn/abn-ads-panels/${ad.value.id}/`);
    await navigateTo("/business-network/abn-ads");
  } catch (e) {
    actionError.value = "মুছে ফেলা যায়নি — আবার চেষ্টা করুন।";
  } finally {
    actionBusy.value = false;
  }
}
</script>

<style scoped>
/* Three-dot loader */
.loader-dots {
  display: inline-flex;
  gap: 6px;
}
.loader-dots span {
  width: 9px;
  height: 9px;
  border-radius: 9999px;
  background: #6366f1;
  display: inline-block;
  animation: loader-bounce 1.4s infinite ease-in-out both;
}
.loader-dots span:nth-child(1) {
  animation-delay: -0.32s;
}
.loader-dots span:nth-child(2) {
  animation-delay: -0.16s;
}
@keyframes loader-bounce {
  0%,
  80%,
  100% {
    transform: scale(0);
    opacity: 0.4;
  }
  40% {
    transform: scale(1);
    opacity: 1;
  }
}
</style>
