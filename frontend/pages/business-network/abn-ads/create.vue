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
          <span class="font-semibold text-indigo-700">
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
                class="block w-full px-3 py-2 text-sm border border-gray-300 rounded-md focus:outline-none focus:ring-indigo-600 focus:border-indigo-600"
              />
            </div>

            <!-- Format -->
            <div>
              <label class="block text-sm font-medium text-gray-800 mb-1">
                Ad Format
              </label>
              <div class="grid grid-cols-2 gap-2">
                <button
                  type="button"
                  @click="form.format = 'image'"
                  class="px-3 py-2.5 text-sm border rounded-md"
                  :class="
                    form.format === 'image'
                      ? 'border-indigo-500 bg-indigo-50 text-indigo-700'
                      : 'border-gray-300 text-gray-700'
                  "
                >
                  🖼️ Image Ad
                </button>
                <button
                  type="button"
                  @click="form.format = 'video'"
                  class="px-3 py-2.5 text-sm border rounded-md"
                  :class="
                    form.format === 'video'
                      ? 'border-indigo-500 bg-indigo-50 text-indigo-700'
                      : 'border-gray-300 text-gray-700'
                  "
                >
                  🎬 Video Ad (5s skippable)
                </button>
              </div>
            </div>

            <!-- Category -->
            <div>
              <label class="block text-sm font-medium text-gray-800 mb-1">
                Category <span class="text-red-500">*</span>
              </label>
              <select
                v-model="form.category"
                required
                class="block w-full px-3 py-2 text-sm border border-gray-300 rounded-md focus:outline-none focus:ring-indigo-600 focus:border-indigo-600"
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
                class="block w-full px-3 py-2 text-sm border border-gray-300 rounded-md focus:outline-none focus:ring-indigo-600 focus:border-indigo-600"
              ></textarea>
            </div>

            <!-- Video upload (video format) -->
            <div v-if="form.format === 'video'" class="space-y-3">
              <div>
                <label class="block text-sm font-medium text-gray-800 mb-1">
                  Ad Video <span class="text-red-500">*</span>
                  <span class="text-xs font-normal text-gray-500"
                    >(সর্বোচ্চ 60MB)</span
                  >
                </label>
                <input
                  type="file"
                  accept="video/*"
                  @change="onVideoPicked"
                  class="block w-full text-sm text-gray-600 file:mr-3 file:px-3 file:py-1.5 file:border-0 file:rounded-md file:bg-indigo-50 file:text-indigo-700"
                />
                <p v-if="videoUploading" class="mt-1 text-xs text-indigo-700">
                  ভিডিও আপলোড হচ্ছে…
                </p>
                <p
                  v-else-if="videoMediaId"
                  class="mt-1 text-xs text-indigo-700"
                >
                  ✓ ভিডিও আপলোড হয়েছে
                </p>
              </div>
              <div>
                <label class="block text-sm font-medium text-gray-800 mb-1">
                  Companion Banner
                  <span class="text-xs font-normal text-gray-500"
                    >(ভিডিওর নিচে দেখাবে)</span
                  >
                </label>
                <div class="flex items-center gap-3">
                  <img
                    v-if="companionBanner"
                    :src="companionBanner"
                    class="h-14 rounded-md border border-gray-200"
                  />
                  <label
                    class="px-3 py-2 text-sm border border-dashed border-gray-300 rounded-md cursor-pointer text-gray-600 hover:border-indigo-400"
                  >
                    {{ companionBanner ? "Change" : "Upload Banner" }}
                    <input
                      type="file"
                      accept="image/*"
                      class="hidden"
                      @change="onBannerPicked"
                    />
                  </label>
                </div>
              </div>
            </div>

            <!-- Images -->
            <div v-if="form.format === 'image'">
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
                  class="w-24 h-24 rounded-md border-2 border-dashed border-gray-300 hover:border-indigo-400 flex flex-col items-center justify-center cursor-pointer text-gray-400 hover:text-indigo-600"
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
                      ? 'border-indigo-600 bg-indigo-50 text-indigo-700'
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
                  class="block w-full px-3 py-2 text-sm border border-gray-300 rounded-md focus:outline-none focus:ring-indigo-600 focus:border-indigo-600"
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
              <div class="grid grid-cols-2 gap-x-4 gap-y-2 mt-1.5">
                <label
                  v-for="p in placementOptions"
                  :key="p.value"
                  class="inline-flex items-center gap-2.5 cursor-pointer text-sm text-gray-700 hover:text-gray-900"
                >
                  <input
                    type="checkbox"
                    class="h-4 w-4 rounded border-gray-300 accent-indigo-600"
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
                    class="h-4 w-4 text-indigo-600 rounded"
                  />
                  <span class="text-sm text-gray-800">Male</span>
                </label>
                <label class="inline-flex items-center gap-2">
                  <input
                    type="checkbox"
                    v-model="form.female"
                    class="h-4 w-4 text-indigo-600 rounded"
                  />
                  <span class="text-sm text-gray-800">Female</span>
                </label>
                <label class="inline-flex items-center gap-2">
                  <input
                    type="checkbox"
                    v-model="form.other"
                    class="h-4 w-4 text-indigo-600 rounded"
                  />
                  <span class="text-sm text-gray-800">Other</span>
                </label>
              </div>
            </div>

            <!-- Age range -->
            <div>
              <div class="flex items-center justify-between mb-2">
                <label class="text-sm font-medium text-gray-800">
                  Age Range
                </label>
                <span
                  class="text-sm font-semibold text-indigo-700 bg-indigo-50 px-2.5 py-0.5 rounded-md"
                >
                  {{ form.min_age }} – {{ form.max_age }} বছর
                </span>
              </div>
              <div class="relative h-6 mx-1">
                <div
                  class="absolute top-1/2 -translate-y-1/2 w-full h-1.5 bg-gray-200 rounded-full"
                ></div>
                <div
                  class="absolute top-1/2 -translate-y-1/2 h-1.5 bg-indigo-500 rounded-full"
                  :style="{
                    left: agePct(form.min_age) + '%',
                    width: agePct(form.max_age) - agePct(form.min_age) + '%',
                  }"
                ></div>
                <input
                  type="range"
                  min="13"
                  max="100"
                  :value="form.min_age"
                  @input="onMinAge($event)"
                  class="age-thumb"
                />
                <input
                  type="range"
                  min="13"
                  max="100"
                  :value="form.max_age"
                  @input="onMaxAge($event)"
                  class="age-thumb"
                />
              </div>
              <div class="flex justify-between text-[11px] text-gray-400 mx-1">
                <span>১৩</span>
                <span>১০০</span>
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
                class="block w-full px-3 py-2 text-sm border border-gray-300 rounded-md focus:outline-none focus:ring-indigo-600 focus:border-indigo-600"
              />
              <div
                class="mt-2 flex items-center justify-between bg-indigo-50 border border-indigo-100 rounded-md px-3 py-2"
              >
                <span class="text-sm text-indigo-700">Estimated Views</span>
                <span
                  v-if="estimating"
                  class="flex items-center gap-1.5 text-sm text-indigo-500"
                >
                  <svg
                    class="animate-spin h-3.5 w-3.5"
                    xmlns="http://www.w3.org/2000/svg"
                    fill="none"
                    viewBox="0 0 24 24"
                  >
                    <circle
                      class="opacity-25"
                      cx="12"
                      cy="12"
                      r="10"
                      stroke="currentColor"
                      stroke-width="4"
                    ></circle>
                    <path
                      class="opacity-75"
                      fill="currentColor"
                      d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4z"
                    ></path>
                  </svg>
                  হিসাব করা হচ্ছে…
                </span>
                <span v-else class="text-sm font-semibold text-indigo-700">
                  ~{{ displayedViews.toLocaleString() }} views
                </span>
              </div>
              <p class="mt-1 text-xs text-gray-500">
                Estimated views পূর্ণ হলে বিজ্ঞাপন স্বয়ংক্রিয়ভাবে বন্ধ হয়ে
                যাবে।
              </p>
            </div>

            <!-- Daily budget (pacing) -->
            <div>
              <label class="block text-sm font-medium text-gray-800 mb-1">
                Daily Budget (৳)
                <span class="text-xs font-normal text-gray-500"
                  >— optional, খালি রাখলে একটানা চলবে</span
                >
              </label>
              <input
                v-model.number="form.daily_budget"
                type="number"
                min="0"
                step="10"
                placeholder="যেমন 50"
                class="block w-full px-3 py-2 text-sm border border-gray-300 rounded-md focus:outline-none focus:ring-indigo-600 focus:border-indigo-600"
              />
            </div>

            <!-- Schedule -->
            <div>
              <label class="block text-sm font-medium text-gray-800 mb-1">
                Schedule
                <span class="text-xs font-normal text-gray-500"
                  >— optional, খালি রাখলে আজ থেকেই চলবে</span
                >
              </label>
              <div class="space-y-2.5">
                <div>
                  <div class="text-xs text-gray-500 mb-1">শুরুর তারিখ</div>
                  <div class="grid grid-cols-3 gap-2">
                    <select v-model="sched.sd" class="date-select">
                      <option value="">দিন</option>
                      <option v-for="d in 31" :key="d" :value="d">
                        {{ d }}
                      </option>
                    </select>
                    <select v-model="sched.sm" class="date-select">
                      <option value="">মাস</option>
                      <option
                        v-for="(m, i) in monthNames"
                        :key="i"
                        :value="i + 1"
                      >
                        {{ m }}
                      </option>
                    </select>
                    <select v-model="sched.sy" class="date-select">
                      <option value="">বছর</option>
                      <option v-for="y in yearOptions" :key="y" :value="y">
                        {{ y }}
                      </option>
                    </select>
                  </div>
                </div>
                <div>
                  <div class="text-xs text-gray-500 mb-1">শেষের তারিখ</div>
                  <div class="grid grid-cols-3 gap-2">
                    <select v-model="sched.ed" class="date-select">
                      <option value="">দিন</option>
                      <option v-for="d in 31" :key="d" :value="d">
                        {{ d }}
                      </option>
                    </select>
                    <select v-model="sched.em" class="date-select">
                      <option value="">মাস</option>
                      <option
                        v-for="(m, i) in monthNames"
                        :key="i"
                        :value="i + 1"
                      >
                        {{ m }}
                      </option>
                    </select>
                    <select v-model="sched.ey" class="date-select">
                      <option value="">বছর</option>
                      <option v-for="y in yearOptions" :key="y" :value="y">
                        {{ y }}
                      </option>
                    </select>
                  </div>
                </div>
              </div>
            </div>

            <!-- Locations -->
            <div>
              <label class="block text-sm font-medium text-gray-800 mb-1">
                Target Locations
                <span class="text-xs font-normal text-gray-500"
                  >— কিছু না বাছলে সারা বাংলাদেশ</span
                >
              </label>
              <div class="grid grid-cols-1 sm:grid-cols-3 gap-2">
                <select v-model="selDivision" class="date-select">
                  <option value="">বিভাগ</option>
                  <option
                    v-for="r in geoRegions"
                    :key="r.name_eng"
                    :value="r.name_eng"
                  >
                    {{ r.name_eng }}
                  </option>
                </select>
                <select
                  v-model="selCity"
                  class="date-select"
                  :disabled="!selDivision"
                >
                  <option value="">জেলা / সিটি</option>
                  <option
                    v-for="c in geoCities"
                    :key="c.name_eng"
                    :value="c.name_eng"
                  >
                    {{ c.name_eng }}
                  </option>
                </select>
                <select
                  v-model="selArea"
                  class="date-select"
                  :disabled="!selCity"
                >
                  <option value="">এরিয়া / উপজেলা</option>
                  <option
                    v-for="u in geoUpazilas"
                    :key="u.name_eng"
                    :value="u.name_eng"
                  >
                    {{ u.name_eng }}
                  </option>
                </select>
              </div>
              <button
                type="button"
                @click="addLocation"
                :disabled="!selDivision"
                class="mt-2 px-3 py-1.5 text-sm font-medium border border-indigo-200 text-indigo-700 hover:bg-indigo-50 disabled:opacity-50 rounded-md transition-colors inline-flex items-center gap-1.5"
              >
                <UIcon name="i-heroicons-plus" class="w-4 h-4" />
                লোকেশন যোগ করুন
              </button>
              <div
                v-if="selectedLocations.length"
                class="mt-2 flex flex-wrap gap-1.5"
              >
                <span
                  v-for="(loc, i) in selectedLocations"
                  :key="loc"
                  class="inline-flex items-center gap-1 px-2.5 py-1 bg-indigo-50 text-indigo-700 text-xs font-medium rounded-full"
                >
                  {{ loc }}
                  <button
                    type="button"
                    @click="selectedLocations.splice(i, 1)"
                    class="hover:text-indigo-900"
                  >
                    <UIcon name="i-heroicons-x-mark" class="w-3.5 h-3.5" />
                  </button>
                </span>
              </div>
            </div>

            <!-- Submit -->
            <div class="pt-2 flex items-center gap-3">
              <button
                type="submit"
                :disabled="isSubmitting"
                class="px-5 py-2.5 text-sm font-medium bg-indigo-600 hover:bg-indigo-700 disabled:opacity-60 text-white rounded-md transition-colors"
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
                class="w-4 h-4 mr-2 text-indigo-600"
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
                  class="mt-2 w-full py-1.5 text-xs font-medium bg-indigo-600 text-white rounded-md"
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
                class="w-4 h-4 mr-2 text-indigo-600"
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
                  class="w-4 h-4 text-indigo-600 mt-0.5 shrink-0"
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
                class="w-4 h-4 mr-2 text-indigo-600"
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
                  class="w-5 h-5 rounded-full bg-indigo-100 text-indigo-700 text-xs font-semibold flex items-center justify-center shrink-0 mt-0.5"
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
  format: "image",
  daily_budget: null,
  start_at: "",
  end_at: "",
});

