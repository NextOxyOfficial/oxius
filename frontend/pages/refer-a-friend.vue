<template>
  <div>
    <div v-if="user?.user" class="py-12 px-4 relative">
      <!-- Subtle background effect -->
      <div class="absolute inset-0 overflow-hidden pointer-events-none -z-10">
        <div
          class="absolute top-1/4 left-1/4 w-64 h-64 rounded-full bg-primary-200/20 blur-3xl animate-float"
        ></div>
        <div
          class="absolute bottom-1/4 right-1/4 w-80 h-80 rounded-full bg-blue-200/20 blur-3xl animate-float-reverse"
        ></div>
      </div>

      <div class="container mx-auto max-w-3xl">
        <!-- Centered Header -->
        <div class="text-center mb-12 animate-fade-in">
          <h1
            class="text-3xl md:text-4xl font-bold text-gray-900 dark:text-white mb-2"
          >
            {{ $t("refer_friend") }}
          </h1>
          <div
            class="h-1 w-24 bg-primary-500 mx-auto rounded-full mb-3 animate-width"
          ></div>
          <p class="text-xl text-gray-600 dark:text-gray-300">
            {{ $t("refer") }}
          </p>
        </div>

        <!-- Referral Link Box -->
        <div
          class="bg-white dark:bg-gray-800 rounded-xl p-6 mb-10 shadow-md border border-gray-100 dark:border-gray-700 animate-fade-in-up"
        >
          <p class="text-center text-gray-600 dark:text-gray-400 mb-3">
            {{ $t("refer_text") }}
          </p>

          <div class="flex flex-col sm:flex-row gap-3">
            <UButtonGroup class="mx-auto">
              <input
                type="text"
                class="text-xs py-1 px-0.5 w-40 sm:w-72"
                :value="`https://adsyclub.com/auth/register/?ref=${user.user.referral_code}`"
              />
              <UButton
                size="xs"
                color="primary"
                icon="i-iconamoon-copy-light"
                variant="solid"
                class="py-1 px-1.5 ml-2"
                @click="
                  CopyToClip(
                    `https://adsyclub.com/auth/register/?ref=${user.user.referral_code}`
                  )
                "
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
          </div>
        </div>

        <!-- The Two Stats Cards -->
        <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
          <!-- Total Referred Users Card -->
          <div
            class="stat-card bg-white dark:bg-gray-800 p-6 rounded-xl shadow-md flex items-center gap-4 border border-gray-100 dark:border-gray-700 transform transition-all duration-300 users-card"
          >
            <div
              class="stat-icon-wrapper h-14 w-14 rounded-full flex items-center justify-center bg-primary-100 dark:bg-primary-900/40"
            >
              <UIcon
                name="i-heroicons-users"
                class="text-2xl text-primary-600 dark:text-primary-400"
              />
            </div>
            <div class="flex-1">
              <h3
                class="text-sm text-gray-500 dark:text-gray-400 font-medium mb-1"
              >
                Total Referred Users
              </h3>
              <div
                class="text-3xl font-bold text-gray-900 dark:text-white flex items-center"
              >
                <span class="counter-animate" data-value="87">
                  {{ user.user.refer_count }}
                </span>
              </div>
              <!-- <div class="text-xs mt-1">
                <span class="text-green-500 flex items-center">
                  <UIcon name="i-heroicons-arrow-trending-up" class="mr-1" />
                  12% this month
                </span>
              </div> -->
            </div>
          </div>

          <!-- Total Earnings Card -->
          <div
            class="stat-card bg-white dark:bg-gray-800 p-6 rounded-xl shadow-md flex items-center gap-4 border border-gray-100 dark:border-gray-700 transform transition-all duration-300 hover:shadow-lg hover:transform hover:-translate-y-1 earnings-card"
          >
            <div
              class="stat-icon-wrapper h-14 w-14 rounded-full flex items-center justify-center bg-primary-100 dark:bg-primary-900/40"
            >
              <UIcon
                name="i-heroicons-banknotes"
                class="text-2xl text-green-600 dark:text-green-400"
              />
            </div>
            <div class="flex-1">
              <h3
                class="text-sm text-gray-500 dark:text-gray-400 font-medium mb-1"
              >
                Total Earnings
              </h3>
              <div
                class="text-3xl font-bold text-gray-900 dark:text-white flex items-center"
              >
                <UIcon name="i-mdi:currency-bdt" class="mr-0.5" />
                <span class="counter-animate" data-value="2450">
                  {{ user.user.commission_earned }}
                </span>
              </div>
              <!-- <div class="text-xs mt-1">
                <span class="text-green-500 flex items-center">
                  <UIcon name="i-heroicons-arrow-trending-up" class="mr-1" />
                  8% from last month
                </span>
              </div> -->
            </div>
          </div>
        </div>

        <!-- Replace both history sections with this single tabbed component -->
        <!-- <div class="mt-12">
          <div
            class="bg-white dark:bg-gray-800 rounded-xl shadow-md border border-gray-100 dark:border-gray-700 overflow-hidden animate-fade-in-up"
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
                      : 'text-gray-500 dark:text-gray-400 hover:text-gray-700 dark:hover:text-gray-300 border-b-2 border-white'
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
                      class="ml-2 px-2 py-0.5 text-xs rounded-full bg-gray-100 dark:bg-gray-700 text-gray-700 dark:text-gray-300"
                    >
                      {{ tab.count }}
                    </span>
                  </div>
                </button>
              </div>

              
              <div
                :class="
                  activeTab === index
                    ? `absolute bottom-0 h-0.5 bg-primary-500 dark:bg-primary-400 transition-all duration-300`
                    : ''
                "
                :style="{
                  left: indicatorLeft + 'px',
                  width: indicatorWidth + 'px',
                }"
              ></div>
            </div>

            
            <div
              class="p-4 border-b border-gray-100 dark:border-gray-700 flex justify-between items-center"
            >
              <div class="text-xs text-gray-500 dark:text-gray-400">
                {{
                  activeTab === 0
                    ? "View your referred users"
                    : "Track your earning commissions"
                }}
              </div>

              <div class="flex items-center gap-2">
                <UInput
                  v-if="activeTab === 0"
                  v-model="searchUser"
                  placeholder="Search users"
                  size="sm"
                  class="w-40 md:w-auto search-input"
                >
                  <template #leading>
                    <UIcon name="i-heroicons-magnifying-glass" />
                  </template>
                </UInput>

                <USelect
                  v-if="activeTab === 1"
                  v-model="filterPeriod"
                  :options="['All Time', 'This Month', 'Last Month']"
                  placeholder="Period"
                  size="sm"
                  class="w-32"
                />

                <UButton
                  size="sm"
                  color="gray"
                  variant="ghost"
                  class="text-sm action-btn"
                  :icon="
                    activeTab === 0
                      ? 'i-heroicons-user-plus'
                      : 'i-heroicons-arrow-down-tray'
                  "
                >
                  {{ activeTab === 0 ? "Invite" : "Export" }}
                </UButton>
              </div>
            </div>

            
            <div class="min-h-[300px] relative overflow-hidden">
              
              <div
                class="tab-pane transition-all duration-500"
                :class="
                  activeTab === 0
                    ? 'opacity-100 translate-x-0'
                    : 'opacity-0 absolute top-0 -translate-x-full'
                "
              >
                <div class="overflow-x-auto">
                  <table
                    class="min-w-full divide-y divide-gray-200 dark:divide-gray-700"
                  >
                    <thead class="bg-gray-50 dark:bg-gray-800/50">
                      <tr>
                        <th
                          class="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider"
                        >
                          User
                        </th>
                        <th
                          class="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider"
                        >
                          Join Date
                        </th>
                        <th
                          class="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider"
                        >
                          Status
                        </th>
                        <th
                          class="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider"
                        >
                          Activity
                        </th>
                      </tr>
                    </thead>
                    <tbody
                      class="bg-white dark:bg-gray-800 divide-y divide-gray-200 dark:divide-gray-700"
                    >
                      <tr
                        v-for="(user, index) in filteredUsers"
                        :key="user.id"
                        class="hover:bg-gray-50 dark:hover:bg-gray-700/50 transition-all table-row-animate"
                        :style="`--delay: ${index * 0.05}s`"
                      >
                        <td class="px-6 py-4 whitespace-nowrap">
                          <div class="flex items-center">
                            <div
                              class="h-8 w-8 rounded-full bg-primary-100 dark:bg-primary-900/50 flex items-center justify-center text-primary-700 dark:text-primary-300 font-medium overflow-hidden user-avatar"
                            >
                              {{ user.name.charAt(0) }}
                            </div>
                            <div class="ml-3">
                              <div
                                class="text-sm font-medium text-gray-900 dark:text-gray-100"
                              >
                                {{ user.name }}
                              </div>
                              <div
                                class="text-xs text-gray-500 dark:text-gray-400"
                              >
                                {{ user.email }}
                              </div>
                            </div>
                          </div>
                        </td>
                        <td
                          class="px-6 py-4 whitespace-nowrap text-sm text-gray-500 dark:text-gray-400"
                        >
                          {{ formatDate(user.joined) }}
                        </td>
                        <td class="px-6 py-4 whitespace-nowrap">
                          <span
                            :class="[
                              'px-2 py-1 inline-flex text-xs leading-5 font-semibold rounded-full',
                              user.active
                                ? 'bg-green-100 text-green-800 dark:bg-green-900/30 dark:text-green-400'
                                : 'bg-red-100 text-red-800 dark:bg-red-900/30 dark:text-red-400',
                            ]"
                          >
                            {{ user.active ? "Active" : "Inactive" }}
                          </span>
                        </td>
                        <td
                          class="px-6 py-4 whitespace-nowrap text-sm text-gray-500 dark:text-gray-400"
                        >
                          {{ user.lastActivity }}
                        </td>
                      </tr>

                      <tr v-if="filteredUsers.length === 0">
                        <td
                          colspan="4"
                          class="px-6 py-8 text-center text-gray-500 dark:text-gray-400"
                        >
                          <div class="py-6">
                            <div
                              class="w-16 h-16 mx-auto bg-gray-100 dark:bg-gray-800 rounded-full flex items-center justify-center mb-4"
                            >
                              <UIcon
                                name="i-heroicons-user-group"
                                class="text-3xl text-gray-400 dark:text-gray-500"
                              />
                            </div>
                            <p>No referred users found.</p>
                            <UButton class="mt-3" color="primary" size="sm"
                              >Invite Friends</UButton
                            >
                          </div>
                        </td>
                      </tr>
                    </tbody>
                  </table>
                </div>
              </div>

              
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
                          class="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider"
                        >
                          Date
                        </th>
                        <th
                          class="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider"
                        >
                          Referred User
                        </th>
                        <th
                          class="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider"
                        >
                          Task
                        </th>
                        <th
                          class="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider"
                        >
                          Amount
                        </th>
                      </tr>
                    </thead>
                    <tbody
                      class="bg-white dark:bg-gray-800 divide-y divide-gray-200 dark:divide-gray-700"
                    >
                      <tr
                        v-for="(earning, index) in filteredEarnings"
                        :key="index"
                        class="hover:bg-gray-50 dark:hover:bg-gray-700/50 transition-all table-row-animate"
                        :style="`--delay: ${index * 0.05}s`"
                      >
                        <td
                          class="px-6 py-4 whitespace-nowrap text-sm text-gray-500 dark:text-gray-400"
                        >
                          {{ formatDate(earning.date) }}
                        </td>
                        <td class="px-6 py-4 whitespace-nowrap">
                          <div class="flex items-center">
                            <div
                              class="h-8 w-8 rounded-full bg-primary-100 dark:bg-primary-900/50 flex items-center justify-center text-primary-700 dark:text-primary-300 font-medium user-avatar"
                            >
                              {{ earning.userName.charAt(0) }}
                            </div>
                            <div
                              class="ml-3 text-sm font-medium text-gray-900 dark:text-gray-100"
                            >
                              {{ earning.userName }}
                            </div>
                          </div>
                        </td>
                        <td
                          class="px-6 py-4 whitespace-nowrap text-sm text-gray-900 dark:text-gray-100"
                        >
                          {{ earning.task }}
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

                      <tr v-if="filteredEarnings.length === 0">
                        <td
                          colspan="4"
                          class="px-6 py-8 text-center text-gray-500 dark:text-gray-400"
                        >
                          <div class="py-6">
                            <div
                              class="w-16 h-16 mx-auto bg-gray-100 dark:bg-gray-800 rounded-full flex items-center justify-center mb-4"
                            >
                              <UIcon
                                name="i-heroicons-banknotes"
                                class="text-3xl text-gray-400 dark:text-gray-500"
                              />
                            </div>
                            <p>No earnings history to display yet.</p>
                            <UButton class="mt-3" color="primary" size="sm"
                              >Invite Friends</UButton
                            >
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
              <div class="text-xs text-gray-500 dark:text-gray-400">
                {{
                  activeTab === 0
                    ? `Showing ${filteredUsers.length} users`
                    : `Showing ${filteredEarnings.length} transactions`
                }}
              </div>

              <UPagination
                v-if="
                  (activeTab === 0 && filteredUsers.length > 5) ||
                  (activeTab === 1 && filteredEarnings.length > 5)
                "
                v-model="currentPage"
                :page-count="2"
                :total="
                  activeTab === 0
                    ? filteredUsers.length
                    : filteredEarnings.length
                "
                size="xs"
                class="pagination-control"
              />
            </div>
          </div>
        </div> -->
      </div>
    </div>

    <!-- public component -->
    <div v-else class="relative">
      <!-- Animated Background -->
      <div class="absolute inset-0 -z-10 overflow-hidden">
        <div
          class="absolute top-0 -left-40 w-[600px] h-[600px] rounded-full bg-gradient-to-br from-primary-100/30 to-primary-300/20 blur-3xl animate-float-slow"
        ></div>
        <div
          class="absolute bottom-0 -right-40 w-[600px] h-[600px] rounded-full bg-gradient-to-tr from-blue-100/30 to-green-200/20 blur-3xl animate-float-reverse"
        ></div>
        <div
          class="absolute inset-0 bg-[url('/noise-pattern.svg')] opacity-[0.02] pointer-events-none"
        ></div>
      </div>

      <div class="container mx-auto px-4 py-16 md:py-24">
        <!-- Hero Section -->
        <div class="max-w-4xl mx-auto text-center mb-20">
          <div
            class="inline-block mb-4 px-6 py-2 rounded-full bg-primary-50 dark:bg-primary-900/30 text-primary-600 dark:text-primary-400 font-medium text-sm"
          >
            Invite Friends & Earn Together
          </div>
          <h1
            class="text-4xl md:text-5xl lg:text-6xl font-bold mb-6 text-gray-900 dark:text-white tracking-tight animate-fade-in"
          >
            Get
            <span class="text-primary-600 dark:text-primary-400"
              >5% Commission</span
            >
            on Every Referral
          </h1>
          <p
            class="text-xl text-gray-600 dark:text-gray-300 mb-10 max-w-2xl mx-auto animate-fade-in-delayed"
          >
            Share your unique link with friends, and earn rewards when they
            complete tasks or make purchases. The more friends you refer, the
            more you earn!
          </p>
          <div class="flex flex-wrap justify-center gap-4">
            <UButton
              size="xl"
              color="primary"
              to="/register"
              class="cta-button"
            >
              Sign Up & Start Earning
              <template #trailing>
                <UIcon name="i-heroicons-arrow-right" />
              </template>
            </UButton>
            <UButton
              size="xl"
              color="gray"
              variant="soft"
              to="#how-it-works"
              class="cta-button-secondary"
            >
              Learn More
              <template #trailing>
                <UIcon name="i-heroicons-arrow-down" />
              </template>
            </UButton>
          </div>
        </div>

        <!-- How It Works Section -->
        <div id="how-it-works" class="max-w-6xl mx-auto mb-20 scroll-mt-20">
          <div class="text-center mb-12">
            <h2
              class="text-3xl md:text-4xl font-bold text-gray-900 dark:text-white mb-4"
            >
              How It Works
            </h2>
            <div
              class="h-1 w-20 bg-primary-500 mx-auto mb-6 rounded-full animate-expand"
            ></div>
            <p
              class="text-lg text-gray-600 dark:text-gray-300 max-w-2xl mx-auto"
            >
              Our referral program is simple, transparent, and rewarding. Just
              follow these easy steps:
            </p>
          </div>

          <div class="grid md:grid-cols-3 gap-8">
            <!-- Step 1 -->
            <div
              class="bg-white dark:bg-gray-800 rounded-xl p-8 shadow-md border border-gray-100 dark:border-gray-700 text-center step-card"
            >
              <div
                class="w-16 h-16 mx-auto mb-6 rounded-full bg-primary-100 dark:bg-primary-900/50 flex items-center justify-center"
              >
                <span
                  class="text-2xl font-bold text-primary-600 dark:text-primary-400"
                  >1</span
                >
              </div>
              <h3
                class="text-xl font-semibold mb-3 text-gray-900 dark:text-white"
              >
                Create Account
              </h3>
              <p class="text-gray-600 dark:text-gray-400">
                Sign up for a free account and get your unique referral link
                instantly.
              </p>
            </div>

            <!-- Step 2 -->
            <div
              class="bg-white dark:bg-gray-800 rounded-xl p-8 shadow-md border border-gray-100 dark:border-gray-700 text-center step-card"
            >
              <div
                class="w-16 h-16 mx-auto mb-6 rounded-full bg-primary-100 dark:bg-primary-900/50 flex items-center justify-center"
              >
                <span
                  class="text-2xl font-bold text-primary-600 dark:text-primary-400"
                  >2</span
                >
              </div>
              <h3
                class="text-xl font-semibold mb-3 text-gray-900 dark:text-white"
              >
                Share Your Link
              </h3>
              <p class="text-gray-600 dark:text-gray-400">
                Share your referral link with friends via email, social media,
                or messaging apps.
              </p>
            </div>

            <!-- Step 3 -->
            <div
              class="bg-white dark:bg-gray-800 rounded-xl p-8 shadow-md border border-gray-100 dark:border-gray-700 text-center step-card"
            >
              <div
                class="w-16 h-16 mx-auto mb-6 rounded-full bg-primary-100 dark:bg-primary-900/50 flex items-center justify-center"
              >
                <span
                  class="text-2xl font-bold text-primary-600 dark:text-primary-400"
                  >3</span
                >
              </div>
              <h3
                class="text-xl font-semibold mb-3 text-gray-900 dark:text-white"
              >
                Earn Commissions
              </h3>
              <p class="text-gray-600 dark:text-gray-400">
                Earn 5% commission when your friends complete tasks or make
                purchases.
              </p>
            </div>
          </div>
        </div>

        <!-- Stats Section -->
        <div class="max-w-6xl mx-auto mb-20">
          <div class="grid grid-cols-2 md:grid-cols-4 gap-4 md:gap-8">
            <div
              class="bg-white dark:bg-gray-800 rounded-xl p-6 shadow-md border border-gray-100 dark:border-gray-700 text-center stat-box"
            >
              <div
                class="text-3xl md:text-4xl font-bold text-primary-600 dark:text-primary-400 mb-2"
              >
                5%
              </div>
              <p class="text-sm md:text-base text-gray-600 dark:text-gray-400">
                Commission Rate
              </p>
            </div>

            <div
              class="bg-white dark:bg-gray-800 rounded-xl p-6 shadow-md border border-gray-100 dark:border-gray-700 text-center stat-box"
            >
              <div
                class="text-3xl md:text-4xl font-bold text-primary-600 dark:text-primary-400 mb-2"
              >
                500+
              </div>
              <p class="text-sm md:text-base text-gray-600 dark:text-gray-400">
                Active Referrers
              </p>
            </div>

            <div
              class="bg-white dark:bg-gray-800 rounded-xl p-6 shadow-md border border-gray-100 dark:border-gray-700 text-center stat-box"
            >
              <div
                class="text-3xl md:text-4xl font-bold text-primary-600 dark:text-primary-400 mb-2"
              >
                ৳ 10,000
              </div>
              <p class="text-sm md:text-base text-gray-600 dark:text-gray-400">
                Top Earner
              </p>
            </div>

            <div
              class="bg-white dark:bg-gray-800 rounded-xl p-6 shadow-md border border-gray-100 dark:border-gray-700 text-center stat-box"
            >
              <div
                class="text-3xl md:text-4xl font-bold text-primary-600 dark:text-primary-400 mb-2"
              >
                24hr
              </div>
              <p class="text-sm md:text-base text-gray-600 dark:text-gray-400">
                Quick Payouts
              </p>
            </div>
          </div>
        </div>

        <!-- CTA Section -->
        <div class="max-w-4xl mx-auto text-center">
          <div
            class="bg-gradient-to-r from-primary-500 to-primary-600 rounded-2xl p-8 md:p-12 shadow-xl cta-section"
          >
            <h2 class="text-2xl md:text-3xl font-bold text-white mb-4">
              Ready to Start Earning?
            </h2>
            <p class="text-white/90 mb-8 max-w-2xl mx-auto">
              Join our referral program today and turn your connections into
              cash. It's free to join and only takes a minute to get started.
            </p>
            <UButton
              size="xl"
              color="white"
              variant="solid"
              to="/register"
              class="cta-button-final"
            >
              Create Your Account
              <template #trailing>
                <UIcon name="i-heroicons-arrow-right" />
              </template>
            </UButton>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
