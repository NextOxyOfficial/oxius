<template>
  <div class="transaction-history h-max">
    <h1 class="text-3xl font-bold text-center mb-2">Recharge History</h1>
    <p class="text-center text-gray-600 mb-6">
      View your recent mobile recharge transactions
    </p>

    <div class="filters mb-6">
      <div class="filter-buttons flex flex-wrap gap-2">
        <button
          @click="activeFilter = 'all'"
          :class="[
            'px-4 py-2 rounded-full text-sm font-medium transition-colors',
            activeFilter === 'all'
              ? 'bg-green-500 text-white'
              : 'bg-gray-100 text-gray-700 hover:bg-gray-200',
          ]"
        >
          All Transactions
        </button>
        <button
          @click="activeFilter = 'data'"
          :class="[
            'px-4 py-2 rounded-full text-sm font-medium transition-colors',
            activeFilter === 'data'
              ? 'bg-green-500 text-white'
              : 'bg-gray-100 text-gray-700 hover:bg-gray-200',
          ]"
        >
          Data
        </button>
        <button
          @click="activeFilter = 'voice'"
          :class="[
            'px-4 py-2 rounded-full text-sm font-medium transition-colors',
            activeFilter === 'voice'
              ? 'bg-green-500 text-white'
              : 'bg-gray-100 text-gray-700 hover:bg-gray-200',
          ]"
        >
          Voice
        </button>
        <button
          @click="activeFilter = 'combo'"
          :class="[
            'px-4 py-2 rounded-full text-sm font-medium transition-colors',
            activeFilter === 'combo'
              ? 'bg-green-500 text-white'
              : 'bg-gray-100 text-gray-700 hover:bg-gray-200',
          ]"
        >
          Combo
        </button>
      </div>
    </div>

    <div class="transactions overflow-auto h-[460px]">
      <div
        v-if="filteredTransactions.length === 0"
        class="text-center py-8 text-gray-500"
      >
        No transactions found
      </div>

      <div
        v-for="(transaction, index) in filteredTransactions"
        :key="index"
        class="transaction-item border rounded-lg p-3 mb-3 hover:shadow-md transition-shadow"
      >
        <div class="flex justify-between items-start">
          <div>
            <div class="flex items-center gap-2">
              <div
                class="operator-icon w-6 h-6 rounded-full flex items-center justify-center"
                :class="getOperatorClass(transaction?.operator)"
              >
                <NuxtImg
                  v-if="transaction.operator_details"
                  :src="transaction.operator_details.icon"
                  class="w-4 h-4"
                />
              </div>
              <div>
                <h3 class="font-semibold">
                  {{ transaction?.operator_details.name }}
                </h3>
                <p class="text-sm text-gray-600">
                  {{ formatDate(transaction.created_at) }}
                </p>
              </div>
            </div>
          </div>
          <div class="text-right">
            <span class="text-base font-bold">${{ transaction.amount }}</span>
            <div
              v-if="transaction.package?.type"
              class="package-type text-xs px-2 py-1 rounded-full inline-block mt-1 ml-1"
              :class="getPackageClass(transaction.packageType)"
            >
              {{ transaction.package?.type }}
            </div>
          </div>
        </div>

        <div
          class="mt-2 text-xs text-gray-700"
          v-if="transaction.package_details"
        >
          <div class="grid grid-cols-2 gap-1">
            <div>
              <span class="text-gray-500">Data:</span>
              {{ transaction.package_details.data }}
            </div>
            <div>
              <span class="text-gray-500">Duration:</span>
              {{ transaction.package_details.validity }} days
            </div>
            <div>
              <span class="text-gray-500">Calls:</span>
              {{ transaction.package_details.calls }}
            </div>
            <div>
              <span class="text-gray-500">Status: </span>
              <span
                class="capitalize"
                :class="
                  transaction.status === 'completed'
                    ? 'text-green-600'
                    : 'text-orange-500'
                "
              >
                {{ transaction.status }}
              </span>
            </div>
          </div>
        </div>
      </div>
    </div>

    <div class="pagination flex justify-center mt-6 gap-2">
      <button
        @click="currentPage = Math.max(1, currentPage - 1)"
        :disabled="currentPage === 1"
        class="px-3 py-1 rounded border disabled:opacity-50 disabled:cursor-not-allowed"
      >
        Previous
      </button>
      <button
        v-for="page in totalPages"
        :key="page"
        @click="currentPage = page"
        :class="[
          'px-3 py-1 rounded border',
          currentPage === page ? 'bg-emerald-500 text-white' : '',
        ]"
      >
        {{ page }}
      </button>
      <button
        @click="currentPage = Math.min(totalPages, currentPage + 1)"
        :disabled="currentPage === totalPages"
        class="px-3 py-1 rounded border disabled:opacity-50 disabled:cursor-not-allowed"
      >
        Next
      </button>
    </div>
  </div>