// Video-format uploads
const videoMediaId = ref(null);
const videoUploading = ref(false);
const companionBanner = ref(""); // base64 data URL

// ── Age range slider ──
function agePct(v) {
  return ((v - 13) / (100 - 13)) * 100;
}
function onMinAge(e) {
  const v = Number(e.target.value);
  form.min_age = Math.min(v, form.max_age - 1);
  e.target.value = form.min_age;
}
function onMaxAge(e) {
  const v = Number(e.target.value);
  form.max_age = Math.max(v, form.min_age + 1);
  e.target.value = form.max_age;
}

// ── Schedule (day/month/year dropdowns) ──
const monthNames = [
  "জানুয়ারি", "ফেব্রুয়ারি", "মার্চ", "এপ্রিল", "মে", "জুন",
  "জুলাই", "আগস্ট", "সেপ্টেম্বর", "অক্টোবর", "নভেম্বর", "ডিসেম্বর",
];
const thisYear = new Date().getFullYear();
const yearOptions = [thisYear, thisYear + 1, thisYear + 2];
const sched = reactive({ sd: "", sm: "", sy: "", ed: "", em: "", ey: "" });
function schedDate(d, m, y) {
  if (!d || !m || !y) return "";
  return `${y}-${String(m).padStart(2, "0")}-${String(d).padStart(2, "0")}`;
}

