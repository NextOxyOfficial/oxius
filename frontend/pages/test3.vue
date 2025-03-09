<template>
  <div class="bg-gray-50 min-h-screen">
    <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-10">
      <div class="">
        <!-- Transaction History -->
        <div class="lg:col-span-2">
          <div class="bg-white rounded-lg shadow overflow-hidden">
            <div class="px-6 py-5 border-b border-gray-200">
              <h2 class="text-lg font-medium text-gray-900">
                Transaction History
              </h2>
              <p class="mt-1 text-sm text-gray-500">
                View and manage your recent transactions
              </p>
            </div>

            <!-- Filters -->
            <div class="px-6 py-4 border-b border-gray-200 bg-gray-50">
              <div
                class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4"
              >
                <div class="flex flex-col sm:flex-row gap-2">
                  <select
                    v-model="filters.type"
                    class="rounded-md border-gray-300 shadow-sm focus:border-primary-500 focus:ring-primary-500 sm:text-sm"
                  >
                    <option value="">All Types</option>
                    <option value="deposit">Deposit</option>
                    <option value="withdraw">Withdraw</option>
                    <option value="transfer">Transfer</option>
                  </select>

                  <select
                    v-model="filters.status"
                    class="rounded-md border-gray-300 shadow-sm focus:border-primary-500 focus:ring-primary-500 sm:text-sm"
                  >
                    <option value="">All Statuses</option>
                    <option value="completed">Completed</option>
                    <option value="pending">Pending</option>
                    <option value="failed">Failed</option>
                  </select>
                </div>

                <div class="relative flex-1 max-w-xs">
                  <input
                    type="text"
                    v-model="filters.search"
                    placeholder="Search transactions..."
                    class="block w-full rounded-md border-gray-300 shadow-sm focus:border-primary-500 focus:ring-primary-500 sm:text-sm"
                  />
                </div>
              </div>
            </div>

            <!-- Table -->
            <div class="overflow-x-auto">
              <table class="min-w-full divide-y divide-gray-200">
                <thead class="bg-gray-50">
                  <tr>
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
                      Recipient
                    </th>
                    <th
                      scope="col"
                      class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider"
                    >
                      Name
                    </th>
                    <th
                      scope="col"
                      class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider"
                    >
                      Time
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
                      class="px-6 py-3 text-right text-xs font-medium text-gray-500 uppercase tracking-wider"
                    >
                      Actions
                    </th>
                  </tr>
                </thead>
                <tbody class="bg-white divide-y divide-gray-200">
                  <tr
                    v-for="transaction in paginatedTransactions"
                    :key="transaction.id"
                    class="hover:bg-gray-50"
                  >
                    <td class="px-6 py-4 whitespace-nowrap">
                      <div class="flex items-center">
                        <span
                          v-if="transaction.type === 'deposit'"
                          class="flex-shrink-0 h-5 w-5 text-green-500"
                        >
                          <svg
                            xmlns="http://www.w3.org/2000/svg"
                            viewBox="0 0 24 24"
                            fill="none"
                            stroke="currentColor"
                            stroke-width="2"
                            stroke-linecap="round"
                            stroke-linejoin="round"
                            class="lucide lucide-arrow-down"
                          >
                            <path d="M12 5v14" />
                            <path d="m19 12-7 7-7-7" />
                          </svg>
                        </span>
                        <span
                          v-else-if="transaction.type === 'withdraw'"
                          class="flex-shrink-0 h-5 w-5 text-red-500"
                        >
                          <svg
                            xmlns="http://www.w3.org/2000/svg"
                            viewBox="0 0 24 24"
                            fill="none"
                            stroke="currentColor"
                            stroke-width="2"
                            stroke-linecap="round"
                            stroke-linejoin="round"
                            class="lucide lucide-arrow-up"
                          >
                            <path d="M12 19V5" />
                            <path d="m5 12 7-7 7 7" />
                          </svg>
                        </span>
                        <span
                          v-else
                          class="flex-shrink-0 h-5 w-5 text-blue-500"
                        >
                          <svg
                            xmlns="http://www.w3.org/2000/svg"
                            viewBox="0 0 24 24"
                            fill="none"
                            stroke="currentColor"
                            stroke-width="2"
                            stroke-linecap="round"
                            stroke-linejoin="round"
                            class="lucide lucide-arrow-left-right"
                          >
                            <path d="M8 3 4 7l4 4" />
                            <path d="M4 7h16" />
                            <path d="m16 21 4-4-4-4" />
                            <path d="M20 17H4" />
                          </svg>
                        </span>
                        <span class="ml-2 text-sm text-gray-900 capitalize">{{
                          transaction.type
                        }}</span>
                      </div>
                    </td>
                    <td class="px-6 py-4 whitespace-nowrap">
                      <div class="text-sm font-mono text-gray-500">
                        {{ transaction.recipient }}
                      </div>
                    </td>
                    <td class="px-6 py-4 whitespace-nowrap">
                      <div class="text-sm text-gray-900">
                        {{ transaction.name }}
                      </div>
                    </td>
                    <td class="px-6 py-4 whitespace-nowrap">
                      <div class="text-sm text-gray-500">
                        {{ formatDate(transaction.time) }}
                      </div>
                    </td>
                    <td class="px-6 py-4 whitespace-nowrap">
                      <div
                        class="text-sm font-medium"
                        :class="{
                          'text-green-600': transaction.type === 'deposit',
                          'text-red-600': transaction.type === 'withdraw',
                          'text-gray-900': transaction.type === 'transfer',
                        }"
                      >
                        {{ formatAmount(transaction.amount, transaction.type) }}
                      </div>
                    </td>
                    <td class="px-6 py-4 whitespace-nowrap">
                      <span
                        class="px-2 inline-flex text-xs leading-5 font-semibold rounded-full"
                        :class="{
                          'bg-green-100 text-green-800':
                            transaction.status === 'completed',
                          'bg-yellow-100 text-yellow-800':
                            transaction.status === 'pending',
                          'bg-red-100 text-red-800':
                            transaction.status === 'failed',
                        }"
                      >
                        {{
                          transaction.status.charAt(0).toUpperCase() +
                          transaction.status.slice(1)
                        }}
                      </span>
                    </td>
                    <td
                      class="px-6 py-4 whitespace-nowrap text-right text-sm font-medium"
                    >
                      <button
                        @click="openTransactionDetails(transaction)"
                        class="text-primary-600 hover:text-primary-900 focus:outline-none focus:underline"
                      >
                        <svg
                          xmlns="http://www.w3.org/2000/svg"
                          viewBox="0 0 24 24"
                          fill="none"
                          stroke="currentColor"
                          stroke-width="2"
                          stroke-linecap="round"
                          stroke-linejoin="round"
                          class="lucide lucide-eye h-5 w-5"
                        >
                          <path
                            d="M2 12s3-7 10-7 10 7 10 7-3 7-10 7-10-7-10-7Z"
                          />
                          <circle cx="12" cy="12" r="3" />
                        </svg>
                        <span class="sr-only">View details</span>
                      </button>
                    </td>
                  </tr>
                  <tr v-if="paginatedTransactions.length === 0">
                    <td
                      colspan="7"
                      class="px-6 py-10 text-center text-sm text-gray-500"
                    >
                      No transactions found matching your criteria.
                    </td>
                  </tr>
                </tbody>
              </table>
            </div>

            <!-- Pagination -->
            <div
              v-if="totalPages > 1"
              class="px-6 py-4 bg-gray-50 border-t border-gray-200 flex items-center justify-between"
            >
              <div
                class="hidden sm:flex-1 sm:flex sm:items-center sm:justify-between"
              >
                <div>
                  <p class="text-sm text-gray-700">
                    Showing
                    <span class="font-medium">{{ startIndex + 1 }}</span> to
                    <span class="font-medium">{{
                      Math.min(
                        startIndex + itemsPerPage,
                        filteredTransactions.length
                      )
                    }}</span>
                    of
                    <span class="font-medium">{{
                      filteredTransactions.length
                    }}</span>
                    results
                  </p>
                </div>
                <div>
                  <nav
                    class="relative z-0 inline-flex rounded-md shadow-sm -space-x-px"
                    aria-label="Pagination"
                  >
                    <button
                      @click="goToPage(1)"
                      :disabled="currentPage === 1"
                      class="relative inline-flex items-center px-2 py-2 rounded-l-md border border-gray-300 bg-white text-sm font-medium text-gray-500 hover:bg-gray-50 disabled:opacity-50 disabled:cursor-not-allowed"
                    >
                      <span class="sr-only">First page</span>
                      <svg
                        xmlns="http://www.w3.org/2000/svg"
                        viewBox="0 0 24 24"
                        fill="none"
                        stroke="currentColor"
                        stroke-width="2"
                        stroke-linecap="round"
                        stroke-linejoin="round"
                        class="lucide lucide-chevrons-left h-5 w-5"
                      >
                        <path d="m11 17-5-5 5-5" />
                        <path d="m18 17-5-5 5-5" />
                      </svg>
                    </button>
                    <button
                      @click="goToPage(currentPage - 1)"
                      :disabled="currentPage === 1"
                      class="relative inline-flex items-center px-2 py-2 border border-gray-300 bg-white text-sm font-medium text-gray-500 hover:bg-gray-50 disabled:opacity-50 disabled:cursor-not-allowed"
                    >
                      <span class="sr-only">Previous</span>
                      <svg
                        xmlns="http://www.w3.org/2000/svg"
                        viewBox="0 0 24 24"
                        fill="none"
                        stroke="currentColor"
                        stroke-width="2"
                        stroke-linecap="round"
                        stroke-linejoin="round"
                        class="lucide lucide-chevron-left h-5 w-5"
                      >
                        <path d="m15 18-6-6 6-6" />
                      </svg>
                    </button>

                    <template v-for="page in displayedPages" :key="page">
                      <button
                        @click="goToPage(page)"
                        :class="[
                          currentPage === page
                            ? 'z-10 bg-primary-50 border-primary-500 text-primary-600'
                            : 'bg-white border-gray-300 text-gray-500 hover:bg-gray-50',
                          'relative inline-flex items-center px-4 py-2 border text-sm font-medium',
                        ]"
                      >
                        {{ page }}
                      </button>
                    </template>

                    <button
                      @click="goToPage(currentPage + 1)"
                      :disabled="currentPage === totalPages"
                      class="relative inline-flex items-center px-2 py-2 border border-gray-300 bg-white text-sm font-medium text-gray-500 hover:bg-gray-50 disabled:opacity-50 disabled:cursor-not-allowed"
                    >
                      <span class="sr-only">Next</span>
                      <svg
                        xmlns="http://www.w3.org/2000/svg"
                        viewBox="0 0 24 24"
                        fill="none"
                        stroke="currentColor"
                        stroke-width="2"
                        stroke-linecap="round"
                        stroke-linejoin="round"
                        class="lucide lucide-chevron-right h-5 w-5"
                      >
                        <path d="m9 18 6-6-6-6" />
                      </svg>
                    </button>
                    <button
                      @click="goToPage(totalPages)"
                      :disabled="currentPage === totalPages"
                      class="relative inline-flex items-center px-2 py-2 rounded-r-md border border-gray-300 bg-white text-sm font-medium text-gray-500 hover:bg-gray-50 disabled:opacity-50 disabled:cursor-not-allowed"
                    >
                      <span class="sr-only">Last page</span>
                      <svg
                        xmlns="http://www.w3.org/2000/svg"
                        viewBox="0 0 24 24"
                        fill="none"
                        stroke="currentColor"
                        stroke-width="2"
                        stroke-linecap="round"
                        stroke-linejoin="round"
                        class="lucide lucide-chevrons-right h-5 w-5"
                      >
                        <path d="m6 17 5-5-5-5" />
                        <path d="m13 17 5-5-5-5" />
                      </svg>
                    </button>
                  </nav>
                </div>
              </div>

              <!-- Mobile pagination -->
              <div class="flex items-center justify-between w-full sm:hidden">
                <button
                  @click="goToPage(currentPage - 1)"
                  :disabled="currentPage === 1"
                  class="relative inline-flex items-center px-4 py-2 border border-gray-300 text-sm font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50 disabled:opacity-50 disabled:cursor-not-allowed"
                >
                  Previous
                </button>
                <p class="text-sm text-gray-700">
                  Page <span class="font-medium">{{ currentPage }}</span> of
                  <span class="font-medium">{{ totalPages }}</span>
                </p>
                <button
                  @click="goToPage(currentPage + 1)"
                  :disabled="currentPage === totalPages"
                  class="relative inline-flex items-center px-4 py-2 border border-gray-300 text-sm font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50 disabled:opacity-50 disabled:cursor-not-allowed"
                >
                  Next
                </button>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- Transaction Details Modal -->
    <div
      v-if="showDetailsModal"
      class="fixed inset-0 overflow-y-auto z-50"
      aria-labelledby="modal-title"
      role="dialog"
      aria-modal="true"
    >
      <div
        class="flex items-end justify-center min-h-screen pt-4 px-4 pb-20 text-center sm:block sm:p-0"
      >
        <!-- Background overlay -->
        <div
          class="fixed inset-0 bg-gray-500 bg-opacity-75 transition-opacity"
          aria-hidden="true"
          @click="showDetailsModal = false"
        ></div>

        <!-- Modal panel -->
        <div
          class="inline-block align-bottom bg-white rounded-lg text-left overflow-hidden shadow-xl transform transition-all sm:my-8 sm:align-middle sm:max-w-lg sm:w-full"
        >
          <div class="bg-white px-4 pt-5 pb-4 sm:p-6 sm:pb-4">
            <div class="sm:flex sm:items-start">
              <div class="mt-3 text-center sm:mt-0 sm:ml-4 sm:text-left w-full">
                <h3
                  class="text-lg leading-6 font-medium text-gray-900"
                  id="modal-title"
                >
                  Transaction Details
                </h3>
                <div class="mt-4 border-t border-gray-200 pt-4">
                  <dl class="divide-y divide-gray-200">
                    <div class="py-3 sm:grid sm:grid-cols-3 sm:gap-4">
                      <dt class="text-sm font-medium text-gray-500">
                        Transaction ID
                      </dt>
                      <dd
                        class="mt-1 text-sm text-gray-900 sm:mt-0 sm:col-span-2 font-mono"
                      >
                        {{ selectedTransaction?.id }}
                      </dd>
                    </div>
                    <div class="py-3 sm:grid sm:grid-cols-3 sm:gap-4">
                      <dt class="text-sm font-medium text-gray-500">Type</dt>
                      <dd
                        class="mt-1 text-sm text-gray-900 sm:mt-0 sm:col-span-2 capitalize flex items-center"
                      >
                        <span
                          v-if="selectedTransaction?.type === 'deposit'"
                          class="flex-shrink-0 h-5 w-5 text-green-500 mr-2"
                        >
                          <svg
                            xmlns="http://www.w3.org/2000/svg"
                            viewBox="0 0 24 24"
                            fill="none"
                            stroke="currentColor"
                            stroke-width="2"
                            stroke-linecap="round"
                            stroke-linejoin="round"
                            class="lucide lucide-arrow-down"
                          >
                            <path d="M12 5v14" />
                            <path d="m19 12-7 7-7-7" />
                          </svg>
                        </span>
                        <span
                          v-else-if="selectedTransaction?.type === 'withdraw'"
                          class="flex-shrink-0 h-5 w-5 text-red-500 mr-2"
                        >
                          <svg
                            xmlns="http://www.w3.org/2000/svg"
                            viewBox="0 0 24 24"
                            fill="none"
                            stroke="currentColor"
                            stroke-width="2"
                            stroke-linecap="round"
                            stroke-linejoin="round"
                            class="lucide lucide-arrow-up"
                          >
                            <path d="M12 19V5" />
                            <path d="m5 12 7-7 7 7" />
                          </svg>
                        </span>
                        <span
                          v-else
                          class="flex-shrink-0 h-5 w-5 text-blue-500 mr-2"
                        >
                          <svg
                            xmlns="http://www.w3.org/2000/svg"
                            viewBox="0 0 24 24"
                            fill="none"
                            stroke="currentColor"
                            stroke-width="2"
                            stroke-linecap="round"
                            stroke-linejoin="round"
                            class="lucide lucide-arrow-left-right"
                          >
                            <path d="M8 3 4 7l4 4" />
                            <path d="M4 7h16" />
                            <path d="m16 21 4-4-4-4" />
                            <path d="M20 17H4" />
                          </svg>
                        </span>
                        {{ selectedTransaction?.type }}
                      </dd>
                    </div>
                    <div class="py-3 sm:grid sm:grid-cols-3 sm:gap-4">
                      <dt class="text-sm font-medium text-gray-500">
                        Recipient
                      </dt>
                      <dd
                        class="mt-1 text-sm text-gray-900 sm:mt-0 sm:col-span-2 font-mono"
                      >
                        {{ selectedTransaction?.recipient }}
                      </dd>
                    </div>
                    <div class="py-3 sm:grid sm:grid-cols-3 sm:gap-4">
                      <dt class="text-sm font-medium text-gray-500">Name</dt>
                      <dd
                        class="mt-1 text-sm text-gray-900 sm:mt-0 sm:col-span-2"
                      >
                        {{ selectedTransaction?.name }}
                      </dd>
                    </div>
                    <div class="py-3 sm:grid sm:grid-cols-3 sm:gap-4">
                      <dt class="text-sm font-medium text-gray-500">
                        Date & Time
                      </dt>
                      <dd
                        class="mt-1 text-sm text-gray-900 sm:mt-0 sm:col-span-2"
                      >
                        {{ formatDate(selectedTransaction?.time) }}
                      </dd>
                    </div>
                    <div class="py-3 sm:grid sm:grid-cols-3 sm:gap-4">
                      <dt class="text-sm font-medium text-gray-500">Amount</dt>
                      <dd
                        class="mt-1 text-sm font-medium sm:mt-0 sm:col-span-2"
                        :class="{
                          'text-green-600':
                            selectedTransaction?.type === 'deposit',
                          'text-red-600':
                            selectedTransaction?.type === 'withdraw',
                          'text-gray-900':
                            selectedTransaction?.type === 'transfer',
                        }"
                      >
                        {{
                          selectedTransaction
                            ? formatAmount(
                                selectedTransaction.amount,
                                selectedTransaction.type
                              )
                            : ""
                        }}
                      </dd>
                    </div>
                    <div class="py-3 sm:grid sm:grid-cols-3 sm:gap-4">
                      <dt class="text-sm font-medium text-gray-500">Status</dt>
                      <dd
                        class="mt-1 text-sm text-gray-900 sm:mt-0 sm:col-span-2"
                      >
                        <span
                          v-if="selectedTransaction"
                          class="px-2 inline-flex text-xs leading-5 font-semibold rounded-full"
                          :class="{
                            'bg-green-100 text-green-800':
                              selectedTransaction.status === 'completed',
                            'bg-yellow-100 text-yellow-800':
                              selectedTransaction.status === 'pending',
                            'bg-red-100 text-red-800':
                              selectedTransaction.status === 'failed',
                          }"
                        >
                          {{
                            selectedTransaction.status.charAt(0).toUpperCase() +
                            selectedTransaction.status.slice(1)
                          }}
                        </span>
                      </dd>
                    </div>
                  </dl>
                </div>
              </div>
            </div>
          </div>
          <div class="bg-gray-50 px-4 py-3 sm:px-6 sm:flex sm:flex-row-reverse">
            <button
              type="button"
              class="w-full inline-flex justify-center rounded-md border border-transparent shadow-sm px-4 py-2 bg-primary-600 text-base font-medium text-white hover:bg-primary-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-primary-500 sm:ml-3 sm:w-auto sm:text-sm"
              @click="showDetailsModal = false"
            >
              Close
            </button>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
