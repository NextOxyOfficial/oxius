<template>
  <UContainer class="mt-3 mb-10">
    <div class="max-w-5xl mx-auto">
      <!-- ── Hero header (same shell as the panel page) ── -->
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
                নতুন বিজ্ঞাপন তৈরি করুন
              </h1>
              <p class="text-xs sm:text-sm text-blue-100/90 mt-0.5">
                আপনার বিজ্ঞাপন AdsyClub-এর হাজারো ইউজারের কাছে পৌঁছে দিন
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

      <div class="flex flex-col lg:flex-row gap-4">
        <!-- ── Form ─────────────────────────────────────────────── -->
        <div class="w-full lg:w-3/5">
          <form
            @submit.prevent="submitAd"
            class="bg-white border border-gray-100 shadow-sm rounded-xl p-5 space-y-5"
          >
            <!-- Campaign objective -->
            <div>
              <label class="block text-sm font-medium text-gray-800 mb-1">
                ক্যাম্পেইন অবজেক্টিভ
              </label>
              <div class="grid grid-cols-1 sm:grid-cols-3 gap-2">
                <button
                  v-for="obj in objectiveOptions"
                  :key="obj.value"
                  type="button"
                  @click="form.ad_objective = obj.value"
                  class="px-3 py-2.5 text-left border rounded-md transition-colors"
                  :class="
                    form.ad_objective === obj.value
                      ? 'border-indigo-500 bg-indigo-50'
                      : 'border-gray-300 hover:border-gray-400'
                  "
                >
                  <div
                    class="text-sm font-semibold"
                    :class="
                      form.ad_objective === obj.value
                        ? 'text-indigo-700'
                        : 'text-gray-800'
                    "
                  >
                    {{ obj.emoji }} {{ obj.title }}
                  </div>
                  <p class="text-xs text-gray-600 mt-0.5 leading-snug">
                    {{ obj.desc }}
                  </p>
                </button>
              </div>
            </div>

            <!-- Target segments (engagement objective) -->
            <div v-if="form.ad_objective === 'engagement'">
              <label class="block text-sm font-medium text-gray-800 mb-1">
                টার্গেট অডিয়েন্স (ঐচ্ছিক)
              </label>
              <div class="flex flex-wrap gap-1.5">
                <button
                  v-for="seg in segmentOptions"
                  :key="seg.value"
                  type="button"
                  @click="toggleSegment(seg.value)"
                  class="px-2.5 py-1 text-xs font-medium rounded-full border transition-colors"
                  :class="
                    form.target_segments.includes(seg.value)
                      ? 'bg-indigo-600 text-white border-indigo-600'
                      : 'border-gray-300 text-gray-700 hover:border-gray-400'
                  "
                >
                  {{ seg.label }}
                </button>
              </div>
              <p class="mt-1 text-xs text-gray-500">
                কিছু না বাছলে সবাই দেখবে
              </p>
            </div>

            <!-- Retargeting sources (retargeting objective) -->
            <div
              v-if="form.ad_objective === 'retargeting'"
              class="space-y-3"
            >
              <div>
                <label class="block text-sm font-medium text-gray-800 mb-1">
                  অডিয়েন্স সোর্স
                </label>
                <div class="grid grid-cols-1 gap-y-2 mt-1.5">
                  <label
                    v-for="s in retargetSourceOptions"
                    :key="s.value"
                    class="inline-flex items-center gap-2.5 cursor-pointer text-sm text-gray-700 hover:text-gray-900"
                  >
                    <input
                      type="checkbox"
                      class="h-4 w-4 rounded border-gray-300 accent-indigo-600"
                      :checked="form.retarget_sources.includes(s.value)"
                      @change="toggleRetargetSource(s.value)"
                    />
                    <span>{{ s.label }}</span>
                  </label>
                </div>
              </div>
              <div>
                <label class="block text-sm font-medium text-gray-800 mb-1">
                  কত দিনের অডিয়েন্স
                </label>
                <select v-model.number="form.retarget_days" class="date-select">
                  <option :value="7">গত ৭ দিন</option>
                  <option :value="30">গত ৩০ দিন</option>
                  <option :value="90">গত ৯০ দিন</option>
                </select>
              </div>
              <div
                v-if="audienceLoading"
                class="inline-flex items-center gap-1.5 px-3 py-1.5 bg-indigo-50 text-indigo-700 text-sm font-medium rounded-full"
              >
                অডিয়েন্স হিসাব করা হচ্ছে…
              </div>
              <div
                v-else-if="audienceSize !== null && audienceSize > 0"
                class="inline-flex items-center gap-1.5 px-3 py-1.5 bg-indigo-50 text-indigo-700 text-sm font-medium rounded-full"
              >
                <UIcon name="i-heroicons-users" class="w-4 h-4" />
                আনুমানিক অডিয়েন্স: ~{{ audienceSize.toLocaleString() }} জন
              </div>
              <div
                v-else-if="audienceSize === 0"
                class="flex items-start gap-2 px-3 py-2 bg-amber-50 border border-amber-200 text-amber-700 text-xs rounded-md"
              >
                <UIcon
                  name="i-heroicons-exclamation-triangle"
                  class="w-4 h-4 shrink-0 mt-0.5"
                />
                <span
                  >এখনো কোনো অডিয়েন্স নেই — আগে কিছু বিজ্ঞাপন/পোস্ট
                  চালান</span
                >
              </div>
            </div>

            <!-- Announcement note (announcement objective) -->
            <p
              v-if="form.ad_objective === 'announcement'"
              class="text-xs text-gray-500 bg-gray-50 border border-gray-100 rounded-md px-3 py-2"
            >
              ঘোষণা সবাইকে সমানভাবে দেখানো হয় — দিনে সর্বোচ্চ ২ বার
            </p>

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
              <div class="grid grid-cols-3 gap-2">
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
                <button
                  type="button"
                  @click="form.format = 'boost'"
                  class="px-3 py-2.5 text-sm border rounded-md"
                  :class="
                    form.format === 'boost'
                      ? 'border-indigo-500 bg-indigo-50 text-indigo-700'
                      : 'border-gray-300 text-gray-700'
                  "
                >
                  🚀 Boost Post
                </button>
              </div>
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

            <!-- Boost post (boost format) -->
            <div v-if="form.format === 'boost'" class="space-y-3">
              <div>
                <label class="block text-sm font-medium text-gray-800 mb-1">
                  Post ID <span class="text-red-500">*</span>
                </label>
                <div class="flex items-center gap-2">
                  <input
                    v-model="boostPostId"
                    type="text"
                    placeholder="যেমন: 1024"
                    class="block w-full px-3 py-2 text-sm border border-gray-300 rounded-md focus:outline-none focus:ring-indigo-600 focus:border-indigo-600"
                  />
                  <button
                    type="button"
                    @click="loadBoostPost"
                    :disabled="!boostPostId || boostLoading"
                    class="shrink-0 px-3 py-2 text-sm font-medium border border-indigo-200 text-indigo-700 hover:bg-indigo-50 disabled:opacity-50 rounded-md transition-colors"
                  >
                    {{ boostLoading ? "লোড হচ্ছে…" : "পোস্ট লোড করুন" }}
                  </button>
                </div>
                <p class="mt-1 text-xs text-gray-500">
                  অ্যাপে পোস্টের ⋯ মেনু থেকে Post ID কপি করুন
                </p>
                <p v-if="boostError" class="mt-1 text-xs text-red-500">
                  পোস্ট পাওয়া যায়নি — ID টি আবার দেখুন
                </p>
              </div>

              <!-- Loaded post preview -->
              <div
                v-if="boostedPost"
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
                  <p class="text-xs text-gray-600 line-clamp-2">
                    {{ boostExcerpt }}
                  </p>
                  <div
                    class="mt-1 inline-flex items-center gap-1 text-xs font-medium text-green-600"
                  >
                    <UIcon name="i-heroicons-check-circle" class="w-4 h-4" />
                    পোস্ট পাওয়া গেছে
                  </div>
                </div>
              </div>

              <p class="text-xs text-gray-500">
                Boost করা পোস্ট Shorts রিলে স্পনসরড হিসেবে দেখানো হবে।
              </p>
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

            <!-- Placements (boosts always run in the shorts reel) -->
            <div v-if="form.format !== 'boost'">
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
              <div class="mt-2 flex justify-end">
                <button
                  type="button"
                  @click="addLocation"
                  :disabled="!selDivision"
                  class="px-3 py-1.5 text-sm font-medium border border-indigo-200 text-indigo-700 hover:bg-indigo-50 disabled:opacity-50 rounded-md transition-colors inline-flex items-center gap-1.5"
                >
                  <UIcon name="i-heroicons-plus" class="w-4 h-4" />
                  লোকেশন যোগ করুন
                </button>
              </div>
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

            <!-- Ad policy agreement (required) -->
            <div class="border border-red-100 bg-red-50/60 rounded-xl p-4">
              <div class="flex items-center gap-2 mb-2">
                <UIcon
                  name="i-heroicons-shield-exclamation"
                  class="w-4.5 h-4.5 text-red-500"
                />
                <span class="text-sm font-semibold text-gray-800"
                  >বিজ্ঞাপন নীতিমালা</span
                >
              </div>
              <p class="text-xs text-gray-600 mb-2">
                নিচের বিষয়গুলোর বিজ্ঞাপন AdsyClub-এ সম্পূর্ণ নিষিদ্ধ — এমন
                বিজ্ঞাপন জমা দিলে তা বাতিল হবে এবং অ্যাকাউন্টে ব্যবস্থা নেওয়া
                হতে পারে:
              </p>
              <ul class="text-xs text-red-600 space-y-1 mb-3 pl-1">
                <li>• জুয়া / বেটিং / ক্যাসিনো</li>
                <li>• প্রাপ্তবয়স্ক (Adult) কনটেন্ট</li>
                <li>• সিগারেট / তামাকজাত পণ্য</li>
                <li>• ভ্যাপ / ই-সিগারেট</li>
                <li>• শিশু নির্যাতন বা শিশুদের জন্য ক্ষতিকর যেকোনো কনটেন্ট</li>
                <li>• আইনবিরুদ্ধ পণ্য বা সেবা</li>
              </ul>
              <label
                class="flex items-start gap-2.5 cursor-pointer select-none"
              >
                <input
                  v-model="policyAgreed"
                  type="checkbox"
                  class="mt-0.5 h-4 w-4 rounded border-gray-300 accent-indigo-600"
                />
                <span class="text-xs text-gray-700 leading-relaxed">
                  আমি নিশ্চিত করছি — আমার বিজ্ঞাপনে উপরের কোনো নিষিদ্ধ বিষয়
                  নেই এবং আমি AdsyClub-এর বিজ্ঞাপন নীতিমালায় সম্মত।
                </span>
              </label>
            </div>

            <!-- Submit -->
            <div class="pt-2 flex items-center gap-3">
              <button
                type="submit"
                :disabled="isSubmitting || !policyAgreed"
                class="px-5 py-2.5 text-sm font-medium bg-indigo-600 hover:bg-indigo-700 disabled:opacity-60 text-white rounded-xl shadow-sm transition-colors"
              >
                {{ isSubmitting ? "Submitting…" : "Submit Ad" }}
              </button>
              <NuxtLink
                to="/business-network/abn-ads"
                class="px-5 py-2.5 text-sm font-medium border border-gray-300 hover:bg-gray-100 text-gray-700 rounded-xl transition-colors"
              >
                Cancel
              </NuxtLink>
            </div>
            <p v-if="errorMsg" class="text-sm text-red-500">{{ errorMsg }}</p>
          </form>
        </div>

        <!-- ── Info / preview column ────────────────────────────── -->
        <div class="w-full lg:w-2/5 space-y-4">
          <!-- Live preview (multi-placement) -->
          <div class="bg-white border border-gray-100 shadow-sm rounded-xl p-4">
            <h3 class="text-sm font-medium text-gray-800 mb-3 flex items-center">
              <UIcon
                name="i-heroicons-eye"
                class="w-4 h-4 mr-2 text-indigo-600"
              />
              Ad Preview
            </h3>

            <!-- Placement pills -->
            <div class="flex flex-wrap gap-1.5 mb-3">
              <button
                v-for="tab in previewTabs"
                :key="tab.value"
                type="button"
                @click="previewTab = tab.value"
                class="px-2.5 py-1 text-xs font-medium rounded-full border transition-colors"
                :class="
                  previewTab === tab.value
                    ? 'border-indigo-500 bg-indigo-50 text-indigo-700'
                    : 'border-gray-200 text-gray-600 hover:border-gray-300'
                "
              >
                {{ tab.label }}
              </button>
            </div>

            <!-- ফিড কার্ড -->
            <div
              v-if="previewTab === 'feed'"
              class="border border-gray-200 rounded-md overflow-hidden"
            >
              <img
                v-if="previewImage"
                :src="previewImage"
                class="w-full h-36 object-cover"
              />
              <div
                v-else
                class="w-full h-36 bg-gray-100 flex items-center justify-center text-gray-400"
              >
                <UIcon name="i-heroicons-photo" class="w-8 h-8" />
              </div>
              <div class="p-3">
                <div class="text-[10px] uppercase tracking-wide text-gray-400">
                  Sponsored
                </div>
                <div class="text-sm font-semibold text-gray-800 mt-0.5">
                  {{ previewTitle }}
                </div>
                <p class="text-xs text-gray-600 mt-1 line-clamp-2">
                  {{ previewDesc }}
                </p>
                <span
                  class="mt-2 inline-block px-3 py-1 text-xs font-medium bg-gray-900/5 text-gray-900 rounded-md"
                >
                  ভিজিট করুন
                </span>
              </div>
            </div>

            <!-- কমপ্যাক্ট -->
            <div
              v-else-if="previewTab === 'compact'"
              class="flex items-center gap-2.5 p-2 bg-slate-50 rounded-xl"
            >
              <img
                v-if="previewImage"
                :src="previewImage"
                class="w-10 h-10 rounded-md object-cover shrink-0"
              />
              <div
                v-else
                class="w-10 h-10 rounded-md bg-gray-200 flex items-center justify-center text-gray-400 shrink-0"
              >
                <UIcon name="i-heroicons-photo" class="w-4 h-4" />
              </div>
              <div class="min-w-0 flex-1">
                <div class="text-sm font-medium text-gray-800 truncate">
                  {{ previewTitle }}
                </div>
                <div class="text-[10px] uppercase tracking-wide text-gray-400">
                  Sponsored
                </div>
              </div>
              <UIcon
                name="i-heroicons-chevron-right"
                class="w-4 h-4 text-gray-400 shrink-0"
              />
            </div>

            <!-- Shorts ব্যানার -->
            <div
              v-else-if="previewTab === 'shorts'"
              class="relative bg-gray-900 rounded-xl overflow-hidden mx-auto"
              style="aspect-ratio: 9 / 14; max-height: 260px"
            >
              <div
                class="absolute inset-0 flex items-center justify-center text-gray-600"
              >
                <UIcon name="i-heroicons-play-circle" class="w-10 h-10" />
              </div>
              <div
                class="absolute bottom-3 left-2 right-2 flex items-center gap-2 bg-white rounded-lg p-1.5 shadow"
              >
                <img
                  v-if="previewImage"
                  :src="previewImage"
                  class="w-8 h-8 rounded-md object-cover shrink-0"
                />
                <div
                  v-else
                  class="w-8 h-8 rounded-md bg-gray-200 flex items-center justify-center text-gray-400 shrink-0"
                >
                  <UIcon name="i-heroicons-photo" class="w-4 h-4" />
                </div>
                <div class="min-w-0">
                  <div class="text-xs font-medium text-gray-800 truncate">
                    {{ previewTitle }}
                  </div>
                  <div class="text-[9px] uppercase tracking-wide text-gray-400">
                    Sponsored
                  </div>
                </div>
              </div>
            </div>

            <!-- রিল -->
            <div
              v-else
              class="relative bg-gray-900 rounded-xl overflow-hidden mx-auto"
              style="aspect-ratio: 9 / 16; max-height: 260px"
            >
              <img
                v-if="previewImage"
                :src="previewImage"
                class="absolute inset-0 w-full h-full object-cover opacity-70"
              />
              <div
                v-else
                class="absolute inset-0 flex items-center justify-center text-gray-600"
              >
                <UIcon name="i-heroicons-play-circle" class="w-10 h-10" />
              </div>
              <div
                class="absolute inset-x-0 bottom-0 p-2.5 bg-gradient-to-t from-black/70 to-transparent"
              >
                <div class="flex items-center gap-2">
                  <div
                    class="w-7 h-7 rounded-full bg-white/20 backdrop-blur flex items-center justify-center text-white text-[10px] font-semibold shrink-0"
                  >
                    {{ (previewAuthor || "A").charAt(0).toUpperCase() }}
                  </div>
                  <div class="min-w-0">
                    <div class="text-xs font-medium text-white truncate">
                      {{ previewAuthor || previewTitle }}
                    </div>
                    <div
                      class="text-[9px] uppercase tracking-wide text-white/60"
                    >
                      Sponsored
                    </div>
                  </div>
                </div>
                <span
                  class="mt-2 inline-block px-3 py-1 text-xs font-medium bg-white/25 backdrop-blur text-white rounded-md"
                >
                  ভিজিট করুন
                </span>
              </div>
            </div>
          </div>

          <!-- Where the ad shows -->
          <div class="bg-white border border-gray-100 shadow-sm rounded-xl p-4">
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
          <div class="bg-white border border-gray-100 shadow-sm rounded-xl p-4">
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
  ad_objective: "engagement",
  target_segments: [],
  retarget_sources: ["ad_engagers"],
  retarget_days: 30,
});