// ── Target locations (division → city → area cascading dropdowns) ──
const geoRegions = ref([]);
const geoCities = ref([]);
const geoUpazilas = ref([]);
const selDivision = ref("");
const selCity = ref("");
const selArea = ref("");
const selectedLocations = ref([]);

async function loadRegions() {
  const res = await get("/geo/regions/?country_name_eng=Bangladesh");
  geoRegions.value = Array.isArray(res.data) ? res.data : [];
}
watch(selDivision, async (v) => {
  selCity.value = "";
  selArea.value = "";
  geoCities.value = [];
  geoUpazilas.value = [];
  if (!v) return;
  const res = await get(`/geo/cities/?region_name_eng=${encodeURIComponent(v)}`);
  geoCities.value = Array.isArray(res.data) ? res.data : [];
});
watch(selCity, async (v) => {
  selArea.value = "";
  geoUpazilas.value = [];
  if (!v) return;
  const res = await get(`/geo/upazila/?city_name_eng=${encodeURIComponent(v)}`);
  geoUpazilas.value = Array.isArray(res.data) ? res.data : [];
});
function addLocation() {
  // Most specific level wins: area > city > division.
  const loc = selArea.value || selCity.value || selDivision.value;
  if (loc && !selectedLocations.value.includes(loc)) {
    selectedLocations.value.push(loc);
  }
  selArea.value = "";
}

