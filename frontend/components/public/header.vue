<template>
  <div
    class="py-3 z-[99999999] bg-slate-100/80 shadow-sm md:shadow-md rounded-2xl mx-2 dark:bg-black max-w-[1280px] md:mx-auto"
    :class="
      isScrolled
        ? 'fixed top-0 left-0 right-0 mx-auto backdrop-blur-sm border-b border-slate-200/50 rounded-none'
        : 'sticky'
    "
  >
    <UContainer>
      <div>
        <!-- Pre-expiration Warning (Closable, shown 7 days before expiration) -->
        <transition name="fade">
          <div
            v-if="shouldShowWarning && !warningDismissed"
            class="mx-auto my-2 md:my-4 relative overflow-hidden rounded-lg md:rounded-xl border border-amber-300 dark:border-amber-800 group transition-all duration-300 hover:shadow-lg"
          >
            <!-- Enhanced glassmorphism background -->
            <div
              class="absolute inset-0 bg-gradient-to-r from-amber-50/90 via-amber-50/80 to-amber-100/90 dark:from-amber-900/40 dark:via-amber-800/30 dark:to-amber-900/40 backdrop-blur-md"
            ></div>

            <!-- Premium pattern overlay -->
            <div
              class="absolute inset-0 bg-[url('/img/patterns/dots.svg')] bg-repeat opacity-[0.03] group-hover:opacity-[0.05] transition-opacity"
            ></div>

            <!-- Enhanced light effects -->
            <div
              class="absolute -top-24 -left-24 w-48 h-48 bg-gradient-to-br from-amber-200/30 to-yellow-300/20 dark:from-amber-500/20 dark:to-yellow-500/10 rounded-full blur-xl group-hover:scale-110 transition-transform duration-700"
            ></div>
            <div
              class="absolute -bottom-24 -right-24 w-48 h-48 bg-gradient-to-tl from-amber-300/20 to-yellow-200/20 dark:from-amber-500/10 dark:to-yellow-500/10 rounded-full blur-xl group-hover:scale-110 transition-transform duration-700"
            ></div>

            <div
              class="relative z-10 p-2.5 sm:p-4 flex flex-col sm:flex-row items-center sm:items-start gap-2 sm:gap-4"
            >
              <!-- Enhanced warning icon with pulse effect (shown on all screen sizes) -->
              <div class="relative mb-1 sm:mb-0">
                <div
                  class="w-10 h-10 sm:w-12 sm:h-12 rounded-full bg-gradient-to-br from-amber-50 via-amber-100 to-amber-200 dark:from-amber-900 dark:via-amber-800 dark:to-amber-700 border border-amber-300 dark:border-amber-600/70 flex items-center justify-center shadow-inner group-hover:shadow-amber-300/30 dark:group-hover:shadow-amber-700/30 transition-shadow duration-300"
                >
                  <UIcon
                    name="i-heroicons-clock"
                    class="w-5 h-5 sm:w-6 sm:h-6 text-amber-600 dark:text-amber-400 group-hover:scale-110 transition-transform"
                  />
                </div>
                <div
                  class="absolute -inset-1 bg-amber-400/30 blur-md rounded-full animate-pulse-slow opacity-70 group-hover:opacity-90"
                ></div>
              </div>

              <!-- Enhanced alert content -->
              <div class="flex-1 text-center sm:text-left">
                <h3
                  class="text-xs sm:text-sm font-semibold text-amber-800 dark:text-amber-300 flex flex-wrap items-center justify-center sm:justify-start gap-1 sm:gap-1.5"
                >
                  <UIcon
                    name="i-heroicons-sparkles"
                    class="w-3 h-3 sm:w-4 sm:h-4 animate-pulse-subtle"
                  />
                  <span class="whitespace-normal">{{
                    $t("subscription_expiring_soon")
                  }}</span>
                  <span
                    class="ml-0 sm:ml-1 mt-1 sm:mt-0 text-2xs sm:text-xs px-1.5 sm:px-2 py-0.5 bg-gradient-to-r from-amber-200/90 to-amber-300/90 dark:from-amber-700/90 dark:to-amber-600/90 text-amber-800 dark:text-amber-100 rounded-full font-medium backdrop-blur-sm shadow-sm"
                  >
                    {{ daysRemaining }}
                    {{ daysRemaining === 1 ? $t("day_left") : $t("days_left") }}
                  </span>
                </h3>
                <p
                  class="text-2xs sm:text-xs text-amber-700 dark:text-amber-400 mt-1 max-w-md px-2 sm:px-0"
                >
                  {{ $t("subscription_renewal_message") }}
                </p>
              </div>

              <div class="flex items-center gap-2 mt-2 sm:mt-0">
                <!-- Mobile renewal button -->
                <UButton
                  @click="renewSubscription"
                  color="amber"
                  size="xs"
                  variant="soft"
                  class="sm:hidden"
                >
                  {{ $t("renew_now") }}
                </UButton>

                <!-- Dismiss button with enhanced hover effect -->
                <UButton
                  @click="dismissWarning"
                  color="amber"
                  variant="ghost"
                  size="xs"
                  icon="i-heroicons-x-mark"
                  class="!p-1.5 hover:bg-amber-200/50 dark:hover:bg-amber-800/50 hover:rotate-90 transition-all duration-300"
                  aria-label="Dismiss"
                />
              </div>
            </div>

            <!-- Hidden desktop renewal link -->
            <div class="hidden sm:block relative z-10 pb-2 text-center">
              <button
                @click="renewSubscription"
                class="text-xs font-medium text-amber-700 dark:text-amber-300 hover:text-amber-600 dark:hover:text-amber-200 underline underline-offset-2 decoration-amber-400/50 dark:decoration-amber-500/50 transition-colors"
              >
                {{ $t("renew_now") }} →
              </button>
            </div>

            <!-- Enhanced bottom border animation -->
            <div
              class="absolute bottom-0 left-0 h-0.5 bg-gradient-to-r from-amber-300 via-yellow-400 to-amber-300 w-full transform-gpu animate-shimmer"
            ></div>
          </div>
        </transition>

        <!-- Post-expiration Alert (Not Closable) -->
        <transition name="fade">
          <div
            v-if="isExpired"
            class="mx-auto my-2 md:my-4 relative overflow-hidden rounded-lg md:rounded-xl border border-red-400 dark:border-red-700 group transition-all duration-300 shadow-lg sm:shadow-xl"
          >
            <!-- Enhanced glassmorphism background -->
            <div
              class="absolute inset-0 bg-gradient-to-br from-red-50/90 via-red-50/80 to-red-100/90 dark:from-red-900/40 dark:via-red-800/40 dark:to-red-900/40 backdrop-blur-md"
            ></div>

            <!-- Premium pattern overlay -->
            <div
              class="absolute inset-0 bg-[url('/img/patterns/circuit.svg')] bg-center opacity-[0.04] group-hover:opacity-[0.06] transition-opacity"
            ></div>

            <!-- Enhanced light effects -->
            <div
              class="absolute -top-32 -right-32 w-80 h-80 bg-gradient-to-br from-red-200/30 to-orange-300/20 dark:from-red-500/20 dark:to-orange-500/10 rounded-full blur-xl transform-gpu animate-pulse-slow"
            ></div>
            <div
              class="absolute -bottom-32 -left-32 w-80 h-80 bg-gradient-to-tl from-red-300/20 to-rose-200/20 dark:from-red-600/10 dark:to-rose-500/10 rounded-full blur-xl transform-gpu animate-pulse-slow animation-delay-1000"
            ></div>

            <!-- Animated shimmer effect -->
            <div
              class="absolute inset-y-0 -inset-x-1/2 w-full bg-gradient-to-r from-transparent via-red-200/20 dark:via-red-400/10 to-transparent skew-x-12 transform-gpu animate-shine"
            ></div>

            <div
              class="relative z-10 p-3 sm:p-5 flex flex-col items-center gap-3 sm:gap-4"
            >
              <!-- Enhanced warning icon with alert effect -->
              <div class="relative">
                <div
                  class="w-14 h-14 sm:w-16 sm:h-16 rounded-full bg-gradient-to-br from-red-50 via-red-100 to-red-200 dark:from-red-900 dark:via-red-800 dark:to-red-700 border border-red-300 dark:border-red-600/70 flex items-center justify-center shadow-inner shadow-red-300/30 dark:shadow-red-900/30"
                >
                  <UIcon
                    name="i-heroicons-exclamation-triangle"
                    class="w-7 h-7 sm:w-8 sm:h-8 text-red-600 dark:text-red-400 animate-pulse-subtle"
                  />
                </div>
                <div
                  class="absolute -inset-2 bg-red-400/30 blur-md rounded-full animate-pulse opacity-70 group-hover:opacity-90"
                ></div>

                <!-- Extra warning circles -->
                <div
                  class="absolute inset-0 rounded-full border-2 border-dashed border-red-400/30 dark:border-red-600/30 animate-spin-slow"
                ></div>
                <div
                  class="absolute inset-0 rounded-full border-4 border-dashed border-red-400/10 dark:border-red-600/10 animate-spin-slow-reverse"
                ></div>
              </div>

              <!-- Enhanced alert content -->
              <div class="flex-1 text-center w-full max-w-md">
                <h3
                  class="text-sm sm:text-base font-bold text-red-800 dark:text-red-300 flex items-center justify-center gap-1.5 mb-1"
                >
                  <UIcon
                    name="i-heroicons-no-symbol"
                    class="w-4 h-4 sm:w-5 sm:h-5 animate-pulse"
                  />
                  {{ $t("subscription_expired") }}
                </h3>
                <p
                  class="text-xs sm:text-sm text-red-700 dark:text-red-400 px-2 sm:px-0"
                >
                  {{ $t("subscription_expired_message") }}
                </p>
              </div>

              <!-- Enhanced renewal button with premium effect -->
              <div class="mt-1 sm:mt-2 w-full sm:max-w-[200px]">
                <div class="relative group/btn">
                  <!-- Improved button glow effect -->
                  <div
                    class="absolute -inset-0.5 bg-gradient-to-r from-red-500 via-orange-500 to-red-500 rounded-lg blur opacity-60 group-hover/btn:opacity-100 transition duration-500 group-hover/btn:duration-200 animate-gradient-x"
                  ></div>

                  <UButton
                    @click="renewSubscription"
                    class="relative w-full bg-gradient-to-br from-red-600 to-red-700 hover:from-red-500 hover:to-red-600 text-white border-0 shadow-lg group-hover/btn:shadow-xl transition-all duration-300 group-hover/btn:scale-[1.03]"
                    size="sm"
                    block
                  >
                    <template #leading>
                      <UIcon
                        name="i-heroicons-shield-check"
                        class="w-4 h-4 sm:w-5 sm:h-5 mr-1 group-hover/btn:scale-110 transition-transform"
                      />
                    </template>
                    <span class="relative inline-block text-xs sm:text-sm">
                      {{ $t("renew_now") }}
                      <span
                        class="absolute bottom-0 left-0 w-full h-0.5 bg-white/40 transform scale-x-0 group-hover/btn:scale-x-100 transition-transform origin-left duration-300"
                      ></span>
                    </span>
                  </UButton>
                </div>
              </div>
            </div>

            <!-- Enhanced bottom border animation -->
            <div
              class="absolute bottom-0 left-0 h-0.5 sm:h-1 bg-gradient-to-r from-red-400 via-orange-500 to-red-400 w-full transform-gpu animate-shimmer"
            ></div>

            <!-- Corner accent (hidden on small screens) -->
            <div
              class="absolute top-0 right-0 w-16 h-16 overflow-hidden hidden sm:block"
            >
              <div
                class="absolute top-0 right-0 transform translate-x-1/2 -translate-y-1/2 rotate-45 bg-gradient-to-br from-red-400 to-red-600 w-4 h-16 blur-sm"
              ></div>
            </div>
          </div>
        </transition>
      </div>
      <!-- <PublicDonation /> -->
      <USlideover
        v-model="isOpen"
        side="left"
        :ui="{
          width: 'w-screen max-w-[270px]',
        }"
      >
        <UCard
          :ui="{
            header: {
              padding: 'pb-0.5',
            },
            ring: '',
            rounded: '',
            shadow: '',
          }"
        >
          <template #header>
            <div class="w-full flex justify-end">
              <UButton
                color="gray"
                variant="ghost"
                icon="i-heroicons-x-mark-20-solid"
                class="-my-1"
                @click="isOpen = false"
              />
            </div>
          </template>
        </UCard>
        <PublicLogo :logo="logo" class="text-center mx-auto mb-4" />
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
            inactive: 'after:hidden before:hidden',
            active: 'after:hidden before:hidden',
            padding: 'py-2',
          }"
        />
        <PublicTranslateHandler class="px-2 mt-3" />
      </USlideover>
      <div class="flex items-center justify-between gap-3 lg:gap-6">
        <div class="block md:hidden">
          <UButton
            @click="isOpen = true"
            icon="i-ci-hamburger-md"
            variant="outline"
            color="gray"
          />
        </div>
        <PublicLogo :logo="logo" class="max-sm:mr-auto" />
        <div class="hidden md:block">
          <UHorizontalNavigation
            :links="[
              {
                label: $t('home'),
                to: '/',
                icon: 'i-heroicons-home',
              },
              {
                label: $t('classified_service'),
                to: '/#classified-services',
                icon: 'i-heroicons-clipboard-document-list',
              },
              {
                label: $t('earn_money'),
                to: '/#micro-gigs',
                icon: 'i-healthicons:money-bag-outline',
              },
              {
                label: $t('faq'),
                to: '/faq',
                icon: 'i-streamline:interface-help-question-circle-circle-faq-frame-help-info-mark-more-query-question',
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
            to="/auth/login/"
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
            <template #trailing>
              <UIcon name="i-heroicons-arrow-right-20-solid" class="w-5 h-5" />
            </template>
          </UButton>
        </div>
        <div v-else class="flex relative menu-container">
          <PublicTranslateHandler class="px-2 max-sm:hidden" />
          <div class="mr-2" v-if="user && user.user">
            <UButton
              icon="i-ic:twotone-qr-code-scanner"
              size="md"
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

                <h3 class="text-2xl font-semibold text-green-700">AdsyPay</h3>
                <h3 class="text-xl font-semibold">Scan My QR Code</h3>
                <div class="border p-4 rounded-lg shadow-md bg-white">
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
              size: {
                sm: 'text-sm',
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

            Hi {{ (user?.user?.first_name).slice(0, 12) }}
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
              class="backdrop-blur-lg bg-white/95 dark:bg-slate-800/95 rounded-2xl shadow-xl border border-slate-200/50 dark:border-slate-700/50 overflow-hidden"
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
                  class="relative rounded-xl overflow-hidden border border-slate-200 dark:border-slate-700 group transition-all duration-300 hover:shadow-md hover:border-primary-200 dark:hover:border-primary-800/50"
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
                          class="text-xs font-medium text-slate-600 dark:text-slate-300"
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
                          class="font-medium text-slate-800 dark:text-white text-sm flex items-center"
                        >
                          {{ $t("upgrade_pro") }}
                          <span
                            class="ml-1.5 inline-flex items-center justify-center w-4 h-4 bg-gradient-to-r from-amber-400 to-amber-500 rounded-full text-[8px] text-white font-bold transform group-hover:scale-110 transition-transform"
                          >
                            +
                          </span>
                        </h4>
                        <p
                          class="text-xs text-slate-600 dark:text-slate-400 mt-0.5 max-w-[180px]"
                        >
                          {{ $t("upgrade_pro_text") }}
                        </p>
                      </div>

                      <!-- Enhanced Switch Toggle Design -->
                      <div
                        class="w-11 h-6 rounded-full bg-gradient-to-r from-slate-200 to-slate-300 dark:from-slate-700 dark:to-slate-600 p-0.5 flex items-center cursor-pointer relative overflow-hidden group-hover:from-indigo-400 group-hover:to-purple-500 transition-all duration-300"
                      >
                        <div
                          class="absolute left-0.5 w-5 h-5 rounded-full bg-white shadow-md transform transition-all duration-500 group-hover:translate-x-5"
                        ></div>
                      </div>
                    </div>
                  </div>
                </div>

                <!-- Pro User Version -->
                <div
                  v-else
                  class="relative rounded-xl overflow-hidden border border-indigo-200 dark:border-indigo-800/40 group transition-all duration-300 hover:shadow-md"
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
                        <h4 class="font-medium text-slate-800 dark:text-white">
                          {{ $t("pro_member") }}
                        </h4>
                        <p
                          class="text-xs text-slate-600 dark:text-slate-400 mt-0.5 flex items-center"
                        >
                          Valid until {{ formatDate(user?.user?.pro_validity) }}
                        </p>
                      </div>

                      <!-- Active premium switch style -->
                      <div
                        class="w-11 h-6 rounded-full bg-gradient-to-r from-indigo-400 to-blue-500 p-0.5 flex items-center justify-end cursor-pointer shadow-inner"
                      >
                        <div
                          class="w-5 h-5 rounded-full bg-white shadow-md transform transition-transform"
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
                        label: t('ad'),
                        to: '/my-classified-services/',
                        icon: 'i-heroicons-megaphone',
                        color: 'text-emerald-600 dark:text-emerald-400',
                        bg: 'from-emerald-100 to-emerald-50 dark:from-emerald-900/30 dark:to-emerald-900/10',
                        border: 'border-emerald-200 dark:border-emerald-800/30',
                        badge: {
                          show: true,
                          type: 'free',
                          text: 'FREE',
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
                          text: 'PRO',
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
                        label: $t('upload_center'),
                        icon: 'material-symbols:drive-folder-upload-outline-sharp',
                        to: '/upload-center',
                        color: 'text-amber-600 dark:text-amber-400',
                        bg: 'from-amber-100 to-amber-50 dark:from-amber-900/30 dark:to-amber-900/10',
                        border: 'border-amber-200 dark:border-amber-800/30',
                      },
                      {
                        label: $t('mobile_recharge'),
                        to: '/mobile-recharge',
                        icon: 'i-uil-mobile-vibrate',
                        color: 'text-orange-600 dark:text-orange-400',
                        bg: 'from-orange-100 to-orange-50 dark:from-orange-900/30 dark:to-orange-900/10',
                        border: 'border-orange-200 dark:border-orange-800/30',
                      },
                      {
                        label: $t('refer_friend'),
                        to: '/refer-a-friend',
                        icon: 'i-solar-users-group-rounded-broken',
                        color: 'text-purple-600 dark:text-purple-400',
                        bg: 'from-purple-100 to-purple-50 dark:from-purple-900/30 dark:to-purple-900/10',
                        border: 'border-purple-200 dark:border-purple-800/30',
                      },
                    ]"
                    :key="index"
                    :to="link.to"
                    class="flex flex-col items-center justify-center py-3 px-2 rounded-xl border bg-gradient-to-br transition-all duration-300 group text-center relative hover:shadow-md hover:-translate-y-0.5 cursor-pointer"
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
                        class="bg-gradient-to-r from-slate-400 to-slate-500 text-white text-[8px] font-bold px-1.5 py-0.5 rounded-full"
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
                        class="bg-gradient-to-r from-indigo-500 to-blue-600 text-white text-[8px] font-bold px-1.5 py-0.5 rounded-full flex items-center"
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
                    to="/contact-us"
                    class="flex items-center gap-2 py-2 px-3 rounded-lg text-slate-700 dark:text-slate-300 hover:bg-slate-100 dark:hover:bg-slate-700/50 transition-colors group"
                    @click="openMenu = false"
                  >
                    <div
                      class="w-7 h-7 rounded-full bg-slate-100 dark:bg-slate-800 flex items-center justify-center group-hover:bg-slate-200 dark:group-hover:bg-slate-700 transition-colors"
                    >
                      <UIcon
                        name="i-heroicons-question-mark-circle"
                        class="w-4 h-4 text-slate-500 dark:text-slate-400"
                      />
                    </div>
                    <span class="text-sm">{{ $t("support") }}</span>
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

const colorMode = useColorMode();
colorMode.preference = "light";
onMounted(() => {
  localStorage.setItem("nuxt-color-mode", "light");
});

import { ref, computed } from "vue";

// Props to receive subscription data from parent component
const props = defineProps({
  expirationDate: {
    type: [Date, String],
    required: true,
  },
  isExpired: {
    type: Boolean,
    default: false,
  },
});

// Emit events to parent component
const emit = defineEmits(["renew"]);

// State
const warningDismissed = ref(false);
const showWarning = ref(true);

// Computed properties
const daysRemaining = computed(() => {
  if (!user.value?.user?.pro_validity) return 0;

  const today = new Date();
  const expiryDate = new Date(user.value.user.pro_validity);

  // Calculate days difference
  const diffTime = expiryDate - today;
  const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24));

  // Only return positive days and cap at 7 for display purposes
  return diffDays > 0 ? Math.min(diffDays, 7) : 0;
});