// ── Campaign objective ──
const objectiveOptions = [
  {
    value: "engagement",
    emoji: "🔥",
    title: "এনগেজমেন্ট",
    desc: "লাইক, কমেন্ট, ফলো বাড়ান — আগ্রহী ইউজারদের কাছে পৌঁছান",
  },
  {
    value: "retargeting",
    emoji: "🔁",
    title: "রিটার্গেটিং",
    desc: "যারা আগে আগ্রহ দেখিয়েছে তাদের আবার দেখান (প্রিমিয়াম ৳0.50/ভিউ)",
  },
  {
    value: "announcement",
    emoji: "📢",
    title: "ঘোষণা",
    desc: "সবার কাছে একবার করে পৌঁছান — সবচেয়ে সস্তা ৳0.20/ভিউ",
  },
];

// Interest-Brain segments — keys mirror the backend's segment keys.
const segmentOptions = [
  { value: "fashion", label: "ফ্যাশন" },
  { value: "beauty", label: "বিউটি" },
  { value: "food", label: "খাবার" },
  { value: "tech", label: "টেক/গ্যাজেট" },
  { value: "business", label: "ব্যবসা" },
  { value: "jobs_education", label: "চাকরি/শিক্ষা" },
  { value: "entertainment", label: "বিনোদন" },
  { value: "sports", label: "খেলাধুলা" },
  { value: "health", label: "স্বাস্থ্য" },
  { value: "travel", label: "ভ্রমণ" },
  { value: "religion", label: "ধর্মীয়" },
  { value: "agriculture", label: "কৃষি" },
  { value: "vehicles_property", label: "গাড়ি/প্রপার্টি" },
  { value: "finance", label: "ফাইন্যান্স" },
];