const { formatDate } = useUtils();
// Sample transaction data generator
const generateTransactions = (count) => {
  const types = ["deposit", "withdraw", "transfer"];
  const statuses = ["completed", "pending", "failed"];
  const names = [
    "John Doe",
    "Jane Smith",
    "Robert Johnson",
    "Emily Davis",
    "Michael Wilson",
  ];

  return Array.from({ length: count }, (_, i) => {
    const type = types[Math.floor(Math.random() * types.length)];
    const amount = Number.parseFloat((Math.random() * 1000 + 10).toFixed(2));
    const date = new Date();
    date.setDate(date.getDate() - Math.floor(Math.random() * 30));

    return {
      id: `tx-${i + 1}`,
      type,
      recipient:
        type === "transfer"
          ? Math.random() > 0.5
            ? `+1${Math.floor(Math.random() * 9000000000) + 1000000000}`
            : `user${i}@example.com`
          : "-",
      name: names[Math.floor(Math.random() * names.length)],
      time: date,
      amount,
      status: statuses[Math.floor(Math.random() * statuses.length)],
    };
  });
};

// Transaction form state
const transaction = ref({
  type: "deposit",
  amount: "",
  fromAccount: "",
  toAccount: "",
  recipient: "",
  description: "",
});

const errors = ref({});

