<template>
  <UContainer class="mt-3 mb-10">
    <div class="max-w-5xl mx-auto">
      <!-- Page header -->
      <div
        class="bg-white border border-gray-200 shadow-sm rounded-md px-4 py-3 mb-4 flex items-center justify-between"
      >
        <div class="flex items-center gap-3">
          <NuxtLink
            to="/business-network/abn-ads"
            class="p-1.5 rounded-md hover:bg-gray-100 text-gray-600"
          >
            <UIcon name="i-heroicons-arrow-left" class="w-5 h-5" />
          </NuxtLink>
          <div>
            <h1 class="text-base font-semibold text-gray-800">
              Create New Ad
            </h1>
            <p class="text-xs text-gray-500">
              ABN Ads Panel — আপনার বিজ্ঞাপন AdsyClub-এর ইউজারদের কাছে পৌঁছে দিন
            </p>
          </div>
        </div>
        <div
          class="hidden sm:flex items-center px-3 py-1.5 bg-gray-100 text-sm rounded-md"
        >
          <span class="text-gray-600 mr-1">Balance:</span>
          <span class="font-semibold text-emerald-600">
            ৳{{ user?.user?.balance ?? 0 }}
          </span>
        </div>
      </div>

      <div class="flex flex-col lg:flex-row gap-4">
        <!-- ── Form ─────────────────────────────────────────────── -->
        <div class="w-full lg:w-3/5">
          <form
            @submit.prevent="submitAd"
            class="bg-white border border-gray-200 shadow-sm rounded-md p-5 space-y-5"
          >
            <!-- Title -->
            <div>
              <label class="block text-sm font-medium text-gray-800 mb-1">
                Ad Title <span class="text-red-500">*</span>
              </label>
              <input
                v-model="form.title"
                type="text"
                required
                maxlength="255"
                placeholder="যেমন: ঈদ অফারে ৩০% ছাড় — আজই অর্ডার করুন"
                class="block w-full px-3 py-2 text-sm border border-gray-300 rounded-md focus:outline-none focus:ring-emerald-500 focus:border-emerald-500"
              />
            </div>

            <!-- Category -->
            <div>
              <label class="block text-sm font-medium text-gray-800 mb-1">
                Category <span class="text-red-500">*</span>
              </label>
              <select
                v-model="form.category"
                required
                class="block w-full px-3 py-2 text-sm border border-gray-300 rounded-md focus:outline-none focus:ring-emerald-500 focus:border-emerald-500"
              >
                <option value="">Select Category</option>
                <option v-for="c in categories" :key="c.id" :value="c.id">
                  {{ c.name }}
                </option>
              </select>
            </div>

            <!-- Description -->
            <div>
              <label class="block text-sm font-medium text-gray-800 mb-1">
                Description <span class="text-red-500">*</span>
              </label>
              <textarea
                v-model="form.description"
                required
                rows="4"
                placeholder="আপনার পণ্য বা সেবা সম্পর্কে সংক্ষেপে লিখুন…"
                class="block w-full px-3 py-2 text-sm border border-gray-300 rounded-md focus:outline-none focus:ring-emerald-500 focus:border-emerald-500"
              ></textarea>
            </div>

            <!-- Images -->
            <div>
              <label class="block text-sm font-medium text-gray-800 mb-1">
                Ad Images
                <span class="text-xs font-normal text-gray-500"
                  >(সর্বোচ্চ ৪টি)</span
                >
              </label>
              <div class="flex flex-wrap gap-2">
                <div
                  v-for="(img, i) in form.images"
                  :key="i"
                  class="relative w-24 h-24 rounded-md overflow-hidden border border-gray-200"
                >
                  <img :src="img" class="w-full h-full object-cover" />
                  <button
                    type="button"
                    @click="form.images.splice(i, 1)"
                    class="absolute top-1 right-1 bg-black/60 text-white rounded-full p-0.5"
                  >
                    <UIcon name="i-heroicons-x-mark" class="w-3.5 h-3.5" />
                  </button>
                </div>
                <label
                  v-if="form.images.length < 4"
                  class="w-24 h-24 rounded-md border-2 border-dashed border-gray-300 hover:border-emerald-400 flex flex-col items-center justify-center cursor-pointer text-gray-400 hover:text-emerald-500"
                >
                  <UIcon name="i-heroicons-photo" class="w-6 h-6" />
                  <span class="text-[11px] mt-1">Add Image</span>
                  <input
                    type="file"
                    accept="image/*"
                    class="hidden"
                    @change="onImagePicked"
                  />
                </label>
              </div>
            </div>

            <!-- Ad type / CTA button -->
            <div>
              <label class="block text-sm font-medium text-gray-800 mb-1">
                Ad Button (কী করলে কী হবে)
                <span class="text-red-500">*</span>
              </label>
              <div class="grid grid-cols-2 gap-2">
                <button
                  v-for="t in adTypes"
                  :key="t.value"
                  type="button"
                  @click="form.ad_type = t.value"
                  class="flex items-center gap-2 px-3 py-2.5 text-sm border rounded-md transition-colors text-left"
                  :class="
                    form.ad_type === t.value
                      ? 'border-emerald-500 bg-emerald-50 text-emerald-700'
                      : 'border-gray-300 text-gray-700 hover:border-gray-400'
                  "
                >
                  <UIcon :name="t.icon" class="w-4 h-4 shrink-0" />
                  <span>{{ t.label }}</span>
                </button>
              </div>
              <div v-if="selectedType" class="mt-2">
                <input
                  v-model="form.ad_type_details"
                  :type="selectedType.inputType"
                  required
                  :placeholder="selectedType.placeholder"
                  class="block w-full px-3 py-2 text-sm border border-gray-300 rounded-md focus:outline-none focus:ring-emerald-500 focus:border-emerald-500"
                />
              </div>
            </div>

            <!-- Placements -->
            <div>
              <label class="block text-sm font-medium text-gray-800 mb-1">
                Placements (কোথায় দেখাবে)
                <span class="text-xs font-normal text-gray-500"
                  >— কিছু না বাছলে সব জায়গায়</span
                >
              </label>
              <div class="grid grid-cols-2 gap-1.5">
                <label
                  v-for="p in placementOptions"
                  :key="p.value"
                  class="inline-flex items-center gap-2 px-2.5 py-1.5 border rounded-md cursor-pointer text-sm"
                  :class="
                    form.placements.includes(p.value)
                      ? 'border-emerald-500 bg-emerald-50 text-emerald-700'
                      : 'border-gray-300 text-gray-700'
                  "
                >
                  <input
                    type="checkbox"
                    class="h-3.5 w-3.5 text-emerald-500 rounded"
                    :checked="form.placements.includes(p.value)"
                    @change="togglePlacement(p.value)"
                  />
                  <span>{{ p.label }}</span>
                </label>
              </div>
            </div>

            <!-- Audience -->
            <div>
              <label class="block text-sm font-medium text-gray-800 mb-1">
                Targeted Audience
              </label>
              <div class="flex gap-4">
                <label class="inline-flex items-center gap-2">
                  <input
                    type="checkbox"
                    v-model="form.male"
                    class="h-4 w-4 text-emerald-500 rounded"
                  />
                  <span class="text-sm text-gray-800">Male</span>
                </label>
                <label class="inline-flex items-center gap-2">
                  <input
                    type="checkbox"
                    v-model="form.female"
                    class="h-4 w-4 text-emerald-500 rounded"
                  />
                  <span class="text-sm text-gray-800">Female</span>
                </label>
                <label class="inline-flex items-center gap-2">
                  <input
                    type="checkbox"
                    v-model="form.other"
                    class="h-4 w-4 text-emerald-500 rounded"
                  />
                  <span class="text-sm text-gray-800">Other</span>
                </label>
              </div>
            </div>

            <!-- Age range -->
            <div>
              <label class="block text-sm font-medium text-gray-800 mb-1">
                Age Range
              </label>
              <div class="flex items-center gap-3">
                <input
                  v-model.number="form.min_age"
                  type="number"
                  min="13"
                  :max="form.max_age"
                  class="w-24 px-3 py-2 text-sm border border-gray-300 rounded-md focus:outline-none focus:ring-emerald-500 focus:border-emerald-500"
                />
                <span class="text-sm text-gray-500">থেকে</span>
                <input
                  v-model.number="form.max_age"
                  type="number"
                  :min="form.min_age"
                  max="100"
                  class="w-24 px-3 py-2 text-sm border border-gray-300 rounded-md focus:outline-none focus:ring-emerald-500 focus:border-emerald-500"
                />
                <span class="text-sm text-gray-500">বছর</span>
              </div>
            </div>

            <!-- Country -->
            <div>
              <label class="block text-sm font-medium text-gray-800 mb-1">
                Country
              </label>
              <select
                v-model="form.country"
                disabled
                class="block w-full px-3 py-2 text-sm border border-gray-300 rounded-md bg-gray-50 text-gray-500"
              >
                <option value="bangladesh">Bangladesh</option>
              </select>
              <p class="mt-1 text-xs text-gray-500">
                Currently only available in Bangladesh
              </p>
            </div>

            <!-- Budget -->
            <div>
              <label class="block text-sm font-medium text-gray-800 mb-1">
                Budget (৳) <span class="text-red-500">*</span>
              </label>
              <input
                v-model.number="form.budget"
                type="number"
                min="100"
                step="50"
                required
                class="block w-full px-3 py-2 text-sm border border-gray-300 rounded-md focus:outline-none focus:ring-emerald-500 focus:border-emerald-500"
              />
              <div
                class="mt-2 flex items-center justify-between bg-emerald-50 border border-emerald-200 rounded-md px-3 py-2"
              >
                <span class="text-sm text-emerald-700">Estimated Views</span>
                <span class="text-sm font-semibold text-emerald-700">
                  ~{{ estimatedViews.toLocaleString() }} views
                </span>
              </div>
              <p class="mt-1 text-xs text-gray-500">
                Estimated views পূর্ণ হলে বিজ্ঞাপন স্বয়ংক্রিয়ভাবে বন্ধ হয়ে
                যাবে।
              </p>
            </div>

            <!-- Submit -->
            <div class="pt-2 flex items-center gap-3">
              <button
                type="submit"
                :disabled="isSubmitting"
                class="px-5 py-2.5 text-sm font-medium bg-emerald-500 hover:bg-emerald-600 disabled:opacity-60 text-white rounded-md transition-colors"
              >
                {{ isSubmitting ? "Submitting…" : "Submit Ad" }}
              </button>
              <NuxtLink
                to="/business-network/abn-ads"
                class="px-5 py-2.5 text-sm font-medium border border-gray-300 hover:bg-gray-100 text-gray-700 rounded-md transition-colors"
              >
                Cancel
              </NuxtLink>
            </div>
            <p v-if="errorMsg" class="text-sm text-red-500">{{ errorMsg }}</p>
          </form>
        </div>

        <!-- ── Info / preview column ────────────────────────────── -->
        <div class="w-full lg:w-2/5 space-y-4">
          <!-- Live preview -->
          <div class="bg-white border border-gray-200 shadow-sm rounded-md p-4">
            <h3 class="text-sm font-medium text-gray-800 mb-3 flex items-center">
              <UIcon
                name="i-heroicons-eye"
                class="w-4 h-4 mr-2 text-emerald-500"
              />
              Ad Preview
            </h3>
            <div class="border border-gray-200 rounded-md overflow-hidden">
              <img
                v-if="form.images.length"
                :src="form.images[0]"
                class="w-full h-40 object-cover"
              />
              <div
                v-else
                class="w-full h-40 bg-gray-100 flex items-center justify-center text-gray-400"
              >
                <UIcon name="i-heroicons-photo" class="w-8 h-8" />
              </div>
              <div class="p-3">
                <div class="text-[10px] uppercase tracking-wide text-gray-400">
                  Sponsored
                </div>
                <div class="text-sm font-semibold text-gray-800 mt-0.5">
                  {{ form.title || "আপনার বিজ্ঞাপনের টাইটেল" }}
                </div>
                <p class="text-xs text-gray-600 mt-1 line-clamp-2">
                  {{ form.description || "বিজ্ঞাপনের বর্ণনা এখানে দেখা যাবে…" }}
                </p>
                <button
                  type="button"
                  class="mt-2 w-full py-1.5 text-xs font-medium bg-emerald-500 text-white rounded-md"
                >
                  {{ selectedType?.cta || "Learn More" }}
                </button>
              </div>
            </div>
          </div>

          <!-- Where the ad shows -->
          <div class="bg-white border border-gray-200 shadow-sm rounded-md p-4">
            <h3 class="text-sm font-medium text-gray-800 mb-3 flex items-center">
              <UIcon
                name="i-heroicons-map-pin"
                class="w-4 h-4 mr-2 text-emerald-500"
              />
              আপনার বিজ্ঞাপন যেখানে দেখাবে
            </h3>
            <ul class="space-y-2">
              <li
                v-for="p in placements"
                :key="p"
                class="flex items-start gap-2 text-sm text-gray-700"
              >
                <UIcon
                  name="i-heroicons-check-circle"
                  class="w-4 h-4 text-emerald-500 mt-0.5 shrink-0"
                />
                <span>{{ p }}</span>
              </li>
            </ul>
          </div>

          <!-- How it works -->
          <div class="bg-white border border-gray-200 shadow-sm rounded-md p-4">
            <h3 class="text-sm font-medium text-gray-800 mb-3 flex items-center">
              <UIcon
                name="i-heroicons-light-bulb"
                class="w-4 h-4 mr-2 text-emerald-500"
              />
              যেভাবে কাজ করে
            </h3>
            <ol class="space-y-2.5">
              <li
                v-for="(s, i) in steps"
                :key="i"
                class="flex items-start gap-2.5 text-sm text-gray-700"
              >
                <span
                  class="w-5 h-5 rounded-full bg-emerald-100 text-emerald-700 text-xs font-semibold flex items-center justify-center shrink-0 mt-0.5"
                  >{{ i + 1 }}</span
                >
                <span>{{ s }}</span>
              </li>
            </ol>
          </div>
        </div>
      </div>
    </div>
  </UContainer>