function toggleSegment(value) {
  const i = form.target_segments.indexOf(value);
  if (i >= 0) form.target_segments.splice(i, 1);
  else form.target_segments.push(value);
}

// ── Retargeting audience ──
const retargetSourceOptions = [
  { value: "ad_engagers", label: "আমার আগের বিজ্ঞাপনে ক্লিক/ভিউ করেছেন" },
  { value: "followers", label: "আমার ফলোয়াররা" },
  { value: "post_engagers", label: "আমার পোস্টে লাইক/কমেন্ট করেছেন" },
  { value: "post_viewers", label: "আমার পোস্ট দেখেছেন" },
];

function toggleRetargetSource(value) {
  const i = form.retarget_sources.indexOf(value);
  if (i >= 0) form.retarget_sources.splice(i, 1);
  else form.retarget_sources.push(value);
}

// Live audience-size estimate (debounced while sources/days change).
const audienceSize = ref(null);
const audienceLoading = ref(false);
let audienceDebounce = null;

async function fetchAudienceSize() {
  if (!form.retarget_sources.length) {
    audienceSize.value = 0;
    audienceLoading.value = false;
    return;
  }
  audienceLoading.value = true;
  try {
    const res = await get(
      `/bn/ads/audience-size/?sources=${form.retarget_sources.join(",")}&days=${
        form.retarget_days
      }`
    );
    audienceSize.value =
      res.data && !res.error ? Number(res.data.size) || 0 : null;
  } catch (e) {
    audienceSize.value = null;
  } finally {
    audienceLoading.value = false;
  }
}