// Transaction history state
const allTransactions = ref(generateTransactions(50));
const currentPage = ref(1);
const itemsPerPage = 15;
const filters = ref({
  type: "",
  status: "",
  search: "",
});

// Modal state
const showDetailsModal = ref(false);
const selectedTransaction = ref(null);

// Computed properties
const filteredTransactions = computed(() => {
  return allTransactions.value.filter((transaction) => {
    const matchesType =
      !filters.value.type || transaction.type === filters.value.type;
    const matchesStatus =
      !filters.value.status || transaction.status === filters.value.status;
    const matchesSearch =
      !filters.value.search ||
      transaction.name
        .toLowerCase()
        .includes(filters.value.search.toLowerCase()) ||
      transaction.recipient
        .toLowerCase()
        .includes(filters.value.search.toLowerCase());

    return matchesType && matchesStatus && matchesSearch;
  });
});

const totalPages = computed(() => {
  return Math.ceil(filteredTransactions.value.length / itemsPerPage);
});

const startIndex = computed(() => {
  return (currentPage.value - 1) * itemsPerPage;
});

const paginatedTransactions = computed(() => {
  return filteredTransactions.value.slice(
    startIndex.value,
    startIndex.value + itemsPerPage
  );
});

const displayedPages = computed(() => {
  const pages = [];
  const maxVisiblePages = 5;

  if (totalPages.value <= maxVisiblePages) {
    // Show all pages if there are 5 or fewer
    for (let i = 1; i <= totalPages.value; i++) {
      pages.push(i);
    }
  } else if (currentPage.value <= 3) {
    // Near the start
    for (let i = 1; i <= maxVisiblePages; i++) {
      pages.push(i);
    }
  } else if (currentPage.value >= totalPages.value - 2) {
    // Near the end
    for (
      let i = totalPages.value - maxVisiblePages + 1;
      i <= totalPages.value;
      i++
    ) {
      pages.push(i);
    }
  } else {
    // In the middle
    for (let i = currentPage.value - 2; i <= currentPage.value + 2; i++) {
      pages.push(i);
    }
  }

  return pages;
});

