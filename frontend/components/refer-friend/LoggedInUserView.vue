<template>
  <div class="py-12 px-4 relative">
    <!-- Subtle background effect -->
    <div class="absolute inset-0 overflow-hidden pointer-events-none -z-10">
      <div
        class="absolute top-1/4 left-1/4 w-64 h-64 rounded-full bg-primary-200/20 blur-3xl animate-float"
      ></div>
      <div
        class="absolute bottom-1/4 right-1/4 w-80 h-80 rounded-full bg-blue-200/20 blur-3xl animate-float-reverse"
      ></div>
    </div>

    <div class="container mx-auto max-w-4xl">
      <!-- Centered Header -->
      <div class="text-center mb-12 animate-fade-in">
        <h1
          class="text-2xl md:text-2xl font-semibold text-gray-800 dark:text-white mb-2"
        >
          {{ $t("refer_friend") }}
        </h1>
        <div
          class="h-1 w-24 bg-primary-500 mx-auto rounded-full mb-3 animate-width"
        ></div>
        <p class="text-xl text-gray-600 dark:text-gray-400">
          {{ $t("refer") }}
        </p>
      </div>

      <!-- Referral Link Box -->
      <div
        class="bg-white dark:bg-gray-800 rounded-xl p-6 mb-10 shadow-sm border border-gray-100 dark:border-gray-700 animate-fade-in-up"
      >
        <p class="text-center text-gray-600 dark:text-gray-600 mb-3">
          {{ $t("refer_text") }}
        </p>
        <div class="flex flex-col sm:flex-row gap-3">
          <UButtonGroup class="mx-auto w-full sm:w-96">
            <input
              type="text"
              class="text-xs py-1 px-0.5 w-full"
              :value="referralUrl"
              readonly
            />
            <UButton
              size="xs"
              color="primary"
              icon="i-iconamoon-copy-light"
              variant="solid"
              class="py-1 px-1.5 ml-2"
              @click="copyReferralLink"
              label="Copy"
            />
          </UButtonGroup>
        </div>

        <!-- Simple Social Share Icons -->
        <div class="flex justify-center items-center gap-4 mt-4">
          <UButton
            color="white"
            variant="ghost"
            class="social-btn h-10 w-10 flex items-center justify-center rounded-full transition-all duration-300"
            @click="shareOnSocial('facebook')"
          >
            <UIcon name="i-mdi:facebook" class="text-xl text-blue-600" />
          </UButton>

          <UButton
            color="white"
            variant="ghost"
            class="social-btn h-10 w-10 flex items-center justify-center rounded-full transition-all duration-300"
            @click="shareOnSocial('twitter')"
          >
            <UIcon name="i-mdi:twitter" class="text-xl text-blue-400" />
          </UButton>

          <UButton
            color="white"
            variant="ghost"
            class="social-btn h-10 w-10 flex items-center justify-center rounded-full transition-all duration-300"
            @click="shareOnSocial('whatsapp')"
          >
            <UIcon name="i-mdi:whatsapp" class="text-xl text-green-500" />
          </UButton>
          <UButton
            color="primary"
            variant="soft"
            class="h-10 px-4 flex items-center justify-center rounded-full transition-all duration-300"
            @click="showShareModal()"
          >
            <UIcon name="i-heroicons-share" class="text-lg mr-2" />
            <span class="text-sm">More</span>
          </UButton>
        </div>
      </div>
      <!-- Share Modal -->
      <Teleport to="body">
        <div
          v-if="props.showShareModal"
          class="fixed inset-0 top-14 z-50 overflow-y-auto"
          :class="{ 'animate-fade-in': props.showShareModal }"
          @click="hideShareModal()"
        >
          <div
            class="fixed inset-0 bg-gray-500 bg-opacity-75 transition-opacity backdrop-blur-sm"
            aria-hidden="true"
            @click="hideShareModal()"
          ></div>
          <div
            class="flex items-end justify-center min-h-screen pt-4 pb-20 text-center sm:block sm:p-0"
          >
            <div
              class="relative max-w-xl w-full mx-auto my-8 bg-white/95 dark:bg-slate-800/95 backdrop-blur-md rounded-xl shadow-sm border border-white/20 dark:border-slate-700/40 overflow-hidden"
              :class="{ 'animate-modal-slide-up': props.showShareModal }"
              @click.stop
            >
              <div
                class="w-full md:h-[75vh] overflow-hidden overflow-y-auto no-scrollbar"
              >
                <UCard>
                  <template #header>
                    <div class="flex items-center justify-between">
                      <h3 class="text-lg font-semibold">
                        Share Your Referral Link
                      </h3>
                      <UButton
                        color="gray"
                        variant="ghost"
                        icon="i-heroicons-x-mark"
                        @click="hideShareModal()"
                      />
                    </div>
                  </template>

                  <div class="space-y-6">
                    <!-- Copy Link Section -->
                    <div>
                      <label
                        class="text-sm font-medium text-gray-800 dark:text-gray-300 mb-2 block"
                      >
                        Your Referral Link
                      </label>
                      <div class="flex gap-2">
                        <UInput
                          :model-value="referralUrl"
                          readonly
                          class="flex-1 font-mono text-sm"
                          :disabled="!props.user?.user?.referral_code"
                        />
                        <UButton
                          color="primary"
                          icon="i-iconamoon-copy-light"
                          @click="copyReferralLink"
                          :disabled="!props.user?.user?.referral_code"
                        >
                          Copy
                        </UButton>
                      </div>
                    </div>
                    <!-- QR Code Section -->
                    <div class="text-center">
                      <label
                        class="text-sm font-medium text-gray-800 dark:text-gray-300 mb-2 block"
                      >
                        QR Code
                      </label>
                      <div
                        class="inline-block p-4 bg-white rounded-lg shadow-sm"
                      >
                        <img
                          v-if="props.user?.user?.referral_code"
                          :src="`https://api.qrserver.com/v1/create-qr-code/?size=150x150&data=${referralUrl}`"
                          alt="Referral QR Code"
                          class="w-32 h-32"
                          @error="handleQrCodeError"
                        />
                        <div
                          v-else
                          class="w-32 h-32 bg-gray-100 rounded flex items-center justify-center"
                        >
                          <UIcon
                            name="i-heroicons-qr-code"
                            class="text-4xl text-gray-400"
                          />
                        </div>
                      </div>
                      <p class="text-xs text-gray-600 mt-2">
                        Scan to open referral link
                      </p>
                    </div>

                    <!-- Social Share Grid -->
                    <div>
                      <label
                        class="text-sm font-medium text-gray-800 dark:text-gray-300 mb-3 block"
                      >
                        Share on Social Media
                      </label>
                      <div class="grid grid-cols-4 gap-3">
                        <UButton
                          color="white"
                          variant="outline"
                          class="h-16 flex flex-col items-center justify-center gap-1"
                          @click="$emit('share-on-social', 'facebook')"
                        >
                          <UIcon
                            name="i-mdi:facebook"
                            class="text-2xl text-blue-600"
                          />
                          <span class="text-xs">Facebook</span>
                        </UButton>

                        <UButton
                          color="white"
                          variant="outline"
                          class="h-16 flex flex-col items-center justify-center gap-1"
                          @click="$emit('share-on-social', 'twitter')"
                        >
                          <UIcon
                            name="i-mdi:twitter"
                            class="text-2xl text-blue-400"
                          />
                          <span class="text-xs">Twitter</span>
                        </UButton>

                        <UButton
                          color="white"
                          variant="outline"
                          class="h-16 flex flex-col items-center justify-center gap-1"
                          @click="$emit('share-on-social', 'whatsapp')"
                        >
                          <UIcon
                            name="i-mdi:whatsapp"
                            class="text-2xl text-green-500"
                          />
                          <span class="text-xs">WhatsApp</span>
                        </UButton>

                        <UButton
                          color="white"
                          variant="outline"
                          class="h-16 flex flex-col items-center justify-center gap-1"
                          @click="$emit('share-on-social', 'linkedin')"
                        >
                          <UIcon
                            name="i-mdi:linkedin"
                            class="text-2xl text-blue-700"
                          />
                          <span class="text-xs">LinkedIn</span>
                        </UButton>
                      </div>
                    </div>

                    <!-- Custom Message -->
                    <div>
                      <label
                        class="text-sm font-medium text-gray-800 dark:text-gray-300 mb-2 block"
                      >
                        Custom Message
                      </label>
                      <UTextarea
                        :model-value="props.customMessage"
                        @input="$emit('update:custom-message', $event)"
                        placeholder="Add a personal message to your referral..."
                        rows="3"
                      />
                    </div>
                  </div>
                  <template #footer>
                    <div class="flex justify-end gap-2">
                      <UButton
                        color="gray"
                        variant="ghost"
                        @click="hideShareModal()"
                      >
                        Close
                      </UButton>
                      <UButton
                        color="primary"
                        @click="$emit('share-custom-message')"
                      >
                        Share with Message
                      </UButton>
                    </div>
                  </template>
                </UCard>
              </div>
            </div>
          </div>
        </div>
      </Teleport>

      <!-- The Two Stats Cards -->
      <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
        <!-- Total Referred Users Card -->
        <div
          class="stat-card bg-white dark:bg-gray-800 p-6 rounded-xl shadow-sm flex items-center gap-4 border border-gray-100 dark:border-gray-700 transform transition-all duration-300 users-card"
        >
          <div
            class="stat-icon-wrapper h-14 w-14 rounded-full flex items-center justify-center bg-primary-100 dark:bg-primary-900/40"
          >
            <UIcon
              name="i-heroicons-users"
              class="text-xl text-primary-600 dark:text-primary-400"
            />
          </div>
          <div class="flex-1">
            <h3
              class="text-sm text-gray-600 dark:text-gray-600 font-medium mb-1"
            >
              Total Referred Users
            </h3>
            <div
              class="text-2xl font-semibold text-gray-800 dark:text-white flex items-center"
            >
              <span class="counter-animate" data-value="87">
                {{ props.user.user.refer_count }}
              </span>
            </div>
          </div>
        </div>

        <!-- Total Earnings Card -->
        <div
          class="stat-card bg-white dark:bg-gray-800 p-6 rounded-xl shadow-sm flex items-center gap-4 border border-gray-100 dark:border-gray-700 transform transition-all duration-300 hover:shadow-sm hover:transform hover:-translate-y-1 earnings-card"
        >
          <div
            class="stat-icon-wrapper h-14 w-14 rounded-full flex items-center justify-center bg-primary-100 dark:bg-primary-900/40"
          >
            <UIcon
              name="i-heroicons-banknotes"
              class="text-xl text-green-600 dark:text-green-400"
            />
          </div>
          <div class="flex-1">
            <h3
              class="text-sm text-gray-600 dark:text-gray-600 font-medium mb-1"
            >
              Total Earnings
            </h3>
            <div
              class="text-2xl font-semibold text-gray-800 dark:text-white flex items-center"
            >
              <UIcon name="i-mdi:currency-bdt" class="mr-0.5" />
              <span class="counter-animate" data-value="2450">
                {{ props.user.user.commission_earned }}
              </span>
            </div>
            <div class="text-xs mt-1">
              <span class="text-green-500 flex items-center">
                <UIcon name="i-heroicons-arrow-trending-up" class="mr-1" />
                <span v-if="growthRate > 0"
                  >+{{ growthRate.toFixed(1) }}% this month</span
                >
              </span>
            </div>
          </div>
        </div>
      </div>

      <!-- Commission Breakdown Section -->
      <div class="mt-8 mb-8">
        <h3 class="text-lg font-semibold text-gray-800 dark:text-white mb-4">
          Commission Breakdown by Service
        </h3>

        <div
          v-if="isLoadingCommissions"
          class="grid grid-cols-1 md:grid-cols-3 gap-4"
        >
          <div
            v-for="i in 3"
            :key="i"
            class="bg-white dark:bg-gray-800 rounded-xl p-6 shadow-sm border border-gray-100 dark:border-gray-700"
          >
            <USkeleton class="h-4 w-3/4 mb-2" />
            <USkeleton class="h-3 w-1/2 mb-4" />
            <USkeleton class="h-8 w-full" />
          </div>
        </div>

        <div
          v-else-if="commissionError"
          class="bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800 rounded-xl p-6 text-center"
        >
          <UIcon
            name="i-heroicons-exclamation-triangle"
            class="text-red-500 text-2xl mb-2"
          />
          <p class="text-red-600 dark:text-red-400">{{ commissionError }}</p>
          <UButton
            @click="getCommissionHistory"
            color="red"
            variant="soft"
            size="sm"
            class="mt-3"
          >
            Try Again
          </UButton>
        </div>

        <div v-else class="grid grid-cols-1 md:grid-cols-3 gap-4">
          <div
            v-for="service in commissionBreakdown"
            :key="service.type"
            class="bg-white dark:bg-gray-800 rounded-xl p-6 shadow-sm border border-gray-100 dark:border-gray-700 hover:shadow-md transition-all duration-300"
          >
            <div class="flex items-center justify-between mb-4">
              <div class="flex items-center">
                <div
                  class="h-10 w-10 rounded-full flex items-center justify-center"
                  :class="{
                    'bg-blue-100 dark:bg-blue-900/50': service.color === 'blue',
                    'bg-purple-100 dark:bg-purple-900/50':
                      service.color === 'purple',
                    'bg-yellow-100 dark:bg-yellow-900/50':
                      service.color === 'yellow',
                  }"
                >
                  <UIcon
                    :name="service.icon"
                    :class="{
                      'text-lg text-blue-600 dark:text-blue-400':
                        service.color === 'blue',
                      'text-lg text-purple-600 dark:text-purple-400':
                        service.color === 'purple',
                      'text-lg text-yellow-600 dark:text-yellow-400':
                        service.color === 'yellow',
                    }"
                  />
                </div>
                <div class="ml-3">
                  <h4 class="text-sm font-medium text-gray-800 dark:text-white">
                    {{ service.name }}
                  </h4>
                  <p class="text-xs text-gray-600 dark:text-gray-400">
                    {{ service.rate }} commission
                  </p>
                </div>
              </div>
              <UBadge :color="service.color" variant="soft" size="sm">
                {{ service.count }}
                {{ service.count === 1 ? "referral" : "referrals" }}
              </UBadge>
            </div>
            <div class="flex items-center justify-between">
              <span class="text-xs text-gray-600 dark:text-gray-400"
                >Total Earned</span
              >
              <div
                class="text-lg font-semibold text-gray-800 dark:text-white flex items-center"
              >
                <UIcon name="i-mdi:currency-bdt" class="mr-0.5 text-sm" />
                {{ service.amount.toFixed(2) }}
              </div>
            </div>
          </div>
        </div>
      </div>
      <!-- Getting Started Guide for new users -->
      <div
        v-if="!isLoadingCommissions && commissionData.total_commissions === 0"
        class="mt-8 mb-8"
      >
        <div
          class="bg-gradient-to-r from-primary-50 to-blue-50 dark:from-primary-900/20 dark:to-blue-900/20 rounded-xl p-6 border border-primary-200 dark:border-primary-800"
        >
          <div class="flex items-start">
            <div class="flex-shrink-0">
              <UIcon
                name="i-heroicons-light-bulb"
                class="text-primary-600 dark:text-primary-400 text-2xl"
              />
            </div>
            <div class="ml-4 flex-1">
              <h4
                class="text-lg font-semibold text-primary-800 dark:text-primary-200 mb-2"
              >
                Get Started with Referrals!
              </h4>
              <p class="text-primary-700 dark:text-primary-300 mb-4">
                You haven't made any referrals yet. Start earning commissions by
                sharing your referral link with friends and family.
              </p>
              <div class="grid grid-cols-1 md:grid-cols-3 gap-4 text-sm">
                <div
                  class="flex items-center text-primary-600 dark:text-primary-400"
                >
                  <UIcon name="i-heroicons-currency-dollar" class="mr-2" />
                  <span>Earn up to 20% commission</span>
                </div>
                <div
                  class="flex items-center text-primary-600 dark:text-primary-400"
                >
                  <UIcon name="i-heroicons-users" class="mr-2" />
                  <span>Help friends save money</span>
                </div>
                <div
                  class="flex items-center text-primary-600 dark:text-primary-400"
                >
                  <UIcon name="i-heroicons-clock" class="mr-2" />
                  <span>Quick 24hr payouts</span>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- Advanced Analytics Section -->
      <div v-if="commissionData.total_commissions > 0" class="mt-8 mb-8">
        <h3 class="text-lg font-semibold text-gray-800 dark:text-white mb-4">
          Performance Analytics
        </h3>

        <div class="grid grid-cols-2 md:grid-cols-4 gap-4">
          <div
            class="bg-white dark:bg-gray-800 rounded-xl p-4 shadow-sm border border-gray-100 dark:border-gray-700"
          >
            <div class="flex items-center justify-between">
              <div>
                <p class="text-xs text-gray-600 dark:text-gray-400">
                  Conversion Rate
                </p>
                <p class="text-lg font-semibold text-gray-800 dark:text-white">
                  {{ conversionRate.toFixed(1) }}%
                </p>
              </div>
              <UIcon
                name="i-heroicons-chart-bar"
                class="text-blue-500 text-xl"
              />
            </div>
          </div>

          <div
            class="bg-white dark:bg-gray-800 rounded-xl p-4 shadow-sm border border-gray-100 dark:border-gray-700"
          >
            <div class="flex items-center justify-between">
              <div>
                <p class="text-xs text-gray-600 dark:text-gray-400">
                  Avg Commission
                </p>
                <p class="text-lg font-semibold text-gray-800 dark:text-white">
                  ৳{{ averageCommission.toFixed(2) }}
                </p>
              </div>
              <UIcon
                name="i-heroicons-calculator"
                class="text-blue-500 text-xl"
              />
            </div>
          </div>

          <div
            class="bg-white dark:bg-gray-800 rounded-xl p-4 shadow-sm border border-gray-100 dark:border-gray-700"
          >
            <div class="flex items-center justify-between">
              <div>
                <p class="text-xs text-gray-600 dark:text-gray-400">
                  Best Performing
                </p>
                <p class="text-lg font-semibold text-gray-800 dark:text-white">
                  {{ bestPerformingService }}
                </p>
              </div>
              <UIcon
                name="i-heroicons-trophy"
                class="text-yellow-500 text-xl"
              />
            </div>
          </div>

          <div
            class="bg-white dark:bg-gray-800 rounded-xl p-4 shadow-sm border border-gray-100 dark:border-gray-700"
          >
            <div class="flex items-center justify-between">
              <div>
                <p class="text-xs text-gray-600 dark:text-gray-400">
                  This Month
                </p>
                <p class="text-lg font-semibold text-gray-800 dark:text-white">
                  ৳{{ thisMonthEarnings.toFixed(2) }}
                </p>
              </div>
              <UIcon
                name="i-heroicons-calendar"
                class="text-green-500 text-xl"
              />
            </div>
          </div>

          <div
            class="bg-white dark:bg-gray-800 rounded-xl p-4 shadow-sm border border-gray-100 dark:border-gray-700"
          >
            <div class="flex items-center justify-between">
              <div>
                <p class="text-xs text-gray-600 dark:text-gray-400">
                  Growth Rate
                </p>
                <p
                  class="text-lg font-semibold"
                  :class="
                    growthRate >= 0
                      ? 'text-green-600 dark:text-green-400'
                      : 'text-red-600 dark:text-red-400'
                  "
                >
                  {{ growthRate >= 0 ? "+" : "" }}{{ growthRate.toFixed(1) }}%
                </p>
              </div>
              <UIcon
                :name="
                  growthRate >= 0
                    ? 'i-heroicons-arrow-trending-up'
                    : 'i-heroicons-arrow-trending-down'
                "
                :class="growthRate >= 0 ? 'text-green-500' : 'text-red-500'"
                class="text-xl"
              />
            </div>
          </div>
        </div>
      </div>

      <!-- Replace both history sections with this single tabbed component -->
      <div class="mt-12">
        <div
          class="bg-white dark:bg-gray-800 rounded-xl shadow-sm border border-gray-100 dark:border-gray-700 overflow-hidden animate-fade-in-up"
          style="animation-delay: 0.2s"
        >
          <div class="tab-navigation overflow-hidden relative">
            <div class="flex border-b border-gray-100 dark:border-gray-700">
              <button
                v-for="(tab, index) in tabs"
                :key="index"
                class="tab-button relative py-4 px-6 font-medium text-sm transition-all duration-300"
                :class="
                  activeTab === index
                    ? 'text-primary-600 dark:text-primary-400 border-b-2 border-green-500'
                    : 'text-gray-600 dark:text-gray-600 hover:text-gray-800 dark:hover:text-gray-400 border-b-2 border-white'
                "
                @click="setActiveTab(index)"
              >
                <div class="flex items-center">
                  <UIcon
                    :name="tab.icon"
                    class="mr-2 transition-transform duration-300"
                  />
                  {{ tab.name }}
                  <span
                    v-if="tab.count"
                    class="ml-2 px-2 py-0.5 text-xs rounded-full bg-gray-100 dark:bg-gray-700 text-gray-800 dark:text-gray-400"
                  >
                    {{ tab.count }}
                  </span>
                </div>
              </button>
            </div>
          </div>

          <div
            class="p-4 border-b border-gray-100 dark:border-gray-700 flex justify-between items-center"
          >
            <div class="text-xs text-gray-600 dark:text-gray-600">
              {{
                activeTab === 0
                  ? "Track your earning commissions"
                  : "View your referred users"
              }}
            </div>

            <div class="flex items-center gap-2">
              <UButton
                :loading="
                  activeTab === 0 ? isLoadingCommissions : isLoadingUsers
                "
                @click="
                  activeTab === 0 ? getCommissionHistory() : getReferredUsers()
                "
                color="gray"
                variant="ghost"
                size="sm"
                icon="i-heroicons-arrow-path"
              >
                Refresh
              </UButton>

              <UButton
                v-if="activeTab === 0 && filteredEarnings.length > 0"
                @click="exportCommissions"
                color="primary"
                variant="ghost"
                size="sm"
                icon="i-heroicons-arrow-down-tray"
              >
                Export
              </UButton>
              <USelect
                v-if="activeTab === 0"
                :value="filterPeriod"
                @update:modelValue="$emit('update:filter-period', $event)"
                :options="['All Time', 'This Month', 'Last Month']"
                placeholder="Period"
                size="sm"
                class="w-32"
              />
            </div>
          </div>

          <div class="min-h-[300px] relative overflow-hidden">
            <div
              class="tab-pane transition-all duration-500"
              :class="
                activeTab === 0
                  ? 'opacity-100 translate-x-0'
                  : 'opacity-0 absolute top-0 translate-x-full'
              "
            >
              <div class="overflow-x-auto">
                <table
                  class="min-w-full divide-y divide-gray-200 dark:divide-gray-700"
                >
                  <thead class="bg-gray-50 dark:bg-gray-800/50">
                    <tr>
                      <th
                        class="px-6 py-3 text-left text-xs font-medium text-gray-600 dark:text-gray-600 uppercase tracking-wider"
                      >
                        Date
                      </th>
                      <th
                        class="px-6 py-3 text-left text-xs font-medium text-gray-600 dark:text-gray-600 uppercase tracking-wider"
                      >
                        Referred User
                      </th>
                      <th
                        class="px-6 py-3 text-left text-xs font-medium text-gray-600 dark:text-gray-600 uppercase tracking-wider"
                      >
                        Service Type
                      </th>
                      <th
                        class="px-6 py-3 text-left text-xs font-medium text-gray-600 dark:text-gray-600 uppercase tracking-wider"
                      >
                        Rate
                      </th>
                      <th
                        class="px-6 py-3 text-left text-xs font-medium text-gray-600 dark:text-gray-600 uppercase tracking-wider"
                      >
                        Amount
                      </th>
                    </tr>
                  </thead>
                  <tbody
                    class="bg-white dark:bg-gray-800 divide-y divide-gray-200 dark:divide-gray-700"
                  >
                    <!-- Loading Skeleton -->
                    <tr
                      v-if="isLoadingCommissions"
                      v-for="i in 5"
                      :key="'loading-' + i"
                      class="animate-pulse"
                    >
                      <td class="px-6 py-4 whitespace-nowrap">
                        <USkeleton class="h-4 w-20" />
                      </td>
                      <td class="px-6 py-4 whitespace-nowrap">
                        <div class="flex items-center">
                          <USkeleton class="h-8 w-8 rounded-full mr-3" />
                          <USkeleton class="h-4 w-24" />
                        </div>
                      </td>
                      <td class="px-6 py-4 whitespace-nowrap">
                        <USkeleton class="h-6 w-20 rounded-full" />
                      </td>
                      <td class="px-6 py-4 whitespace-nowrap">
                        <USkeleton class="h-4 w-12" />
                      </td>
                      <td class="px-6 py-4 whitespace-nowrap">
                        <USkeleton class="h-4 w-16" />
                      </td>
                    </tr>

                    <!-- Actual Data -->
                    <tr
                      v-if="!isLoadingCommissions"
                      v-for="(earning, index) in filteredEarnings"
                      :key="index"
                      class="hover:bg-gray-50 dark:hover:bg-gray-700/50 transition-all table-row-animate"
                      :style="`--delay: ${index * 0.05}s`"
                    >
                      <td
                        class="px-6 py-4 whitespace-nowrap text-sm text-gray-600 dark:text-gray-600"
                      >
                        {{ formatDate(earning.date) }}
                      </td>
                      <td class="px-6 py-4 whitespace-nowrap">
                        <div class="flex items-center">
                          <div
                            class="ml-3 text-sm font-medium text-gray-800 dark:text-gray-200"
                          >
                            {{ earning.name }}
                          </div>
                        </div>
                      </td>

                      <td class="px-6 py-4 whitespace-nowrap">
                        <UBadge
                          :color="
                            getServiceTypeColor(
                              earning.type_code || 'gig_completion'
                            )
                          "
                          variant="soft"
                          size="sm"
                        >
                          {{ earning.task }}
                        </UBadge>
                      </td>

                      <td
                        class="px-6 py-4 whitespace-nowrap text-sm text-gray-600 dark:text-gray-600"
                      >
                        {{
                          getCommissionRate(
                            earning.type_code || "gig_completion"
                          )
                        }}
                      </td>

                      <td class="px-6 py-4 whitespace-nowrap">
                        <div
                          class="text-sm font-medium text-green-600 dark:text-green-400 flex items-center"
                        >
                          <UIcon name="i-mdi:currency-bdt" class="mr-0.5" />
                          {{ earning.amount.toFixed(2) }}
                        </div>
                      </td>
                    </tr>
                    <tr
                      v-if="
                        !isLoadingCommissions && filteredEarnings.length === 0
                      "
                    >
                      <td
                        colspan="5"
                        class="px-6 py-8 text-center text-gray-600 dark:text-gray-600"
                      >
                        <div class="py-6">
                          <div
                            class="w-16 h-16 mx-auto bg-gray-100 dark:bg-gray-800 rounded-full flex items-center justify-center mb-4"
                          >
                            <UIcon
                              name="i-heroicons-banknotes"
                              class="text-2xl text-gray-600 dark:text-gray-600"
                            />
                          </div>
                          <p>No earnings history to display yet.</p>
                          <UButton
                            class="mt-3"
                            color="primary"
                            size="sm"
                            @click="showShareModal()"
                          >
                            Invite Friends
                          </UButton>
                        </div>
                      </td>
                    </tr>
                  </tbody>
                </table>
              </div>
            </div>

            <!-- Referred Users Tab -->
            <div
              class="tab-pane transition-all duration-500"
              :class="
                activeTab === 1
                  ? 'opacity-100 translate-x-0'
                  : 'opacity-0 absolute top-0 translate-x-full'
              "
            >
              <div class="overflow-x-auto">
                <table
                  class="min-w-full divide-y divide-gray-200 dark:divide-gray-700"
                >
                  <thead class="bg-gray-50 dark:bg-gray-800/50">
                    <tr>
                      <th
                        class="px-6 py-3 text-left text-xs font-medium text-gray-600 dark:text-gray-600 uppercase tracking-wider"
                      >
                        User
                      </th>
                      <th
                        class="px-6 py-3 text-left text-xs font-medium text-gray-600 dark:text-gray-600 uppercase tracking-wider"
                      >
                        Email
                      </th>

                      <th
                        class="px-6 py-3 text-left text-xs font-medium text-gray-600 dark:text-gray-600 uppercase tracking-wider"
                      >
                        Status
                      </th>
                    </tr>
                  </thead>
                  <tbody
                    class="bg-white dark:bg-gray-800 divide-y divide-gray-200 dark:divide-gray-700"
                  >
                    <tr
                      v-for="(user, index) in referredUsers"
                      :key="user.id"
                      class="hover:bg-gray-50 dark:hover:bg-gray-700/50 transition-all table-row-animate"
                      :style="`--delay: ${index * 0.05}s`"
                    >
                      <td class="px-6 py-4 whitespace-nowrap">
                        <div class="flex items-center">
                          <div
                            v-if="!user.image"
                            class="h-8 w-8 rounded-full bg-primary-100 dark:bg-primary-900/50 flex items-center justify-center text-primary-700 dark:text-primary-300 font-medium user-avatar"
                          >
                            {{
                              (user.first_name || user.name || "User").charAt(0)
                            }}
                          </div>
                          <UAvatar
                            v-else
                            :src="user.image || '/static/frontend/avatar.png'"
                            size="sm"
                            class="user-avatar"
                          />
                          <div
                            class="ml-3 text-sm font-medium text-gray-800 dark:text-gray-200"
                          >
                            <div>
                              {{ user.first_name }} {{ user.last_name }}
                            </div>
                          </div>
                        </div>
                      </td>
                      <td
                        class="px-6 py-4 whitespace-nowrap text-sm text-gray-600 dark:text-gray-600"
                      >
                        {{ user.email }}
                      </td>

                      <td class="px-6 py-4 whitespace-nowrap">
                        <UBadge
                          :color="user.is_active ? 'green' : 'gray'"
                          variant="soft"
                          size="sm"
                        >
                          {{ user.is_active ? "Active" : "Inactive" }}
                        </UBadge>
                      </td>
                    </tr>

                    <tr v-if="referredUsers.length === 0">
                      <td
                        colspan="4"
                        class="px-6 py-8 text-center text-gray-600 dark:text-gray-600"
                      >
                        <div class="py-6">
                          <div
                            class="w-16 h-16 mx-auto bg-gray-100 dark:bg-gray-800 rounded-full flex items-center justify-center mb-4"
                          >
                            <UIcon
                              name="i-heroicons-users"
                              class="text-2xl text-gray-600 dark:text-gray-600"
                            />
                          </div>
                          <p>You haven't referred any users yet.</p>
                          <UButton
                            class="mt-3"
                            color="primary"
                            size="sm"
                            @click="showShareModal()"
                          >
                            Invite Friends
                          </UButton>
                        </div>
                      </td>
                    </tr>
                  </tbody>
                </table>
              </div>
            </div>
          </div>

          <div
            class="px-6 py-3 border-t border-gray-100 dark:border-gray-700 bg-gray-50 dark:bg-gray-800/50 flex justify-between items-center"
          >
            <div class="text-xs text-gray-600 dark:text-gray-600">
              {{
                activeTab === 0
                  ? `Showing ${filteredEarnings.length} transactions`
                  : `Showing ${referredUsers.length} referred users`
              }}
            </div>
            <UPagination
              v-if="
                (activeTab === 0 && filteredEarnings.length > 5) ||
                (activeTab === 1 && referredUsers.length > 5)
              "
              :model-value="currentPage"
              @update:model-value="$emit('update:current-page', $event)"
              :page-count="2"
              :total="
                activeTab === 0 ? filteredEarnings.length : referredUsers.length
              "
              size="xs"
              class="pagination-control"
            />
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { computed } from "vue";