definePageMeta({
  layout: "dashboard",
});

const { user } = useAuth();
const filterPeriod = ref("All Time");
const currentPage = ref(1);
const searchUser = ref("");
const activeTab = ref(0);
const indicatorLeft = ref(0);
const indicatorWidth = ref(0);

// Sample data for referred users
const referredUsers = ref([
  {
    id: 1,
    name: "Mohammad Rahman",
    email: "mrahman@example.com",
    joined: "2025-02-10T09:30:00",
    active: true,
    lastActivity: "2 days ago",
  },
  {
    id: 2,
    name: "Sakib Khan",
    email: "sakib@example.com",
    joined: "2025-02-15T14:20:00",
    active: true,
    lastActivity: "Today",
  },
  {
    id: 3,
    name: "Nusrat Jahan",
    email: "nusrat@example.com",
    joined: "2025-02-28T11:45:00",
    active: false,
    lastActivity: "1 week ago",
  },
]);

// Sample data for earnings history
const earnings = ref([
  {
    date: "2025-03-12T15:30:00",
    userName: "Mohammad Rahman",
    task: "Product Purchase",
    amount: 45.5,
  },
  {
    date: "2025-03-10T09:15:00",
    userName: "Sakib Khan",
    task: "Subscription",
    amount: 25.0,
  },
  {
    date: "2025-03-05T14:20:00",
    userName: "Mohammad Rahman",
    task: "Mobile App Download",
    amount: 15.0,
  },
  {
    date: "2025-02-28T10:45:00",
    userName: "Nusrat Jahan",
    task: "Website Sign Up",
    amount: 10.0,
  },
]);