// Methods
const submitTransaction = () => {
  // Reset errors
  errors.value = {};

  // Validate form
  if (
    !transaction.value.amount ||
    isNaN(transaction.value.amount) ||
    Number(transaction.value.amount) <= 0
  ) {
    errors.value.amount = "Please enter a valid amount greater than zero";
    return;
  }

  if (transaction.value.type === "withdraw" && !transaction.value.fromAccount) {
    errors.value.fromAccount = "Please select an account";
    return;
  }

  if (transaction.value.type === "deposit" && !transaction.value.toAccount) {
    errors.value.toAccount = "Please select an account";
    return;
  }

  if (transaction.value.type === "transfer") {
    if (!transaction.value.fromAccount) {
      errors.value.fromAccount = "Please select a source account";
      return;
    }
    if (!transaction.value.toAccount) {
      errors.value.toAccount = "Please select a destination account";
      return;
    }
    if (transaction.value.fromAccount === transaction.value.toAccount) {
      errors.value.toAccount =
        "Source and destination accounts must be different";
      return;
    }
  }

  // In a real app, you would send this data to your API
  console.log("Transaction submitted:", transaction.value);

  // Add to transaction history (for demo purposes)
  const newTransaction = {
    id: `tx-${allTransactions.value.length + 1}`,
    type: transaction.value.type,
    recipient:
      transaction.value.type === "transfer" ? transaction.value.recipient : "-",
    name: "You",
    time: new Date(),
    amount: Number(transaction.value.amount),
    status: "completed",
  };

  allTransactions.value.unshift(newTransaction);

  // Reset form
  transaction.value = {
    type: "deposit",
    amount: "",
    fromAccount: "",
    toAccount: "",
    recipient: "",
    description: "",
  };

  // Show first page to see the new transaction
  currentPage.value = 1;
};