const props = defineProps({
  user: {
    type: Object,
    required: true,
  },
  showShareModal: {
    type: Boolean,
    default: false,
  },
  customMessage: {
    type: String,
    default: "",
  },
  isLoadingCommissions: {
    type: Boolean,
    default: false,
  },
  isLoadingUsers: {
    type: Boolean,
    default: false,
  },
  commissionError: {
    type: String,
    default: null,
  },
  usersError: {
    type: String,
    default: null,
  },
  commissionBreakdown: {
    type: Array,
    default: () => [],
  },
  commissionData: {
    type: Object,
    default: () => ({}),
  },
  tabs: {
    type: Array,
    default: () => [],
  },
  activeTab: {
    type: Number,
    default: 0,
  },
  earnings: {
    type: Array,
    default: () => [],
  },
  referredUsers: {
    type: Array,
    default: () => [],
  },
  filteredEarnings: {
    type: Array,
    default: () => [],
  },
  filterPeriod: {
    type: String,
    default: "All Time",
  },
  currentPage: {
    type: Number,
    default: 1,
  },
  conversionRate: {
    type: Number,
    default: 0,
  },
  averageCommission: {
    type: Number,
    default: 0,
  },
  bestPerformingService: {
    type: String,
    default: "N/A",
  },
  thisMonthEarnings: {
    type: Number,
    default: 0,
  },
  growthRate: {
    type: Number,
    default: 0,
  },
});