</template>

<script setup>
const { get, post } = useApi();
const { user } = useAuth();
const router = useRouter();

const categories = ref([]);
const isSubmitting = ref(false);
const errorMsg = ref("");

const form = reactive({
  title: "",
  category: "",
  description: "",
  images: [],
  budget: 200,
  country: "bangladesh",
  ad_type: "click_to_website",
  ad_type_details: "",
  male: true,
  female: true,
  other: false,
  min_age: 18,
  max_age: 65,
  placements: [],
});

// Placement keys mirror the backend's VALID_PLACEMENTS.
const placementOptions = [
  { value: "bn_feed", label: "বিজনেস নেটওয়ার্ক ফিড" },
  { value: "shorts_banner", label: "Shorts ব্যানার" },
  { value: "shorts_fullscreen", label: "Shorts ফুলস্ক্রিন" },
  { value: "gigs_list", label: "মাইক্রো গিগস" },
  { value: "sale_list", label: "সেল লিস্ট" },
  { value: "news_list", label: "নিউজ" },
  { value: "food_list", label: "ফুড জোন" },
  { value: "web_feed", label: "ওয়েবসাইট" },
];

function togglePlacement(value) {
  const i = form.placements.indexOf(value);
  if (i >= 0) form.placements.splice(i, 1);
  else form.placements.push(value);
}

