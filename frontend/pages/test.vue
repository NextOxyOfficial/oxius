<template>
  <div class="min-h-screen bg-gray-50">
    <!-- Mobile Header -->
    <div
      class="lg:hidden bg-white border-b border-gray-200 fixed top-0 left-0 right-0 z-30"
    >
      <div class="flex items-center justify-between p-4">
        <div class="flex items-center">
          <img src="" alt="Logo" class="h-8 w-8 mr-2" />
          <h1 class="text-xl font-bold text-gray-800">Admin Panel</h1>
        </div>
        <button
          @click="mobileMenuOpen = !mobileMenuOpen"
          class="text-gray-500 hover:text-gray-700"
        >
          <menu-icon v-if="!mobileMenuOpen" class="h-6 w-6" />
          <x-icon v-else class="h-6 w-6" />
        </button>
      </div>

      <!-- Mobile Menu -->
      <div
        v-if="mobileMenuOpen"
        class="fixed inset-0 bg-gray-800 bg-opacity-75 z-20"
        @click="mobileMenuOpen = false"
      ></div>
      <div
        v-if="mobileMenuOpen"
        class="fixed top-16 left-0 right-0 bottom-0 bg-white z-20 overflow-y-auto"
      >
        <nav class="px-4 py-2">
          <div
            v-for="(item, index) in navigationItems"
            :key="index"
            class="py-2"
          >
            <button
              @click="
                activeSection = item.id;
                mobileMenuOpen = false;
              "
              class="w-full flex items-center px-4 py-3 rounded-lg"
              :class="
                activeSection === item.id
                  ? 'bg-primary text-white'
                  : 'hover:bg-gray-100'
              "
            >
              <component :is="item.icon" class="h-5 w-5 mr-3" />
              <span>{{ item.name }}</span>
              <badge v-if="item.badge" class="ml-auto">{{ item.badge }}</badge>
            </button>
          </div>

          <div class="mt-6 border-t border-gray-200 pt-4">
            <div class="flex items-center px-4 py-3">
              <avatar class="h-10 w-10 mr-3">
                <avatar-image src="/placeholder.svg?height=40&width=40" />
                <avatar-fallback>AD</avatar-fallback>
              </avatar>
              <div>
                <p class="text-sm font-medium">Admin User</p>
                <p class="text-xs text-gray-500">admin@example.com</p>
              </div>
            </div>
            <button
              class="mt-2 w-full flex items-center px-4 py-3 text-red-600 hover:bg-gray-100 rounded-lg"
            >
              <log-out-icon class="h-5 w-5 mr-3" />
              <span>Logout</span>
            </button>
          </div>
        </nav>
      </div>
    </div>

    <!-- Desktop Sidebar -->
    <div
      class="hidden lg:flex lg:flex-col lg:w-64 lg:fixed lg:inset-y-0 lg:border-r lg:border-gray-200 lg:bg-white lg:pt-5 lg:pb-4"
    >
      <div class="flex items-center flex-shrink-0 px-6">
        <img src="" alt="Logo" class="h-8 w-8" />
        <h1 class="ml-2 text-xl font-bold text-gray-800">Admin Panel</h1>
      </div>
      <div class="mt-6 h-0 flex-1 flex flex-col overflow-y-auto">
        <nav class="px-3 mt-6">
          <div
            v-for="(item, index) in navigationItems"
            :key="index"
            class="mb-2"
          >
            <button
              @click="activeSection = item.id"
              class="w-full flex items-center px-3 py-2 text-sm font-medium rounded-md"
              :class="
                activeSection === item.id
                  ? 'bg-primary text-white'
                  : 'text-gray-700 hover:bg-gray-100'
              "
            >
              <component :is="item.icon" class="h-5 w-5 mr-3" />
              <span>{{ item.name }}</span>
              <badge v-if="item.badge" class="ml-auto">{{ item.badge }}</badge>
            </button>
          </div>
        </nav>

        <div class="mt-auto px-3 py-4 border-t border-gray-200">
          <div class="flex items-center">
            <avatar class="h-10 w-10 mr-3">
              <avatar-image src="/placeholder.svg?height=40&width=40" />
              <avatar-fallback>AD</avatar-fallback>
            </avatar>
            <div>
              <p class="text-sm font-medium text-gray-700">Admin User</p>
              <p class="text-xs text-gray-500">admin@example.com</p>
            </div>
          </div>
          <button
            class="mt-4 w-full flex items-center px-3 py-2 text-sm font-medium text-red-600 rounded-md hover:bg-gray-100"
          >
            <log-out-icon class="h-5 w-5 mr-3" />
            <span>Logout</span>
          </button>
        </div>
      </div>
    </div>

    <!-- Main Content -->
    <div class="lg:pl-64 flex flex-col flex-1">
      <main class="flex-1 pb-8 pt-2 lg:pt-8">
        <!-- Page header -->
        <div class="mt-14 lg:mt-0 bg-white shadow">
          <div class="px-4 sm:px-6 lg:px-8 py-6">
            <h2 class="text-2xl font-bold text-gray-900">
              {{ currentSection.name }}
            </h2>
            <p class="mt-1 text-sm text-gray-500">
              {{ currentSection.description }}
            </p>
          </div>
        </div>

        <!-- Page content -->
        <div class="mt-6 px-4 sm:px-6 lg:px-8">
          <!-- Users Management -->
          <div v-if="activeSection === 'users'" class="space-y-6">
            <div
              class="flex flex-col sm:flex-row sm:items-center sm:justify-between"
            >
              <div class="flex items-center space-x-2">
                <input
                  type="text"
                  placeholder="Search users..."
                  class="px-4 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-primary focus:border-transparent"
                />
                <button
                  class="px-4 py-2 bg-primary text-white rounded-md hover:bg-primary/90"
                >
                  <search-icon class="h-5 w-5" />
                </button>
              </div>
              <button
                class="mt-3 sm:mt-0 px-4 py-2 bg-primary text-white rounded-md hover:bg-primary/90 flex items-center"
              >
                <plus-icon class="h-5 w-5 mr-1" />
                Add User
              </button>
            </div>

            <div class="bg-white shadow rounded-lg overflow-hidden">
              <div class="overflow-x-auto">
                <table class="min-w-full divide-y divide-gray-200">
                  <thead class="bg-gray-50">
                    <tr>
                      <th
                        scope="col"
                        class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider"
                      >
                        User
                      </th>
                      <th
                        scope="col"
                        class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider"
                      >
                        Email
                      </th>
                      <th
                        scope="col"
                        class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider"
                      >
                        Status
                      </th>
                      <th
                        scope="col"
                        class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider"
                      >
                        Role
                      </th>
                      <th
                        scope="col"
                        class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider"
                      >
                        Actions
                      </th>
                    </tr>
                  </thead>
                  <tbody class="bg-white divide-y divide-gray-200">
                    <tr v-for="(user, index) in users" :key="index">
                      <td class="px-6 py-4 whitespace-nowrap">
                        <div class="flex items-center">
                          <div class="flex-shrink-0 h-10 w-10">
                            <img
                              class="h-10 w-10 rounded-full"
                              :src="user.avatar"
                              alt=""
                            />
                          </div>
                          <div class="ml-4">
                            <div class="text-sm font-medium text-gray-900">
                              {{ user.name }}
                            </div>
                            <div class="text-sm text-gray-500">
                              Joined {{ user.joined }}
                            </div>
                          </div>
                        </div>
                      </td>
                      <td class="px-6 py-4 whitespace-nowrap">
                        <div class="text-sm text-gray-900">
                          {{ user.email }}
                        </div>
                      </td>
                      <td class="px-6 py-4 whitespace-nowrap">
                        <span
                          class="px-2 inline-flex text-xs leading-5 font-semibold rounded-full"
                          :class="{
                            'bg-green-100 text-green-800':
                              user.status === 'Active',
                            'bg-yellow-100 text-yellow-800':
                              user.status === 'Pending',
                            'bg-red-100 text-red-800':
                              user.status === 'Suspended',
                          }"
                        >
                          {{ user.status }}
                        </span>
                      </td>
                      <td
                        class="px-6 py-4 whitespace-nowrap text-sm text-gray-500"
                      >
                        {{ user.role }}
                      </td>
                      <td
                        class="px-6 py-4 whitespace-nowrap text-sm font-medium"
                      >
                        <div class="flex space-x-2">
                          <button class="text-primary hover:text-primary/80">
                            <edit-icon class="h-5 w-5" />
                          </button>
                          <button
                            v-if="user.status === 'Pending'"
                            class="text-green-600 hover:text-green-800"
                          >
                            <check-icon class="h-5 w-5" />
                          </button>
                          <button
                            v-if="user.status === 'Active'"
                            class="text-red-600 hover:text-red-800"
                          >
                            <ban-icon class="h-5 w-5" />
                          </button>
                          <button
                            v-if="user.status === 'Suspended'"
                            class="text-green-600 hover:text-green-800"
                          >
                            <refresh-cw-icon class="h-5 w-5" />
                          </button>
                        </div>
                      </td>
                    </tr>
                  </tbody>
                </table>
              </div>
              <div
                class="bg-white px-4 py-3 flex items-center justify-between border-t border-gray-200 sm:px-6"
              >
                <div class="flex-1 flex justify-between sm:hidden">
                  <button
                    class="relative inline-flex items-center px-4 py-2 border border-gray-300 text-sm font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50"
                  >
                    Previous
                  </button>
                  <button
                    class="ml-3 relative inline-flex items-center px-4 py-2 border border-gray-300 text-sm font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50"
                  >
                    Next
                  </button>
                </div>
                <div
                  class="hidden sm:flex-1 sm:flex sm:items-center sm:justify-between"
                >
                  <div>
                    <p class="text-sm text-gray-700">
                      Showing <span class="font-medium">1</span> to
                      <span class="font-medium">10</span> of
                      <span class="font-medium">97</span> results
                    </p>
                  </div>
                  <div>
                    <nav
                      class="relative z-0 inline-flex rounded-md shadow-sm -space-x-px"
                      aria-label="Pagination"
                    >
                      <button
                        class="relative inline-flex items-center px-2 py-2 rounded-l-md border border-gray-300 bg-white text-sm font-medium text-gray-500 hover:bg-gray-50"
                      >
                        <chevron-left-icon class="h-5 w-5" />
                      </button>
                      <button
                        class="relative inline-flex items-center px-4 py-2 border border-gray-300 bg-white text-sm font-medium text-gray-700 hover:bg-gray-50"
                      >
                        1
                      </button>
                      <button
                        class="relative inline-flex items-center px-4 py-2 border border-gray-300 bg-primary text-sm font-medium text-white"
                      >
                        2
                      </button>
                      <button
                        class="relative inline-flex items-center px-4 py-2 border border-gray-300 bg-white text-sm font-medium text-gray-700 hover:bg-gray-50"
                      >
                        3
                      </button>
                      <span
                        class="relative inline-flex items-center px-4 py-2 border border-gray-300 bg-white text-sm font-medium text-gray-700"
                      >
                        ...
                      </span>
                      <button
                        class="relative inline-flex items-center px-4 py-2 border border-gray-300 bg-white text-sm font-medium text-gray-700 hover:bg-gray-50"
                      >
                        10
                      </button>
                      <button
                        class="relative inline-flex items-center px-2 py-2 rounded-r-md border border-gray-300 bg-white text-sm font-medium text-gray-500 hover:bg-gray-50"
                      >
                        <chevron-right-icon class="h-5 w-5" />
                      </button>
                    </nav>
                  </div>
                </div>
              </div>
            </div>
          </div>

          <!-- KYC Management -->
          <div v-if="activeSection === 'kyc'" class="space-y-6">
            <div
              class="flex flex-col sm:flex-row sm:items-center sm:justify-between"
            >
              <div class="flex items-center space-x-2">
                <input
                  type="text"
                  placeholder="Search KYC requests..."
                  class="px-4 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-primary focus:border-transparent"
                />
                <button
                  class="px-4 py-2 bg-primary text-white rounded-md hover:bg-primary/90"
                >
                  <search-icon class="h-5 w-5" />
                </button>
              </div>
              <div class="mt-3 sm:mt-0 flex space-x-2">
                <button
                  class="px-4 py-2 bg-white border border-gray-300 text-gray-700 rounded-md hover:bg-gray-50 flex items-center"
                >
                  <filter-icon class="h-5 w-5 mr-1" />
                  Filter
                </button>
                <button
                  class="px-4 py-2 bg-white border border-gray-300 text-gray-700 rounded-md hover:bg-gray-50 flex items-center"
                >
                  <download-icon class="h-5 w-5 mr-1" />
                  Export
                </button>
              </div>
            </div>

            <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
              <div
                v-for="(kyc, index) in kycRequests"
                :key="index"
                class="bg-white shadow rounded-lg overflow-hidden"
              >
                <div class="p-4 border-b border-gray-200">
                  <div class="flex justify-between items-center">
                    <h3 class="text-lg font-medium text-gray-900">
                      {{ kyc.name }}
                    </h3>
                    <span
                      class="px-2 py-1 text-xs font-semibold rounded-full"
                      :class="{
                        'bg-yellow-100 text-yellow-800':
                          kyc.status === 'Pending',
                        'bg-green-100 text-green-800':
                          kyc.status === 'Approved',
                        'bg-red-100 text-red-800': kyc.status === 'Rejected',
                      }"
                    >
                      {{ kyc.status }}
                    </span>
                  </div>
                  <p class="text-sm text-gray-500 mt-1">ID: {{ kyc.id }}</p>
                  <p class="text-sm text-gray-500">Submitted: {{ kyc.date }}</p>
                </div>
                <div class="p-4 space-y-4">
                  <div class="grid grid-cols-2 gap-4">
                    <div>
                      <p class="text-xs text-gray-500">ID Front</p>
                      <img
                        :src="kyc.idFront"
                        alt="ID Front"
                        class="mt-1 h-24 w-full object-cover rounded-md"
                      />
                    </div>
                    <div>
                      <p class="text-xs text-gray-500">ID Back</p>
                      <img
                        :src="kyc.idBack"
                        alt="ID Back"
                        class="mt-1 h-24 w-full object-cover rounded-md"
                      />
                    </div>
                  </div>
                  <div>
                    <p class="text-xs text-gray-500">Selfie with ID</p>
                    <img
                      :src="kyc.selfie"
                      alt="Selfie"
                      class="mt-1 h-32 w-full object-cover rounded-md"
                    />
                  </div>
                  <div class="grid grid-cols-2 gap-4">
                    <div>
                      <p class="text-xs text-gray-500">Document Type</p>
                      <p class="text-sm font-medium">{{ kyc.documentType }}</p>
                    </div>
                    <div>
                      <p class="text-xs text-gray-500">Document Number</p>
                      <p class="text-sm font-medium">
                        {{ kyc.documentNumber }}
                      </p>
                    </div>
                  </div>
                </div>
                <div class="px-4 py-3 bg-gray-50 flex justify-between">
                  <button
                    v-if="kyc.status === 'Pending'"
                    class="px-3 py-1 bg-red-600 text-white text-sm rounded hover:bg-red-700"
                  >
                    Reject
                  </button>
                  <button
                    v-if="kyc.status === 'Pending'"
                    class="px-3 py-1 bg-primary text-white text-sm rounded hover:bg-primary/90"
                  >
                    Approve
                  </button>
                  <button
                    v-if="kyc.status !== 'Pending'"
                    class="px-3 py-1 bg-gray-600 text-white text-sm rounded hover:bg-gray-700"
                  >
                    View Details
                  </button>
                </div>
              </div>
            </div>

            <div class="flex justify-center mt-6">
              <nav
                class="relative z-0 inline-flex rounded-md shadow-sm -space-x-px"
                aria-label="Pagination"
              >
                <button
                  class="relative inline-flex items-center px-2 py-2 rounded-l-md border border-gray-300 bg-white text-sm font-medium text-gray-500 hover:bg-gray-50"
                >
                  <chevron-left-icon class="h-5 w-5" />
                </button>
                <button
                  class="relative inline-flex items-center px-4 py-2 border border-gray-300 bg-primary text-sm font-medium text-white"
                >
                  1
                </button>
                <button
                  class="relative inline-flex items-center px-4 py-2 border border-gray-300 bg-white text-sm font-medium text-gray-700 hover:bg-gray-50"
                >
                  2
                </button>
                <button
                  class="relative inline-flex items-center px-4 py-2 border border-gray-300 bg-white text-sm font-medium text-gray-700 hover:bg-gray-50"
                >
                  3
                </button>
                <button
                  class="relative inline-flex items-center px-2 py-2 rounded-r-md border border-gray-300 bg-white text-sm font-medium text-gray-500 hover:bg-gray-50"
                >
                  <chevron-right-icon class="h-5 w-5" />
                </button>
              </nav>
            </div>
          </div>

          <!-- Transactions Management -->
          <div v-if="activeSection === 'transactions'" class="space-y-6">
            <div class="grid grid-cols-1 md:grid-cols-3 gap-6">
              <div class="bg-white shadow rounded-lg p-6">
                <div class="flex items-center">
                  <div class="p-3 rounded-full bg-green-100 text-green-600">
                    <arrow-down-icon class="h-6 w-6" />
                  </div>
                  <div class="ml-4">
                    <p class="text-sm font-medium text-gray-500">
                      Total Deposits
                    </p>
                    <h3 class="text-xl font-bold text-gray-900">$24,780.00</h3>
                    <p class="text-sm text-green-600">+12.5% from last month</p>
                  </div>
                </div>
              </div>
              <div class="bg-white shadow rounded-lg p-6">
                <div class="flex items-center">
                  <div class="p-3 rounded-full bg-red-100 text-red-600">
                    <arrow-up-icon class="h-6 w-6" />
                  </div>
                  <div class="ml-4">
                    <p class="text-sm font-medium text-gray-500">
                      Total Withdrawals
                    </p>
                    <h3 class="text-xl font-bold text-gray-900">$18,230.00</h3>
                    <p class="text-sm text-red-600">+8.2% from last month</p>
                  </div>
                </div>
              </div>
              <div class="bg-white shadow rounded-lg p-6">
                <div class="flex items-center">
                  <div class="p-3 rounded-full bg-blue-100 text-blue-600">
                    <repeat-icon class="h-6 w-6" />
                  </div>
                  <div class="ml-4">
                    <p class="text-sm font-medium text-gray-500">
                      P2P Transfers
                    </p>
                    <h3 class="text-xl font-bold text-gray-900">$9,540.00</h3>
                    <p class="text-sm text-blue-600">+5.8% from last month</p>
                  </div>
                </div>
              </div>
            </div>

            <div class="bg-white shadow rounded-lg overflow-hidden">
              <div class="px-6 py-4 border-b border-gray-200">
                <div
                  class="flex flex-col sm:flex-row sm:items-center sm:justify-between"
                >
                  <h3 class="text-lg font-medium text-gray-900">
                    Recent Transactions
                  </h3>
                  <div class="mt-3 sm:mt-0 flex space-x-2">
                    <select
                      class="px-4 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-primary focus:border-transparent"
                    >
                      <option>All Types</option>
                      <option>Deposits</option>
                      <option>Withdrawals</option>
                      <option>P2P Transfers</option>
                    </select>
                    <select
                      class="px-4 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-primary focus:border-transparent"
                    >
                      <option>All Status</option>
                      <option>Pending</option>
                      <option>Completed</option>
                      <option>Rejected</option>
                    </select>
                  </div>
                </div>
              </div>
              <div class="overflow-x-auto">
                <table class="min-w-full divide-y divide-gray-200">
                  <thead class="bg-gray-50">
                    <tr>
                      <th
                        scope="col"
                        class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider"
                      >
                        Transaction ID
                      </th>
                      <th
                        scope="col"
                        class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider"
                      >
                        User
                      </th>
                      <th
                        scope="col"
                        class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider"
                      >
                        Type
                      </th>
                      <th
                        scope="col"
                        class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider"
                      >
                        Amount
                      </th>
                      <th
                        scope="col"
                        class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider"
                      >
                        Status
                      </th>
                      <th
                        scope="col"
                        class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider"
                      >
                        Date
                      </th>
                      <th
                        scope="col"
                        class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider"
                      >
                        Actions
                      </th>
                    </tr>
                  </thead>
                  <tbody class="bg-white divide-y divide-gray-200">
                    <tr
                      v-for="(transaction, index) in transactions"
                      :key="index"
                    >
                      <td
                        class="px-6 py-4 whitespace-nowrap text-sm text-gray-500"
                      >
                        {{ transaction.id }}
                      </td>
                      <td class="px-6 py-4 whitespace-nowrap">
                        <div class="flex items-center">
                          <div class="flex-shrink-0 h-8 w-8">
                            <img
                              class="h-8 w-8 rounded-full"
                              :src="transaction.userAvatar"
                              alt=""
                            />
                          </div>
                          <div class="ml-3">
                            <div class="text-sm font-medium text-gray-900">
                              {{ transaction.userName }}
                            </div>
                          </div>
                        </div>
                      </td>
                      <td class="px-6 py-4 whitespace-nowrap">
                        <div class="flex items-center">
                          <div
                            class="p-1.5 rounded-full mr-2"
                            :class="{
                              'bg-green-100 text-green-600':
                                transaction.type === 'Deposit',
                              'bg-red-100 text-red-600':
                                transaction.type === 'Withdrawal',
                              'bg-blue-100 text-blue-600':
                                transaction.type === 'P2P Transfer',
                            }"
                          >
                            <arrow-down-icon
                              v-if="transaction.type === 'Deposit'"
                              class="h-4 w-4"
                            />
                            <arrow-up-icon
                              v-if="transaction.type === 'Withdrawal'"
                              class="h-4 w-4"
                            />
                            <repeat-icon
                              v-if="transaction.type === 'P2P Transfer'"
                              class="h-4 w-4"
                            />
                          </div>
                          <span class="text-sm text-gray-900">{{
                            transaction.type
                          }}</span>
                        </div>
                      </td>
                      <td
                        class="px-6 py-4 whitespace-nowrap text-sm text-gray-900"
                      >
                        {{ transaction.amount }}
                      </td>
                      <td class="px-6 py-4 whitespace-nowrap">
                        <span
                          class="px-2 inline-flex text-xs leading-5 font-semibold rounded-full"
                          :class="{
                            'bg-yellow-100 text-yellow-800':
                              transaction.status === 'Pending',
                            'bg-green-100 text-green-800':
                              transaction.status === 'Completed',
                            'bg-red-100 text-red-800':
                              transaction.status === 'Rejected',
                          }"
                        >
                          {{ transaction.status }}
                        </span>
                      </td>
                      <td
                        class="px-6 py-4 whitespace-nowrap text-sm text-gray-500"
                      >
                        {{ transaction.date }}
                      </td>
                      <td
                        class="px-6 py-4 whitespace-nowrap text-sm font-medium"
                      >
                        <div class="flex space-x-2">
                          <button class="text-primary hover:text-primary/80">
                            <eye-icon class="h-5 w-5" />
                          </button>
                          <button
                            v-if="transaction.status === 'Pending'"
                            class="text-green-600 hover:text-green-800"
                          >
                            <check-icon class="h-5 w-5" />
                          </button>
                          <button
                            v-if="transaction.status === 'Pending'"
                            class="text-red-600 hover:text-red-800"
                          >
                            <x-icon class="h-5 w-5" />
                          </button>
                        </div>
                      </td>
                    </tr>
                  </tbody>
                </table>
              </div>
              <div
                class="bg-white px-4 py-3 flex items-center justify-between border-t border-gray-200 sm:px-6"
              >
                <div class="flex-1 flex justify-between sm:hidden">
                  <button
                    class="relative inline-flex items-center px-4 py-2 border border-gray-300 text-sm font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50"
                  >
                    Previous
                  </button>
                  <button
                    class="ml-3 relative inline-flex items-center px-4 py-2 border border-gray-300 text-sm font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50"
                  >
                    Next
                  </button>
                </div>
                <div
                  class="hidden sm:flex-1 sm:flex sm:items-center sm:justify-between"
                >
                  <div>
                    <p class="text-sm text-gray-700">
                      Showing <span class="font-medium">1</span> to
                      <span class="font-medium">10</span> of
                      <span class="font-medium">45</span> results
                    </p>
                  </div>
                  <div>
                    <nav
                      class="relative z-0 inline-flex rounded-md shadow-sm -space-x-px"
                      aria-label="Pagination"
                    >
                      <button
                        class="relative inline-flex items-center px-2 py-2 rounded-l-md border border-gray-300 bg-white text-sm font-medium text-gray-500 hover:bg-gray-50"
                      >
                        <chevron-left-icon class="h-5 w-5" />
                      </button>
                      <button
                        class="relative inline-flex items-center px-4 py-2 border border-gray-300 bg-primary text-sm font-medium text-white"
                      >
                        1
                      </button>
                      <button
                        class="relative inline-flex items-center px-4 py-2 border border-gray-300 bg-white text-sm font-medium text-gray-700 hover:bg-gray-50"
                      >
                        2
                      </button>
                      <button
                        class="relative inline-flex items-center px-4 py-2 border border-gray-300 bg-white text-sm font-medium text-gray-700 hover:bg-gray-50"
                      >
                        3
                      </button>
                      <button
                        class="relative inline-flex items-center px-2 py-2 rounded-r-md border border-gray-300 bg-white text-sm font-medium text-gray-500 hover:bg-gray-50"
                      >
                        <chevron-right-icon class="h-5 w-5" />
                      </button>
                    </nav>
                  </div>
                </div>
              </div>
            </div>
          </div>

          <!-- Support Tickets -->
          <div v-if="activeSection === 'support'" class="space-y-6">
            <div
              class="flex flex-col sm:flex-row sm:items-center sm:justify-between"
            >
              <div class="flex items-center space-x-2">
                <input
                  type="text"
                  placeholder="Search tickets..."
                  class="px-4 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-primary focus:border-transparent"
                />
                <button
                  class="px-4 py-2 bg-primary text-white rounded-md hover:bg-primary/90"
                >
                  <search-icon class="h-5 w-5" />
                </button>
              </div>
              <div class="mt-3 sm:mt-0 flex space-x-2">
                <select
                  class="px-4 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-primary focus:border-transparent"
                >
                  <option>All Priorities</option>
                  <option>High</option>
                  <option>Medium</option>
                  <option>Low</option>
                </select>
                <select
                  class="px-4 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-primary focus:border-transparent"
                >
                  <option>All Status</option>
                  <option>Open</option>
                  <option>In Progress</option>
                  <option>Resolved</option>
                </select>
              </div>
            </div>

            <div class="bg-white shadow rounded-lg overflow-hidden">
              <div class="overflow-x-auto">
                <table class="min-w-full divide-y divide-gray-200">
                  <thead class="bg-gray-50">
                    <tr>
                      <th
                        scope="col"
                        class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider"
                      >
                        Ticket ID
                      </th>
                      <th
                        scope="col"
                        class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider"
                      >
                        Subject
                      </th>
                      <th
                        scope="col"
                        class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider"
                      >
                        User
                      </th>
                      <th
                        scope="col"
                        class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider"
                      >
                        Priority
                      </th>
                      <th
                        scope="col"
                        class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider"
                      >
                        Status
                      </th>
                      <th
                        scope="col"
                        class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider"
                      >
                        Created
                      </th>
                      <th
                        scope="col"
                        class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider"
                      >
                        Actions
                      </th>
                    </tr>
                  </thead>
                  <tbody class="bg-white divide-y divide-gray-200">
                    <tr v-for="(ticket, index) in supportTickets" :key="index">
                      <td
                        class="px-6 py-4 whitespace-nowrap text-sm text-gray-500"
                      >
                        {{ ticket.id }}
                      </td>
                      <td class="px-6 py-4">
                        <div class="text-sm text-gray-900">
                          {{ ticket.subject }}
                        </div>
                        <div class="text-sm text-gray-500 truncate max-w-xs">
                          {{ ticket.preview }}
                        </div>
                      </td>
                      <td class="px-6 py-4 whitespace-nowrap">
                        <div class="flex items-center">
                          <div class="flex-shrink-0 h-8 w-8">
                            <img
                              class="h-8 w-8 rounded-full"
                              :src="ticket.userAvatar"
                              alt=""
                            />
                          </div>
                          <div class="ml-3">
                            <div class="text-sm font-medium text-gray-900">
                              {{ ticket.userName }}
                            </div>
                          </div>
                        </div>
                      </td>
                      <td class="px-6 py-4 whitespace-nowrap">
                        <span
                          class="px-2 inline-flex text-xs leading-5 font-semibold rounded-full"
                          :class="{
                            'bg-red-100 text-red-800':
                              ticket.priority === 'High',
                            'bg-yellow-100 text-yellow-800':
                              ticket.priority === 'Medium',
                            'bg-blue-100 text-blue-800':
                              ticket.priority === 'Low',
                          }"
                        >
                          {{ ticket.priority }}
                        </span>
                      </td>
                      <td class="px-6 py-4 whitespace-nowrap">
                        <span
                          class="px-2 inline-flex text-xs leading-5 font-semibold rounded-full"
                          :class="{
                            'bg-green-100 text-green-800':
                              ticket.status === 'Open',
                            'bg-purple-100 text-purple-800':
                              ticket.status === 'In Progress',
                            'bg-gray-100 text-gray-800':
                              ticket.status === 'Resolved',
                          }"
                        >
                          {{ ticket.status }}
                        </span>
                      </td>
                      <td
                        class="px-6 py-4 whitespace-nowrap text-sm text-gray-500"
                      >
                        {{ ticket.created }}
                      </td>
                      <td
                        class="px-6 py-4 whitespace-nowrap text-sm font-medium"
                      >
                        <div class="flex space-x-2">
                          <button class="text-primary hover:text-primary/80">
                            <message-square-icon class="h-5 w-5" />
                          </button>
                          <button class="text-gray-600 hover:text-gray-800">
                            <user-icon class="h-5 w-5" />
                          </button>
                          <button
                            v-if="ticket.status !== 'Resolved'"
                            class="text-green-600 hover:text-green-800"
                          >
                            <check-circle-icon class="h-5 w-5" />
                          </button>
                        </div>
                      </td>
                    </tr>
                  </tbody>
                </table>
              </div>
              <div
                class="bg-white px-4 py-3 flex items-center justify-between border-t border-gray-200 sm:px-6"
              >
                <div class="flex-1 flex justify-between sm:hidden">
                  <button
                    class="relative inline-flex items-center px-4 py-2 border border-gray-300 text-sm font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50"
                  >
                    Previous
                  </button>
                  <button
                    class="ml-3 relative inline-flex items-center px-4 py-2 border border-gray-300 text-sm font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50"
                  >
                    Next
                  </button>
                </div>
                <div
                  class="hidden sm:flex-1 sm:flex sm:items-center sm:justify-between"
                >
                  <div>
                    <p class="text-sm text-gray-700">
                      Showing <span class="font-medium">1</span> to
                      <span class="font-medium">10</span> of
                      <span class="font-medium">23</span> results
                    </p>
                  </div>
                  <div>
                    <nav
                      class="relative z-0 inline-flex rounded-md shadow-sm -space-x-px"
                      aria-label="Pagination"
                    >
                      <button
                        class="relative inline-flex items-center px-2 py-2 rounded-l-md border border-gray-300 bg-white text-sm font-medium text-gray-500 hover:bg-gray-50"
                      >
                        <chevron-left-icon class="h-5 w-5" />
                      </button>
                      <button
                        class="relative inline-flex items-center px-4 py-2 border border-gray-300 bg-primary text-sm font-medium text-white"
                      >
                        1
                      </button>
                      <button
                        class="relative inline-flex items-center px-4 py-2 border border-gray-300 bg-white text-sm font-medium text-gray-700 hover:bg-gray-50"
                      >
                        2
                      </button>
                      <button
                        class="relative inline-flex items-center px-4 py-2 border border-gray-300 bg-white text-sm font-medium text-gray-700 hover:bg-gray-50"
                      >
                        3
                      </button>
                      <button
                        class="relative inline-flex items-center px-2 py-2 rounded-r-md border border-gray-300 bg-white text-sm font-medium text-gray-500 hover:bg-gray-50"
                      >
                        <chevron-right-icon class="h-5 w-5" />
                      </button>
                    </nav>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </main>
    </div>
  </div>
