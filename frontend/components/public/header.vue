<template>
  <div
    class="py-3 z-[99999999] bg-slate-200/70 shadow-sm rounded-b-lg dark:bg-black max-w-[1280px] md:mx-auto"
    :class="
      isScrolled
        ? 'fixed top-0 left-0 right-0 mx-auto backdrop-blur-sm border-b border-slate-200/50 rounded-b-lg'
        : 'sticky'
    "
  >
    <!-- Subscription Warnings - Always visible regardless of scroll state -->
    <div class="subscription-warnings relative px-4">
      <!-- Pre-expiration Warning (Closable) -->
      <transition name="fade">
        <div
          v-if="shouldShowWarning && !warningDismissed"
          class="mx-auto my-2 px-4 relative overflow-hidden rounded-lg border border-amber-300/70 dark:border-amber-600/50 group transition-all duration-300 hover:shadow-sm"
        >
          <!-- Premium glass background -->
          <div
            class="absolute inset-0 bg-gradient-to-r from-amber-50/90 via-amber-50/80 to-amber-100/90 dark:from-amber-900/30 dark:via-amber-800/20 dark:to-amber-900/30 backdrop-blur-md"
          ></div>

          <!-- Premium effects -->
          <div
            class="absolute -left-20 -top-20 w-40 h-40 bg-amber-200/20 rounded-full blur-2xl transform-gpu"
          ></div>
          <div
            class="absolute -right-20 -bottom-20 w-40 h-40 bg-amber-300/20 rounded-full blur-2xl transform-gpu"
          ></div>

          <!-- Shimmering line -->
          <div
            class="absolute left-0 top-0 h-px w-full bg-gradient-to-r from-transparent via-amber-400/50 dark:via-amber-400/30 to-transparent opacity-70 animate-shimmer"
          ></div>
          <div
            class="absolute left-0 bottom-0 h-px w-full bg-gradient-to-r from-transparent via-amber-400/50 dark:via-amber-400/30 to-transparent opacity-70 animate-shimmer"
          ></div>

          <div
            class="relative z-10 p-2.5 sm:p-3.5 flex items-center justify-between"
          >
            <!-- Left side with icon and text -->
            <div class="flex items-center gap-2 sm:gap-3">
              <!-- Premium icon with pulse effect -->
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
                  class="absolute -inset-1.5 bg-amber-300/20 blur-md rounded-full animate-pulse-slow opacity-50"
                ></div>
              </div>

              <!-- Alert content - simplified to just the title -->

              <div class="inline-flex items-center gap-2">
                <UIcon
                  name="i-icon-park-outline-caution"
                  class="size-5 text-amber-800"
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

            <!-- Right side with actions -->
            <div class="flex items-center gap-2">
              <UButton
                @click="dismissWarning"
                size="2xs"
                variant="ghost"
                color="gray"
                icon="i-heroicons-x-mark"
                class="!p-1 hover:rotate-90 transition-transform"
                aria-label="Dismiss"
              />
            </div>
          </div>
        </div>
      </transition>

      <!-- Post-expiration Alert (Not Closable) -->
      <transition name="fade">
        <div
          v-if="isExpired"
          class="mx-auto my-2 relative overflow-hidden rounded-lg border border-red-400/70 dark:border-red-600/40 group transition-all duration-300 shadow-sm hover:shadow-sm"
        >
          <!-- Premium glass background with subtle animation -->
          <div
            class="absolute inset-0 bg-gradient-to-r from-red-50/90 via-red-100/80 to-red-50/90 dark:from-red-900/30 dark:via-red-800/20 dark:to-red-900/30 backdrop-blur-md"
          ></div>

          <!-- Premium effects -->
          <div
            class="absolute -left-20 -top-20 w-40 h-40 bg-red-200/20 rounded-full blur-2xl transform-gpu"
          ></div>
          <div
            class="absolute -right-20 -bottom-20 w-40 h-40 bg-red-300/20 rounded-full blur-2xl transform-gpu"
          ></div>

          <!-- Pulsing border effect -->
          <div
            class="absolute inset-0 rounded-lg border-2 border-red-400/20 dark:border-red-600/20 scale-[0.98] animate-pulse-slow"
          ></div>

          <!-- Shimmering lines -->
          <div
            class="absolute left-0 top-0 h-px w-full bg-gradient-to-r from-transparent via-red-400/50 dark:via-red-400/30 to-transparent opacity-70 animate-shimmer"
          ></div>
          <div
            class="absolute left-0 bottom-0 h-px w-full bg-gradient-to-r from-transparent via-red-400/50 dark:via-red-400/30 to-transparent opacity-70 animate-shimmer"
          ></div>

          <div
            class="relative z-10 p-3 sm:p-3.5 flex items-center justify-between"
          >
            <!-- Left side with icon and text -->
            <div class="flex items-center gap-2 sm:gap-3">
              <!-- Premium alert icon with effect -->
              <div class="relative hidden xs:block">
                <div
                  class="w-10 h-10 rounded-full bg-gradient-to-br from-red-100 to-red-200 dark:from-red-800 dark:to-red-700 border border-red-300/50 dark:border-red-600/30 flex items-center justify-center shadow-inner"
                >
                  <UIcon
                    name="i-heroicons-exclamation-triangle"
                    class="w-5 h-5 text-red-600 dark:text-red-400"
                  />
                </div>
                <div
                  class="absolute -inset-1.5 bg-red-300/30 blur-md rounded-full animate-pulse opacity-70"
                ></div>
              </div>

              <!-- Simplified alert content - just the title -->
              <h3
                class="text-xs sm:text-sm font-medium text-red-800 dark:text-red-300"
              >
                {{ $t("subscription_expired") }}
              </h3>
            </div>

            <!-- Premium renewal button -->
            <UButton
              @click="renewSubscription"
              size="2xs"
              color="red"
              variant="solid"
              class="!py-1 !px-2.5 group hover:bg-red-600 transition-colors duration-300 relative overflow-hidden"
            >
              <div
                class="absolute inset-0 bg-gradient-to-r from-red-400/0 via-white/10 to-red-400/0 -translate-x-full group-hover:translate-x-full transition-transform duration-700 ease-in-out"
              ></div>
              <span
                class="text-2xs sm:text-xs whitespace-nowrap flex items-center gap-1 relative z-10"
              >
                {{ $t("renew_now") }}
                <UIcon
                  name="i-heroicons-arrow-right"
                  class="w-3 h-3 group-hover:translate-x-0.5 transition-transform"
                />
              </span>
            </UButton>
          </div>
        </div>
      </transition>
    </div>

    <UContainer>
      <!-- <PublicDonation /> -->
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
            header: {
              padding: 'pb-0.5',
            },
            ring: '',
            rounded: '',
            shadow: '',
            body: {
              padding: '',
            },
          }"
          class="bg-white dark:bg-gray-900 border border-gray-200 dark:border-gray-700 mt-4 overflow-y-scroll"
        >
          <div class="w-full flex justify-end pt-12 px-4">
            <UButton
              color="gray"
              variant="ghost"
              icon="i-heroicons-x-mark-20-solid"
              class="text-gray-500 hover:text-gray-700 dark:text-gray-500 dark:hover:text-gray-300 transition-transform transform hover:scale-110"
              @click="isOpen = false"
            />
          </div>
          <div class="px-4">
            <PublicTranslateHandler class="px-2 mt-3" />
          </div>
          <!-- Navigation Links -->
          <div class="px-4 py-6">
            <h3
              class="text-lg font-semibold text-gray-700 dark:text-gray-300 mb-2 px-4"
            >
              {{ $t("menu") }}
            </h3>
            <UVerticalNavigation
              :links="[
                {
                  label: $t('home'),
                  to: '/',
                  icon: 'i-heroicons-home',
                },
                {
                  label: $t('classified_service'),
                  to: '#classified-services',
                  icon: 'i-heroicons-clipboard-document-list',
                },
                {
                  label: $t('earn_money'),
                  to: '#micro-gigs',
                  icon: 'i-healthicons:money-bag-outline',
                },
                {
                  label: $t('faq'),
                  to: '/faq/',
                  icon: 'i-streamline:interface-help-question-circle-circle-faq-frame-help-info-mark-more-query-question',
                },
                {
                  label: 'মোবাইল রিচার্জ',
                  to: '/mobile-recharge',
                  icon: 'i-ic-baseline-install-mobile',
                },
              ]"
              :ui="{
                padding: 'py-3 px-4',
              }"
              class="space-y-2"
            >
              <template #default="{ link }">
                <span @click="isOpen = false">{{ link.label }}</span>
              </template>
            </UVerticalNavigation>
          </div>

          <!-- Download App Section -->
          <div class="px-4 py-6 border-t border-gray-200 dark:border-gray-700">
            <h3
              class="text-lg font-semibold text-gray-700 dark:text-gray-300 mb-4"
            >
              {{ $t("download_our_app") }}
            </h3>
            <div class="flex items-center gap-4">
              <NuxtLink
                to="/coming-soon"
                class="w-32 h-10 bg-gray-100 dark:bg-gray-800 rounded-lg shadow-sm flex items-center justify-center hover:bg-gray-200 dark:hover:bg-gray-700 transition overflow-hidden"
              >
                <img
                  src="/static/frontend/images/google.png"
                  alt="Google Play"
                  class="w-full h-full object-contain"
                />
              </NuxtLink>
              <NuxtLink
                href="/coming-soon"
                class="w-32 h-10 bg-gray-100 dark:bg-gray-800 rounded-lg shadow-sm flex items-center justify-center hover:bg-gray-200 dark:hover:bg-gray-700 transition overflow-hidden"
              >
                <img
                  src="/static/frontend/images/apple.png"
                  alt="App Store"
                  class="w-full h-full object-contain"
                />
              </NuxtLink>
            </div>
          </div>

          <!-- Social Media Share Section -->
          <div class="px-4 py-6 border-t border-gray-200 dark:border-gray-700">
            <h3
              class="text-lg font-semibold text-gray-700 dark:text-gray-300 mb-4"
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
              <!-- <a
                href="#"
                class="w-10 h-10 rounded-full bg-sky-400 text-white flex items-center justify-center hover:bg-sky-500 transition"
                aria-label="Twitter"
              >
                <UIcon name="i-heroicons-twitter" class="w-5 h-5" />
              </a>
              <a
                href="#"
                class="w-10 h-10 rounded-full bg-pink-500 text-white flex items-center justify-center hover:bg-pink-600 transition"
                aria-label="Instagram"
              >
                <UIcon name="i-heroicons-instagram" class="w-5 h-5" />
              </a>
              <a
                href="#"
                class="w-10 h-10 rounded-full bg-red-500 text-white flex items-center justify-center hover:bg-red-600 transition"
                aria-label="YouTube"
              >
                <UIcon name="i-heroicons-youtube" class="w-5 h-5" />
              </a> -->
            </div>
          </div>

          <!-- Footer Section -->
        </UCard>
      </USlideover>
      <div class="flex items-center justify-between gap-1.5 lg:gap-6">
        <div class="block md:hidden">
          <UButton
            @click="isOpen = true"
            icon="i-ci-hamburger-md"
            variant="outline"
            color="gray"
            size="xs"
          />
        </div>
        <PublicLogo class="max-sm:mr-auto" />
        <div class="hidden md:block">
          <UHorizontalNavigation
            :links="[
              {
                label: $t('home'),
                to: '/#home',
                icon: 'i-heroicons-home',
              },
              {
                label: $t('business_network'),
                to: '/business-network',
                icon: 'i-lucide-globe',
              },
              {
                label: $t('adsy_news'),
                to: '/adsy-news',
                icon: 'i-lucide-newspaper',
              },
              {
                label: $t('earn_money'),
                to: '/#micro-gigs',
                icon: 'i-healthicons:money-bag-outline',
              },

              {
                label: $t('mobile_recharge'),
                to: '/mobile-recharge',
                icon: 'i-uil-mobile-vibrate',
              },
            ]"
            class="border-b border-gray-200 dark:border-gray-800 text-lg"
            :ui="{
              wrapper: 'w-auto',
              label: 'text-base',
              active: 'after:hidden',
            }"
          />
        </div>
        <div v-if="!user" class="flex relative menu-container">
          <PublicTranslateHandler class="px-2 max-sm:hidden" />
          <UButton
            to="/auth/login"
            label="Login/Register"
            color="gray"
            :ui="{
              size: {
                sm: 'text-xs md:text-sm',
              },
              padding: {
                sm: 'px-2 py-1 md:px-2.5 md:py-1.5',
              },
              icon: {
                size: {
                  sm: 'w-2 h-2 md:w-2.5 md:h-2.5',
                },
              },
            }"
            size="md"
          >
          </UButton>
        </div>
        <div v-else class="flex relative menu-container">
          <PublicTranslateHandler class="px-2 max-sm:hidden" />
          <div class="mr-2" v-if="user && user.user">
            <UButton
              icon="i-ic:twotone-qr-code-scanner"
              size="md"
              :ui="{
                size: { md: 'text-xs sm:text-sm' },
                padding: { md: 'px-2.5 py-1.5 sm:px-3 sm:py-2' },
              }"
              color="primary"
              variant="outline"
              @click="showQr = !showQr"
              block
            />
            <UModal
              v-model="showQr"
              :ui="{
                width: 'w-full sm:max-w-md',
                background: 'bg-slate-100',
              }"
            >
              <div
                class="px-4 py-12 flex flex-col gap-4 items-center justify-center relative rounded-3xl overflow-hidden"
              >
                <UButton
                  icon="i-heroicons-x-mark"
                  size="md"
                  color="primary"
                  variant="solid"
                  @click="showQr = false"
                  class="absolute top-1 right-1 rounded-full"
                />

                <h3 class="text-xl font-semibold text-green-700">AdsyPay</h3>
                <h3 class="text-xl font-semibold">Scan My QR Code</h3>
                <div class="border p-4 rounded-lg shadow-sm bg-white">
                  <NuxtImg
                    class="w-[250px]"
                    :src="`https://api.qrserver.com/v1/create-qr-code/?size=250x250&data=${user.user.phone}`"
                  ></NuxtImg>
                </div>
              </div>
            </UModal>
          </div>
          <UButton
            size="sm"
            color="primary"
            variant="outline"
            @click="openMenu = !openMenu"
            :ui="{
              gap: {
                sm: 'gap-x-1 md:gap-x-1.5',
              },
              size: {
                sm: 'text-xs sm:text-sm',
              },
              padding: {
                sm: 'px-1.5 py-1 md:px-2.5 md:py-1.5',
              },
              icon: {
                size: {
                  sm: 'w-2 h-2 md:w-2.5 md:h-2.5',
                },
              },
            }"
          >
            <span
              v-if="user?.user?.is_pro"
              class="text-2xs px-2 py-0.5 bg-gradient-to-r from-indigo-500 to-blue-600 text-white rounded-full font-medium shadow-sm"
            >
              <div class="flex items-center gap-1">
                <UIcon
                  name="i-heroicons-shield-check"
                  class="size-4 text-white"
                />
                <span class="text-xs">Pro</span>
              </div>
            </span>
            <UIcon
              v-if="user?.user?.kyc"
              name="mdi:check-decagram"
              class="w-5 h-5 text-blue-600"
            />
            <UIcon v-else name="i-heroicons-user-circle" class="text-xl" />

            Hi {{ (user?.user?.first_name).slice(0, 8) }}
            <UIcon name="i-heroicons-chevron-down-16-solid" v-if="!openMenu" />
            <UIcon name="i-heroicons-chevron-up-16-solid" v-if="openMenu" />
          </UButton>

          <!-- Modern Glass-Morphism Dropdown Menu -->
          <div
            class="absolute right-3 top-11 w-72 overflow-hidden transition-all duration-300 origin-top-right transform-gpu"
            :class="
              openMenu
                ? 'opacity-100 scale-100 translate-y-0'
                : 'opacity-0 scale-95 translate-y-2 pointer-events-none'
            "
          >
            <!-- Frosted glass container with modern shadow -->
            <div
              class="backdrop-blur-lg bg-white/95 dark:bg-slate-800/95 rounded-xl shadow-sm border border-slate-200/50 dark:border-slate-700/50 overflow-hidden"
            >
              <!-- Animated gradient accent -->
              <div
                class="absolute inset-x-0 top-0 h-1 bg-gradient-to-r from-primary-400 via-indigo-500 to-primary-600 animate-gradient-x"
              ></div>

              <!-- User Profile Section -->
              <div class="p-2 relative overflow-hidden">
                <!-- Background pattern -->
                <div
                  class="absolute inset-0 bg-grid-slate-100 dark:bg-grid-slate-700/30 opacity-20"
                ></div>
              </div>

              <!-- Membership Section -->
              <div
                class="px-2 pb-3"
                :class="user?.user?.is_pro ? 'pointer-events-none' : ''"
              >
                <!-- Free User Version -->
                <div
                  v-if="!user?.user?.is_pro"
                  class="relative rounded-xl overflow-hidden border border-slate-200 dark:border-slate-700 group transition-all duration-300 hover:shadow-sm hover:border-primary-200 dark:hover:border-primary-800/50"
                >
                  <!-- Subtle background pattern -->
                  <div
                    class="absolute inset-0 bg-graph-paper-slate-100 dark:bg-graph-paper-slate-900 opacity-[0.03] group-hover:opacity-[0.05]"
                  ></div>

                  <!-- Top Section: Current Plan -->
                  <div
                    class="relative bg-slate-50 dark:bg-slate-800/60 px-3 py-2.5 border-b border-slate-200 dark:border-slate-700"
                  >
                    <div class="flex items-center justify-between">
                      <div class="flex items-center gap-1.5">
                        <UIcon
                          name="i-heroicons-user"
                          class="w-4 h-4 text-slate-500 dark:text-slate-400"
                        />
                        <span
                          class="text-xs font-medium text-gray-500 dark:text-slate-300"
                          >{{ $t("current_plan") }}</span
                        >
                      </div>
                      <span
                        class="text-2xs px-2 py-0.5 bg-slate-200 dark:bg-slate-700 text-slate-700 dark:text-slate-300 rounded-full font-medium"
                      >
                        {{ $t("free") }}
                      </span>
                    </div>
                  </div>

                  <!-- Bottom Section: Upgrade Action with enhanced hover effects -->
                  <div
                    @click="upgradeToPro"
                    class="relative p-3.5 cursor-pointer group overflow-hidden"
                  >
                    <!-- Hover background effect -->
                    <div
                      class="absolute inset-0 bg-gradient-to-r from-indigo-50/0 via-indigo-50 to-indigo-50/0 dark:from-indigo-900/0 dark:via-indigo-900/20 dark:to-indigo-900/0 opacity-0 group-hover:opacity-100 -translate-x-full group-hover:translate-x-0 transition-all duration-700"
                    ></div>

                    <div class="flex items-center gap-2 relative z-10">
                      <!-- Pro Badge Icon with 3D effect -->
                      <div
                        class="w-10 h-10 rounded-xl bg-gradient-to-br from-indigo-100 to-purple-100 dark:from-indigo-900/30 dark:to-purple-900/40 flex items-center justify-center shadow-sm border border-indigo-200/80 dark:border-indigo-800/30 transform transition-all duration-300 group-hover:scale-110 group-hover:rotate-3"
                      >
                        <div
                          class="w-5 h-5 text-transparent bg-clip-text bg-gradient-to-br from-indigo-600 to-purple-600 dark:from-indigo-400 dark:to-purple-400"
                        >
                          ⭐
                        </div>
                      </div>

                      <!-- Upgrade Text with micro-interactions -->
                      <div class="flex-1">
                        <h4
                          class="font-medium text-gray-700 dark:text-white text-sm flex items-center"
                        >
                          {{ $t("upgrade_pro") }}
                          <span
                            class="ml-1.5 inline-flex items-center justify-center w-4 h-4 bg-gradient-to-r from-amber-400 to-amber-500 rounded-full text-xs text-white font-semibold transform group-hover:scale-110 transition-transform"
                          >
                            +
                          </span>
                        </h4>
                        <p
                          class="text-xs text-gray-500 dark:text-slate-400 mt-0.5 max-w-[180px]"
                        >
                          {{ $t("upgrade_pro_text") }}
                        </p>
                      </div>

                      <!-- Enhanced Switch Toggle Design -->
                      <div
                        class="w-11 h-6 rounded-full bg-gradient-to-r from-slate-200 to-slate-300 dark:from-slate-700 dark:to-slate-600 p-0.5 flex items-center cursor-pointer relative overflow-hidden group-hover:from-indigo-400 group-hover:to-purple-500 transition-all duration-300"
                      >
                        <div
                          class="absolute left-0.5 w-5 h-5 rounded-full bg-white shadow-sm transform transition-all duration-500 group-hover:translate-x-5"
                        ></div>
                      </div>
                    </div>
                  </div>
                </div>

                <!-- Pro User Version -->
                <div
                  v-else
                  class="relative rounded-xl overflow-hidden border border-indigo-200 dark:border-indigo-800/40 group transition-all duration-300 hover:shadow-sm"
                >
                  <!-- Animated pattern background -->
                  <div
                    class="absolute inset-0 bg-[url('/img/patterns/circuit.svg')] bg-center opacity-[0.03] group-hover:opacity-[0.07]"
                  ></div>

                  <!-- Top Section: Current Plan with premium styling -->
                  <div
                    class="relative bg-gradient-to-r from-indigo-50 to-blue-50 dark:from-indigo-900/50 dark:to-blue-900/30 px-3 py-2.5 border-b border-indigo-100 dark:border-indigo-800/30"
                  >
                    <div class="flex items-center justify-between">
                      <div class="flex items-center gap-1.5">
                        <UIcon
                          name="i-heroicons-sparkles"
                          class="w-4 h-4 text-indigo-600 dark:text-indigo-400"
                        />
                        <span
                          class="text-xs font-medium text-indigo-700 dark:text-indigo-300"
                          >{{ $t("premium_access") }}</span
                        >
                      </div>
                      <span
                        class="text-2xs px-2 py-0.5 bg-gradient-to-r from-indigo-500 to-blue-600 text-white rounded-full font-medium shadow-sm"
                      >
                        <div class="flex items-center gap-1">
                          <UIcon
                            name="i-heroicons-shield-check"
                            class="size-4 text-white"
                          />
                          <span>{{ $t("pro") }}</span>
                        </div>
                      </span>
                    </div>
                  </div>

                  <!-- Bottom Section: Pro Status with enhanced styling -->
                  <div
                    @click="manageSubscription"
                    class="relative p-3.5 cursor-pointer group/inner overflow-hidden"
                  >
                    <!-- Hover background effect -->
                    <div
                      class="absolute inset-0 bg-gradient-to-r from-blue-50/0 via-blue-50 to-blue-50/0 dark:from-blue-900/0 dark:via-blue-900/20 dark:to-blue-900/0 opacity-0 group-hover:opacity-100 -translate-x-full group-hover:translate-x-0 transition-all duration-700"
                    ></div>

                    <div class="flex items-center gap-3 relative z-10">
                      <!-- Premium badge with glow effect -->
                      <div
                        class="w-10 h-10 rounded-xl bg-gradient-to-br from-indigo-500/10 to-blue-500/10 dark:from-indigo-600/20 dark:to-blue-600/20 flex items-center justify-center border border-indigo-300 dark:border-indigo-700/50 shadow-sm group-hover/inner:shadow-indigo-200 dark:group-hover/inner:shadow-indigo-900/30 transform transition-all duration-300 group-hover/inner:scale-110"
                      >
                        <div class="relative">
                          <UIcon
                            name="i-heroicons-shield-check"
                            class="w-5 h-5 text-indigo-600 dark:text-indigo-400"
                          />
                          <div
                            class="absolute inset-0 bg-indigo-400 blur-xl opacity-0 group-hover/inner:opacity-30 transition-opacity duration-500"
                          ></div>
                        </div>
                      </div>

                      <!-- Pro Status Text -->
                      <div class="flex-1">
                        <h4 class="font-medium text-gray-700 dark:text-white">
                          {{ $t("pro_member") }}
                        </h4>
                        <p
                          class="text-xs text-gray-500 dark:text-slate-400 mt-0.5 flex items-center"
                        >
                          Valid until {{ formatDate(user?.user?.pro_validity) }}
                        </p>
                      </div>

                      <!-- Active premium switch style -->
                      <div
                        class="w-11 h-6 rounded-full bg-gradient-to-r from-indigo-400 to-blue-500 p-0.5 flex items-center justify-end cursor-pointer shadow-inner"
                      >
                        <div
                          class="w-5 h-5 rounded-full bg-white shadow-sm transform transition-transform"
                        ></div>
                      </div>
                    </div>
                  </div>
                </div>
              </div>

              <!-- Main Navigation Links with enhanced styling -->
              <div class="px-4 pt-2 pb-3">
                <div class="grid grid-cols-2 gap-2">
                  <NuxtLink
                    v-for="(link, index) in [
                      {
                        label: $route.path.includes('/business-network')
                          ? 'AdsyClub'
                          : t('business_network'),
                        to: $route.path.includes('/business-network')
                          ? '/'
                          : '/business-network',
                        icon: $route.path.includes('/business-network')
                          ? 'i-lucide-chart-bar-big'
                          : 'i-eos-icons-network',
                        color: 'text-orange-600 dark:text-orange-400',
                        bg: 'from-orange-100 to-orange-50 dark:from-orange-900/30 dark:to-orange-900/10',
                        border: 'border-orange-200 dark:border-orange-800/30',
                      },
                      {
                        label: t('adsy_news'),
                        to: '/adsy-news',
                        icon: 'i-mdi-newspaper-variant-multiple-outline',
                        color: 'text-purple-600 dark:text-purple-400',
                        bg: 'from-purple-100 to-purple-50 dark:from-purple-900/30 dark:to-purple-900/10',
                        border: 'border-purple-200 dark:border-purple-800/30',
                      },
                      {
                        label: t('ad'),
                        to: '/my-classified-services/',
                        icon: 'i-heroicons-megaphone',
                        color: 'text-emerald-600 dark:text-emerald-400',
                        bg: 'from-emerald-100 to-emerald-50 dark:from-emerald-900/30 dark:to-emerald-900/10',
                        border: 'border-emerald-200 dark:border-emerald-800/30',
                        badge: {
                          show: true,
                          type: 'free',
                          text: t('free'),
                        },
                      },
                      {
                        label: t('eshop_manager'),
                        to: '/shop-manager/',
                        icon: 'i-heroicons-shopping-bag',
                        color: 'text-blue-600 dark:text-blue-400',
                        bg: 'from-blue-100 to-blue-50 dark:from-blue-900/30 dark:to-blue-900/10',
                        border: 'border-blue-200 dark:border-blue-800/30',
                        badge: {
                          show: true,
                          type: 'pro',
                          text: t('pro'),
                        },
                      },

                      {
                        label: $t('transaction'),
                        to: '/deposit-withdraw',
                        icon: 'i-heroicons-banknotes',
                        color: 'text-emerald-600 dark:text-emerald-400',
                        bg: 'from-emerald-100 to-emerald-50 dark:from-emerald-900/30 dark:to-emerald-900/10',
                        border: 'border-emerald-200 dark:border-emerald-800/30',
                      },
                      {
                        label: $t('mobile_recharge'),
                        to: '/mobile-recharge',
                        icon: 'i-uil-mobile-vibrate',
                        color: 'text-orange-600 dark:text-orange-400',
                        bg: 'from-orange-100 to-orange-50 dark:from-orange-900/30 dark:to-orange-900/10',
                        border: 'border-orange-200 dark:border-orange-800/30',
                      },
                    ]"
                    :key="index"
                    :to="link.to"
                    class="flex flex-col items-center justify-center py-3 px-2 rounded-xl border bg-gradient-to-br transition-all duration-300 group text-center relative hover:shadow-sm hover:-translate-y-0.5 cursor-pointer"
                    :class="[`bg-${link.bg}`, `${link.border}`]"
                    @click="openMenu = false"
                  >
                    <!-- FREE Badge (for বিজ্ঞাপন) -->
                    <div
                      v-if="
                        link.badge &&
                        link.badge.show &&
                        link.badge.type === 'free'
                      "
                      class="absolute -top-1.5 -right-1.5 bg-white dark:bg-slate-800 rounded-full p-0.5 shadow-sm transform transition-all duration-300 group-hover:scale-110 group-hover:rotate-3 z-10"
                    >
                      <div
                        class="bg-gradient-to-r from-slate-400 to-slate-500 text-white text-xs font-semibold px-1.5 py-0.5 rounded-full"
                      >
                        {{ link.badge.text }}
                      </div>
                    </div>

                    <!-- PRO Badge (for eShop) -->
                    <div
                      v-if="
                        link.badge &&
                        link.badge.show &&
                        link.badge.type === 'pro'
                      "
                      class="absolute -top-1.5 -right-1.5 bg-white dark:bg-slate-800 rounded-full p-0.5 shadow-sm transform transition-all duration-300 group-hover:scale-110 group-hover:rotate-3 z-10"
                    >
                      <div
                        class="bg-gradient-to-r from-indigo-500 to-blue-600 text-white text-xs font-semibold px-1.5 py-0.5 rounded-full flex items-center"
                      >
                        <UIcon
                          name="i-heroicons-sparkles"
                          class="w-2 h-2 mr-0.5 text-yellow-200"
                        />
                        {{ link.badge.text }}
                      </div>
                    </div>

                    <div
                      :class="`w-9 h-9 rounded-full flex items-center justify-center ${link.color} mb-1 
                                 group-hover:scale-110 transition-transform group-hover:rotate-3`"
                    >
                      <UIcon :name="link.icon" class="w-5 h-5" />
                    </div>
                    <span
                      class="text-xs font-medium text-slate-700 dark:text-slate-200 relative overflow-hidden"
                    >
                      {{ link.label }}
                      <span
                        class="absolute bottom-0 left-0 w-full h-0.5 bg-current transform scale-x-0 origin-left transition-transform group-hover:scale-x-100"
                      ></span>
                    </span>
                  </NuxtLink>
                </div>
              </div>

              <!-- Settings & Logout -->
              <div
                class="px-4 py-3 border-t border-slate-100 dark:border-slate-700/50 space-y-0.5"
              >
                <div class="flex justify-between">
                  <!-- Settings Link -->
                  <NuxtLink
                    to="/settings"
                    class="flex items-center gap-2 py-2 px-3 rounded-lg text-slate-700 dark:text-slate-300 hover:bg-slate-100 dark:hover:bg-slate-700/50 transition-colors group"
                    @click="openMenu = false"
                  >
                    <div
                      class="w-7 h-7 rounded-full bg-slate-100 dark:bg-slate-800 flex items-center justify-center group-hover:bg-slate-200 dark:group-hover:bg-slate-700 transition-colors"
                    >
                      <UIcon
                        name="i-heroicons-cog-6-tooth"
                        class="w-4 h-4 text-slate-500 dark:text-slate-400"
                      />
                    </div>
                    <span class="text-sm">{{ $t("settings") }}</span>
                  </NuxtLink>

                  <!-- Support Link -->
                  <NuxtLink
                    to="/upload-center"
                    class="flex items-center gap-2 py-2 px-3 rounded-lg text-slate-700 dark:text-slate-300 hover:bg-slate-100 dark:hover:bg-slate-700/50 transition-colors group"
                    @click="openMenu = false"
                  >
                    <div
                      class="w-7 h-7 rounded-full bg-slate-100 dark:bg-slate-800 flex items-center justify-center group-hover:bg-slate-200 dark:group-hover:bg-slate-700 transition-colors"
                    >
                      <UIcon
                        name="i-material-symbols-drive-folder-upload-outline-sharp"
                        class="w-4 h-4 text-slate-500 dark:text-slate-400"
                      />
                    </div>
                    <span class="text-sm">{{ $t("verification") }}</span>
                  </NuxtLink>
                </div>

                <!-- Logout button with polished design -->
                <button
                  @click="
                    logout();
                    openMenu = false;
                  "
                  class="w-full flex items-center gap-2 py-2 px-3 mt-1 rounded-lg text-red-600 dark:text-red-400 hover:bg-red-50 dark:hover:bg-red-900/20 transition-all duration-300 group"
                >
                  <div
                    class="w-7 h-7 rounded-full bg-red-50 dark:bg-red-900/20 flex items-center justify-center group-hover:bg-red-100 dark:group-hover:bg-red-800/30 transition-colors"
                  >
                    <UIcon
                      name="i-heroicons-arrow-right-on-rectangle"
                      class="w-4 h-4 text-red-500 dark:text-red-400 transform transition-transform group-hover:-translate-x-0.5"
                    />
                  </div>
                  <span class="text-sm font-medium">{{ $t("logout") }}</span>
                </button>
              </div>
            </div>
          </div>
        </div>
      </div>
    </UContainer>
  </div>
</template>

<script setup>
const { t } = useI18n();
const { user, logout } = useAuth();
const { get } = useApi();
const openMenu = ref(false);
const router = useRouter();
const open = ref(true);
const logo = ref({});
const isOpen = ref(false);
const showQr = ref(false);
// Subscription alert state
const warningDismissed = ref(false);

// Calculate days remaining before subscription expiration
const daysRemaining = computed(() => {
  if (!user.value?.user?.pro_validity) return 0;

  const today = new Date();
  const expiryDate = new Date(user.value.user.pro_validity);
  const diffTime = expiryDate - today;
  const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24));

  return diffDays > 0 ? Math.min(diffDays, 7) : 0;
});

// Should show warning only if user is pro and has 1-7 days left
const shouldShowWarning = computed(() => {
  if (!user.value?.user?.is_pro) return false;

  const today = new Date();
  const expiryDate = new Date(user.value?.user?.pro_validity || null);
  const diffTime = expiryDate - today;
  const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24));

  return diffDays > 0 && diffDays <= 7;
});

// Check if subscription is expired
const isExpired = computed(() => {
  if (!user.value?.user?.is_pro || !user.value?.user?.pro_validity)
    return false;

  const today = new Date();
  const expiryDate = new Date(user.value.user.pro_validity);

  return today > expiryDate;
});

// Dismiss the warning for the current session
function dismissWarning() {
  warningDismissed.value = true;
  // Store in localStorage to remember dismissal
  localStorage.setItem("subscription_warning_dismissed", "true");
  localStorage.setItem(
    "subscription_warning_dismissed_date",
    new Date().toDateString()
  );
}

// Open the subscription renewal page
function renewSubscription() {
  openMenu.value = false; // Close any open menu
  router.push("/upgrade-to-pro");
}

// Check localStorage on mount to see if warning was dismissed
onMounted(() => {
  const storedDismissalDate = localStorage.getItem(
    "subscription_warning_dismissed_date"
  );
  if (storedDismissalDate) {
    // Only consider it dismissed if the stored date is from today
    const today = new Date().toDateString();
    warningDismissed.value = storedDismissalDate === today;
  } else {
    warningDismissed.value = false;
  }

  // Rest of your existing onMounted code...
});
const colorMode = useColorMode();
colorMode.preference = "light";
onMounted(() => {
  localStorage.setItem("nuxt-color-mode", "light");
});

async function getLogo() {
  const res = await get("/logo/");
  logo.value = res.data;
}
function upgradeToPro() {
  openMenu.value = false;
  router.push("/upgrade-to-pro");
}

function manageSubscription() {
  openMenu.value = false;
  router.push("/account/subscription");
}

function formatDate(date) {
  return new Date(date).toLocaleDateString(undefined, {
    year: "numeric",
    month: "short",
    day: "numeric",
  });
}
getLogo();

defineShortcuts({
  o: () => (open.value = !open.value),
});

const handleClickOutside = (event) => {
  const menuContainer = document.querySelector(".menu-container");
  if (menuContainer && !menuContainer.contains(event.target)) {
    openMenu.value = false;
  }
};

onMounted(() => {
  document.addEventListener("click", handleClickOutside);
});

onUnmounted(() => {
  document.removeEventListener("click", handleClickOutside);
});

// if sidebar clicked and route changes, close sidebar if opened
watch(router.currentRoute, () => {
  if (openMenu.value) {
    openMenu.value = false;
    isOpen.value = false;
  }
});

const isScrolled = ref(false);

// Function to handle scroll event
const handleScroll = () => {
  isScrolled.value = window.scrollY > 80;
};

// Add event listener on component mount
onMounted(() => {
  window.addEventListener("scroll", handleScroll);
  document.addEventListener("click", handleClickOutside);
});

// Clean up event listeners
onUnmounted(() => {
  window.removeEventListener("scroll", handleScroll);
  document.removeEventListener("click", handleClickOutside);
});

// Example logic for subscription warnings
onMounted(() => {
  const subscriptionEndDate = new Date(user?.user?.pro_validity);
  const currentDate = new Date();
  const timeDifference = subscriptionEndDate - currentDate;
  daysRemaining.value = Math.ceil(timeDifference / (1000 * 60 * 60 * 24));

  if (daysRemaining.value <= 7 && daysRemaining.value > 0) {
    shouldShowWarning.value = true;
  } else if (daysRemaining.value <= 0) {
    isExpired.value = true;
  }
});
</script>

<style scoped>
/* Add this style if you want to animate the transition */
.fixed {
  animation: slideDown 0.3s ease-in-out;
  width: 100%;
  max-width: 1280px;
}

@keyframes slideDown {
  from {
    transform: translateY(-100%);
  }
  to {
    transform: translateY(0);
  }
}
.text-2xs {
  font-size: 0.65rem;
  line-height: 1rem;
}

.fade-enter-active,
.fade-leave-active {
  transition: opacity 0.3s, transform 0.3s;
}

.fade-enter-from,
.fade-leave-to {
  opacity: 0;
  transform: translateY(-10px);
}

/* For extra small screens */
@media (max-width: 385px) {
  .xs\:block {
    display: block;
  }
}
@keyframes shimmer {
  0% {
    transform: translateX(-100%);
  }
  100% {
    transform: translateX(100%);
  }
}

.animate-shimmer {
  animation: shimmer 3s linear infinite;
}

.animate-pulse-slow {
  animation: pulse 3s cubic-bezier(0.4, 0, 0.6, 1) infinite;
}

@keyframes pulse {
  0%,
  100% {
    opacity: 1;
  }
  50% {
    opacity: 0.5;
  }
}
</style>