watch(
  [
    () => form.ad_objective,
    () => [...form.retarget_sources],
    () => form.retarget_days,
  ],
  () => {
    if (form.ad_objective !== "retargeting") return;
    clearTimeout(audienceDebounce);
    audienceDebounce = setTimeout(fetchAudienceSize, 400);
  },
  { immediate: true }
);

// Video-format uploads
const videoMediaId = ref(null);
const videoUploading = ref(false);
const companionBanner = ref(""); // base64 data URL

// Required ad-policy consent (gambling/adult/tobacco/vape/child-harm ban).
const policyAgreed = ref(false);

// ── Boost post (boost format) ──
const route = useRoute();
const boostPostId = ref("");
const boostedPost = ref(null);
const boostLoading = ref(false);
const boostError = ref(false);

async function loadBoostPost() {
  if (!boostPostId.value) return;
  boostLoading.value = true;
  boostError.value = false;
  boostedPost.value = null;
  try {
    const res = await get(`/bn/posts/${boostPostId.value}/`);
    if (res.data && !res.error) {
      boostedPost.value = res.data;
    } else {
      boostError.value = true;
    }
  } catch (e) {
    boostError.value = true;
  } finally {
    boostLoading.value = false;
  }
}

// Defensive field extraction — post payload shape varies slightly.
const boostThumb = computed(() => {
  const p = boostedPost.value;
  if (!p) return "";
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
  const p = boostedPost.value;
  if (!p) return "";
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
  const p = boostedPost.value;
  if (!p) return "";
  const text = p.title || p.content || p.post_content || "";
  return String(text).replace(/<[^>]*>/g, "");
});

