<template>
  <div
    class="py-3 backdrop-blur-sm max-sm:bg-slate-200/70 bg-white shadow-sm rounded-b-lg transition-all duration-500 z-[99999999] w-full"
    :class="[
      isScrolled
        ? 'fixed top-0 left-0 right-0 backdrop-blur-sm max-sm:bg-slate-200/70 bg-white shadow-sm rounded-b-lg border-gray-200/50 dark:border-gray-800/50'
        : 'sticky top-0 w-full shadow-sm',
      'sm:py-3 py-1.5', // Smaller padding on mobile
      // Hide on mobile when scrolling down
      isScrollingDown ? 'md:translate-y-0 -translate-y-full' : 'translate-y-0'
    ]"
    style="
      padding-top: max(0.75rem, env(safe-area-inset-top));
      padding-top: max(12px, env(safe-area-inset-top));
    "
  >
    <!-- Mobile App Download Banner -->
    <transition
      enter-active-class="transition duration-300 ease-out"
      enter-from-class="opacity-0 -translate-y-2"
      leave-active-class="transition duration-200 ease-in"
      leave-to-class="opacity-0 -translate-y-2"
    >
      <div v-if="showDownloadBanner" class="sm:hidden px-3 pb-2">
        <div class="relative rounded-xl bg-gradient-to-r from-emerald-600 via-emerald-500 to-teal-500 p-[1px] shadow-lg shadow-emerald-500/20">
          <!-- Inner content with subtle pattern -->
          <div class="relative flex items-center gap-2 rounded-[11px] bg-gradient-to-r from-emerald-600 via-emerald-500 to-teal-500 px-3 py-2.5 pr-8">
            <!-- Decorative circles -->
            <div class="absolute -left-6 -top-6 w-16 h-16 bg-white/10 rounded-full blur-xl"></div>
            <div class="absolute -right-4 -bottom-4 w-12 h-12 bg-white/10 rounded-full blur-lg"></div>
            
            <!-- App Icon -->
            <div class="relative shrink-0 w-10 h-10 rounded-xl bg-white/20 backdrop-blur-sm flex items-center justify-center shadow-inner">
              <NuxtImg 
                src="/favicon.png" 
                alt="Adsy App" 
                class="w-7 h-7 rounded-lg"
                loading="lazy"
              />
            </div>
            
            <!-- Text Content -->
            <div class="flex-1 min-w-0">
              <div class="flex items-center gap-1.5">
                <span class="text-[13px] font-bold text-white">Adsy App</span>
                <span class="px-1.5 py-0.5 text-[9px] font-bold bg-white/20 text-white rounded-full uppercase tracking-wide">Free</span>
              </div>
              <div class="text-[11px] text-emerald-100 mt-0.5">
                Get the best experience on mobile
              </div>
            </div>
            
            <!-- Download Button -->
            <button
              @click="downloadAndroidApp"
              class="shrink-0 flex items-center gap-1.5 text-[12px] font-bold px-4 py-2 rounded-lg bg-white text-emerald-600 hover:bg-emerald-50 active:scale-95 transition-all shadow-md"
            >
              <UIcon name="i-heroicons-arrow-down-tray" class="w-4 h-4" />
              <span>GET</span>
            </button>
            
            <!-- Close Button -->
            <button
              @click="dismissDownloadBanner"
              class="absolute flex top-1/2 -translate-y-1/2 right-1.5 p-1.5 rounded-full bg-white/20 hover:bg-white/30 text-white transition"
              aria-label="Close"
            >
              <UIcon name="i-heroicons-x-mark" class="w-4 h-4" />
            </button>
          </div>
        </div>
      </div>
    </transition>

    <!-- Subscription Warnings Section -->
    <div class="relative px-4">
      <!-- Pre-expiration Warning -->
      <transition
        enter-active-class="transition duration-300 ease-out"
        enter-from-class="opacity-0 -translate-y-4"
        leave-active-class="transition duration-200 ease-in"
        leave-to-class="opacity-0 -translate-y-4"
      >
        <div
          v-if="shouldShowWarning && !warningDismissed"
          class="mx-auto my-2 px-4 relative overflow-hidden rounded-lg border border-amber-300/70 dark:border-amber-600/50 group transition-all duration-300 hover:shadow-sm"
        >
          <!-- Warning Background -->
          <div
            class="absolute inset-0 bg-gradient-to-r from-amber-50/90 via-amber-50/80 to-amber-100/90 dark:from-amber-900/30 dark:via-amber-800/20 dark:to-amber-900/30 backdrop-blur-md"
          ></div>

          <!-- Decorative Elements -->
          <div
            class="absolute -left-20 -top-20 w-40 h-40 bg-amber-200/20 rounded-full blur-2xl transform-gpu"
          ></div>
          <div
            class="absolute -right-20 -bottom-20 w-40 h-40 bg-amber-300/20 rounded-full blur-2xl transform-gpu"
          ></div>

          <!-- Animated Border Lines -->
          <div
            class="absolute left-0 top-0 h-px w-full bg-gradient-to-r from-transparent via-amber-400/50 dark:via-amber-400/30 to-transparent opacity-70 animate-[shimmer_3s_linear_infinite]"
          ></div>
          <div
            class="absolute left-0 bottom-0 h-px w-full bg-gradient-to-r from-transparent via-amber-400/50 dark:via-amber-400/30 to-transparent opacity-70 animate-[shimmer_3s_linear_infinite]"
          ></div>

          <!-- Content -->
          <div
            class="relative z-10 p-2.5 sm:p-3.5 flex items-center justify-between"
          >
            <div class="flex items-center gap-2 sm:gap-3">
              <!-- Warning Icon -->
              <div class="relative hidden xs:block">
                <div
                  class="w-10 h-10 rounded-full bg-gradient-to-br from-amber-100 to-amber-200 dark:from-amber-800 dark:to-amber-700 border border-amber-300/50 dark:border-amber-600/30 flex items-center justify-center shadow-inner"
                >
                  <UIcon
                    name="i-heroicons-clock"
                    class="w-5 h-5 text-amber-600 dark:text-amber-400"
                  />
                </div>
                <div
                  class="absolute -inset-1.5 bg-amber-300/20 blur-md rounded-full animate-pulse opacity-50"
                ></div>
              </div>

              <!-- Warning Text -->
              <div class="inline-flex items-center gap-2">
                <UIcon
                  name="i-icon-park-outline-caution"
                  class="w-5 h-5 text-amber-800"
                />
                <h3 class="text-xs sm:text-sm font-medium text-amber-800">
                  {{ $t("subscription_expiring") }}
                  <span class="inline-block ml-1 font-semibold">
                    {{ daysRemaining }}
                    {{ daysRemaining === 1 ? $t("day") : $t("days") }}
                  </span>
                </h3>
              </div>
            </div>

            <!-- Dismiss Button -->
            <UButton
              @click="dismissWarning"
              size="2xs"
              variant="ghost"
              color="gray"
              icon="i-heroicons-x-mark"
              class="p-1 hover:rotate-90 transition-transform"
              aria-label="Dismiss"
            />
          </div>
        </div>
      </transition>

      <!-- Post-expiration Alert -->
      <transition
        enter-active-class="transition duration-300 ease-out"
        enter-from-class="opacity-0 -translate-y-4"
        leave-active-class="transition duration-200 ease-in"
        leave-to-class="opacity-0 -translate-y-4"
      >
        <div
          v-if="isExpired && !expiredWarningDismissed"
          class="mx-auto my-2 px-3 py-2 relative overflow-hidden rounded-lg border border-red-300 dark:border-red-700 bg-red-50 dark:bg-red-900/20"
        >
          <!-- Content -->
          <div class="flex items-center justify-between gap-3">
            <div class="flex items-center gap-2 flex-1 min-w-0">
              <!-- Alert Icon -->
              <UIcon
                name="i-heroicons-exclamation-triangle"
                class="w-4 h-4 text-red-600 dark:text-red-400 flex-shrink-0"
              />

              <!-- Alert Text -->
              <p class="text-xs font-medium text-red-800 dark:text-red-300 truncate">
                {{ $t("subscription_expired") }}
              </p>
            </div>

            <!-- Action Buttons -->
            <div class="flex items-center gap-2 flex-shrink-0">
              <UButton
                @click="renewSubscription"
                size="2xs"
                color="red"
                variant="solid"
                class="text-xs font-medium"
              >
                {{ $t("renew_now") }}
              </UButton>
              <UButton
                @click="dismissExpiredWarning"
                size="2xs"
                variant="ghost"
                color="gray"
                icon="i-heroicons-x-mark"
                class="p-1"
                aria-label="No Thanks"
              />
            </div>
          </div>
        </div>
      </transition>
    </div>

    <UContainer class="w-full max-w-7xl mx-auto">
      <!-- Mobile Sidebar Menu -->
      <USlideover
        v-model="isOpen"
        side="left"
        :ui="{
          width: 'w-screen max-w-[300px]',
          height: 'max-h-screen',
        }"
        class="bg-gradient-to-br from-gray-50 to-gray-100 dark:from-gray-900 dark:to-gray-800 shadow-sm"
      >
        <UCard
          :ui="{
            header: { padding: 'pb-0.5' },
            ring: '',
            rounded: '',
            shadow: '',
            body: { padding: '' },
          }"
          class="bg-white dark:bg-gray-900 border border-gray-200 dark:border-gray-700 mt-4 overflow-y-scroll scrollbar-hide sm:scrollbar-default"
        >
          <!-- Close Button -->
          <div class="w-full flex justify-end pt-12 px-4">
            <UButton
              color="gray"
              variant="ghost"
              icon="i-heroicons-x-mark-20-solid"
              class="text-gray-600 hover:text-gray-800 dark:text-gray-600 dark:hover:text-gray-300 transition-transform transform hover:scale-110"
              @click="isOpen = false"
            />
          </div>

          <!-- Language Switcher in Sidebar -->
          <div class="px-4">
            <PublicTranslateHandler class="px-2 mt-3" :showText="true" />
          </div>

          <!-- Navigation Links -->
          <div class="px-4 py-6">
            <h3
              class="text-lg font-medium text-gray-800 dark:text-gray-300 mb-2 px-4"
            >
              {{ $t("menu") }}
            </h3>

            <!-- Mobile Navigation Menu -->
            <div
              class="rounded-xl overflow-hidden bg-gray-50 dark:bg-gray-800 space-y-1 py-2"
            >
              <!-- Home -->
              <NuxtLink
                to="/"
                class="flex items-center py-3 px-4 gap-3 transition-colors hover:bg-gray-100 dark:hover:bg-gray-700"
                @click="isOpen = false"
              >
                <div
                  class="flex items-center justify-center w-8 h-8 rounded-full bg-blue-100 text-blue-600 dark:bg-blue-900/30 dark:text-blue-400"
                >
                  <UIcon name="i-heroicons-home-20-solid" class="w-5 h-5" />
                </div>
                <span
                  class="flex-1 font-medium text-sm text-blue-700 dark:text-blue-300"
                  >{{ $t("home") }}</span
                >
                <UIcon
                  name="i-heroicons-chevron-right"
                  class="w-4 h-4 text-blue-500 dark:text-blue-400 opacity-50 transition-transform group-hover:translate-x-1 group-hover:opacity-100"
                />
              </NuxtLink>

              <!-- Classified Service -->
              <NuxtLink
                to="#classified-services"
                class="flex items-center py-3 px-4 gap-3 transition-colors hover:bg-gray-100 dark:hover:bg-gray-700"
                @click="isOpen = false"
              >
                <div
                  class="flex items-center justify-center w-8 h-8 rounded-full bg-emerald-100 text-emerald-600 dark:bg-emerald-900/30 dark:text-emerald-400"
                >
                  <UIcon
                    name="i-heroicons-clipboard-document-list"
                    class="w-5 h-5"
                  />
                </div>
                <span
                  class="flex-1 font-medium text-sm text-emerald-700 dark:text-emerald-300"
                  >{{ $t("classified_service") }}</span
                >
                <UIcon
                  name="i-heroicons-chevron-right"
                  class="w-4 h-4 text-emerald-500 dark:text-emerald-400 opacity-50 transition-transform group-hover:translate-x-1 group-hover:opacity-100"
                />
              </NuxtLink>

              <!-- E-Learning -->
              <NuxtLink
                to="/courses"
                class="flex items-center py-3 px-4 gap-3 transition-colors hover:bg-gray-100 dark:hover:bg-gray-700"
                @click="isOpen = false"
              >
                <div
                  class="flex items-center justify-center w-8 h-8 rounded-full bg-purple-100 text-purple-600 dark:bg-purple-900/30 dark:text-purple-400"
                >
                  <UIcon name="i-heroicons-academic-cap" class="w-5 h-5" />
                </div>
                <span
                  class="flex-1 font-medium text-sm text-purple-700 dark:text-purple-300"
                  >{{ $t("elearning") }}</span
                >
                <UIcon
                  name="i-heroicons-chevron-right"
                  class="w-4 h-4 text-purple-500 dark:text-purple-400 opacity-50 transition-transform group-hover:translate-x-1 group-hover:opacity-100"
                />
              </NuxtLink>

              <!-- Earn Money -->
              <NuxtLink
                to="#micro-gigs"
                class="flex items-center py-3 px-4 gap-3 transition-colors hover:bg-gray-100 dark:hover:bg-gray-700"
                @click="isOpen = false"
              >
                <div
                  class="flex items-center justify-center w-8 h-8 rounded-full bg-amber-100 text-amber-600 dark:bg-amber-900/30 dark:text-amber-400"
                >
                  <UIcon
                    name="i-healthicons:money-bag-outline"
                    class="w-5 h-5"
                  />
                </div>
                <span
                  class="flex-1 font-medium text-sm text-amber-700 dark:text-amber-300"
                  >{{ $t("earn_money") }}</span
                >
                <UIcon
                  name="i-heroicons-chevron-right"
                  class="w-4 h-4 text-amber-500 dark:text-amber-400 opacity-50 transition-transform group-hover:translate-x-1 group-hover:opacity-100"
                />
              </NuxtLink>

              <!-- FAQ -->
              <NuxtLink
                to="/faq/"
                class="flex items-center py-3 px-4 gap-3 transition-colors hover:bg-gray-100 dark:hover:bg-gray-700"
                @click="isOpen = false"
              >
                <div
                  class="flex items-center justify-center w-8 h-8 rounded-full bg-red-100 text-red-600 dark:bg-red-900/30 dark:text-red-400"
                >
                  <UIcon
                    name="i-streamline:interface-help-question-circle-circle-faq-frame-help-info-mark-more-query-question"
                    class="w-5 h-5"
                  />
                </div>
                <span
                  class="flex-1 font-medium text-sm text-red-700 dark:text-red-300"
                  >{{ $t("faq") }}</span
                >
                <UIcon
                  name="i-heroicons-chevron-right"
                  class="w-4 h-4 text-red-500 dark:text-red-400 opacity-50 transition-transform group-hover:translate-x-1 group-hover:opacity-100"
                />
              </NuxtLink>

              <!-- Business Network -->
              <NuxtLink
                to="/business-network"
                class="flex items-center py-3 px-4 gap-3 transition-colors hover:bg-gray-100 dark:hover:bg-gray-700"
                @click="isOpen = false"
              >
                <div
                  class="flex items-center justify-center w-8 h-8 rounded-full bg-teal-100 text-teal-600 dark:bg-teal-900/30 dark:text-teal-400"
                >
                  <UIcon name="i-lucide-globe" class="w-5 h-5" />
                </div>
                <span
                  class="flex-1 font-medium text-sm text-teal-700 dark:text-teal-300"
                  >{{ $t("business_network") }}</span
                >
                <UIcon
                  name="i-heroicons-chevron-right"
                  class="w-4 h-4 text-teal-500 dark:text-teal-400 opacity-50 transition-transform group-hover:translate-x-1 group-hover:opacity-100"
                />
              </NuxtLink>

              <NuxtLink
                to="/food-zone"
                class="flex items-center py-3 px-4 gap-3 transition-colors hover:bg-gray-100 dark:hover:bg-gray-700"
                @click="isOpen = false"
              >
                <div
                  class="flex items-center justify-center w-8 h-8 rounded-full bg-pink-100 text-pink-600 dark:bg-pink-900/30 dark:text-pink-400"
                >
                  <UIcon name="i-heroicons-rectangle-stack" class="w-5 h-5" />
                </div>
                <span
                  class="flex-1 font-medium text-sm text-pink-700 dark:text-pink-300"
                  >Food Zone</span
                >
                <UIcon
                  name="i-heroicons-chevron-right"
                  class="w-4 h-4 text-pink-500 dark:text-pink-400 opacity-50 transition-transform group-hover:translate-x-1 group-hover:opacity-100"
                />
              </NuxtLink>

              <!-- News -->
              <NuxtLink
                to="/adsy-news"
                class="flex items-center py-3 px-4 gap-3 transition-colors hover:bg-gray-100 dark:hover:bg-gray-700"
                @click="isOpen = false"
              >
                <div
                  class="flex items-center justify-center w-8 h-8 rounded-full bg-orange-100 text-orange-600 dark:bg-orange-900/30 dark:text-orange-400"
                >
                  <UIcon name="i-lucide-newspaper" class="w-5 h-5" />
                </div>
                <span
                  class="flex-1 font-medium text-sm text-orange-700 dark:text-orange-300"
                  >{{ $t("adsy_news") }}</span
                >
                <UIcon
                  name="i-heroicons-chevron-right"
                  class="w-4 h-4 text-orange-500 dark:text-orange-400 opacity-50 transition-transform group-hover:translate-x-1 group-hover:opacity-100"
                />
              </NuxtLink>

              <!-- Referral Program -->
              <NuxtLink
                to="/refer-a-friend"
                class="flex items-center py-3 px-4 gap-3 transition-colors hover:bg-gray-100 dark:hover:bg-gray-700"
                @click="isOpen = false"
              >
                <div
                  class="flex items-center justify-center w-8 h-8 rounded-full bg-pink-100 text-pink-600 dark:bg-pink-900/30 dark:text-pink-400"
                >
                  <UIcon name="i-heroicons-user-plus" class="w-5 h-5" />
                </div>
                <span
                  class="flex-1 font-medium text-sm text-pink-700 dark:text-pink-300"
                  >{{ $t("refer_program") }}</span
                >
                <UIcon
                  name="i-heroicons-chevron-right"
                  class="w-4 h-4 text-pink-500 dark:text-pink-400 opacity-50 transition-transform group-hover:translate-x-1 group-hover:opacity-100"
                />
              </NuxtLink>

              <!-- Mobile Recharge -->
              <NuxtLink
                to="/mobile-recharge"
                class="flex items-center py-3 px-4 gap-3 transition-colors hover:bg-gray-100 dark:hover:bg-gray-700"
                @click="isOpen = false"
              >
                <div
                  class="flex items-center justify-center w-8 h-8 rounded-full bg-indigo-100 text-indigo-600 dark:bg-indigo-900/30 dark:text-indigo-400"
                >
                  <UIcon name="i-ic-baseline-install-mobile" class="w-5 h-5" />
                </div>
                <span
                  class="flex-1 font-medium text-sm text-indigo-700 dark:text-indigo-300"
                  >মোবাইল রিচার্জ</span
                >
                <UIcon
                  name="i-heroicons-chevron-right"
                  class="w-4 h-4 text-indigo-500 dark:text-indigo-400 opacity-50 transition-transform group-hover:translate-x-1 group-hover:opacity-100"
                />
              </NuxtLink>
            </div>
          </div>
          <!-- Download App Section -->
          <div class="px-4 py-6 border-t border-gray-200 dark:border-gray-700">
            <h3
              class="text-lg font-medium text-gray-800 dark:text-gray-300 mb-4"
            >
              {{ $t("download_our_app") }}
            </h3>
            <div class="flex items-center gap-4">
              <button
                @click="downloadAndroidApp"
                class="w-32 h-10 bg-green-100 dark:bg-green-800 rounded-lg shadow-sm flex items-center justify-center hover:bg-green-200 dark:hover:bg-green-700 transition overflow-hidden relative group"
              >
                <img
                  src="/static/frontend/images/google.png"
                  alt="Google Play"
                  class="w-full h-full object-contain"
                />
                <div
                  class="absolute inset-0 bg-green-500/10 opacity-0 group-hover:opacity-100 flex items-center justify-center transition-opacity"
                >
                  <UIcon
                    name="i-heroicons-arrow-down-tray"
                    class="w-5 h-5 text-green-600 dark:text-green-300"
                  />
                </div>
              </button>
              <div
                class="w-32 h-10 bg-gray-100 dark:bg-gray-800 rounded-lg shadow-sm flex items-center justify-center relative opacity-60 overflow-hidden"
              >
                <img
                  src="/static/frontend/images/apple.png"
                  alt="App Store"
                  class="w-full h-full object-contain"
                />
                <div
                  class="absolute inset-0 bg-gray-500/20 flex items-center justify-center"
                >
                  <div
                    class="bg-gray-600 text-white text-xs py-0.5 px-2 rounded-full"
                  >
                    Coming Soon
                  </div>
                </div>
              </div>
            </div>
          </div>

          <!-- Social Media Section -->
          <div class="px-4 py-6 border-t border-gray-200 dark:border-gray-700">
            <h3
              class="text-lg font-medium text-gray-800 dark:text-gray-300 mb-4"
            >
              {{ $t("follow_us") }}
            </h3>
            <div class="flex items-center gap-4">
              <a
                href="https://www.facebook.com/profile.php?id=61573940373294"
                target="_blank"
                class="w-10 h-10 rounded-full bg-blue-500 text-white flex items-center justify-center hover:bg-blue-600 transition"
                aria-label="Facebook"
              >
                <UIcon name="i-logos-facebook" class="w-5 h-5" />
              </a>
            </div>
          </div>
        </UCard>
      </USlideover>

      <div class="flex items-center justify-between gap-2 lg:gap-6 pr-3">
        <!-- Mobile Layout: Menu Button and Logo -->
        <div class="flex items-center gap-1">
          <!-- Mobile Menu Button -->
          <div class="md:hidden">
            <UButton
              @click="isOpen = true"
              icon="i-heroicons-bars-4"
              variant="ghost"
              color="gray"
              class="hover:bg-gray-100 rounded-lg transition-all duration-200"
              size="lg"
            />
          </div>

          <!-- Logo -->
          <PublicLogo />
        </div>

        <!-- Desktop Navigation Menu -->
        <nav class="hidden md:block sm:text-xs lg:text-base">
          <div class="flex items-center gap-1 border-b border-transparent">
            <NuxtLink
              to="/#home"
              class="relative flex items-center gap-2 py-1 px-2 font-medium text-blue-600 hover:text-blue-800 transition-all duration-300"
              :class="{ active: $route.path === '/' }"
            >
              <UIcon
                name="i-heroicons-home-20-solid"
                class="w-5 h-5 transition-transform duration-200 hover:scale-110"
              />
              <span>{{ $t("home") }}</span>
              <div
                class="absolute bottom-0 left-0 w-full h-0.5 bg-blue-500 transform scale-x-0 origin-left transition-transform duration-300 group-hover:scale-x-100"
                :class="{ 'scale-x-100': $route.path === '/' }"
              ></div>
            </NuxtLink>

            <NuxtLink
              to="/business-network"
              class="relative flex items-center gap-2 py-1 px-2 font-medium text-emerald-600 hover:text-emerald-800 transition-all duration-300"
              :class="{ active: $route.path === '/business-network' }"
            >
              <UIcon
                name="i-lucide-globe"
                class="w-5 h-5 transition-transform duration-200 hover:scale-110"
              />
              <span>{{ $t("business_network") }}</span>
              <div
                class="absolute bottom-0 left-0 w-full h-0.5 bg-emerald-500 transform scale-x-0 origin-left transition-transform duration-300 group-hover:scale-x-100"
                :class="{ 'scale-x-100': $route.path === '/business-network' }"
              ></div>
            </NuxtLink>

            <NuxtLink
              to="/food-zone"
              class="relative flex items-center gap-2 py-1 px-2 font-medium text-pink-600 hover:text-pink-800 transition-all duration-300"
              :class="{ active: $route.path === '/food-zone' }"
            >
              <UIcon
                name="i-heroicons-rectangle-stack"
                class="w-5 h-5 transition-transform duration-200 hover:scale-110"
              />
              <span>Food Zone</span>
              <div
                class="absolute bottom-0 left-0 w-full h-0.5 bg-pink-500 transform scale-x-0 origin-left transition-transform duration-300 group-hover:scale-x-100"
                :class="{ 'scale-x-100': $route.path === '/food-zone' }"
              ></div>
            </NuxtLink>

            <NuxtLink
              to="/adsy-news"
              class="relative flex items-center gap-2 py-1 px-2 font-medium text-amber-600 hover:text-amber-800 transition-all duration-300"
              :class="{ active: $route.path === '/adsy-news' }"
            >
              <UIcon
                name="i-lucide-newspaper"
                class="w-5 h-5 transition-transform duration-200 hover:scale-110"
              />
              <span>{{ $t("adsy_news") }}</span>
              <div
                class="absolute bottom-0 left-0 w-full h-0.5 bg-amber-500 transform scale-x-0 origin-left transition-transform duration-300 group-hover:scale-x-100"
                :class="{ 'scale-x-100': $route.path === '/adsy-news' }"
              ></div>
            </NuxtLink>

            <NuxtLink
              to="/courses"
              class="relative flex items-center gap-2 py-1 px-2 font-medium text-purple-600 hover:text-purple-800 transition-all duration-300"
              :class="{ active: $route.path === '/courses' }"
            >
              <UIcon
                name="i-heroicons-academic-cap"
                class="w-5 h-5 transition-transform duration-200 hover:scale-110"
              />
              <span>{{ $t("elearning") }}</span>
              <div
                class="absolute bottom-0 left-0 w-full h-0.5 bg-purple-500 transform scale-x-0 origin-left transition-transform duration-300 group-hover:scale-x-100"
                :class="{ 'scale-x-100': $route.path === '/courses' }"
              ></div>
            </NuxtLink>

            <NuxtLink
              to="/#micro-gigs"
              class="relative flex items-center gap-2 py-1 px-2 font-medium text-red-600 hover:text-red-800 transition-all duration-300"
              :class="{ active: $route.path === '/#micro-gigs' }"
            >
              <UIcon
                name="i-healthicons:money-bag-outline"
                class="w-5 h-5 transition-transform duration-200 hover:scale-110"
              />
              <span>{{ $t("earn_money") }}</span>
              <div
                class="absolute bottom-0 left-0 w-full h-0.5 bg-red-500 transform scale-x-0 origin-left transition-transform duration-300 group-hover:scale-x-100"
                :class="{ 'scale-x-100': $route.path === '/#micro-gigs' }"
              ></div>
            </NuxtLink>
          </div>
        </nav>

        <!-- Not Logged In User Section -->
        <div v-if="!user" class="flex relative menu-container items-center">
          <!-- Desktop language switcher - completely hidden on mobile -->
          <PublicTranslateHandler class="px-2 hidden" />

          <!-- Mobile Profile Icon -->
          <div class="sm:hidden">
            <NuxtLink to="/auth/login">
              <div
                class="w-10 h-10 rounded-full flex items-center justify-center bg-gray-100 border border-gray-200 shadow-sm"
              >
                <UIcon
                  name="i-material-symbols-person-rounded"
                  class="w-7 h-7 text-gray-600"
                />
              </div>
            </NuxtLink>
          </div>

          <!-- Login Button -->
          <UButton
            to="/auth/login"
            label="Login"
            color="gray"
            class="hidden sm:flex"
            :ui="{
              size: { sm: 'text-xs md:text-sm' },
              padding: { sm: 'px-2 py-1 md:px-2.5 md:py-1.5' },
              icon: { size: { sm: 'w-2 h-2 md:w-2.5 md:h-2.5' } },
            }"
            size="md"
          />
        </div>

        <!-- Logged In User Section -->
        <div v-else class="flex relative menu-container items-center z-40">
          <!-- Desktop language switcher - completely hidden on mobile -->
          <PublicTranslateHandler class="px-2 hidden sm:block" />

          <!-- User Action Buttons -->
          <div
            class="flex items-center gap-1.5 pr-1.5"
            v-if="user && user.user"
          >
            <!-- Inbox Button with Tailwind styling -->
            <NuxtLink to="/inbox/" class="relative cursor-pointer">
              <div
                class="size-10 flex items-center justify-center rounded-full transition-all duration-300 shadow-sm"
              >
                <NuxtImg 
                  src="https://adsyclub.com/static/frontend/images/chat_icon.png" 
                  alt="Inbox"
                  class="size-6"
                  loading="lazy"
                />

                <!-- Notification Badge with animation -->
                <transition
                  enter-active-class="transition duration-300 ease-out"
                  enter-from-class="transform scale-50 opacity-0"
                  leave-active-class="transition duration-200 ease-in"
                  leave-to-class="transform scale-50 opacity-0"
                >
                  <div
                    v-if="badgeCount > 0"
                    class="absolute -top-1 -right-1 min-w-4 h-4 flex items-center justify-center rounded-full bg-red-500 text-white text-xs font-semibold px-1 shadow-sm animate-pulse"
                  >
                    {{ badgeCount > 99 ? "99+" : badgeCount }}
                  </div>
                </transition>
              </div>
            </NuxtLink>

            <!-- QR Code Button with Tailwind styling -->
            <div @click="showQr = !showQr" class="relative cursor-pointer">
              <div
                class="size-10 flex items-center justify-center rounded-full transition-all duration-300 shadow-sm dark:bg-green-900/30 dark:hover:bg-green-900/50"
              >
                <UIcon
                  name="i-ic:twotone-qr-code-scanner"
                  class="size-6 text-green-600 dark:text-green-400"
                />
              </div>
            </div>
            <!-- QR Code Modal -->
            <CommonQrCodeModal
              v-model="showQr"
              title="Scan My QR Code"
              :qr-data="user.user.phone"
            />
          </div>

          <!-- Mobile User Profile Avatar with Tailwind -->
          <div
            @click="openMenu = !openMenu"
            class="sm:hidden relative cursor-pointer"
          >
            <div class="relative">
              <!-- User profile image with Tailwind styling -->
              <div
                :class="[
                  'size-10 rounded-full flex items-center justify-center overflow-hidden border-2 border-white shadow-sm',
                  user?.user?.is_pro
                    ? 'shadow-indigo-200 ring-2 ring-indigo-500'
                    : '',
                ]"
              >
                <img
                  v-if="user?.user?.image"
                  :src="user.user.image"
                  :alt="user.user.name || user.user.first_name"
                  class="w-full h-full object-cover rounded-full z-10"
                />
                <UIcon
                  v-else
                  name="i-heroicons-user"
                  class="w-6 h-6 text-gray-600 flex z-10"
                />
              </div>

              <!-- Pro Badge with Tailwind -->
              <div
                v-if="user?.user?.is_pro"
                class="absolute -top-2.5 -right-3.5 flex items-center gap-0.5 py-0.5 px-2 bg-gradient-to-r from-indigo-500 to-violet-600 text-white rounded-full text-[9px] font-medium shadow-sm"
              >
                <UIcon name="i-heroicons-shield-check" class="w-3 h-3" />
                <span>Pro</span>
              </div>

              <!-- Verification Badge with Tailwind -->
              <div
                v-if="user?.user?.kyc"
                class="absolute -bottom-1 -right-1 w-4 h-4 bg-white dark:bg-gray-800 flex items-center justify-center rounded-full shadow-sm"
              >
                <UIcon
                  name="mdi:check-decagram"
                  class="w-4 h-4 text-blue-600"
                />
              </div>
            </div>
          </div>

          <!-- Desktop User Profile Button with Tailwind -->
          <div
            @click="openMenu = !openMenu"
            class="relative cursor-pointer transition-all duration-300 rounded-full hover:shadow-sm max-sm:hidden"
          >
            <div
              class="flex items-center gap-2 p-1 pl-1 pr-3 border border-gray-200 dark:border-gray-700 rounded-full bg-white dark:bg-gray-800 hover:bg-gray-50 dark:hover:bg-gray-700 transition-colors duration-200"
            >
              <!-- Pro Badge -->
              <div
                v-if="user?.user?.is_pro"
                class="flex items-center gap-1 py-0.5 px-2 bg-gradient-to-r from-indigo-500 to-blue-600 text-white text-xs font-medium rounded-full"
              >
                <UIcon name="i-heroicons-shield-check" class="w-3.5 h-3.5" />
                <span>Pro</span>
              </div>

              <!-- User Info -->
              <div class="flex items-center gap-1.5">
                <!-- Verified Icon -->
                <UIcon
                  v-if="user?.user?.kyc"
                  name="mdi:check-decagram"
                  class="w-4 h-4 text-blue-600 dark:text-blue-400"
                />

                <!-- Avatar -->
                <div
                  class="relative w-8 h-8 rounded-full overflow-hidden flex items-center justify-center bg-gray-100 dark:bg-gray-700"
                >
                  <img
                    v-if="user?.user?.image"
                    :src="user.user.image"
                    :alt="user.user.name || user.user.first_name"
                    class="w-full h-full object-cover"
                  />
                  <UIcon
                    v-else
                    name="i-heroicons-user-circle"
                    class="w-6 h-6 text-gray-600 dark:text-gray-300"
                  />
                </div>
              </div>

              <!-- Dropdown indicator -->
              <UIcon
                :name="
                  openMenu
                    ? 'i-heroicons-chevron-up'
                    : 'i-heroicons-chevron-down'
                "
                class="w-4 h-4 text-gray-600 transition-transform duration-200"
              />
            </div>
          </div>

          <!-- User Dropdown Menu -->
          <UserDropdownMenu
            :user="user"
            :is-open="openMenu"
            @update:is-open="openMenu = $event"
            @upgrade-to-pro="upgradeToPro"
            @manage-subscription="manageSubscription"
            @logout="logout"
          />
        </div>
      </div>
    </UContainer>
  </div>