const emit = defineEmits([
  "update:show-share-modal",
  "update:custom-message",
  "update:filter-period",
  "update:current-page",
  "copy-to-clip",
  "share-on-social",
  "share-custom-message",
  "get-commission-history",
  "get-referred-users",
  "set-active-tab",
  "export-commissions",
  "format-date",
  "get-service-type-color",
  "get-commission-rate",
]);

// Computed property for the referral URL
const referralUrl = computed(() => {
  if (!props.user?.user?.referral_code) return "";
  return `https://adsyclub.com/auth/register/?ref=${props.user.user.referral_code}`;
});

// Method to copy the referral link
function copyReferralLink() {
  if (referralUrl.value) {
    emit("copy-to-clip", referralUrl.value);
  }
}

// Method for sharing on social platforms
function shareOnSocial(platform) {
  emit("share-on-social", platform);
}

// Method to handle errors with QR code loading
function handleQrCodeError(event) {
  console.error("Error loading QR code:", event);
  // Replace the broken image with the QR code icon as fallback
  if (event.target) {
    event.target.style.display = "none";
    const parent = event.target.parentElement;
    if (parent) {
      const fallback = document.createElement("div");
      fallback.className =
        "w-32 h-32 bg-gray-100 rounded flex items-center justify-center";
      fallback.innerHTML =
        '<div class="text-4xl text-gray-400"><svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" d="M3.75 4.875c0-.621.504-1.125 1.125-1.125h4.5c.621 0 1.125.504 1.125 1.125v4.5c0 .621-.504 1.125-1.125 1.125h-4.5A1.125 1.125 0 013.75 9.375v-4.5zM3.75 14.625c0-.621.504-1.125 1.125-1.125h4.5c.621 0 1.125.504 1.125 1.125v4.5c0 .621-.504 1.125-1.125 1.125h-4.5a1.125 1.125 0 01-1.125-1.125v-4.5zM13.5 4.875c0-.621.504-1.125 1.125-1.125h4.5c.621 0 1.125.504 1.125 1.125v4.5c0 .621-.504 1.125-1.125 1.125h-4.5A1.125 1.125 0 0113.5 9.375v-4.5z" /><path stroke-linecap="round" stroke-linejoin="round" d="M6.75 6.75h.75v.75h-.75v-.75zM6.75 16.75h.75v.75h-.75v-.75zM16.5 6.75h.75v.75h-.75v-.75z" /></svg></div>';
      parent.appendChild(fallback);
    }
  }
}