// ── Estimated views: brief "calculating…" pass + approximate figure ──
const estimating = ref(false);
const displayedViews = ref(0);
let estDebounce = null;
let estTimer = null;
function computeDisplayedViews() {
  const base = Math.max(0, Math.round((Number(form.budget) || 0) * 2.5));
  // Show a nearby approximate number, rounded to tens.
  const jitter = 1 + (Math.random() * 0.12 - 0.06);
  displayedViews.value = Math.max(0, Math.round((base * jitter) / 10) * 10);
}
watch(
  () => form.budget,
  () => {
    clearTimeout(estDebounce);
    clearTimeout(estTimer);
    estimating.value = true;
    estDebounce = setTimeout(() => {
      estTimer = setTimeout(() => {
        computeDisplayedViews();
        estimating.value = false;
      }, 700);
    }, 300);
  },
  { immediate: true }
);

async function onVideoPicked(e) {
  const file = e.target.files?.[0];
  if (!file) return;
  videoUploading.value = true;
  videoMediaId.value = null;
  try {
    const fd = new FormData();
    fd.append("video", file);
    const res = await post("/bn/ads/upload-video/", fd);
    videoMediaId.value = res.data?.media_id || null;
    if (!videoMediaId.value) {
      errorMsg.value = "ভিডিও আপলোড করা যায়নি — আবার চেষ্টা করুন।";
    }
  } finally {
    videoUploading.value = false;
    e.target.value = "";
  }
}