// Prefill from ?post=<id> (e.g. shared from the app's ⋯ menu).
onMounted(() => {
  const q = route.query.post;
  if (q) {
    form.format = "boost";
    boostPostId.value = String(q);
    loadBoostPost();
  }
});

// ── Multi-placement preview tabs ──
const previewTabs = [
  { value: "feed", label: "ফিড কার্ড" },
  { value: "compact", label: "কমপ্যাক্ট" },
  { value: "shorts", label: "Shorts ব্যানার" },
  { value: "reel", label: "রিল" },
];
const previewTab = ref("feed");
const previewImage = computed(() => {
  if (form.format === "boost") return boostThumb.value;
  return form.images.length ? form.images[0] : "";
});
const previewTitle = computed(() => {
  if (form.format === "boost" && boostedPost.value) {
    return boostExcerpt.value || "Boosted পোস্ট";
  }
  return form.title || "আপনার বিজ্ঞাপনের টাইটেল";
});
const previewDesc = computed(() => {
  if (form.format === "boost" && boostedPost.value) {
    return boostExcerpt.value;
  }
  return form.description || "বিজ্ঞাপনের বর্ণনা এখানে দেখা যাবে…";
});
const previewAuthor = computed(() =>
  form.format === "boost" ? boostAuthorName.value : ""
);

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