// Method to handle tab changes
function setActiveTab(index) {
  emit("set-active-tab", index);
}

// Method to get commission history
function getCommissionHistory() {
  emit("get-commission-history");
}

// Method to get referred users
function getReferredUsers() {
  emit("get-referred-users");
}

// Method to export commissions
function exportCommissions() {
  emit("export-commissions");
}

// Method to format date
function formatDate(date) {
  return emit("format-date", date);
}

// Method to get service type color
function getServiceTypeColor(typeCode) {
  return emit("get-service-type-color", typeCode);
}

// Method to get commission rate
function getCommissionRate(typeCode) {
  return emit("get-commission-rate", typeCode);
}

// Method to show share modal
function showShareModal() {
  console.log("showShareModal called, emitting update:show-share-modal");
  // Update custom message with current referral link
  if (referralUrl.value) {
    emit(
      "update:custom-message",
      `Join on AdsyClub to start earning & build social connectivity! Use my referral link to get started: ${referralUrl.value}`
    );
  }
  emit("update:show-share-modal", true);
}

// Method to hide share modal
function hideShareModal() {
  console.log("hideShareModal called, emitting update:show-share-modal");
  emit("update:show-share-modal", false);
}
</script>

<style scoped>
.no-scrollbar::-webkit-scrollbar {
  display: none;
}
/* Hide scrollbar for IE, Edge and Firefox */
.no-scrollbar {
  -ms-overflow-style: none; /* IE and Edge */
  scrollbar-width: none; /* Firefox */
}
</style>