</template>

<script setup>
 import UserDropdownMenu from "./user-dropdown-menu.vue";
 import { useScrollDirection } from "~/composables/useScrollDirection";
 
 const { t } = useI18n();
 const { user, logout } = useAuth();
 const { get } = useApi();
 const { unreadTicketCount, totalUnreadCount, fetchUnreadCount } = useTickets();
 const { isScrollingDown, isScrollingUp } = useScrollDirection();
 const { chatIconPath } = useStaticAssets();
 const toast = useToast();
 
 const { useAdsyChat } = await import('~/composables/useAdsyChat.js');
 const { unreadCount: adsyUnreadCount, loadChatRooms, startHeaderPolling, stopHeaderPolling } = useAdsyChat();
 
 const openMenu = ref(false);
 const router = useRouter();
 const open = ref(true);
 const logo = ref({});
 const isOpen = ref(false);
 const showQr = ref(false);
 const warningDismissed = ref(false);
 const expiredWarningDismissed = ref(false);
 
 const badgeCount = computed(() => {
   return (totalUnreadCount.value || 0) + (adsyUnreadCount.value || 0);
 });
 
 import { useAppDownload } from "~/composables/useAppDownload";
 const { downloadApp } = useAppDownload();
 
 const downloadAndroidApp = async () => {
   try {
     await downloadApp();
     isOpen.value = false;
     toast.add({
       title: "Download Started",
       description: "AdsyClub Android app is downloading...",
       color: "green",
       icon: "i-heroicons-check-circle",
     });
   } catch (error) {
     console.error("Download error:", error);
     toast.add({
       title: "Download Error",
       description: "Failed to start download. Please try again.",
       color: "red",
       icon: "i-heroicons-exclamation-triangle",
     });
   }
 };
 
 const showDownloadBanner = ref(false);
 const _downloadBannerCookie = 'adsy_download_app_banner_dismissed_v1';
 
 const _getCookie = (name) => {
   try {
     const value = `; ${document.cookie}`;
     const parts = value.split(`; ${name}=`);
     if (parts.length === 2) return parts.pop().split(';').shift();
   } catch (_) {
   }
   return null;
 };
 
 const _setCookieHours = (name, value, hours) => {
   try {
     const date = new Date();
     date.setTime(date.getTime() + hours * 60 * 60 * 1000);
     document.cookie = `${name}=${value}; expires=${date.toUTCString()}; path=/`;
   } catch (_) {
   }
 };
 
 const dismissDownloadBanner = () => {
   _setCookieHours(_downloadBannerCookie, '1', 24);
   showDownloadBanner.value = false;
 };
 
 onMounted(async () => {
   await fetchUnreadCount();
   if (user.value?.user) {
     await loadChatRooms();
     startHeaderPolling();
   }
 
   if (!_getCookie(_downloadBannerCookie)) {
     showDownloadBanner.value = true;
   }
 });
 
 onUnmounted(() => {
   stopHeaderPolling();
 });
 
 const daysRemaining = computed(() => {
   if (!user.value?.user?.pro_validity) return 0;
 
   const today = new Date();
   const expiryDate = new Date(user.value.user.pro_validity);
   const diffTime = expiryDate - today;
   const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24));
 
   return diffDays > 0 ? Math.min(diffDays, 7) : 0;
 });
 
 const shouldShowWarning = computed(() => {
   if (!user.value?.user?.is_pro) return false;
 
   const today = new Date();
   const expiryDate = new Date(user.value?.user?.pro_validity || null);
   const diffTime = expiryDate - today;
   const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24));
 
   return diffDays > 0 && diffDays <= 7;
 });
 
 const isExpired = computed(() => {
   if (!user.value?.user?.is_pro || !user.value?.user?.pro_validity) return false;
 
   const today = new Date();
   const expiryDate = new Date(user.value.user.pro_validity);
 
   return today > expiryDate;
 });
 
 function dismissWarning() {
   warningDismissed.value = true;
   localStorage.setItem("subscription_warning_dismissed", "true");
   localStorage.setItem("subscription_warning_dismissed_date", new Date().toDateString());
 }
 
 function dismissExpiredWarning() {
   expiredWarningDismissed.value = true;
   localStorage.setItem("expired_warning_dismissed", "true");
   localStorage.setItem("expired_warning_dismissed_date", new Date().toDateString());
 }
 
 function renewSubscription() {
   openMenu.value = false;
   router.push("/upgrade-to-pro");
 }
 
 onMounted(() => {
   const storedDismissalDate = localStorage.getItem("subscription_warning_dismissed_date");
   if (storedDismissalDate) {
     const today = new Date().toDateString();
     warningDismissed.value = storedDismissalDate === today;
   } else {
     warningDismissed.value = false;
   }
 
   const expiredDismissalDate = localStorage.getItem("expired_warning_dismissed_date");
   if (expiredDismissalDate) {
     const today = new Date().toDateString();
     expiredWarningDismissed.value = expiredDismissalDate === today;
   } else {
     expiredWarningDismissed.value = false;
   }
 });
 
 const colorMode = useColorMode();
 colorMode.preference = "light";
 onMounted(() => {
   localStorage.setItem("nuxt-color-mode", "light");
 });
 
 async function getLogo() {
   try {
     const res = await get("/logo/");
     if (res.data) {
       logo.value = res.data;
     }
   } catch (error) {
     logo.value = {};
   }
 }
 getLogo();
 
 function upgradeToPro() {
   openMenu.value = false;
   router.push("/upgrade-to-pro");
 }
 
 function manageSubscription() {
   openMenu.value = false;
   router.push("/account/subscription");
 }
 
 function navigateToInbox() {
   router.push("/inbox/");
 }
 
 function formatDate(date) {
   return new Date(date).toLocaleDateString(undefined, {
     year: "numeric",
     month: "short",
     day: "numeric",
   });
 }
 
 defineShortcuts({
   o: () => (open.value = !open.value),
 });
 
 const handleClickOutside = (event) => {
   const menuContainer = document.querySelector(".menu-container");
   if (menuContainer && !menuContainer.contains(event.target)) {
     openMenu.value = false;
   }
 };
 
 const isScrolled = ref(false);
 const handleScroll = () => {
   isScrolled.value = window.scrollY > 80;
 };
 
 onMounted(() => {
   window.addEventListener("scroll", handleScroll);
   document.addEventListener("click", handleClickOutside);
 
   const subscriptionEndDate = new Date(user?.user?.pro_validity);
   const currentDate = new Date();
   const timeDifference = subscriptionEndDate - currentDate;
   const days = Math.ceil(timeDifference / (1000 * 60 * 60 * 24));
 
   if (days <= 7 && days > 0) {
     shouldShowWarning.value = true;
   } else if (days <= 0) {
     isExpired.value = true;
   }
 });
 
 onUnmounted(() => {
   window.removeEventListener("scroll", handleScroll);
   document.removeEventListener("click", handleClickOutside);
 });
 
 watch(router.currentRoute, () => {
   if (openMenu.value) {
     openMenu.value = false;
     isOpen.value = false;
   }
 });
</script>

<!-- Using simple Tailwind animation utilities -->
<style>
@keyframes shimmer {
  0% {
    transform: translateX(-100%);
  }
  100% {
    transform: translateX(100%);
  }
}

/* Hide scrollbar on mobile while keeping scroll functionality */
@media (max-width: 640px) {
  .scrollbar-hide {
    -ms-overflow-style: none; /* Internet Explorer 10+ */
    scrollbar-width: none; /* Firefox */
  }

  .scrollbar-hide::-webkit-scrollbar {
    display: none; /* Safari and Chrome */
  }
}

/* Show scrollbar on larger screens */
@media (min-width: 640px) {
  .scrollbar-default {
    -ms-overflow-style: auto;
    scrollbar-width: auto;
  }

  .scrollbar-default::-webkit-scrollbar {
    display: block;
  }
}

/* For very small screens */
@media (max-width: 385px) {
  .xs\:block {
    display: block;
  }
}
</style>