// CTA button types — mirrors AbnAdsPanel.AD_TyPES on the backend.
const adTypes = [
  {
    value: "click_to_website",
    label: "Visit Website",
    cta: "Visit Website",
    icon: "i-heroicons-globe-alt",
    inputType: "url",
    placeholder: "https://your-website.com",
  },
  {
    value: "call_on_whatsapp",
    label: "WhatsApp",
    cta: "Message on WhatsApp",
    icon: "i-heroicons-chat-bubble-left-right",
    inputType: "tel",
    placeholder: "WhatsApp নম্বর (যেমন 01XXXXXXXXX)",
  },
  {
    value: "call_on_phone",
    label: "Call Now",
    cta: "Call Now",
    icon: "i-heroicons-phone",
    inputType: "tel",
    placeholder: "ফোন নম্বর (যেমন 01XXXXXXXXX)",
  },
  {
    value: "email_us",
    label: "Email Us",
    cta: "Send Email",
    icon: "i-heroicons-envelope",
    inputType: "email",
    placeholder: "contact@example.com",
  },
];

const selectedType = computed(() =>
  adTypes.find((t) => t.value === form.ad_type)
);

// Same rate the panel has always used: ৳200 → ~500 views (2.5 views/৳).
const estimatedViews = computed(() =>
  Math.max(0, Math.round((Number(form.budget) || 0) * 2.5))
);