// const formatDate = (date) => {
//   return format(new Date(date), "MMM d, yyyy h:mm a");
// };

// const formatDetailDate = (date) => {
//   if (!date) return "";
//   return format(new Date(date), "PPPP p");
// };

const formatAmount = (amount, type) => {
  if (type === "deposit") return `+$${amount.toFixed(2)}`;
  if (type === "withdraw") return `-$${amount.toFixed(2)}`;
  return `$${amount.toFixed(2)}`;
};

const goToPage = (page) => {
  currentPage.value = Math.max(1, Math.min(page, totalPages.value));
};

const openTransactionDetails = (transaction) => {
  selectedTransaction.value = transaction;
  showDetailsModal.value = true;
};

// Reset pagination when filters change
watch(
  filters,
  () => {
    currentPage.value = 1;
  },
  { deep: true }
);
</script>

<style>
:root {
  --color-primary-50: #f0f9ff;
  --color-primary-100: #e0f2fe;
  --color-primary-200: #bae6fd;
  --color-primary-300: #7dd3fc;
  --color-primary-400: #38bdf8;
  --color-primary-500: #0ea5e9;
  --color-primary-600: #0284c7;
  --color-primary-700: #0369a1;
  --color-primary-800: #075985;
  --color-primary-900: #0c4a6e;
}

.bg-primary-50 {
  background-color: var(--color-primary-50);
}
.bg-primary-100 {
  background-color: var(--color-primary-100);
}
.bg-primary-500 {
  background-color: var(--color-primary-500);
}
.bg-primary-600 {
  background-color: var(--color-primary-600);
}
.bg-primary-700 {
  background-color: var(--color-primary-700);
}

.border-primary-500 {
  border-color: var(--color-primary-500);
}

.text-primary-600 {
  color: var(--color-primary-600);
}
.text-primary-900 {
  color: var(--color-primary-900);
}

.focus\:border-primary-500:focus {
  border-color: var(--color-primary-500);
}
.focus\:ring-primary-500:focus {
  --tw-ring-color: var(--color-primary-500);
}
.hover\:bg-primary-700:hover {
  background-color: var(--color-primary-700);
}
</style>