</template>

<script setup>
const { get } = useApi();
const { user } = useAuth();
const { formatDate } = useUtils();

const searchQuery = ref("");
const activeFilter = ref("all");
const currentPage = ref(1);
const itemsPerPage = 5;

// Sample transaction data based on the packages shown in the screenshot
const transactions = ref([]);
async function getMobileRechargeHistory() {
  const { data } = await get(`/mobile-recharge/recharges/`);
  transactions.value = data;
}
await getMobileRechargeHistory();

const filteredTransactions = computed(() => {
  let result = transactions.value;

  // Apply search filter
  if (searchQuery.value) {
    const query = searchQuery.value.toLowerCase();
    result = result.filter(
      (t) =>
        t.operator.toLowerCase().includes(query) ||
        t.packageType.toLowerCase().includes(query) ||
        t.amount.toString().includes(query) ||
        t.id.toLowerCase().includes(query)
    );
  }

  // Apply package type filter
  if (activeFilter.value !== "all") {
    result = result.filter((t) => t.packageType === activeFilter.value);
  }

  // Apply pagination
  const startIndex = (currentPage.value - 1) * itemsPerPage;
  const endIndex = startIndex + itemsPerPage;

  return result.slice(startIndex, endIndex);
});

const totalTransactions = computed(() => {
  let result = transactions.value;

  // Apply search filter
  if (searchQuery.value) {
    const query = searchQuery.value.toLowerCase();
    result = result.filter(
      (t) =>
        t.operator.toLowerCase().includes(query) ||
        t.packageType.toLowerCase().includes(query) ||
        t.amount.toString().includes(query) ||
        t.id.toLowerCase().includes(query)
    );
  }

  // Apply package type filter
  if (activeFilter.value !== "all") {
    result = result.filter((t) => t.packageType === activeFilter.value);
  }

  return result.length;
});

const totalPages = computed(() => {
  return Math.ceil(totalTransactions.value / itemsPerPage);
});

const getPackageClass = (packageType) => {
  switch (packageType) {
    case "data":
      return "bg-green-100 text-green-800";
    case "voice":
      return "bg-purple-100 text-purple-800";
    case "combo":
      return "bg-amber-100 text-amber-800";
    default:
      return "bg-gray-100 text-gray-800";
  }
};

const getOperatorClass = (operator) => {
  switch (operator) {
    case "Grameenphone":
      return "bg-green-100 text-green-800";
    case "Banglalink":
      return "bg-orange-100 text-orange-800";
    case "Robi":
      return "bg-red-100 text-red-800";
    default:
      return "bg-gray-100 text-gray-800";
  }
};

const getOperatorIcon = (operator) => {
  switch (operator) {
    case "Grameenphone":
      return;
    case "Banglalink":
      return;
    case "Robi":
      return;
    default:
      return;
  }
};
</script>

<style scoped>
.transaction-history {
  max-width: 800px;
  margin: 0 auto;
  padding: 1.5rem;
}

@media (max-width: 640px) {
  .transaction-history {
    padding: 1rem;
  }
}
</style>
