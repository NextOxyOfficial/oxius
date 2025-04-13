<template>
  <div class="transaction-history h-max">
    <h1 class="text-lg sm:text-2xl font-bold text-center mb-2">
      {{ $t("recharge_history") }}
    </h1>
    <p class="text-center text-gray-600 mb-6">
      {{ $t("mobile_recharge_transactions") }}
    </p>

    <!-- Filter buttons with improved styling -->
    <div class="filters mb-6">
      <div class="filter-buttons flex flex-wrap gap-2 justify-center">
        <button
          v-for="filter in filterOptions"
          :key="filter.value"
          @click="activeFilter = filter.value"
          :class="[
            'px-4 py-2 rounded-full text-sm font-medium transition-colors',
            activeFilter === filter.value
              ? 'border border-green-500  shadow-sm'
              : 'bg-gray-100 text-gray-700 hover:bg-gray-200',
          ]"
        >
          {{ filter.label }}
        </button>
      </div>
    </div>

    <!-- Transactions list with proper null checks -->
    <div
      class="transactions overflow-auto h-[36vh] sm:h-[460px] scrollbar-thin scrollbar-thumb-gray-300 scrollbar-track-gray-100"
    >
      <div
        v-if="filteredTransactions.length === 0"
        class="text-center py-8 text-gray-500 flex flex-col items-center"
      >
        <UIcon
          name="i-heroicons-document-magnifying-glass"
          class="w-12 h-12 text-gray-300 mb-2"
        />
        No transactions found
      </div>

      <div
        v-for="(transaction, index) in filteredTransactions"
        :key="index"
        class="transaction-item border rounded-lg p-4 mb-3 hover:shadow-md transition-shadow bg-white"
      >
        <div class="flex justify-between items-start">
          <div>
            <div class="flex items-center gap-2">
              <div
                class="operator-icon w-8 h-8 rounded-full flex items-center justify-center"
                :class="getOperatorClass(transaction?.operator)"
              >
                <NuxtImg
                  v-if="transaction?.operator_details?.icon"
                  :src="transaction.operator_details.icon"
                  class="w-5 h-5"
                  alt="Operator"
                />
                <span v-else class="text-xs">{{
                  getOperatorInitial(transaction?.operator)
                }}</span>
              </div>
              <div>
                <h3 class="font-semibold">
                  {{
                    transaction?.operator_details?.name || "Unknown Operator"
                  }}
                </h3>
                <p class="text-sm text-gray-600">
                  {{ formatDate(transaction?.created_at) }}
                </p>
              </div>
            </div>
          </div>
          <div class="text-right">
            <span class="text-base font-bold"
              ><span class="text-xl">৳</span>
              {{ transaction?.amount || "0" }}</span
            >
            <div
              v-if="transaction?.package?.type"
              class="package-type text-xs px-2 py-1 rounded-full inline-block mt-1 ml-1"
              :class="getPackageClass(transaction?.package?.type)"
            >
              {{ transaction?.package?.type }}
            </div>
          </div>
        </div>

        <div
          class="mt-2 text-xs text-gray-700"
          v-if="transaction?.package_details"
        >
          <div class="grid grid-cols-2 gap-1">
            <div>
              <span class="text-gray-500">Data:</span>
              {{ transaction?.package_details?.data || "N/A" }}
            </div>
            <div>
              <span class="text-gray-500">Duration:</span>
              {{ transaction?.package_details?.validity || "0" }} days
            </div>
            <div>
              <span class="text-gray-500">Calls:</span>
              {{ transaction?.package_details?.calls || "N/A" }}
            </div>
            <div>
              <span class="text-gray-500">Status: </span>
              <span
                class="capitalize"
                :class="
                  transaction?.status === 'completed'
                    ? 'text-green-600'
                    : 'text-orange-500'
                "
              >
                {{ transaction?.status || "pending" }}
              </span>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- Improved pagination with clear indication -->
    <div class="pagination flex justify-center mt-6 gap-2">
      <button
        @click="currentPage = Math.max(1, currentPage - 1)"
        :disabled="currentPage === 1"
        class="px-3 py-1 rounded border disabled:opacity-50 disabled:cursor-not-allowed hover:bg-gray-50"
      >
        <UIcon name="i-heroicons-chevron-left" class="w-4 h-4" />
      </button>

      <button
        v-for="page in paginationRange"
        :key="page"
        @click="currentPage = page"
        :class="[
          'px-3 py-1 rounded border transition-colors',
          currentPage === page
            ? 'bg-emerald-500 text-white border-emerald-500'
            : 'hover:bg-gray-50',
        ]"
      >
        {{ page }}
      </button>

      <button
        @click="currentPage = Math.min(totalPages, currentPage + 1)"
        :disabled="currentPage === totalPages || totalPages === 0"
        class="px-3 py-1 rounded border disabled:opacity-50 disabled:cursor-not-allowed hover:bg-gray-50"
      >
        <UIcon name="i-heroicons-chevron-right" class="w-4 h-4" />
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