const shouldShowWarning = computed(() => {
  if (!user.value?.user?.pro_validity) return false;

  const today = new Date();
  const expiryDate = new Date(user.value.user.pro_validity);
  const diffTime = expiryDate - today;
  const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24));

  // Only show warning in the last 7 days before expiration
  return diffDays > 0 && diffDays <= 27;
});

// Methods
const dismissWarning = () => {
  warningDismissed.value = true;
  // You might want to store this in localStorage to persist across page refreshes
  localStorage.setItem("subscription_warning_dismissed", "true");
};

const renewSubscription = () => {
  emit("renew");
};

// Check if warning was previously dismissed (on component mount)
if (typeof window !== "undefined") {
  const dismissed = localStorage.getItem("subscription_warning_dismissed");
  if (dismissed === "true") {
    warningDismissed.value = true;
  }
}
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
/* Custom animations */
@keyframes shimmer {
  0% {
    background-position: -200% 0;
  }
  100% {
    background-position: 200% 0;
  }
}

.animate-shimmer {
  animation: shimmer 3s infinite linear;
  background-size: 200% 100%;
}

@keyframes pulse-slow {
  0%,
  100% {
    opacity: 0.4;
  }
  50% {
    opacity: 0.8;
  }
}

.animate-pulse-slow {
  animation: pulse-slow 3s infinite ease-in-out;
}