</template>

<script setup>
import { ref, computed } from "vue";
import {
  Menu as MenuIcon,
  Search as SearchIcon,
  Plus as PlusIcon,
  Edit as EditIcon,
  Check as CheckIcon,
  Ban as BanIcon,
  RefreshCw as RefreshCwIcon,
  ChevronLeft as ChevronLeftIcon,
  ChevronRight as ChevronRightIcon,
  Filter as FilterIcon,
  Download as DownloadIcon,
  ArrowDown as ArrowDownIcon,
  ArrowUp as ArrowUpIcon,
  Repeat as RepeatIcon,
  Eye as EyeIcon,
  LogOut as LogOutIcon,
  MessageSquare as MessageSquareIcon,
  User as UserIcon,
  CheckCircle as CheckCircleIcon,
  X as XIcon,
} from "lucide-vue-next";

// State
const mobileMenuOpen = ref(false);
const activeSection = ref("users");

// Navigation items
const navigationItems = [
  {
    id: "users",
    name: "Users Management",
    icon: UserIcon,
    description: "Manage user accounts and permissions",
    badge: "12",
  },
  {
    id: "recharge",
    name: "Mobile Recharge",
    icon: RepeatIcon,
    description: "Manage mobile recharge transactions",
  },
  {
    id: "gigs",
    name: "Gigs",
    icon: MenuIcon,
    description: "Manage gig listings and providers",
  },
  {
    id: "kyc",
    name: "KYC Verification",
    icon: CheckCircleIcon,
    description: "Verify user identities",
    badge: "8",
  },
  {
    id: "classified",
    name: "Classified Posts",
    icon: MessageSquareIcon,
    description: "Manage classified advertisements",
  },
  {
    id: "transactions",
    name: "Financial Transactions",
    icon: ArrowDownIcon,
    description: "Manage deposits, withdrawals and transfers",
    badge: "5",
  },
  {
    id: "affiliates",
    name: "Affiliates",
    icon: UserIcon,
    description: "Manage affiliate partners and commissions",
  },
  {
    id: "support",
    name: "Support Tickets",
    icon: MessageSquareIcon,
    description: "Manage customer support requests",
    badge: "3",
  },
];