// Pre-defined filter options to avoid hardcoding
const filterOptions = [{ value: "all", label: "All Transactions" }];

// Fetch transaction data
const transactions = ref([]);
const isLoading = ref(true);

async function getMobileRechargeHistory() {
  try {
    isLoading.value = true;
    const { data } = await get(`/mobile-recharge/recharges/`);
    transactions.value = Array.isArray(data) ? data : [];
  } catch (error) {
    console.error("Error fetching mobile recharge history:", error);
    transactions.value = [];
  } finally {
    isLoading.value = false;
  }
}

await getMobileRechargeHistory();

// Filtered transactions with proper error handling
const filteredTransactions = computed(() => {
  if (!transactions.value || !Array.isArray(transactions.value)) {
    return [];
  }

  let result = [...transactions.value];

  // Apply search filter
  if (searchQuery.value) {
    const query = searchQuery.value.toLowerCase();
    result = result.filter((item) => {
      if (!item) return false;

      return (
        (item.operator && item.operator.toLowerCase().includes(query)) ||
        (item.package?.type &&
          item.package.type.toLowerCase().includes(query)) ||
        (item.amount && item.amount.toString().includes(query)) ||
        (item.id && item.id.toString().toLowerCase().includes(query))
      );
    });
  }

  // Apply package type filter
  if (activeFilter.value !== "all") {
    result = result.filter(
      (item) => item && item.package && item.package.type === activeFilter.value
    );
  }

  // Apply pagination
  const startIndex = (currentPage.value - 1) * itemsPerPage;
  const endIndex = startIndex + itemsPerPage;

  return result.slice(startIndex, endIndex);
});

// Count total filtered transactions for pagination
const totalTransactions = computed(() => {
  if (!transactions.value || !Array.isArray(transactions.value)) {
    return 0;
  }

  let result = [...transactions.value];

  // Apply search filter
  if (searchQuery.value) {
    const query = searchQuery.value.toLowerCase();
    result = result.filter((item) => {
      if (!item) return false;

      return (
        (item.operator && item.operator.toLowerCase().includes(query)) ||
        (item.package?.type &&
          item.package.type.toLowerCase().includes(query)) ||
        (item.amount && item.amount.toString().includes(query)) ||
        (item.id && item.id.toString().toLowerCase().includes(query))
      );
    });
  }

  // Apply package type filter
  if (activeFilter.value !== "all") {
    result = result.filter(
      (item) => item && item.package && item.package.type === activeFilter.value
    );
  }

  return result.length;
});

// Calculate total pages
const totalPages = computed(() => {
  return Math.max(1, Math.ceil(totalTransactions.value / itemsPerPage));
});

// Intelligent pagination range display
const paginationRange = computed(() => {
  if (totalPages.value <= 5) {
    // If 5 or fewer pages, show all
    return Array.from({ length: totalPages.value }, (_, i) => i + 1);
  }

  const start = Math.max(1, currentPage.value - 2);
  const end = Math.min(totalPages.value, start + 4);

  return Array.from({ length: end - start + 1 }, (_, i) => start + i);
});

// Reset to first page when filter changes
watch(activeFilter, () => {
  currentPage.value = 1;
});

watch(searchQuery, () => {
  currentPage.value = 1;
});

// Helper functions with null checks
const getPackageClass = (packageType) => {
  if (!packageType) return "bg-gray-100 text-gray-800";

  switch (packageType.toLowerCase()) {
    case "data":
      return "bg-green-100 text-green-800";
    case "voice":
      return "bg-purple-100 text-purple-800";
    case "combo":
      return "bg-amber-100 text-amber-800";
    case "balance":
      return "bg-blue-100 text-blue-800";
    default:
      return "bg-gray-100 text-gray-800";
  }
};

const getOperatorClass = (operator) => {
  if (!operator) return "bg-gray-100 text-gray-800";

  switch (operator) {
    case "Grameenphone":
      return "bg-green-100 text-green-800";
    case "Banglalink":
      return "bg-orange-100 text-orange-800";
    case "Robi":
      return "bg-red-100 text-red-800";
    case "Airtel":
      return "bg-red-100 text-red-800";
    case "Teletalk":
      return "bg-blue-100 text-blue-800";
    default:
      return "bg-gray-100 text-gray-800";
  }
};

const getOperatorInitial = (operator) => {
  if (!operator) return "?";
  return operator.charAt(0).toUpperCase();
};
</script>

<style scoped>
.transaction-history {
  max-width: 800px;
  margin: 0 auto;
  padding: 1.5rem;
}

/* Custom scrollbar styling */
.scrollbar-thin::-webkit-scrollbar {
  width: 6px;
}

.scrollbar-thin::-webkit-scrollbar-track {
  background: #f1f1f1;
  border-radius: 10px;
}

.scrollbar-thin::-webkit-scrollbar-thumb {
  background: #d1d5db;
  border-radius: 10px;
}

@media (max-width: 640px) {
  .transaction-history {
    padding: 1rem;
  }
}
</style>