// Category is auto-assigned server-side (the Interest Brain classifies the
// ad content itself) — no user-facing category picker.
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
  if (!policyAgreed.value) {
    errorMsg.value = "বিজ্ঞাপন জমা দিতে নীতিমালায় সম্মতি দিন।";
    return;
  }
  if (!form.male && !form.female && !form.other) {
    errorMsg.value = "কমপক্ষে একটি audience নির্বাচন করুন।";
    return;
  }
  if (form.format === "video" && !videoMediaId.value) {
    errorMsg.value = "Video ad-এর জন্য আগে ভিডিও আপলোড করুন।";
    return;
  }
  if (form.format === "boost" && !boostedPost.value) {
    errorMsg.value = "Boost করার আগে Post ID দিয়ে পোস্টটি লোড করুন।";
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
      ad_objective: form.ad_objective,
      target_segments:
        form.ad_objective === "engagement" ? [...form.target_segments] : [],
      retarget_sources:
        form.ad_objective === "retargeting" ? [...form.retarget_sources] : [],
      retarget_days: form.retarget_days,
      policy_agreed: true,
    };
    if (form.format === "video") {
      payload.media_ids = [videoMediaId.value];
      if (companionBanner.value) {
        payload.companion_banner_b64 = companionBanner.value;
      }
      payload.images = []; // video creative — no base64 images
    }
    if (form.format === "boost") {
      payload.boosted_post = boostPostId.value;
      payload.images = []; // creative comes from the boosted post itself
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