const placements = [
  "বিজনেস নেটওয়ার্ক ফিড (পোস্টের মাঝে স্পনসরড কার্ড)",
  "BN Shorts (ভিডিওর মাঝে)",
  "মাইক্রো গিগস, সেল, নিউজ, ক্লাসিফাইড ও ফুড জোন লিস্ট",
  "AdsyClub ওয়েবসাইট",
];

const steps = [
  "ফর্ম পূরণ করে Submit করুন — বিজ্ঞাপন রিভিউতে যাবে।",
  "অ্যাডমিন approve করলে বিজ্ঞাপন Active হবে।",
  "Budget অনুযায়ী estimated views পর্যন্ত ইউজারদের দেখানো হবে।",
  "Estimated views পূর্ণ হলে বিজ্ঞাপন স্বয়ংক্রিয়ভাবে বন্ধ হবে — প্যানেল থেকে performance দেখুন।",
];

async function loadCategories() {
  const res = await get("/bn/abn-ads-categories/");
  const d = res.data;
  categories.value = Array.isArray(d) ? d : d?.results ?? [];
}
await loadCategories();

function onImagePicked(e) {
  const file = e.target.files?.[0];
  if (!file) return;
  const reader = new FileReader();
  reader.onload = () => {
    if (form.images.length < 4) form.images.push(reader.result);
  };
  reader.readAsDataURL(file);
  e.target.value = "";
}

async function submitAd() {
  errorMsg.value = "";
  if (!form.male && !form.female && !form.other) {
    errorMsg.value = "কমপক্ষে একটি audience নির্বাচন করুন।";
    return;
  }
  isSubmitting.value = true;
  try {
    const res = await post("/bn/abn-ads-panels/", {
      ...form,
      estimated_views: estimatedViews.value,
    });
    if (res.data) {
      router.push("/business-network/abn-ads");
    } else {
      // Surface the backend's message (e.g. insufficient balance) directly.
      const detail =
        res.error?.data?.detail || res.error?.data?.error || null;
      errorMsg.value =
        detail ||
        "বিজ্ঞাপন জমা দেওয়া যায়নি — তথ্যগুলো আবার দেখে চেষ্টা করুন।";
    }
  } catch (e) {
    console.error("Error submitting ad:", e);
    errorMsg.value = "কিছু একটা সমস্যা হয়েছে — আবার চেষ্টা করুন।";
  } finally {
    isSubmitting.value = false;
  }
}
</script>