// Computed current section
const currentSection = computed(() => {
  return (
    navigationItems.find((item) => item.id === activeSection.value) ||
    navigationItems[0]
  );
});

// Sample data for users
const users = [
  {
    name: "John Smith",
    email: "john@example.com",
    status: "Active",
    role: "User",
    joined: "Jan 10, 2023",
    avatar: "/placeholder.svg?height=40&width=40",
  },
  {
    name: "Sarah Johnson",
    email: "sarah@example.com",
    status: "Active",
    role: "Premium User",
    joined: "Feb 15, 2023",
    avatar: "/placeholder.svg?height=40&width=40",
  },
  {
    name: "Michael Brown",
    email: "michael@example.com",
    status: "Pending",
    role: "User",
    joined: "Mar 22, 2023",
    avatar: "/placeholder.svg?height=40&width=40",
  },
  {
    name: "Emily Davis",
    email: "emily@example.com",
    status: "Active",
    role: "Admin",
    joined: "Dec 5, 2022",
    avatar: "/placeholder.svg?height=40&width=40",
  },
  {
    name: "David Wilson",
    email: "david@example.com",
    status: "Suspended",
    role: "User",
    joined: "Apr 18, 2023",
    avatar: "/placeholder.svg?height=40&width=40",
  },
];

// Sample data for KYC requests
const kycRequests = [
  {
    id: "KYC-2023-001",
    name: "John Smith",
    status: "Pending",
    date: "Aug 15, 2023",
    documentType: "Passport",
    documentNumber: "P12345678",
    idFront: "/placeholder.svg?height=100&width=150",
    idBack: "/placeholder.svg?height=100&width=150",
    selfie: "/placeholder.svg?height=150&width=200",
  },
  {
    id: "KYC-2023-002",
    name: "Sarah Johnson",
    status: "Approved",
    date: "Aug 12, 2023",
    documentType: "Driver License",
    documentNumber: "DL987654321",
    idFront: "/placeholder.svg?height=100&width=150",
    idBack: "/placeholder.svg?height=100&width=150",
    selfie: "/placeholder.svg?height=150&width=200",
  },
  {
    id: "KYC-2023-003",
    name: "Michael Brown",
    status: "Rejected",
    date: "Aug 10, 2023",
    documentType: "National ID",
    documentNumber: "ID123456789",
    idFront: "/placeholder.svg?height=100&width=150",
    idBack: "/placeholder.svg?height=100&width=150",
    selfie: "/placeholder.svg?height=150&width=200",
  },
  {
    id: "KYC-2023-004",
    name: "Emily Davis",
    status: "Pending",
    date: "Aug 8, 2023",
    documentType: "Passport",
    documentNumber: "P87654321",
    idFront: "/placeholder.svg?height=100&width=150",
    idBack: "/placeholder.svg?height=100&width=150",
    selfie: "/placeholder.svg?height=150&width=200",
  },
  {
    id: "KYC-2023-005",
    name: "David Wilson",
    status: "Pending",
    date: "Aug 5, 2023",
    documentType: "Driver License",
    documentNumber: "DL123987456",
    idFront: "/placeholder.svg?height=100&width=150",
    idBack: "/placeholder.svg?height=100&width=150",
    selfie: "/placeholder.svg?height=150&width=200",
  },
];