@keyframes pulse-subtle {
  0%,
  100% {
    opacity: 0.7;
  }
  50% {
    opacity: 1;
  }
}

.animate-pulse-subtle {
  animation: pulse-subtle 4s infinite ease-in-out;
}

/* Transition effects */
.fade-enter-active,
.fade-leave-active {
  transition: opacity 0.5s ease, transform 0.5s ease;
}

.fade-enter-from,
.fade-leave-to {
  opacity: 0;
  transform: translateY(-10px);
}
</style>

<style>
/* Add this to your global CSS if not already present */
.bg-grid-amber-500\/\[0\.03\] {
  background-image: linear-gradient(
      to right,
      rgba(245, 158, 11, 0.03) 1px,
      transparent 1px
    ),
    linear-gradient(to bottom, rgba(245, 158, 11, 0.03) 1px, transparent 1px);
  background-size: 20px 20px;
}
@keyframes shine {
  0% {
    left: -100%;
    opacity: 0;
  }
  50% {
    opacity: 0.5;
  }
  100% {
    left: 100%;
    opacity: 0;
  }
}

.animate-shine {
  animation: shine 3s ease-in-out infinite;
}

@keyframes spin-slow {
  0% {
    transform: rotate(0deg);
  }
  100% {
    transform: rotate(360deg);
  }
}

.animate-spin-slow {
  animation: spin-slow 12s linear infinite;
}

.animate-spin-slow-reverse {
  animation: spin-slow 18s linear infinite reverse;
}

@keyframes gradient-x {
  0%,
  100% {
    background-position: 0% 50%;
  }
  50% {
    background-position: 100% 50%;
  }
}

.animate-gradient-x {
  animation: gradient-x 3s ease infinite;
  background-size: 200% 200%;
}

.animation-delay-1000 {
  animation-delay: 1s;
}
.text-2xs {
  font-size: 0.65rem;
  line-height: 1rem;
}
</style>
