<template>
  <div
    class="py-3 sticky z-50 top-2 bg-slate-100/80 shadow-sm md:shadow-md rounded-2xl mx-2 mt-2 dark:bg-black max-w-[1280px] md:mx-auto"
  >
    <UContainer>
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
              <div class="p-5 relative overflow-hidden">
                <!-- Background pattern -->
                <div
                  class="absolute inset-0 bg-grid-slate-100 dark:bg-grid-slate-700/30 opacity-20"
                ></div>

                <div class="relative z-10">
                  <div class="flex items-center gap-4">
                    <!-- Enhanced Avatar -->
                    <div class="relative group">
                      <div
                        class="w-14 h-14 rounded-xl bg-gradient-to-br from-primary-50 to-primary-200 dark:from-primary-900/40 dark:to-primary-800/60 border-2 border-white dark:border-slate-700 shadow-md flex items-center justify-center text-xl font-bold text-primary-600 dark:text-primary-400 transform transition-all duration-300 group-hover:rotate-3 group-hover:scale-105"
                      >
                        {{
                          user?.user?.first_name
                            ? user.user.first_name[0].toUpperCase()
                            : "U"
                        }}
                      </div>

                      <!-- KYC Badge with animation -->
                      <div
                        v-if="user?.user?.kyc"
                        class="absolute -bottom-1 -right-1 bg-white dark:bg-slate-800 rounded-full p-0.5 shadow-lg transform transition-all duration-300 group-hover:scale-110 group-hover:rotate-6"
                      >
                        <div
                          class="bg-gradient-to-br from-blue-500 to-blue-600 rounded-full px-2 py-0.5"
                        >
                          <UIcon
                            name="i-heroicons-check"
                            class="w-3 h-3 text-white"
                          />
                        </div>
                      </div>
                    </div>

                    <!-- User Info with improved typography -->
                    <div class="flex-1 min-w-0">
                      <h3
                        class="font-semibold text-base text-slate-800 dark:text-white truncate"
                      >
                        {{ user?.user?.first_name }} {{ user?.user?.last_name }}
                      </h3>
                      <div class="flex items-center mt-0.5">
                        <p
                          class="text-xs text-slate-500 dark:text-slate-400 truncate"
                        >
                          {{ user?.user?.email }}
                        </p>
                        <span
                          v-if="user?.user?.is_pro"
                          class="ml-2 inline-flex items-center px-1.5 py-0.5 rounded-full text-xs font-medium bg-gradient-to-r from-indigo-500 to-blue-500 text-white"
                        >
                          <UIcon
                            name="i-heroicons-sparkles"
                            class="w-3 h-3 mr-0.5 text-yellow-200"
                          />
                          {{ $t("pro") }}
                        </span>
                      </div>
                    </div>
                  </div>

                  <!-- Account Balance Indicator (New feature) -->
                  <div
                    class="mt-4 bg-gradient-to-r from-slate-50 to-slate-100 dark:from-slate-800 dark:to-slate-800/60 rounded-lg p-3 border border-slate-200/80 dark:border-slate-700/80 group hover:shadow-md transition-all duration-300"
                  >
                    <div class="flex justify-between items-center">
                      <div class="flex items-center gap-2">
                        <div
                          class="w-8 h-8 rounded-full bg-emerald-100 dark:bg-emerald-900/30 flex items-center justify-center"
                        >
                          <UIcon
                            name="i-heroicons-banknotes"
                            class="w-4 h-4 text-emerald-600 dark:text-emerald-400"
                          />
                        </div>
                        <div>
                          <div
                            class="text-xs text-slate-500 dark:text-slate-400"
                          >
                            {{ $t("balance") }}
                          </div>
                          <div
                            class="font-semibold text-slate-800 dark:text-white"
                          >
                            ৳{{ user?.user?.balance || "0.00" }}
                          </div>
                        </div>
                      </div>
                      <UButton
                        size="xs"
                        color="primary"
                        to="/deposit-withdraw"
                        class="bg-gradient-to-r from-emerald-500 to-green-600 border-0 opacity-90 hover:opacity-100"
                      >
                        {{ $t("add_funds") }}
                      </UButton>
                    </div>
                  </div>
                </div>
              </div>

              <!-- Membership Section -->
              <div
                class="px-4 pb-3"
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
</script>