// Sample data for transactions
const transactions = [
  {
    id: "TRX-2023-001",
    userName: "John Smith",
    userAvatar: "",
    type: "Deposit",
    amount: "$500.00",
    status: "Completed",
    date: "Aug 15, 2023 14:30",
  },
  {
    id: "TRX-2023-002",
    userName: "Sarah Johnson",
    userAvatar: "",
    type: "Withdrawal",
    amount: "$200.00",
    status: "Pending",
    date: "Aug 14, 2023 10:15",
  },
  {
    id: "TRX-2023-003",
    userName: "Michael Brown",
    userAvatar: "",
    type: "P2P Transfer",
    amount: "$150.00",
    status: "Completed",
    date: "Aug 13, 2023 16:45",
  },
  {
    id: "TRX-2023-004",
    userName: "Emily Davis",
    userAvatar: "",
    type: "Deposit",
    amount: "$1,000.00",
    status: "Completed",
    date: "Aug 12, 2023 09:20",
  },
  {
    id: "TRX-2023-005",
    userName: "David Wilson",
    userAvatar: "",
    type: "Withdrawal",
    amount: "$350.00",
    status: "Rejected",
    date: "Aug 11, 2023 13:10",
  },
];

// Sample data for support tickets
const supportTickets = [
  {
    id: "TICKET-001",
    subject: "Unable to withdraw funds",
    preview:
      "I tried to withdraw my funds but the transaction keeps failing...",
    userName: "John Smith",
    userAvatar: "",
    priority: "High",
    status: "Open",
    created: "Aug 15, 2023 14:30",
  },
  {
    id: "TICKET-002",
    subject: "KYC verification taking too long",
    preview: "I submitted my KYC documents 5 days ago but still no update...",
    userName: "Sarah Johnson",
    userAvatar: "",
    priority: "Medium",
    status: "In Progress",
    created: "Aug 14, 2023 10:15",
  },
  {
    id: "TICKET-003",
    subject: "Mobile recharge failed",
    preview:
      "I tried to recharge my mobile but the payment was deducted and no recharge...",
    userName: "Michael Brown",
    userAvatar: "",
    priority: "High",
    status: "Open",
    created: "Aug 13, 2023 16:45",
  },
  {
    id: "TICKET-004",
    subject: "How to become an affiliate?",
    preview:
      "I would like to know the process to become an affiliate partner...",
    userName: "Emily Davis",
    userAvatar: "",
    priority: "Low",
    status: "Resolved",
    created: "Aug 12, 2023 09:20",
  },
  {
    id: "TICKET-005",
    subject: "Classified post not showing up",
    preview:
      "I created a classified post but it is not showing up in the listings...",
    userName: "David Wilson",
    userAvatar: "",
    priority: "Medium",
    status: "In Progress",
    created: "Aug 11, 2023 13:10",
  },
];
</script>

<style scoped>
:root {
  --primary: #4f46e5;
  --primary-hover: #4338ca;
}

.bg-primary {
  background-color: var(--primary);
}

.hover\:bg-primary\/90:hover {
  background-color: var(--primary-hover);
}

.text-primary {
  color: var(--primary);
}

.hover\:text-primary\/80:hover {
  color: var(--primary-hover);
}

.focus\:ring-primary:focus {
  --tw-ring-color: var(--primary);
}
</style>