function onBannerPicked(e) {
  const file = e.target.files?.[0];
  if (!file) return;
  const reader = new FileReader();
  reader.onload = () => (companionBanner.value = reader.result);
  reader.readAsDataURL(file);
  e.target.value = "";
}

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
loadRegions();

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
  if (form.format === "video" && !videoMediaId.value) {
    errorMsg.value = "Video ad-এর জন্য আগে ভিডিও আপলোড করুন।";
    return;
  }
  const startDate = schedDate(sched.sd, sched.sm, sched.sy);
  const endDate = schedDate(sched.ed, sched.em, sched.ey);
  if (startDate && endDate && endDate < startDate) {
    errorMsg.value = "শেষের তারিখ শুরুর তারিখের আগে হতে পারে না।";
    return;
  }
  isSubmitting.value = true;
  try {
    const payload = {
      ...form,
      daily_budget: form.daily_budget || null,
      start_at: startDate ? `${startDate}T00:00:00+06:00` : null,
      end_at: endDate ? `${endDate}T23:59:59+06:00` : null,
      target_locations: [...selectedLocations.value],
      estimated_views: estimatedViews.value,
    };
    if (form.format === "video") {
      payload.media_ids = [videoMediaId.value];
      if (companionBanner.value) {
        payload.companion_banner_b64 = companionBanner.value;
      }
      payload.images = []; // video creative — no base64 images
    }
    const res = await post("/bn/abn-ads-panels/", payload);
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

<style scoped>
/* Dual-thumb age range slider: two overlapping native ranges, track drawn
   by the divs behind them, only the thumbs receive pointer events. */
.age-thumb {
  -webkit-appearance: none;
  appearance: none;
  position: absolute;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  background: transparent;
  pointer-events: none;
  margin: 0;
}
.age-thumb::-webkit-slider-thumb {
  -webkit-appearance: none;
  appearance: none;
  pointer-events: auto;
  width: 18px;
  height: 18px;
  border-radius: 9999px;
  background: #fff;
  border: 2px solid #4f46e5;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.25);
  cursor: pointer;
}
.age-thumb::-moz-range-thumb {
  pointer-events: auto;
  width: 18px;
  height: 18px;
  border-radius: 9999px;
  background: #fff;
  border: 2px solid #4f46e5;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.25);
  cursor: pointer;
}
.age-thumb::-moz-range-track {
  background: transparent;
}

.date-select {
  display: block;
  width: 100%;
  padding: 0.5rem 0.75rem;
  font-size: 0.875rem;
  border: 1px solid #d1d5db;
  border-radius: 0.375rem;
  background-color: #fff;
  color: #374151;
}
.date-select:disabled {
  background-color: #f9fafb;
  color: #9ca3af;
}
.date-select:focus {
  outline: none;
  border-color: #6366f1;
  box-shadow: 0 0 0 1px #6366f1;
}
</style>