// Define tabs with counts from actual data
const tabs = ref([
  {
    name: "Referred Users",
    icon: "i-heroicons-user-group",
    count: referredUsers.value.length,
  },
  {
    name: "Earnings",
    icon: "i-heroicons-banknotes",
    count: earnings.value.length,
  },
]);

function CopyToClip(text) {
  //Copy text to clipboard
  console.log(text);
  navigator.clipboard.writeText(text);
  toast.add({ title: "Link copied" });
}

// Share on social media
function shareOnSocial(platform) {
  let url = "";
  const text = "Join me and earn rewards! Use my referral link:";

  switch (platform) {
    case "facebook":
      url = `https://www.facebook.com/sharer/sharer.php?u=${encodeURIComponent(
        `https://adsyclub.com/auth/register/?ref=${user?.user?.referral_code}`
      )}`;
      break;
    case "twitter":
      url = `https://twitter.com/intent/tweet?url=${encodeURIComponent(
        `https://adsyclub.com/auth/register/?ref=${user?.user?.referral_code}`
      )}&text=${encodeURIComponent(text)}`;
      break;
    case "whatsapp":
      url = `https://wa.me/?text=${encodeURIComponent(
        text +
          " " +
          `https://adsyclub.com/auth/register/?ref=${user?.user?.referral_code}`
      )}`;
      break;
  }

  if (url) {
    window.open(url, "_blank");
  }
}

// Format date function
function formatDate(dateString) {
  return new Date(dateString).toLocaleDateString("en-US", {
    year: "numeric",
    month: "short",
    day: "numeric",
  });
}

// Set active tab and animate the indicator
function setActiveTab(index) {
  activeTab.value = index;
  updateIndicator();
}

// Update the tab indicator position and width
function updateIndicator() {
  const activeButton = document.querySelector(".tab-button.text-primary-600");
  if (activeButton) {
    const navRect = document
      .querySelector(".tab-navigation")
      ?.getBoundingClientRect();

    if (navRect) {
      indicatorLeft.value = activeButton.offsetLeft;
      indicatorWidth.value = activeButton.offsetWidth;
    }
  }
}

// Filter users by search query
const filteredUsers = computed(() => {
  if (!searchUser.value) return referredUsers.value;

  const search = searchUser.value.toLowerCase();
  return referredUsers.value.filter(
    (user) =>
      user.name.toLowerCase().includes(search) ||
      user.email.toLowerCase().includes(search)
  );
});

// Filter earnings by period
const filteredEarnings = computed(() => {
  if (filterPeriod.value === "All Time") return earnings.value;

  const now = new Date();
  if (filterPeriod.value === "This Month") {
    const startOfMonth = new Date(now.getFullYear(), now.getMonth(), 1);
    return earnings.value.filter(
      (earning) => new Date(earning.date) >= startOfMonth
    );
  } else if (filterPeriod.value === "Last Month") {
    const startOfLastMonth = new Date(now.getFullYear(), now.getMonth() - 1, 1);
    const startOfThisMonth = new Date(now.getFullYear(), now.getMonth(), 1);
    return earnings.value.filter(
      (earning) =>
        new Date(earning.date) >= startOfLastMonth &&
        new Date(earning.date) < startOfThisMonth
    );
  }

  return earnings.value;
});

// Lifecycle hooks
onMounted(() => {
  nextTick(() => {
    updateIndicator();
  });

  // Update indicator on window resize
  window.addEventListener("resize", updateIndicator);
});

onBeforeUnmount(() => {
  window.removeEventListener("resize", updateIndicator);
});

// public section
definePageMeta({
  layout: "default",
});

// FAQ items
const faqItems = [
  {
    label: "How does the referral program work?",
    content:
      "When you sign up, you get a unique referral link. Share this link with friends, and when they sign up and complete tasks or make purchases, you earn a 5% commission on their transactions.",
    icon: "i-heroicons-question-mark-circle",
  },
  {
    label: "When do I get paid my commissions?",
    content:
      "Commissions are processed within 24 hours of your referred friend completing a transaction. You can withdraw your earnings once you reach the minimum threshold of ৳100.",
    icon: "i-heroicons-banknotes",
  },
  {
    label: "Is there a limit to how many people I can refer?",
    content:
      "No, there is no limit! You can refer as many friends as you want and earn commissions on all their qualifying transactions.",
    icon: "i-heroicons-user-group",
  },
  {
    label: "What transactions qualify for the 5% commission?",
    content:
      "Most transactions including product purchases, subscription payments, and premium service upgrades qualify. Some exceptions may apply to promotional or discounted items.",
    icon: "i-heroicons-shopping-bag",
  },
  {
    label: "How long does my referral link stay active?",
    content:
      "Your referral link stays active indefinitely. Once a friend uses your link to sign up, they are permanently linked to your account for commission purposes.",
    icon: "i-heroicons-link",
  },
];
</script>

<style scoped>
/* Subtle animations */
@keyframes fadeIn {
  from {
    opacity: 0;
  }
  to {
    opacity: 1;
  }
}

@keyframes fadeInUp {
  from {
    opacity: 0;
    transform: translateY(20px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}

@keyframes float {
  0%,
  100% {
    transform: translate(0, 0);
  }
  50% {
    transform: translate(0, -10px);
  }
}

@keyframes floatReverse {
  0%,
  100% {
    transform: translate(0, 0);
  }
  50% {
    transform: translate(0, 10px);
  }
}

@keyframes width {
  from {
    width: 0;
  }
  to {
    width: 24rem;
  }
}

/* Applied animations */
.animate-fade-in {
  animation: fadeIn 0.8s ease-out forwards;
}

.animate-fade-in-up {
  animation: fadeInUp 0.8s ease-out forwards;
}

.animate-float {
  animation: float 8s ease-in-out infinite;
}

.animate-float-reverse {
  animation: floatReverse 9s ease-in-out infinite;
}

.animate-width {
  animation: width 1s ease-out forwards;
  width: 0;
}

/* Stats Cards */
.stat-card {
  animation: fadeInUp 0.5s ease-out forwards;
}

.stat-icon-wrapper {
  transition: all 0.3s ease;
}

/* Copy button */
.copy-btn {
  transition: all 0.2s ease;
  overflow: hidden;
}

.copy-btn::after {
  content: "";
  position: absolute;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  background: rgba(255, 255, 255, 0.2);
  transform: translateX(-100%);
}

.copy-btn:hover::after {
  transform: translateX(100%);
  transition: all 0.5s ease;
}

/* Social buttons */
.social-btn {
  position: relative;
  overflow: hidden;
}

.social-btn::after {
  content: "";
  position: absolute;
  top: 0;
  left: 0;
  width: 200%;
  height: 200%;
  background: radial-gradient(
    circle,
    rgba(255, 255, 255, 0.2) 0%,
    rgba(255, 255, 255, 0) 70%
  );
  transform: scale(0);
  opacity: 0;
  transition: transform 0.5s, opacity 0.5s;
}

.social-btn:hover::after {
  transform: scale(1);
  opacity: 1;
}

.social-btn:hover {
  transform: translateY(-2px);
}

/* Add these to your existing styles */

.tab-button:hover .tab-icon {
  transform: translateY(-2px) scale(1.1);
}

.table-row-animate {
  opacity: 0;
  animation: tableRowFadeIn 0.5s forwards;
  animation-delay: var(--delay, 0s);
}

@keyframes tableRowFadeIn {
  from {
    opacity: 0;
    transform: translateY(10px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}

/* Search input animation */
.search-input {
  transition: width 0.3s ease;
}

.search-input:focus-within {
  width: 160px !important;
}

/* Action button hover effect */
.action-btn {
  position: relative;
  overflow: hidden;
  z-index: 1;
}

.action-btn::after {
  content: "";
  position: absolute;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  background-color: rgba(var(--color-primary-500-rgb), 0.1);
  transform: scaleX(0);
  transform-origin: right;
  transition: transform 0.4s ease;
  z-index: -1;
}

.action-btn:hover::after {
  transform: scaleX(1);
  transform-origin: left;
}

/* Tab animation enhancements */
.tab-pane {
  will-change: transform, opacity;
}

/* Enhanced pagination styling */
.pagination-control {
  transition: transform 0.3s ease;
}

.pagination-control:hover {
  transform: translateY(-2px);
}

/* User avatar enhanced animation */
.user-avatar {
  transition: all 0.3s cubic-bezier(0.34, 1.56, 0.64, 1);
}

tr:hover .user-avatar {
  transform: scale(1.2) rotate(8deg);
  box-shadow: 0 3px 15px rgba(0, 0, 0, 0.1);
}
/* public section */
/* Animations */
@keyframes fadeIn {
  from {
    opacity: 0;
  }
  to {
    opacity: 1;
  }
}

@keyframes fadeInUp {
  from {
    opacity: 0;
    transform: translateY(20px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}

@keyframes fadeInDelayed {
  0% {
    opacity: 0;
  }
  50% {
    opacity: 0;
  }
  100% {
    opacity: 1;
  }
}

@keyframes floatSlow {
  0%,
  100% {
    transform: translate(0, 0);
  }
  50% {
    transform: translate(0, -30px);
  }
}

@keyframes floatReverse {
  0%,
  100% {
    transform: translate(0, 0);
  }
  50% {
    transform: translate(0, 30px);
  }
}

@keyframes expand {
  from {
    width: 0;
  }
  to {
    width: 5rem;
  }
}

/* Applied animations */
.animate-fade-in {
  animation: fadeIn 1s ease-out forwards;
}

.animate-fade-in-delayed {
  animation: fadeInDelayed 1.5s ease-out forwards;
}

.animate-float-slow {
  animation: floatSlow 20s ease-in-out infinite;
}

.animate-float-reverse {
  animation: floatReverse 15s ease-in-out infinite;
}

.animate-expand {
  animation: expand 1s ease-out forwards;
}

/* CTA Buttons */
.cta-button,
.cta-button-secondary {
  position: relative;
  overflow: hidden;
  transition: all 0.3s ease;
}

.cta-button::after,
.cta-button-secondary::after {
  content: "";
  position: absolute;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  background: linear-gradient(
    120deg,
    rgba(255, 255, 255, 0) 0%,
    rgba(255, 255, 255, 0.3) 50%,
    rgba(255, 255, 255, 0) 100%
  );
  transform: translateX(-100%);
  transition: transform 0.8s;
}

.cta-button:hover::after,
.cta-button-secondary:hover::after {
  transform: translateX(100%);
}

/* Step Cards Animation */
.step-card {
  transition: all 0.4s cubic-bezier(0.175, 0.885, 0.32, 1.275);
  transform: translateY(0);
}

.step-card:hover {
  transform: translateY(-10px);
  box-shadow: 0 15px 30px rgba(0, 0, 0, 0.1);
}

/* Stat Boxes */
.stat-box {
  transition: all 0.3s ease;
}

.stat-box:hover {
  transform: scale(1.05);
}

/* Testimonial Cards */
.testimonial-card {
  transition: all 0.3s ease;
  border-left: 4px solid transparent;
}

.testimonial-card:hover {
  border-left: 4px solid var(--color-primary-500);
  transform: translateX(5px);
}

/* FAQ Accordion */
.faq-accordion :deep(.u-accordion-item) {
  margin-bottom: 0.5rem;
  border-radius: 0.5rem;
  overflow: hidden;
  transition: all 0.3s ease;
  border: 1px solid var(--color-gray-100);
}

.faq-accordion :deep(.u-accordion-item:hover) {
  box-shadow: 0 5px 15px rgba(0, 0, 0, 0.05);
}

.faq-accordion :deep(.u-accordion-item__button) {
  transition: background 0.3s ease;
}

.faq-accordion :deep(.u-accordion-item__button:hover) {
  background-color: var(--color-gray-50);
}

.faq-accordion :deep(.dark .u-accordion-item) {
  border-color: var(--color-gray-700);
}

.faq-accordion :deep(.dark .u-accordion-item__button:hover) {
  background-color: var(--color-gray-700);
}

/* Final CTA Section */
.cta-section {
  position: relative;
  overflow: hidden;
}

.cta-section::before {
  content: "";
  position: absolute;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background: url("data:image/svg+xml,%3Csvg width='100' height='100' viewBox='0 0 100 100' xmlns='http://www.w3.org/2000/svg'%3E%3Cpath d='M11 18c3.866 0 7-3.134 7-7s-3.134-7-7-7-7 3.134-7 7 3.134 7 7 7zm48 25c3.866 0 7-3.134 7-7s-3.134-7-7-7-7 3.134-7 7 3.134 7 7 7zm-43-7c1.657 0 3-1.343 3-3s-1.343-3-3-3-3 1.343-3 3 1.343 3 3 3zm63 31c1.657 0 3-1.343 3-3s-1.343-3-3-3-3 1.343-3 3 1.343 3 3 3zM34 90c1.657 0 3-1.343 3-3s-1.343-3-3-3-3 1.343-3 3 1.343 3 3 3zm56-76c1.657 0 3-1.343 3-3s-1.343-3-3-3-3 1.343-3 3 1.343 3 3 3zM12 86c2.21 0 4-1.79 4-4s-1.79-4-4-4-4 1.79-4 4 1.79 4 4 4zm28-65c2.21 0 4-1.79 4-4s-1.79-4-4-4-4 1.79-4 4 1.79 4 4 4zm23-11c2.76 0 5-2.24 5-5s-2.24-5-5-5-5 2.24-5 5 2.24 5 5 5zm-6 60c2.21 0 4-1.79 4-4s-1.79-4-4-4-4 1.79-4 4 1.79 4 4 4zm29 22c2.76 0 5-2.24 5-5s-2.24-5-5-5-5 2.24-5 5 2.24 5 5 5zM32 63c2.76 0 5-2.24 5-5s-2.24-5-5-5-5 2.24-5 5 2.24 5 5 5zm57-13c2.76 0 5-2.24 5-5s-2.24-5-5-5-5 2.24-5 5 2.24 5 5 5zm-9-21c1.105 0 2-.895 2-2s-.895-2-2-2-2 .895-2 2 .895 2 2 2zM60 91c1.105 0 2-.895 2-2s-.895-2-2-2-2 .895-2 2 .895 2 2 2zM35 41c1.105 0 2-.895 2-2s-.895-2-2-2-2 .895-2 2 .895 2 2 2zM12 60c1.105 0 2-.895 2-2s-.895-2-2-2-2 .895-2 2 .895 2 2 2z' fill='%23ffffff' fill-opacity='0.1' fill-rule='evenodd'/%3E%3C/svg%3E");
  opacity: 0.5;
}

.cta-button-final {
  position: relative;
  overflow: hidden;
  transition: all 0.3s ease;
}

.cta-button-final:hover {
  transform: translateY(-2px);
  box-shadow: 0 7px 14px rgba(0, 0, 0, 0.1), 0 3px 6px rgba(0, 0, 0, 0.08);
}
</style>
